# V8Ray - 跨平台Xray Core客户端

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-1.75+-orange.svg)](https://rust-lang.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20鸿蒙%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

V8Ray是一个基于Xray Core的现代化跨平台代理客户端，提供安全、高效、易用的网络代理服务。支持iOS、Android、鸿蒙、Windows、macOS、Linux等主流平台。

## 🚧 项目状态

**当前版本**: v0.2.0 - 自动更新功能发布 🎉

**发布日期**: 2025-10-15

**开发进度**:
- ✅ Sprint 0: 环境搭建和基础架构 (已完成 - 2025-10-11)
- ✅ Sprint 1: Rust核心基础 (已完成 - 2025-10-11)
- ✅ Sprint 2-6: MVP 开发 (已完成 - 2025-10-14)
- ✅ Sprint 7: 自动更新功能 (已完成 - 2025-10-15)
- 🔄 Sprint 8: 高级功能开发 (进行中)
- ⏳ Sprint 9-12: 平台适配和优化 (计划中)

**v0.2.0 新增内容** (2025-10-15):

**自动更新功能**:
- ✅ 应用自动更新（从 GitHub Releases）
- ✅ Xray Core 自动更新（从 XTLS/Xray-core）
- ✅ 智能平台检测和文件下载
- ✅ 实时下载进度显示
- ✅ 自动安装和权限设置
- ✅ Windows 自动重启支持
- ✅ 统一的更新入口 UI
- ✅ 完善的错误处理和重试机制

**版本管理优化**:
- ✅ 统一版本号管理
- ✅ 自动生成 User-Agent 字符串
- ✅ 版本信息集中配置

**Bug 修复**:
- ✅ 修复了无法连接 Shadowsocks 和 Trojan 协议服务器的问题
- ✅ 修复了节点名称中特殊字符的解码问题
- ✅ 完善了 URL 解析和参数处理

**v0.1.0 核心功能** (2025-10-14):
- ✅ 代理连接/断开功能
- ✅ 订阅管理（添加、更新、删除）
- ✅ 节点自动解析和选择
- ✅ 系统代理自动配置
- ✅ 代理模式切换（全局/智能分流/直连）
- ✅ 多协议支持（VMess、VLESS、Trojan、Shadowsocks）
- ✅ 多订阅格式（Base64、V2Ray JSON、Clash YAML）
- ✅ 简单模式完整实现
- ✅ 中英文国际化
- ✅ 浅色/深色主题

**平台支持**:
- ✅ Linux (Ubuntu 20.04+) - 完全支持
- ⏳ Windows 10+ - 待测试
- ⏳ macOS 12+ - 待测试

**技术实现**:
- ✅ Rust 后端核心逻辑
- ✅ Flutter 跨平台 UI
- ✅ FFI 桥接（Flutter Rust Bridge 2.11.1）
- ✅ SQLite 数据持久化
- ✅ Riverpod 状态管理
- ✅ Xray Core 集成
- ✅ 异步架构（Tokio）
- ✅ 结构化日志系统
- ✅ 统一错误处理

**Bug 修复**:
- ✅ 系统代理配置问题
- ✅ Xray 进程权限问题
- ✅ 日志系统 release 模式问题
- ✅ 节点名称解析和显示问题
- ✅ UI 导航和交互问题

## 🎯 版本亮点

### v0.1.0: 首个 MVP 版本 ✅
**发布时间**: 2025-10-14 | **状态**: 稳定版 | **平台**: Linux

#### 核心功能
- ✅ **一键连接**: 简单模式下一键连接代理服务器
- ✅ **订阅管理**: 支持添加、更新、删除订阅源
- ✅ **自动配置**: 连接时自动启用系统代理，断开时自动禁用
- ✅ **多协议支持**: VMess、VLESS、Trojan、Shadowsocks
- ✅ **智能路由**: 支持全局、智能分流
- ✅ **节点管理**: 自动解析订阅中的所有节点
- ✅ **国际化**: 支持中文和英文界面

#### 技术亮点
- 🔒 **安全**: AES-256-GCM 加密存储敏感配置
- ⚡ **高性能**: Rust 后端 + 异步架构
- 🎨 **现代化 UI**: Flutter Material Design 3
- 🔧 **易维护**: 统一的错误处理和日志系统
- 📦 **开箱即用**: 自动下载 Xray Core，无需手动配置

#### 用户体验
- 🎯 **极简操作**: 简单模式只需 3 步即可连接
- 🌍 **多语言**: 应用内一键切换中英文
- 🎨 **主题支持**: 自动适配系统浅色/深色主题
- 📊 **状态显示**: 实时显示连接状态和节点信息

详细更新日志请查看 [CHANGELOG.md](CHANGELOG.md)

## ✨ 特性

### 🚀 核心功能
- **多协议支持**: VLESS、VMess、Trojan、Shadowsocks、HTTP、SOCKS等
- **多传输方式**: TCP、mKCP、WebSocket、HTTP/2、gRPC、QUIC等
- **智能路由**: 支持域名、IP、地理位置等多种路由规则
- **负载均衡**: 多服务器负载均衡和故障转移
- **订阅管理**: 支持多订阅源自动更新和分组管理

### 📱 跨平台支持
- **移动端**: iOS 14+、Android 7+、鸿蒙 4.0+
- **桌面端**: Windows 10+、macOS 12+、Linux (Ubuntu 20.04+)
- **统一体验**: 所有平台保持一致的用户界面和功能

### 🛡️ 安全特性
- **数据加密**: 本地配置数据AES-256加密存储
- **传输安全**: 所有网络传输使用TLS加密
- **隐私保护**: 不收集用户隐私数据
- **权限控制**: 最小权限原则

### ⚡ 性能优化
- **快速启动**: 应用启动时间<3秒
- **低延迟**: 代理延迟增加<50ms
- **低资源**: 移动端内存使用<100MB
- **智能连接**: 自动选择最优节点

### 🎨 界面设计
- **双模式设计**: 简单模式和高级模式自由切换
- **简单模式**: 极简操作，一键连接，适合普通用户
- **高级模式**: 完整功能，专业配置，适合高级用户
- **明暗主题**: 支持浅色和深色主题切换

### 🌍 国际化支持
- **默认语言**: English (英文)
- **支持语言**: 简体中文 (Simplified Chinese)
- **语言切换**: 应用内一键切换语言
- **本地化**: 所有UI文本完全本地化

## 📋 系统要求

### 移动端
- **iOS**: iOS 14.0+ / iPadOS 14.0+
- **Android**: Android 7.0+ (API Level 24+)
- **鸿蒙**: HarmonyOS 4.0+

### 桌面端
- **Windows**: Windows 10 1903+ (64位)
- **macOS**: macOS 12.0+ (Intel/Apple Silicon)
- **Linux**: Ubuntu 20.04+, Debian 11+, Fedora 35+

## 🏗️ 技术架构

### 核心技术栈
- **前端**: Flutter 3.16+ / Dart 3.2+
- **后端**: Rust 1.75+ / Xray Core
- **状态管理**: Riverpod 2.4+
- **存储**: SQLite + Hive + Secure Storage
- **网络**: Dio + HTTP/2
- **桥接**: Flutter Rust Bridge 2.0+

### 架构设计
```
┌─────────────────────────────────────────────────────────────┐
│                Flutter UI Layer (简单/高级模式)              │
├─────────────────────────────────────────────────────────────┤
│                Flutter Business Layer (Dart)                │
├─────────────────────────────────────────────────────────────┤
│                Flutter-Rust Bridge (FFI)                    │
├─────────────────────────────────────────────────────────────┤
│                Rust Core Layer (业务逻辑)                    │
├─────────────────────────────────────────────────────────────┤
│                Platform Adapter (平台适配)                   │
├─────────────────────────────────────────────────────────────┤
│                Xray Core Engine (代理核心)                   │
└─────────────────────────────────────────────────────────────┘
```

## 📁 项目结构

```
v8ray/
├── docs/                    # 项目文档
│   ├── requirements.md      # 需求说明书
│   ├── architecture.md      # 系统架构设计
│   └── technical-architecture.md # 技术架构详细设计
├── core/                    # Rust核心模块
│   ├── src/                # Rust源代码
│   │   ├── bridge/         # Flutter桥接
│   │   ├── xray/           # Xray Core集成
│   │   ├── config/         # 配置管理
│   │   └── platform/       # 平台适配
│   └── Cargo.toml          # Rust项目配置
├── app/                     # Flutter应用
│   ├── lib/                # Dart源代码
│   │   ├── core/           # 核心模块
│   │   ├── data/           # 数据层
│   │   ├── domain/         # 业务层
│   │   ├── presentation/   # 表现层
│   │   └── platform/       # 平台适配
│   ├── android/            # Android项目
│   ├── ios/                # iOS项目
│   ├── windows/            # Windows项目
│   ├── macos/              # macOS项目
│   ├── linux/              # Linux项目
│   └── harmony/            # 鸿蒙项目
└── platform/               # 平台特定模块
    ├── android/            # Android VPN服务
    ├── ios/                # iOS NetworkExtension
    ├── windows/            # Windows TUN
    ├── macos/              # macOS NetworkExtension
    ├── linux/              # Linux TUN/TAP
    └── harmony/            # 鸿蒙VPN Kit
```

## 🚀 快速开始

### 开发环境准备

**前置要求**:
- Flutter SDK 3.16+
- Rust 1.75+
- Git
- Dart SDK (Flutter 自带)

1. **安装Flutter SDK**
```bash
# 下载并安装Flutter 3.16+
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PWD/flutter/bin:$PATH"
flutter doctor
```

2. **安装Rust环境**
```bash
# 下载并安装Rust 1.75+
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup update
```

3. **克隆项目**
```bash
git clone git@github.com:v8ray/v8ray.git
cd v8ray
```

4. **安装依赖**
```bash
# Flutter依赖
cd app
flutter pub get

# Rust依赖
cd ../core
cargo build
```

### 使用 Makefile 构建

项目提供了便捷的 Makefile 命令：

```bash
# 安装所有依赖（首次运行）
make setup

# 生成 FFI 桥接代码
make bridge

# 构建 debug 版本
make build-debug

# 构建 release 版本
make build-release

# 运行应用（debug 模式）
make run

# 清理构建产物
make clean

# 深度清理（包括下载的文件）
make clean-all
```

### 手动构建步骤

如果不使用 Makefile，可以手动执行以下步骤：

1. **构建 Rust 库**
```bash
cd core
cargo build --release --lib
```

2. **构建 Flutter 应用**
```bash
cd app
flutter build linux --release  # Linux
flutter build windows --release  # Windows
flutter build macos --release  # macOS
```

3. **下载 Xray Core**
```bash
# Linux/macOS
bash scripts/post_build.sh release

# Windows
scripts\post_build.bat release
```

### 运行应用

**Linux**:
```bash
# Debug 模式
./app/build/linux/x64/debug/bundle/v8ray

# Release 模式
./app/build/linux/x64/release/bundle/v8ray
```

**Windows**:
```powershell
# Debug 模式
.\app\build\windows\x64\runner\Debug\v8ray.exe

# Release 模式
.\app\build\windows\x64\runner\Release\v8ray.exe
```

**macOS**:
```bash
# Debug 模式
./app/build/macos/Build/Products/Debug/v8ray.app/Contents/MacOS/v8ray

# Release 模式
./app/build/macos/Build/Products/Release/v8ray.app/Contents/MacOS/v8ray
```

## 📖 文档

### 用户文档
- [CHANGELOG.md](CHANGELOG.md) - 版本更新日志
- [用户指南](docs/user-guide/) - 用户使用手册（待完善）

### 项目文档
- [需求说明书](docs/requirements.md) - 详细的功能需求和用户故事
- [系统架构设计](docs/architecture.md) - 整体架构和设计原则
- [技术架构文档](docs/technical-architecture.md) - 技术选型和模块设计
- [项目结构规划](docs/project-structure.md) - 目录结构和开发环境
- [开发计划](docs/development-plan.md) - 敏捷开发计划和Sprint规划

### Sprint文档
- [Sprint 1 进度报告](docs/SPRINT1_PROGRESS.md) - Sprint 1详细进度
- [Sprint 1 完成总结](docs/SPRINT1_COMPLETION_SUMMARY.md) - Sprint 1成果总结

### 开发文档
- [API文档](docs/api/) - 接口文档和使用说明（待完善）
- [开发者指南](docs/developer-guide/) - 开发者文档（待完善）

## 🤝 贡献

我们欢迎所有形式的贡献！请阅读 [贡献指南](CONTRIBUTING.md) 了解如何参与项目开发。

### 开发流程
1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范
- 遵循 [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- 遵循 [Rust Style Guide](https://doc.rust-lang.org/1.0.0/style/)
- 使用 `flutter analyze` 和 `cargo clippy` 进行代码检查
- 使用 `dart format` 和 `cargo fmt` 进行代码格式化
- 确保测试覆盖率 > 80%

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [Xray Core](https://github.com/XTLS/Xray-core) - 强大的代理核心
- [Flutter](https://flutter.dev) - 优秀的跨平台UI框架
- [Rust](https://rust-lang.org) - 安全高效的系统编程语言
- [Flutter Rust Bridge](https://github.com/fzyzcjy/flutter_rust_bridge) - Flutter与Rust的桥接方案

## 📞 联系我们

- 项目主页: [https://github.com/v8ray/v8ray](https://github.com/v8ray/v8ray)
- 问题反馈: [Issues](https://github.com/v8ray/v8ray/issues)
- 讨论交流: [Discussions](https://github.com/v8ray/v8ray/discussions)

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=v8ray/v8ray&type=Date)](https://star-history.com/#v8ray/v8ray&Date)

---

**注意**: 本软件仅供学习和研究使用，请遵守当地法律法规，不得用于非法用途。
