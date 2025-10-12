# V8Ray Makefile
# 用于简化常用开发任务

.PHONY: help setup bridge clean test fmt lint run-core run-app

# 默认目标
help:
	@echo "V8Ray Development Commands:"
	@echo "  make setup      - 安装所有依赖"
	@echo "  make bridge     - 生成 Flutter Rust Bridge 代码"
	@echo "  make clean      - 清理构建产物"
	@echo "  make test       - 运行所有测试"
	@echo "  make fmt        - 格式化代码"
	@echo "  make lint       - 运行代码检查"
	@echo "  make run-core   - 运行 Rust Core"
	@echo "  make run-app    - 运行 Flutter App"

# 安装依赖
setup:
	@echo "Installing Rust dependencies..."
	cd core && cargo build
	@echo "Installing Flutter dependencies..."
	cd app && flutter pub get
	@echo "Installing flutter_rust_bridge_codegen..."
	cargo install flutter_rust_bridge_codegen
	@echo "Setup complete!"

# 生成 Flutter Rust Bridge 代码
bridge:
	@echo "Generating Flutter Rust Bridge code..."
	flutter_rust_bridge_codegen generate
	@echo "Formatting generated code..."
	cd core && cargo fmt
	cd app && dart format lib/core/ffi/
	@echo "Bridge code generated successfully!"

# 清理构建产物
clean:
	@echo "Cleaning Rust build..."
	cd core && cargo clean
	@echo "Cleaning Flutter build..."
	cd app && flutter clean
	@echo "Clean complete!"

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
	cd app && flutter analyze --no-fatal-infos
	@echo "Lint complete!"

# 运行 Rust Core
run-core:
	cd core && cargo run

# 运行 Flutter App
run-app:
	cd app && flutter run

# 构建发布版本
build-release:
	@echo "Building Rust release..."
	cd core && cargo build --release
	@echo "Building Flutter release..."
	cd app && flutter build apk --release
	@echo "Release build complete!"

# 运行 CI 检查
ci:
	@echo "Running CI checks..."
	make fmt
	make lint
	make test
	@echo "CI checks passed!"

