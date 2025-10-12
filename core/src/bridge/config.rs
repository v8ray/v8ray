//! 配置管理 Bridge 模块

use anyhow::{anyhow, Result};
use std::sync::Arc;
use tokio::sync::RwLock;

use super::api::ConfigInfo;

lazy_static::lazy_static! {
    static ref CONFIG_MANAGER: Arc<RwLock<ConfigManager>> = Arc::new(RwLock::new(ConfigManager::new()));
}

/// 配置管理器
struct ConfigManager {
    configs: Vec<ConfigInfo>,
}

impl ConfigManager {
    fn new() -> Self {
        Self {
            configs: Vec::new(),
        }
    }

    fn load(&self, id: &str) -> Result<ConfigInfo> {
        self.configs
            .iter()
            .find(|c| c.id == id)
            .cloned()
            .ok_or_else(|| anyhow!("Config not found: {}", id))
    }

    fn save(&mut self, config: ConfigInfo) -> Result<()> {
        // 检查是否已存在
        if let Some(pos) = self.configs.iter().position(|c| c.id == config.id) {
            // 更新现有配置
            self.configs[pos] = config;
        } else {
            // 添加新配置
            self.configs.push(config);
        }
        Ok(())
    }

    fn delete(&mut self, id: &str) -> Result<()> {
        let pos = self
            .configs
            .iter()
            .position(|c| c.id == id)
            .ok_or_else(|| anyhow!("Config not found: {}", id))?;
        self.configs.remove(pos);
        Ok(())
    }

    fn list(&self) -> Vec<ConfigInfo> {
        self.configs.clone()
    }

    fn validate(&self, config: &ConfigInfo) -> Result<bool> {
        // 基本验证
        if config.name.is_empty() {
            return Ok(false);
        }
        if config.server.is_empty() {
            return Ok(false);
        }
        if config.port == 0 {
            return Ok(false);
        }
        if config.protocol.is_empty() {
            return Ok(false);
        }
        Ok(true)
    }
}

/// 初始化配置管理器
pub fn init() -> Result<()> {
    tracing::info!("Initializing config manager");
    Ok(())
}

/// 加载配置
pub fn load_config(config_id: &str) -> Result<ConfigInfo> {
    let manager = CONFIG_MANAGER.blocking_read();
    manager.load(config_id)
}

/// 保存配置
pub fn save_config(config: ConfigInfo) -> Result<()> {
    let mut manager = CONFIG_MANAGER.blocking_write();
    manager.save(config)
}

/// 删除配置
pub fn delete_config(config_id: &str) -> Result<()> {
    let mut manager = CONFIG_MANAGER.blocking_write();
    manager.delete(config_id)
}

/// 列出所有配置
pub fn list_configs() -> Result<Vec<ConfigInfo>> {
    let manager = CONFIG_MANAGER.blocking_read();
    Ok(manager.list())
}

/// 验证配置
pub fn validate_config(config: ConfigInfo) -> Result<bool> {
    let manager = CONFIG_MANAGER.blocking_read();
    manager.validate(&config)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use serial_test::serial;

    fn create_test_config() -> ConfigInfo {
        ConfigInfo {
            id: "test-1".to_string(),
            name: "Test Config".to_string(),
            server: "example.com".to_string(),
            port: 443,
            protocol: "vmess".to_string(),
            enabled: true,
            created_at: Utc::now().timestamp(),
            updated_at: Utc::now().timestamp(),
        }
    }

    #[test]
    #[serial]
    fn test_save_and_load_config() {
        let config = create_test_config();
        save_config(config.clone()).unwrap();

        let loaded = load_config(&config.id).unwrap();
        assert_eq!(loaded.id, config.id);
        assert_eq!(loaded.name, config.name);
    }

    #[test]
    #[serial]
    fn test_list_configs() {
        let config1 = create_test_config();
        let mut config2 = create_test_config();
        config2.id = "test-2".to_string();

        save_config(config1).unwrap();
        save_config(config2).unwrap();

        let configs = list_configs().unwrap();
        assert!(configs.len() >= 2);
    }

    #[test]
    #[serial]
    fn test_delete_config() {
        let config = create_test_config();
        save_config(config.clone()).unwrap();

        delete_config(&config.id).unwrap();

        assert!(load_config(&config.id).is_err());
    }

    #[test]
    #[serial]
    fn test_validate_config() {
        let config = create_test_config();
        assert!(validate_config(config).unwrap());

        let mut invalid_config = create_test_config();
        invalid_config.name = String::new();
        assert!(!validate_config(invalid_config).unwrap());
    }
}
