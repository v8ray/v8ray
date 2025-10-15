#!/bin/bash
# Pre-build script for V8Ray
# This script runs before Flutter build to prepare dependencies

set -e

echo "=== V8Ray Pre-Build Script ==="

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project root: $PROJECT_ROOT"

# 1. 检查并生成 Flutter Rust Bridge 代码（如果需要）
echo ""
echo "Step 1: Checking Flutter Rust Bridge code..."
if [ ! -f "$PROJECT_ROOT/core/src/frb_generated.rs" ] || [ ! -f "$PROJECT_ROOT/app/lib/core/ffi/frb_generated.dart" ]; then
    echo "FRB generated code not found, generating..."
    cd "$PROJECT_ROOT"
    flutter_rust_bridge_codegen generate
    echo "✓ FRB code generated"
else
    echo "✓ FRB code already exists"
fi

# 2. 构建 Rust Core (生成下载信息)
echo ""
echo "Step 2: Building Rust Core..."
cd "$PROJECT_ROOT/core"

# 根据构建类型选择 profile
BUILD_MODE="${1:-debug}"
if [ "$BUILD_MODE" == "release" ]; then
    echo "Building in release mode..."
    cargo build --release --lib
else
    echo "Building in debug mode..."
    cargo build --lib
fi

echo ""
echo "✓ Pre-build completed successfully"
echo ""
echo "Note: Xray Core will be downloaded after Flutter build to the bundle directory"
echo ""
echo "If you encounter 'frb_get_rust_content_hash' error, run: make bridge"

