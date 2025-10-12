//! Connection Management Module
//!
//! This module handles proxy connections, including connection state management,
//! statistics collection, and connection lifecycle.

use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

/// Connection state
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Connected,
    Disconnecting,
    Error(String),
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
}

/// Connection manager
pub struct ConnectionManager {
    /// Current connection
    current_connection: Arc<RwLock<Option<Connection>>>,
    /// Connection history
    history: Arc<RwLock<Vec<Connection>>>,
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

    /// Start a new connection
    pub async fn connect(&self, name: String, server: String) -> crate::Result<()> {
        let mut current = self.current_connection.write().await;

        // Disconnect existing connection if any
        if let Some(ref mut conn) = *current {
            conn.state = ConnectionState::Disconnecting;
            // TODO: Implement actual disconnection logic
            conn.state = ConnectionState::Disconnected;
        }

        // Create new connection
        let connection = Connection {
            id: Uuid::new_v4(),
            name,
            server,
            state: ConnectionState::Connecting,
            stats: Some(ConnectionStats {
                upload: 0,
                download: 0,
                start_time: chrono::Utc::now(),
                last_activity: chrono::Utc::now(),
            }),
        };

        *current = Some(connection);

        // TODO: Implement actual connection logic
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

        if let Some(ref mut conn) = *current {
            conn.state = ConnectionState::Connected;
        }

        Ok(())
    }

    /// Disconnect current connection
    pub async fn disconnect(&self) -> crate::Result<()> {
        let mut current = self.current_connection.write().await;

        if let Some(ref mut conn) = *current {
            conn.state = ConnectionState::Disconnecting;

            // TODO: Implement actual disconnection logic
            tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

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
    pub async fn update_stats(&self, upload: u64, download: u64) -> crate::Result<()> {
        let mut current = self.current_connection.write().await;

        if let Some(ref mut conn) = *current {
            if let Some(ref mut stats) = conn.stats {
                stats.upload += upload;
                stats.download += download;
                stats.last_activity = chrono::Utc::now();
            }
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_connection_manager() {
        let manager = ConnectionManager::new();

        // Initial state should be disconnected
        assert_eq!(manager.get_state().await, ConnectionState::Disconnected);

        // Test connection
        manager
            .connect("Test".to_string(), "127.0.0.1:8080".to_string())
            .await
            .unwrap();
        assert_eq!(manager.get_state().await, ConnectionState::Connected);

        // Test disconnection
        manager.disconnect().await.unwrap();
        assert_eq!(manager.get_state().await, ConnectionState::Disconnected);
    }

    #[tokio::test]
    async fn test_connection_stats() {
        let manager = ConnectionManager::new();

        manager
            .connect("Test".to_string(), "127.0.0.1:8080".to_string())
            .await
            .unwrap();
        manager.update_stats(1024, 2048).await.unwrap();

        let connection = manager.get_current_connection().await.unwrap();
        let stats = connection.stats.unwrap();
        assert_eq!(stats.upload, 1024);
        assert_eq!(stats.download, 2048);
    }
}
