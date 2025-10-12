//! Error types for V8Ray Core
//!
//! This module defines all error types used throughout the V8Ray core library.
//! It uses `thiserror` for custom error types and `anyhow` for error handling.

use thiserror::Error;

/// Main error type for V8Ray Core
#[derive(Error, Debug)]
pub enum V8RayError {
    /// Configuration related errors
    #[error("Configuration error: {0}")]
    Config(#[from] ConfigError),

    /// Connection related errors
    #[error("Connection error: {0}")]
    Connection(#[from] ConnectionError),

    /// Subscription related errors
    #[error("Subscription error: {0}")]
    Subscription(#[from] SubscriptionError),

    /// Xray Core related errors
    #[error("Xray error: {0}")]
    Xray(#[from] XrayError),

    /// Platform specific errors
    #[error("Platform error: {0}")]
    Platform(#[from] PlatformError),

    /// Network related errors
    #[error("Network error: {0}")]
    Network(#[from] NetworkError),

    /// Storage related errors
    #[error("Storage error: {0}")]
    Storage(#[from] StorageError),

    /// Generic error
    #[error("{0}")]
    Generic(String),
}

/// Configuration errors
#[derive(Error, Debug)]
#[allow(missing_docs)]
pub enum ConfigError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("JSON serialization error: {0}")]
    JsonSerialization(#[from] serde_json::Error),

    #[error("YAML serialization error: {0}")]
    YamlSerialization(#[from] serde_yaml::Error),

    #[error("TOML serialization error: {0}")]
    TomlSerialization(#[from] toml::de::Error),

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("Invalid URL: {0}")]
    InvalidUrl(String),

    #[error("Invalid protocol: {0}")]
    InvalidProtocol(String),

    #[error("Missing required field: {0}")]
    MissingField(String),

    #[error("Invalid port: {0}")]
    InvalidPort(u16),

    #[error("Config not found: {0}")]
    NotFound(String),

    #[error("Config already exists: {0}")]
    AlreadyExists(String),
}

/// Connection errors
#[derive(Error, Debug)]
#[allow(missing_docs)]
pub enum ConnectionError {
    #[error("Connection failed: {0}")]
    Failed(String),

    #[error("Connection timeout")]
    Timeout,

    #[error("Connection refused")]
    Refused,

    #[error("Already connected")]
    AlreadyConnected,

    #[error("Not connected")]
    NotConnected,

    #[error("Invalid state: {0}")]
    InvalidState(String),

    #[error("Network unreachable")]
    NetworkUnreachable,
}

/// Subscription errors
#[derive(Error, Debug)]
#[allow(missing_docs)]
pub enum SubscriptionError {
    #[error("HTTP request failed: {0}")]
    HttpRequest(#[from] reqwest::Error),

    #[error("Invalid subscription URL: {0}")]
    InvalidUrl(String),

    #[error("Parse error: {0}")]
    Parse(String),

    #[error("Unsupported format: {0}")]
    UnsupportedFormat(String),

    #[error("Empty subscription")]
    Empty,

    #[error("Subscription not found: {0}")]
    NotFound(String),

    #[error("Update failed: {0}")]
    UpdateFailed(String),
}

/// Xray Core errors
#[derive(Error, Debug)]
#[allow(missing_docs)]
pub enum XrayError {
    #[error("Xray process error: {0}")]
    Process(String),

    #[error("Xray not found")]
    NotFound,

    #[error("Xray start failed: {0}")]
    StartFailed(String),

    #[error("Xray stop failed: {0}")]
    StopFailed(String),

    #[error("Invalid config: {0}")]
    InvalidConfig(String),

    #[error("API error: {0}")]
    Api(String),
}

/// Platform specific errors
#[derive(Error, Debug)]
#[allow(missing_docs)]
pub enum PlatformError {
    #[error("VPN permission denied")]
    VpnPermissionDenied,

    #[error("VPN setup failed: {0}")]
    VpnSetupFailed(String),

    #[error("System proxy error: {0}")]
    SystemProxy(String),

    #[error("Platform not supported: {0}")]
    NotSupported(String),

    #[error("Permission error: {0}")]
    Permission(String),
}

/// Network errors
#[derive(Error, Debug)]
#[allow(missing_docs)]
pub enum NetworkError {
    #[error("HTTP error: {0}")]
    Http(#[from] reqwest::Error),

    #[error("DNS resolution failed: {0}")]
    DnsResolution(String),

    #[error("Connection timeout")]
    Timeout,

    #[error("Network unavailable")]
    Unavailable,

    #[error("Invalid address: {0}")]
    InvalidAddress(String),
}

/// Storage errors
#[derive(Error, Debug)]
#[allow(missing_docs)]
pub enum StorageError {
    #[error("Database error: {0}")]
    Database(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Serialization error: {0}")]
    Serialization(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Already exists: {0}")]
    AlreadyExists(String),

    #[error("Encryption error: {0}")]
    Encryption(String),
}

/// Result type alias for V8Ray operations
pub type Result<T> = std::result::Result<T, V8RayError>;

/// Result type alias for configuration operations
pub type ConfigResult<T> = std::result::Result<T, ConfigError>;

/// Result type alias for connection operations
pub type ConnectionResult<T> = std::result::Result<T, ConnectionError>;

/// Result type alias for subscription operations
pub type SubscriptionResult<T> = std::result::Result<T, SubscriptionError>;

/// Result type alias for Xray operations
pub type XrayResult<T> = std::result::Result<T, XrayError>;

/// Result type alias for platform operations
pub type PlatformResult<T> = std::result::Result<T, PlatformError>;

/// Result type alias for network operations
pub type NetworkResult<T> = std::result::Result<T, NetworkError>;

/// Result type alias for storage operations
pub type StorageResult<T> = std::result::Result<T, StorageError>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_display() {
        let err = ConfigError::Validation("test error".to_string());
        assert_eq!(err.to_string(), "Validation error: test error");
    }

    #[test]
    fn test_error_conversion() {
        let config_err = ConfigError::NotFound("test".to_string());
        let v8ray_err: V8RayError = config_err.into();
        assert!(matches!(v8ray_err, V8RayError::Config(_)));
    }

    #[test]
    fn test_connection_error() {
        let err = ConnectionError::Timeout;
        assert_eq!(err.to_string(), "Connection timeout");
    }

    #[test]
    fn test_subscription_error() {
        let err = SubscriptionError::Empty;
        assert_eq!(err.to_string(), "Empty subscription");
    }
}
