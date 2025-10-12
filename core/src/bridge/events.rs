//! 事件流 Bridge 模块

use anyhow::Result;
use futures::stream::{Stream, StreamExt};
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

use super::api::V8RayEvent;

lazy_static::lazy_static! {
    static ref EVENT_MANAGER: Arc<RwLock<EventManager>> = Arc::new(RwLock::new(EventManager::new()));
}

/// 事件管理器
struct EventManager {
    sender: broadcast::Sender<V8RayEvent>,
}

impl EventManager {
    fn new() -> Self {
        let (sender, _) = broadcast::channel(100);
        Self { sender }
    }

    fn subscribe(&self) -> broadcast::Receiver<V8RayEvent> {
        self.sender.subscribe()
    }

    #[allow(dead_code)]
    fn send(&self, event: V8RayEvent) -> Result<()> {
        // 忽略发送错误（没有接收者时）
        let _ = self.sender.send(event);
        Ok(())
    }
}

/// 初始化事件系统
pub fn init() -> Result<()> {
    tracing::info!("Initializing event system");
    Ok(())
}

/// 关闭事件系统
pub fn shutdown() -> Result<()> {
    tracing::info!("Event system shutdown");
    Ok(())
}

/// 创建事件流
pub fn create_event_stream() -> impl Stream<Item = V8RayEvent> {
    let receiver = {
        // 使用 try_read 避免在异步上下文中阻塞
        let manager = match EVENT_MANAGER.try_read() {
            Ok(m) => m,
            Err(_) => {
                // 如果无法获取锁,返回空流
                return futures::stream::empty().boxed();
            }
        };
        manager.subscribe()
    };

    futures::stream::unfold(receiver, |mut rx| async move {
        match rx.recv().await {
            Ok(event) => Some((event, rx)),
            Err(_) => None,
        }
    })
    .boxed()
}

/// 发送事件（内部使用）
#[allow(dead_code)]
pub(crate) fn send_event(event: V8RayEvent) -> Result<()> {
    let manager = EVENT_MANAGER
        .try_read()
        .map_err(|e| anyhow::anyhow!("Failed to acquire event manager lock: {}", e))?;
    manager.send(event)
}

#[cfg(test)]
mod tests {
    use super::super::api::{ConnectionStatus, TrafficStats};
    use super::*;
    use futures::StreamExt;
    use serial_test::serial;

    #[tokio::test]
    #[serial]
    async fn test_event_stream() {
        init().unwrap();

        let mut stream = Box::pin(create_event_stream());

        // 发送测试事件
        send_event(V8RayEvent::ConnectionStatusChanged {
            status: ConnectionStatus::Connected,
        })
        .unwrap();

        // 接收事件
        if let Some(event) = stream.next().await {
            match event {
                V8RayEvent::ConnectionStatusChanged { status } => {
                    assert_eq!(status, ConnectionStatus::Connected);
                }
                _ => panic!("Unexpected event type"),
            }
        }
    }

    #[tokio::test]
    #[serial]
    async fn test_multiple_events() {
        init().unwrap();

        let mut stream = Box::pin(create_event_stream());

        // 发送多个事件
        send_event(V8RayEvent::ConnectionStatusChanged {
            status: ConnectionStatus::Connecting,
        })
        .unwrap();

        send_event(V8RayEvent::TrafficStatsUpdated {
            stats: TrafficStats {
                upload_speed: 1000,
                download_speed: 2000,
                total_upload: 10000,
                total_download: 20000,
            },
        })
        .unwrap();

        send_event(V8RayEvent::Log {
            level: "info".to_string(),
            message: "Test log".to_string(),
        })
        .unwrap();

        // 接收事件
        let mut count = 0;
        while let Some(_event) = stream.next().await {
            count += 1;
            if count >= 3 {
                break;
            }
        }

        assert_eq!(count, 3);
    }

    #[test]
    #[serial]
    fn test_send_without_receiver() {
        init().unwrap();

        // 发送事件但没有接收者，应该不会出错
        let result = send_event(V8RayEvent::Error {
            message: "Test error".to_string(),
        });

        assert!(result.is_ok());
    }
}
