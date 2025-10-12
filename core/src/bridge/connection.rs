//! 连接管理 Bridge 模块

use anyhow::{anyhow, Result};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;

use super::api::{ConnectionInfo, ConnectionStatus};

lazy_static::lazy_static! {
    static ref CONNECTION_MANAGER: Arc<RwLock<ConnectionManager>> = Arc::new(RwLock::new(ConnectionManager::new()));
}

/// 连接管理器
struct ConnectionManager {
    status: ConnectionStatus,
    config_id: Option<String>,
    server_address: Option<String>,
    connected_at: Option<Instant>,
    upload_bytes: u64,
    download_bytes: u64,
}

impl ConnectionManager {
    fn new() -> Self {
        Self {
            status: ConnectionStatus::Disconnected,
            config_id: None,
            server_address: None,
            connected_at: None,
            upload_bytes: 0,
            download_bytes: 0,
        }
    }

    fn connect(&mut self, config_id: &str) -> Result<()> {
        if self.status == ConnectionStatus::Connected {
            return Err(anyhow!("Already connected"));
        }

        self.status = ConnectionStatus::Connecting;

        // TODO: 实际的连接逻辑
        // 这里只是模拟
        std::thread::sleep(Duration::from_millis(100));

        self.status = ConnectionStatus::Connected;
        self.config_id = Some(config_id.to_string());
        self.server_address = Some(format!("server-{}", config_id));
        self.connected_at = Some(Instant::now());

        tracing::info!("Connected to config: {}", config_id);
        Ok(())
    }

    fn disconnect(&mut self) -> Result<()> {
        if self.status == ConnectionStatus::Disconnected {
            return Ok(());
        }

        self.status = ConnectionStatus::Disconnecting;

        // TODO: 实际的断开逻辑
        std::thread::sleep(Duration::from_millis(50));

        self.status = ConnectionStatus::Disconnected;
        self.config_id = None;
        self.server_address = None;
        self.connected_at = None;

        tracing::info!("Disconnected");
        Ok(())
    }

    fn get_info(&self) -> ConnectionInfo {
        let duration = self
            .connected_at
            .map(|t| t.elapsed().as_secs())
            .unwrap_or(0);

        ConnectionInfo {
            status: self.status,
            server_address: self.server_address.clone(),
            duration,
            upload_bytes: self.upload_bytes,
            download_bytes: self.download_bytes,
            latency_ms: None,
        }
    }

    fn test_latency(&self, _config_id: &str) -> Result<u32> {
        // TODO: 实际的延迟测试逻辑
        // 这里只是模拟
        Ok(50)
    }

    #[allow(dead_code)]
    fn update_traffic(&mut self, upload: u64, download: u64) {
        self.upload_bytes += upload;
        self.download_bytes += download;
    }
}

/// 初始化连接管理器
pub fn init() -> Result<()> {
    tracing::info!("Initializing connection manager");
    Ok(())
}

/// 关闭连接管理器
pub fn shutdown() -> Result<()> {
    let mut manager = CONNECTION_MANAGER.blocking_write();
    manager.disconnect()?;
    tracing::info!("Connection manager shutdown");
    Ok(())
}

/// 连接到服务器
pub fn connect(config_id: &str) -> Result<()> {
    let mut manager = CONNECTION_MANAGER.blocking_write();
    manager.connect(config_id)
}

/// 断开连接
pub fn disconnect() -> Result<()> {
    let mut manager = CONNECTION_MANAGER.blocking_write();
    manager.disconnect()
}

/// 获取连接信息
pub fn get_connection_info() -> Result<ConnectionInfo> {
    let manager = CONNECTION_MANAGER.blocking_read();
    Ok(manager.get_info())
}

/// 测试延迟
pub fn test_latency(config_id: &str) -> Result<u32> {
    let manager = CONNECTION_MANAGER.blocking_read();
    manager.test_latency(config_id)
}

/// 更新流量统计（内部使用）
#[allow(dead_code)]
pub(crate) fn update_traffic(upload: u64, download: u64) {
    if let Ok(mut manager) = CONNECTION_MANAGER.try_write() {
        manager.update_traffic(upload, download);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;

    #[test]
    #[serial]
    fn test_connect_and_disconnect() {
        let config_id = "test-config";

        connect(config_id).unwrap();

        let info = get_connection_info().unwrap();
        assert_eq!(info.status, ConnectionStatus::Connected);
        assert_eq!(info.server_address, Some(format!("server-{}", config_id)));

        disconnect().unwrap();

        let info = get_connection_info().unwrap();
        assert_eq!(info.status, ConnectionStatus::Disconnected);
        assert_eq!(info.server_address, None);
    }

    #[test]
    #[serial]
    fn test_double_connect() {
        let config_id = "test-config";

        // 确保先断开
        let _ = disconnect();

        connect(config_id).unwrap();

        // 第二次连接应该失败
        assert!(connect(config_id).is_err());

        disconnect().unwrap();
    }

    #[test]
    #[serial]
    fn test_test_latency() {
        let config_id = "test-config";
        let latency = test_latency(config_id).unwrap();
        assert!(latency > 0);
    }

    #[test]
    #[serial]
    fn test_traffic_update() {
        // 确保先断开并重置状态
        let _ = disconnect();

        // 重置连接管理器状态
        {
            let mut manager = CONNECTION_MANAGER.blocking_write();
            manager.upload_bytes = 0;
            manager.download_bytes = 0;
        }

        connect("test-config").unwrap();

        update_traffic(1000, 2000);

        let info = get_connection_info().unwrap();
        assert_eq!(info.upload_bytes, 1000);
        assert_eq!(info.download_bytes, 2000);

        disconnect().unwrap();
    }
}
