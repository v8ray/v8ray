//! Logging utilities for V8Ray Core
//!
//! This module provides logging functionality using the `tracing` crate.
//! It supports multiple log levels and file output.

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tracing::Level;
use tracing_appender::rolling::{RollingFileAppender, Rotation};
use tracing_subscriber::{fmt, layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

/// Log level configuration
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum LogLevel {
    /// Trace level - most verbose
    Trace,
    /// Debug level
    Debug,
    /// Info level - default
    Info,
    /// Warn level
    Warn,
    /// Error level - least verbose
    Error,
}

impl From<LogLevel> for Level {
    fn from(level: LogLevel) -> Self {
        match level {
            LogLevel::Trace => Level::TRACE,
            LogLevel::Debug => Level::DEBUG,
            LogLevel::Info => Level::INFO,
            LogLevel::Warn => Level::WARN,
            LogLevel::Error => Level::ERROR,
        }
    }
}

impl std::fmt::Display for LogLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LogLevel::Trace => write!(f, "trace"),
            LogLevel::Debug => write!(f, "debug"),
            LogLevel::Info => write!(f, "info"),
            LogLevel::Warn => write!(f, "warn"),
            LogLevel::Error => write!(f, "error"),
        }
    }
}

/// Logger configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogConfig {
    /// Log level
    pub level: LogLevel,
    /// Enable console output
    pub console: bool,
    /// Enable file output
    pub file: bool,
    /// Log file directory
    pub file_dir: Option<PathBuf>,
    /// Log file name prefix
    pub file_prefix: String,
    /// Log file rotation
    pub rotation: LogRotation,
}

/// Log file rotation strategy
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum LogRotation {
    /// Never rotate
    Never,
    /// Rotate daily
    Daily,
    /// Rotate hourly
    Hourly,
    /// Rotate when file size exceeds limit
    Size(u64),
}

impl From<LogRotation> for Rotation {
    fn from(rotation: LogRotation) -> Self {
        match rotation {
            LogRotation::Never => Rotation::NEVER,
            LogRotation::Daily => Rotation::DAILY,
            LogRotation::Hourly => Rotation::HOURLY,
            LogRotation::Size(_) => Rotation::DAILY, // tracing_appender doesn't support size-based rotation
        }
    }
}

impl Default for LogConfig {
    fn default() -> Self {
        Self {
            level: LogLevel::Info, // 使用 Info 级别，在 release 模式下也能显示
            console: true,
            file: false,
            file_dir: None,
            file_prefix: "v8ray".to_string(),
            rotation: LogRotation::Daily,
        }
    }
}

/// Initialize the logger with the given configuration
pub fn init_logger(config: &LogConfig) -> Result<()> {
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(config.level.to_string()));

    let registry = tracing_subscriber::registry().with(filter);

    if config.console && config.file {
        // Both console and file output
        let console_layer = fmt::layer().with_writer(std::io::stdout);

        let file_dir = config
            .file_dir
            .clone()
            .unwrap_or_else(|| PathBuf::from("logs"));

        std::fs::create_dir_all(&file_dir)?;

        let file_appender =
            RollingFileAppender::new(config.rotation.into(), file_dir, &config.file_prefix);
        let file_layer = fmt::layer().with_writer(file_appender).with_ansi(false);

        registry.with(console_layer).with(file_layer).init();
    } else if config.console {
        // Console output only
        let console_layer = fmt::layer().with_writer(std::io::stdout);
        registry.with(console_layer).init();
    } else if config.file {
        // File output only
        let file_dir = config
            .file_dir
            .clone()
            .unwrap_or_else(|| PathBuf::from("logs"));

        std::fs::create_dir_all(&file_dir)?;

        let file_appender =
            RollingFileAppender::new(config.rotation.into(), file_dir, &config.file_prefix);
        let file_layer = fmt::layer().with_writer(file_appender).with_ansi(false);

        registry.with(file_layer).init();
    } else {
        // No output (shouldn't happen, but default to console)
        let console_layer = fmt::layer().with_writer(std::io::stdout);
        registry.with(console_layer).init();
    }

    tracing::info!("Logger initialized with level: {}", config.level);
    Ok(())
}

/// Initialize a simple logger with default settings
pub fn init_simple_logger() -> Result<()> {
    init_logger(&LogConfig::default())
}

/// Initialize a logger with custom level
pub fn init_logger_with_level(level: LogLevel) -> Result<()> {
    let config = LogConfig {
        level,
        ..Default::default()
    };
    init_logger(&config)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_log_level_conversion() {
        assert_eq!(Level::from(LogLevel::Info), Level::INFO);
        assert_eq!(Level::from(LogLevel::Debug), Level::DEBUG);
        assert_eq!(Level::from(LogLevel::Error), Level::ERROR);
    }

    #[test]
    fn test_log_level_display() {
        assert_eq!(LogLevel::Info.to_string(), "info");
        assert_eq!(LogLevel::Debug.to_string(), "debug");
        assert_eq!(LogLevel::Error.to_string(), "error");
    }

    #[test]
    fn test_default_log_config() {
        let config = LogConfig::default();
        assert_eq!(config.level, LogLevel::Info);
        assert!(config.console);
        assert!(!config.file);
    }

    #[test]
    fn test_log_rotation_conversion() {
        let rotation: Rotation = LogRotation::Daily.into();
        assert_eq!(rotation, Rotation::DAILY);
    }
}
