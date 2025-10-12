//! Flutter Rust Bridge API 定义
//!
//! 这个文件定义了 Rust 和 Flutter 之间的 FFI 接口
//! 使用 flutter_rust_bridge 自动生成绑定代码

use anyhow::Result;
use serde::{Deserialize, Serialize};

// ============================================================================
// 数据类型定义
// ============================================================================

/// 连接状态
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ConnectionStatus {
    /// 已断开
    Disconnected,
    /// 连接中
    Connecting,
    /// 已连接
    Connected,
    /// 断开中
    Disconnecting,
    /// 错误
    Error,
}

/// 连接信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectionInfo {
    /// 连接状态
    pub status: ConnectionStatus,
    /// 服务器地址
    pub server_address: Option<String>,
    /// 连接时长（秒）
    pub duration: u64,
    /// 上传流量（字节）
    pub upload_bytes: u64,
    /// 下载流量（字节）
    pub download_bytes: u64,
    /// 延迟（毫秒）
    pub latency_ms: Option<u32>,
}

/// 配置信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigInfo {
    /// 配置 ID
    pub id: String,
    /// 配置名称
    pub name: String,
    /// 服务器地址
    pub server: String,
    /// 端口
    pub port: u16,
    /// 协议类型
    pub protocol: String,
    /// 是否启用
    pub enabled: bool,
    /// 创建时间（Unix 时间戳）
    pub created_at: i64,
    /// 更新时间（Unix 时间戳）
    pub updated_at: i64,
}

/// 流量统计
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrafficStats {
    /// 上传速度（字节/秒）
    pub upload_speed: u64,
    /// 下载速度（字节/秒）
    pub download_speed: u64,
    /// 总上传流量（字节）
    pub total_upload: u64,
    /// 总下载流量（字节）
    pub total_download: u64,
}

/// 事件类型
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum V8RayEvent {
    /// 连接状态变化
    ConnectionStatusChanged {
        /// 新状态
        status: ConnectionStatus,
    },
    /// 流量统计更新
    TrafficStatsUpdated {
        /// 流量统计
        stats: TrafficStats,
    },
    /// 错误事件
    Error {
        /// 错误消息
        message: String,
    },
    /// 日志消息
    Log {
        /// 日志级别
        level: String,
        /// 日志消息
        message: String,
    },
}

// ============================================================================
// FFI 接口定义
// ============================================================================

/// 初始化 V8Ray Core
///
/// 必须在使用其他 API 之前调用
///
/// # 返回
/// - `Ok(())`: 初始化成功
/// - `Err(e)`: 初始化失败
pub fn init_v8ray() -> Result<()> {
    crate::bridge::init()
}

/// 关闭 V8Ray Core
///
/// 释放所有资源
///
/// # 返回
/// - `Ok(())`: 关闭成功
/// - `Err(e)`: 关闭失败
pub fn shutdown_v8ray() -> Result<()> {
    crate::bridge::shutdown()
}

// ============================================================================
// 配置管理 API
// ============================================================================

/// 加载配置
///
/// # 参数
/// - `config_id`: 配置 ID
///
/// # 返回
/// - `Ok(config)`: 配置信息
/// - `Err(e)`: 加载失败
pub fn load_config(config_id: String) -> Result<ConfigInfo> {
    crate::bridge::config::load_config(&config_id)
}

/// 保存配置
///
/// # 参数
/// - `config`: 配置信息
///
/// # 返回
/// - `Ok(())`: 保存成功
/// - `Err(e)`: 保存失败
pub fn save_config(config: ConfigInfo) -> Result<()> {
    crate::bridge::config::save_config(config)
}

/// 删除配置
///
/// # 参数
/// - `config_id`: 配置 ID
///
/// # 返回
/// - `Ok(())`: 删除成功
/// - `Err(e)`: 删除失败
pub fn delete_config(config_id: String) -> Result<()> {
    crate::bridge::config::delete_config(&config_id)
}

/// 列出所有配置
///
/// # 返回
/// - `Ok(configs)`: 配置列表
/// - `Err(e)`: 列出失败
pub fn list_configs() -> Result<Vec<ConfigInfo>> {
    crate::bridge::config::list_configs()
}

/// 验证配置
///
/// # 参数
/// - `config`: 配置信息
///
/// # 返回
/// - `Ok(true)`: 配置有效
/// - `Ok(false)`: 配置无效
/// - `Err(e)`: 验证失败
pub fn validate_config(config: ConfigInfo) -> Result<bool> {
    crate::bridge::config::validate_config(config)
}

// ============================================================================
// 连接管理 API
// ============================================================================

/// 连接到服务器
///
/// # 参数
/// - `config_id`: 配置 ID
///
/// # 返回
/// - `Ok(())`: 连接成功
/// - `Err(e)`: 连接失败
pub fn connect(config_id: String) -> Result<()> {
    crate::bridge::connection::connect(&config_id)
}

/// 断开连接
///
/// # 返回
/// - `Ok(())`: 断开成功
/// - `Err(e)`: 断开失败
pub fn disconnect() -> Result<()> {
    crate::bridge::connection::disconnect()
}

/// 获取连接信息
///
/// # 返回
/// - `Ok(info)`: 连接信息
/// - `Err(e)`: 获取失败
pub fn get_connection_info() -> Result<ConnectionInfo> {
    crate::bridge::connection::get_connection_info()
}

/// 测试连接延迟
///
/// # 参数
/// - `config_id`: 配置 ID
///
/// # 返回
/// - `Ok(latency_ms)`: 延迟（毫秒）
/// - `Err(e)`: 测试失败
pub fn test_latency(config_id: String) -> Result<u32> {
    crate::bridge::connection::test_latency(&config_id)
}

// ============================================================================
// 流量统计 API
// ============================================================================

/// 获取流量统计
///
/// # 返回
/// - `Ok(stats)`: 流量统计
/// - `Err(e)`: 获取失败
pub fn get_traffic_stats() -> Result<TrafficStats> {
    crate::bridge::traffic::get_traffic_stats()
}

/// 重置流量统计
///
/// # 返回
/// - `Ok(())`: 重置成功
/// - `Err(e)`: 重置失败
pub fn reset_traffic_stats() -> Result<()> {
    crate::bridge::traffic::reset_traffic_stats()
}

// ============================================================================
// 事件流 API
// ============================================================================

/// 创建事件流
///
/// 返回一个事件流，用于接收 V8Ray 事件
///
/// # 返回
/// - 事件流
pub fn create_event_stream() -> impl futures::Stream<Item = V8RayEvent> {
    crate::bridge::events::create_event_stream()
}

