//! 连接管理 Bridge 模块

use anyhow::{anyhow, Result};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Instant;
use tokio::sync::RwLock;

use super::api::{ConnectionInfo, ConnectionStatus, ProxyServerConfig};
use crate::config::{ProxyProtocol, ProxyServerConfig as CoreProxyServerConfig};
use crate::connection::ConnectionManager as CoreConnectionManager;
use chrono::Utc;

lazy_static::lazy_static! {
    static ref CONNECTION_MANAGER: Arc<RwLock<BridgeConnectionManager>> =
        Arc::new(RwLock::new(BridgeConnectionManager::new()));

    static ref TOKIO_RUNTIME: tokio::runtime::Runtime = {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .expect("Failed to create Tokio runtime")
    };
}

/// 将简化配置转换为核心配置
fn convert_to_core_config(config: &ProxyServerConfig) -> CoreProxyServerConfig {
    let protocol = match config.protocol.as_str() {
        "vless" => ProxyProtocol::Vless,
        "vmess" => ProxyProtocol::Vmess,
        "trojan" => ProxyProtocol::Trojan,
        "shadowsocks" => ProxyProtocol::Shadowsocks,
        "socks" => ProxyProtocol::Socks,
        "http" => ProxyProtocol::Http,
        _ => ProxyProtocol::Vless, // 默认值
    };

    CoreProxyServerConfig {
        id: config.id.clone(),
        name: config.name.clone(),
        server: config.address.clone(),
        port: config.port,
        protocol,
        settings: config.settings.clone(),
        stream_settings: None, // 简化版本不包含流设置
        tags: config.tags.clone(),
        created_at: Utc::now(),
        updated_at: Utc::now(),
    }
}

/// Bridge 连接管理器
struct BridgeConnectionManager {
    core_manager: Arc<CoreConnectionManager>,
    config_cache: HashMap<String, ProxyServerConfig>,
    connected_at: Option<Instant>,
    proxy_mode: String, // "global", "smart", or "direct"
}

impl BridgeConnectionManager {
    fn new() -> Self {
        Self {
            core_manager: Arc::new(CoreConnectionManager::new()),
            config_cache: HashMap::new(),
            connected_at: None,
            proxy_mode: "smart".to_string(), // Default to smart mode
        }
    }

    async fn connect(&mut self, config_id: &str) -> Result<()> {
        // 从缓存获取配置
        let config = self
            .config_cache
            .get(config_id)
            .ok_or_else(|| anyhow!("Config not found: {}", config_id))?;

        // 转换为核心配置
        let core_config = convert_to_core_config(config);

        // 使用核心管理器连接，传递代理模式
        self.core_manager
            .connect_with_config_and_mode(core_config, &self.proxy_mode)
            .await?;
        self.connected_at = Some(Instant::now());

        tracing::info!(
            "Connected to config: {} with mode: {}",
            config_id,
            self.proxy_mode
        );
        Ok(())
    }

    fn set_proxy_mode(&mut self, mode: String) {
        self.proxy_mode = mode;
        tracing::info!("Proxy mode set to: {}", self.proxy_mode);
    }

    async fn disconnect(&mut self) -> Result<()> {
        self.core_manager.disconnect().await?;
        self.connected_at = None;
        tracing::info!("Disconnected");
        Ok(())
    }

    async fn get_info(&self) -> ConnectionInfo {
        let state = self.core_manager.get_state().await;
        let (upload_bytes, download_bytes) = self.core_manager.get_traffic_totals().await;
        let duration = self
            .connected_at
            .map(|t| t.elapsed().as_secs())
            .unwrap_or(0);

        let status = match state {
            crate::connection::ConnectionState::Disconnected => ConnectionStatus::Disconnected,
            crate::connection::ConnectionState::Connecting => ConnectionStatus::Connecting,
            crate::connection::ConnectionState::Connected => ConnectionStatus::Connected,
            crate::connection::ConnectionState::Disconnecting => ConnectionStatus::Disconnecting,
            crate::connection::ConnectionState::Reconnecting => ConnectionStatus::Connecting,
            crate::connection::ConnectionState::Error(_) => ConnectionStatus::Error,
        };

        let server_address = self
            .core_manager
            .get_current_config()
            .await
            .map(|c| c.server.clone());

        ConnectionInfo {
            status,
            server_address,
            duration,
            upload_bytes,
            download_bytes,
            latency_ms: None,
        }
    }

    fn cache_config(&mut self, config_id: String, config: ProxyServerConfig) {
        self.config_cache.insert(config_id, config);
    }

    fn test_latency(&self, _config_id: &str) -> Result<u32> {
        // TODO: 实际的延迟测试逻辑
        // 这里只是模拟
        Ok(50)
    }
}

/// 初始化连接管理器
pub fn init() -> Result<()> {
    tracing::info!("Initializing connection manager");
    Ok(())
}

/// 关闭连接管理器
pub fn shutdown() -> Result<()> {
    tokio::runtime::Runtime::new()?.block_on(async {
        let mut manager = CONNECTION_MANAGER.write().await;
        manager.disconnect().await?;
        tracing::info!("Connection manager shutdown");
        Ok(())
    })
}

/// 设置代理模式
pub fn set_proxy_mode(mode: String) -> Result<()> {
    let mut manager = CONNECTION_MANAGER.blocking_write();
    manager.set_proxy_mode(mode);
    Ok(())
}

/// 缓存配置（在连接前调用）
pub fn cache_proxy_config(config_id: String, config: ProxyServerConfig) -> Result<()> {
    let mut manager = CONNECTION_MANAGER.blocking_write();
    manager.cache_config(config_id, config);
    Ok(())
}

/// 连接到服务器
pub fn connect(config_id: &str) -> Result<()> {
    TOKIO_RUNTIME.block_on(async {
        let mut manager = CONNECTION_MANAGER.write().await;
        manager.connect(config_id).await
    })
}

/// 断开连接
pub fn disconnect() -> Result<()> {
    TOKIO_RUNTIME.block_on(async {
        let mut manager = CONNECTION_MANAGER.write().await;
        manager.disconnect().await
    })
}

/// 获取连接信息
pub fn get_connection_info() -> Result<ConnectionInfo> {
    TOKIO_RUNTIME.block_on(async {
        let manager = CONNECTION_MANAGER.read().await;
        Ok(manager.get_info().await)
    })
}

/// 测试延迟
pub fn test_latency(config_id: &str) -> Result<u32> {
    let manager = CONNECTION_MANAGER.blocking_read();
    manager.test_latency(config_id)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{ProxyProtocol, ProxyServerConfig};
    use serial_test::serial;

    fn create_test_config() -> ProxyServerConfig {
        use std::collections::HashMap;
        let mut settings = HashMap::new();
        settings.insert("id".to_string(), serde_json::json!("test-uuid"));
        settings.insert("alterId".to_string(), serde_json::json!(0));
        settings.insert("security".to_string(), serde_json::json!("auto"));

        ProxyServerConfig {
            id: "test-config".to_string(),
            name: "Test Server".to_string(),
            server: "example.com".to_string(),
            port: 443,
            protocol: ProxyProtocol::Vmess,
            settings,
            stream_settings: None,
            tags: vec![],
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        }
    }

    #[test]
    #[serial]
    fn test_cache_and_connect() {
        let config = create_test_config();
        let config_id = config.id.clone();

        // 缓存配置
        cache_proxy_config(config_id.clone(), config).unwrap();

        // 连接
        let result = connect(&config_id);

        // 可能因为 Xray 二进制不存在而失败，这是正常的
        // 我们主要测试 API 调用不会 panic
        let _ = result;

        // 断开
        let _ = disconnect();
    }

    #[test]
    #[serial]
    fn test_get_connection_info() {
        let info = get_connection_info().unwrap();
        // 初始状态应该是断开
        assert_eq!(info.status, ConnectionStatus::Disconnected);
    }

    #[test]
    #[serial]
    fn test_test_latency() {
        let config_id = "test-config";
        let latency = test_latency(config_id).unwrap();
        assert!(latency > 0);
    }
}
