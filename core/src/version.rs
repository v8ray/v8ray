//! Version information for V8Ray Core
//!
//! This module provides centralized version information that is used
//! throughout the application, including HTTP User-Agent strings.

/// Application version (from Cargo.toml)
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Application name
pub const APP_NAME: &str = "V8Ray";

/// User-Agent string for HTTP requests
pub fn user_agent() -> String {
    format!("{}/{}", APP_NAME, VERSION)
}

/// Full version string with additional information
pub fn full_version() -> String {
    format!(
        "{} {} ({})",
        APP_NAME,
        VERSION,
        env!("CARGO_PKG_DESCRIPTION")
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
        assert_eq!(VERSION, env!("CARGO_PKG_VERSION"));
    }

    #[test]
    fn test_user_agent() {
        let ua = user_agent();
        assert!(ua.starts_with("V8Ray/"));
        assert!(ua.contains(VERSION));
    }

    #[test]
    fn test_full_version() {
        let fv = full_version();
        assert!(fv.contains("V8Ray"));
        assert!(fv.contains(VERSION));
    }
}
