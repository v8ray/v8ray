//! Platform Adaptation Module
//!
//! This module provides platform-specific functionality and abstractions
//! for different operating systems.

use serde::{Deserialize, Serialize};

/// Platform information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlatformInfo {
    /// Operating system name
    pub os: String,
    /// Architecture
    pub arch: String,
    /// OS version
    pub version: String,
    /// Platform capabilities
    pub capabilities: PlatformCapabilities,
}

/// Platform capabilities
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlatformCapabilities {
    /// Supports system proxy
    pub system_proxy: bool,
    /// Supports VPN mode
    pub vpn_mode: bool,
    /// Supports TUN mode
    pub tun_mode: bool,
    /// Supports auto start
    pub auto_start: bool,
}

/// Platform-specific operations
pub trait PlatformOps {
    /// Set system proxy
    fn set_system_proxy(&self, http_port: u16, socks_port: u16) -> crate::Result<()>;
    
    /// Clear system proxy
    fn clear_system_proxy(&self) -> crate::Result<()>;
    
    /// Check if system proxy is set
    fn is_system_proxy_set(&self) -> crate::Result<bool>;
    
    /// Enable auto start
    fn enable_auto_start(&self) -> crate::Result<()>;
    
    /// Disable auto start
    fn disable_auto_start(&self) -> crate::Result<()>;
    
    /// Check if auto start is enabled
    fn is_auto_start_enabled(&self) -> crate::Result<bool>;
}

/// Get current platform information
pub fn get_platform_info() -> PlatformInfo {
    let os = std::env::consts::OS.to_string();
    let arch = std::env::consts::ARCH.to_string();
    
    // Get OS version (simplified)
    let version = match os.as_str() {
        #[cfg(target_os = "windows")]
        "windows" => get_windows_version(),
        #[cfg(target_os = "macos")]
        "macos" => get_macos_version(),
        #[cfg(target_os = "linux")]
        "linux" => get_linux_version(),
        _ => "unknown".to_string(),
    };

    let capabilities = get_platform_capabilities(&os);

    PlatformInfo {
        os,
        arch,
        version,
        capabilities,
    }
}

/// Get platform capabilities based on OS
fn get_platform_capabilities(os: &str) -> PlatformCapabilities {
    match os {
        "windows" => PlatformCapabilities {
            system_proxy: true,
            vpn_mode: false, // TODO: Implement WinTUN support
            tun_mode: false,
            auto_start: true,
        },
        "macos" => PlatformCapabilities {
            system_proxy: true,
            vpn_mode: true, // NetworkExtension
            tun_mode: true,
            auto_start: true,
        },
        "linux" => PlatformCapabilities {
            system_proxy: true,
            vpn_mode: false,
            tun_mode: true,
            auto_start: true,
        },
        "ios" => PlatformCapabilities {
            system_proxy: false,
            vpn_mode: true, // NetworkExtension
            tun_mode: false,
            auto_start: false,
        },
        "android" => PlatformCapabilities {
            system_proxy: false,
            vpn_mode: true, // VpnService
            tun_mode: false,
            auto_start: false,
        },
        _ => PlatformCapabilities {
            system_proxy: false,
            vpn_mode: false,
            tun_mode: false,
            auto_start: false,
        },
    }
}

#[cfg(target_os = "windows")]
fn get_windows_version() -> String {
    // TODO: Implement proper Windows version detection
    "Windows 10+".to_string()
}

#[cfg(target_os = "macos")]
fn get_macos_version() -> String {
    // TODO: Implement proper macOS version detection
    "macOS 12+".to_string()
}

#[cfg(target_os = "linux")]
fn get_linux_version() -> String {
    // TODO: Implement proper Linux version detection
    "Linux".to_string()
}

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn get_windows_version() -> String { "unknown".to_string() }
#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn get_macos_version() -> String { "unknown".to_string() }
#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn get_linux_version() -> String { "unknown".to_string() }

/// Windows platform implementation
#[cfg(target_os = "windows")]
pub struct WindowsPlatform;

#[cfg(target_os = "windows")]
impl PlatformOps for WindowsPlatform {
    fn set_system_proxy(&self, http_port: u16, socks_port: u16) -> crate::Result<()> {
        // TODO: Implement Windows system proxy setting
        tracing::info!("Setting Windows system proxy: HTTP={}, SOCKS={}", http_port, socks_port);
        Ok(())
    }

    fn clear_system_proxy(&self) -> crate::Result<()> {
        // TODO: Implement Windows system proxy clearing
        tracing::info!("Clearing Windows system proxy");
        Ok(())
    }

    fn is_system_proxy_set(&self) -> crate::Result<bool> {
        // TODO: Implement Windows system proxy check
        Ok(false)
    }

    fn enable_auto_start(&self) -> crate::Result<()> {
        // TODO: Implement Windows auto start
        tracing::info!("Enabling Windows auto start");
        Ok(())
    }

    fn disable_auto_start(&self) -> crate::Result<()> {
        // TODO: Implement Windows auto start disable
        tracing::info!("Disabling Windows auto start");
        Ok(())
    }

    fn is_auto_start_enabled(&self) -> crate::Result<bool> {
        // TODO: Implement Windows auto start check
        Ok(false)
    }
}

/// macOS platform implementation
#[cfg(target_os = "macos")]
pub struct MacOSPlatform;

#[cfg(target_os = "macos")]
impl PlatformOps for MacOSPlatform {
    fn set_system_proxy(&self, http_port: u16, socks_port: u16) -> crate::Result<()> {
        // TODO: Implement macOS system proxy setting
        tracing::info!("Setting macOS system proxy: HTTP={}, SOCKS={}", http_port, socks_port);
        Ok(())
    }

    fn clear_system_proxy(&self) -> crate::Result<()> {
        // TODO: Implement macOS system proxy clearing
        tracing::info!("Clearing macOS system proxy");
        Ok(())
    }

    fn is_system_proxy_set(&self) -> crate::Result<bool> {
        // TODO: Implement macOS system proxy check
        Ok(false)
    }

    fn enable_auto_start(&self) -> crate::Result<()> {
        // TODO: Implement macOS auto start
        tracing::info!("Enabling macOS auto start");
        Ok(())
    }

    fn disable_auto_start(&self) -> crate::Result<()> {
        // TODO: Implement macOS auto start disable
        tracing::info!("Disabling macOS auto start");
        Ok(())
    }

    fn is_auto_start_enabled(&self) -> crate::Result<bool> {
        // TODO: Implement macOS auto start check
        Ok(false)
    }
}

/// Linux platform implementation
#[cfg(target_os = "linux")]
pub struct LinuxPlatform;

#[cfg(target_os = "linux")]
impl PlatformOps for LinuxPlatform {
    fn set_system_proxy(&self, http_port: u16, socks_port: u16) -> crate::Result<()> {
        // TODO: Implement Linux system proxy setting
        tracing::info!("Setting Linux system proxy: HTTP={}, SOCKS={}", http_port, socks_port);
        Ok(())
    }

    fn clear_system_proxy(&self) -> crate::Result<()> {
        // TODO: Implement Linux system proxy clearing
        tracing::info!("Clearing Linux system proxy");
        Ok(())
    }

    fn is_system_proxy_set(&self) -> crate::Result<bool> {
        // TODO: Implement Linux system proxy check
        Ok(false)
    }

    fn enable_auto_start(&self) -> crate::Result<()> {
        // TODO: Implement Linux auto start
        tracing::info!("Enabling Linux auto start");
        Ok(())
    }

    fn disable_auto_start(&self) -> crate::Result<()> {
        // TODO: Implement Linux auto start disable
        tracing::info!("Disabling Linux auto start");
        Ok(())
    }

    fn is_auto_start_enabled(&self) -> crate::Result<bool> {
        // TODO: Implement Linux auto start check
        Ok(false)
    }
}

/// Get platform-specific implementation
pub fn get_platform() -> Box<dyn PlatformOps> {
    #[cfg(target_os = "windows")]
    return Box::new(WindowsPlatform);

    #[cfg(target_os = "macos")]
    return Box::new(MacOSPlatform);

    #[cfg(target_os = "linux")]
    return Box::new(LinuxPlatform);

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    panic!("Unsupported platform");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_platform_info() {
        let info = get_platform_info();
        assert!(!info.os.is_empty());
        assert!(!info.arch.is_empty());
    }

    #[test]
    fn test_platform_capabilities() {
        let info = get_platform_info();
        // At least one capability should be supported on major platforms
        assert!(
            info.capabilities.system_proxy ||
            info.capabilities.vpn_mode ||
            info.capabilities.tun_mode ||
            info.capabilities.auto_start
        );
    }
}
