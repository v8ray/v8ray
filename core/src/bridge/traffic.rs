//! 流量统计 Bridge 模块

use anyhow::Result;
use std::sync::Arc;
use std::time::Instant;
use tokio::sync::RwLock;

use super::api::TrafficStats;

lazy_static::lazy_static! {
    static ref TRAFFIC_MANAGER: Arc<RwLock<TrafficManager>> = Arc::new(RwLock::new(TrafficManager::new()));
}

/// 流量管理器
struct TrafficManager {
    total_upload: u64,
    total_download: u64,
    last_upload: u64,
    last_download: u64,
    last_update: Instant,
}

impl TrafficManager {
    fn new() -> Self {
        Self {
            total_upload: 0,
            total_download: 0,
            last_upload: 0,
            last_download: 0,
            last_update: Instant::now(),
        }
    }

    fn get_stats(&mut self) -> TrafficStats {
        let now = Instant::now();
        let elapsed = now.duration_since(self.last_update).as_secs_f64();

        let upload_speed = if elapsed > 0.0 {
            ((self.total_upload - self.last_upload) as f64 / elapsed) as u64
        } else {
            0
        };

        let download_speed = if elapsed > 0.0 {
            ((self.total_download - self.last_download) as f64 / elapsed) as u64
        } else {
            0
        };

        self.last_upload = self.total_upload;
        self.last_download = self.total_download;
        self.last_update = now;

        TrafficStats {
            upload_speed,
            download_speed,
            total_upload: self.total_upload,
            total_download: self.total_download,
        }
    }

    fn reset(&mut self) {
        self.total_upload = 0;
        self.total_download = 0;
        self.last_upload = 0;
        self.last_download = 0;
        self.last_update = Instant::now();
    }

    #[allow(dead_code)]
    fn update(&mut self, upload: u64, download: u64) {
        self.total_upload += upload;
        self.total_download += download;
    }
}

/// 获取流量统计
pub fn get_traffic_stats() -> Result<TrafficStats> {
    let mut manager = TRAFFIC_MANAGER.blocking_write();
    Ok(manager.get_stats())
}

/// 重置流量统计
pub fn reset_traffic_stats() -> Result<()> {
    let mut manager = TRAFFIC_MANAGER.blocking_write();
    manager.reset();
    tracing::info!("Traffic stats reset");
    Ok(())
}

/// 更新流量（内部使用）
#[allow(dead_code)]
pub(crate) fn update_traffic(upload: u64, download: u64) {
    if let Ok(mut manager) = TRAFFIC_MANAGER.try_write() {
        manager.update(upload, download);
        // 同时更新连接管理器的流量
        super::connection::update_traffic(upload, download);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use std::time::Duration;

    #[test]
    #[serial]
    fn test_get_stats() {
        reset_traffic_stats().unwrap();

        let stats = get_traffic_stats().unwrap();
        assert_eq!(stats.total_upload, 0);
        assert_eq!(stats.total_download, 0);
    }

    #[test]
    #[serial]
    fn test_update_traffic() {
        reset_traffic_stats().unwrap();

        update_traffic(1000, 2000);

        let stats = get_traffic_stats().unwrap();
        assert_eq!(stats.total_upload, 1000);
        assert_eq!(stats.total_download, 2000);
    }

    #[test]
    #[serial]
    fn test_reset() {
        update_traffic(1000, 2000);

        reset_traffic_stats().unwrap();

        let stats = get_traffic_stats().unwrap();
        assert_eq!(stats.total_upload, 0);
        assert_eq!(stats.total_download, 0);
    }

    #[test]
    #[serial]
    fn test_speed_calculation() {
        reset_traffic_stats().unwrap();

        // 第一次更新
        update_traffic(1000, 2000);
        let _stats1 = get_traffic_stats().unwrap();

        // 等待一段时间
        std::thread::sleep(Duration::from_millis(100));

        // 第二次更新
        update_traffic(1000, 2000);
        let stats2 = get_traffic_stats().unwrap();

        // 速度应该大于 0
        assert!(stats2.upload_speed > 0 || stats2.download_speed > 0);
    }
}
