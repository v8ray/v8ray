/// Build script for flutter_rust_bridge code generation
use std::env;

fn main() {
    // 只在需要时重新运行
    println!("cargo:rerun-if-changed=src/bridge/api.rs");

    // flutter_rust_bridge 代码生成
    // 注意：实际的代码生成需要使用 flutter_rust_bridge_codegen CLI 工具
    // 这里只是一个占位符，实际生成需要在命令行运行：
    // flutter_rust_bridge_codegen generate

    // 设置环境变量
    if let Ok(out_dir) = env::var("OUT_DIR") {
        println!("cargo:warning=OUT_DIR: {}", out_dir);
    }
}
