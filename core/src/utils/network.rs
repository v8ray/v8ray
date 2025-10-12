//! Network utilities for V8Ray Core
//!
//! This module provides network-related utility functions.

use anyhow::{anyhow, Result};
use std::net::{IpAddr, SocketAddr};

/// Check if a string is a valid IP address
pub fn is_valid_ip(ip: &str) -> bool {
    ip.parse::<IpAddr>().is_ok()
}

/// Check if a port number is valid
pub fn is_valid_port(port: u16) -> bool {
    port > 0
}

/// Parse an address string into host and port
///
/// # Arguments
/// * `address` - Address string in format "host:port"
///
/// # Returns
/// Tuple of (host, port)
pub fn parse_address(address: &str) -> Result<(String, u16)> {
    let parts: Vec<&str> = address.rsplitn(2, ':').collect();

    if parts.len() != 2 {
        return Err(anyhow!("Invalid address format: {}", address));
    }

    let port = parts[0]
        .parse::<u16>()
        .map_err(|_| anyhow!("Invalid port: {}", parts[0]))?;

    let host = parts[1].to_string();

    if host.is_empty() {
        return Err(anyhow!("Empty host"));
    }

    Ok((host, port))
}

/// Parse a socket address
pub fn parse_socket_addr(address: &str) -> Result<SocketAddr> {
    address
        .parse::<SocketAddr>()
        .map_err(|e| anyhow!("Invalid socket address: {}", e))
}

/// Check if a hostname is valid
pub fn is_valid_hostname(hostname: &str) -> bool {
    if hostname.is_empty() || hostname.len() > 253 {
        return false;
    }

    // Check each label
    for label in hostname.split('.') {
        if label.is_empty() || label.len() > 63 {
            return false;
        }

        // Label must start and end with alphanumeric
        if !label.chars().next().unwrap().is_alphanumeric()
            || !label.chars().last().unwrap().is_alphanumeric()
        {
            return false;
        }

        // Label can only contain alphanumeric and hyphens
        if !label.chars().all(|c| c.is_alphanumeric() || c == '-') {
            return false;
        }
    }

    true
}

/// Normalize a URL by removing trailing slashes and ensuring proper scheme
pub fn normalize_url(url: &str) -> String {
    let mut normalized = url.trim().to_string();

    // Remove trailing slashes
    while normalized.ends_with('/') {
        normalized.pop();
    }

    // Ensure scheme
    if !normalized.starts_with("http://") && !normalized.starts_with("https://") {
        normalized = format!("https://{}", normalized);
    }

    normalized
}

/// Extract domain from URL
pub fn extract_domain(url: &str) -> Result<String> {
    let url = url::Url::parse(url).map_err(|e| anyhow!("Invalid URL: {}", e))?;

    url.host_str()
        .map(|s| s.to_string())
        .ok_or_else(|| anyhow!("No host in URL"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_valid_ip() {
        assert!(is_valid_ip("127.0.0.1"));
        assert!(is_valid_ip("192.168.1.1"));
        assert!(is_valid_ip("::1"));
        assert!(is_valid_ip("2001:db8::1"));
        assert!(!is_valid_ip("invalid"));
        assert!(!is_valid_ip("256.1.1.1"));
    }

    #[test]
    fn test_is_valid_port() {
        assert!(is_valid_port(80));
        assert!(is_valid_port(443));
        assert!(is_valid_port(8080));
        assert!(is_valid_port(65535));
        assert!(!is_valid_port(0));
    }

    #[test]
    fn test_parse_address() {
        let (host, port) = parse_address("example.com:8080").unwrap();
        assert_eq!(host, "example.com");
        assert_eq!(port, 8080);

        let (host, port) = parse_address("192.168.1.1:443").unwrap();
        assert_eq!(host, "192.168.1.1");
        assert_eq!(port, 443);

        assert!(parse_address("invalid").is_err());
        assert!(parse_address(":8080").is_err());
    }

    #[test]
    fn test_is_valid_hostname() {
        assert!(is_valid_hostname("example.com"));
        assert!(is_valid_hostname("sub.example.com"));
        assert!(is_valid_hostname("my-server.example.com"));
        assert!(!is_valid_hostname(""));
        assert!(!is_valid_hostname("-invalid.com"));
        assert!(!is_valid_hostname("invalid-.com"));
    }

    #[test]
    fn test_normalize_url() {
        assert_eq!(normalize_url("example.com"), "https://example.com");
        assert_eq!(normalize_url("http://example.com/"), "http://example.com");
        assert_eq!(
            normalize_url("https://example.com///"),
            "https://example.com"
        );
    }

    #[test]
    fn test_extract_domain() {
        assert_eq!(
            extract_domain("https://example.com/path").unwrap(),
            "example.com"
        );
        assert_eq!(
            extract_domain("http://sub.example.com:8080").unwrap(),
            "sub.example.com"
        );
        assert!(extract_domain("invalid").is_err());
    }
}
