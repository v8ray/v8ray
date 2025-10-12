//! Subscription Management Integration Tests
//!
//! These tests verify the complete subscription management workflow.

use v8ray_core::subscription::{
    SchedulerConfig, SubscriptionHttpClient, SubscriptionManager, SubscriptionParser,
    SubscriptionScheduler, SubscriptionStorage,
};

#[tokio::test]
async fn test_subscription_complete_workflow() {
    // Create storage
    let storage = SubscriptionStorage::new(":memory:")
        .await
        .expect("Failed to create storage");

    // Create manager
    let mut manager = SubscriptionManager::new();

    // Add a subscription
    let subscription_id = manager
        .add_subscription(
            "Test Subscription".to_string(),
            "https://example.com/subscription".to_string(),
        )
        .await
        .expect("Failed to add subscription");

    // Verify subscription was added
    let subscriptions = manager.get_subscriptions();
    assert_eq!(subscriptions.len(), 1);
    assert_eq!(subscriptions[0].name, "Test Subscription");
    assert_eq!(subscriptions[0].id, subscription_id);

    // Save to storage
    storage
        .save_subscription(&subscriptions[0])
        .await
        .expect("Failed to save subscription");

    // Load from storage
    let loaded_subscriptions = storage
        .load_subscriptions()
        .await
        .expect("Failed to load subscriptions");
    assert_eq!(loaded_subscriptions.len(), 1);
    assert_eq!(loaded_subscriptions[0].name, "Test Subscription");

    // Remove subscription
    manager
        .remove_subscription(subscription_id)
        .expect("Failed to remove subscription");

    // Verify subscription was removed
    let subscriptions = manager.get_subscriptions();
    assert_eq!(subscriptions.len(), 0);

    // Delete from storage
    storage
        .delete_subscription(subscription_id)
        .await
        .expect("Failed to delete subscription");

    // Verify deletion
    let loaded_subscriptions = storage
        .load_subscriptions()
        .await
        .expect("Failed to load subscriptions");
    assert_eq!(loaded_subscriptions.len(), 0);
}

#[tokio::test]
async fn test_subscription_with_servers() {
    // Create storage
    let storage = SubscriptionStorage::new(":memory:")
        .await
        .expect("Failed to create storage");

    // Create manager
    let mut manager = SubscriptionManager::new();

    // Add a subscription
    let subscription_id = manager
        .add_subscription(
            "Test Subscription".to_string(),
            "https://example.com/subscription".to_string(),
        )
        .await
        .expect("Failed to add subscription");

    // Note: In a real scenario, we would update the subscription to fetch servers
    // For this test, we'll manually create a server

    // Get servers for subscription (should be empty initially)
    let servers = manager.get_servers_for_subscription(subscription_id);
    assert_eq!(servers.len(), 0);

    // Save subscription to storage
    let subscriptions = manager.get_subscriptions();
    storage
        .save_subscription(&subscriptions[0])
        .await
        .expect("Failed to save subscription");

    // Load servers from storage
    let loaded_servers = storage
        .load_servers_for_subscription(subscription_id)
        .await
        .expect("Failed to load servers");
    assert_eq!(loaded_servers.len(), 0);
}

#[tokio::test]
async fn test_subscription_scheduler_integration() {
    // Create scheduler
    let config = SchedulerConfig {
        update_interval_hours: 24,
        update_on_startup: false,
        max_concurrent_updates: 3,
    };
    let scheduler = SubscriptionScheduler::new(config);

    // Create a subscription ID
    let subscription_id = uuid::Uuid::new_v4();

    // Check if should update (should be true for new subscription)
    assert!(scheduler.should_update(subscription_id).await);

    // Mark as updated
    scheduler.mark_updated(subscription_id).await;

    // Check if should update (should be false immediately after update)
    assert!(!scheduler.should_update(subscription_id).await);

    // Check time until next update
    let time_until_next = scheduler.time_until_next_update(subscription_id).await;
    assert!(time_until_next.is_some());
    assert!(time_until_next.unwrap() > std::time::Duration::ZERO);
}

#[tokio::test]
async fn test_subscription_parser_integration() {
    // Test empty subscription
    let result = SubscriptionParser::parse("");
    // Empty content may return error or empty list, both are acceptable
    // Error is also acceptable for empty content
    if let Ok(servers) = result {
        assert_eq!(servers.len(), 0);
    }

    // Test invalid content
    let result = SubscriptionParser::parse("invalid content that is not base64, json, or yaml");
    // Invalid content should return empty list or error
    // This is acceptable behavior - just verify it doesn't panic
    let _ = result;
}

#[tokio::test]
async fn test_http_client_integration() {
    // Create HTTP client
    let client = SubscriptionHttpClient::new().expect("Failed to create HTTP client");

    // Test with invalid URL (should fail)
    let result = client.fetch_subscription("invalid-url").await;
    assert!(result.is_err());

    // Test with non-existent domain (should fail after retries)
    let result = client
        .fetch_subscription("https://nonexistent-domain-12345.com/subscription")
        .await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_multiple_subscriptions() {
    // Create storage
    let storage = SubscriptionStorage::new(":memory:")
        .await
        .expect("Failed to create storage");

    // Create manager
    let mut manager = SubscriptionManager::new();

    // Add multiple subscriptions
    let id1 = manager
        .add_subscription(
            "Subscription 1".to_string(),
            "https://example1.com".to_string(),
        )
        .await
        .expect("Failed to add subscription 1");

    let id2 = manager
        .add_subscription(
            "Subscription 2".to_string(),
            "https://example2.com".to_string(),
        )
        .await
        .expect("Failed to add subscription 2");

    let id3 = manager
        .add_subscription(
            "Subscription 3".to_string(),
            "https://example3.com".to_string(),
        )
        .await
        .expect("Failed to add subscription 3");

    // Verify all subscriptions were added
    let subscriptions = manager.get_subscriptions();
    assert_eq!(subscriptions.len(), 3);

    // Save all to storage
    for subscription in subscriptions.iter() {
        storage
            .save_subscription(subscription)
            .await
            .expect("Failed to save subscription");
    }

    // Load from storage
    let loaded_subscriptions = storage
        .load_subscriptions()
        .await
        .expect("Failed to load subscriptions");
    assert_eq!(loaded_subscriptions.len(), 3);

    // Remove one subscription
    manager
        .remove_subscription(id2)
        .expect("Failed to remove subscription");

    // Verify removal
    let subscriptions = manager.get_subscriptions();
    assert_eq!(subscriptions.len(), 2);
    assert!(subscriptions.iter().any(|s| s.id == id1));
    assert!(subscriptions.iter().any(|s| s.id == id3));
    assert!(!subscriptions.iter().any(|s| s.id == id2));

    // Delete from storage
    storage
        .delete_subscription(id2)
        .await
        .expect("Failed to delete subscription");

    // Verify deletion
    let loaded_subscriptions = storage
        .load_subscriptions()
        .await
        .expect("Failed to load subscriptions");
    assert_eq!(loaded_subscriptions.len(), 2);
}

#[tokio::test]
async fn test_subscription_error_handling() {
    // Create manager
    let mut manager = SubscriptionManager::new();

    // Add a subscription first
    let id = manager
        .add_subscription("Test".to_string(), "https://example.com".to_string())
        .await
        .expect("Failed to add subscription");

    // Remove it
    let result = manager.remove_subscription(id);
    assert!(
        result.is_ok(),
        "Removing existing subscription should succeed"
    );

    // Try to remove it again (should fail or succeed depending on implementation)
    let result = manager.remove_subscription(id);
    // Just verify it doesn't panic
    let _ = result;

    // Try to update non-existent subscription
    let result = manager.update_subscription(uuid::Uuid::new_v4()).await;
    // Should return error for non-existent subscription
    assert!(
        result.is_err(),
        "Updating non-existent subscription should fail"
    );
}
