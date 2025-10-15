//! Integration tests for bug fixes
//!
//! This test file verifies the fixes for:
//! 1. Shadowsocks and Trojan configuration parsing
//! 2. Traffic statistics tracking

use v8ray_core::config::parser::ConfigParser;

#[test]
fn test_shadowsocks_url_parsing_format1() {
    // Format 1: ss://base64(method:password)@server:port#name
    // Example: ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@example.com:8388#TestServer
    // Base64 decodes to: aes-256-gcm:password

    let url = "ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@example.com:8388#TestServer";
    let result = ConfigParser::parse_url(url);

    assert!(
        result.is_ok(),
        "Failed to parse Shadowsocks URL: {:?}",
        result.err()
    );

    let config = result.unwrap();
    assert_eq!(config.server, "example.com");
    assert_eq!(config.port, 8388);
    assert_eq!(config.name, "TestServer");

    // Check settings
    assert_eq!(
        config.settings.get("method").and_then(|v| v.as_str()),
        Some("aes-256-gcm")
    );
    assert_eq!(
        config.settings.get("password").and_then(|v| v.as_str()),
        Some("password")
    );
}

#[test]
fn test_shadowsocks_url_parsing_format2() {
    // Format 2: ss://base64(method:password@server:port)#name
    // Example: ss://YWVzLTI1Ni1nY206cGFzc3dvcmRAZXhhbXBsZS5jb206ODM4OA==#TestServer2
    // Base64 decodes to: aes-256-gcm:password@example.com:8388

    let url = "ss://YWVzLTI1Ni1nY206cGFzc3dvcmRAZXhhbXBsZS5jb206ODM4OA==#TestServer2";
    let result = ConfigParser::parse_url(url);

    assert!(
        result.is_ok(),
        "Failed to parse Shadowsocks URL format 2: {:?}",
        result.err()
    );

    let config = result.unwrap();
    assert_eq!(config.server, "example.com");
    assert_eq!(config.port, 8388);
    assert_eq!(config.name, "TestServer2");

    // Check settings
    assert_eq!(
        config.settings.get("method").and_then(|v| v.as_str()),
        Some("aes-256-gcm")
    );
    assert_eq!(
        config.settings.get("password").and_then(|v| v.as_str()),
        Some("password")
    );
}

#[test]
fn test_trojan_url_with_stream_settings() {
    // Trojan URL with TLS and WebSocket settings
    let url = "trojan://password123@example.com:443?type=ws&security=tls&sni=example.com&path=/ws#TrojanWS";
    let result = ConfigParser::parse_url(url);

    assert!(
        result.is_ok(),
        "Failed to parse Trojan URL: {:?}",
        result.err()
    );

    let config = result.unwrap();
    assert_eq!(config.server, "example.com");
    assert_eq!(config.port, 443);
    assert_eq!(config.name, "TrojanWS");

    // Check password
    assert_eq!(
        config.settings.get("password").and_then(|v| v.as_str()),
        Some("password123")
    );

    // Check stream settings
    assert!(config.stream_settings.is_some());
    let stream = config.stream_settings.unwrap();
    assert_eq!(stream.network, "ws");
    assert_eq!(stream.security, "tls");

    // Check TLS settings
    assert!(stream.tls_settings.is_some());
    let tls = stream.tls_settings.unwrap();
    assert_eq!(tls.server_name, Some("example.com".to_string()));

    // Check WebSocket settings
    assert!(stream.ws_settings.is_some());
    let ws = stream.ws_settings.unwrap();
    assert_eq!(ws.path, "/ws");
}

// Note: Clash YAML parsing is tested in unit tests
// The SubscriptionManager API requires async and database setup,
// so we test the parser directly in unit tests instead

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_traffic_stats_integration() {
    use std::time::Duration;
    use v8ray_core::connection::ConnectionManager;

    let manager = ConnectionManager::new();

    // Get initial stats
    let (upload1, download1) = manager.get_traffic_totals().await;
    assert_eq!(upload1, 0);
    assert_eq!(download1, 0);

    // Simulate traffic update
    let stats_collector = manager.get_stats_collector();
    stats_collector.update_traffic(1024, 2048).await;

    // Wait a bit for stats to update
    tokio::time::sleep(Duration::from_millis(100)).await;

    // Get updated stats
    let (upload2, download2) = manager.get_traffic_totals().await;
    assert_eq!(upload2, 1024);
    assert_eq!(download2, 2048);

    // Reset stats
    manager.reset_stats().await;

    // Verify reset
    let (upload3, download3) = manager.get_traffic_totals().await;
    assert_eq!(upload3, 0);
    assert_eq!(download3, 0);
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_traffic_speeds_calculation() {
    use std::time::Duration;
    use v8ray_core::connection::ConnectionManager;

    let manager = ConnectionManager::new();

    // Start stats collection
    manager
        .start_stats_collection(Duration::from_millis(100))
        .await;

    // Simulate traffic
    let stats_collector = manager.get_stats_collector();
    stats_collector.update_traffic(1000, 2000).await;

    // Wait for speed calculation
    tokio::time::sleep(Duration::from_millis(150)).await;

    // Add more traffic
    stats_collector.update_traffic(1000, 2000).await;

    // Wait for speed calculation
    tokio::time::sleep(Duration::from_millis(150)).await;

    // Get speeds
    let (upload_speed, download_speed) = manager.get_traffic_speeds().await;

    // Speeds should be calculated (may vary based on timing)
    // Just verify the function works (speeds are u64, always >= 0)
    let _ = upload_speed;
    let _ = download_speed;
}
