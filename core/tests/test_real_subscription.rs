/// 测试真实订阅解析
use v8ray_core::config::parser::ConfigParser;
use v8ray_core::subscription::SubscriptionParser;
use v8ray_core::xray::XrayConfigGenerator;

#[tokio::test]
async fn test_parse_real_trojan_url() {
    // 真实的 Trojan URL
    let url = "trojan://c7a5b0a1-2e38-4fc5-8960-9a90696ae748@ldn01.v8ray.com:443?type=tcp&security=tls&sni=ldn01.v8ray.com&alpn=http/1.1#英国伦敦01";

    let config = ConfigParser::parse_url(url).expect("Failed to parse Trojan URL");

    println!("\n=== Parsed Trojan Config ===");
    println!("Name: {}", config.name);
    println!("Server: {}", config.server);
    println!("Port: {}", config.port);
    println!("Protocol: {:?}", config.protocol);
    println!("Settings: {:#?}", config.settings);

    // 验证基本字段
    assert_eq!(config.server, "ldn01.v8ray.com");
    assert_eq!(config.port, 443);
    assert_eq!(
        config.settings.get("password").and_then(|v| v.as_str()),
        Some("c7a5b0a1-2e38-4fc5-8960-9a90696ae748")
    );

    // 验证 stream_settings
    assert!(
        config.stream_settings.is_some(),
        "stream_settings should exist"
    );
    let stream = config.stream_settings.as_ref().unwrap();

    println!("\n=== Stream Settings ===");
    println!("Network: {}", stream.network);
    println!("Security: {}", stream.security);

    assert_eq!(stream.network, "tcp");
    assert_eq!(stream.security, "tls");

    // 验证 TLS 设置
    assert!(stream.tls_settings.is_some(), "tls_settings should exist");
    let tls = stream.tls_settings.as_ref().unwrap();

    println!("\n=== TLS Settings ===");
    println!("Server Name (SNI): {:?}", tls.server_name);
    println!("ALPN: {:?}", tls.alpn);
    println!("Allow Insecure: {}", tls.allow_insecure);
    println!("Fingerprint: {:?}", tls.fingerprint);

    assert_eq!(
        tls.server_name,
        Some("ldn01.v8ray.com".to_string()),
        "SNI should be set"
    );
    assert_eq!(
        tls.alpn,
        vec!["http/1.1".to_string()],
        "ALPN should be http/1.1"
    );
    assert_eq!(tls.allow_insecure, false);
}

#[tokio::test]
async fn test_generate_xray_config_from_trojan() {
    // 解析 Trojan URL
    let url = "trojan://c7a5b0a1-2e38-4fc5-8960-9a90696ae748@ldn01.v8ray.com:443?type=tcp&security=tls&sni=ldn01.v8ray.com&alpn=http/1.1#英国伦敦01";
    let config = ConfigParser::parse_url(url).expect("Failed to parse Trojan URL");

    // 生成 Xray 配置
    let generator = XrayConfigGenerator::new();
    let xray_config = generator.generate(&config);

    // 转换为 JSON 以便检查
    let json_str = serde_json::to_string_pretty(&xray_config).expect("Failed to serialize");
    println!("\n=== Generated Xray Config ===");
    println!("{}", json_str);

    // 验证配置包含必要的字段
    assert!(
        json_str.contains("trojan"),
        "Config should contain trojan protocol"
    );
    assert!(
        json_str.contains("ldn01.v8ray.com"),
        "Config should contain server address"
    );
    assert!(
        json_str.contains("serverName"),
        "Config should contain serverName (SNI)"
    );
    assert!(
        json_str.contains("tlsSettings"),
        "Config should contain tlsSettings"
    );
    assert!(json_str.contains("http/1.1"), "Config should contain ALPN");
    assert!(
        json_str.contains("c7a5b0a1-2e38-4fc5-8960-9a90696ae748"),
        "Config should contain password"
    );
}

#[tokio::test]
async fn test_parse_base64_subscription() {
    // 真实的 Base64 订阅内容（部分）
    let subscription = "dHJvamFuOi8vYzdhNWIwYTEtMmUzOC00ZmM1LTg5NjAtOWE5MDY5NmFlNzQ4QGxkbjAxLnY4cmF5LmNvbTo0NDM/dHlwZT10Y3Amc2VjdXJpdHk9dGxzJnNuaT1sZG4wMS52OHJheS5jb20mYWxwbj1odHRwLzEuMSPoi7Hlm73kvKbmlaYwMSAtIHRyb2phbi00NDM=";

    let configs = SubscriptionParser::parse(subscription).expect("Failed to parse subscription");

    println!("\n=== Parsed Subscription ===");
    println!("Number of configs: {}", configs.len());

    assert_eq!(configs.len(), 1, "Should parse 1 config");

    let config = &configs[0];
    println!("\nConfig 0:");
    println!("  Name: {}", config.name);
    println!("  Server: {}", config.server);
    println!("  Port: {}", config.port);
    println!("  Protocol: {:?}", config.protocol);

    // 验证解析结果
    assert_eq!(config.server, "ldn01.v8ray.com");
    assert_eq!(config.port, 443);

    // 验证 stream_settings 存在
    assert!(
        config.stream_settings.is_some(),
        "stream_settings should exist after parsing"
    );
    let stream = config.stream_settings.as_ref().unwrap();
    assert_eq!(stream.security, "tls");

    // 验证 TLS 设置
    assert!(stream.tls_settings.is_some(), "tls_settings should exist");
    let tls = stream.tls_settings.as_ref().unwrap();
    assert_eq!(
        tls.server_name,
        Some("ldn01.v8ray.com".to_string()),
        "SNI should be preserved"
    );
    assert_eq!(
        tls.alpn,
        vec!["http/1.1".to_string()],
        "ALPN should be preserved"
    );
}

#[tokio::test]
async fn test_trojan_without_explicit_alpn() {
    // Trojan URL 没有明确指定 ALPN
    let url = "trojan://password123@example.com:443?type=tcp&security=tls&sni=example.com#Test";

    let config = ConfigParser::parse_url(url).expect("Failed to parse");

    // 验证默认 ALPN
    let stream = config.stream_settings.as_ref().unwrap();
    let tls = stream.tls_settings.as_ref().unwrap();

    println!("\n=== Trojan without explicit ALPN ===");
    println!("ALPN: {:?}", tls.alpn);

    assert_eq!(
        tls.alpn,
        vec!["http/1.1".to_string()],
        "Should default to http/1.1"
    );
}

#[tokio::test]
async fn test_trojan_minimal_url() {
    // 最小化的 Trojan URL（只有必要参数）
    let url = "trojan://password123@example.com:443#Test";

    let config = ConfigParser::parse_url(url).expect("Failed to parse");

    println!("\n=== Minimal Trojan URL ===");
    println!("Server: {}", config.server);
    println!("Port: {}", config.port);

    // 验证默认值
    let stream = config.stream_settings.as_ref().unwrap();
    assert_eq!(stream.network, "tcp", "Should default to tcp");
    assert_eq!(stream.security, "tls", "Should default to tls");

    let tls = stream.tls_settings.as_ref().unwrap();
    assert_eq!(
        tls.server_name,
        Some("example.com".to_string()),
        "SNI should default to server address"
    );
    assert_eq!(
        tls.alpn,
        vec!["http/1.1".to_string()],
        "ALPN should default to http/1.1"
    );
}
