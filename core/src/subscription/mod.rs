//! Subscription Management Module
//!
//! This module handles subscription management including parsing different
//! subscription formats, automatic updates, and server list management.

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
    Active,
    Inactive,
    Error(String),
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
        }
    }

    /// Add a new subscription
    pub async fn add_subscription(&mut self, name: String, url: String) -> crate::Result<Uuid> {
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
    pub fn remove_subscription(&mut self, id: Uuid) -> crate::Result<()> {
        // Remove subscription
        self.subscriptions.retain(|s| s.id != id);
        
        // Remove associated servers
        self.servers.retain(|s| s.subscription_id != id);
        
        Ok(())
    }

    /// Update a specific subscription
    pub async fn update_subscription(&mut self, id: Uuid) -> crate::Result<()> {
        let subscription = self.subscriptions
            .iter_mut()
            .find(|s| s.id == id)
            .ok_or_else(|| anyhow::anyhow!("Subscription not found"))?;

        subscription.status = SubscriptionStatus::Updating;

        // TODO: Implement actual subscription fetching and parsing
        // For now, simulate the update process
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

        // Simulate parsing some servers
        let mock_servers = vec![
            Server {
                id: Uuid::new_v4(),
                name: "Mock Server 1".to_string(),
                address: "example1.com".to_string(),
                port: 443,
                protocol: "vmess".to_string(),
                config: HashMap::new(),
                subscription_id: id,
            },
            Server {
                id: Uuid::new_v4(),
                name: "Mock Server 2".to_string(),
                address: "example2.com".to_string(),
                port: 443,
                protocol: "vless".to_string(),
                config: HashMap::new(),
                subscription_id: id,
            },
        ];

        // Remove old servers for this subscription
        self.servers.retain(|s| s.subscription_id != id);
        
        // Add new servers
        self.servers.extend(mock_servers);

        // Update subscription info
        subscription.last_update = Some(chrono::Utc::now());
        subscription.server_count = self.servers.iter().filter(|s| s.subscription_id == id).count();
        subscription.status = SubscriptionStatus::Active;

        Ok(())
    }

    /// Update all subscriptions
    pub async fn update_all_subscriptions(&mut self) -> crate::Result<()> {
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
        self.servers.iter().filter(|s| s.subscription_id == subscription_id).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_subscription_manager() {
        let mut manager = SubscriptionManager::new();
        
        // Add subscription
        let id = manager.add_subscription(
            "Test Subscription".to_string(),
            "https://example.com/subscription".to_string()
        ).await.unwrap();
        
        // Check subscription was added
        assert_eq!(manager.get_subscriptions().len(), 1);
        assert_eq!(manager.get_subscriptions()[0].id, id);
        
        // Check servers were added during update
        assert!(!manager.get_servers().is_empty());
        
        // Remove subscription
        manager.remove_subscription(id).unwrap();
        assert!(manager.get_subscriptions().is_empty());
        assert!(manager.get_servers().is_empty());
    }

    #[tokio::test]
    async fn test_subscription_update() {
        let mut manager = SubscriptionManager::new();
        
        let id = manager.add_subscription(
            "Test".to_string(),
            "https://example.com/sub".to_string()
        ).await.unwrap();
        
        // Update subscription
        manager.update_subscription(id).await.unwrap();
        
        let subscription = &manager.get_subscriptions()[0];
        assert_eq!(subscription.status, SubscriptionStatus::Active);
        assert!(subscription.last_update.is_some());
        assert!(subscription.server_count > 0);
    }
}
