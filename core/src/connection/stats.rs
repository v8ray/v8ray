//! Connection statistics collection module
//!
//! This module provides functionality for collecting and tracking connection statistics
//! including traffic data, speed measurements, and historical data.

use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;
use tracing::{debug, info};

/// Traffic statistics snapshot
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrafficSnapshot {
    /// Timestamp of the snapshot
    pub timestamp: chrono::DateTime<chrono::Utc>,
    /// Total bytes uploaded
    pub upload_bytes: u64,
    /// Total bytes downloaded
    pub download_bytes: u64,
    /// Upload speed in bytes per second
    pub upload_speed: u64,
    /// Download speed in bytes per second
    pub download_speed: u64,
}

/// Traffic statistics collector
pub struct TrafficStatsCollector {
    /// Current upload bytes
    upload_bytes: Arc<RwLock<u64>>,
    /// Current download bytes
    download_bytes: Arc<RwLock<u64>>,
    /// Historical snapshots (limited to last N snapshots)
    snapshots: Arc<RwLock<VecDeque<TrafficSnapshot>>>,
    /// Maximum number of snapshots to keep
    max_snapshots: usize,
    /// Last snapshot for speed calculation
    last_snapshot: Arc<RwLock<Option<TrafficSnapshot>>>,
}

impl Default for TrafficStatsCollector {
    fn default() -> Self {
        Self::new(100)
    }
}

impl TrafficStatsCollector {
    /// Create a new traffic stats collector
    pub fn new(max_snapshots: usize) -> Self {
        Self {
            upload_bytes: Arc::new(RwLock::new(0)),
            download_bytes: Arc::new(RwLock::new(0)),
            snapshots: Arc::new(RwLock::new(VecDeque::with_capacity(max_snapshots))),
            max_snapshots,
            last_snapshot: Arc::new(RwLock::new(None)),
        }
    }

    /// Update traffic statistics
    pub async fn update_traffic(&self, upload: u64, download: u64) {
        let mut upload_bytes = self.upload_bytes.write().await;
        let mut download_bytes = self.download_bytes.write().await;

        *upload_bytes += upload;
        *download_bytes += download;

        debug!(
            "Traffic updated: +{} up, +{} down (total: {} up, {} down)",
            upload, download, *upload_bytes, *download_bytes
        );
    }

    /// Get current traffic totals
    pub async fn get_totals(&self) -> (u64, u64) {
        let upload = *self.upload_bytes.read().await;
        let download = *self.download_bytes.read().await;
        (upload, download)
    }

    /// Reset traffic statistics
    pub async fn reset(&self) {
        let mut upload_bytes = self.upload_bytes.write().await;
        let mut download_bytes = self.download_bytes.write().await;
        let mut snapshots = self.snapshots.write().await;
        let mut last_snapshot = self.last_snapshot.write().await;

        *upload_bytes = 0;
        *download_bytes = 0;
        snapshots.clear();
        *last_snapshot = None;

        info!("Traffic statistics reset");
    }

    /// Take a snapshot of current statistics
    pub async fn take_snapshot(&self) -> TrafficSnapshot {
        let (upload, download) = self.get_totals().await;
        let now = chrono::Utc::now();

        // Calculate speeds based on last snapshot
        let (upload_speed, download_speed) = {
            let last = self.last_snapshot.read().await;
            if let Some(ref last_snap) = *last {
                let time_diff = (now - last_snap.timestamp).num_seconds() as f64;
                if time_diff > 0.0 {
                    let upload_diff = upload.saturating_sub(last_snap.upload_bytes);
                    let download_diff = download.saturating_sub(last_snap.download_bytes);
                    (
                        (upload_diff as f64 / time_diff) as u64,
                        (download_diff as f64 / time_diff) as u64,
                    )
                } else {
                    (0, 0)
                }
            } else {
                (0, 0)
            }
        };

        let snapshot = TrafficSnapshot {
            timestamp: now,
            upload_bytes: upload,
            download_bytes: download,
            upload_speed,
            download_speed,
        };

        // Update last snapshot
        {
            let mut last = self.last_snapshot.write().await;
            *last = Some(snapshot.clone());
        }

        // Add to snapshots history
        {
            let mut snapshots = self.snapshots.write().await;
            snapshots.push_back(snapshot.clone());

            // Remove old snapshots if exceeding max
            while snapshots.len() > self.max_snapshots {
                snapshots.pop_front();
            }
        }

        debug!(
            "Snapshot taken: {} up, {} down, {} up/s, {} down/s",
            upload, download, upload_speed, download_speed
        );

        snapshot
    }

    /// Get all historical snapshots
    pub async fn get_snapshots(&self) -> Vec<TrafficSnapshot> {
        self.snapshots.read().await.iter().cloned().collect()
    }

    /// Get latest snapshot
    pub async fn get_latest_snapshot(&self) -> Option<TrafficSnapshot> {
        self.snapshots.read().await.back().cloned()
    }

    /// Get current speeds (from last snapshot)
    pub async fn get_current_speeds(&self) -> (u64, u64) {
        let last = self.last_snapshot.read().await;
        if let Some(ref snap) = *last {
            (snap.upload_speed, snap.download_speed)
        } else {
            (0, 0)
        }
    }

    /// Get average speeds over all snapshots
    pub async fn get_average_speeds(&self) -> (u64, u64) {
        let snapshots = self.snapshots.read().await;
        if snapshots.is_empty() {
            return (0, 0);
        }

        let total_upload_speed: u64 = snapshots.iter().map(|s| s.upload_speed).sum();
        let total_download_speed: u64 = snapshots.iter().map(|s| s.download_speed).sum();
        let count = snapshots.len() as u64;

        (total_upload_speed / count, total_download_speed / count)
    }

    /// Get peak speeds from snapshots
    pub async fn get_peak_speeds(&self) -> (u64, u64) {
        let snapshots = self.snapshots.read().await;
        if snapshots.is_empty() {
            return (0, 0);
        }

        let max_upload = snapshots.iter().map(|s| s.upload_speed).max().unwrap_or(0);
        let max_download = snapshots
            .iter()
            .map(|s| s.download_speed)
            .max()
            .unwrap_or(0);

        (max_upload, max_download)
    }

    /// Start automatic snapshot collection
    pub async fn start_auto_snapshot(&self, interval: Duration) {
        let collector = Self {
            upload_bytes: Arc::clone(&self.upload_bytes),
            download_bytes: Arc::clone(&self.download_bytes),
            snapshots: Arc::clone(&self.snapshots),
            max_snapshots: self.max_snapshots,
            last_snapshot: Arc::clone(&self.last_snapshot),
        };

        tokio::spawn(async move {
            let mut interval_timer = tokio::time::interval(interval);
            loop {
                interval_timer.tick().await;
                collector.take_snapshot().await;
            }
        });

        info!("Auto-snapshot started with interval: {:?}", interval);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_traffic_stats_collector() {
        let collector = TrafficStatsCollector::new(10);

        // Initial state
        let (up, down) = collector.get_totals().await;
        assert_eq!(up, 0);
        assert_eq!(down, 0);

        // Update traffic
        collector.update_traffic(1024, 2048).await;
        let (up, down) = collector.get_totals().await;
        assert_eq!(up, 1024);
        assert_eq!(down, 2048);

        // Update again
        collector.update_traffic(512, 1024).await;
        let (up, down) = collector.get_totals().await;
        assert_eq!(up, 1536);
        assert_eq!(down, 3072);
    }

    #[tokio::test]
    async fn test_snapshot() {
        let collector = TrafficStatsCollector::new(10);

        collector.update_traffic(1000, 2000).await;
        let snapshot = collector.take_snapshot().await;

        assert_eq!(snapshot.upload_bytes, 1000);
        assert_eq!(snapshot.download_bytes, 2000);
    }

    #[tokio::test]
    async fn test_snapshot_history() {
        let collector = TrafficStatsCollector::new(3);

        // Take multiple snapshots
        for i in 1..=5 {
            collector.update_traffic(100, 200).await;
            tokio::time::sleep(Duration::from_millis(10)).await;
            collector.take_snapshot().await;
        }

        let snapshots = collector.get_snapshots().await;
        // Should only keep last 3 snapshots
        assert_eq!(snapshots.len(), 3);
    }

    #[tokio::test]
    async fn test_reset() {
        let collector = TrafficStatsCollector::new(10);

        collector.update_traffic(1000, 2000).await;
        collector.take_snapshot().await;

        collector.reset().await;

        let (up, down) = collector.get_totals().await;
        assert_eq!(up, 0);
        assert_eq!(down, 0);

        let snapshots = collector.get_snapshots().await;
        assert_eq!(snapshots.len(), 0);
    }

    #[tokio::test]
    async fn test_speeds() {
        let collector = TrafficStatsCollector::new(10);

        // First snapshot
        collector.update_traffic(1000, 2000).await;
        collector.take_snapshot().await;

        // Wait at least 1 second for accurate speed calculation
        tokio::time::sleep(Duration::from_secs(1)).await;

        // Second snapshot with more traffic
        collector.update_traffic(1000, 2000).await;
        let snapshot = collector.take_snapshot().await;

        // Speed should be calculated (approximately 1000 bytes/sec)
        // Allow some margin for timing variations
        assert!(snapshot.upload_speed >= 900 && snapshot.upload_speed <= 1100);
        assert!(snapshot.download_speed >= 1900 && snapshot.download_speed <= 2100);
    }
}
