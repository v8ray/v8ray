//! Auto-reconnect mechanism for connection management
//!
//! This module provides automatic reconnection functionality with exponential backoff,
//! maximum retry limits, and configurable strategies.

use serde::{Deserialize, Serialize};
use std::time::Duration;
use tracing::{debug, info, warn};

/// Reconnect strategy
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ReconnectStrategy {
    /// No automatic reconnection
    Disabled,
    /// Immediate reconnection (no delay)
    Immediate,
    /// Fixed delay between reconnection attempts
    FixedDelay(Duration),
    /// Exponential backoff with configurable base delay
    ExponentialBackoff {
        /// Initial delay
        initial_delay: Duration,
        /// Maximum delay
        max_delay: Duration,
        /// Multiplier for each attempt
        multiplier: f64,
    },
}

impl Default for ReconnectStrategy {
    fn default() -> Self {
        Self::ExponentialBackoff {
            initial_delay: Duration::from_secs(1),
            max_delay: Duration::from_secs(60),
            multiplier: 2.0,
        }
    }
}

/// Reconnect configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReconnectConfig {
    /// Reconnect strategy
    pub strategy: ReconnectStrategy,
    /// Maximum number of reconnection attempts (0 = unlimited)
    pub max_attempts: u32,
    /// Whether to enable auto-reconnect
    pub enabled: bool,
}

impl Default for ReconnectConfig {
    fn default() -> Self {
        Self {
            strategy: ReconnectStrategy::default(),
            max_attempts: 5,
            enabled: true,
        }
    }
}

impl ReconnectConfig {
    /// Create a new reconnect config with disabled auto-reconnect
    pub fn disabled() -> Self {
        Self {
            strategy: ReconnectStrategy::Disabled,
            max_attempts: 0,
            enabled: false,
        }
    }

    /// Create a new reconnect config with immediate reconnection
    pub fn immediate(max_attempts: u32) -> Self {
        Self {
            strategy: ReconnectStrategy::Immediate,
            max_attempts,
            enabled: true,
        }
    }

    /// Create a new reconnect config with fixed delay
    pub fn fixed_delay(delay: Duration, max_attempts: u32) -> Self {
        Self {
            strategy: ReconnectStrategy::FixedDelay(delay),
            max_attempts,
            enabled: true,
        }
    }

    /// Create a new reconnect config with exponential backoff
    pub fn exponential_backoff(
        initial_delay: Duration,
        max_delay: Duration,
        multiplier: f64,
        max_attempts: u32,
    ) -> Self {
        Self {
            strategy: ReconnectStrategy::ExponentialBackoff {
                initial_delay,
                max_delay,
                multiplier,
            },
            max_attempts,
            enabled: true,
        }
    }

    /// Check if reconnection should be attempted
    pub fn should_reconnect(&self, current_attempts: u32) -> bool {
        if !self.enabled {
            debug!("Auto-reconnect is disabled");
            return false;
        }

        if self.strategy == ReconnectStrategy::Disabled {
            debug!("Reconnect strategy is disabled");
            return false;
        }

        if self.max_attempts > 0 && current_attempts >= self.max_attempts {
            warn!(
                "Maximum reconnection attempts reached: {}/{}",
                current_attempts, self.max_attempts
            );
            return false;
        }

        true
    }

    /// Calculate delay before next reconnection attempt
    pub fn calculate_delay(&self, attempt: u32) -> Duration {
        match &self.strategy {
            ReconnectStrategy::Disabled => Duration::from_secs(0),
            ReconnectStrategy::Immediate => Duration::from_secs(0),
            ReconnectStrategy::FixedDelay(delay) => {
                info!("Using fixed delay: {:?}", delay);
                *delay
            }
            ReconnectStrategy::ExponentialBackoff {
                initial_delay,
                max_delay,
                multiplier,
            } => {
                let delay_secs = initial_delay.as_secs_f64() * multiplier.powi(attempt as i32);
                let delay = Duration::from_secs_f64(delay_secs.min(max_delay.as_secs_f64()));
                info!(
                    "Exponential backoff delay for attempt {}: {:?}",
                    attempt, delay
                );
                delay
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_reconnect_config_default() {
        let config = ReconnectConfig::default();
        assert!(config.enabled);
        assert_eq!(config.max_attempts, 5);
        assert!(matches!(
            config.strategy,
            ReconnectStrategy::ExponentialBackoff { .. }
        ));
    }

    #[test]
    fn test_reconnect_config_disabled() {
        let config = ReconnectConfig::disabled();
        assert!(!config.enabled);
        assert_eq!(config.max_attempts, 0);
        assert_eq!(config.strategy, ReconnectStrategy::Disabled);
    }

    #[test]
    fn test_reconnect_config_immediate() {
        let config = ReconnectConfig::immediate(3);
        assert!(config.enabled);
        assert_eq!(config.max_attempts, 3);
        assert_eq!(config.strategy, ReconnectStrategy::Immediate);
    }

    #[test]
    fn test_reconnect_config_fixed_delay() {
        let delay = Duration::from_secs(5);
        let config = ReconnectConfig::fixed_delay(delay, 10);
        assert!(config.enabled);
        assert_eq!(config.max_attempts, 10);
        assert_eq!(config.strategy, ReconnectStrategy::FixedDelay(delay));
    }

    #[test]
    fn test_should_reconnect() {
        let config = ReconnectConfig::default();
        assert!(config.should_reconnect(0));
        assert!(config.should_reconnect(3));
        assert!(!config.should_reconnect(5));
        assert!(!config.should_reconnect(10));
    }

    #[test]
    fn test_should_reconnect_disabled() {
        let config = ReconnectConfig::disabled();
        assert!(!config.should_reconnect(0));
        assert!(!config.should_reconnect(1));
    }

    #[test]
    fn test_should_reconnect_unlimited() {
        let mut config = ReconnectConfig::default();
        config.max_attempts = 0; // Unlimited
        assert!(config.should_reconnect(0));
        assert!(config.should_reconnect(100));
        assert!(config.should_reconnect(1000));
    }

    #[test]
    fn test_calculate_delay_immediate() {
        let config = ReconnectConfig::immediate(5);
        assert_eq!(config.calculate_delay(0), Duration::from_secs(0));
        assert_eq!(config.calculate_delay(5), Duration::from_secs(0));
    }

    #[test]
    fn test_calculate_delay_fixed() {
        let delay = Duration::from_secs(3);
        let config = ReconnectConfig::fixed_delay(delay, 5);
        assert_eq!(config.calculate_delay(0), delay);
        assert_eq!(config.calculate_delay(3), delay);
        assert_eq!(config.calculate_delay(10), delay);
    }

    #[test]
    fn test_calculate_delay_exponential() {
        let config = ReconnectConfig::exponential_backoff(
            Duration::from_secs(1),
            Duration::from_secs(60),
            2.0,
            10,
        );

        // Attempt 0: 1 * 2^0 = 1 second
        assert_eq!(config.calculate_delay(0), Duration::from_secs(1));

        // Attempt 1: 1 * 2^1 = 2 seconds
        assert_eq!(config.calculate_delay(1), Duration::from_secs(2));

        // Attempt 2: 1 * 2^2 = 4 seconds
        assert_eq!(config.calculate_delay(2), Duration::from_secs(4));

        // Attempt 3: 1 * 2^3 = 8 seconds
        assert_eq!(config.calculate_delay(3), Duration::from_secs(8));

        // Attempt 10: Should be capped at max_delay (60 seconds)
        assert_eq!(config.calculate_delay(10), Duration::from_secs(60));
    }

    #[test]
    fn test_reconnect_strategy_serialization() {
        let strategy = ReconnectStrategy::ExponentialBackoff {
            initial_delay: Duration::from_secs(1),
            max_delay: Duration::from_secs(60),
            multiplier: 2.0,
        };

        let json = serde_json::to_string(&strategy).unwrap();
        let deserialized: ReconnectStrategy = serde_json::from_str(&json).unwrap();
        assert_eq!(strategy, deserialized);
    }

    #[test]
    fn test_reconnect_config_serialization() {
        let config = ReconnectConfig::default();
        let json = serde_json::to_string(&config).unwrap();
        let deserialized: ReconnectConfig = serde_json::from_str(&json).unwrap();
        assert_eq!(config.enabled, deserialized.enabled);
        assert_eq!(config.max_attempts, deserialized.max_attempts);
    }
}
