//! Configuration Management Module
//!
//! This module handles all configuration-related functionality including
//! loading, saving, validation, and conversion of configuration data.

use serde::{Deserialize, Serialize};
use std::path::Path;
use thiserror::Error;

/// Configuration errors
#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
    #[error("Validation error: {0}")]
    Validation(String),
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
}

/// Main configuration structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    /// Application settings
    pub app: AppConfig,
    /// Proxy settings
    pub proxy: ProxyConfig,
    /// Subscription settings
    pub subscription: SubscriptionConfig,
}

/// Application configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    /// Application mode (simple/advanced)
    pub mode: AppMode,
    /// Language setting
    pub language: String,
    /// Theme setting
    pub theme: Theme,
    /// Auto start setting
    pub auto_start: bool,
}

/// Application mode
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AppMode {
    Simple,
    Advanced,
}

/// Theme setting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Theme {
    Light,
    Dark,
    System,
}

/// Proxy configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProxyConfig {
    /// Current proxy mode
    pub mode: ProxyMode,
    /// System proxy settings
    pub system_proxy: bool,
    /// Local HTTP port
    pub http_port: u16,
    /// Local SOCKS port
    pub socks_port: u16,
}

/// Proxy mode
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ProxyMode {
    Direct,
    Proxy,
    Auto,
}

/// Subscription configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubscriptionConfig {
    /// Auto update interval in hours
    pub auto_update_interval: u32,
    /// User agent for subscription requests
    pub user_agent: String,
    /// Request timeout in seconds
    pub timeout: u32,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            app: AppConfig {
                mode: AppMode::Simple,
                language: "en".to_string(),
                theme: Theme::System,
                auto_start: false,
            },
            proxy: ProxyConfig {
                mode: ProxyMode::Auto,
                system_proxy: false,
                http_port: 8080,
                socks_port: 1080,
            },
            subscription: SubscriptionConfig {
                auto_update_interval: 24,
                user_agent: "V8Ray/1.0".to_string(),
                timeout: 30,
            },
        }
    }
}

impl Config {
    /// Load configuration from file
    pub fn load<P: AsRef<Path>>(path: P) -> Result<Self, ConfigError> {
        let content = std::fs::read_to_string(path)?;
        let config: Config = serde_json::from_str(&content)?;
        config.validate()?;
        Ok(config)
    }

    /// Save configuration to file
    pub fn save<P: AsRef<Path>>(&self, path: P) -> Result<(), ConfigError> {
        self.validate()?;
        let content = serde_json::to_string_pretty(self)?;
        std::fs::write(path, content)?;
        Ok(())
    }

    /// Validate configuration
    pub fn validate(&self) -> Result<(), ConfigError> {
        if self.proxy.http_port == 0 || self.proxy.http_port > 65535 {
            return Err(ConfigError::Validation("Invalid HTTP port".to_string()));
        }
        if self.proxy.socks_port == 0 || self.proxy.socks_port > 65535 {
            return Err(ConfigError::Validation("Invalid SOCKS port".to_string()));
        }
        if self.subscription.timeout == 0 {
            return Err(ConfigError::Validation("Invalid timeout".to_string()));
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;

    #[test]
    fn test_default_config() {
        let config = Config::default();
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_config_save_load() {
        let config = Config::default();
        let temp_file = NamedTempFile::new().unwrap();
        
        config.save(temp_file.path()).unwrap();
        let loaded_config = Config::load(temp_file.path()).unwrap();
        
        assert_eq!(config.app.mode as u8, loaded_config.app.mode as u8);
        assert_eq!(config.proxy.http_port, loaded_config.proxy.http_port);
    }

    #[test]
    fn test_config_validation() {
        let mut config = Config::default();
        config.proxy.http_port = 0;
        assert!(config.validate().is_err());
    }
}
