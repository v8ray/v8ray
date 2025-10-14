//! Connection Management Module
//!
//! This module handles proxy connections, including connection state management,
//! statistics collection, and connection lifecycle.

pub mod reconnect;
pub mod stats;

use crate::config::ProxyServerConfig;
use crate::xray::{XrayCore, XrayEvent, XrayStatus};
use reconnect::ReconnectConfig;
use serde::{Deserialize, Serialize};
use stats::TrafficStatsCollector;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{broadcast, RwLock};
use tracing::{debug, error, info, warn};
use uuid::Uuid;

/// Connection state
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ConnectionState {
    /// Not connected
    Disconnected,
    /// Connecting to server
    Connecting,
    /// Connected to server
    Connected,
    /// Disconnecting from server
    Disconnecting,
    /// Reconnecting after error
    Reconnecting,
    /// Connection error
    Error(String),
}

/// Connection error type
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConnectionError {
    /// Xray process failed to start
    XrayStartFailed(String),
    /// Xray process crashed
    XrayCrashed(String),
    /// Configuration error
    ConfigError(String),
    /// Network error
    NetworkError(String),
    /// Timeout error
    Timeout(String),
    /// Unknown error
    Unknown(String),
}

/// Connection statistics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectionStats {
    /// Bytes uploaded
    pub upload: u64,
    /// Bytes downloaded
    pub download: u64,
    /// Connection start time
    pub start_time: chrono::DateTime<chrono::Utc>,
    /// Last activity time
    pub last_activity: chrono::DateTime<chrono::Utc>,
}

/// Connection information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Connection {
    /// Connection ID
    pub id: Uuid,
    /// Connection name
    pub name: String,
    /// Server address
    pub server: String,
    /// Connection state
    pub state: ConnectionState,
    /// Connection statistics
    pub stats: Option<ConnectionStats>,
    /// Proxy server configuration ID
    pub config_id: String,
    /// Last error
    pub last_error: Option<ConnectionError>,
    /// Reconnect attempts
    pub reconnect_attempts: u32,
}

/// Connection manager
pub struct ConnectionManager {
    /// Current connection
    current_connection: Arc<RwLock<Option<Connection>>>,
    /// Connection history
    history: Arc<RwLock<Vec<Connection>>>,
    /// Xray Core instance
    xray: Arc<XrayCore>,
    /// Current proxy configuration
    current_config: Arc<RwLock<Option<ProxyServerConfig>>>,
    /// Reconnect configuration
    reconnect_config: Arc<RwLock<ReconnectConfig>>,
    /// Reconnect task cancellation sender
    reconnect_cancel_tx: Arc<RwLock<Option<broadcast::Sender<()>>>>,
    /// Traffic statistics collector
    stats_collector: Arc<TrafficStatsCollector>,
}

impl Default for ConnectionManager {
    fn default() -> Self {
        Self::new()
    }
}

impl ConnectionManager {
    /// Create a new connection manager
    pub fn new() -> Self {
        Self {
            current_connection: Arc::new(RwLock::new(None)),
            history: Arc::new(RwLock::new(Vec::new())),
            xray: Arc::new(XrayCore::new()),
            current_config: Arc::new(RwLock::new(None)),
            reconnect_config: Arc::new(RwLock::new(ReconnectConfig::default())),
            reconnect_cancel_tx: Arc::new(RwLock::new(None)),
            stats_collector: Arc::new(TrafficStatsCollector::default()),
        }
    }

    /// Create a new connection manager with existing Xray instance
    pub fn with_xray(xray: Arc<XrayCore>) -> Self {
        Self {
            current_connection: Arc::new(RwLock::new(None)),
            history: Arc::new(RwLock::new(Vec::new())),
            xray,
            current_config: Arc::new(RwLock::new(None)),
            reconnect_config: Arc::new(RwLock::new(ReconnectConfig::default())),
            reconnect_cancel_tx: Arc::new(RwLock::new(None)),
            stats_collector: Arc::new(TrafficStatsCollector::default()),
        }
    }

    /// Create a new connection manager with custom reconnect config
    pub fn with_reconnect_config(reconnect_config: ReconnectConfig) -> Self {
        Self {
            current_connection: Arc::new(RwLock::new(None)),
            history: Arc::new(RwLock::new(Vec::new())),
            xray: Arc::new(XrayCore::new()),
            current_config: Arc::new(RwLock::new(None)),
            reconnect_config: Arc::new(RwLock::new(reconnect_config)),
            reconnect_cancel_tx: Arc::new(RwLock::new(None)),
            stats_collector: Arc::new(TrafficStatsCollector::default()),
        }
    }

    /// Get current connection state
    pub async fn get_state(&self) -> ConnectionState {
        let connection = self.current_connection.read().await;
        connection
            .as_ref()
            .map(|c| c.state.clone())
            .unwrap_or(ConnectionState::Disconnected)
    }

    /// Start a new connection with proxy configuration
    pub async fn connect_with_config(&self, config: ProxyServerConfig) -> crate::V8RayResult<()> {
        self.connect_with_config_and_mode(config, "global").await
    }

    /// Start a new connection with proxy configuration and mode
    pub async fn connect_with_config_and_mode(
        &self,
        config: ProxyServerConfig,
        mode: &str,
    ) -> crate::V8RayResult<()> {
        info!(
            "Starting connection to: {} with mode: {}",
            config.name, mode
        );

        // Disconnect existing connection if any
        if self.get_state().await != ConnectionState::Disconnected {
            debug!("Disconnecting existing connection");
            self.disconnect().await?;
        }

        // Create new connection
        let connection = Connection {
            id: Uuid::new_v4(),
            name: config.name.clone(),
            server: format!("{}:{}", config.server, config.port),
            state: ConnectionState::Connecting,
            stats: Some(ConnectionStats {
                upload: 0,
                download: 0,
                start_time: chrono::Utc::now(),
                last_activity: chrono::Utc::now(),
            }),
            config_id: config.id.clone(),
            last_error: None,
            reconnect_attempts: 0,
        };

        {
            let mut current = self.current_connection.write().await;
            *current = Some(connection);
        }

        // Store configuration
        {
            let mut current_config = self.current_config.write().await;
            *current_config = Some(config.clone());
        }

        // Generate Xray configuration with mode
        let xray_config = self.xray.generate_config_with_mode(&config, mode);

        // Start Xray with configuration
        match self.xray.start(xray_config).await {
            Ok(_) => {
                info!("Xray started successfully");
                let mut current = self.current_connection.write().await;
                if let Some(ref mut conn) = *current {
                    conn.state = ConnectionState::Connected;
                }
                Ok(())
            }
            Err(e) => {
                error!("Failed to start Xray: {}", e);
                let error_msg = e.to_string();
                let mut current = self.current_connection.write().await;
                if let Some(ref mut conn) = *current {
                    conn.state = ConnectionState::Error(error_msg.clone());
                    conn.last_error = Some(ConnectionError::XrayStartFailed(error_msg.clone()));
                }
                Err(crate::error::V8RayError::Xray(
                    crate::error::XrayError::Process(error_msg),
                ))
            }
        }
    }

    /// Start a new connection (legacy method for compatibility)
    pub async fn connect(&self, name: String, server: String) -> crate::V8RayResult<()> {
        warn!("Using legacy connect method, consider using connect_with_config");

        // Create a minimal config for legacy support
        let config = ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name,
            server: server.split(':').next().unwrap_or("127.0.0.1").to_string(),
            port: server
                .split(':')
                .nth(1)
                .and_then(|p| p.parse().ok())
                .unwrap_or(8080),
            protocol: crate::config::ProxyProtocol::Vless,
            settings: std::collections::HashMap::new(),
            stream_settings: None,
            tags: vec![],
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };

        self.connect_with_config(config).await
    }

    /// Disconnect current connection
    pub async fn disconnect(&self) -> crate::V8RayResult<()> {
        info!("Disconnecting current connection");

        // Update state to disconnecting
        {
            let mut current = self.current_connection.write().await;
            if let Some(ref mut conn) = *current {
                conn.state = ConnectionState::Disconnecting;
            }
        }

        // Stop Xray
        match self.xray.stop().await {
            Ok(_) => {
                info!("Xray stopped successfully");
            }
            Err(e) => {
                warn!("Error stopping Xray: {}", e);
            }
        }

        // Update connection state and move to history
        let mut current = self.current_connection.write().await;
        if let Some(ref mut conn) = *current {
            conn.state = ConnectionState::Disconnected;

            // Move to history
            let mut history = self.history.write().await;
            history.push(conn.clone());

            // Keep only last 100 connections in history
            if history.len() > 100 {
                history.remove(0);
            }
        }

        *current = None;

        // Clear current config
        {
            let mut current_config = self.current_config.write().await;
            *current_config = None;
        }

        Ok(())
    }

    /// Get current connection info
    pub async fn get_current_connection(&self) -> Option<Connection> {
        self.current_connection.read().await.clone()
    }

    /// Get connection history
    pub async fn get_history(&self) -> Vec<Connection> {
        self.history.read().await.clone()
    }

    /// Update connection statistics
    pub async fn update_stats(&self, upload: u64, download: u64) -> crate::V8RayResult<()> {
        // Update connection stats
        let mut current = self.current_connection.write().await;
        if let Some(ref mut conn) = *current {
            if let Some(ref mut stats) = conn.stats {
                stats.upload += upload;
                stats.download += download;
                stats.last_activity = chrono::Utc::now();
            }
        }

        // Update stats collector
        self.stats_collector.update_traffic(upload, download).await;

        Ok(())
    }

    /// Get current proxy configuration
    pub async fn get_current_config(&self) -> Option<ProxyServerConfig> {
        self.current_config.read().await.clone()
    }

    /// Get Xray status
    pub async fn get_xray_status(&self) -> XrayStatus {
        self.xray.get_status().await
    }

    /// Subscribe to Xray events
    pub fn subscribe_xray_events(&self) -> tokio::sync::broadcast::Receiver<XrayEvent> {
        self.xray.subscribe()
    }

    /// Check if connection is active
    pub async fn is_connected(&self) -> bool {
        matches!(self.get_state().await, ConnectionState::Connected)
    }

    /// Get connection uptime in seconds
    pub async fn get_uptime(&self) -> Option<i64> {
        let current = self.current_connection.read().await;
        current.as_ref().and_then(|conn| {
            conn.stats.as_ref().map(|stats| {
                let now = chrono::Utc::now();
                (now - stats.start_time).num_seconds()
            })
        })
    }

    /// Update connection state
    pub async fn update_state(&self, new_state: ConnectionState) {
        let mut current = self.current_connection.write().await;
        if let Some(ref mut conn) = *current {
            debug!(
                "Connection state changed: {:?} -> {:?}",
                conn.state, new_state
            );
            conn.state = new_state;
        }
    }

    /// Set connection error
    pub async fn set_error(&self, error: ConnectionError) {
        let mut current = self.current_connection.write().await;
        if let Some(ref mut conn) = *current {
            error!("Connection error: {:?}", error);
            conn.state = ConnectionState::Error(format!("{:?}", error));
            conn.last_error = Some(error);
        }
    }

    /// Increment reconnect attempts
    pub async fn increment_reconnect_attempts(&self) -> u32 {
        let mut current = self.current_connection.write().await;
        if let Some(ref mut conn) = *current {
            conn.reconnect_attempts += 1;
            conn.reconnect_attempts
        } else {
            0
        }
    }

    /// Reset reconnect attempts
    pub async fn reset_reconnect_attempts(&self) {
        let mut current = self.current_connection.write().await;
        if let Some(ref mut conn) = *current {
            conn.reconnect_attempts = 0;
        }
    }

    /// Get Xray instance
    pub fn get_xray(&self) -> Arc<XrayCore> {
        Arc::clone(&self.xray)
    }

    /// Set reconnect configuration
    pub async fn set_reconnect_config(&self, config: ReconnectConfig) {
        let mut reconnect_config = self.reconnect_config.write().await;
        *reconnect_config = config;
        info!("Reconnect configuration updated: {:?}", reconnect_config);
    }

    /// Get reconnect configuration
    pub async fn get_reconnect_config(&self) -> ReconnectConfig {
        self.reconnect_config.read().await.clone()
    }

    /// Enable auto-reconnect
    pub async fn enable_auto_reconnect(&self) {
        let mut config = self.reconnect_config.write().await;
        config.enabled = true;
        info!("Auto-reconnect enabled");
    }

    /// Disable auto-reconnect
    pub async fn disable_auto_reconnect(&self) {
        let mut config = self.reconnect_config.write().await;
        config.enabled = false;
        info!("Auto-reconnect disabled");

        // Cancel any ongoing reconnect task
        self.cancel_reconnect_task().await;
    }

    /// Cancel ongoing reconnect task
    async fn cancel_reconnect_task(&self) {
        let mut cancel_tx = self.reconnect_cancel_tx.write().await;
        if let Some(tx) = cancel_tx.take() {
            let _ = tx.send(());
            debug!("Reconnect task cancelled");
        }
    }

    /// Start auto-reconnect task
    pub async fn start_auto_reconnect(&self) {
        // Cancel any existing reconnect task
        self.cancel_reconnect_task().await;

        let config = self.get_reconnect_config().await;
        if !config.enabled {
            debug!("Auto-reconnect is disabled, not starting task");
            return;
        }

        let current_config = self.current_config.read().await.clone();
        if current_config.is_none() {
            warn!("No configuration available for reconnection");
            return;
        }

        let _proxy_config = current_config.unwrap();

        info!("Starting auto-reconnect task");

        // Create cancellation channel
        let (cancel_tx, mut cancel_rx) = broadcast::channel::<()>(1);
        {
            let mut tx = self.reconnect_cancel_tx.write().await;
            *tx = Some(cancel_tx);
        }

        // Clone necessary data for the task
        let current_connection = Arc::clone(&self.current_connection);
        let xray = Arc::clone(&self.xray);
        let current_config_arc = Arc::clone(&self.current_config);
        let reconnect_config_arc = Arc::clone(&self.reconnect_config);

        // Spawn reconnect task with loop
        tokio::spawn(async move {
            loop {
                // Get current attempts
                let attempts = {
                    let current = current_connection.read().await;
                    current.as_ref().map(|c| c.reconnect_attempts).unwrap_or(0)
                };

                // Check if we should continue
                let config = reconnect_config_arc.read().await.clone();
                if !config.should_reconnect(attempts) {
                    warn!("Reconnection not allowed (attempts: {})", attempts);
                    break;
                }

                let delay = config.calculate_delay(attempts);
                info!(
                    "Waiting {:?} before reconnection attempt {}",
                    delay,
                    attempts + 1
                );

                // Wait for delay or cancellation
                tokio::select! {
                    _ = tokio::time::sleep(delay) => {
                        info!("Attempting to reconnect (attempt {})...", attempts + 1);

                        // Increment reconnect attempts
                        {
                            let mut current = current_connection.write().await;
                            if let Some(ref mut conn) = *current {
                                conn.reconnect_attempts += 1;
                                conn.state = ConnectionState::Reconnecting;
                            }
                        }

                        // Get current config
                        let config_to_use = {
                            let cfg = current_config_arc.read().await;
                            cfg.clone()
                        };

                        if let Some(cfg) = config_to_use {
                            // Generate Xray configuration
                            let xray_config = {
                                let temp_xray = XrayCore::new();
                                temp_xray.generate_config(&cfg)
                            };

                            // Attempt to start Xray
                            match xray.start(xray_config).await {
                                Ok(_) => {
                                    info!("Reconnection successful");
                                    // Reset attempts and update state
                                    let mut current = current_connection.write().await;
                                    if let Some(ref mut conn) = *current {
                                        conn.reconnect_attempts = 0;
                                        conn.state = ConnectionState::Connected;
                                        conn.last_error = None;
                                    }
                                    break; // Exit loop on success
                                }
                                Err(e) => {
                                    error!("Reconnection failed: {}", e);
                                    let mut current = current_connection.write().await;
                                    if let Some(ref mut conn) = *current {
                                        conn.state = ConnectionState::Error(e.to_string());
                                        conn.last_error = Some(ConnectionError::XrayStartFailed(e.to_string()));
                                    }
                                    // Continue loop to try again
                                }
                            }
                        } else {
                            warn!("No configuration available for reconnection");
                            break;
                        }
                    }
                    _ = cancel_rx.recv() => {
                        info!("Reconnect task cancelled");
                        break;
                    }
                }
            }
        });
    }

    /// Monitor Xray events and trigger auto-reconnect on errors
    pub async fn start_monitoring_for_reconnect(&self) {
        let mut event_rx = self.subscribe_xray_events();

        let manager = Self {
            current_connection: Arc::clone(&self.current_connection),
            history: Arc::clone(&self.history),
            xray: Arc::clone(&self.xray),
            current_config: Arc::clone(&self.current_config),
            reconnect_config: Arc::clone(&self.reconnect_config),
            reconnect_cancel_tx: Arc::clone(&self.reconnect_cancel_tx),
            stats_collector: Arc::clone(&self.stats_collector),
        };

        tokio::spawn(async move {
            while let Ok(event) = event_rx.recv().await {
                match event {
                    XrayEvent::StatusChanged(status) => {
                        debug!("Xray status changed: {:?}", status);
                        if matches!(status, XrayStatus::Error(_)) {
                            warn!("Xray error detected, triggering auto-reconnect");
                            manager.start_auto_reconnect().await;
                        }
                    }
                    XrayEvent::LogReceived(log) => {
                        // Check for critical errors in logs
                        if log.message.contains("failed") || log.message.contains("error") {
                            debug!("Potential error in Xray log: {}", log.message);
                        }
                    }
                    _ => {}
                }
            }
        });
    }

    /// Get traffic statistics collector
    pub fn get_stats_collector(&self) -> Arc<TrafficStatsCollector> {
        Arc::clone(&self.stats_collector)
    }

    /// Get current traffic totals
    pub async fn get_traffic_totals(&self) -> (u64, u64) {
        self.stats_collector.get_totals().await
    }

    /// Get current traffic speeds
    pub async fn get_traffic_speeds(&self) -> (u64, u64) {
        self.stats_collector.get_current_speeds().await
    }

    /// Start automatic traffic statistics collection
    pub async fn start_stats_collection(&self, interval: Duration) {
        info!(
            "Starting traffic statistics collection with interval: {:?}",
            interval
        );
        self.stats_collector.start_auto_snapshot(interval).await;
    }

    /// Reset traffic statistics
    pub async fn reset_stats(&self) {
        self.stats_collector.reset().await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::ProxyProtocol;
    use std::collections::HashMap;

    fn create_test_config() -> ProxyServerConfig {
        let mut settings = HashMap::new();
        settings.insert("id".to_string(), serde_json::json!("test-uuid"));

        ProxyServerConfig {
            id: Uuid::new_v4().to_string(),
            name: "Test Server".to_string(),
            server: "example.com".to_string(),
            port: 443,
            protocol: ProxyProtocol::Vless,
            settings,
            stream_settings: None,
            tags: vec![],
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        }
    }

    #[tokio::test]
    async fn test_connection_manager() {
        let manager = ConnectionManager::new();

        // Initial state should be disconnected
        assert_eq!(manager.get_state().await, ConnectionState::Disconnected);
        assert!(!manager.is_connected().await);
    }

    #[tokio::test]
    async fn test_connection_state_transitions() {
        let manager = ConnectionManager::new();
        let config = create_test_config();

        // Create a connection first
        let connection = Connection {
            id: Uuid::new_v4(),
            name: config.name.clone(),
            server: format!("{}:{}", config.server, config.port),
            state: ConnectionState::Disconnected,
            stats: None,
            config_id: config.id.clone(),
            last_error: None,
            reconnect_attempts: 0,
        };

        {
            let mut current = manager.current_connection.write().await;
            *current = Some(connection);
        }

        // Test state updates
        manager.update_state(ConnectionState::Connecting).await;
        assert_eq!(manager.get_state().await, ConnectionState::Connecting);

        manager.update_state(ConnectionState::Connected).await;
        assert_eq!(manager.get_state().await, ConnectionState::Connected);
        assert!(manager.is_connected().await);

        manager.update_state(ConnectionState::Disconnecting).await;
        assert_eq!(manager.get_state().await, ConnectionState::Disconnecting);
    }

    #[tokio::test]
    async fn test_connection_stats() {
        let manager = ConnectionManager::new();
        let config = create_test_config();

        // Create a connection manually for testing
        let connection = Connection {
            id: Uuid::new_v4(),
            name: config.name.clone(),
            server: format!("{}:{}", config.server, config.port),
            state: ConnectionState::Connected,
            stats: Some(ConnectionStats {
                upload: 0,
                download: 0,
                start_time: chrono::Utc::now(),
                last_activity: chrono::Utc::now(),
            }),
            config_id: config.id.clone(),
            last_error: None,
            reconnect_attempts: 0,
        };

        {
            let mut current = manager.current_connection.write().await;
            *current = Some(connection);
        }

        manager.update_stats(1024, 2048).await.unwrap();

        let connection = manager.get_current_connection().await.unwrap();
        let stats = connection.stats.unwrap();
        assert_eq!(stats.upload, 1024);
        assert_eq!(stats.download, 2048);
    }

    #[tokio::test]
    async fn test_connection_error_handling() {
        let manager = ConnectionManager::new();
        let config = create_test_config();

        // Create a connection first
        let connection = Connection {
            id: Uuid::new_v4(),
            name: config.name.clone(),
            server: format!("{}:{}", config.server, config.port),
            state: ConnectionState::Connected,
            stats: None,
            config_id: config.id.clone(),
            last_error: None,
            reconnect_attempts: 0,
        };

        {
            let mut current = manager.current_connection.write().await;
            *current = Some(connection);
        }

        // Set an error
        let error = ConnectionError::NetworkError("Test error".to_string());
        manager.set_error(error.clone()).await;

        let connection = manager.get_current_connection().await;
        assert!(connection.is_some());
        let conn = connection.unwrap();
        assert!(matches!(conn.state, ConnectionState::Error(_)));
        assert!(conn.last_error.is_some());
    }

    #[tokio::test]
    async fn test_reconnect_attempts() {
        let manager = ConnectionManager::new();
        let config = create_test_config();

        // Create a connection
        let connection = Connection {
            id: Uuid::new_v4(),
            name: config.name.clone(),
            server: format!("{}:{}", config.server, config.port),
            state: ConnectionState::Connected,
            stats: None,
            config_id: config.id.clone(),
            last_error: None,
            reconnect_attempts: 0,
        };

        {
            let mut current = manager.current_connection.write().await;
            *current = Some(connection);
        }

        // Test increment
        let attempts = manager.increment_reconnect_attempts().await;
        assert_eq!(attempts, 1);

        let attempts = manager.increment_reconnect_attempts().await;
        assert_eq!(attempts, 2);

        // Test reset
        manager.reset_reconnect_attempts().await;
        let connection = manager.get_current_connection().await.unwrap();
        assert_eq!(connection.reconnect_attempts, 0);
    }

    #[tokio::test]
    async fn test_connection_uptime() {
        let manager = ConnectionManager::new();
        let config = create_test_config();

        // Create a connection with start time
        let start_time = chrono::Utc::now() - chrono::Duration::seconds(60);
        let connection = Connection {
            id: Uuid::new_v4(),
            name: config.name.clone(),
            server: format!("{}:{}", config.server, config.port),
            state: ConnectionState::Connected,
            stats: Some(ConnectionStats {
                upload: 0,
                download: 0,
                start_time,
                last_activity: chrono::Utc::now(),
            }),
            config_id: config.id.clone(),
            last_error: None,
            reconnect_attempts: 0,
        };

        {
            let mut current = manager.current_connection.write().await;
            *current = Some(connection);
        }

        let uptime = manager.get_uptime().await;
        assert!(uptime.is_some());
        assert!(uptime.unwrap() >= 60);
    }

    #[tokio::test]
    async fn test_reconnect_config() {
        let manager = ConnectionManager::new();

        // Test default config
        let config = manager.get_reconnect_config().await;
        assert!(config.enabled);
        assert_eq!(config.max_attempts, 5);

        // Test setting new config
        let new_config = ReconnectConfig::immediate(3);
        manager.set_reconnect_config(new_config.clone()).await;

        let updated_config = manager.get_reconnect_config().await;
        assert!(updated_config.enabled);
        assert_eq!(updated_config.max_attempts, 3);
    }

    #[tokio::test]
    async fn test_enable_disable_auto_reconnect() {
        let manager = ConnectionManager::new();

        // Initially enabled
        let config = manager.get_reconnect_config().await;
        assert!(config.enabled);

        // Disable
        manager.disable_auto_reconnect().await;
        let config = manager.get_reconnect_config().await;
        assert!(!config.enabled);

        // Enable
        manager.enable_auto_reconnect().await;
        let config = manager.get_reconnect_config().await;
        assert!(config.enabled);
    }

    #[tokio::test]
    async fn test_reconnect_with_disabled_config() {
        let manager = ConnectionManager::with_reconnect_config(ReconnectConfig::disabled());

        let config = manager.get_reconnect_config().await;
        assert!(!config.enabled);
        assert_eq!(config.max_attempts, 0);
    }

    #[tokio::test]
    async fn test_traffic_stats() {
        let manager = ConnectionManager::new();

        // Initial state
        let (up, down) = manager.get_traffic_totals().await;
        assert_eq!(up, 0);
        assert_eq!(down, 0);

        // Update stats
        manager.update_stats(1024, 2048).await.unwrap();
        let (up, down) = manager.get_traffic_totals().await;
        assert_eq!(up, 1024);
        assert_eq!(down, 2048);

        // Update again
        manager.update_stats(512, 1024).await.unwrap();
        let (up, down) = manager.get_traffic_totals().await;
        assert_eq!(up, 1536);
        assert_eq!(down, 3072);
    }

    #[tokio::test]
    async fn test_reset_stats() {
        let manager = ConnectionManager::new();

        manager.update_stats(1000, 2000).await.unwrap();
        let (up, down) = manager.get_traffic_totals().await;
        assert_eq!(up, 1000);
        assert_eq!(down, 2000);

        manager.reset_stats().await;
        let (up, down) = manager.get_traffic_totals().await;
        assert_eq!(up, 0);
        assert_eq!(down, 0);
    }

    #[tokio::test]
    async fn test_stats_collector_integration() {
        let manager = ConnectionManager::new();
        let collector = manager.get_stats_collector();

        // Update through manager
        manager.update_stats(500, 1000).await.unwrap();

        // Check through collector
        let (up, down) = collector.get_totals().await;
        assert_eq!(up, 500);
        assert_eq!(down, 1000);
    }
}
