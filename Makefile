# V8Ray Makefile
# 用于简化常用开发任务

.PHONY: help setup bridge clean test fmt lint run-core run-app build build-debug build-release download-xray

# 检测操作系统
ifeq ($(OS),Windows_NT)
    DETECTED_OS := windows
    FLUTTER_PLATFORM := windows
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        DETECTED_OS := linux
        FLUTTER_PLATFORM := linux
    endif
    ifeq ($(UNAME_S),Darwin)
        DETECTED_OS := macos
        FLUTTER_PLATFORM := macos
    endif
endif

# 默认目标
help:
	@echo "V8Ray Development Commands:"
	@echo ""
	@echo "Setup & Dependencies:"
	@echo "  make setup           - 安装所有依赖"
	@echo "  make download-xray   - 下载 Xray Core 二进制"
	@echo "  make bridge          - 生成 Flutter Rust Bridge 代码"
	@echo ""
	@echo "Build:"
	@echo "  make build           - 构建应用 (debug 模式)"
	@echo "  make build-debug     - 构建应用 (debug 模式)"
	@echo "  make build-release   - 构建应用 (release 模式)"
	@echo ""
	@echo "Development:"
	@echo "  make run-core        - 运行 Rust Core"
	@echo "  make run-app         - 运行 Flutter App"
	@echo "  make clean           - 清理构建产物"
	@echo ""
	@echo "Code Quality:"
	@echo "  make test            - 运行所有测试"
	@echo "  make fmt             - 格式化代码"
	@echo "  make lint            - 运行代码检查"
	@echo "  make ci              - 运行 CI 检查"

# 安装依赖
setup:
	@echo "=== Installing Dependencies ==="
	@echo ""
	@echo "Step 1: Installing Rust dependencies..."
	cd core && cargo build --lib
	@echo ""
	@echo "Step 2: Installing Flutter dependencies..."
	cd app && flutter pub get
	@echo ""
	@echo "Step 3: Installing flutter_rust_bridge_codegen..."
	cargo install flutter_rust_bridge_codegen
	@echo ""
	@echo "Step 4: Downloading Xray Core..."
	$(MAKE) download-xray
	@echo ""
	@echo "✓ Setup complete!"

# 下载 Xray Core (到构建输出目录)
download-xray:
	@echo "Downloading Xray Core binary to build output..."
	@if [ ! -f core/bin/.xray_download_info ]; then \
		echo "Generating download info..."; \
		cd core && cargo build --lib; \
	fi
	@cd scripts && dart download_xray.dart --build-mode debug
	@echo "✓ Xray Core downloaded successfully!"

# 强制重新下载 Xray Core
download-xray-force:
	@echo "Force downloading Xray Core binary..."
	@if [ ! -f core/bin/.xray_download_info ]; then \
		echo "Generating download info..."; \
		cd core && cargo build --lib; \
	fi
	@cd scripts && dart download_xray.dart --build-mode debug --force
	@echo "✓ Xray Core downloaded successfully!"

# 生成 Flutter Rust Bridge 代码
bridge:
	@echo "Generating Flutter Rust Bridge code..."
	flutter_rust_bridge_codegen generate
	@echo "Formatting generated code..."
	cd core && cargo fmt
	cd app && dart format lib/core/ffi/
	@echo "Bridge code generated successfully!"

# 构建应用 (debug 模式)
build: build-debug

build-debug:
	@echo "=== Building V8Ray (Debug) for $(DETECTED_OS) ==="
	@bash scripts/pre_build.sh debug
	@echo ""
	@echo "Step 2: Building Flutter application..."
	@cd app && flutter build $(FLUTTER_PLATFORM) --debug
	@echo ""
	@bash scripts/post_build.sh debug
	@echo ""
	@echo "✓ Build complete!"

# 构建应用 (release 模式)
build-release:
	@echo "=== Building V8Ray (Release) for $(DETECTED_OS) ==="
	@bash scripts/pre_build.sh release
	@echo ""
	@echo "Step 2: Building Flutter application..."
	@cd app && flutter build $(FLUTTER_PLATFORM) --release
	@echo ""
	@bash scripts/post_build.sh release
	@echo ""
	@echo "✓ Build complete!"

# 清理构建产物
clean:
	@echo "Cleaning Rust build..."
	cd core && cargo clean
	@echo "Cleaning Flutter build..."
	cd app && flutter clean
	@echo "Clean complete!"

# 深度清理 (包括下载的文件和生成的信息)
clean-all: clean
	@echo "Removing download info..."
	@rm -f core/bin/.xray_download_info
	@echo "Deep clean complete!"

# 运行测试
test:
	@echo "Running Rust tests..."
	cd core && cargo test
	@echo "Running Flutter tests..."
	cd app && flutter test
	@echo "All tests passed!"

# 格式化代码
fmt:
	@echo "Formatting Rust code..."
	cd core && cargo fmt --all
	@echo "Formatting Dart code..."
	cd app && dart format lib/
	@echo "Code formatted!"

# 代码检查
lint:
	@echo "Linting Rust code..."
	cd core && cargo clippy -- -W clippy::all
	@echo "Analyzing Flutter code..."
	cd app && flutter analyze --no-fatal-infos --no-fatal-warnings
	@echo "Lint complete!"

# 运行 Rust Core
run-core:
	cd core && cargo run

# 运行 Flutter App
run-app:
	@echo "Running Flutter app..."
	cd app && flutter run

# 运行 Flutter App (Linux)
run-linux:
	@echo "Running Flutter app on Linux..."
	cd app && flutter run -d linux

# 运行 CI 检查
ci:
	@echo "=== Running CI Checks ==="
	@echo ""
	@echo "Step 1: Formatting code..."
	@$(MAKE) fmt
	@echo ""
	@echo "Step 2: Linting code..."
	@$(MAKE) lint
	@echo ""
	@echo "Step 3: Running tests..."
	@$(MAKE) test
	@echo ""
	@echo "✓ All CI checks passed!"

# 预构建 (生成下载信息 + 下载 Xray)
pre-build:
	@bash scripts/pre_build.sh debug

pre-build-release:
	@bash scripts/pre_build.sh release

