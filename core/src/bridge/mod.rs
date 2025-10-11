//! Flutter Rust Bridge Module
//!
//! This module provides the FFI interface for communication between
//! the Rust core and Flutter frontend.

// TODO: Enable when flutter_rust_bridge is properly configured
// use flutter_rust_bridge::frb;

/// Initialize the bridge
// TODO: Enable when flutter_rust_bridge is properly configured
// #[frb(sync)]
pub fn init_bridge() -> String {
    "V8Ray Bridge initialized".to_string()
}

/// Get core version through bridge
// TODO: Enable when flutter_rust_bridge is properly configured
// #[frb(sync)]
pub fn get_version() -> String {
    crate::version().to_string()
}

/// Bridge result type
pub type BridgeResult<T> = Result<T, String>;

/// Convert anyhow::Error to String for bridge
pub fn convert_error(err: anyhow::Error) -> String {
    err.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init_bridge() {
        let result = init_bridge();
        assert!(!result.is_empty());
    }

    #[test]
    fn test_get_version() {
        let version = get_version();
        assert!(!version.is_empty());
    }
}
