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
    /// Check if the application has sufficient permissions to modify system settings
    /// Returns true if running with admin/root privileges
    fn has_admin_privileges(&self) -> crate::V8RayResult<bool>;

    /// Set system proxy
    fn set_system_proxy(&self, http_port: u16, socks_port: u16) -> crate::V8RayResult<()>;

    /// Clear system proxy
    fn clear_system_proxy(&self) -> crate::V8RayResult<()>;

    /// Check if system proxy is set
    fn is_system_proxy_set(&self) -> crate::V8RayResult<bool>;

    /// Enable auto start
    fn enable_auto_start(&self) -> crate::V8RayResult<()>;

    /// Disable auto start
    fn disable_auto_start(&self) -> crate::V8RayResult<()>;

    /// Check if auto start is enabled
    fn is_auto_start_enabled(&self) -> crate::V8RayResult<bool>;
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
        "harmonyos" | "ohos" => PlatformCapabilities {
            system_proxy: false,
            vpn_mode: true, // VPN Kit
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
fn get_windows_version() -> String {
    "unknown".to_string()
}
#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn get_macos_version() -> String {
    "unknown".to_string()
}
#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn get_linux_version() -> String {
    "unknown".to_string()
}

/// Windows platform implementation
#[cfg(target_os = "windows")]
pub struct WindowsPlatform;

#[cfg(target_os = "windows")]
impl PlatformOps for WindowsPlatform {
    fn has_admin_privileges(&self) -> crate::V8RayResult<bool> {
        // On Windows, check if running as Administrator
        // Note: For HKCU registry changes, admin is not required
        // But for system-wide settings (HKLM), admin is needed
        #[cfg(windows)]
        {
            use std::ptr;
            use winapi::um::processthreadsapi::{GetCurrentProcess, OpenProcessToken};
            use winapi::um::securitybaseapi::GetTokenInformation;
            use winapi::um::winnt::{TokenElevation, TOKEN_ELEVATION, TOKEN_QUERY};

            unsafe {
                let mut token = ptr::null_mut();
                if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token) == 0 {
                    return Ok(false);
                }

                let mut elevation = TOKEN_ELEVATION { TokenIsElevated: 0 };
                let mut size = 0;

                let result = GetTokenInformation(
                    token,
                    TokenElevation,
                    &mut elevation as *mut _ as *mut _,
                    std::mem::size_of::<TOKEN_ELEVATION>() as u32,
                    &mut size,
                );

                winapi::um::handleapi::CloseHandle(token);

                if result == 0 {
                    return Ok(false);
                }

                Ok(elevation.TokenIsElevated != 0)
            }
        }
        #[cfg(not(windows))]
        {
            Ok(false)
        }
    }

    fn set_system_proxy(&self, _http_port: u16, socks_port: u16) -> crate::V8RayResult<()> {
        tracing::info!(
            "Setting Windows system proxy using WinInet API: SOCKS={}",
            socks_port
        );

        // 使用 WinInet API 设置系统代理（参考 v2rayN 的实现）
        // 代理格式：127.0.0.1:端口（不带任何协议前缀）
        let proxy_server = format!("127.0.0.1:{}", socks_port);
        let proxy_bypass = "localhost;127.*;10.*;172.16.*;192.168.*;*.local;<local>";

        Self::set_internet_proxy(&proxy_server, &proxy_bypass)?;

        tracing::info!("Windows system proxy set successfully: {}", proxy_server);
        Ok(())
    }

    fn clear_system_proxy(&self) -> crate::V8RayResult<()> {
        tracing::info!("Clearing Windows system proxy using WinInet API");

        // 使用 WinInet API 清除系统代理
        Self::unset_internet_proxy()?;

        tracing::info!("Windows system proxy cleared successfully");
        Ok(())
    }

    fn is_system_proxy_set(&self) -> crate::V8RayResult<bool> {
        use winreg::enums::*;
        use winreg::RegKey;

        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let internet_settings = hkcu
            .open_subkey_with_flags(
                "Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings",
                KEY_READ,
            )
            .map_err(|e| {
                crate::error::PlatformError::SystemProxy(format!(
                    "Failed to open registry key: {}",
                    e
                ))
            })?;

        let proxy_enable: u32 = internet_settings.get_value("ProxyEnable").unwrap_or(0);

        Ok(proxy_enable == 1)
    }

    fn enable_auto_start(&self) -> crate::V8RayResult<()> {
        // TODO: Implement Windows auto start
        tracing::info!("Enabling Windows auto start");
        Ok(())
    }

    fn disable_auto_start(&self) -> crate::V8RayResult<()> {
        // TODO: Implement Windows auto start disable
        tracing::info!("Disabling Windows auto start");
        Ok(())
    }

    fn is_auto_start_enabled(&self) -> crate::V8RayResult<bool> {
        // TODO: Implement Windows auto start check
        Ok(false)
    }
}

#[cfg(target_os = "windows")]
impl WindowsPlatform {
    /// 使用 WinInet API 设置系统代理
    /// 参考 v2rayN 的实现：ProxySettingWindows.cs
    fn set_internet_proxy(proxy_server: &str, proxy_bypass: &str) -> crate::V8RayResult<()> {
        use std::ffi::OsStr;
        use std::iter::once;
        use std::mem;
        use std::os::windows::ffi::OsStrExt;
        use std::ptr;

        // WinInet API 常量
        const INTERNET_OPTION_PER_CONNECTION_OPTION: u32 = 75;
        const INTERNET_OPTION_SETTINGS_CHANGED: u32 = 39;
        const INTERNET_OPTION_REFRESH: u32 = 37;

        const INTERNET_PER_CONN_FLAGS: u32 = 1;
        const INTERNET_PER_CONN_PROXY_SERVER: u32 = 2;
        const INTERNET_PER_CONN_PROXY_BYPASS: u32 = 3;

        const PROXY_TYPE_DIRECT: u32 = 0x00000001;
        const PROXY_TYPE_PROXY: u32 = 0x00000002;

        // WinInet API 结构体定义
        #[repr(C)]
        union InternetPerConnOptionValue {
            dw_value: u32,
            psz_value: *mut u16,
            ft_value: winapi::shared::minwindef::FILETIME,
        }

        #[repr(C)]
        struct InternetPerConnOptionW {
            dw_option: u32,
            value: InternetPerConnOptionValue,
        }

        #[repr(C)]
        struct InternetPerConnOptionListW {
            dw_size: u32,
            psz_connection: *mut u16,
            dw_option_count: u32,
            dw_option_error: u32,
            p_options: *mut InternetPerConnOptionW,
        }

        // 外部函数声明
        extern "system" {
            fn InternetSetOptionW(
                h_internet: *mut winapi::ctypes::c_void,
                dw_option: u32,
                lp_buffer: *mut winapi::ctypes::c_void,
                dw_buffer_length: u32,
            ) -> i32;
        }

        unsafe {
            // 准备代理服务器字符串（宽字符）
            let proxy_server_wide: Vec<u16> = OsStr::new(proxy_server)
                .encode_wide()
                .chain(once(0))
                .collect();
            let proxy_bypass_wide: Vec<u16> = OsStr::new(proxy_bypass)
                .encode_wide()
                .chain(once(0))
                .collect();

            // 创建选项数组
            let mut options: [InternetPerConnOptionW; 3] = mem::zeroed();

            // 选项 1: 设置代理标志（启用直连和代理）
            options[0].dw_option = INTERNET_PER_CONN_FLAGS;
            options[0].value.dw_value = PROXY_TYPE_DIRECT | PROXY_TYPE_PROXY;

            // 选项 2: 设置代理服务器地址
            options[1].dw_option = INTERNET_PER_CONN_PROXY_SERVER;
            options[1].value.psz_value = proxy_server_wide.as_ptr() as *mut _;

            // 选项 3: 设置代理绕过列表
            options[2].dw_option = INTERNET_PER_CONN_PROXY_BYPASS;
            options[2].value.psz_value = proxy_bypass_wide.as_ptr() as *mut _;

            // 创建选项列表
            let mut option_list = InternetPerConnOptionListW {
                dw_size: mem::size_of::<InternetPerConnOptionListW>() as u32,
                psz_connection: ptr::null_mut(), // NULL = LAN connection
                dw_option_count: 3,
                dw_option_error: 0,
                p_options: options.as_mut_ptr(),
            };

            // 调用 InternetSetOptionW 设置代理
            let result = InternetSetOptionW(
                ptr::null_mut(),
                INTERNET_OPTION_PER_CONNECTION_OPTION,
                &mut option_list as *mut _ as *mut _,
                option_list.dw_size,
            );

            if result == 0 {
                let error = winapi::um::errhandlingapi::GetLastError();
                return Err(crate::error::PlatformError::SystemProxy(format!(
                    "InternetSetOptionW failed with error code: {}",
                    error
                ))
                .into());
            }

            // 通知系统代理设置已更改
            InternetSetOptionW(
                ptr::null_mut(),
                INTERNET_OPTION_SETTINGS_CHANGED,
                ptr::null_mut(),
                0,
            );

            // 刷新代理设置
            InternetSetOptionW(ptr::null_mut(), INTERNET_OPTION_REFRESH, ptr::null_mut(), 0);

            tracing::info!("WinInet API: Proxy set successfully");
        }

        Ok(())
    }

    /// 使用 WinInet API 清除系统代理
    fn unset_internet_proxy() -> crate::V8RayResult<()> {
        use std::mem;
        use std::ptr;

        // WinInet API 常量
        const INTERNET_OPTION_PER_CONNECTION_OPTION: u32 = 75;
        const INTERNET_OPTION_SETTINGS_CHANGED: u32 = 39;
        const INTERNET_OPTION_REFRESH: u32 = 37;

        const INTERNET_PER_CONN_FLAGS: u32 = 1;
        const PROXY_TYPE_DIRECT: u32 = 0x00000001;

        // WinInet API 结构体定义
        #[repr(C)]
        union InternetPerConnOptionValue {
            dw_value: u32,
            psz_value: *mut u16,
            ft_value: winapi::shared::minwindef::FILETIME,
        }

        #[repr(C)]
        struct InternetPerConnOptionW {
            dw_option: u32,
            value: InternetPerConnOptionValue,
        }

        #[repr(C)]
        struct InternetPerConnOptionListW {
            dw_size: u32,
            psz_connection: *mut u16,
            dw_option_count: u32,
            dw_option_error: u32,
            p_options: *mut InternetPerConnOptionW,
        }

        // 外部函数声明
        extern "system" {
            fn InternetSetOptionW(
                h_internet: *mut winapi::ctypes::c_void,
                dw_option: u32,
                lp_buffer: *mut winapi::ctypes::c_void,
                dw_buffer_length: u32,
            ) -> i32;
        }

        unsafe {
            // 创建选项数组（只设置直连标志）
            let mut options: [InternetPerConnOptionW; 1] = mem::zeroed();

            // 选项 1: 设置为直连（禁用代理）
            options[0].dw_option = INTERNET_PER_CONN_FLAGS;
            options[0].value.dw_value = PROXY_TYPE_DIRECT;

            // 创建选项列表
            let mut option_list = InternetPerConnOptionListW {
                dw_size: mem::size_of::<InternetPerConnOptionListW>() as u32,
                psz_connection: ptr::null_mut(), // NULL = LAN connection
                dw_option_count: 1,
                dw_option_error: 0,
                p_options: options.as_mut_ptr(),
            };

            // 调用 InternetSetOptionW 清除代理
            let result = InternetSetOptionW(
                ptr::null_mut(),
                INTERNET_OPTION_PER_CONNECTION_OPTION,
                &mut option_list as *mut _ as *mut _,
                option_list.dw_size,
            );

            if result == 0 {
                let error = winapi::um::errhandlingapi::GetLastError();
                return Err(crate::error::PlatformError::SystemProxy(format!(
                    "InternetSetOptionW (unset) failed with error code: {}",
                    error
                ))
                .into());
            }

            // 通知系统代理设置已更改
            InternetSetOptionW(
                ptr::null_mut(),
                INTERNET_OPTION_SETTINGS_CHANGED,
                ptr::null_mut(),
                0,
            );

            // 刷新代理设置
            InternetSetOptionW(ptr::null_mut(), INTERNET_OPTION_REFRESH, ptr::null_mut(), 0);

            tracing::info!("WinInet API: Proxy cleared successfully");
        }

        Ok(())
    }
}

/// macOS platform implementation
#[cfg(target_os = "macos")]
pub struct MacOSPlatform;

#[cfg(target_os = "macos")]
impl PlatformOps for MacOSPlatform {
    fn has_admin_privileges(&self) -> crate::V8RayResult<bool> {
        // On macOS, networksetup requires admin privileges
        // Check if running as root or if user can use sudo
        #[cfg(unix)]
        {
            // Check if effective UID is 0 (root)
            let is_root = unsafe { libc::geteuid() } == 0;
            if is_root {
                return Ok(true);
            }

            // Check if user is in admin group (can use sudo)
            // This is a simplified check - in practice, networksetup will prompt for password
            use std::process::Command;
            let output = Command::new("groups").output().map_err(|e| {
                crate::error::PlatformError::Command(format!("Failed to check groups: {}", e))
            })?;

            let groups = String::from_utf8_lossy(&output.stdout);
            Ok(groups.contains("admin") || groups.contains("wheel"))
        }
        #[cfg(not(unix))]
        {
            Ok(false)
        }
    }

    fn set_system_proxy(&self, http_port: u16, socks_port: u16) -> crate::V8RayResult<()> {
        use std::process::Command;

        tracing::info!("Setting macOS system proxy: SOCKS={}", socks_port);

        // Get active network services
        let services = Self::get_network_services()?;

        for service in services {
            tracing::info!("Setting SOCKS proxy for network service: {}", service);

            // Set SOCKS proxy
            let output = Command::new("networksetup")
                .args([
                    "-setsocksfirewallproxy",
                    &service,
                    "127.0.0.1",
                    &socks_port.to_string(),
                ])
                .output()
                .map_err(|e| {
                    crate::error::PlatformError::SystemProxy(format!(
                        "Failed to set SOCKS proxy: {}",
                        e
                    ))
                })?;

            if !output.status.success() {
                tracing::warn!(
                    "Failed to set SOCKS proxy for {}: {}",
                    service,
                    String::from_utf8_lossy(&output.stderr)
                );
            }
        }

        tracing::info!("macOS system proxy (SOCKS) set successfully");
        Ok(())
    }

    fn clear_system_proxy(&self) -> crate::V8RayResult<()> {
        use std::process::Command;

        tracing::info!("Clearing macOS system proxy");

        // Get active network services
        let services = Self::get_network_services()?;

        for service in services {
            tracing::info!("Clearing SOCKS proxy for network service: {}", service);

            // Clear SOCKS proxy
            Command::new("networksetup")
                .args(["-setsocksfirewallproxystate", &service, "off"])
                .output()
                .ok();
        }

        tracing::info!("macOS system proxy (SOCKS) cleared successfully");
        Ok(())
    }

    fn is_system_proxy_set(&self) -> crate::V8RayResult<bool> {
        use std::process::Command;

        // Get active network services
        let services = Self::get_network_services()?;

        for service in services {
            // Check HTTP proxy state
            let output = Command::new("networksetup")
                .args(["-getwebproxy", &service])
                .output()
                .map_err(|e| {
                    crate::error::PlatformError::SystemProxy(format!(
                        "Failed to get HTTP proxy state: {}",
                        e
                    ))
                })?;

            if output.status.success() {
                let output_str = String::from_utf8_lossy(&output.stdout);
                if output_str.contains("Enabled: Yes") {
                    return Ok(true);
                }
            }
        }

        Ok(false)
    }

    fn enable_auto_start(&self) -> crate::V8RayResult<()> {
        // TODO: Implement macOS auto start
        tracing::info!("Enabling macOS auto start");
        Ok(())
    }

    fn disable_auto_start(&self) -> crate::V8RayResult<()> {
        // TODO: Implement macOS auto start disable
        tracing::info!("Disabling macOS auto start");
        Ok(())
    }

    fn is_auto_start_enabled(&self) -> crate::V8RayResult<bool> {
        // TODO: Implement macOS auto start check
        Ok(false)
    }
}

#[cfg(target_os = "macos")]
impl MacOSPlatform {
    fn get_network_services() -> crate::V8RayResult<Vec<String>> {
        use std::process::Command;

        let output = Command::new("networksetup")
            .arg("-listallnetworkservices")
            .output()
            .map_err(|e| {
                crate::error::PlatformError::SystemProxy(format!(
                    "Failed to list network services: {}",
                    e
                ))
            })?;

        if !output.status.success() {
            return Err(crate::error::PlatformError::SystemProxy(
                "Failed to get network services".to_string(),
            )
            .into());
        }

        let output_str = String::from_utf8_lossy(&output.stdout);
        let services: Vec<String> = output_str
            .lines()
            .skip(1) // Skip the first line (header)
            .filter(|line| !line.starts_with('*')) // Skip disabled services
            .map(|line| line.trim().to_string())
            .filter(|line| !line.is_empty())
            .collect();

        tracing::debug!("Found network services: {:?}", services);
        Ok(services)
    }
}

/// Linux platform implementation
#[cfg(target_os = "linux")]
pub struct LinuxPlatform;

#[cfg(target_os = "linux")]
impl PlatformOps for LinuxPlatform {
    fn has_admin_privileges(&self) -> crate::V8RayResult<bool> {
        // On Linux, check if running as root (UID 0)
        // Note: For system proxy settings, root is not always required
        // (gsettings works for current user), but some operations may need it
        #[cfg(unix)]
        {
            // Check if effective UID is 0 (root)
            let is_root = unsafe { libc::geteuid() } == 0;
            Ok(is_root)
        }
        #[cfg(not(unix))]
        {
            Ok(false)
        }
    }

    fn set_system_proxy(&self, _http_port: u16, socks_port: u16) -> crate::V8RayResult<()> {
        tracing::info!("Setting Linux system proxy: SOCKS={}", socks_port);

        let socks_proxy = format!("socks5://127.0.0.1:{}", socks_port);

        // Try to set proxy using gsettings (GNOME/Ubuntu)
        let gsettings_result = Self::set_gsettings_socks_proxy(&socks_proxy);

        if gsettings_result.is_ok() {
            tracing::info!("Successfully set system proxy using gsettings");
            return Ok(());
        }

        // Fallback: Set environment variables
        tracing::warn!("gsettings not available, using environment variables");
        std::env::set_var("all_proxy", &socks_proxy);
        std::env::set_var("ALL_PROXY", &socks_proxy);

        Ok(())
    }

    fn clear_system_proxy(&self) -> crate::V8RayResult<()> {
        tracing::info!("Clearing Linux system proxy");

        // Try to clear proxy using gsettings
        let gsettings_result = Self::clear_gsettings_proxy();

        if gsettings_result.is_ok() {
            tracing::info!("Successfully cleared system proxy using gsettings");
            return Ok(());
        }

        // Fallback: Clear environment variables
        tracing::warn!("gsettings not available, clearing environment variables");
        std::env::remove_var("all_proxy");
        std::env::remove_var("ALL_PROXY");

        Ok(())
    }

    fn is_system_proxy_set(&self) -> crate::V8RayResult<bool> {
        use std::process::Command;

        // Check gsettings first
        let output = Command::new("gsettings")
            .args(["get", "org.gnome.system.proxy", "mode"])
            .output();

        if let Ok(output) = output {
            if output.status.success() {
                let mode = String::from_utf8_lossy(&output.stdout);
                return Ok(mode.trim().contains("manual"));
            }
        }

        // Fallback: Check environment variables
        Ok(std::env::var("http_proxy").is_ok() || std::env::var("HTTP_PROXY").is_ok())
    }

    fn enable_auto_start(&self) -> crate::V8RayResult<()> {
        // TODO: Implement Linux auto start
        tracing::info!("Enabling Linux auto start");
        Ok(())
    }

    fn disable_auto_start(&self) -> crate::V8RayResult<()> {
        // TODO: Implement Linux auto start disable
        tracing::info!("Disabling Linux auto start");
        Ok(())
    }

    fn is_auto_start_enabled(&self) -> crate::V8RayResult<bool> {
        // TODO: Implement Linux auto start check
        Ok(false)
    }
}

#[cfg(target_os = "linux")]
impl LinuxPlatform {
    fn set_gsettings_socks_proxy(socks_proxy: &str) -> crate::V8RayResult<()> {
        use std::process::Command;

        // 获取实际用户（如果是通过 sudo 运行的）
        let actual_user = std::env::var("SUDO_USER").ok();

        // 创建 gsettings 命令的辅助函数
        let run_gsettings = |args: &[&str]| -> crate::V8RayResult<()> {
            let output = if let Some(ref user) = actual_user {
                // 如果是通过 sudo 运行的，使用实际用户的权限运行 gsettings
                Command::new("sudo")
                    .arg("-u")
                    .arg(user)
                    .arg("gsettings")
                    .args(args)
                    .output()
            } else {
                // 否则直接运行 gsettings
                Command::new("gsettings").args(args).output()
            }
            .map_err(|e| crate::error::PlatformError::SystemProxy(e.to_string()))?;

            if !output.status.success() {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(crate::error::PlatformError::SystemProxy(format!(
                    "gsettings command failed: {}",
                    stderr
                ))
                .into());
            }
            Ok(())
        };

        // Set proxy mode to manual
        run_gsettings(&["set", "org.gnome.system.proxy", "mode", "manual"])?;
        tracing::info!("Successfully set proxy mode to manual");

        // Extract host and port from socks_proxy
        let socks_url = socks_proxy
            .trim_start_matches("socks5://")
            .trim_start_matches("socks://");
        let socks_parts: Vec<&str> = socks_url.split(':').collect();
        if socks_parts.len() != 2 {
            return Err(crate::error::PlatformError::SystemProxy(
                "Invalid SOCKS proxy URL format".to_string(),
            )
            .into());
        }
        let socks_host = socks_parts[0];
        let socks_port = socks_parts[1];

        // Set SOCKS proxy
        run_gsettings(&["set", "org.gnome.system.proxy.socks", "host", socks_host])?;
        run_gsettings(&["set", "org.gnome.system.proxy.socks", "port", socks_port])?;

        tracing::info!("Successfully set SOCKS proxy settings");
        Ok(())
    }

    fn clear_gsettings_proxy() -> crate::V8RayResult<()> {
        use std::process::Command;

        // 获取实际用户（如果是通过 sudo 运行的）
        let actual_user = std::env::var("SUDO_USER").ok();

        // Set proxy mode to none
        let output = if let Some(ref user) = actual_user {
            // 如果是通过 sudo 运行的，使用实际用户的权限运行 gsettings
            Command::new("sudo")
                .arg("-u")
                .arg(user)
                .arg("gsettings")
                .args(["set", "org.gnome.system.proxy", "mode", "none"])
                .output()
        } else {
            // 否则直接运行 gsettings
            Command::new("gsettings")
                .args(["set", "org.gnome.system.proxy", "mode", "none"])
                .output()
        }
        .map_err(|e| crate::error::PlatformError::SystemProxy(e.to_string()))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(crate::error::PlatformError::SystemProxy(format!(
                "Failed to clear proxy mode: {}",
                stderr
            ))
            .into());
        }

        tracing::info!("Successfully cleared system proxy");
        Ok(())
    }
}

/// iOS platform implementation (VPN mode only, no system proxy)
#[cfg(target_os = "ios")]
pub struct IOSPlatform;

#[cfg(target_os = "ios")]
impl PlatformOps for IOSPlatform {
    fn has_admin_privileges(&self) -> crate::V8RayResult<bool> {
        // iOS apps run in sandbox, no admin privileges concept
        Ok(false)
    }

    fn set_system_proxy(&self, _http_port: u16, _socks_port: u16) -> crate::V8RayResult<()> {
        Err(crate::error::PlatformError::SystemProxy(
            "iOS does not support system proxy. Use VPN mode instead.".to_string(),
        )
        .into())
    }

    fn clear_system_proxy(&self) -> crate::V8RayResult<()> {
        Err(crate::error::PlatformError::SystemProxy(
            "iOS does not support system proxy. Use VPN mode instead.".to_string(),
        )
        .into())
    }

    fn is_system_proxy_set(&self) -> crate::V8RayResult<bool> {
        Ok(false)
    }

    fn enable_auto_start(&self) -> crate::V8RayResult<()> {
        Err(
            crate::error::PlatformError::SystemProxy("iOS does not support auto start".to_string())
                .into(),
        )
    }

    fn disable_auto_start(&self) -> crate::V8RayResult<()> {
        Err(
            crate::error::PlatformError::SystemProxy("iOS does not support auto start".to_string())
                .into(),
        )
    }

    fn is_auto_start_enabled(&self) -> crate::V8RayResult<bool> {
        Ok(false)
    }
}

/// Android platform implementation (VPN mode only, no system proxy)
#[cfg(target_os = "android")]
pub struct AndroidPlatform;

#[cfg(target_os = "android")]
impl PlatformOps for AndroidPlatform {
    fn has_admin_privileges(&self) -> crate::V8RayResult<bool> {
        // Android apps run in sandbox, no admin privileges concept
        // Root access is a different matter and not recommended
        Ok(false)
    }

    fn set_system_proxy(&self, _http_port: u16, _socks_port: u16) -> crate::V8RayResult<()> {
        Err(crate::error::PlatformError::SystemProxy(
            "Android does not support system proxy. Use VPN mode instead.".to_string(),
        )
        .into())
    }

    fn clear_system_proxy(&self) -> crate::V8RayResult<()> {
        Err(crate::error::PlatformError::SystemProxy(
            "Android does not support system proxy. Use VPN mode instead.".to_string(),
        )
        .into())
    }

    fn is_system_proxy_set(&self) -> crate::V8RayResult<bool> {
        Ok(false)
    }

    fn enable_auto_start(&self) -> crate::V8RayResult<()> {
        Err(crate::error::PlatformError::SystemProxy(
            "Android does not support auto start".to_string(),
        )
        .into())
    }

    fn disable_auto_start(&self) -> crate::V8RayResult<()> {
        Err(crate::error::PlatformError::SystemProxy(
            "Android does not support auto start".to_string(),
        )
        .into())
    }

    fn is_auto_start_enabled(&self) -> crate::V8RayResult<bool> {
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

    #[cfg(target_os = "ios")]
    return Box::new(IOSPlatform);

    #[cfg(target_os = "android")]
    return Box::new(AndroidPlatform);

    #[cfg(not(any(
        target_os = "windows",
        target_os = "macos",
        target_os = "linux",
        target_os = "ios",
        target_os = "android"
    )))]
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
            info.capabilities.system_proxy
                || info.capabilities.vpn_mode
                || info.capabilities.tun_mode
                || info.capabilities.auto_start
        );
    }
}
