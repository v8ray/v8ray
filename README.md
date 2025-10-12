# V8Ray - 跨平台Xray Core客户端

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-1.75+-orange.svg)](https://rust-lang.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20鸿蒙%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

V8Ray是一个基于Xray Core的现代化跨平台代理客户端，提供安全、高效、易用的网络代理服务。支持iOS、Android、鸿蒙、Windows、macOS、Linux等主流平台。

## 🚧 项目状态

**当前版本**: v0.1.0 (Sprint 1 已完成)

**开发进度**:
- ✅ Sprint 0: 环境搭建和基础架构 (已完成 - 2025-10-11)
- ✅ Sprint 1: Rust核心基础 (已完成 - 2025-10-11)
- 🔄 Sprint 2: Flutter基础UI (计划中)
- ⏳ Sprint 3: Rust-Flutter桥接 (计划中)
- ⏳ Sprint 4-12: 功能开发和平台适配 (计划中)

**Sprint 1 完成内容** (2025-10-11):
- ✅ 错误处理系统 (8种专用错误类型)
- ✅ 日志系统 (支持多级别日志和文件输出)
- ✅ 配置管理系统 (支持加密、备份、验证)
- ✅ 工具模块 (加密工具、网络工具)
- ✅ URL解析器 (支持VLESS、VMess、Trojan、Shadowsocks)
- ✅ 完整的测试覆盖 (71个测试,覆盖率>85%)
- ✅ 集成测试框架 (17个集成测试)
- ✅ 详细的开发文档

**Sprint 0 完成内容** (2025-10-11):
- ✅ 项目仓库和基础目录结构
- ✅ Rust开发环境和Cargo.toml配置
- ✅ Flutter开发环境和pubspec.yaml配置
- ✅ Flutter Rust Bridge基础配置
- ✅ GitHub Actions CI/CD流水线
- ✅ 代码质量检查工具(clippy, dartanalyzer)
- ✅ 基础测试框架(单元测试、集成测试)
- ✅ 开发环境文档

## 🎯 技术成果

### Sprint 1: Rust核心基础 ✅
**完成时间**: 2025-10-11 | **测试覆盖率**: 85%+ | **测试数量**: 71个

#### 核心模块
- ✅ **错误处理系统**: 统一的错误类型定义,8种专用错误类型
- ✅ **日志系统**: 基于tracing的结构化日志,支持5个日志级别
- ✅ **配置管理**: 完整的配置CRUD,支持加密存储(AES-256-GCM)
- ✅ **配置备份**: 自动备份和恢复,支持配置导出/导入
- ✅ **配置验证**: 协议特定验证,详细的错误和警告信息
- ✅ **URL解析**: 支持vmess://, vless://, trojan://, ss://等协议
- ✅ **加密工具**: AES-256-GCM加密/解密,密钥生成和派生
- ✅ **网络工具**: IP/端口/主机名验证,URL解析和规范化

#### 技术亮点
- 🔒 **配置加密**: 使用AES-256-GCM加密算法保护敏感配置
- 💾 **自动备份**: 带时间戳的配置备份,支持备份管理
- ⚡ **异步架构**: 全面使用Tokio异步运行时,线程安全设计
- 🧪 **高测试覆盖**: 54个单元测试 + 17个集成测试,覆盖率>85%

详细信息请查看 [Sprint 1 完成总结](docs/SPRINT1_COMPLETION_SUMMARY.md)

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

### 开发工具和脚本

项目提供了便捷的开发脚本：

1. **代码质量检查**
```bash
# 检查所有代码质量
./scripts/check-quality.sh

# 只检查Rust代码
./scripts/check-quality.sh --rust

# 只检查Flutter代码
./scripts/check-quality.sh --flutter

# 自动修复格式问题
./scripts/check-quality.sh --fix
```

2. **运行测试**
```bash
# 运行所有测试
./scripts/run-tests.sh

# 只运行Rust测试
./scripts/run-tests.sh --rust

# 只运行Flutter测试
./scripts/run-tests.sh --flutter

# 运行集成测试
./scripts/run-tests.sh --integration

# 生成覆盖率报告
./scripts/run-tests.sh --coverage
```

**Windows用户**: 使用PowerShell脚本
```powershell
# 代码质量检查
.\scripts\check-quality.ps1

# 运行测试
.\scripts\run-tests.ps1
```

### 构建和运行

1. **开发模式运行**
```bash
# 运行Flutter应用(调试模式)
cd app
flutter run

# 运行Rust核心服务
cd ../core
cargo run
```

2. **构建发布版本**
```bash
# 构建Android APK
flutter build apk --release

# 构建iOS IPA
flutter build ios --release

# 构建Windows应用
flutter build windows --release

# 构建macOS应用
flutter build macos --release

# 构建Linux应用
flutter build linux --release
```

## 📖 文档

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
- [API文档](docs/api/) - 接口文档和使用说明
- [用户指南](docs/user-guide/) - 用户使用手册
- [开发者指南](docs/developer-guide/) - 开发者文档

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
