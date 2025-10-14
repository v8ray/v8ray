#!/bin/bash
# Pre-build script for V8Ray
# This script runs before Flutter build to prepare dependencies

set -e

echo "=== V8Ray Pre-Build Script ==="

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project root: $PROJECT_ROOT"

# 1. 构建 Rust Core (生成下载信息)
echo ""
echo "Step 1: Building Rust Core..."
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

