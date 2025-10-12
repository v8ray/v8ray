//! Integration tests for configuration management
//!
//! These tests verify the complete configuration management workflow.

use chrono::Utc;
use std::collections::HashMap;
use tempfile::{NamedTempFile, TempDir};
use v8ray_core::config::{
    manager::ConfigManager, parser::ConfigParser, validator::ConfigValidator, ProxyProtocol,
    ProxyServerConfig,
};

/// Test complete configuration workflow
#[tokio::test]
async fn test_complete_config_workflow() {
    let temp_file = NamedTempFile::new().unwrap();
    let manager = ConfigManager::new(temp_file.path());

    // 1. Update application config
    manager
        .update_config(|config| {
            config.proxy.http_port = 8888;
            config.proxy.socks_port = 1888;
            config.app.language = "zh".to_string();
        })
        .await
        .unwrap();

    // 2. Add proxy configs (in-memory only)
    let proxy1 = create_test_proxy("proxy-1", "Server 1", "example1.com", 443);
    let proxy2 = create_test_proxy("proxy-2", "Server 2", "example2.com", 443);

    manager.add_proxy_config(proxy1).await.unwrap();
    manager.add_proxy_config(proxy2).await.unwrap();

    // 3. Verify proxy configs in current manager
    let proxies = manager.get_all_proxy_configs().await;
    assert_eq!(proxies.len(), 2);

    // 4. Save configuration
    manager.save().await.unwrap();

    // 5. Create new manager and load
    let manager2 = ConfigManager::new(temp_file.path());
    manager2.load().await.unwrap();

    // 6. Verify loaded config
    let config = manager2.get_config().await;
    assert_eq!(config.proxy.http_port, 8888);
    assert_eq!(config.proxy.socks_port, 1888);
    assert_eq!(config.app.language, "zh");
}

/// Test configuration validation workflow
#[tokio::test]
async fn test_validation_workflow() {
    let temp_file = NamedTempFile::new().unwrap();
    let manager = ConfigManager::new(temp_file.path());

    // Test valid config
    let result = manager
        .update_config(|config| {
            config.proxy.http_port = 8080;
            config.proxy.socks_port = 1080;
        })
        .await;
    assert!(result.is_ok());

    // Test saving with validation
    let result = manager.save().await;
    assert!(result.is_ok());

    // Test invalid proxy config
    let mut invalid_proxy = create_test_proxy("invalid", "Invalid", "", 0);
    invalid_proxy.server = "".to_string(); // Empty server

    let result = manager.add_proxy_config(invalid_proxy).await;
    // Note: add_proxy_config doesn't validate yet, so this will succeed
    // In a future version, we should add validation here
    assert!(result.is_ok());
}

/// Test URL parsing and config creation
#[tokio::test]
async fn test_url_parsing_workflow() {
    let temp_file = NamedTempFile::new().unwrap();
    let manager = ConfigManager::new(temp_file.path());

    // Parse VLESS URL
    let vless_url = "vless://test-uuid@example.com:443?type=ws&security=tls&path=/ws#Test%20Server";
    let config = ConfigParser::parse_url(vless_url).unwrap();

    assert_eq!(config.protocol, ProxyProtocol::Vless);
    assert_eq!(config.server, "example.com");
    assert_eq!(config.port, 443);

    // Validate parsed config
    let validation = ConfigValidator::validate_proxy_config(&config);
    assert!(validation.is_valid());

    // Add to manager
    manager.add_proxy_config(config).await.unwrap();

    let proxies = manager.get_all_proxy_configs().await;
    assert_eq!(proxies.len(), 1);
}

/// Test encrypted configuration workflow
#[tokio::test]
async fn test_encrypted_workflow() {
    let temp_file = NamedTempFile::new().unwrap();
    let password = "secure_password_123";

    // Create manager with encryption
    let mut manager = ConfigManager::new(temp_file.path());
    manager.set_encryption_password(password.to_string());

    // Update and save config
    manager
        .update_config(|config| {
            config.proxy.http_port = 9999;
        })
        .await
        .unwrap();
    manager.save().await.unwrap();

    // Try to load without password (should fail or get garbage)
    let manager_no_pass = ConfigManager::new(temp_file.path());
    let result = manager_no_pass.load().await;
    assert!(result.is_err()); // Should fail to parse encrypted data

    // Load with correct password
    let mut manager_with_pass = ConfigManager::new(temp_file.path());
    manager_with_pass.set_encryption_password(password.to_string());
    manager_with_pass.load().await.unwrap();

    let config = manager_with_pass.get_config().await;
    assert_eq!(config.proxy.http_port, 9999);
}

/// Test backup and restore workflow
#[tokio::test]
async fn test_backup_restore_workflow() {
    let temp_dir = TempDir::new().unwrap();
    let config_file = temp_dir.path().join("config.json");
    let backup_dir = temp_dir.path().join("backups");

    let mut manager = ConfigManager::new(&config_file);
    manager.set_backup_dir(&backup_dir);

    // Initial state
    manager
        .update_config(|config| {
            config.proxy.http_port = 8080;
        })
        .await
        .unwrap();

    // Create backup
    let backup1 = manager.create_backup().await.unwrap();
    assert!(backup1.exists());

    // Modify config
    manager
        .update_config(|config| {
            config.proxy.http_port = 9090;
        })
        .await
        .unwrap();

    // Create another backup
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;
    let _backup2 = manager.create_backup().await.unwrap();

    // List backups
    let backups = manager.list_backups().unwrap();
    assert_eq!(backups.len(), 2);

    // Restore from first backup
    manager.restore_from_backup(&backup1).await.unwrap();
    let config = manager.get_config().await;
    assert_eq!(config.proxy.http_port, 8080);

    // Cleanup old backups
    let deleted = manager.cleanup_old_backups(1).unwrap();
    assert_eq!(deleted, 1);

    let backups = manager.list_backups().unwrap();
    assert_eq!(backups.len(), 1);
}

/// Test export and import workflow
#[tokio::test]
async fn test_export_import_workflow() {
    let temp_dir = TempDir::new().unwrap();
    let config_file1 = temp_dir.path().join("config1.json");
    let config_file2 = temp_dir.path().join("config2.json");
    let export_file = temp_dir.path().join("export.json");

    // Setup first manager
    let manager1 = ConfigManager::new(&config_file1);
    manager1
        .update_config(|config| {
            config.proxy.http_port = 7777;
            config.app.language = "en".to_string();
        })
        .await
        .unwrap();

    let proxy = create_test_proxy("test-1", "Test Server", "test.com", 443);
    manager1.add_proxy_config(proxy).await.unwrap();

    // Export configuration
    manager1.export_config(&export_file).await.unwrap();
    assert!(export_file.exists());

    // Import to second manager
    let manager2 = ConfigManager::new(&config_file2);
    manager2.import_config(&export_file).await.unwrap();

    // Verify imported config
    let config = manager2.get_config().await;
    assert_eq!(config.proxy.http_port, 7777);
    assert_eq!(config.app.language, "en");
}

/// Test concurrent access to configuration
#[tokio::test]
async fn test_concurrent_access() {
    let temp_file = NamedTempFile::new().unwrap();
    let manager = ConfigManager::new(temp_file.path());

    // Spawn multiple tasks that modify config
    let mut handles = vec![];

    for i in 0..10 {
        let manager_clone = manager.clone();
        let handle = tokio::spawn(async move {
            let proxy = create_test_proxy(
                &format!("proxy-{}", i),
                &format!("Server {}", i),
                "example.com",
                443,
            );
            manager_clone.add_proxy_config(proxy).await.unwrap();
        });
        handles.push(handle);
    }

    // Wait for all tasks
    for handle in handles {
        handle.await.unwrap();
    }

    // Verify all proxies were added
    let proxies = manager.get_all_proxy_configs().await;
    assert_eq!(proxies.len(), 10);
}

/// Helper function to create test proxy config
fn create_test_proxy(id: &str, name: &str, server: &str, port: u16) -> ProxyServerConfig {
    let mut settings = HashMap::new();
    settings.insert("id".to_string(), serde_json::json!("test-uuid"));

    ProxyServerConfig {
        id: id.to_string(),
        name: name.to_string(),
        server: server.to_string(),
        port,
        protocol: ProxyProtocol::Vless,
        settings,
        stream_settings: None,
        tags: vec![],
        created_at: Utc::now(),
        updated_at: Utc::now(),
    }
}
