//! Flutter Rust Bridge API 定义
//!
//! 这个文件定义了 Rust 和 Flutter 之间的 FFI 接口
//! 使用 flutter_rust_bridge 自动生成绑定代码

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

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

/// 简化的代理服务器配置（用于 FFI）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProxyServerConfig {
    /// 服务器 ID
    pub id: String,
    /// 服务器名称
    pub name: String,
    /// 服务器地址
    pub address: String,
    /// 服务器端口
    pub port: u16,
    /// 协议类型
    pub protocol: String,
    /// 协议特定设置
    pub settings: HashMap<String, serde_json::Value>,
    /// 流设置 (传输层配置)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stream_settings: Option<serde_json::Value>,
    /// 标签
    pub tags: Vec<String>,
}

/// 订阅信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubscriptionInfo {
    /// 订阅 ID
    pub id: String,
    /// 订阅名称
    pub name: String,
    /// 订阅 URL
    pub url: String,
    /// 最后更新时间（Unix 时间戳）
    pub last_update: Option<i64>,
    /// 服务器数量
    pub server_count: i32,
    /// 订阅状态
    pub status: String,
}

/// 服务器信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerInfo {
    /// 服务器 ID
    pub id: String,
    /// 所属订阅 ID
    pub subscription_id: String,
    /// 服务器名称
    pub name: String,
    /// 服务器地址
    pub address: String,
    /// 端口
    pub port: i32,
    /// 协议类型
    pub protocol: String,
}

/// Xray Core 更新信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XrayCoreUpdateInfo {
    /// 是否有更新
    pub has_update: bool,
    /// 当前版本
    pub current_version: String,
    /// 最新版本
    pub latest_version: String,
    /// 下载 URL
    pub download_url: String,
    /// 文件大小（字节）
    pub file_size: u64,
}

/// 事件类型
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum V8RayEvent {
    /// 连接状态变化
    ConnectionStatusChanged {
        /// 新状态
        status: ConnectionStatus,
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

/// 缓存代理配置（在连接前调用）
///
/// # 参数
/// - `config_id`: 配置 ID
/// - `config`: 代理服务器配置
///
/// # 返回
/// - `Ok(())`: 缓存成功
/// - `Err(e)`: 缓存失败
pub fn cache_proxy_config(config_id: String, config: ProxyServerConfig) -> Result<()> {
    crate::bridge::connection::cache_proxy_config(config_id, config)
}

/// 设置代理模式
///
/// # 参数
/// - `mode`: 代理模式 ("global", "smart", "direct")
///
/// # 返回
/// - `Ok(())`: 设置成功
/// - `Err(e)`: 设置失败
pub fn set_proxy_mode(mode: String) -> Result<()> {
    crate::bridge::connection::set_proxy_mode(mode)
}

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

// ============================================================================
// 订阅管理 API
// ============================================================================

/// 初始化订阅管理器
///
/// # 参数
/// - `db_path`: 数据库路径
///
/// # 返回
/// - `Ok(())`: 初始化成功
/// - `Err(e)`: 初始化失败
pub async fn init_subscription_manager(db_path: String) -> Result<()> {
    crate::bridge::subscription::init_subscription_manager(db_path).await
}

/// 添加订阅
///
/// # 参数
/// - `name`: 订阅名称
/// - `url`: 订阅 URL
///
/// # 返回
/// - `Ok(id)`: 订阅 ID
/// - `Err(e)`: 添加失败
pub async fn add_subscription(name: String, url: String) -> Result<String> {
    crate::bridge::subscription::add_subscription(name, url).await
}

/// 删除订阅
///
/// # 参数
/// - `id`: 订阅 ID
///
/// # 返回
/// - `Ok(())`: 删除成功
/// - `Err(e)`: 删除失败
pub async fn remove_subscription(id: String) -> Result<()> {
    crate::bridge::subscription::remove_subscription(id).await
}

/// 更新订阅
///
/// # 参数
/// - `id`: 订阅 ID
///
/// # 返回
/// - `Ok(())`: 更新成功
/// - `Err(e)`: 更新失败
pub async fn update_subscription(id: String) -> Result<()> {
    crate::bridge::subscription::update_subscription(id).await
}

/// 更新所有订阅
///
/// # 返回
/// - `Ok(())`: 更新成功
/// - `Err(e)`: 更新失败
pub async fn update_all_subscriptions() -> Result<()> {
    crate::bridge::subscription::update_all_subscriptions().await
}

/// 获取所有订阅
///
/// # 返回
/// - `Ok(subscriptions)`: 订阅列表
/// - `Err(e)`: 获取失败
pub async fn get_subscriptions() -> Result<Vec<SubscriptionInfo>> {
    crate::bridge::subscription::get_subscriptions().await
}

/// 获取所有服务器
///
/// # 返回
/// - `Ok(servers)`: 服务器列表
/// - `Err(e)`: 获取失败
pub async fn get_servers() -> Result<Vec<ServerInfo>> {
    crate::bridge::subscription::get_servers().await
}

/// 获取指定订阅的服务器
///
/// # 参数
/// - `subscription_id`: 订阅 ID
///
/// # 返回
/// - `Ok(servers)`: 服务器列表
/// - `Err(e)`: 获取失败
pub async fn get_servers_for_subscription(subscription_id: String) -> Result<Vec<ServerInfo>> {
    crate::bridge::subscription::get_servers_for_subscription(subscription_id).await
}

/// 获取服务器配置
///
/// # 参数
/// - `server_id`: 服务器 ID
///
/// # 返回
/// - `Ok(config)`: 服务器配置
/// - `Err(e)`: 获取失败
pub async fn get_server_config(server_id: String) -> Result<ProxyServerConfig> {
    crate::bridge::subscription::get_server_config(server_id).await
}

/// 从存储加载订阅
///
/// # 返回
/// - `Ok(())`: 加载成功
/// - `Err(e)`: 加载失败
pub async fn load_subscriptions_from_storage() -> Result<()> {
    crate::bridge::subscription::load_subscriptions_from_storage().await
}

// ============================================================================
// 平台相关 API
// ============================================================================

/// 设置系统代理
///
/// # 参数
/// - `http_port`: HTTP 代理端口
/// - `socks_port`: SOCKS 代理端口
///
/// # 返回
/// - `Ok(())`: 设置成功
/// - `Err(e)`: 设置失败
#[flutter_rust_bridge::frb(sync)]
pub fn set_system_proxy(http_port: u16, socks_port: u16) -> Result<(), String> {
    tracing::info!(
        "FFI: set_system_proxy called with http_port={}, socks_port={}",
        http_port,
        socks_port
    );
    let result = crate::bridge::platform::set_system_proxy(http_port, socks_port);
    if let Err(ref e) = result {
        tracing::error!("FFI: set_system_proxy failed: {}", e);
    } else {
        tracing::info!("FFI: set_system_proxy succeeded");
    }
    result
}

/// 清除系统代理
///
/// # 返回
/// - `Ok(())`: 清除成功
/// - `Err(e)`: 清除失败
#[flutter_rust_bridge::frb(sync)]
pub fn clear_system_proxy() -> Result<(), String> {
    crate::bridge::platform::clear_system_proxy()
}

/// 检查系统代理是否已设置
///
/// # 返回
/// - `Ok(true)`: 代理已设置
/// - `Ok(false)`: 代理未设置
/// - `Err(e)`: 检查失败
#[flutter_rust_bridge::frb(sync)]
pub fn is_system_proxy_set() -> Result<bool, String> {
    crate::bridge::platform::is_system_proxy_set()
}

/// 检查 Xray Core 更新
///
/// # 返回
/// - `Ok(info)`: 更新信息
/// - `Err(e)`: 检查失败
pub async fn check_xray_core_update() -> Result<XrayCoreUpdateInfo> {
    // 获取 ConnectionManager 实例
    let connection_manager = crate::bridge::connection::get_core_connection_manager()?;

    // 获取 XrayCore 实例
    let xray_core = connection_manager.get_xray();

    // 获取 updater
    let updater = xray_core.get_updater();
    let update_info = updater
        .check_update()
        .await
        .map_err(|e| anyhow::anyhow!("Failed to check update: {}", e))?;

    Ok(XrayCoreUpdateInfo {
        has_update: update_info.has_update,
        current_version: update_info.current_version,
        latest_version: update_info.latest_version,
        download_url: update_info.download_url,
        file_size: update_info.file_size,
    })
}

/// 下载并安装 Xray Core 更新
///
/// # 参数
/// - `version`: 要更新的版本号
///
/// # 返回
/// - `Ok(())`: 更新成功
/// - `Err(e)`: 更新失败
pub async fn update_xray_core(version: String) -> Result<()> {
    // 获取 ConnectionManager 实例
    let connection_manager = crate::bridge::connection::get_core_connection_manager()?;

    // 获取 XrayCore 实例
    let xray_core = connection_manager.get_xray();

    // 获取 updater
    let updater = xray_core.get_updater();
    updater
        .update(&version)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to update Xray Core: {}", e))?;

    Ok(())
}

/// 获取 Xray Core 下载进度
///
/// # 返回
/// - 下载进度 (0.0 到 1.0)
pub async fn get_xray_core_update_progress() -> Result<f64> {
    // 获取 ConnectionManager 实例
    let connection_manager = crate::bridge::connection::get_core_connection_manager()?;

    // 获取 XrayCore 实例
    let xray_core = connection_manager.get_xray();

    // 获取 updater
    let updater = xray_core.get_updater();
    Ok(updater.get_progress().await)
}

/// 获取平台信息
///
/// # 返回
/// 平台信息，包括操作系统、架构、版本和功能支持
#[flutter_rust_bridge::frb(sync)]
pub fn get_platform_info() -> crate::platform::PlatformInfo {
    crate::bridge::platform::get_platform_information()
}

/// 检查是否有管理员权限
///
/// # 返回
/// * `Ok(true)` - 有管理员权限
/// * `Ok(false)` - 没有管理员权限
/// * `Err(String)` - 检查失败
#[flutter_rust_bridge::frb(sync)]
pub fn has_admin_privileges() -> Result<bool, String> {
    crate::bridge::platform::has_admin_privileges()
}
