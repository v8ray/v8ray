//! Cryptographic utilities for V8Ray Core
//!
//! This module provides encryption and decryption functions for sensitive data.

use aes_gcm::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use anyhow::{anyhow, Result};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};

/// Encrypt data using AES-256-GCM
///
/// # Arguments
/// * `data` - The data to encrypt
/// * `key` - The encryption key (must be 32 bytes)
///
/// # Returns
/// Base64-encoded encrypted data with nonce prepended
pub fn encrypt_aes256(data: &[u8], key: &[u8; 32]) -> Result<String> {
    let cipher = Aes256Gcm::new(key.into());

    // Generate a random nonce
    let nonce = Aes256Gcm::generate_nonce(&mut OsRng);

    // Encrypt the data
    let ciphertext = cipher
        .encrypt(&nonce, data)
        .map_err(|e| anyhow!("Encryption failed: {}", e))?;

    // Prepend nonce to ciphertext
    let mut result = nonce.to_vec();
    result.extend_from_slice(&ciphertext);

    // Encode as base64
    Ok(BASE64.encode(&result))
}

/// Decrypt data using AES-256-GCM
///
/// # Arguments
/// * `encrypted_data` - Base64-encoded encrypted data with nonce prepended
/// * `key` - The decryption key (must be 32 bytes)
///
/// # Returns
/// Decrypted data
pub fn decrypt_aes256(encrypted_data: &str, key: &[u8; 32]) -> Result<Vec<u8>> {
    // Decode from base64
    let data = BASE64
        .decode(encrypted_data)
        .map_err(|e| anyhow!("Base64 decode failed: {}", e))?;

    if data.len() < 12 {
        return Err(anyhow!("Invalid encrypted data: too short"));
    }

    // Extract nonce and ciphertext
    let (nonce_bytes, ciphertext) = data.split_at(12);

    // Convert nonce bytes to Nonce type (suppress deprecation warning)
    #[allow(deprecated)]
    let nonce = Nonce::from_slice(nonce_bytes);

    let cipher = Aes256Gcm::new(key.into());

    // Decrypt the data
    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| anyhow!("Decryption failed: {}", e))
}

/// Generate a random encryption key
pub fn generate_key() -> [u8; 32] {
    use aes_gcm::aead::rand_core::RngCore;
    let mut key = [0u8; 32];
    OsRng.fill_bytes(&mut key);
    key
}

/// Derive a key from a password using a simple hash
/// Note: This is a simple implementation. For production, use a proper KDF like PBKDF2 or Argon2
pub fn derive_key_from_password(password: &str) -> [u8; 32] {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};

    let mut hasher = DefaultHasher::new();
    password.hash(&mut hasher);
    let hash = hasher.finish();

    // Expand the hash to 32 bytes
    let mut key = [0u8; 32];
    for (i, chunk) in key.chunks_mut(8).enumerate() {
        let mut hasher = DefaultHasher::new();
        (hash + i as u64).hash(&mut hasher);
        let bytes = hasher.finish().to_le_bytes();
        chunk.copy_from_slice(&bytes);
    }

    key
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt() {
        let key = generate_key();
        let data = b"Hello, V8Ray!";

        let encrypted = encrypt_aes256(data, &key).unwrap();
        let decrypted = decrypt_aes256(&encrypted, &key).unwrap();

        assert_eq!(data.to_vec(), decrypted);
    }

    #[test]
    fn test_encrypt_decrypt_with_password() {
        let password = "my_secure_password";
        let key = derive_key_from_password(password);
        let data = b"Sensitive configuration data";

        let encrypted = encrypt_aes256(data, &key).unwrap();
        let decrypted = decrypt_aes256(&encrypted, &key).unwrap();

        assert_eq!(data.to_vec(), decrypted);
    }

    #[test]
    fn test_decrypt_invalid_data() {
        let key = generate_key();
        let result = decrypt_aes256("invalid_base64!", &key);
        assert!(result.is_err());
    }

    #[test]
    fn test_decrypt_wrong_key() {
        let key1 = generate_key();
        let key2 = generate_key();
        let data = b"Test data";

        let encrypted = encrypt_aes256(data, &key1).unwrap();
        let result = decrypt_aes256(&encrypted, &key2);
        assert!(result.is_err());
    }

    #[test]
    fn test_generate_key() {
        let key1 = generate_key();
        let key2 = generate_key();
        assert_ne!(key1, key2);
        assert_eq!(key1.len(), 32);
    }

    #[test]
    fn test_derive_key_consistency() {
        let password = "test_password";
        let key1 = derive_key_from_password(password);
        let key2 = derive_key_from_password(password);
        assert_eq!(key1, key2);
    }
}
