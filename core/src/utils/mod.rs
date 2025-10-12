//! Utility modules for V8Ray Core
//!
//! This module contains various utility functions and helpers used throughout
//! the V8Ray core library.

pub mod logger;
pub mod crypto;
pub mod network;

pub use logger::{init_logger, LogConfig, LogLevel};
pub use crypto::{encrypt_aes256, decrypt_aes256};
pub use network::{is_valid_ip, is_valid_port, parse_address};

