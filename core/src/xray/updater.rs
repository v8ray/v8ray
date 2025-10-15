//! Xray Core Updater Module
//!
//! This module handles downloading and updating Xray Core binary.

use super::XrayError;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tokio::fs;
use tokio::io::AsyncWriteExt;

// Windows-specific imports for hiding console window
#[cfg(windows)]
use std::os::windows::process::CommandExt;

/// Xray Core update information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateInfo {
    /// Whether an update is available
    pub has_update: bool,
    /// Current version
    pub current_version: String,
    /// Latest available version
    pub latest_version: String,
    /// Download URL for the update
    pub download_url: String,
    /// File size in bytes
    pub file_size: u64,
}

/// Xray Core updater
pub struct XrayUpdater {
    /// Binary directory path
    bin_dir: PathBuf,
    /// HTTP client
    client: reqwest::Client,
    /// Download progress (0.0 to 1.0)
    progress: std::sync::Arc<tokio::sync::RwLock<f64>>,
}

impl XrayUpdater {
    /// Create a new updater
    pub fn new(bin_dir: PathBuf) -> Self {
        Self {
            bin_dir,
            client: reqwest::Client::builder()
                .user_agent(crate::version::user_agent())
                .timeout(std::time::Duration::from_secs(300))
                .build()
                .unwrap(),
            progress: std::sync::Arc::new(tokio::sync::RwLock::new(0.0)),
        }
    }

    /// Get current Xray Core version
    pub async fn get_current_version(&self) -> Result<String, XrayError> {
        let binary_path = self.get_binary_path();

        if !binary_path.exists() {
            return Ok("not installed".to_string());
        }

        let mut cmd = tokio::process::Command::new(&binary_path);
        cmd.arg("version");

        // On Windows, hide the console window
        #[cfg(windows)]
        {
            const CREATE_NO_WINDOW: u32 = 0x08000000;
            cmd.creation_flags(CREATE_NO_WINDOW);
        }

        let output = cmd
            .output()
            .await
            .map_err(|e| XrayError::Process(e.to_string()))?;

        if output.status.success() {
            let version_output = String::from_utf8_lossy(&output.stdout);
            // Parse version from output like "Xray 1.8.7 (Xray, Penetrates Everything.) Custom"
            if let Some(line) = version_output.lines().next() {
                if let Some(version) = line.split_whitespace().nth(1) {
                    return Ok(version.to_string());
                }
            }
        }

        Ok("unknown".to_string())
    }

    /// Fetch latest version from GitHub
    pub async fn fetch_latest_version(&self) -> Result<String, XrayError> {
        let url = "https://api.github.com/repos/XTLS/Xray-core/releases/latest";

        let response =
            self.client.get(url).send().await.map_err(|e| {
                XrayError::Process(format!("Failed to fetch latest version: {}", e))
            })?;

        if !response.status().is_success() {
            return Err(XrayError::Process(format!(
                "GitHub API returned status: {}",
                response.status()
            )));
        }

        let release: serde_json::Value = response
            .json()
            .await
            .map_err(|e| XrayError::Process(format!("Failed to parse response: {}", e)))?;

        let tag_name = release["tag_name"]
            .as_str()
            .ok_or_else(|| XrayError::Process("No tag_name in response".to_string()))?;

        // Remove 'v' prefix if present
        let version = tag_name.trim_start_matches('v').to_string();
        Ok(version)
    }

    /// Check for updates
    pub async fn check_update(&self) -> Result<UpdateInfo, XrayError> {
        let current = self.get_current_version().await?;
        let latest = self.fetch_latest_version().await?;

        let has_update = current != latest && current != "unknown";

        let download_url = self.get_download_url(&latest)?;

        Ok(UpdateInfo {
            has_update,
            current_version: current,
            latest_version: latest.clone(),
            download_url,
            file_size: 0, // Will be determined during download
        })
    }

    /// Get download URL for specific version
    fn get_download_url(&self, version: &str) -> Result<String, XrayError> {
        let (os, arch, ext) = self.get_platform_info()?;

        let url = format!(
            "https://github.com/XTLS/Xray-core/releases/download/v{}/Xray-{}-{}.{}",
            version, os, arch, ext
        );

        Ok(url)
    }

    /// Get platform information for download
    fn get_platform_info(&self) -> Result<(&'static str, &'static str, &'static str), XrayError> {
        #[cfg(all(target_os = "windows", target_arch = "x86_64"))]
        return Ok(("windows", "64", "zip"));

        #[cfg(all(target_os = "windows", target_arch = "x86"))]
        return Ok(("windows", "32", "zip"));

        #[cfg(all(target_os = "windows", target_arch = "aarch64"))]
        return Ok(("windows", "arm64-v8a", "zip"));

        #[cfg(all(target_os = "linux", target_arch = "x86_64"))]
        return Ok(("linux", "64", "zip"));

        #[cfg(all(target_os = "linux", target_arch = "aarch64"))]
        return Ok(("linux", "arm64-v8a", "zip"));

        #[cfg(all(target_os = "macos", target_arch = "x86_64"))]
        return Ok(("macos", "64", "zip"));

        #[cfg(all(target_os = "macos", target_arch = "aarch64"))]
        return Ok(("macos", "arm64-v8a", "zip"));

        #[cfg(not(any(
            all(
                target_os = "windows",
                any(target_arch = "x86_64", target_arch = "x86", target_arch = "aarch64")
            ),
            all(
                target_os = "linux",
                any(target_arch = "x86_64", target_arch = "aarch64")
            ),
            all(
                target_os = "macos",
                any(target_arch = "x86_64", target_arch = "aarch64")
            )
        )))]
        return Err(XrayError::NotFound);
    }

    /// Download and install Xray Core update
    pub async fn update(&self, version: &str) -> Result<(), XrayError> {
        tracing::info!("Starting Xray Core update to version {}", version);

        // 1. Download to temporary file
        let temp_path = self.download_xray(version).await?;

        // 2. Backup current binary
        self.backup_current_binary().await?;

        // 3. Extract and install
        self.install_binary(&temp_path).await?;

        // 4. Verify installation
        self.verify_installation().await?;

        // 5. Cleanup
        let _ = fs::remove_file(&temp_path).await;

        tracing::info!("Xray Core updated successfully to version {}", version);
        Ok(())
    }

    /// Download Xray Core binary
    async fn download_xray(&self, version: &str) -> Result<PathBuf, XrayError> {
        let download_url = self.get_download_url(version)?;

        tracing::info!("Downloading Xray Core from: {}", download_url);

        let response = self
            .client
            .get(&download_url)
            .send()
            .await
            .map_err(|e| XrayError::Process(format!("Download failed: {}", e)))?;

        if !response.status().is_success() {
            return Err(XrayError::Process(format!(
                "Download failed with status: {}",
                response.status()
            )));
        }

        let _total_size = response.content_length().unwrap_or(0);
        let temp_path = std::env::temp_dir().join(format!("xray-{}.zip", version));

        let mut file = fs::File::create(&temp_path).await.map_err(XrayError::Io)?;
        let bytes = response
            .bytes()
            .await
            .map_err(|e| XrayError::Process(format!("Download error: {}", e)))?;

        file.write_all(&bytes).await.map_err(XrayError::Io)?;

        let downloaded = bytes.len() as u64;

        let mut p = self.progress.write().await;
        *p = 1.0;

        file.flush().await.map_err(XrayError::Io)?;

        tracing::info!("Downloaded {} bytes to {:?}", downloaded, temp_path);
        Ok(temp_path)
    }

    /// Backup current binary
    async fn backup_current_binary(&self) -> Result<(), XrayError> {
        let binary_path = self.get_binary_path();

        if binary_path.exists() {
            let backup_path = binary_path.with_extension("bak");
            fs::copy(&binary_path, &backup_path)
                .await
                .map_err(XrayError::Io)?;
            tracing::info!("Backed up current binary to {:?}", backup_path);
        }

        Ok(())
    }

    /// Install binary from downloaded archive
    async fn install_binary(&self, _archive_path: &Path) -> Result<(), XrayError> {
        // TODO: Implement ZIP extraction
        // For now, this is a placeholder
        tracing::warn!("Binary installation not yet implemented");
        Ok(())
    }

    /// Verify installation
    async fn verify_installation(&self) -> Result<(), XrayError> {
        let version = self.get_current_version().await?;
        if version == "not installed" || version == "unknown" {
            return Err(XrayError::Process(
                "Installation verification failed".to_string(),
            ));
        }

        tracing::info!("Installation verified, version: {}", version);
        Ok(())
    }

    /// Get binary path
    fn get_binary_path(&self) -> PathBuf {
        #[cfg(windows)]
        let binary_name = "xray.exe";
        #[cfg(not(windows))]
        let binary_name = "xray";

        self.bin_dir.join(binary_name)
    }

    /// Get download progress
    pub async fn get_progress(&self) -> f64 {
        *self.progress.read().await
    }

    /// Rollback to backup
    pub async fn rollback(&self) -> Result<(), XrayError> {
        let binary_path = self.get_binary_path();
        let backup_path = binary_path.with_extension("bak");

        if !backup_path.exists() {
            return Err(XrayError::Process("No backup found".to_string()));
        }

        fs::copy(&backup_path, &binary_path)
            .await
            .map_err(XrayError::Io)?;

        tracing::info!("Rolled back to backup version");
        Ok(())
    }
}
