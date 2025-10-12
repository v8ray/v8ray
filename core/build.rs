/// Build script for V8Ray Core
///
/// This script handles:
/// 1. Flutter Rust Bridge code generation setup
/// 2. Xray Core binary download and integration
use std::env;
use std::fs;
use std::path::PathBuf;

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
    // 仅在 release 构建时下载 Xray Core
    let profile = env::var("PROFILE").unwrap_or_else(|_| "debug".to_string());

    if profile == "release" || env::var("DOWNLOAD_XRAY").is_ok() {
        println!("cargo:warning=Downloading Xray Core for {} build", profile);

        if let Err(e) = download_xray_core() {
            println!("cargo:warning=Failed to download Xray Core: {}", e);
            println!("cargo:warning=Application will try to find Xray Core at runtime");
        }
    } else {
        println!("cargo:warning=Skipping Xray Core download in debug build");
        println!("cargo:warning=Set DOWNLOAD_XRAY=1 to force download in debug build");
    }
}

/// Download Xray Core binary for the target platform
fn download_xray_core() -> Result<(), Box<dyn std::error::Error>> {
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

    let binary_path = bin_dir.join(binary_name);

    // 如果已存在，检查是否需要更新
    if binary_path.exists() {
        println!(
            "cargo:warning=Xray Core binary already exists at {:?}",
            binary_path
        );

        // 可以在这里添加版本检查逻辑
        // 如果不强制更新，则跳过下载
        if env::var("FORCE_UPDATE_XRAY").is_err() {
            println!("cargo:warning=Skipping download. Set FORCE_UPDATE_XRAY=1 to force update");
            return Ok(());
        }
    }

    // 构建下载 URL - 默认使用最新版本
    // 用户可以通过环境变量 XRAY_VERSION 指定特定版本，如 XRAY_VERSION=v1.8.7
    let xray_version = env::var("XRAY_VERSION").unwrap_or_else(|_| "latest".to_string());

    println!("cargo:warning=Xray Core version: {}", xray_version);
    println!("cargo:warning=Platform: {}-{}", os_name, arch_name);

    // 构建下载 URL
    // GitHub Releases 的 "latest" 会自动重定向到最新版本
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

    println!("cargo:warning=Download URL: {}", download_url);
    println!("cargo:warning=Xray Core will be downloaded at first run if not present");

    // 创建一个标记文件，包含下载信息，供运行时使用
    let marker_file = bin_dir.join(".xray_download_info");
    let download_info = format!("{}\n{}-{}", download_url, os_name, arch_name);
    fs::write(&marker_file, download_info)?;

    Ok(())
}

// 设置可执行权限（仅 Unix 系统）
#[cfg(unix)]
fn set_executable_permission(path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    use std::os::unix::fs::PermissionsExt;

    let mut perms = fs::metadata(path)?.permissions();
    perms.set_mode(0o755);
    fs::set_permissions(path, perms)?;

    println!("cargo:warning=Set executable permission for {:?}", path);
    Ok(())
}
