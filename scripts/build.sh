#!/bin/bash
# Build script for V8Ray
# Usage: ./build.sh [debug|release] [--force-xray]

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 默认构建类型
BUILD_TYPE="${1:-debug}"
FORCE_XRAY="${2}"

echo "=== V8Ray Build Script ==="
echo "Build type: $BUILD_TYPE"

# 运行预构建脚本
echo ""
bash "$SCRIPT_DIR/pre_build.sh" "$BUILD_TYPE"

# 构建 Flutter 应用
echo ""
echo "Step 2: Building Flutter application..."
cd "$PROJECT_ROOT/app"

if [ "$BUILD_TYPE" == "release" ]; then
    echo "Building Flutter app in release mode..."
    flutter build linux --release
else
    echo "Building Flutter app in debug mode..."
    flutter build linux --debug
fi

# 运行后构建脚本（下载 Xray Core）
echo ""
bash "$SCRIPT_DIR/post_build.sh" "$BUILD_TYPE" "$FORCE_XRAY"

echo ""
echo "✓ Build completed successfully"
echo ""
echo "Executable location:"
if [ "$BUILD_TYPE" == "release" ]; then
    echo "  $PROJECT_ROOT/app/build/linux/x64/release/bundle/v8ray"
    echo "Xray Core location:"
    echo "  $PROJECT_ROOT/app/build/linux/x64/release/bundle/bin/xray"
else
    echo "  $PROJECT_ROOT/app/build/linux/x64/debug/bundle/v8ray"
    echo "Xray Core location:"
    echo "  $PROJECT_ROOT/app/build/linux/x64/debug/bundle/bin/xray"
fi

