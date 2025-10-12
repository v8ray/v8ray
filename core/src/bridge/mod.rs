//! Flutter Rust Bridge Module
//!
//! This module provides the FFI interface for communication between
//! the Rust core and Flutter frontend.

use anyhow::Result;
use std::sync::Arc;
use tokio::sync::RwLock;

// 子模块
/// API 定义模块
pub mod api;
/// 配置管理模块
pub mod config;
/// 连接管理模块
pub mod connection;
/// 事件流模块
pub mod events;
/// 流量统计模块
pub mod traffic;

// 全局状态
lazy_static::lazy_static! {
    static ref BRIDGE_STATE: Arc<RwLock<BridgeState>> = Arc::new(RwLock::new(BridgeState::default()));
}

/// Bridge 状态
#[derive(Debug, Default)]
struct BridgeState {
    initialized: bool,
}

/// 初始化 Bridge
pub fn init() -> Result<()> {
    let mut state = BRIDGE_STATE.blocking_write();
    if state.initialized {
        return Ok(());
    }

    // 初始化日志（忽略重复初始化错误）
    let log_config = crate::utils::logger::LogConfig::default();
    let _ = crate::utils::logger::init_logger(&log_config);

    // 初始化配置管理器
    config::init()?;

    // 初始化连接管理器
    connection::init()?;

    // 初始化事件系统
    events::init()?;

    state.initialized = true;
    tracing::info!("V8Ray Bridge initialized successfully");
    Ok(())
}

/// 关闭 Bridge
pub fn shutdown() -> Result<()> {
    let mut state = BRIDGE_STATE.blocking_write();
    if !state.initialized {
        return Ok(());
    }

    // 关闭连接
    connection::shutdown()?;

    // 关闭事件系统
    events::shutdown()?;

    state.initialized = false;
    tracing::info!("V8Ray Bridge shutdown successfully");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;

    #[test]
    #[serial]
    fn test_init() {
        let result = init();
        assert!(result.is_ok());
    }

    #[test]
    #[serial]
    fn test_shutdown() {
        init().unwrap();
        let result = shutdown();
        assert!(result.is_ok());
    }
}
