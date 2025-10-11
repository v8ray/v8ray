//! V8Ray Core Library
//!
//! This is the core Rust library for V8Ray, providing the backend functionality
//! for the cross-platform proxy client.

#![warn(missing_docs)]
#![warn(clippy::all)]

pub mod bridge;
pub mod config;
pub mod connection;
pub mod platform;
pub mod subscription;
pub mod xray;

// Re-export commonly used types
pub use config::{Config, ConfigError};
pub use connection::{Connection, ConnectionManager, ConnectionState};
pub use subscription::{Subscription, SubscriptionManager};
pub use xray::{XrayCore, XrayError};

/// Result type used throughout the library
pub type Result<T> = anyhow::Result<T>;

/// Initialize the V8Ray core library
pub fn init() -> Result<()> {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    tracing::info!("V8Ray Core initialized");
    Ok(())
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
        assert!(!version().is_empty());
    }

    #[tokio::test]
    async fn test_init() {
        assert!(init().is_ok());
    }
}
