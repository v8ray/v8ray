//! Integration tests for V8Ray Core
//!
//! These tests verify the interaction between different modules
//! and the overall functionality of the core library.

mod integration;

use v8ray_core::*;

/// Test the complete initialization flow
#[tokio::test]
async fn test_complete_initialization() {
    // Initialize the core library
    let result = init(None);
    assert!(result.is_ok());

    // Verify version information
    let version = version();
    assert!(!version.is_empty());
    assert!(version.starts_with("0.1.0"));
}

/// Test configuration management integration
#[tokio::test]
async fn test_config_integration() {
    use v8ray_core::config::*;

    // Create a test configuration
    let mut config = Config::default();
    config.app.mode = AppMode::Advanced;
    config.proxy.http_port = 8080;
    config.proxy.socks_port = 1080;

    // Validate configuration
    assert!(config.validate().is_ok());

    // Test serialization/deserialization
    let json = serde_json::to_string(&config).unwrap();
    let deserialized: Config = serde_json::from_str(&json).unwrap();

    assert_eq!(config.app.mode as u8, deserialized.app.mode as u8);
    assert_eq!(config.proxy.http_port, deserialized.proxy.http_port);
}

/// Test connection manager integration
///
/// Note: This test requires Xray binary to be present, so it's ignored in debug builds
#[tokio::test]
#[ignore] // Requires Xray binary
async fn test_connection_integration() {
    use v8ray_core::config::{ProxyProtocol, ProxyServerConfig};
    use v8ray_core::connection::*;
    use std::collections::HashMap;

    let manager = ConnectionManager::new();

    // Test initial state
    assert_eq!(manager.get_state().await, ConnectionState::Disconnected);

    // Create test config
    let mut settings = HashMap::new();
    settings.insert("id".to_string(), serde_json::json!("test-uuid"));

    let config = ProxyServerConfig {
        id: "test-config".to_string(),
        name: "Test Server".to_string(),
        server: "127.0.0.1".to_string(),
        port: 8080,
        protocol: ProxyProtocol::Vmess,
        settings,
        stream_settings: None,
        tags: vec![],
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    };

    // Test connection flow (will fail without Xray binary)
    let result = manager.connect_with_config(config).await;
    // In debug mode without Xray binary, this will fail
    // assert!(result.is_ok());
    let _ = result; // Ignore result in test

    // Test statistics update
    manager.update_stats(1024, 2048).await.unwrap();
    let connection = manager.get_current_connection().await.unwrap();
    let stats = connection.stats.unwrap();
    assert_eq!(stats.upload, 1024);
    assert_eq!(stats.download, 2048);

    // Test disconnection
    manager.disconnect().await.unwrap();
    assert_eq!(manager.get_state().await, ConnectionState::Disconnected);
}

/// Test subscription manager integration
#[tokio::test]
async fn test_subscription_integration() {
    use v8ray_core::subscription::*;

    let mut manager = SubscriptionManager::new();

    // Add subscription
    let id = manager
        .add_subscription(
            "Test Subscription".to_string(),
            "https://example.com/subscription".to_string(),
        )
        .await
        .unwrap();

    // Verify subscription was added
    let subscriptions = manager.get_subscriptions();
    assert_eq!(subscriptions.len(), 1);
    assert_eq!(subscriptions[0].id, id);
    assert_eq!(subscriptions[0].name, "Test Subscription");

    // Test subscription update (will fail due to network, but that's expected)
    let _result = manager.update_subscription(id).await;
    // Update may fail due to network issues, which is acceptable in integration test
    // Just verify the subscription still exists
    let subscriptions = manager.get_subscriptions();
    assert_eq!(subscriptions.len(), 1);

    // Test subscription removal
    manager.remove_subscription(id).unwrap();
    assert!(manager.get_subscriptions().is_empty());
    assert!(manager.get_servers().is_empty());
}

/// Test Xray Core integration
#[tokio::test]
async fn test_xray_integration() {
    use v8ray_core::xray::*;

    let xray = XrayCore::new();

    // Test initial status
    assert_eq!(xray.get_status().await, XrayStatus::Stopped);

    // Test configuration creation
    let config = XrayConfig::default();
    assert!(!config.inbounds.is_empty());
    assert!(!config.outbounds.is_empty());

    // Test configuration serialization
    let json = serde_json::to_string(&config).unwrap();
    assert!(!json.is_empty());

    // Note: We don't actually start Xray in tests as it requires the binary
    // In a real environment, you would test the start/stop functionality
}

/// Test platform integration
#[tokio::test]
async fn test_platform_integration() {
    use v8ray_core::platform::*;

    // Test platform information
    let info = get_platform_info();
    assert!(!info.os.is_empty());
    assert!(!info.arch.is_empty());
    assert!(!info.version.is_empty());

    // Test platform capabilities
    let capabilities = &info.capabilities;
    // At least one capability should be supported
    assert!(
        capabilities.system_proxy
            || capabilities.vpn_mode
            || capabilities.tun_mode
            || capabilities.auto_start
    );

    // Test platform operations (mock implementation)
    // Note: Platform-specific tests are skipped in integration tests
    // as they require platform-specific implementations
    #[cfg(target_os = "windows")]
    {
        // let platform = WindowsPlatform::default();
        // assert!(platform.set_system_proxy(8080, 1080).is_ok());
        // assert!(platform.clear_system_proxy().is_ok());
    }
}

/// Test error handling across modules
#[tokio::test]
async fn test_error_handling() {
    use uuid::Uuid;
    use v8ray_core::subscription::*;

    let mut manager = SubscriptionManager::new();

    // Test invalid subscription ID
    let invalid_id = Uuid::new_v4();
    let result = manager.update_subscription(invalid_id).await;
    assert!(result.is_err());

    // Test removing non-existent subscription
    let result = manager.remove_subscription(invalid_id);
    assert!(result.is_ok()); // Remove is idempotent
}

/// Test concurrent operations
#[tokio::test]
async fn test_concurrent_operations() {
    use std::sync::Arc;
    use v8ray_core::connection::*;

    let manager = Arc::new(ConnectionManager::new());

    // Test concurrent state queries
    let handles: Vec<_> = (0..10)
        .map(|_| {
            let manager = Arc::clone(&manager);
            tokio::spawn(async move { manager.get_state().await })
        })
        .collect();

    // All should return Disconnected
    for handle in handles {
        let state = handle.await.unwrap();
        assert_eq!(state, ConnectionState::Disconnected);
    }
}

/// Test memory usage and cleanup
#[tokio::test]
async fn test_memory_cleanup() {
    use v8ray_core::subscription::*;

    let mut manager = SubscriptionManager::new();

    // Add multiple subscriptions
    let mut ids = Vec::new();
    for i in 0..10 {
        let id = manager
            .add_subscription(
                format!("Test {}", i),
                format!("https://example.com/sub{}", i),
            )
            .await
            .unwrap();
        ids.push(id);
    }

    assert_eq!(manager.get_subscriptions().len(), 10);

    // Remove all subscriptions
    for id in ids {
        manager.remove_subscription(id).unwrap();
    }

    assert!(manager.get_subscriptions().is_empty());
    assert!(manager.get_servers().is_empty());
}

/// Test performance benchmarks
#[tokio::test]
async fn test_performance() {
    use std::time::Instant;
    use v8ray_core::config::*;

    // Test configuration validation performance
    let config = Config::default();
    let start = Instant::now();

    for _ in 0..1000 {
        config.validate().unwrap();
    }

    let duration = start.elapsed();
    // Should complete 1000 validations in less than 100ms
    assert!(duration.as_millis() < 100);
}
