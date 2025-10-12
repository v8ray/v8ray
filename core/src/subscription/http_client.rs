//! HTTP Client for Subscription Management
//!
//! This module provides a specialized HTTP client for fetching subscription data
//! with features like timeout, retry, custom user-agent, and error handling.

use crate::error::SubscriptionResult;
use reqwest::{Client, ClientBuilder};
use std::time::Duration;
use tracing::{debug, info, warn};

/// Default timeout for HTTP requests (30 seconds)
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(30);

/// Default maximum number of retries
const DEFAULT_MAX_RETRIES: u32 = 3;

/// Default user agent
const DEFAULT_USER_AGENT: &str = "V8Ray/1.0";

/// HTTP client configuration
#[derive(Debug, Clone)]
pub struct HttpClientConfig {
    /// Request timeout
    pub timeout: Duration,
    /// Maximum number of retries
    pub max_retries: u32,
    /// User agent string
    pub user_agent: String,
    /// Follow redirects
    pub follow_redirects: bool,
}

impl Default for HttpClientConfig {
    fn default() -> Self {
        Self {
            timeout: DEFAULT_TIMEOUT,
            max_retries: DEFAULT_MAX_RETRIES,
            user_agent: DEFAULT_USER_AGENT.to_string(),
            follow_redirects: true,
        }
    }
}

/// HTTP client for subscription management
pub struct SubscriptionHttpClient {
    /// Reqwest client
    client: Client,
    /// Client configuration
    config: HttpClientConfig,
}

impl SubscriptionHttpClient {
    /// Create a new HTTP client with default configuration
    pub fn new() -> SubscriptionResult<Self> {
        Self::with_config(HttpClientConfig::default())
    }

    /// Create a new HTTP client with custom configuration
    pub fn with_config(config: HttpClientConfig) -> SubscriptionResult<Self> {
        let client = ClientBuilder::new()
            .timeout(config.timeout)
            .user_agent(&config.user_agent)
            .redirect(if config.follow_redirects {
                reqwest::redirect::Policy::limited(10)
            } else {
                reqwest::redirect::Policy::none()
            })
            .build()?;

        Ok(Self { client, config })
    }

    /// Fetch subscription data from URL
    ///
    /// This method will automatically retry on failure according to the configuration.
    pub async fn fetch_subscription(&self, url: &str) -> SubscriptionResult<String> {
        info!("Fetching subscription from: {}", url);

        // Validate URL
        if !url.starts_with("http://") && !url.starts_with("https://") {
            return Err(crate::error::SubscriptionError::InvalidUrl(
                "URL must start with http:// or https://".to_string(),
            ));
        }

        let mut last_error = None;

        // Retry loop
        for attempt in 1..=self.config.max_retries {
            debug!(
                "Attempt {}/{} to fetch subscription",
                attempt, self.config.max_retries
            );

            match self.fetch_with_timeout(url).await {
                Ok(content) => {
                    info!(
                        "Successfully fetched subscription ({} bytes)",
                        content.len()
                    );
                    return Ok(content);
                }
                Err(e) => {
                    warn!("Attempt {} failed: {}", attempt, e);
                    last_error = Some(e);

                    // Wait before retry (exponential backoff)
                    if attempt < self.config.max_retries {
                        let wait_time = Duration::from_secs(2u64.pow(attempt - 1));
                        debug!("Waiting {:?} before retry", wait_time);
                        tokio::time::sleep(wait_time).await;
                    }
                }
            }
        }

        // All retries failed
        Err(last_error.unwrap_or_else(|| {
            crate::error::SubscriptionError::UpdateFailed("All retries failed".to_string())
        }))
    }

    /// Fetch subscription with timeout
    async fn fetch_with_timeout(&self, url: &str) -> SubscriptionResult<String> {
        let response = self.client.get(url).send().await?;

        // Check status code
        if !response.status().is_success() {
            return Err(crate::error::SubscriptionError::UpdateFailed(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        // Get response body
        let content = response.text().await?;

        // Check if content is empty
        if content.trim().is_empty() {
            return Err(crate::error::SubscriptionError::Empty);
        }

        Ok(content)
    }

    /// Get the current configuration
    pub fn config(&self) -> &HttpClientConfig {
        &self.config
    }
}

impl Default for SubscriptionHttpClient {
    fn default() -> Self {
        Self::new().expect("Failed to create default HTTP client")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = HttpClientConfig::default();
        assert_eq!(config.timeout, DEFAULT_TIMEOUT);
        assert_eq!(config.max_retries, DEFAULT_MAX_RETRIES);
        assert_eq!(config.user_agent, DEFAULT_USER_AGENT);
        assert!(config.follow_redirects);
    }

    #[test]
    fn test_custom_config() {
        let config = HttpClientConfig {
            timeout: Duration::from_secs(60),
            max_retries: 5,
            user_agent: "CustomAgent/1.0".to_string(),
            follow_redirects: false,
        };

        assert_eq!(config.timeout, Duration::from_secs(60));
        assert_eq!(config.max_retries, 5);
        assert_eq!(config.user_agent, "CustomAgent/1.0");
        assert!(!config.follow_redirects);
    }

    #[test]
    fn test_client_creation() {
        let client = SubscriptionHttpClient::new();
        assert!(client.is_ok());

        let client = client.unwrap();
        assert_eq!(client.config().timeout, DEFAULT_TIMEOUT);
        assert_eq!(client.config().max_retries, DEFAULT_MAX_RETRIES);
    }

    #[test]
    fn test_client_with_custom_config() {
        let config = HttpClientConfig {
            timeout: Duration::from_secs(60),
            max_retries: 5,
            user_agent: "CustomAgent/1.0".to_string(),
            follow_redirects: false,
        };

        let client = SubscriptionHttpClient::with_config(config.clone());
        assert!(client.is_ok());

        let client = client.unwrap();
        assert_eq!(client.config().timeout, config.timeout);
        assert_eq!(client.config().max_retries, config.max_retries);
        assert_eq!(client.config().user_agent, config.user_agent);
    }

    #[tokio::test]
    async fn test_invalid_url() {
        let client = SubscriptionHttpClient::new().unwrap();
        let result = client.fetch_subscription("invalid-url").await;
        assert!(result.is_err());
        assert!(matches!(
            result.unwrap_err(),
            crate::error::SubscriptionError::InvalidUrl(_)
        ));
    }

    #[tokio::test]
    async fn test_fetch_nonexistent_url() {
        let client = SubscriptionHttpClient::new().unwrap();
        // Use a URL that will definitely fail
        let result = client
            .fetch_subscription("https://nonexistent-domain-12345.com/subscription")
            .await;
        assert!(result.is_err());
    }
}
