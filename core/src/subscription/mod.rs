//! Subscription Management Module
//!
//! This module handles subscription management including parsing different
//! subscription formats, automatic updates, and server list management.

mod http_client;
mod parser;
mod scheduler;
mod storage;

pub use http_client::{HttpClientConfig, SubscriptionHttpClient};
pub use parser::{SubscriptionFormat, SubscriptionParser};
pub use scheduler::{SchedulerConfig, SubscriptionScheduler};
pub use storage::SubscriptionStorage;

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

/// Subscription information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Subscription {
    /// Subscription ID
    pub id: Uuid,
    /// Subscription name
    pub name: String,
    /// Subscription URL
    pub url: String,
    /// Last update time
    pub last_update: Option<chrono::DateTime<chrono::Utc>>,
    /// Server count
    pub server_count: usize,
    /// Subscription status
    pub status: SubscriptionStatus,
}

/// Subscription status
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SubscriptionStatus {
    /// Subscription is active
    Active,
    /// Subscription is inactive
    Inactive,
    /// Subscription has error
    Error(String),
    /// Subscription is updating
    Updating,
}

/// Server information from subscription
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Server {
    /// Server ID
    pub id: Uuid,
    /// Server name
    pub name: String,
    /// Server address
    pub address: String,
    /// Server port
    pub port: u16,
    /// Protocol type
    pub protocol: String,
    /// Server configuration
    pub config: HashMap<String, serde_json::Value>,
    /// Subscription ID this server belongs to
    pub subscription_id: Uuid,
}

/// Subscription manager
pub struct SubscriptionManager {
    /// List of subscriptions
    subscriptions: Vec<Subscription>,
    /// List of servers from all subscriptions
    servers: Vec<Server>,
    /// HTTP client for fetching subscriptions
    http_client: SubscriptionHttpClient,
}

impl Default for SubscriptionManager {
    fn default() -> Self {
        Self::new()
    }
}

impl SubscriptionManager {
    /// Create a new subscription manager
    pub fn new() -> Self {
        Self {
            subscriptions: Vec::new(),
            servers: Vec::new(),
            http_client: SubscriptionHttpClient::new().expect("Failed to create HTTP client"),
        }
    }

    /// Create a new subscription manager with custom HTTP client config
    pub fn with_http_config(config: HttpClientConfig) -> crate::V8RayResult<Self> {
        Ok(Self {
            subscriptions: Vec::new(),
            servers: Vec::new(),
            http_client: SubscriptionHttpClient::with_config(config)?,
        })
    }

    /// Add a new subscription
    pub async fn add_subscription(
        &mut self,
        name: String,
        url: String,
    ) -> crate::V8RayResult<Uuid> {
        let subscription = Subscription {
            id: Uuid::new_v4(),
            name,
            url,
            last_update: None,
            server_count: 0,
            status: SubscriptionStatus::Inactive,
        };

        let id = subscription.id;
        self.subscriptions.push(subscription);

        // Try to update the subscription immediately
        if let Err(e) = self.update_subscription(id).await {
            tracing::warn!("Failed to update subscription {}: {}", id, e);
        }

        Ok(id)
    }

    /// Remove a subscription
    pub fn remove_subscription(&mut self, id: Uuid) -> crate::V8RayResult<()> {
        // Remove subscription
        self.subscriptions.retain(|s| s.id != id);

        // Remove associated servers
        self.servers.retain(|s| s.subscription_id != id);

        Ok(())
    }

    /// Update a specific subscription
    pub async fn update_subscription(&mut self, id: Uuid) -> crate::V8RayResult<()> {
        let subscription = self
            .subscriptions
            .iter_mut()
            .find(|s| s.id == id)
            .ok_or_else(|| {
                crate::error::V8RayError::Generic("Subscription not found".to_string())
            })?;

        subscription.status = SubscriptionStatus::Updating;

        // Fetch subscription content
        let content = match self.http_client.fetch_subscription(&subscription.url).await {
            Ok(content) => content,
            Err(e) => {
                subscription.status = SubscriptionStatus::Error(e.to_string());
                return Err(e.into());
            }
        };

        // Parse subscription content
        let proxy_configs = match SubscriptionParser::parse(&content) {
            Ok(configs) => configs,
            Err(e) => {
                subscription.status = SubscriptionStatus::Error(e.to_string());
                return Err(e.into());
            }
        };

        // Convert ProxyServerConfig to Server
        let new_servers: Vec<Server> = proxy_configs
            .into_iter()
            .map(|config| Server {
                id: Uuid::new_v4(),
                name: config.name,
                address: config.server,
                port: config.port,
                protocol: format!("{:?}", config.protocol).to_lowercase(),
                config: config.settings,
                subscription_id: id,
            })
            .collect();

        // Remove old servers for this subscription
        self.servers.retain(|s| s.subscription_id != id);

        // Add new servers
        self.servers.extend(new_servers);

        // Update subscription info
        subscription.last_update = Some(chrono::Utc::now());
        subscription.server_count = self
            .servers
            .iter()
            .filter(|s| s.subscription_id == id)
            .count();
        subscription.status = SubscriptionStatus::Active;

        tracing::info!(
            "Updated subscription '{}': {} servers",
            subscription.name,
            subscription.server_count
        );

        Ok(())
    }

    /// Update all subscriptions
    pub async fn update_all_subscriptions(&mut self) -> crate::V8RayResult<()> {
        let subscription_ids: Vec<Uuid> = self.subscriptions.iter().map(|s| s.id).collect();

        for id in subscription_ids {
            if let Err(e) = self.update_subscription(id).await {
                tracing::error!("Failed to update subscription {}: {}", id, e);

                // Mark subscription as error
                if let Some(subscription) = self.subscriptions.iter_mut().find(|s| s.id == id) {
                    subscription.status = SubscriptionStatus::Error(e.to_string());
                }
            }
        }

        Ok(())
    }

    /// Get all subscriptions
    pub fn get_subscriptions(&self) -> &[Subscription] {
        &self.subscriptions
    }

    /// Get all servers
    pub fn get_servers(&self) -> &[Server] {
        &self.servers
    }

    /// Get servers for a specific subscription
    pub fn get_servers_for_subscription(&self, subscription_id: Uuid) -> Vec<&Server> {
        self.servers
            .iter()
            .filter(|s| s.subscription_id == subscription_id)
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_subscription_manager_basic() {
        let mut manager = SubscriptionManager::new();

        // Add subscription (will fail to fetch, but subscription should be added)
        let id = manager
            .add_subscription(
                "Test Subscription".to_string(),
                "https://nonexistent-domain-12345.com/subscription".to_string(),
            )
            .await
            .unwrap();

        // Check subscription was added
        assert_eq!(manager.get_subscriptions().len(), 1);
        assert_eq!(manager.get_subscriptions()[0].id, id);
        assert_eq!(manager.get_subscriptions()[0].name, "Test Subscription");

        // The subscription should have error status since the URL doesn't exist
        // But it should still be in the list
        assert!(matches!(
            manager.get_subscriptions()[0].status,
            SubscriptionStatus::Error(_) | SubscriptionStatus::Inactive
        ));

        // Remove subscription
        manager.remove_subscription(id).unwrap();
        assert!(manager.get_subscriptions().is_empty());
        assert!(manager.get_servers().is_empty());
    }

    #[tokio::test]
    async fn test_subscription_with_mock_data() {
        let mut manager = SubscriptionManager::new();

        // Create a subscription manually
        let subscription = Subscription {
            id: Uuid::new_v4(),
            name: "Test Subscription".to_string(),
            url: "https://example.com/sub".to_string(),
            last_update: None,
            server_count: 0,
            status: SubscriptionStatus::Inactive,
        };

        let id = subscription.id;
        manager.subscriptions.push(subscription);

        // Manually add some servers
        manager.servers.push(Server {
            id: Uuid::new_v4(),
            name: "Test Server".to_string(),
            address: "example.com".to_string(),
            port: 443,
            protocol: "vmess".to_string(),
            config: HashMap::new(),
            subscription_id: id,
        });

        // Check servers
        assert_eq!(manager.get_servers().len(), 1);
        assert_eq!(manager.get_servers_for_subscription(id).len(), 1);

        // Remove subscription
        manager.remove_subscription(id).unwrap();
        assert!(manager.get_subscriptions().is_empty());
        assert!(manager.get_servers().is_empty());
    }

    #[test]
    fn test_subscription_status() {
        let active = SubscriptionStatus::Active;
        let inactive = SubscriptionStatus::Inactive;
        let error = SubscriptionStatus::Error("test error".to_string());
        let updating = SubscriptionStatus::Updating;

        assert_eq!(active, SubscriptionStatus::Active);
        assert_eq!(inactive, SubscriptionStatus::Inactive);
        assert!(matches!(error, SubscriptionStatus::Error(_)));
        assert_eq!(updating, SubscriptionStatus::Updating);
    }
}
