//! Configuration Parser
//!
//! This module provides parsing functionality for various configuration formats.

use super::{ProxyProtocol, ProxyServerConfig, StreamSettings, TlsSettings, WsSettings};
use crate::error::{ConfigError, ConfigResult};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use chrono::Utc;
use serde_json::Value;
use std::collections::HashMap;
use tracing::{debug, warn};
use url::Url;
use uuid::Uuid;

/// Configuration parser
pub struct ConfigParser;

impl ConfigParser {
    /// Parse a proxy URL into a ProxyServerConfig
    ///
    /// Supported formats:
    /// - vmess://base64_encoded_json
    /// - vless://uuid@server:port?params
    /// - trojan://password@server:port?params
    /// - ss://base64_encoded_method_password@server:port
    pub fn parse_url(url: &str) -> ConfigResult<ProxyServerConfig> {
        debug!("Parsing proxy URL");

        let url_lower = url.to_lowercase();

        if url_lower.starts_with("vmess://") {
            Self::parse_vmess_url(url)
        } else if url_lower.starts_with("vless://") {
            Self::parse_vless_url(url)
        } else if url_lower.starts_with("trojan://") {
            Self::parse_trojan_url(url)
        } else if url_lower.starts_with("ss://") {
            Self::parse_shadowsocks_url(url)
        } else {
            Err(ConfigError::InvalidProtocol(
                "Unsupported protocol".to_string(),
            ))
        }
    }

    /// Parse VMess URL
    fn parse_vmess_url(url: &str) -> ConfigResult<ProxyServerConfig> {
        let encoded = url
            .strip_prefix("vmess://")
            .ok_or_else(|| ConfigError::InvalidUrl("Invalid VMess URL format".to_string()))?;

        let decoded = BASE64
            .decode(encoded)
            .map_err(|e| ConfigError::InvalidUrl(format!("Base64 decode failed: {}", e)))?;

        let json_str = String::from_utf8(decoded)
            .map_err(|e| ConfigError::InvalidUrl(format!("UTF-8 decode failed: {}", e)))?;

        let json: Value = serde_json::from_str(&json_str)
            .map_err(|e| ConfigError::InvalidUrl(format!("JSON parse failed: {}", e)))?;

        let server = json["add"]
            .as_str()
            .ok_or_else(|| ConfigError::MissingField("add".to_string()))?
            .to_string();

        // Port can be either a number or a string
        let port = if let Some(port_num) = json["port"].as_u64() {
            port_num as u16
        } else if let Some(port_str) = json["port"].as_str() {
            port_str
                .parse::<u16>()
                .map_err(|_| ConfigError::InvalidUrl(format!("Invalid port: {}", port_str)))?
        } else {
            return Err(ConfigError::MissingField("port".to_string()));
        };

        let id = json["id"]
            .as_str()
            .ok_or_else(|| ConfigError::MissingField("id".to_string()))?
            .to_string();

        let name = json["ps"].as_str().unwrap_or("VMess Server").to_string();

        let mut settings = HashMap::new();
        settings.insert("id".to_string(), serde_json::json!(id));
        settings.insert(
            "alterId".to_string(),
            serde_json::json!(json["aid"].as_u64().unwrap_or(0)),
        );

        let mut stream_settings = None;
        if let Some(net) = json["net"].as_str() {
            let mut stream = StreamSettings {
                network: net.to_string(),
                security: json["tls"].as_str().unwrap_or("none").to_string(),
                tls_settings: None,
                tcp_settings: None,
                ws_settings: None,
                http_settings: None,
                quic_settings: None,
                grpc_settings: None,
            };

            if stream.security == "tls" {
                stream.tls_settings = Some(TlsSettings {
                    server_name: json["sni"].as_str().map(|s| s.to_string()),
                    allow_insecure: false,
                    alpn: vec![],
                    fingerprint: None,
                });
            }

            if net == "ws" {
                let mut headers = HashMap::new();
                if let Some(host) = json["host"].as_str() {
                    headers.insert("Host".to_string(), host.to_string());
                }

                stream.ws_settings = Some(WsSettings {
                    path: json["path"].as_str().unwrap_or("/").to_string(),
                    headers,
                });
            }

            stream_settings = Some(stream);
        }

        Ok(ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name,
            server,
            port,
            protocol: ProxyProtocol::Vmess,
            settings,
            stream_settings,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        })
    }

    /// Parse VLESS URL
    fn parse_vless_url(url: &str) -> ConfigResult<ProxyServerConfig> {
        let url = Url::parse(url)
            .map_err(|e| ConfigError::InvalidUrl(format!("URL parse failed: {}", e)))?;

        let id = url.username().to_string();
        if id.is_empty() {
            return Err(ConfigError::MissingField("id".to_string()));
        }

        let server = url
            .host_str()
            .ok_or_else(|| ConfigError::MissingField("host".to_string()))?
            .to_string();

        let port = url
            .port()
            .ok_or_else(|| ConfigError::MissingField("port".to_string()))?;

        let query_pairs: HashMap<String, String> = url.query_pairs().into_owned().collect();

        let name = query_pairs
            .get("remarks")
            .or_else(|| query_pairs.get("name"))
            .cloned()
            .unwrap_or_else(|| "VLESS Server".to_string());

        let mut settings = HashMap::new();
        settings.insert("id".to_string(), serde_json::json!(id));

        if let Some(encryption) = query_pairs.get("encryption") {
            settings.insert("encryption".to_string(), serde_json::json!(encryption));
        }

        let mut stream_settings = None;
        if let Some(network) = query_pairs.get("type") {
            let security = query_pairs
                .get("security")
                .map(|s| s.as_str())
                .unwrap_or("none");

            let mut stream = StreamSettings {
                network: network.clone(),
                security: security.to_string(),
                tls_settings: None,
                tcp_settings: None,
                ws_settings: None,
                http_settings: None,
                quic_settings: None,
                grpc_settings: None,
            };

            if security == "tls" {
                stream.tls_settings = Some(TlsSettings {
                    server_name: query_pairs.get("sni").cloned(),
                    allow_insecure: query_pairs.get("allowInsecure") == Some(&"1".to_string()),
                    alpn: query_pairs
                        .get("alpn")
                        .map(|s| s.split(',').map(|s| s.to_string()).collect())
                        .unwrap_or_default(),
                    fingerprint: query_pairs.get("fp").cloned(),
                });
            }

            if network == "ws" {
                let mut headers = HashMap::new();
                if let Some(host) = query_pairs.get("host") {
                    headers.insert("Host".to_string(), host.clone());
                }

                stream.ws_settings = Some(WsSettings {
                    path: query_pairs
                        .get("path")
                        .cloned()
                        .unwrap_or_else(|| "/".to_string()),
                    headers,
                });
            }

            stream_settings = Some(stream);
        }

        Ok(ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name,
            server,
            port,
            protocol: ProxyProtocol::Vless,
            settings,
            stream_settings,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        })
    }

    /// Parse Trojan URL
    fn parse_trojan_url(url: &str) -> ConfigResult<ProxyServerConfig> {
        let url = Url::parse(url)
            .map_err(|e| ConfigError::InvalidUrl(format!("URL parse failed: {}", e)))?;

        let password = url.username().to_string();
        if password.is_empty() {
            return Err(ConfigError::MissingField("password".to_string()));
        }

        let server = url
            .host_str()
            .ok_or_else(|| ConfigError::MissingField("host".to_string()))?
            .to_string();

        let port = url
            .port()
            .ok_or_else(|| ConfigError::MissingField("port".to_string()))?;

        let query_pairs: HashMap<String, String> = url.query_pairs().into_owned().collect();

        let name = url
            .fragment()
            .or_else(|| query_pairs.get("name").map(|s| s.as_str()))
            .unwrap_or("Trojan Server")
            .to_string();

        let mut settings = HashMap::new();
        settings.insert("password".to_string(), serde_json::json!(password));

        Ok(ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name,
            server,
            port,
            protocol: ProxyProtocol::Trojan,
            settings,
            stream_settings: None,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        })
    }

    /// Parse Shadowsocks URL
    fn parse_shadowsocks_url(url: &str) -> ConfigResult<ProxyServerConfig> {
        warn!("Shadowsocks URL parsing is simplified");

        // ss://base64(method:password)@server:port#name
        let url = Url::parse(url)
            .map_err(|e| ConfigError::InvalidUrl(format!("URL parse failed: {}", e)))?;

        let server = url
            .host_str()
            .ok_or_else(|| ConfigError::MissingField("host".to_string()))?
            .to_string();

        let port = url
            .port()
            .ok_or_else(|| ConfigError::MissingField("port".to_string()))?;

        let name = url.fragment().unwrap_or("Shadowsocks Server").to_string();

        // For now, return a basic config
        // Full implementation would decode the method:password from username
        let mut settings = HashMap::new();
        settings.insert("method".to_string(), serde_json::json!("aes-256-gcm"));
        settings.insert("password".to_string(), serde_json::json!("password"));

        Ok(ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name,
            server,
            port,
            protocol: ProxyProtocol::Shadowsocks,
            settings,
            stream_settings: None,
            tags: vec![],
            created_at: Utc::now(),
            updated_at: Utc::now(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_vless_url() {
        let url = "vless://uuid-here@example.com:443?type=ws&security=tls&path=/ws#Test%20Server";
        let result = ConfigParser::parse_url(url);
        assert!(result.is_ok());

        let config = result.unwrap();
        assert_eq!(config.protocol, ProxyProtocol::Vless);
        assert_eq!(config.server, "example.com");
        assert_eq!(config.port, 443);
    }

    #[test]
    fn test_parse_trojan_url() {
        let url = "trojan://password@example.com:443#Test%20Server";
        let result = ConfigParser::parse_url(url);
        assert!(result.is_ok());

        let config = result.unwrap();
        assert_eq!(config.protocol, ProxyProtocol::Trojan);
        assert_eq!(config.server, "example.com");
    }

    #[test]
    fn test_parse_invalid_url() {
        let url = "invalid://test";
        let result = ConfigParser::parse_url(url);
        assert!(result.is_err());
    }
}
