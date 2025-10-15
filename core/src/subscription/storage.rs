//! Subscription Storage
//!
//! This module provides persistent storage for subscriptions and servers using SQLite.

use super::{Server, Subscription, SubscriptionStatus};
use crate::error::{StorageError, StorageResult};
use sqlx::{
    sqlite::{SqliteConnectOptions, SqlitePool},
    Row,
};
use std::path::Path;
use std::str::FromStr;
use tracing::{debug, info};
use uuid::Uuid;

/// Subscription storage manager
pub struct SubscriptionStorage {
    /// SQLite connection pool
    pool: SqlitePool,
}

impl SubscriptionStorage {
    /// Create a new storage manager with the given database path
    pub async fn new<P: AsRef<Path>>(db_path: P) -> StorageResult<Self> {
        let path = db_path.as_ref();
        info!("Opening subscription database: {}", path.display());

        // Use SqliteConnectOptions for better control
        let options = SqliteConnectOptions::from_str(&format!("sqlite://{}", path.display()))?
            .create_if_missing(true);

        let pool = SqlitePool::connect_with(options).await?;

        let storage = Self { pool };
        storage.init_tables().await?;

        Ok(storage)
    }

    /// Create an in-memory storage (for testing)
    pub async fn new_in_memory() -> StorageResult<Self> {
        info!("Creating in-memory subscription database");

        let pool = SqlitePool::connect("sqlite::memory:").await?;

        let storage = Self { pool };
        storage.init_tables().await?;

        Ok(storage)
    }

    /// Initialize database tables
    async fn init_tables(&self) -> StorageResult<()> {
        debug!("Initializing subscription database tables");

        // Create subscriptions table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS subscriptions (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                url TEXT NOT NULL,
                last_update TEXT,
                server_count INTEGER NOT NULL DEFAULT 0,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            "#,
        )
        .execute(&self.pool)
        .await?;

        // Create servers table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS servers (
                id TEXT PRIMARY KEY,
                subscription_id TEXT NOT NULL,
                name TEXT NOT NULL,
                address TEXT NOT NULL,
                port INTEGER NOT NULL,
                protocol TEXT NOT NULL,
                config TEXT NOT NULL,
                stream_settings TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
            )
            "#,
        )
        .execute(&self.pool)
        .await?;

        // Add stream_settings column if it doesn't exist (migration for existing databases)
        let _ = sqlx::query(
            r#"
            ALTER TABLE servers ADD COLUMN stream_settings TEXT
            "#,
        )
        .execute(&self.pool)
        .await; // Ignore error if column already exists

        // Create index on subscription_id for faster queries
        sqlx::query(
            r#"
            CREATE INDEX IF NOT EXISTS idx_servers_subscription_id 
            ON servers(subscription_id)
            "#,
        )
        .execute(&self.pool)
        .await?;

        info!("Database tables initialized");
        Ok(())
    }

    /// Save a subscription to the database
    pub async fn save_subscription(&self, subscription: &Subscription) -> StorageResult<()> {
        debug!("Saving subscription: {}", subscription.id);

        let status_str = match &subscription.status {
            SubscriptionStatus::Active => "active",
            SubscriptionStatus::Inactive => "inactive",
            SubscriptionStatus::Error(msg) => &format!("error:{}", msg),
            SubscriptionStatus::Updating => "updating",
        };

        sqlx::query(
            r#"
            INSERT OR REPLACE INTO subscriptions 
            (id, name, url, last_update, server_count, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
            "#,
        )
        .bind(subscription.id.to_string())
        .bind(&subscription.name)
        .bind(&subscription.url)
        .bind(subscription.last_update.map(|dt| dt.to_rfc3339()))
        .bind(subscription.server_count as i64)
        .bind(status_str)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Load all subscriptions from the database
    pub async fn load_subscriptions(&self) -> StorageResult<Vec<Subscription>> {
        debug!("Loading all subscriptions");

        let rows = sqlx::query("SELECT * FROM subscriptions")
            .fetch_all(&self.pool)
            .await?;

        let mut subscriptions = Vec::new();

        for row in rows {
            let id: String = row.get("id");
            let status_str: String = row.get("status");
            let last_update_str: Option<String> = row.get("last_update");

            let status = if status_str == "active" {
                SubscriptionStatus::Active
            } else if status_str == "inactive" {
                SubscriptionStatus::Inactive
            } else if status_str == "updating" {
                SubscriptionStatus::Updating
            } else if let Some(msg) = status_str.strip_prefix("error:") {
                SubscriptionStatus::Error(msg.to_string())
            } else {
                SubscriptionStatus::Inactive
            };

            let last_update = last_update_str
                .and_then(|s| chrono::DateTime::parse_from_rfc3339(&s).ok())
                .map(|dt| dt.with_timezone(&chrono::Utc));

            subscriptions.push(Subscription {
                id: Uuid::parse_str(&id)
                    .map_err(|e| StorageError::Parse(format!("Invalid UUID: {}", e)))?,
                name: row.get("name"),
                url: row.get("url"),
                last_update,
                server_count: row.get::<i64, _>("server_count") as usize,
                status,
            });
        }

        info!("Loaded {} subscriptions", subscriptions.len());
        Ok(subscriptions)
    }

    /// Delete a subscription from the database
    pub async fn delete_subscription(&self, id: Uuid) -> StorageResult<()> {
        debug!("Deleting subscription: {}", id);

        sqlx::query("DELETE FROM subscriptions WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        // Also delete associated servers
        self.delete_servers_for_subscription(id).await?;

        Ok(())
    }

    /// Save a server to the database
    pub async fn save_server(&self, server: &Server) -> StorageResult<()> {
        debug!("Saving server: {}", server.id);

        let config_json = serde_json::to_string(&server.config)
            .map_err(|e| StorageError::Serialization(e.to_string()))?;

        let stream_settings_json = server
            .stream_settings
            .as_ref()
            .map(|s| serde_json::to_string(s))
            .transpose()
            .map_err(|e| StorageError::Serialization(e.to_string()))?;

        sqlx::query(
            r#"
            INSERT OR REPLACE INTO servers
            (id, subscription_id, name, address, port, protocol, config, stream_settings, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
            "#,
        )
        .bind(server.id.to_string())
        .bind(server.subscription_id.to_string())
        .bind(&server.name)
        .bind(&server.address)
        .bind(server.port as i64)
        .bind(&server.protocol)
        .bind(config_json)
        .bind(stream_settings_json)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Load all servers from the database
    pub async fn load_servers(&self) -> StorageResult<Vec<Server>> {
        debug!("Loading all servers");

        let rows = sqlx::query("SELECT * FROM servers")
            .fetch_all(&self.pool)
            .await?;

        let mut servers = Vec::new();

        for row in rows {
            let id: String = row.get("id");
            let subscription_id: String = row.get("subscription_id");
            let config_json: String = row.get("config");

            let config = serde_json::from_str(&config_json)
                .map_err(|e| StorageError::Parse(format!("Invalid config JSON: {}", e)))?;

            let stream_settings_json: Option<String> = row.try_get("stream_settings").ok();
            let stream_settings =
                stream_settings_json.and_then(|json| serde_json::from_str(&json).ok());

            servers.push(Server {
                id: Uuid::parse_str(&id)
                    .map_err(|e| StorageError::Parse(format!("Invalid UUID: {}", e)))?,
                subscription_id: Uuid::parse_str(&subscription_id)
                    .map_err(|e| StorageError::Parse(format!("Invalid UUID: {}", e)))?,
                name: row.get("name"),
                address: row.get("address"),
                port: row.get::<i64, _>("port") as u16,
                protocol: row.get("protocol"),
                config,
                stream_settings,
            });
        }

        info!("Loaded {} servers", servers.len());
        Ok(servers)
    }

    /// Load servers for a specific subscription
    pub async fn load_servers_for_subscription(
        &self,
        subscription_id: Uuid,
    ) -> StorageResult<Vec<Server>> {
        debug!("Loading servers for subscription: {}", subscription_id);

        let rows = sqlx::query("SELECT * FROM servers WHERE subscription_id = ?")
            .bind(subscription_id.to_string())
            .fetch_all(&self.pool)
            .await?;

        let mut servers = Vec::new();

        for row in rows {
            let id: String = row.get("id");
            let config_json: String = row.get("config");

            let config = serde_json::from_str(&config_json)
                .map_err(|e| StorageError::Parse(format!("Invalid config JSON: {}", e)))?;

            let stream_settings_json: Option<String> = row.try_get("stream_settings").ok();
            let stream_settings =
                stream_settings_json.and_then(|json| serde_json::from_str(&json).ok());

            servers.push(Server {
                id: Uuid::parse_str(&id)
                    .map_err(|e| StorageError::Parse(format!("Invalid UUID: {}", e)))?,
                subscription_id,
                name: row.get("name"),
                address: row.get("address"),
                port: row.get::<i64, _>("port") as u16,
                protocol: row.get("protocol"),
                config,
                stream_settings,
            });
        }

        Ok(servers)
    }

    /// Delete all servers for a subscription
    pub async fn delete_servers_for_subscription(
        &self,
        subscription_id: Uuid,
    ) -> StorageResult<()> {
        debug!("Deleting servers for subscription: {}", subscription_id);

        sqlx::query("DELETE FROM servers WHERE subscription_id = ?")
            .bind(subscription_id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    #[tokio::test]
    async fn test_storage_creation() {
        let storage = SubscriptionStorage::new_in_memory().await;
        assert!(storage.is_ok());
    }

    #[tokio::test]
    async fn test_save_and_load_subscription() {
        let storage = SubscriptionStorage::new_in_memory().await.unwrap();

        let subscription = Subscription {
            id: Uuid::new_v4(),
            name: "Test Subscription".to_string(),
            url: "https://example.com/sub".to_string(),
            last_update: Some(chrono::Utc::now()),
            server_count: 5,
            status: SubscriptionStatus::Active,
        };

        // Save subscription
        storage.save_subscription(&subscription).await.unwrap();

        // Load subscriptions
        let loaded = storage.load_subscriptions().await.unwrap();
        assert_eq!(loaded.len(), 1);
        assert_eq!(loaded[0].id, subscription.id);
        assert_eq!(loaded[0].name, subscription.name);
        assert_eq!(loaded[0].url, subscription.url);
        assert_eq!(loaded[0].server_count, subscription.server_count);
    }

    #[tokio::test]
    async fn test_delete_subscription() {
        let storage = SubscriptionStorage::new_in_memory().await.unwrap();

        let subscription = Subscription {
            id: Uuid::new_v4(),
            name: "Test".to_string(),
            url: "https://example.com".to_string(),
            last_update: None,
            server_count: 0,
            status: SubscriptionStatus::Inactive,
        };

        storage.save_subscription(&subscription).await.unwrap();
        storage.delete_subscription(subscription.id).await.unwrap();

        let loaded = storage.load_subscriptions().await.unwrap();
        assert!(loaded.is_empty());
    }

    #[tokio::test]
    async fn test_save_and_load_server() {
        let storage = SubscriptionStorage::new_in_memory().await.unwrap();

        // First create a subscription
        let subscription_id = Uuid::new_v4();
        let subscription = Subscription {
            id: subscription_id,
            name: "Test Subscription".to_string(),
            url: "https://example.com".to_string(),
            last_update: None,
            server_count: 0,
            status: SubscriptionStatus::Inactive,
        };
        storage.save_subscription(&subscription).await.unwrap();

        // Now create a server
        let server = Server {
            id: Uuid::new_v4(),
            subscription_id,
            name: "Test Server".to_string(),
            address: "example.com".to_string(),
            port: 443,
            protocol: "vmess".to_string(),
            config: HashMap::new(),
            stream_settings: None,
        };

        // Save server
        storage.save_server(&server).await.unwrap();

        // Load servers
        let loaded = storage.load_servers().await.unwrap();
        assert_eq!(loaded.len(), 1);
        assert_eq!(loaded[0].id, server.id);
        assert_eq!(loaded[0].name, server.name);
        assert_eq!(loaded[0].address, server.address);
        assert_eq!(loaded[0].port, server.port);
    }

    #[tokio::test]
    async fn test_load_servers_for_subscription() {
        let storage = SubscriptionStorage::new_in_memory().await.unwrap();

        let sub1_id = Uuid::new_v4();
        let sub2_id = Uuid::new_v4();

        // Create subscriptions first
        let sub1 = Subscription {
            id: sub1_id,
            name: "Subscription 1".to_string(),
            url: "https://example.com".to_string(),
            last_update: None,
            server_count: 0,
            status: SubscriptionStatus::Inactive,
        };
        storage.save_subscription(&sub1).await.unwrap();

        let sub2 = Subscription {
            id: sub2_id,
            name: "Subscription 2".to_string(),
            url: "https://example2.com".to_string(),
            last_update: None,
            server_count: 0,
            status: SubscriptionStatus::Inactive,
        };
        storage.save_subscription(&sub2).await.unwrap();

        // Add servers for subscription 1
        for i in 0..3 {
            let server = Server {
                id: Uuid::new_v4(),
                subscription_id: sub1_id,
                name: format!("Server {}", i),
                address: "example.com".to_string(),
                port: 443,
                protocol: "vmess".to_string(),
                config: HashMap::new(),
                stream_settings: None,
            };
            storage.save_server(&server).await.unwrap();
        }

        // Add servers for subscription 2
        for i in 0..2 {
            let server = Server {
                id: Uuid::new_v4(),
                subscription_id: sub2_id,
                name: format!("Server {}", i),
                address: "example2.com".to_string(),
                port: 443,
                protocol: "vless".to_string(),
                config: HashMap::new(),
                stream_settings: None,
            };
            storage.save_server(&server).await.unwrap();
        }

        // Load servers for subscription 1
        let sub1_servers = storage
            .load_servers_for_subscription(sub1_id)
            .await
            .unwrap();
        assert_eq!(sub1_servers.len(), 3);

        // Load servers for subscription 2
        let sub2_servers = storage
            .load_servers_for_subscription(sub2_id)
            .await
            .unwrap();
        assert_eq!(sub2_servers.len(), 2);
    }

    #[tokio::test]
    async fn test_delete_servers_for_subscription() {
        let storage = SubscriptionStorage::new_in_memory().await.unwrap();

        let subscription_id = Uuid::new_v4();

        // Create subscription first
        let subscription = Subscription {
            id: subscription_id,
            name: "Test Subscription".to_string(),
            url: "https://example.com".to_string(),
            last_update: None,
            server_count: 0,
            status: SubscriptionStatus::Inactive,
        };
        storage.save_subscription(&subscription).await.unwrap();

        // Add servers
        for i in 0..3 {
            let server = Server {
                id: Uuid::new_v4(),
                subscription_id,
                name: format!("Server {}", i),
                address: "example.com".to_string(),
                port: 443,
                protocol: "vmess".to_string(),
                config: HashMap::new(),
                stream_settings: None,
            };
            storage.save_server(&server).await.unwrap();
        }

        // Delete servers
        storage
            .delete_servers_for_subscription(subscription_id)
            .await
            .unwrap();

        // Verify deletion
        let servers = storage
            .load_servers_for_subscription(subscription_id)
            .await
            .unwrap();
        assert!(servers.is_empty());
    }
}
