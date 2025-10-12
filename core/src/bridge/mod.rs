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
    // 使用 try-catch 来捕获 panic
    let log_result = std::panic::catch_unwind(|| {
        let log_config = crate::utils::logger::LogConfig::default();
        crate::utils::logger::init_logger(&log_config)
    });

    // 忽略日志初始化错误（可能已经初始化过了）
    match log_result {
        Ok(Ok(_)) => {},
        Ok(Err(_)) => {},  // 日志初始化失败,继续
        Err(_) => {},      // panic 被捕获,继续
    }

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
        // 初始化可能会因为日志系统已经初始化而失败,这是正常的
        let result = init();
        // 只要不是其他错误就可以
        match result {
            Ok(_) => {},
            Err(e) => {
                // 允许日志系统重复初始化的错误
                assert!(e.to_string().contains("global default"));
            }
        }
    }

    #[test]
    #[serial]
    fn test_shutdown() {
        // 初始化可能会因为日志系统已经初始化而失败,这是正常的
        let _ = init();
        let result = shutdown();
        assert!(result.is_ok());
    }
}
