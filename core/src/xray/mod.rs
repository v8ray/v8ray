//! Xray Core Integration Module
//!
//! This module handles integration with Xray Core, including process management,
//! configuration generation, and status monitoring.

use serde::{Deserialize, Serialize};
use std::process::{Child, Command, Stdio};
use thiserror::Error;
use tokio::sync::RwLock;

/// Xray Core errors
#[derive(Error, Debug)]
pub enum XrayError {
    /// IO error
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    /// Process error
    #[error("Process error: {0}")]
    Process(String),
    /// Configuration error
    #[error("Configuration error: {0}")]
    Config(String),
    /// Xray Core not found
    #[error("Xray Core not found")]
    NotFound,
}

/// Xray Core status
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum XrayStatus {
    /// Xray Core is stopped
    Stopped,
    /// Xray Core is starting
    Starting,
    /// Xray Core is running
    Running,
    /// Xray Core is stopping
    Stopping,
    /// Xray Core has error
    Error(String),
}

/// Xray Core configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XrayConfig {
    /// Log configuration
    pub log: LogConfig,
    /// Inbound configurations
    pub inbounds: Vec<InboundConfig>,
    /// Outbound configurations
    pub outbounds: Vec<OutboundConfig>,
    /// Routing configuration
    pub routing: Option<RoutingConfig>,
}

/// Log configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogConfig {
    /// Log level
    pub level: String,
    /// Access log path
    pub access: Option<String>,
    /// Error log path
    pub error: Option<String>,
}

/// Inbound configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InboundConfig {
    /// Port number
    pub port: u16,
    /// Protocol
    pub protocol: String,
    /// Listen address
    pub listen: Option<String>,
    /// Settings
    pub settings: Option<serde_json::Value>,
}

/// Outbound configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutboundConfig {
    /// Protocol
    pub protocol: String,
    /// Settings
    pub settings: Option<serde_json::Value>,
    /// Stream settings
    pub stream_settings: Option<serde_json::Value>,
}

/// Routing configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoutingConfig {
    /// Domain strategy
    pub domain_strategy: Option<String>,
    /// Rules
    pub rules: Vec<serde_json::Value>,
}

/// Xray Core manager
pub struct XrayCore {
    /// Current status
    status: RwLock<XrayStatus>,
    /// Xray process
    process: RwLock<Option<Child>>,
    /// Current configuration
    config: RwLock<Option<XrayConfig>>,
}

impl Default for XrayCore {
    fn default() -> Self {
        Self::new()
    }
}

impl XrayCore {
    /// Create a new Xray Core manager
    pub fn new() -> Self {
        Self {
            status: RwLock::new(XrayStatus::Stopped),
            process: RwLock::new(None),
            config: RwLock::new(None),
        }
    }

    /// Get current status
    pub async fn get_status(&self) -> XrayStatus {
        self.status.read().await.clone()
    }

    /// Start Xray Core with configuration
    pub async fn start(&self, config: XrayConfig) -> Result<(), XrayError> {
        let mut status = self.status.write().await;

        if *status == XrayStatus::Running {
            return Ok(());
        }

        *status = XrayStatus::Starting;
        drop(status);

        // Save configuration
        {
            let mut current_config = self.config.write().await;
            *current_config = Some(config.clone());
        }

        // TODO: Find Xray Core binary
        let xray_path = self.find_xray_binary()?;

        // Generate configuration file
        let config_content =
            serde_json::to_string_pretty(&config).map_err(|e| XrayError::Config(e.to_string()))?;

        // Write config to temporary file
        let config_path = std::env::temp_dir().join("v8ray_xray_config.json");
        std::fs::write(&config_path, config_content)?;

        // Start Xray process
        let child = Command::new(xray_path)
            .arg("-config")
            .arg(&config_path)
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?;

        {
            let mut process = self.process.write().await;
            *process = Some(child);
        }

        // Update status
        {
            let mut status = self.status.write().await;
            *status = XrayStatus::Running;
        }

        tracing::info!("Xray Core started successfully");
        Ok(())
    }

    /// Stop Xray Core
    pub async fn stop(&self) -> Result<(), XrayError> {
        let mut status = self.status.write().await;

        if *status == XrayStatus::Stopped {
            return Ok(());
        }

        *status = XrayStatus::Stopping;
        drop(status);

        // Kill process
        {
            let mut process = self.process.write().await;
            if let Some(mut child) = process.take() {
                child.kill()?;
                child.wait()?;
            }
        }

        // Update status
        {
            let mut status = self.status.write().await;
            *status = XrayStatus::Stopped;
        }

        tracing::info!("Xray Core stopped");
        Ok(())
    }

    /// Restart Xray Core
    pub async fn restart(&self) -> Result<(), XrayError> {
        let config = {
            let config_guard = self.config.read().await;
            config_guard.clone()
        };

        self.stop().await?;

        if let Some(config) = config {
            self.start(config).await?;
        }

        Ok(())
    }

    /// Find Xray binary
    fn find_xray_binary(&self) -> Result<String, XrayError> {
        // TODO: Implement proper binary discovery
        // For now, assume xray is in PATH
        #[cfg(windows)]
        let binary_name = "xray.exe";
        #[cfg(not(windows))]
        let binary_name = "xray";

        // Try to find in PATH
        if let Ok(output) = Command::new("which").arg(binary_name).output() {
            if output.status.success() {
                let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                return Ok(path);
            }
        }

        // Try common locations
        let common_paths = [
            format!("/usr/local/bin/{}", binary_name),
            format!("/usr/bin/{}", binary_name),
            format!("./bin/{}", binary_name),
            format!("./{}", binary_name),
        ];

        for path in &common_paths {
            if std::path::Path::new(path).exists() {
                return Ok(path.clone());
            }
        }

        Err(XrayError::NotFound)
    }
}

impl Default for XrayConfig {
    fn default() -> Self {
        Self {
            log: LogConfig {
                level: "warning".to_string(),
                access: None,
                error: None,
            },
            inbounds: vec![
                InboundConfig {
                    port: 8080,
                    protocol: "http".to_string(),
                    listen: Some("127.0.0.1".to_string()),
                    settings: None,
                },
                InboundConfig {
                    port: 1080,
                    protocol: "socks".to_string(),
                    listen: Some("127.0.0.1".to_string()),
                    settings: None,
                },
            ],
            outbounds: vec![OutboundConfig {
                protocol: "freedom".to_string(),
                settings: None,
                stream_settings: None,
            }],
            routing: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_xray_core_status() {
        let xray = XrayCore::new();
        assert_eq!(xray.get_status().await, XrayStatus::Stopped);
    }

    #[test]
    fn test_xray_config_serialization() {
        let config = XrayConfig::default();
        let json = serde_json::to_string(&config).unwrap();
        assert!(!json.is_empty());

        let _parsed: XrayConfig = serde_json::from_str(&json).unwrap();
    }
}
