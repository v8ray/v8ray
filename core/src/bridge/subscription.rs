//! Subscription Management Bridge
//!
//! This module provides FFI interfaces for subscription management.

use crate::bridge::api::{ServerInfo, SubscriptionInfo};
use crate::subscription::{
    SchedulerConfig, SubscriptionManager, SubscriptionScheduler, SubscriptionStatus,
    SubscriptionStorage,
};
use anyhow::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

lazy_static::lazy_static! {
    static ref SUBSCRIPTION_MANAGER: Arc<RwLock<Option<SubscriptionManager>>> = Arc::new(RwLock::new(None));
    static ref SUBSCRIPTION_STORAGE: Arc<RwLock<Option<SubscriptionStorage>>> = Arc::new(RwLock::new(None));
    static ref SUBSCRIPTION_SCHEDULER: Arc<RwLock<Option<SubscriptionScheduler>>> = Arc::new(RwLock::new(None));
}

/// Initialize subscription manager
pub async fn init_subscription_manager(db_path: String) -> Result<()> {
    tracing::info!("Initializing subscription manager");

    // Create storage
    let storage = SubscriptionStorage::new(&db_path).await?;
    *SUBSCRIPTION_STORAGE.write().await = Some(storage);

    // Create manager
    let manager = SubscriptionManager::new();
    *SUBSCRIPTION_MANAGER.write().await = Some(manager);

    // Create scheduler
    let scheduler_config = SchedulerConfig::default();
    let scheduler = SubscriptionScheduler::new(scheduler_config);
    *SUBSCRIPTION_SCHEDULER.write().await = Some(scheduler);

    tracing::info!("Subscription manager initialized");
    Ok(())
}

/// Add a new subscription
pub async fn add_subscription(name: String, url: String) -> Result<String> {
    tracing::info!("Adding subscription: {}", name);

    let mut manager_guard = SUBSCRIPTION_MANAGER.write().await;
    let manager = manager_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Subscription manager not initialized"))?;

    let id = manager.add_subscription(name, url).await?;

    // Save to storage
    if let Some(storage) = SUBSCRIPTION_STORAGE.read().await.as_ref() {
        let subscriptions = manager.get_subscriptions();
        if let Some(subscription) = subscriptions.iter().find(|s| s.id == id) {
            storage.save_subscription(subscription).await?;
        }
    }

    Ok(id.to_string())
}

/// Remove a subscription
pub async fn remove_subscription(id: String) -> Result<()> {
    tracing::info!("Removing subscription: {}", id);

    let subscription_id = Uuid::parse_str(&id)?;

    let mut manager_guard = SUBSCRIPTION_MANAGER.write().await;
    let manager = manager_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Subscription manager not initialized"))?;

    manager.remove_subscription(subscription_id)?;

    // Delete from storage
    if let Some(storage) = SUBSCRIPTION_STORAGE.read().await.as_ref() {
        storage.delete_subscription(subscription_id).await?;
    }

    Ok(())
}

/// Update a subscription
pub async fn update_subscription(id: String) -> Result<()> {
    tracing::info!("Updating subscription: {}", id);

    let subscription_id = Uuid::parse_str(&id)?;

    let mut manager_guard = SUBSCRIPTION_MANAGER.write().await;
    let manager = manager_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Subscription manager not initialized"))?;

    manager.update_subscription(subscription_id).await?;

    // Save to storage
    if let Some(storage) = SUBSCRIPTION_STORAGE.read().await.as_ref() {
        let subscriptions = manager.get_subscriptions();
        if let Some(subscription) = subscriptions.iter().find(|s| s.id == subscription_id) {
            storage.save_subscription(subscription).await?;
        }

        // Save servers
        let servers = manager.get_servers_for_subscription(subscription_id);
        for server in servers {
            storage.save_server(server).await?;
        }
    }

    // Mark as updated in scheduler
    if let Some(scheduler) = SUBSCRIPTION_SCHEDULER.read().await.as_ref() {
        scheduler.mark_updated(subscription_id).await;
    }

    Ok(())
}

/// Update all subscriptions
pub async fn update_all_subscriptions() -> Result<()> {
    tracing::info!("Updating all subscriptions");

    let mut manager_guard = SUBSCRIPTION_MANAGER.write().await;
    let manager = manager_guard
        .as_mut()
        .ok_or_else(|| anyhow::anyhow!("Subscription manager not initialized"))?;

    manager.update_all_subscriptions().await?;

    // Save to storage
    if let Some(storage) = SUBSCRIPTION_STORAGE.read().await.as_ref() {
        for subscription in manager.get_subscriptions() {
            storage.save_subscription(subscription).await?;
        }

        for server in manager.get_servers() {
            storage.save_server(server).await?;
        }
    }

    Ok(())
}

/// Get all subscriptions
pub async fn get_subscriptions() -> Result<Vec<SubscriptionInfo>> {
    let manager_guard = SUBSCRIPTION_MANAGER.read().await;
    let manager = manager_guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("Subscription manager not initialized"))?;

    let subscriptions = manager
        .get_subscriptions()
        .iter()
        .map(|s| SubscriptionInfo {
            id: s.id.to_string(),
            name: s.name.clone(),
            url: s.url.clone(),
            last_update: s.last_update.map(|dt| dt.timestamp()),
            server_count: s.server_count as i32,
            status: match &s.status {
                SubscriptionStatus::Active => "active".to_string(),
                SubscriptionStatus::Inactive => "inactive".to_string(),
                SubscriptionStatus::Error(msg) => format!("error:{}", msg),
                SubscriptionStatus::Updating => "updating".to_string(),
            },
        })
        .collect();

    Ok(subscriptions)
}

/// Get all servers
pub async fn get_servers() -> Result<Vec<ServerInfo>> {
    let manager_guard = SUBSCRIPTION_MANAGER.read().await;
    let manager = manager_guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("Subscription manager not initialized"))?;

    let servers = manager
        .get_servers()
        .iter()
        .map(|s| ServerInfo {
            id: s.id.to_string(),
            subscription_id: s.subscription_id.to_string(),
            name: s.name.clone(),
            address: s.address.clone(),
            port: s.port as i32,
            protocol: s.protocol.clone(),
        })
        .collect();

    Ok(servers)
}

/// Get servers for a specific subscription
pub async fn get_servers_for_subscription(subscription_id: String) -> Result<Vec<ServerInfo>> {
    let id = Uuid::parse_str(&subscription_id)?;

    let manager_guard = SUBSCRIPTION_MANAGER.read().await;
    let manager = manager_guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("Subscription manager not initialized"))?;

    let servers = manager
        .get_servers_for_subscription(id)
        .iter()
        .map(|s| ServerInfo {
            id: s.id.to_string(),
            subscription_id: s.subscription_id.to_string(),
            name: s.name.clone(),
            address: s.address.clone(),
            port: s.port as i32,
            protocol: s.protocol.clone(),
        })
        .collect();

    Ok(servers)
}

/// Check if a subscription should be updated
pub async fn should_update_subscription(subscription_id: String) -> Result<bool> {
    let id = Uuid::parse_str(&subscription_id)?;

    let scheduler_guard = SUBSCRIPTION_SCHEDULER.read().await;
    let scheduler = scheduler_guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("Subscription scheduler not initialized"))?;

    Ok(scheduler.should_update(id).await)
}

/// Load subscriptions from storage
pub async fn load_subscriptions_from_storage() -> Result<()> {
    tracing::info!("Loading subscriptions from storage");

    let storage_guard = SUBSCRIPTION_STORAGE.read().await;
    let storage = storage_guard
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("Subscription storage not initialized"))?;

    let subscriptions = storage.load_subscriptions().await?;
    let servers = storage.load_servers().await?;

    // Load subscriptions and servers into manager
    // Note: This is a simplified implementation
    // In a real implementation, you would need to properly restore the manager state

    tracing::info!(
        "Loaded {} subscriptions and {} servers from storage",
        subscriptions.len(),
        servers.len()
    );

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_subscription_manager_init() {
        let result = init_subscription_manager(":memory:".to_string()).await;
        assert!(result.is_ok());
    }
}
