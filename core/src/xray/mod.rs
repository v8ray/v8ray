//! Xray Core Integration Module
//!
//! This module handles integration with Xray Core, including process management,
//! configuration generation, and status monitoring.

mod updater;

pub use updater::{UpdateInfo, XrayUpdater};

use crate::config::{ProxyProtocol, ProxyServerConfig};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::path::PathBuf;
use std::process::{Child, Command, Stdio};
use std::sync::Arc;
use std::time::Duration;
use thiserror::Error;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::sync::{broadcast, RwLock};
use tokio::time;

/// Xray Core errors
#[derive(Error, Debug)]
pub enum XrayError {
    /// IO error
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    /// Process error
    #[error("Process error: {0}")]
    Process(String),
    /// Configuration error
    #[error("Configuration error: {0}")]
    Config(String),
    /// Xray Core not found
    #[error("Xray Core not found")]
    NotFound,
}

/// Xray Core status
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum XrayStatus {
    /// Xray Core is stopped
    Stopped,
    /// Xray Core is starting
    Starting,
    /// Xray Core is running
    Running,
    /// Xray Core is stopping
    Stopping,
    /// Xray Core has error
    Error(String),
}

/// Xray process health information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XrayHealth {
    /// Process ID
    pub pid: Option<u32>,
    /// Uptime in seconds
    pub uptime: u64,
    /// Last health check time
    pub last_check: std::time::SystemTime,
    /// Is process responsive
    pub is_responsive: bool,
}

/// Xray log entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XrayLogEntry {
    /// Timestamp
    pub timestamp: String,
    /// Log level
    pub level: String,
    /// Message
    pub message: String,
}

/// Xray status event
#[derive(Debug, Clone)]
pub enum XrayEvent {
    /// Status changed
    StatusChanged(XrayStatus),
    /// Log entry received
    LogReceived(XrayLogEntry),
    /// Health check result
    HealthCheck(XrayHealth),
}

/// Xray Core configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XrayConfig {
    /// Log configuration
    pub log: LogConfig,
    /// Inbound configurations
    pub inbounds: Vec<InboundConfig>,
    /// Outbound configurations
    pub outbounds: Vec<OutboundConfig>,
    /// Routing configuration
    pub routing: Option<RoutingConfig>,
}

/// Log configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogConfig {
    /// Log level
    pub level: String,
    /// Access log path
    pub access: Option<String>,
    /// Error log path
    pub error: Option<String>,
}

/// Inbound configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InboundConfig {
    /// Port number
    pub port: u16,
    /// Protocol
    pub protocol: String,
    /// Listen address
    pub listen: Option<String>,
    /// Settings
    pub settings: Option<serde_json::Value>,
}

/// Outbound configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutboundConfig {
    /// Protocol
    pub protocol: String,
    /// Settings
    pub settings: Option<serde_json::Value>,
    /// Stream settings
    pub stream_settings: Option<serde_json::Value>,
}

/// Routing configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoutingConfig {
    /// Domain strategy
    pub domain_strategy: Option<String>,
    /// Rules
    pub rules: Vec<serde_json::Value>,
}

/// Xray Core manager
pub struct XrayCore {
    /// Current status
    status: Arc<RwLock<XrayStatus>>,
    /// Xray process
    process: RwLock<Option<Child>>,
    /// Current configuration
    config: Arc<RwLock<Option<XrayConfig>>>,
    /// Xray binary path
    binary_path: Arc<RwLock<Option<PathBuf>>>,
    /// Config generator
    config_generator: Arc<XrayConfigGenerator>,
    /// Updater
    updater: Arc<XrayUpdater>,
    /// Event broadcaster
    event_tx: broadcast::Sender<XrayEvent>,
    /// Process start time
    start_time: Arc<RwLock<Option<std::time::Instant>>>,
    /// Health information
    health: Arc<RwLock<Option<XrayHealth>>>,
}

impl Default for XrayCore {
    fn default() -> Self {
        Self::new()
    }
}

impl XrayCore {
    /// Create a new Xray Core manager
    pub fn new() -> Self {
        // Determine bin directory
        let bin_dir = if let Ok(exe_path) = std::env::current_exe() {
            if let Some(exe_dir) = exe_path.parent() {
                exe_dir.join("bin")
            } else {
                PathBuf::from("bin")
            }
        } else {
            PathBuf::from("bin")
        };

        let (event_tx, _) = broadcast::channel(100);

        Self {
            status: Arc::new(RwLock::new(XrayStatus::Stopped)),
            process: RwLock::new(None),
            config: Arc::new(RwLock::new(None)),
            binary_path: Arc::new(RwLock::new(None)),
            config_generator: Arc::new(XrayConfigGenerator::new()),
            updater: Arc::new(XrayUpdater::new(bin_dir)),
            event_tx,
            start_time: Arc::new(RwLock::new(None)),
            health: Arc::new(RwLock::new(None)),
        }
    }

    /// Get updater reference
    pub fn updater(&self) -> &XrayUpdater {
        &self.updater
    }

    /// Generate Xray configuration from proxy config
    pub fn generate_config(&self, proxy_config: &ProxyServerConfig) -> XrayConfig {
        self.config_generator.generate(proxy_config)
    }

    /// Get current status
    pub async fn get_status(&self) -> XrayStatus {
        self.status.read().await.clone()
    }

    /// Set Xray binary path manually
    pub async fn set_binary_path(&self, path: PathBuf) -> Result<(), XrayError> {
        if !path.exists() {
            return Err(XrayError::NotFound);
        }
        let mut binary_path = self.binary_path.write().await;
        *binary_path = Some(path);
        tracing::info!("Xray binary path set");
        Ok(())
    }

    /// Get Xray binary path
    pub async fn get_binary_path(&self) -> Option<PathBuf> {
        self.binary_path.read().await.clone()
    }

    /// Start Xray Core with configuration
    pub async fn start(&self, config: XrayConfig) -> Result<(), XrayError> {
        let current_status = self.status.read().await.clone();

        if current_status == XrayStatus::Running {
            return Ok(());
        }

        // Update status to Starting
        self.update_status(XrayStatus::Starting).await;

        // Save configuration
        {
            let mut current_config = self.config.write().await;
            *current_config = Some(config.clone());
        }

        // Find Xray Core binary
        let xray_path = self.find_xray_binary()?;

        // Generate configuration file
        let config_content =
            serde_json::to_string_pretty(&config).map_err(|e| XrayError::Config(e.to_string()))?;

        // Write config to temporary file
        let config_path = std::env::temp_dir().join("v8ray_xray_config.json");
        std::fs::write(&config_path, config_content)?;

        // Start Xray process
        let mut child = Command::new(xray_path)
            .arg("-config")
            .arg(&config_path)
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?;

        // Get stdout and stderr for monitoring
        let stdout = child
            .stdout
            .take()
            .ok_or_else(|| XrayError::Process("Failed to capture stdout".to_string()))?;
        let stderr = child
            .stderr
            .take()
            .ok_or_else(|| XrayError::Process("Failed to capture stderr".to_string()))?;

        // Store process
        {
            let mut process = self.process.write().await;
            *process = Some(child);
        }

        // Record start time
        {
            let mut start_time = self.start_time.write().await;
            *start_time = Some(std::time::Instant::now());
        }

        // Start log monitoring
        Self::monitor_logs(stdout, stderr, self.event_tx.clone());

        // Start health monitoring
        self.start_monitoring();

        // Update status to Running
        self.update_status(XrayStatus::Running).await;

        tracing::info!("Xray Core started successfully");
        Ok(())
    }

    /// Stop Xray Core
    pub async fn stop(&self) -> Result<(), XrayError> {
        let current_status = self.status.read().await.clone();

        if current_status == XrayStatus::Stopped {
            return Ok(());
        }

        // Update status to Stopping
        self.update_status(XrayStatus::Stopping).await;

        // Kill process
        {
            let mut process = self.process.write().await;
            if let Some(mut child) = process.take() {
                child.kill()?;
                child.wait()?;
            }
        }

        // Clear start time
        {
            let mut start_time = self.start_time.write().await;
            *start_time = None;
        }

        // Clear health info
        {
            let mut health = self.health.write().await;
            *health = None;
        }

        // Update status to Stopped
        self.update_status(XrayStatus::Stopped).await;

        tracing::info!("Xray Core stopped");
        Ok(())
    }

    /// Restart Xray Core
    pub async fn restart(&self) -> Result<(), XrayError> {
        let config = {
            let config_guard = self.config.read().await;
            config_guard.clone()
        };

        self.stop().await?;

        if let Some(config) = config {
            self.start(config).await?;
        }

        Ok(())
    }

    /// Find bundled Xray binary in application directory
    fn find_xray_binary(&self) -> Result<String, XrayError> {
        #[cfg(windows)]
        let binary_name = "xray.exe";
        #[cfg(not(windows))]
        let binary_name = "xray";

        // Check application directory (bundled Xray Core)
        if let Ok(exe_path) = std::env::current_exe() {
            if let Some(exe_dir) = exe_path.parent() {
                // Priority 1: bin subdirectory
                let app_binary = exe_dir.join("bin").join(binary_name);
                if app_binary.exists() {
                    tracing::info!("Found bundled Xray binary: {:?}", app_binary);
                    return Ok(app_binary.to_string_lossy().to_string());
                }

                // Priority 2: same directory as executable
                let same_dir_binary = exe_dir.join(binary_name);
                if same_dir_binary.exists() {
                    tracing::info!("Found Xray binary in exe directory: {:?}", same_dir_binary);
                    return Ok(same_dir_binary.to_string_lossy().to_string());
                }
            }
        }

        tracing::error!(
            "Bundled Xray binary not found. Please ensure Xray Core is properly installed."
        );
        Err(XrayError::NotFound)
    }

    /// Write configuration to temporary file
    async fn write_config_file(&self, config: &XrayConfig) -> Result<PathBuf, XrayError> {
        let config_content =
            serde_json::to_string_pretty(config).map_err(|e| XrayError::Config(e.to_string()))?;

        let config_path = std::env::temp_dir().join("v8ray_xray_config.json");
        tokio::fs::write(&config_path, config_content)
            .await
            .map_err(|e| XrayError::Io(e))?;

        tracing::debug!("Xray config written to: {:?}", config_path);
        Ok(config_path)
    }

    /// Check if Xray process is running
    pub async fn is_running(&self) -> bool {
        let status = self.status.read().await;
        *status == XrayStatus::Running
    }

    /// Get Xray version
    pub async fn get_version(&self) -> Result<String, XrayError> {
        let binary_path = self.find_xray_binary()?;

        let output = Command::new(binary_path)
            .arg("version")
            .output()
            .map_err(|e| XrayError::Process(e.to_string()))?;

        if output.status.success() {
            let version = String::from_utf8_lossy(&output.stdout).to_string();
            Ok(version)
        } else {
            Err(XrayError::Process("Failed to get version".to_string()))
        }
    }

    /// Subscribe to Xray events
    pub fn subscribe(&self) -> broadcast::Receiver<XrayEvent> {
        self.event_tx.subscribe()
    }

    /// Get current health information
    pub async fn get_health(&self) -> Option<XrayHealth> {
        self.health.read().await.clone()
    }

    /// Start health monitoring
    pub fn start_monitoring(&self) {
        let status = self.status.clone();
        let health = self.health.clone();
        let start_time = self.start_time.clone();
        let event_tx = self.event_tx.clone();

        tokio::spawn(async move {
            let mut interval = time::interval(Duration::from_secs(5));

            loop {
                interval.tick().await;

                let current_status = status.read().await.clone();
                if current_status != XrayStatus::Running {
                    continue;
                }

                let uptime = {
                    let start = start_time.read().await;
                    start.as_ref().map(|t| t.elapsed().as_secs()).unwrap_or(0)
                };

                let health_info = XrayHealth {
                    pid: None, // Will be set by process check
                    uptime,
                    last_check: std::time::SystemTime::now(),
                    is_responsive: true,
                };

                // Update health
                {
                    let mut h = health.write().await;
                    *h = Some(health_info.clone());
                }

                // Broadcast health check event
                let _ = event_tx.send(XrayEvent::HealthCheck(health_info));
            }
        });
    }

    /// Monitor process logs
    fn monitor_logs(
        stdout: std::process::ChildStdout,
        stderr: std::process::ChildStderr,
        event_tx: broadcast::Sender<XrayEvent>,
    ) {
        // Monitor stdout
        let event_tx_clone = event_tx.clone();
        tokio::spawn(async move {
            let reader = BufReader::new(tokio::process::ChildStdout::from_std(stdout).unwrap());
            let mut lines = reader.lines();

            while let Ok(Some(line)) = lines.next_line().await {
                let log_entry = Self::parse_log_line(&line);
                let _ = event_tx_clone.send(XrayEvent::LogReceived(log_entry));
            }
        });

        // Monitor stderr
        tokio::spawn(async move {
            let reader = BufReader::new(tokio::process::ChildStderr::from_std(stderr).unwrap());
            let mut lines = reader.lines();

            while let Ok(Some(line)) = lines.next_line().await {
                let log_entry = Self::parse_log_line(&line);
                let _ = event_tx.send(XrayEvent::LogReceived(log_entry));
            }
        });
    }

    /// Parse log line
    pub fn parse_log_line(line: &str) -> XrayLogEntry {
        // Simple log parsing - can be enhanced based on Xray log format
        // Example: "2024/01/01 12:00:00 [Info] message"
        let parts: Vec<&str> = line.splitn(3, ' ').collect();

        if parts.len() >= 3 {
            let timestamp = format!("{} {}", parts[0], parts.get(1).unwrap_or(&""));
            let level_and_msg = parts[2];

            if let Some(level_end) = level_and_msg.find(']') {
                let level = level_and_msg[1..level_end].to_string();
                let message = level_and_msg[level_end + 1..].trim().to_string();

                XrayLogEntry {
                    timestamp,
                    level,
                    message,
                }
            } else {
                XrayLogEntry {
                    timestamp,
                    level: "Info".to_string(),
                    message: level_and_msg.to_string(),
                }
            }
        } else {
            XrayLogEntry {
                timestamp: chrono::Utc::now().to_rfc3339(),
                level: "Info".to_string(),
                message: line.to_string(),
            }
        }
    }

    /// Update status and broadcast event
    async fn update_status(&self, new_status: XrayStatus) {
        let mut status = self.status.write().await;
        *status = new_status.clone();
        let _ = self.event_tx.send(XrayEvent::StatusChanged(new_status));
    }
}

impl Default for XrayConfig {
    fn default() -> Self {
        Self {
            log: LogConfig {
                level: "warning".to_string(),
                access: None,
                error: None,
            },
            inbounds: vec![
                InboundConfig {
                    port: 8080,
                    protocol: "http".to_string(),
                    listen: Some("127.0.0.1".to_string()),
                    settings: None,
                },
                InboundConfig {
                    port: 1080,
                    protocol: "socks".to_string(),
                    listen: Some("127.0.0.1".to_string()),
                    settings: None,
                },
            ],
            outbounds: vec![OutboundConfig {
                protocol: "freedom".to_string(),
                settings: None,
                stream_settings: None,
            }],
            routing: None,
        }
    }
}

/// Xray configuration generator
pub struct XrayConfigGenerator {
    http_port: u16,
    socks_port: u16,
    log_level: String,
}

impl Default for XrayConfigGenerator {
    fn default() -> Self {
        Self::new()
    }
}

impl XrayConfigGenerator {
    /// Create a new configuration generator
    pub fn new() -> Self {
        Self {
            http_port: 8080,
            socks_port: 1080,
            log_level: "warning".to_string(),
        }
    }

    /// Set HTTP inbound port
    pub fn with_http_port(mut self, port: u16) -> Self {
        self.http_port = port;
        self
    }

    /// Set SOCKS inbound port
    pub fn with_socks_port(mut self, port: u16) -> Self {
        self.socks_port = port;
        self
    }

    /// Set log level
    pub fn with_log_level(mut self, level: String) -> Self {
        self.log_level = level;
        self
    }

    /// Generate Xray configuration from ProxyServerConfig
    pub fn generate(&self, proxy_config: &ProxyServerConfig) -> XrayConfig {
        let log = LogConfig {
            level: self.log_level.clone(),
            access: None,
            error: None,
        };

        let inbounds = vec![
            InboundConfig {
                port: self.http_port,
                protocol: "http".to_string(),
                listen: Some("127.0.0.1".to_string()),
                settings: None,
            },
            InboundConfig {
                port: self.socks_port,
                protocol: "socks".to_string(),
                listen: Some("127.0.0.1".to_string()),
                settings: None,
            },
        ];

        let outbound = self.generate_outbound(proxy_config);
        let outbounds = vec![
            outbound,
            // Add direct outbound as fallback
            OutboundConfig {
                protocol: "freedom".to_string(),
                settings: None,
                stream_settings: None,
            },
        ];

        let routing = Some(RoutingConfig {
            domain_strategy: Some("IPIfNonMatch".to_string()),
            rules: vec![],
        });

        XrayConfig {
            log,
            inbounds,
            outbounds,
            routing,
        }
    }

    /// Generate outbound configuration based on protocol
    fn generate_outbound(&self, proxy_config: &ProxyServerConfig) -> OutboundConfig {
        match proxy_config.protocol {
            ProxyProtocol::Vmess => self.generate_vmess_outbound(proxy_config),
            ProxyProtocol::Vless => self.generate_vless_outbound(proxy_config),
            ProxyProtocol::Trojan => self.generate_trojan_outbound(proxy_config),
            ProxyProtocol::Shadowsocks => self.generate_shadowsocks_outbound(proxy_config),
            _ => OutboundConfig {
                protocol: "freedom".to_string(),
                settings: None,
                stream_settings: None,
            },
        }
    }

    /// Generate VMess outbound configuration
    fn generate_vmess_outbound(&self, proxy_config: &ProxyServerConfig) -> OutboundConfig {
        let vnext = json!([{
            "address": proxy_config.server,
            "port": proxy_config.port,
            "users": [{
                "id": proxy_config.settings.get("id").and_then(|v| v.as_str()).unwrap_or(""),
                "alterId": proxy_config.settings.get("alterId").and_then(|v| v.as_u64()).unwrap_or(0),
                "security": proxy_config.settings.get("security").and_then(|v| v.as_str()).unwrap_or("auto"),
            }]
        }]);

        let settings = json!({
            "vnext": vnext
        });

        let stream_settings = self.generate_stream_settings(proxy_config);

        OutboundConfig {
            protocol: "vmess".to_string(),
            settings: Some(settings),
            stream_settings,
        }
    }

    /// Generate VLESS outbound configuration
    fn generate_vless_outbound(&self, proxy_config: &ProxyServerConfig) -> OutboundConfig {
        let vnext = json!([{
            "address": proxy_config.server,
            "port": proxy_config.port,
            "users": [{
                "id": proxy_config.settings.get("id").and_then(|v| v.as_str()).unwrap_or(""),
                "encryption": proxy_config.settings.get("encryption").and_then(|v| v.as_str()).unwrap_or("none"),
                "flow": proxy_config.settings.get("flow").and_then(|v| v.as_str()).unwrap_or(""),
            }]
        }]);

        let settings = json!({
            "vnext": vnext
        });

        let stream_settings = self.generate_stream_settings(proxy_config);

        OutboundConfig {
            protocol: "vless".to_string(),
            settings: Some(settings),
            stream_settings,
        }
    }

    /// Generate Trojan outbound configuration
    fn generate_trojan_outbound(&self, proxy_config: &ProxyServerConfig) -> OutboundConfig {
        let servers = json!([{
            "address": proxy_config.server,
            "port": proxy_config.port,
            "password": proxy_config.settings.get("password").and_then(|v| v.as_str()).unwrap_or(""),
        }]);

        let settings = json!({
            "servers": servers
        });

        let stream_settings = self.generate_stream_settings(proxy_config);

        OutboundConfig {
            protocol: "trojan".to_string(),
            settings: Some(settings),
            stream_settings,
        }
    }

    /// Generate Shadowsocks outbound configuration
    fn generate_shadowsocks_outbound(&self, proxy_config: &ProxyServerConfig) -> OutboundConfig {
        let servers = json!([{
            "address": proxy_config.server,
            "port": proxy_config.port,
            "method": proxy_config.settings.get("method").and_then(|v| v.as_str()).unwrap_or("aes-256-gcm"),
            "password": proxy_config.settings.get("password").and_then(|v| v.as_str()).unwrap_or(""),
        }]);

        let settings = json!({
            "servers": servers
        });

        OutboundConfig {
            protocol: "shadowsocks".to_string(),
            settings: Some(settings),
            stream_settings: None,
        }
    }

    /// Generate stream settings from proxy configuration
    fn generate_stream_settings(&self, proxy_config: &ProxyServerConfig) -> Option<Value> {
        if let Some(stream_settings) = &proxy_config.stream_settings {
            let mut settings = json!({
                "network": stream_settings.network,
                "security": stream_settings.security,
            });

            // Add TLS settings
            if stream_settings.security == "tls" {
                if let Some(tls_settings) = &stream_settings.tls_settings {
                    let mut tls = json!({
                        "allowInsecure": tls_settings.allow_insecure,
                    });

                    if let Some(server_name) = &tls_settings.server_name {
                        tls["serverName"] = json!(server_name);
                    }

                    if !tls_settings.alpn.is_empty() {
                        tls["alpn"] = json!(tls_settings.alpn);
                    }

                    if let Some(fingerprint) = &tls_settings.fingerprint {
                        tls["fingerprint"] = json!(fingerprint);
                    }

                    settings["tlsSettings"] = tls;
                }
            }

            // Add WebSocket settings
            if stream_settings.network == "ws" {
                if let Some(ws_settings) = &stream_settings.ws_settings {
                    settings["wsSettings"] = json!({
                        "path": ws_settings.path,
                        "headers": ws_settings.headers,
                    });
                }
            }

            // Add gRPC settings
            if stream_settings.network == "grpc" {
                if let Some(grpc_settings) = &stream_settings.grpc_settings {
                    settings["grpcSettings"] = json!({
                        "serviceName": grpc_settings.service_name,
                        "multiMode": grpc_settings.multi_mode,
                    });
                }
            }

            Some(settings)
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_xray_core_status() {
        let xray = XrayCore::new();
        assert_eq!(xray.get_status().await, XrayStatus::Stopped);
    }

    #[test]
    fn test_xray_config_serialization() {
        let config = XrayConfig::default();
        let json = serde_json::to_string(&config).unwrap();
        assert!(!json.is_empty());

        let _parsed: XrayConfig = serde_json::from_str(&json).unwrap();
    }

    #[tokio::test]
    async fn test_event_subscription() {
        let xray = XrayCore::new();
        let mut rx = xray.subscribe();

        // Test that we can subscribe to events
        assert!(rx.try_recv().is_err()); // No events yet

        // Simulate status change
        xray.update_status(XrayStatus::Starting).await;

        // Should receive status change event
        if let Ok(event) = rx.try_recv() {
            match event {
                XrayEvent::StatusChanged(status) => {
                    assert_eq!(status, XrayStatus::Starting);
                }
                _ => panic!("Expected StatusChanged event"),
            }
        }
    }

    #[tokio::test]
    async fn test_health_info() {
        let xray = XrayCore::new();

        // Initially no health info
        assert!(xray.get_health().await.is_none());

        // Simulate health update
        let health = XrayHealth {
            pid: Some(1234),
            uptime: 60,
            last_check: std::time::SystemTime::now(),
            is_responsive: true,
        };

        {
            let mut h = xray.health.write().await;
            *h = Some(health.clone());
        }

        // Should have health info now
        let retrieved = xray.get_health().await;
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().pid, Some(1234));
    }

    #[test]
    fn test_log_parsing() {
        let line = "2024/01/01 12:00:00 [Info] Xray started";
        let entry = XrayCore::parse_log_line(line);

        assert_eq!(entry.level, "Info");
        assert!(entry.message.contains("Xray started"));
    }

    #[test]
    fn test_xray_health_serialization() {
        let health = XrayHealth {
            pid: Some(1234),
            uptime: 60,
            last_check: std::time::SystemTime::now(),
            is_responsive: true,
        };

        let json = serde_json::to_string(&health).unwrap();
        assert!(!json.is_empty());

        let _parsed: XrayHealth = serde_json::from_str(&json).unwrap();
    }

    #[test]
    fn test_xray_log_entry_serialization() {
        let entry = XrayLogEntry {
            timestamp: "2024/01/01 12:00:00".to_string(),
            level: "Info".to_string(),
            message: "Test message".to_string(),
        };

        let json = serde_json::to_string(&entry).unwrap();
        assert!(!json.is_empty());

        let _parsed: XrayLogEntry = serde_json::from_str(&json).unwrap();
    }
}
