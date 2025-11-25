# File Explorer 项目构建脚本
# 支持 macOS, Windows, Linux

.PHONY: all clean setup build-rust build-flutter run codegen

# 默认目标
all: setup codegen build

# 清理构建产物
clean:
	cd rust_core && cargo clean
	cd flutter_app && flutter clean
	rm -rf flutter_app/lib/src/rust/

# 初始化设置
setup:
	@echo "==> 安装 flutter_rust_bridge_codegen..."
	cargo install flutter_rust_bridge_codegen
	@echo "==> 获取 Flutter 依赖..."
	cd flutter_app && flutter pub get

# 生成 Rust-Flutter 绑定代码
codegen:
	@echo "==> 生成 FFI 绑定代码..."
	flutter_rust_bridge_codegen generate

# 构建 Rust 库
build-rust:
	@echo "==> 构建 Rust 库..."
	cd rust_core && cargo build --release

# 构建 Flutter 应用
build-flutter:
	@echo "==> 构建 Flutter 应用..."
ifeq ($(shell uname), Darwin)
	cd flutter_app && flutter build macos --release
else ifeq ($(shell uname), Linux)
	cd flutter_app && flutter build linux --release
else
	cd flutter_app && flutter build windows --release
endif

# 完整构建
build: build-rust build-flutter

# 运行应用
run:
	@echo "==> 运行应用..."
ifeq ($(shell uname), Darwin)
	cd flutter_app && flutter run -d macos
else ifeq ($(shell uname), Linux)
	cd flutter_app && flutter run -d linux
else
	cd flutter_app && flutter run -d windows
endif

# 开发模式（热重载）
dev:
	cd flutter_app && flutter run -d macos --debug

# 运行 Rust 测试
test-rust:
	cd rust_core && cargo test

# 运行 Flutter 测试
test-flutter:
	cd flutter_app && flutter test

# 运行所有测试
test: test-rust test-flutter

# 格式化代码
fmt:
	cd rust_core && cargo fmt
	cd flutter_app && dart format lib/

# 代码检查
lint:
	cd rust_core && cargo clippy
	cd flutter_app && flutter analyze
