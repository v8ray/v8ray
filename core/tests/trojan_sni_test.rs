use v8ray_core::config::parser::ConfigParser;
use v8ray_core::subscription::{Server, SubscriptionFormat, SubscriptionParser};
use v8ray_core::xray::XrayConfigGenerator;

#[tokio::test]
async fn test_trojan_url_parsing_with_sni() {
    // Test Trojan URL with explicit SNI
    let url = "trojan://password@example.com:443?sni=example.com&security=tls#Test%20Server";
    let config = ConfigParser::parse_url(url).expect("Failed to parse Trojan URL");

    assert_eq!(format!("{:?}", config.protocol).to_lowercase(), "trojan");
    assert_eq!(config.server, "example.com");
    assert_eq!(config.port, 443);

    // Check stream settings
    assert!(
        config.stream_settings.is_some(),
        "Stream settings should be present"
    );
    let stream = config.stream_settings.as_ref().unwrap();
    assert_eq!(stream.security, "tls");

    // Check TLS settings with SNI
    assert!(
        stream.tls_settings.is_some(),
        "TLS settings should be present"
    );
    let tls = stream.tls_settings.as_ref().unwrap();
    assert_eq!(
        tls.server_name,
        Some("example.com".to_string()),
        "SNI should be set to example.com"
    );
}

#[tokio::test]
async fn test_trojan_url_parsing_without_explicit_sni() {
    // Test Trojan URL without explicit SNI (should default to server address)
    let url = "trojan://password@example.com:443?security=tls#Test%20Server";
    let config = ConfigParser::parse_url(url).expect("Failed to parse Trojan URL");

    assert_eq!(format!("{:?}", config.protocol).to_lowercase(), "trojan");

    // Check stream settings
    assert!(
        config.stream_settings.is_some(),
        "Stream settings should be present"
    );
    let stream = config.stream_settings.as_ref().unwrap();
    assert_eq!(stream.security, "tls");

    // Check TLS settings with SNI defaulting to server address
    assert!(
        stream.tls_settings.is_some(),
        "TLS settings should be present"
    );
    let tls = stream.tls_settings.as_ref().unwrap();
    assert_eq!(
        tls.server_name,
        Some("example.com".to_string()),
        "SNI should default to server address"
    );
}

#[tokio::test]
async fn test_trojan_url_parsing_minimal() {
    // Test minimal Trojan URL (should still get TLS and SNI)
    let url = "trojan://password@example.com:443#Test";
    let config = ConfigParser::parse_url(url).expect("Failed to parse Trojan URL");

    assert_eq!(format!("{:?}", config.protocol).to_lowercase(), "trojan");

    // Check stream settings (should be created even without explicit security param)
    assert!(
        config.stream_settings.is_some(),
        "Stream settings should be present for Trojan"
    );
    let stream = config.stream_settings.as_ref().unwrap();
    assert_eq!(stream.security, "tls", "Trojan should default to TLS");

    // Check TLS settings
    assert!(
        stream.tls_settings.is_some(),
        "TLS settings should be present"
    );
    let tls = stream.tls_settings.as_ref().unwrap();
    assert_eq!(
        tls.server_name,
        Some("example.com".to_string()),
        "SNI should default to server address"
    );
}

#[tokio::test]
async fn test_trojan_storage_preserves_stream_settings() {
    use chrono::Utc;
    use uuid::Uuid;
    use v8ray_core::subscription::{Subscription, SubscriptionStatus, SubscriptionStorage};

    // Create in-memory storage
    let storage = SubscriptionStorage::new_in_memory()
        .await
        .expect("Failed to create storage");

    // First create a subscription
    let sub_id = Uuid::new_v4();
    let subscription = Subscription {
        id: sub_id,
        name: "Test Subscription".to_string(),
        url: "http://example.com".to_string(),
        last_update: None,
        server_count: 0,
        status: SubscriptionStatus::Inactive,
    };
    storage
        .save_subscription(&subscription)
        .await
        .expect("Failed to save subscription");

    // Parse a Trojan URL
    let url = "trojan://password@example.com:443?sni=custom.example.com#Test";
    let config = ConfigParser::parse_url(url).expect("Failed to parse Trojan URL");

    // Create a server from the config
    let server = Server {
        id: Uuid::new_v4(),
        name: config.name.clone(),
        address: config.server.clone(),
        port: config.port,
        protocol: format!("{:?}", config.protocol).to_lowercase(),
        config: config.settings.clone(),
        stream_settings: config.stream_settings.clone(),
        subscription_id: sub_id,
    };

    // Save the server
    storage
        .save_server(&server)
        .await
        .expect("Failed to save server");

    // Load the server back
    let loaded_servers = storage
        .load_servers_for_subscription(sub_id)
        .await
        .expect("Failed to load servers");

    assert_eq!(loaded_servers.len(), 1);
    let loaded_server = &loaded_servers[0];

    // Verify stream_settings is preserved
    assert!(
        loaded_server.stream_settings.is_some(),
        "Stream settings should be preserved in storage"
    );
    let stream = loaded_server.stream_settings.as_ref().unwrap();
    assert_eq!(stream.security, "tls");

    // Verify SNI is preserved
    assert!(stream.tls_settings.is_some());
    let tls = stream.tls_settings.as_ref().unwrap();
    assert_eq!(
        tls.server_name,
        Some("custom.example.com".to_string()),
        "Custom SNI should be preserved"
    );
}

#[tokio::test]
async fn test_xray_config_generation_includes_sni() {
    // Parse a Trojan URL
    let url = "trojan://password@example.com:443?sni=custom.example.com#Test";
    let config = ConfigParser::parse_url(url).expect("Failed to parse Trojan URL");

    // Generate Xray config
    let generator = XrayConfigGenerator::new();
    let xray_config = generator.generate(&config);

    // Convert to JSON
    let json_str = serde_json::to_string_pretty(&xray_config).expect("Failed to serialize config");

    // Verify the config contains SNI
    assert!(
        json_str.contains("serverName"),
        "Xray config should contain serverName field"
    );
    assert!(
        json_str.contains("custom.example.com"),
        "Xray config should contain the custom SNI"
    );

    // Verify TLS settings are present
    assert!(
        json_str.contains("tlsSettings"),
        "Xray config should contain tlsSettings"
    );
}

#[tokio::test]
async fn test_clash_yaml_trojan_parsing() {
    let yaml = r#"
proxies:
  - name: "Trojan Server"
    type: trojan
    server: example.com
    port: 443
    password: password123
    sni: custom.example.com
    skip-cert-verify: false
"#;

    let configs = SubscriptionParser::parse_with_format(yaml, SubscriptionFormat::ClashYaml)
        .expect("Failed to parse Clash YAML");
    assert_eq!(configs.len(), 1);

    let config = &configs[0];
    assert_eq!(format!("{:?}", config.protocol).to_lowercase(), "trojan");

    // Check stream settings
    assert!(
        config.stream_settings.is_some(),
        "Stream settings should be present"
    );
    let stream = config.stream_settings.as_ref().unwrap();
    assert_eq!(stream.security, "tls");

    // Check SNI
    assert!(stream.tls_settings.is_some());
    let tls = stream.tls_settings.as_ref().unwrap();
    assert_eq!(
        tls.server_name,
        Some("custom.example.com".to_string()),
        "SNI should be extracted from Clash YAML"
    );
}
