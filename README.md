# File Explorer

一个使用 Flutter + Rust 构建的跨平台文件检索桌面应用，架构参考 RustDesk。

## 架构概览

```
┌─────────────────────────────────────────────────┐
│                 Flutter UI Layer                 │
│  (跨平台 UI，支持 macOS/Windows/Linux)           │
├─────────────────────────────────────────────────┤
│              flutter_rust_bridge                 │
│  (FFI 桥接层，自动生成绑定代码)                   │
├─────────────────────────────────────────────────┤
│                 Rust Core Library                │
│  ┌───────────┬──────────────┬─────────────┐     │
│  │ 文件扫描   │   索引管理    │   搜索引擎   │     │
│  └───────────┴──────────────┴─────────────┘     │
└─────────────────────────────────────────────────┘
```

## 项目结构

```
flutter_demo/
├── rust_core/                 # Rust 核心库
│   ├── src/
│   │   ├── lib.rs            # 库入口
│   │   ├── api.rs            # Flutter API 接口
│   │   ├── models.rs         # 数据模型
│   │   ├── scanner.rs        # 文件扫描器
│   │   └── search.rs         # 搜索引擎
│   └── Cargo.toml
│
├── flutter_app/               # Flutter 前端
│   ├── lib/
│   │   ├── main.dart         # 应用入口
│   │   ├── models/           # Dart 数据模型
│   │   ├── screens/          # 页面
│   │   ├── widgets/          # 组件
│   │   ├── services/         # 服务层
│   │   └── utils/            # 工具类
│   └── pubspec.yaml
│
├── flutter_rust_bridge.yaml   # FRB 配置
├── Makefile                   # 构建脚本
└── README.md
```

## 核心功能

- **文件浏览**: 列表/网格视图、排序、隐藏文件显示
- **快速搜索**: 模糊匹配、实时搜索
- **高级搜索**: 按扩展名、大小、日期过滤
- **导航历史**: 前进/后退/上级目录
- **快捷访问**: 主目录、桌面、下载等常用位置

## 环境要求

- Rust 1.70+
- Flutter 3.10+
- flutter_rust_bridge_codegen

## 快速开始

### 1. 安装依赖

```bash
# 安装 Rust (如果未安装)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安装 Flutter (如果未安装)
# 参考: https://docs.flutter.dev/get-started/install

# 安装 flutter_rust_bridge 代码生成器
cargo install flutter_rust_bridge_codegen
```

### 2. 初始化项目

```bash
# 获取依赖
make setup

# 生成 FFI 绑定代码
make codegen
```

### 3. 运行应用

```bash
# 开发模式
make dev

# 或者指定平台
cd flutter_app
flutter run -d macos   # macOS
flutter run -d windows # Windows
flutter run -d linux   # Linux
```

### 4. 构建发布版本

```bash
make build
```

## 开发指南

### 添加新的 Rust API

1. 在 `rust_core/src/api.rs` 中添加函数
2. 运行 `make codegen` 重新生成绑定
3. 在 Flutter 中调用生成的 Dart 函数

### 状态管理

使用 Riverpod 进行状态管理：

```dart
// 读取状态
final state = ref.watch(fileServiceProvider);

// 调用方法
ref.read(fileServiceProvider.notifier).navigateTo('/path');
```

## 技术栈

### Rust
- `flutter_rust_bridge` - FFI 桥接
- `rayon` - 并行处理
- `fuzzy-matcher` - 模糊搜索
- `notify` - 文件系统监控
- `infer` - 文件类型检测

### Flutter
- `flutter_riverpod` - 状态管理
- `go_router` - 路由
- `fluent_ui` / `macos_ui` - 原生风格 UI

## License

MIT
