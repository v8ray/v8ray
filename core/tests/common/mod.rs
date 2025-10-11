//! Common test utilities and helpers for V8Ray Core tests

use std::sync::Once;
use tracing_subscriber::{fmt, EnvFilter};

static INIT: Once = Once::new();

/// Initialize test environment
/// This should be called at the beginning of each test that needs logging
pub fn init_test_env() {
    INIT.call_once(|| {
        // Initialize tracing for tests
        let filter = EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| EnvFilter::new("debug"));

        fmt()
            .with_env_filter(filter)
            .with_test_writer()
            .init();
    });
}

/// Create a temporary directory for test files
pub fn create_temp_dir() -> tempfile::TempDir {
    tempfile::tempdir().expect("Failed to create temporary directory")
}

/// Create a test configuration with default values
pub fn create_test_config() -> v8ray_core::config::Config {
    let mut config = v8ray_core::config::Config::default();
    config.proxy.http_port = 18080; // Use different ports for tests
    config.proxy.socks_port = 11080;
    config
}

/// Mock server for testing subscription updates
pub struct MockServer {
    pub port: u16,
    pub responses: std::collections::HashMap<String, String>,
}

impl MockServer {
    pub fn new() -> Self {
        Self {
            port: 0, // Will be assigned when started
            responses: std::collections::HashMap::new(),
        }
    }

    pub fn add_response(&mut self, path: String, response: String) {
        self.responses.insert(path, response);
    }

    // In a real implementation, this would start an HTTP server
    pub async fn start(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        // Mock implementation - just assign a port
        self.port = 18888;
        Ok(())
    }

    pub fn url(&self) -> String {
        format!("http://127.0.0.1:{}", self.port)
    }
}

/// Test helper for creating mock subscription data
pub fn create_mock_subscription_data() -> String {
    // This would typically be a valid subscription format
    // For now, we'll use a simple JSON format
    serde_json::json!({
        "servers": [
            {
                "name": "Test Server 1",
                "address": "127.0.0.1",
                "port": 8080,
                "protocol": "vmess",
                "settings": {
                    "id": "test-uuid-1",
                    "security": "auto"
                }
            },
            {
                "name": "Test Server 2", 
                "address": "127.0.0.1",
                "port": 8081,
                "protocol": "vless",
                "settings": {
                    "id": "test-uuid-2",
                    "encryption": "none"
                }
            }
        ]
    }).to_string()
}

/// Test helper for waiting with timeout
pub async fn wait_for_condition<F, Fut>(
    mut condition: F,
    timeout: std::time::Duration,
) -> Result<(), Box<dyn std::error::Error>>
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = bool>,
{
    let start = std::time::Instant::now();
    
    while start.elapsed() < timeout {
        if condition().await {
            return Ok(());
        }
        tokio::time::sleep(std::time::Duration::from_millis(10)).await;
    }
    
    Err("Condition not met within timeout".into())
}

/// Test helper for asserting async results
#[macro_export]
macro_rules! assert_async {
    ($condition:expr, $timeout:expr) => {
        {
            use std::time::{Duration, Instant};
            let start = Instant::now();
            let timeout = Duration::from_millis($timeout);
            
            loop {
                if $condition {
                    break;
                }
                
                if start.elapsed() > timeout {
                    panic!("Async assertion failed: condition not met within {}ms", $timeout);
                }
                
                tokio::time::sleep(Duration::from_millis(10)).await;
            }
        }
    };
}

/// Test helper for creating test data directories
pub fn setup_test_data_dir() -> tempfile::TempDir {
    let temp_dir = create_temp_dir();
    
    // Create subdirectories that might be needed
    std::fs::create_dir_all(temp_dir.path().join("config")).unwrap();
    std::fs::create_dir_all(temp_dir.path().join("logs")).unwrap();
    std::fs::create_dir_all(temp_dir.path().join("data")).unwrap();
    
    temp_dir
}

/// Test helper for cleaning up resources
pub struct TestCleanup {
    cleanup_fns: Vec<Box<dyn FnOnce() + Send>>,
}

impl TestCleanup {
    pub fn new() -> Self {
        Self {
            cleanup_fns: Vec::new(),
        }
    }

    pub fn add<F>(&mut self, cleanup_fn: F)
    where
        F: FnOnce() + Send + 'static,
    {
        self.cleanup_fns.push(Box::new(cleanup_fn));
    }

    pub fn cleanup(self) {
        for cleanup_fn in self.cleanup_fns {
            cleanup_fn();
        }
    }
}

impl Drop for TestCleanup {
    fn drop(&mut self) {
        // Cleanup any remaining functions
        while let Some(cleanup_fn) = self.cleanup_fns.pop() {
            cleanup_fn();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_init_test_env() {
        init_test_env();
        // Should not panic on multiple calls
        init_test_env();
    }

    #[test]
    fn test_create_temp_dir() {
        let temp_dir = create_temp_dir();
        assert!(temp_dir.path().exists());
    }

    #[test]
    fn test_create_test_config() {
        let config = create_test_config();
        assert_eq!(config.proxy.http_port, 18080);
        assert_eq!(config.proxy.socks_port, 11080);
    }

    #[tokio::test]
    async fn test_mock_server() {
        let mut server = MockServer::new();
        server.add_response("/test".to_string(), "test response".to_string());
        
        server.start().await.unwrap();
        assert!(server.port > 0);
        assert!(server.url().contains(&server.port.to_string()));
    }

    #[test]
    fn test_create_mock_subscription_data() {
        let data = create_mock_subscription_data();
        assert!(!data.is_empty());
        
        // Should be valid JSON
        let parsed: serde_json::Value = serde_json::from_str(&data).unwrap();
        assert!(parsed["servers"].is_array());
    }

    #[tokio::test]
    async fn test_wait_for_condition() {
        let mut counter = 0;
        
        let result = wait_for_condition(
            || {
                counter += 1;
                async move { counter >= 3 }
            },
            std::time::Duration::from_millis(100),
        ).await;
        
        assert!(result.is_ok());
        assert!(counter >= 3);
    }

    #[test]
    fn test_setup_test_data_dir() {
        let temp_dir = setup_test_data_dir();
        
        assert!(temp_dir.path().join("config").exists());
        assert!(temp_dir.path().join("logs").exists());
        assert!(temp_dir.path().join("data").exists());
    }

    #[test]
    fn test_cleanup() {
        let mut cleanup = TestCleanup::new();
        let mut cleaned = false;
        
        cleanup.add(move || {
            // This would normally be captured by reference,
            // but for testing we'll use a different approach
        });
        
        cleanup.cleanup();
        // Test passes if no panic occurs
    }
}
