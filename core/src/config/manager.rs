//! Configuration Manager
//!
//! This module provides the configuration management functionality.

use super::{Config, ProxyServerConfig};
use crate::error::{ConfigError, ConfigResult};
use crate::utils::crypto::{decrypt_aes256, derive_key_from_password, encrypt_aes256};
use chrono::{DateTime, Utc};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{debug, info, warn};

/// Configuration manager
#[derive(Clone)]
pub struct ConfigManager {
    /// Configuration file path
    config_path: PathBuf,
    /// Current configuration
    config: Arc<RwLock<Config>>,
    /// Proxy server configurations
    proxy_configs: Arc<RwLock<HashMap<String, ProxyServerConfig>>>,
    /// Encryption password (optional)
    encryption_password: Option<String>,
    /// Backup directory
    backup_dir: Option<PathBuf>,
}

impl ConfigManager {
    /// Create a new configuration manager
    pub fn new<P: AsRef<Path>>(config_path: P) -> Self {
        Self {
            config_path: config_path.as_ref().to_path_buf(),
            config: Arc::new(RwLock::new(Config::default())),
            proxy_configs: Arc::new(RwLock::new(HashMap::new())),
            encryption_password: None,
            backup_dir: None,
        }
    }

    /// Create a new configuration manager with encryption
    pub fn new_with_encryption<P: AsRef<Path>>(config_path: P, password: String) -> Self {
        Self {
            config_path: config_path.as_ref().to_path_buf(),
            config: Arc::new(RwLock::new(Config::default())),
            proxy_configs: Arc::new(RwLock::new(HashMap::new())),
            encryption_password: Some(password),
            backup_dir: None,
        }
    }

    /// Set backup directory
    pub fn set_backup_dir<P: AsRef<Path>>(&mut self, backup_dir: P) {
        self.backup_dir = Some(backup_dir.as_ref().to_path_buf());
    }

    /// Set encryption password
    pub fn set_encryption_password(&mut self, password: String) {
        self.encryption_password = Some(password);
    }

    /// Clear encryption password
    pub fn clear_encryption_password(&mut self) {
        self.encryption_password = None;
    }

    /// Load configuration from file
    pub async fn load(&self) -> ConfigResult<()> {
        info!("Loading configuration from {:?}", self.config_path);

        if !self.config_path.exists() {
            warn!("Configuration file not found, using defaults");
            return Ok(());
        }

        let content = std::fs::read_to_string(&self.config_path)?;

        // Decrypt if password is set
        let json_str = if let Some(ref password) = self.encryption_password {
            let key = derive_key_from_password(password);
            let decrypted = decrypt_aes256(&content, &key)
                .map_err(|e| ConfigError::Validation(format!("Decryption failed: {}", e)))?;
            String::from_utf8(decrypted)
                .map_err(|e| ConfigError::Validation(format!("UTF-8 decode failed: {}", e)))?
        } else {
            content
        };

        let config: Config = serde_json::from_str(&json_str)?;
        config.validate()?;

        let mut current_config = self.config.write().await;
        *current_config = config;

        info!("Configuration loaded successfully");
        Ok(())
    }

    /// Save configuration to file
    pub async fn save(&self) -> ConfigResult<()> {
        info!("Saving configuration to {:?}", self.config_path);

        // Ensure parent directory exists
        if let Some(parent) = self.config_path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        let config = self.config.read().await;
        config.validate()?;

        let json_str = serde_json::to_string_pretty(&*config)?;

        // Encrypt if password is set
        let content = if let Some(ref password) = self.encryption_password {
            let key = derive_key_from_password(password);
            encrypt_aes256(json_str.as_bytes(), &key)
                .map_err(|e| ConfigError::Validation(format!("Encryption failed: {}", e)))?
        } else {
            json_str
        };

        std::fs::write(&self.config_path, content)?;

        info!("Configuration saved successfully");
        Ok(())
    }

    /// Get current configuration
    pub async fn get_config(&self) -> Config {
        self.config.read().await.clone()
    }

    /// Update configuration
    pub async fn update_config<F>(&self, f: F) -> ConfigResult<()>
    where
        F: FnOnce(&mut Config),
    {
        let mut config = self.config.write().await;
        f(&mut config);
        config.validate()?;
        Ok(())
    }

    /// Add a proxy server configuration
    pub async fn add_proxy_config(&self, config: ProxyServerConfig) -> ConfigResult<String> {
        let id = config.id.clone();
        
        let mut configs = self.proxy_configs.write().await;
        if configs.contains_key(&id) {
            return Err(ConfigError::AlreadyExists(id));
        }
        
        configs.insert(id.clone(), config);
        debug!("Added proxy config: {}", id);
        
        Ok(id)
    }

    /// Get a proxy server configuration
    pub async fn get_proxy_config(&self, id: &str) -> ConfigResult<ProxyServerConfig> {
        let configs = self.proxy_configs.read().await;
        configs
            .get(id)
            .cloned()
            .ok_or_else(|| ConfigError::NotFound(id.to_string()))
    }

    /// Get all proxy server configurations
    pub async fn get_all_proxy_configs(&self) -> Vec<ProxyServerConfig> {
        let configs = self.proxy_configs.read().await;
        configs.values().cloned().collect()
    }

    /// Update a proxy server configuration
    pub async fn update_proxy_config(
        &self,
        id: &str,
        config: ProxyServerConfig,
    ) -> ConfigResult<()> {
        let mut configs = self.proxy_configs.write().await;
        
        if !configs.contains_key(id) {
            return Err(ConfigError::NotFound(id.to_string()));
        }
        
        configs.insert(id.to_string(), config);
        debug!("Updated proxy config: {}", id);
        
        Ok(())
    }

    /// Delete a proxy server configuration
    pub async fn delete_proxy_config(&self, id: &str) -> ConfigResult<()> {
        let mut configs = self.proxy_configs.write().await;
        
        if configs.remove(id).is_none() {
            return Err(ConfigError::NotFound(id.to_string()));
        }
        
        debug!("Deleted proxy config: {}", id);
        Ok(())
    }

    /// Delete multiple proxy server configurations
    pub async fn delete_proxy_configs(&self, ids: Vec<String>) -> ConfigResult<()> {
        let mut configs = self.proxy_configs.write().await;
        
        for id in ids {
            configs.remove(&id);
        }
        
        debug!("Deleted multiple proxy configs");
        Ok(())
    }

    /// Clear all proxy server configurations
    pub async fn clear_proxy_configs(&self) -> ConfigResult<()> {
        let mut configs = self.proxy_configs.write().await;
        configs.clear();
        debug!("Cleared all proxy configs");
        Ok(())
    }

    /// Get proxy configs count
    pub async fn get_proxy_configs_count(&self) -> usize {
        let configs = self.proxy_configs.read().await;
        configs.len()
    }

    /// Create a backup of the current configuration
    pub async fn create_backup(&self) -> ConfigResult<PathBuf> {
        let backup_dir = self.backup_dir.as_ref().ok_or_else(|| {
            ConfigError::Validation("Backup directory not set".to_string())
        })?;

        // Create backup directory if it doesn't exist
        std::fs::create_dir_all(backup_dir)?;

        // Generate backup filename with timestamp (including microseconds for uniqueness)
        let timestamp = Utc::now().format("%Y%m%d_%H%M%S_%6f");
        let backup_filename = format!("config_backup_{}.json", timestamp);
        let backup_path = backup_dir.join(backup_filename);

        // Save current config to backup file
        let config = self.config.read().await;
        config.validate()?;

        let json_str = serde_json::to_string_pretty(&*config)?;
        std::fs::write(&backup_path, json_str)?;

        info!("Backup created at {:?}", backup_path);
        Ok(backup_path)
    }

    /// Restore configuration from a backup file
    pub async fn restore_from_backup<P: AsRef<Path>>(&self, backup_path: P) -> ConfigResult<()> {
        info!("Restoring configuration from {:?}", backup_path.as_ref());

        let content = std::fs::read_to_string(backup_path)?;
        let config: Config = serde_json::from_str(&content)?;
        config.validate()?;

        let mut current_config = self.config.write().await;
        *current_config = config;

        info!("Configuration restored successfully");
        Ok(())
    }

    /// List all available backups
    pub fn list_backups(&self) -> ConfigResult<Vec<PathBuf>> {
        let backup_dir = self.backup_dir.as_ref().ok_or_else(|| {
            ConfigError::Validation("Backup directory not set".to_string())
        })?;

        if !backup_dir.exists() {
            return Ok(vec![]);
        }

        let mut backups = Vec::new();
        for entry in std::fs::read_dir(backup_dir)? {
            let entry = entry?;
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("json") {
                if let Some(filename) = path.file_name().and_then(|s| s.to_str()) {
                    if filename.starts_with("config_backup_") {
                        backups.push(path);
                    }
                }
            }
        }

        // Sort by modification time (newest first)
        backups.sort_by(|a, b| {
            let a_time = std::fs::metadata(a).and_then(|m| m.modified()).ok();
            let b_time = std::fs::metadata(b).and_then(|m| m.modified()).ok();
            b_time.cmp(&a_time)
        });

        Ok(backups)
    }

    /// Delete old backups, keeping only the specified number of recent backups
    pub fn cleanup_old_backups(&self, keep_count: usize) -> ConfigResult<usize> {
        let backups = self.list_backups()?;

        if backups.len() <= keep_count {
            return Ok(0);
        }

        let mut deleted_count = 0;
        for backup in backups.iter().skip(keep_count) {
            std::fs::remove_file(backup)?;
            deleted_count += 1;
            debug!("Deleted old backup: {:?}", backup);
        }

        info!("Cleaned up {} old backups", deleted_count);
        Ok(deleted_count)
    }

    /// Export configuration to a file
    pub async fn export_config<P: AsRef<Path>>(&self, export_path: P) -> ConfigResult<()> {
        let config = self.config.read().await;
        config.validate()?;

        let json_str = serde_json::to_string_pretty(&*config)?;
        std::fs::write(export_path.as_ref(), json_str)?;

        info!("Configuration exported to {:?}", export_path.as_ref());
        Ok(())
    }

    /// Import configuration from a file
    pub async fn import_config<P: AsRef<Path>>(&self, import_path: P) -> ConfigResult<()> {
        let content = std::fs::read_to_string(import_path)?;
        let config: Config = serde_json::from_str(&content)?;
        config.validate()?;

        let mut current_config = self.config.write().await;
        *current_config = config;

        info!("Configuration imported successfully");
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use tempfile::NamedTempFile;

    fn create_test_proxy_config(id: &str, name: &str) -> ProxyServerConfig {
        ProxyServerConfig {
            id: id.to_string(),
            name: name.to_string(),
            server: "example.com".to_string(),
            port: 443,
            protocol: super::super::ProxyProtocol::Vless,
            settings: HashMap::new(),
            stream_settings: None,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    #[tokio::test]
    async fn test_config_manager_new() {
        let temp_file = NamedTempFile::new().unwrap();
        let manager = ConfigManager::new(temp_file.path());
        
        let config = manager.get_config().await;
        assert_eq!(config.proxy.http_port, 8080);
    }

    #[tokio::test]
    async fn test_add_and_get_proxy_config() {
        let temp_file = NamedTempFile::new().unwrap();
        let manager = ConfigManager::new(temp_file.path());
        
        let proxy_config = create_test_proxy_config("test-1", "Test Server");
        let id = manager.add_proxy_config(proxy_config.clone()).await.unwrap();
        
        let retrieved = manager.get_proxy_config(&id).await.unwrap();
        assert_eq!(retrieved.name, "Test Server");
    }

    #[tokio::test]
    async fn test_update_proxy_config() {
        let temp_file = NamedTempFile::new().unwrap();
        let manager = ConfigManager::new(temp_file.path());
        
        let mut proxy_config = create_test_proxy_config("test-1", "Test Server");
        manager.add_proxy_config(proxy_config.clone()).await.unwrap();
        
        proxy_config.name = "Updated Server".to_string();
        manager.update_proxy_config("test-1", proxy_config).await.unwrap();
        
        let retrieved = manager.get_proxy_config("test-1").await.unwrap();
        assert_eq!(retrieved.name, "Updated Server");
    }

    #[tokio::test]
    async fn test_delete_proxy_config() {
        let temp_file = NamedTempFile::new().unwrap();
        let manager = ConfigManager::new(temp_file.path());
        
        let proxy_config = create_test_proxy_config("test-1", "Test Server");
        manager.add_proxy_config(proxy_config).await.unwrap();
        
        manager.delete_proxy_config("test-1").await.unwrap();
        
        let result = manager.get_proxy_config("test-1").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_get_all_proxy_configs() {
        let temp_file = NamedTempFile::new().unwrap();
        let manager = ConfigManager::new(temp_file.path());

        manager.add_proxy_config(create_test_proxy_config("test-1", "Server 1")).await.unwrap();
        manager.add_proxy_config(create_test_proxy_config("test-2", "Server 2")).await.unwrap();

        let all_configs = manager.get_all_proxy_configs().await;
        assert_eq!(all_configs.len(), 2);
    }

    #[tokio::test]
    async fn test_encrypted_save_load() {
        let temp_file = NamedTempFile::new().unwrap();
        let mut manager = ConfigManager::new(temp_file.path());
        manager.set_encryption_password("test_password".to_string());

        // Modify config
        manager.update_config(|config| {
            config.proxy.http_port = 9090;
        }).await.unwrap();

        // Save with encryption
        manager.save().await.unwrap();

        // Create new manager with same password
        let mut manager2 = ConfigManager::new(temp_file.path());
        manager2.set_encryption_password("test_password".to_string());

        // Load encrypted config
        manager2.load().await.unwrap();

        let config = manager2.get_config().await;
        assert_eq!(config.proxy.http_port, 9090);
    }

    #[tokio::test]
    async fn test_backup_and_restore() {
        use tempfile::TempDir;

        let temp_dir = TempDir::new().unwrap();
        let config_file = temp_dir.path().join("config.json");
        let backup_dir = temp_dir.path().join("backups");

        let mut manager = ConfigManager::new(&config_file);
        manager.set_backup_dir(&backup_dir);

        // Modify config
        manager.update_config(|config| {
            config.proxy.http_port = 7070;
        }).await.unwrap();

        // Create backup
        let backup_path = manager.create_backup().await.unwrap();
        assert!(backup_path.exists());

        // Modify config again
        manager.update_config(|config| {
            config.proxy.http_port = 8080;
        }).await.unwrap();

        // Restore from backup
        manager.restore_from_backup(&backup_path).await.unwrap();

        let config = manager.get_config().await;
        assert_eq!(config.proxy.http_port, 7070);
    }

    #[tokio::test]
    async fn test_list_backups() {
        use tempfile::TempDir;

        let temp_dir = TempDir::new().unwrap();
        let config_file = temp_dir.path().join("config.json");
        let backup_dir = temp_dir.path().join("backups");

        let mut manager = ConfigManager::new(&config_file);
        manager.set_backup_dir(&backup_dir);

        // Create multiple backups
        manager.create_backup().await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;
        manager.create_backup().await.unwrap();
        tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;
        manager.create_backup().await.unwrap();

        let backups = manager.list_backups().unwrap();
        assert_eq!(backups.len(), 3);
    }

    #[tokio::test]
    async fn test_cleanup_old_backups() {
        use tempfile::TempDir;

        let temp_dir = TempDir::new().unwrap();
        let config_file = temp_dir.path().join("config.json");
        let backup_dir = temp_dir.path().join("backups");

        let mut manager = ConfigManager::new(&config_file);
        manager.set_backup_dir(&backup_dir);

        // Create 5 backups
        for _ in 0..5 {
            manager.create_backup().await.unwrap();
            tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;
        }

        // Keep only 2 most recent
        let deleted = manager.cleanup_old_backups(2).unwrap();
        assert_eq!(deleted, 3);

        let backups = manager.list_backups().unwrap();
        assert_eq!(backups.len(), 2);
    }

    #[tokio::test]
    async fn test_export_import() {
        use tempfile::TempDir;

        let temp_dir = TempDir::new().unwrap();
        let config_file = temp_dir.path().join("config.json");
        let export_file = temp_dir.path().join("export.json");

        let manager = ConfigManager::new(&config_file);

        // Modify config
        manager.update_config(|config| {
            config.proxy.http_port = 6060;
        }).await.unwrap();

        // Export
        manager.export_config(&export_file).await.unwrap();
        assert!(export_file.exists());

        // Create new manager and import
        let manager2 = ConfigManager::new(temp_dir.path().join("config2.json"));
        manager2.import_config(&export_file).await.unwrap();

        let config = manager2.get_config().await;
        assert_eq!(config.proxy.http_port, 6060);
    }
}

