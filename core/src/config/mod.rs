//! Configuration Management Module
//!
//! This module handles all configuration-related functionality including
//! loading, saving, validation, and conversion of configuration data.

pub mod manager;
pub mod parser;
pub mod validator;

use crate::error::ConfigError;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;

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
    /// Simple mode - minimal UI
    Simple,
    /// Advanced mode - full features
    Advanced,
}

/// Theme setting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Theme {
    /// Light theme
    Light,
    /// Dark theme
    Dark,
    /// Follow system theme
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
    /// Direct connection (no proxy)
    Direct,
    /// Always use proxy
    Proxy,
    /// Auto mode (PAC/rules)
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

/// Proxy server configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProxyServerConfig {
    /// Unique identifier
    pub id: String,
    /// Display name
    pub name: String,
    /// Server address
    pub server: String,
    /// Server port
    pub port: u16,
    /// Protocol type
    pub protocol: ProxyProtocol,
    /// Protocol-specific settings
    pub settings: HashMap<String, serde_json::Value>,
    /// Stream settings (transport)
    pub stream_settings: Option<StreamSettings>,
    /// Tags for categorization
    pub tags: Vec<String>,
    /// Creation timestamp
    pub created_at: DateTime<Utc>,
    /// Last update timestamp
    pub updated_at: DateTime<Utc>,
}

/// Proxy protocol types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ProxyProtocol {
    /// VLESS protocol
    Vless,
    /// VMess protocol
    Vmess,
    /// Trojan protocol
    Trojan,
    /// Shadowsocks protocol
    Shadowsocks,
    /// HTTP proxy
    Http,
    /// SOCKS proxy
    Socks,
}

/// Stream settings for transport
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamSettings {
    /// Network type (tcp, kcp, ws, http, quic, grpc)
    pub network: String,
    /// Security type (none, tls, reality)
    pub security: String,
    /// TLS settings
    pub tls_settings: Option<TlsSettings>,
    /// TCP settings
    pub tcp_settings: Option<serde_json::Value>,
    /// WebSocket settings
    pub ws_settings: Option<WsSettings>,
    /// HTTP/2 settings
    pub http_settings: Option<serde_json::Value>,
    /// QUIC settings
    pub quic_settings: Option<serde_json::Value>,
    /// gRPC settings
    pub grpc_settings: Option<GrpcSettings>,
}

/// TLS settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TlsSettings {
    /// Server name indication
    pub server_name: Option<String>,
    /// Allow insecure connections
    pub allow_insecure: bool,
    /// ALPN protocols
    pub alpn: Vec<String>,
    /// Fingerprint
    pub fingerprint: Option<String>,
}

/// WebSocket settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WsSettings {
    /// WebSocket path
    pub path: String,
    /// Custom headers
    pub headers: HashMap<String, String>,
}

/// gRPC settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrpcSettings {
    /// Service name
    pub service_name: String,
    /// Multi mode
    pub multi_mode: bool,
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
                user_agent: crate::version::user_agent(),
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
        if self.proxy.http_port == 0 {
            return Err(ConfigError::Validation("Invalid HTTP port".to_string()));
        }
        if self.proxy.socks_port == 0 {
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
