/// Build script for V8Ray Core
///
/// This script handles:
/// 1. Flutter Rust Bridge code generation setup
/// 2. Xray Core binary download and integration
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

fn main() {
    // 只在需要时重新运行
    println!("cargo:rerun-if-changed=src/bridge/api.rs");
    println!("cargo:rerun-if-changed=build.rs");

    // flutter_rust_bridge 代码生成
    // 注意：实际的代码生成需要使用 flutter_rust_bridge_codegen CLI 工具
    // 这里只是一个占位符，实际生成需要在命令行运行：
    // flutter_rust_bridge_codegen generate

    // 设置环境变量
    if let Ok(out_dir) = env::var("OUT_DIR") {
        println!("cargo:warning=OUT_DIR: {}", out_dir);
    }

    // Xray Core 集成
    // 生成下载信息，供 Flutter 构建脚本使用
    println!("cargo:warning=Generating Xray Core download information");

    if let Err(e) = generate_xray_download_info() {
        println!("cargo:warning=Failed to generate Xray download info: {}", e);
    }
}

/// Generate Xray Core download information for Flutter build script
fn generate_xray_download_info() -> Result<(), Box<dyn std::error::Error>> {
    // 获取目标平台信息
    let target_os = env::var("CARGO_CFG_TARGET_OS")?;
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH")?;

    println!(
        "cargo:warning=Target OS: {}, Arch: {}",
        target_os, target_arch
    );

    // 确定 Xray Core 的平台标识
    let (os_name, arch_name, extension) = match (target_os.as_str(), target_arch.as_str()) {
        ("windows", "x86_64") => ("windows", "64", ".zip"),
        ("windows", "x86") => ("windows", "32", ".zip"),
        ("windows", "aarch64") => ("windows", "arm64-v8a", ".zip"),
        ("linux", "x86_64") => ("linux", "64", ".zip"),
        ("linux", "aarch64") => ("linux", "arm64-v8a", ".zip"),
        ("macos", "x86_64") => ("macos", "64", ".zip"),
        ("macos", "aarch64") => ("macos", "arm64-v8a", ".zip"),
        _ => {
            println!(
                "cargo:warning=Unsupported platform: {}-{}",
                target_os, target_arch
            );
            return Err("Unsupported platform".into());
        }
    };

    // 创建 bin 目录
    let bin_dir = PathBuf::from("bin");
    fs::create_dir_all(&bin_dir)?;

    // 确定二进制文件名
    let binary_name = if target_os == "windows" {
        "xray.exe"
    } else {
        "xray"
    };

    // 构建下载 URL - 默认使用最新版本
    let xray_version = env::var("XRAY_VERSION").unwrap_or_else(|_| "latest".to_string());

    println!("cargo:warning=Xray Core version: {}", xray_version);
    println!("cargo:warning=Platform: {}-{}", os_name, arch_name);

    // 构建下载 URL
    let download_url = if xray_version == "latest" {
        format!(
            "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-{}-{}{}",
            os_name, arch_name, extension
        )
    } else {
        format!(
            "https://github.com/XTLS/Xray-core/releases/download/{}/Xray-{}-{}{}",
            xray_version, os_name, arch_name, extension
        )
    };

    // 创建下载信息文件，供 Flutter 构建脚本使用
    let info_file = bin_dir.join(".xray_download_info");
    let download_info = serde_json::json!({
        "url": download_url,
        "os": os_name,
        "arch": arch_name,
        "extension": extension,
        "binary_name": binary_name,
        "version": xray_version,
    });

    fs::write(&info_file, serde_json::to_string_pretty(&download_info)?)?;

    println!(
        "cargo:warning=Generated Xray download info at {:?}",
        info_file
    );
    println!("cargo:warning=Download URL: {}", download_url);

    Ok(())
}

// 设置可执行权限（仅 Unix 系统）
#[cfg(unix)]
#[allow(dead_code)]
fn set_executable_permission(path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    use std::os::unix::fs::PermissionsExt;

    let mut perms = fs::metadata(path)?.permissions();
    perms.set_mode(0o755);
    fs::set_permissions(path, perms)?;

    println!("cargo:warning=Set executable permission for {:?}", path);
    Ok(())
}
