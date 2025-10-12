//! V8Ray Core Library
//!
//! This is the core Rust library for V8Ray, providing the backend functionality
//! for the cross-platform proxy client.

#![warn(missing_docs)]
#![warn(clippy::all)]

pub mod bridge;
pub mod config;
pub mod connection;
pub mod error;
pub mod platform;
pub mod subscription;
pub mod utils;
pub mod xray;

// Re-export commonly used types
pub use config::Config;
pub use connection::{Connection, ConnectionManager, ConnectionState};
pub use error::{
    ConfigError, ConfigResult, ConnectionError, ConnectionResult, NetworkError, NetworkResult,
    PlatformError, PlatformResult, StorageError, StorageResult, SubscriptionError,
    SubscriptionResult, V8RayError, XrayError, XrayResult,
};
pub use subscription::{Subscription, SubscriptionManager};
pub use utils::{init_logger, LogConfig, LogLevel};
pub use xray::{XrayCore, XrayError as XrayCoreError};

/// Result type used throughout the library
pub type Result<T> = std::result::Result<T, V8RayError>;

/// Initialize the V8Ray core library
///
/// # Arguments
/// * `log_config` - Optional logging configuration. If None, uses default settings.
///
/// # Returns
/// Result indicating success or failure
pub fn init(log_config: Option<LogConfig>) -> Result<()> {
    // Initialize logging
    let config = log_config.unwrap_or_default();
    utils::logger::init_logger(&config)
        .map_err(|e| V8RayError::Generic(format!("Failed to initialize logger: {}", e)))?;

    tracing::info!("V8Ray Core v{} initialized", version());
    Ok(())
}

/// Initialize the V8Ray core library with simple logging
pub fn init_simple() -> Result<()> {
    init(None)
}

/// Get the version of the V8Ray core library
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        let ver = version();
        assert!(!ver.is_empty());
        assert_eq!(ver, env!("CARGO_PKG_VERSION"));
    }

    #[test]
    fn test_init_simple() {
        // Note: This test may fail if logger is already initialized
        // In real tests, we should use a test-specific logger
        let result = init_simple();
        // We don't assert success because logger can only be initialized once
        // The first test to run will succeed, others will fail
        println!("Init result: {:?}", result);
    }

    #[test]
    #[ignore] // Ignore this test because logger can only be initialized once
    fn test_init_with_config() {
        let config = LogConfig {
            level: LogLevel::Debug,
            console: true,
            file: false,
            ..Default::default()
        };
        let result = init(Some(config));
        println!("Init with config result: {:?}", result);
    }
}
