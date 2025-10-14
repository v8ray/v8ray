#!/bin/bash
# Post-build script for V8Ray
# This script runs after Flutter build to download Xray Core to the bundle directory

set -e

echo "=== V8Ray Post-Build Script ==="

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project root: $PROJECT_ROOT"

# 获取构建模式
BUILD_MODE="${1:-debug}"

echo "Build mode: $BUILD_MODE"

# 下载 Xray Core 到构建输出目录
echo ""
echo "Downloading Xray Core to bundle directory..."
cd "$PROJECT_ROOT/scripts"

# 检查是否需要强制更新
FORCE_FLAG=""
if [ "$2" == "--force-xray" ]; then
    FORCE_FLAG="--force"
    echo "Force update Xray Core enabled"
fi

dart download_xray.dart --build-mode "$BUILD_MODE" $FORCE_FLAG

echo ""
echo "✓ Post-build completed successfully"

