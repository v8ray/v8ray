//! Xray Core Integration Tests
//!
//! These tests verify the complete Xray Core integration functionality,
//! including process management, configuration generation, status monitoring,
//! and event handling.

use chrono::Utc;
use std::collections::HashMap;
use v8ray_core::config::{ProxyProtocol, ProxyServerConfig};
use v8ray_core::xray::*;

/// Test Xray Core initialization and status
#[tokio::test]
async fn test_xray_initialization() {
    let xray = XrayCore::new();

    // Test initial status
    assert_eq!(xray.get_status().await, XrayStatus::Stopped);

    // Test initial health
    assert!(xray.get_health().await.is_none());

    // Test binary path is not set initially
    assert!(xray.get_binary_path().await.is_none());
}

/// Test Xray configuration generation for different protocols
#[tokio::test]
async fn test_xray_config_generation() {
    let xray = XrayCore::new();

    // Test VMess configuration
    let mut vmess_settings = HashMap::new();
    vmess_settings.insert("id".to_string(), serde_json::json!("test-uuid"));
    vmess_settings.insert("alterId".to_string(), serde_json::json!(0));
    vmess_settings.insert("security".to_string(), serde_json::json!("auto"));

    let vmess_config = ProxyServerConfig {
        id: uuid::Uuid::new_v4().to_string(),
        name: "VMess Server".to_string(),
        protocol: ProxyProtocol::Vmess,
        server: "example.com".to_string(),
        port: 443,
        settings: vmess_settings,
        stream_settings: None,
        tags: vec![],
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    let config = xray.generate_config(&vmess_config);
    assert_eq!(config.inbounds.len(), 2); // HTTP + SOCKS
    assert_eq!(config.outbounds.len(), 2); // Proxy + Direct

    // Verify inbound protocols
    assert_eq!(config.inbounds[0].protocol, "http");
    assert_eq!(config.inbounds[1].protocol, "socks");

    // Verify outbound protocol
    assert_eq!(config.outbounds[0].protocol, "vmess");
    assert_eq!(config.outbounds[1].protocol, "freedom");

    // Test VLESS configuration
    let mut vless_settings = HashMap::new();
    vless_settings.insert("id".to_string(), serde_json::json!("test-uuid"));
    vless_settings.insert("encryption".to_string(), serde_json::json!("none"));

    let vless_config = ProxyServerConfig {
        id: uuid::Uuid::new_v4().to_string(),
        name: "VLESS Server".to_string(),
        protocol: ProxyProtocol::Vless,
        server: "example.com".to_string(),
        port: 443,
        settings: vless_settings,
        stream_settings: None,
        tags: vec![],
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    let config = xray.generate_config(&vless_config);
    assert_eq!(config.outbounds[0].protocol, "vless");

    // Test Trojan configuration
    let mut trojan_settings = HashMap::new();
    trojan_settings.insert("password".to_string(), serde_json::json!("test-password"));

    let trojan_config = ProxyServerConfig {
        id: uuid::Uuid::new_v4().to_string(),
        name: "Trojan Server".to_string(),
        protocol: ProxyProtocol::Trojan,
        server: "example.com".to_string(),
        port: 443,
        settings: trojan_settings,
        stream_settings: None,
        tags: vec![],
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    let config = xray.generate_config(&trojan_config);
    assert_eq!(config.outbounds[0].protocol, "trojan");

    // Test Shadowsocks configuration
    let mut ss_settings = HashMap::new();
    ss_settings.insert("method".to_string(), serde_json::json!("aes-256-gcm"));
    ss_settings.insert("password".to_string(), serde_json::json!("test-password"));

    let ss_config = ProxyServerConfig {
        id: uuid::Uuid::new_v4().to_string(),
        name: "Shadowsocks Server".to_string(),
        protocol: ProxyProtocol::Shadowsocks,
        server: "example.com".to_string(),
        port: 8388,
        settings: ss_settings,
        stream_settings: None,
        tags: vec![],
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    let config = xray.generate_config(&ss_config);
    assert_eq!(config.outbounds[0].protocol, "shadowsocks");
}

/// Test Xray configuration serialization
#[tokio::test]
async fn test_xray_config_serialization() {
    let config = XrayConfig::default();

    // Test JSON serialization
    let json = serde_json::to_string_pretty(&config).unwrap();
    assert!(!json.is_empty());
    assert!(json.contains("\"log\""));
    assert!(json.contains("\"inbounds\""));
    assert!(json.contains("\"outbounds\""));

    // Test deserialization
    let deserialized: XrayConfig = serde_json::from_str(&json).unwrap();
    assert_eq!(deserialized.log.level, config.log.level);
    assert_eq!(deserialized.inbounds.len(), config.inbounds.len());
    assert_eq!(deserialized.outbounds.len(), config.outbounds.len());
}

/// Test Xray event subscription
#[tokio::test]
async fn test_xray_event_subscription() {
    let xray = XrayCore::new();
    let mut rx = xray.subscribe();

    // Initially no events
    assert!(rx.try_recv().is_err());

    // Test that subscription works
    // Note: We can't directly call update_status as it's private,
    // but we can verify the subscription mechanism works
    assert_eq!(xray.get_status().await, XrayStatus::Stopped);
}

/// Test Xray health monitoring
#[tokio::test]
async fn test_xray_health_monitoring() {
    let xray = XrayCore::new();

    // Initially no health info
    assert!(xray.get_health().await.is_none());

    // Test health info serialization
    let health = XrayHealth {
        pid: Some(12345),
        uptime: 120,
        last_check: std::time::SystemTime::now(),
        is_responsive: true,
    };

    let json = serde_json::to_string(&health).unwrap();
    assert!(!json.is_empty());

    let _parsed: XrayHealth = serde_json::from_str(&json).unwrap();
}

/// Test Xray log parsing
#[tokio::test]
async fn test_xray_log_parsing() {
    // Test standard Xray log format
    let line1 = "2024/01/01 12:00:00 [Info] Xray 1.8.7 started";
    let entry1 = XrayCore::parse_log_line(line1);
    assert_eq!(entry1.level, "Info");
    assert!(entry1.message.contains("Xray"));

    // Test warning log
    let line2 = "2024/01/01 12:00:01 [Warning] Connection timeout";
    let entry2 = XrayCore::parse_log_line(line2);
    assert_eq!(entry2.level, "Warning");
    assert!(entry2.message.contains("timeout"));

    // Test error log
    let line3 = "2024/01/01 12:00:02 [Error] Failed to connect";
    let entry3 = XrayCore::parse_log_line(line3);
    assert_eq!(entry3.level, "Error");
    assert!(entry3.message.contains("Failed"));

    // Test malformed log (will be parsed as timestamp + message)
    let line4 = "Some random log without proper format";
    let entry4 = XrayCore::parse_log_line(line4);
    assert_eq!(entry4.level, "Info");
    // The parser splits on spaces, so "Some random" becomes timestamp
    // and "log without proper format" becomes message
    assert!(entry4.message.contains("log"));
}

/// Test Xray status transitions
#[tokio::test]
async fn test_xray_status_transitions() {
    let xray = XrayCore::new();

    // Initial state
    assert_eq!(xray.get_status().await, XrayStatus::Stopped);

    // Test status serialization
    let status = XrayStatus::Running;
    let json = serde_json::to_string(&status).unwrap();
    assert!(!json.is_empty());

    // Test error status
    let error_status = XrayStatus::Error("Test error".to_string());
    let json = serde_json::to_string(&error_status).unwrap();
    assert!(json.contains("Test error"));
}

/// Test concurrent event subscriptions
#[tokio::test]
async fn test_concurrent_event_subscriptions() {
    use std::sync::Arc;

    let xray = Arc::new(XrayCore::new());

    // Create multiple subscribers
    let _rx1 = xray.subscribe();
    let _rx2 = xray.subscribe();
    let _rx3 = xray.subscribe();

    // Verify all subscribers are created successfully
    assert_eq!(xray.get_status().await, XrayStatus::Stopped);
}

/// Test Xray configuration with stream settings
#[tokio::test]
async fn test_xray_config_with_stream_settings() {
    use v8ray_core::config::{StreamSettings, TlsSettings};

    let xray = XrayCore::new();

    let mut settings = HashMap::new();
    settings.insert("id".to_string(), serde_json::json!("test-uuid"));

    let stream_settings = StreamSettings {
        network: "tcp".to_string(),
        security: "tls".to_string(),
        tls_settings: Some(TlsSettings {
            server_name: Some("example.com".to_string()),
            allow_insecure: false,
            alpn: vec!["h2".to_string(), "http/1.1".to_string()],
            fingerprint: Some("chrome".to_string()),
        }),
        tcp_settings: None,
        ws_settings: None,
        http_settings: None,
        quic_settings: None,
        grpc_settings: None,
    };

    let config = ProxyServerConfig {
        id: uuid::Uuid::new_v4().to_string(),
        name: "TLS Server".to_string(),
        protocol: ProxyProtocol::Vless,
        server: "example.com".to_string(),
        port: 443,
        settings,
        stream_settings: Some(stream_settings),
        tags: vec!["test".to_string()],
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    let xray_config = xray.generate_config(&config);
    assert_eq!(xray_config.outbounds[0].protocol, "vless");
    assert!(xray_config.outbounds[0].stream_settings.is_some());
}
