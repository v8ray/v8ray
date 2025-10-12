//! Configuration Validator
//!
//! This module provides validation functionality for configurations.

use super::{Config, ProxyServerConfig, ProxyProtocol};
use crate::utils::network::{is_valid_hostname, is_valid_ip, is_valid_port};
use tracing::debug;

/// Validation result
#[derive(Debug, Clone)]
pub struct ValidationResult {
    /// Whether the validation passed
    pub valid: bool,
    /// Validation errors
    pub errors: Vec<String>,
    /// Validation warnings
    pub warnings: Vec<String>,
}

impl ValidationResult {
    /// Create a new successful validation result
    pub fn success() -> Self {
        Self {
            valid: true,
            errors: vec![],
            warnings: vec![],
        }
    }

    /// Create a new failed validation result
    pub fn failure(errors: Vec<String>) -> Self {
        Self {
            valid: false,
            errors,
            warnings: vec![],
        }
    }

    /// Add an error
    pub fn add_error(&mut self, error: String) {
        self.valid = false;
        self.errors.push(error);
    }

    /// Add a warning
    pub fn add_warning(&mut self, warning: String) {
        self.warnings.push(warning);
    }

    /// Check if validation passed
    pub fn is_valid(&self) -> bool {
        self.valid
    }
}

/// Configuration validator
pub struct ConfigValidator;

impl ConfigValidator {
    /// Validate application configuration
    pub fn validate_config(config: &Config) -> ValidationResult {
        let mut result = ValidationResult::success();

        // Validate proxy ports
        if !is_valid_port(config.proxy.http_port) {
            result.add_error(format!("Invalid HTTP port: {}", config.proxy.http_port));
        }

        if !is_valid_port(config.proxy.socks_port) {
            result.add_error(format!("Invalid SOCKS port: {}", config.proxy.socks_port));
        }

        // Check for port conflicts
        if config.proxy.http_port == config.proxy.socks_port {
            result.add_error("HTTP and SOCKS ports cannot be the same".to_string());
        }

        // Validate subscription settings
        if config.subscription.timeout == 0 {
            result.add_error("Subscription timeout cannot be zero".to_string());
        }

        if config.subscription.timeout > 300 {
            result.add_warning("Subscription timeout is very high (>300s)".to_string());
        }

        if config.subscription.auto_update_interval == 0 {
            result.add_warning("Auto update is disabled".to_string());
        }

        debug!("Config validation result: {:?}", result);
        result
    }

    /// Validate proxy server configuration
    pub fn validate_proxy_config(config: &ProxyServerConfig) -> ValidationResult {
        let mut result = ValidationResult::success();

        // Validate server address
        if config.server.is_empty() {
            result.add_error("Server address cannot be empty".to_string());
        } else if !is_valid_ip(&config.server) && !is_valid_hostname(&config.server) {
            result.add_error(format!("Invalid server address: {}", config.server));
        }

        // Validate port
        if !is_valid_port(config.port) {
            result.add_error(format!("Invalid port: {}", config.port));
        }

        // Validate name
        if config.name.is_empty() {
            result.add_error("Server name cannot be empty".to_string());
        }

        // Protocol-specific validation
        match config.protocol {
            ProxyProtocol::Vless => {
                Self::validate_vless_settings(config, &mut result);
            }
            ProxyProtocol::Vmess => {
                Self::validate_vmess_settings(config, &mut result);
            }
            ProxyProtocol::Trojan => {
                Self::validate_trojan_settings(config, &mut result);
            }
            ProxyProtocol::Shadowsocks => {
                Self::validate_shadowsocks_settings(config, &mut result);
            }
            ProxyProtocol::Http | ProxyProtocol::Socks => {
                // Basic validation is sufficient
            }
        }

        // Validate stream settings
        if let Some(ref stream) = config.stream_settings {
            if stream.security == "tls" && stream.tls_settings.is_none() {
                result.add_error("TLS security requires TLS settings".to_string());
            }

            if stream.network == "ws" && stream.ws_settings.is_none() {
                result.add_warning("WebSocket network should have WS settings".to_string());
            }

            if stream.network == "grpc" && stream.grpc_settings.is_none() {
                result.add_warning("gRPC network should have gRPC settings".to_string());
            }
        }

        debug!("Proxy config validation result: {:?}", result);
        result
    }

    /// Validate VLESS-specific settings
    fn validate_vless_settings(config: &ProxyServerConfig, result: &mut ValidationResult) {
        if !config.settings.contains_key("id") {
            result.add_error("VLESS requires 'id' (UUID) in settings".to_string());
        }
    }

    /// Validate VMess-specific settings
    fn validate_vmess_settings(config: &ProxyServerConfig, result: &mut ValidationResult) {
        if !config.settings.contains_key("id") {
            result.add_error("VMess requires 'id' (UUID) in settings".to_string());
        }

        if !config.settings.contains_key("alterId") {
            result.add_warning("VMess should have 'alterId' in settings".to_string());
        }
    }

    /// Validate Trojan-specific settings
    fn validate_trojan_settings(config: &ProxyServerConfig, result: &mut ValidationResult) {
        if !config.settings.contains_key("password") {
            result.add_error("Trojan requires 'password' in settings".to_string());
        }
    }

    /// Validate Shadowsocks-specific settings
    fn validate_shadowsocks_settings(config: &ProxyServerConfig, result: &mut ValidationResult) {
        if !config.settings.contains_key("method") {
            result.add_error("Shadowsocks requires 'method' in settings".to_string());
        }

        if !config.settings.contains_key("password") {
            result.add_error("Shadowsocks requires 'password' in settings".to_string());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use std::collections::HashMap;

    #[test]
    fn test_validate_config_success() {
        let config = Config::default();
        let result = ConfigValidator::validate_config(&config);
        assert!(result.is_valid());
    }

    #[test]
    fn test_validate_config_invalid_port() {
        let mut config = Config::default();
        config.proxy.http_port = 0;
        
        let result = ConfigValidator::validate_config(&config);
        assert!(!result.is_valid());
        assert!(!result.errors.is_empty());
    }

    #[test]
    fn test_validate_config_port_conflict() {
        let mut config = Config::default();
        config.proxy.http_port = 8080;
        config.proxy.socks_port = 8080;
        
        let result = ConfigValidator::validate_config(&config);
        assert!(!result.is_valid());
    }

    #[test]
    fn test_validate_proxy_config_success() {
        let mut settings = HashMap::new();
        settings.insert("id".to_string(), serde_json::json!("uuid-here"));
        
        let config = ProxyServerConfig {
            id: "test".to_string(),
            name: "Test Server".to_string(),
            server: "example.com".to_string(),
            port: 443,
            protocol: ProxyProtocol::Vless,
            settings,
            stream_settings: None,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        let result = ConfigValidator::validate_proxy_config(&config);
        assert!(result.is_valid());
    }

    #[test]
    fn test_validate_proxy_config_empty_server() {
        let config = ProxyServerConfig {
            id: "test".to_string(),
            name: "Test Server".to_string(),
            server: "".to_string(),
            port: 443,
            protocol: ProxyProtocol::Vless,
            settings: HashMap::new(),
            stream_settings: None,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        let result = ConfigValidator::validate_proxy_config(&config);
        assert!(!result.is_valid());
    }

    #[test]
    fn test_validate_vless_missing_id() {
        let config = ProxyServerConfig {
            id: "test".to_string(),
            name: "Test Server".to_string(),
            server: "example.com".to_string(),
            port: 443,
            protocol: ProxyProtocol::Vless,
            settings: HashMap::new(),
            stream_settings: None,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        
        let result = ConfigValidator::validate_proxy_config(&config);
        assert!(!result.is_valid());
    }
}

