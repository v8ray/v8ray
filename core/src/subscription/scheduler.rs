//! Subscription Auto-Update Scheduler
//!
//! This module provides automatic subscription update scheduling functionality.

use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;
use uuid::Uuid;

/// Auto-update scheduler configuration
#[derive(Debug, Clone)]
pub struct SchedulerConfig {
    /// Update interval in hours
    pub update_interval_hours: u64,
    /// Whether to update on startup
    pub update_on_startup: bool,
    /// Maximum concurrent updates
    pub max_concurrent_updates: usize,
}

impl Default for SchedulerConfig {
    fn default() -> Self {
        Self {
            update_interval_hours: 24,
            update_on_startup: true,
            max_concurrent_updates: 3,
        }
    }
}

/// Subscription auto-update scheduler
///
/// This is a simple scheduler that tracks update intervals.
/// The actual update logic should be implemented by the caller.
pub struct SubscriptionScheduler {
    /// Scheduler configuration
    config: SchedulerConfig,
    /// Last update time for each subscription
    last_updates: Arc<RwLock<std::collections::HashMap<Uuid, std::time::Instant>>>,
}

impl SubscriptionScheduler {
    /// Create a new scheduler with the given configuration
    pub fn new(config: SchedulerConfig) -> Self {
        Self {
            config,
            last_updates: Arc::new(RwLock::new(std::collections::HashMap::new())),
        }
    }

    /// Check if a subscription needs to be updated
    pub async fn should_update(&self, subscription_id: Uuid) -> bool {
        let last_updates = self.last_updates.read().await;

        if let Some(last_update) = last_updates.get(&subscription_id) {
            let elapsed = last_update.elapsed();
            let interval = Duration::from_secs(self.config.update_interval_hours * 3600);
            elapsed >= interval
        } else {
            // Never updated before
            true
        }
    }

    /// Mark a subscription as updated
    pub async fn mark_updated(&self, subscription_id: Uuid) {
        let mut last_updates = self.last_updates.write().await;
        last_updates.insert(subscription_id, std::time::Instant::now());
    }

    /// Get the time until next update for a subscription
    pub async fn time_until_next_update(&self, subscription_id: Uuid) -> Option<Duration> {
        let last_updates = self.last_updates.read().await;

        if let Some(last_update) = last_updates.get(&subscription_id) {
            let elapsed = last_update.elapsed();
            let interval = Duration::from_secs(self.config.update_interval_hours * 3600);

            if elapsed < interval {
                Some(interval - elapsed)
            } else {
                Some(Duration::ZERO)
            }
        } else {
            Some(Duration::ZERO)
        }
    }

    /// Get the configuration
    pub fn config(&self) -> &SchedulerConfig {
        &self.config
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_scheduler_creation() {
        let config = SchedulerConfig::default();
        let scheduler = SubscriptionScheduler::new(config);
        assert_eq!(scheduler.config().update_interval_hours, 24);
    }

    #[tokio::test]
    async fn test_should_update_new_subscription() {
        let config = SchedulerConfig::default();
        let scheduler = SubscriptionScheduler::new(config);

        let id = Uuid::new_v4();
        assert!(scheduler.should_update(id).await);
    }

    #[tokio::test]
    async fn test_mark_updated() {
        let config = SchedulerConfig {
            update_interval_hours: 1,
            update_on_startup: true,
            max_concurrent_updates: 3,
        };
        let scheduler = SubscriptionScheduler::new(config);

        let id = Uuid::new_v4();

        // Should update before marking
        assert!(scheduler.should_update(id).await);

        // Mark as updated
        scheduler.mark_updated(id).await;

        // Should not update immediately after marking
        assert!(!scheduler.should_update(id).await);
    }

    #[tokio::test]
    async fn test_time_until_next_update() {
        let config = SchedulerConfig {
            update_interval_hours: 1,
            update_on_startup: true,
            max_concurrent_updates: 3,
        };
        let scheduler = SubscriptionScheduler::new(config);

        let id = Uuid::new_v4();

        // New subscription should have zero time until update
        let time = scheduler.time_until_next_update(id).await;
        assert_eq!(time, Some(Duration::ZERO));

        // After marking as updated
        scheduler.mark_updated(id).await;
        let time = scheduler.time_until_next_update(id).await;
        assert!(time.is_some());
        assert!(time.unwrap() > Duration::ZERO);
    }

    #[test]
    fn test_scheduler_config_default() {
        let config = SchedulerConfig::default();
        assert_eq!(config.update_interval_hours, 24);
        assert!(config.update_on_startup);
        assert_eq!(config.max_concurrent_updates, 3);
    }
}
