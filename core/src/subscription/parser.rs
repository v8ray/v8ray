//! Subscription Parser
//!
//! This module provides parsers for different subscription formats including
//! Base64, V2Ray JSON, and Clash YAML formats.

use crate::config::parser::ConfigParser;
use crate::config::ProxyServerConfig;
use crate::error::{SubscriptionError, SubscriptionResult};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use serde_json::Value;
use std::collections::HashMap;
use tracing::{debug, info, warn};
use uuid::Uuid;

/// Subscription format type
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SubscriptionFormat {
    /// Base64 encoded list of proxy URLs
    Base64,
    /// V2Ray JSON format
    V2RayJson,
    /// Clash YAML format
    ClashYaml,
    /// Auto-detect format
    Auto,
}

/// Subscription parser
pub struct SubscriptionParser;

impl SubscriptionParser {
    /// Parse subscription content with auto-detection
    pub fn parse(content: &str) -> SubscriptionResult<Vec<ProxyServerConfig>> {
        Self::parse_with_format(content, SubscriptionFormat::Auto)
    }

    /// Parse subscription content with specified format
    pub fn parse_with_format(
        content: &str,
        format: SubscriptionFormat,
    ) -> SubscriptionResult<Vec<ProxyServerConfig>> {
        let content = content.trim();
        if content.is_empty() {
            return Err(SubscriptionError::Empty);
        }

        match format {
            SubscriptionFormat::Base64 => Self::parse_base64(content),
            SubscriptionFormat::V2RayJson => Self::parse_v2ray_json(content),
            SubscriptionFormat::ClashYaml => Self::parse_clash_yaml(content),
            SubscriptionFormat::Auto => Self::auto_detect_and_parse(content),
        }
    }

    /// Auto-detect subscription format and parse
    fn auto_detect_and_parse(content: &str) -> SubscriptionResult<Vec<ProxyServerConfig>> {
        debug!("Auto-detecting subscription format");

        // Try JSON first
        if content.trim_start().starts_with('{') || content.trim_start().starts_with('[') {
            info!("Detected V2Ray JSON format");
            return Self::parse_v2ray_json(content);
        }

        // Try YAML
        if content.contains("proxies:") || content.contains("proxy-groups:") {
            info!("Detected Clash YAML format");
            return Self::parse_clash_yaml(content);
        }

        // Default to Base64
        info!("Defaulting to Base64 format");
        Self::parse_base64(content)
    }

    /// Parse Base64 encoded subscription
    ///
    /// Format: Base64 encoded list of proxy URLs, one per line
    /// Supported protocols: vmess://, vless://, trojan://, ss://
    pub fn parse_base64(content: &str) -> SubscriptionResult<Vec<ProxyServerConfig>> {
        debug!("Parsing Base64 subscription");

        // Try to decode as Base64
        let decoded = match BASE64.decode(content.trim()) {
            Ok(bytes) => match String::from_utf8(bytes) {
                Ok(s) => s,
                Err(_) => {
                    // If not valid Base64, treat as plain text
                    content.to_string()
                }
            },
            Err(_) => {
                // If not valid Base64, treat as plain text
                content.to_string()
            }
        };

        let mut servers = Vec::new();
        let mut errors = Vec::new();

        // Parse each line as a proxy URL
        for (line_num, line) in decoded.lines().enumerate() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }

            match ConfigParser::parse_url(line) {
                Ok(server) => {
                    debug!("Parsed server: {}", server.name);
                    servers.push(server);
                }
                Err(e) => {
                    warn!("Failed to parse line {}: {} - {}", line_num + 1, line, e);
                    errors.push(format!("Line {}: {}", line_num + 1, e));
                }
            }
        }

        if servers.is_empty() {
            if errors.is_empty() {
                return Err(SubscriptionError::Empty);
            } else {
                return Err(SubscriptionError::Parse(format!(
                    "Failed to parse any servers. Errors: {}",
                    errors.join("; ")
                )));
            }
        }

        info!("Parsed {} servers from Base64 subscription", servers.len());
        Ok(servers)
    }

    /// Parse V2Ray JSON format subscription
    ///
    /// Format: JSON object or array containing server configurations
    pub fn parse_v2ray_json(content: &str) -> SubscriptionResult<Vec<ProxyServerConfig>> {
        debug!("Parsing V2Ray JSON subscription");

        let json: Value = serde_json::from_str(content)
            .map_err(|e| SubscriptionError::Parse(format!("Invalid JSON: {}", e)))?;

        let mut servers = Vec::new();

        // Handle both array and object formats
        let server_list = if json.is_array() {
            json.as_array().unwrap()
        } else if let Some(outbounds) = json.get("outbounds") {
            outbounds
                .as_array()
                .ok_or_else(|| SubscriptionError::Parse("Invalid outbounds format".to_string()))?
        } else {
            return Err(SubscriptionError::UnsupportedFormat(
                "Unknown V2Ray JSON format".to_string(),
            ));
        };

        for (idx, server_json) in server_list.iter().enumerate() {
            match Self::parse_v2ray_server(server_json) {
                Ok(server) => {
                    debug!("Parsed V2Ray server: {}", server.name);
                    servers.push(server);
                }
                Err(e) => {
                    warn!("Failed to parse server {}: {}", idx, e);
                }
            }
        }

        if servers.is_empty() {
            return Err(SubscriptionError::Empty);
        }

        info!("Parsed {} servers from V2Ray JSON", servers.len());
        Ok(servers)
    }

    /// Parse a single V2Ray server from JSON
    fn parse_v2ray_server(json: &Value) -> SubscriptionResult<ProxyServerConfig> {
        let protocol = json["protocol"]
            .as_str()
            .ok_or_else(|| SubscriptionError::Parse("Missing protocol field".to_string()))?;

        let settings = json
            .get("settings")
            .ok_or_else(|| SubscriptionError::Parse("Missing settings field".to_string()))?;

        let vnext = settings
            .get("vnext")
            .and_then(|v| v.as_array())
            .and_then(|arr| arr.first())
            .ok_or_else(|| SubscriptionError::Parse("Missing vnext field".to_string()))?;

        let server = vnext["address"]
            .as_str()
            .ok_or_else(|| SubscriptionError::Parse("Missing address field".to_string()))?
            .to_string();

        let port = vnext["port"]
            .as_u64()
            .ok_or_else(|| SubscriptionError::Parse("Missing port field".to_string()))?
            as u16;

        let name = json["tag"].as_str().unwrap_or("V2Ray Server").to_string();

        let protocol_enum = match protocol {
            "vmess" => crate::config::ProxyProtocol::Vmess,
            "vless" => crate::config::ProxyProtocol::Vless,
            "trojan" => crate::config::ProxyProtocol::Trojan,
            "shadowsocks" => crate::config::ProxyProtocol::Shadowsocks,
            _ => {
                return Err(SubscriptionError::UnsupportedFormat(format!(
                    "Unsupported protocol: {}",
                    protocol
                )))
            }
        };

        Ok(ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name,
            server,
            port,
            protocol: protocol_enum,
            settings: HashMap::new(),
            stream_settings: None,
            tags: vec![],
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        })
    }

    /// Parse Clash YAML format subscription
    ///
    /// Format: YAML with proxies list
    pub fn parse_clash_yaml(content: &str) -> SubscriptionResult<Vec<ProxyServerConfig>> {
        debug!("Parsing Clash YAML subscription");

        let yaml: serde_yaml::Value = serde_yaml::from_str(content)
            .map_err(|e| SubscriptionError::Parse(format!("Invalid YAML: {}", e)))?;

        let proxies = yaml
            .get("proxies")
            .ok_or_else(|| SubscriptionError::Parse("Missing proxies field".to_string()))?
            .as_sequence()
            .ok_or_else(|| SubscriptionError::Parse("Invalid proxies format".to_string()))?;

        let mut servers = Vec::new();

        for (idx, proxy) in proxies.iter().enumerate() {
            match Self::parse_clash_proxy(proxy) {
                Ok(server) => {
                    debug!("Parsed Clash proxy: {}", server.name);
                    servers.push(server);
                }
                Err(e) => {
                    warn!("Failed to parse proxy {}: {}", idx, e);
                }
            }
        }

        if servers.is_empty() {
            return Err(SubscriptionError::Empty);
        }

        info!("Parsed {} servers from Clash YAML", servers.len());
        Ok(servers)
    }

    /// Parse a single Clash proxy from YAML
    fn parse_clash_proxy(yaml: &serde_yaml::Value) -> SubscriptionResult<ProxyServerConfig> {
        let name = yaml["name"].as_str().unwrap_or("Clash Server").to_string();

        let server = yaml["server"]
            .as_str()
            .ok_or_else(|| SubscriptionError::Parse("Missing server field".to_string()))?
            .to_string();

        let port = yaml["port"]
            .as_u64()
            .ok_or_else(|| SubscriptionError::Parse("Missing port field".to_string()))?
            as u16;

        let proxy_type = yaml["type"]
            .as_str()
            .ok_or_else(|| SubscriptionError::Parse("Missing type field".to_string()))?;

        let protocol = match proxy_type {
            "vmess" => crate::config::ProxyProtocol::Vmess,
            "vless" => crate::config::ProxyProtocol::Vless,
            "trojan" => crate::config::ProxyProtocol::Trojan,
            "ss" | "shadowsocks" => crate::config::ProxyProtocol::Shadowsocks,
            _ => {
                return Err(SubscriptionError::UnsupportedFormat(format!(
                    "Unsupported proxy type: {}",
                    proxy_type
                )))
            }
        };

        Ok(ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name,
            server,
            port,
            protocol,
            settings: HashMap::new(),
            stream_settings: None,
            tags: vec![],
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_base64_subscription() {
        // Create a simple Base64 encoded subscription
        let urls = "vless://uuid-test@example.com:443?type=tcp&security=none#Test1\nvless://uuid-test2@example2.com:443?type=tcp&security=none#Test2";
        let encoded = BASE64.encode(urls);

        let result = SubscriptionParser::parse_base64(&encoded);
        assert!(result.is_ok());

        let servers = result.unwrap();
        assert_eq!(servers.len(), 2);
        assert_eq!(servers[0].server, "example.com");
        assert_eq!(servers[1].server, "example2.com");
    }

    #[test]
    fn test_parse_plain_text_urls() {
        let urls = "vless://uuid-test@example.com:443?type=tcp&security=none#Test1\nvless://uuid-test2@example2.com:443?type=tcp&security=none#Test2";

        let result = SubscriptionParser::parse_base64(urls);
        assert!(result.is_ok());

        let servers = result.unwrap();
        assert_eq!(servers.len(), 2);
    }

    #[test]
    fn test_parse_empty_subscription() {
        let result = SubscriptionParser::parse_base64("");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), SubscriptionError::Empty));
    }

    #[test]
    fn test_parse_v2ray_json() {
        let json = r#"{
            "outbounds": [
                {
                    "protocol": "vmess",
                    "tag": "Test Server",
                    "settings": {
                        "vnext": [
                            {
                                "address": "example.com",
                                "port": 443
                            }
                        ]
                    }
                }
            ]
        }"#;

        let result = SubscriptionParser::parse_v2ray_json(json);
        assert!(result.is_ok());

        let servers = result.unwrap();
        assert_eq!(servers.len(), 1);
        assert_eq!(servers[0].server, "example.com");
        assert_eq!(servers[0].port, 443);
    }

    #[test]
    fn test_parse_clash_yaml() {
        let yaml = r#"
proxies:
  - name: Test Server 1
    type: vmess
    server: example.com
    port: 443
  - name: Test Server 2
    type: vless
    server: example2.com
    port: 8443
"#;

        let result = SubscriptionParser::parse_clash_yaml(yaml);
        assert!(result.is_ok());

        let servers = result.unwrap();
        assert_eq!(servers.len(), 2);
        assert_eq!(servers[0].name, "Test Server 1");
        assert_eq!(servers[1].name, "Test Server 2");
    }

    #[test]
    fn test_auto_detect_json() {
        let json = r#"{
            "outbounds": [
                {
                    "protocol": "vmess",
                    "tag": "Test",
                    "settings": {
                        "vnext": [{"address": "example.com", "port": 443}]
                    }
                }
            ]
        }"#;

        let result = SubscriptionParser::parse(json);
        assert!(result.is_ok());
    }

    #[test]
    fn test_auto_detect_yaml() {
        let yaml = r#"
proxies:
  - name: Test
    type: vmess
    server: example.com
    port: 443
"#;

        let result = SubscriptionParser::parse(yaml);
        assert!(result.is_ok());
    }

    #[test]
    fn test_auto_detect_base64() {
        let urls = "vless://uuid@example.com:443?type=tcp#Test";
        let encoded = BASE64.encode(urls);

        let result = SubscriptionParser::parse(&encoded);
        assert!(result.is_ok());
    }

    #[test]
    fn test_parse_with_comments() {
        let urls = "# Comment line\nvless://uuid@example.com:443?type=tcp#Test\n# Another comment";

        let result = SubscriptionParser::parse_base64(urls);
        assert!(result.is_ok());

        let servers = result.unwrap();
        assert_eq!(servers.len(), 1);
    }

    #[test]
    fn test_parse_invalid_json() {
        let invalid_json = "{ invalid json }";
        let result = SubscriptionParser::parse_v2ray_json(invalid_json);
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_invalid_yaml() {
        let invalid_yaml = "invalid: yaml: structure:";
        let result = SubscriptionParser::parse_clash_yaml(invalid_yaml);
        assert!(result.is_err());
    }
}
