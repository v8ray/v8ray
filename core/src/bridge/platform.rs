//! Platform FFI Bridge
//!
//! This module provides FFI bindings for platform-specific operations.

use crate::platform::{get_platform, get_platform_info, PlatformInfo};

/// Check if the application has administrator/root privileges
///
/// # Returns
/// * `Ok(true)` if running with admin/root privileges
/// * `Ok(false)` if running as normal user
/// * `Err(String)` with error message if check failed
#[flutter_rust_bridge::frb(sync)]
pub fn has_admin_privileges() -> Result<bool, String> {
    let platform = get_platform();
    platform.has_admin_privileges().map_err(|e| e.to_string())
}

/// Set system proxy
///
/// # Arguments
/// * `http_port` - HTTP proxy port
/// * `socks_port` - SOCKS proxy port
///
/// # Returns
/// * `Ok(())` if successful
/// * `Err(String)` with error message if failed
#[flutter_rust_bridge::frb(sync)]
pub fn set_system_proxy(http_port: u16, socks_port: u16) -> Result<(), String> {
    tracing::info!(
        "Platform bridge: set_system_proxy called with http_port={}, socks_port={}",
        http_port,
        socks_port
    );
    let platform = get_platform();
    let result = platform
        .set_system_proxy(http_port, socks_port)
        .map_err(|e| e.to_string());
    if let Err(ref e) = result {
        tracing::error!("Platform bridge: set_system_proxy failed: {}", e);
    } else {
        tracing::info!("Platform bridge: set_system_proxy succeeded");
    }
    result
}

/// Clear system proxy
///
/// # Returns
/// * `Ok(())` if successful
/// * `Err(String)` with error message if failed
#[flutter_rust_bridge::frb(sync)]
pub fn clear_system_proxy() -> Result<(), String> {
    let platform = get_platform();
    platform.clear_system_proxy().map_err(|e| e.to_string())
}

/// Check if system proxy is set
///
/// # Returns
/// * `Ok(true)` if proxy is set
/// * `Ok(false)` if proxy is not set
/// * `Err(String)` with error message if failed
#[flutter_rust_bridge::frb(sync)]
pub fn is_system_proxy_set() -> Result<bool, String> {
    let platform = get_platform();
    platform.is_system_proxy_set().map_err(|e| e.to_string())
}

/// Get platform information
///
/// # Returns
/// Platform information including OS, architecture, version, and capabilities
#[flutter_rust_bridge::frb(sync)]
pub fn get_platform_information() -> PlatformInfo {
    get_platform_info()
}

/// Enable auto start
///
/// # Returns
/// * `Ok(())` if successful
/// * `Err(String)` with error message if failed
#[flutter_rust_bridge::frb(sync)]
pub fn enable_auto_start() -> Result<(), String> {
    let platform = get_platform();
    platform.enable_auto_start().map_err(|e| e.to_string())
}

/// Disable auto start
///
/// # Returns
/// * `Ok(())` if successful
/// * `Err(String)` with error message if failed
#[flutter_rust_bridge::frb(sync)]
pub fn disable_auto_start() -> Result<(), String> {
    let platform = get_platform();
    platform.disable_auto_start().map_err(|e| e.to_string())
}

/// Check if auto start is enabled
///
/// # Returns
/// * `Ok(true)` if auto start is enabled
/// * `Ok(false)` if auto start is not enabled
/// * `Err(String)` with error message if failed
#[flutter_rust_bridge::frb(sync)]
pub fn is_auto_start_enabled() -> Result<bool, String> {
    let platform = get_platform();
    platform.is_auto_start_enabled().map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_platform_information() {
        let info = get_platform_information();
        assert!(!info.os.is_empty());
        assert!(!info.arch.is_empty());
    }

    #[test]
    fn test_system_proxy_operations() {
        // Note: These tests may require elevated privileges
        // and should be run with caution

        // Test getting proxy status
        let result = is_system_proxy_set();
        assert!(result.is_ok());

        // Don't actually set/clear proxy in tests to avoid
        // affecting the development environment
    }
}
