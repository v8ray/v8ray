# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-14

### 🎉 首个 MVP 版本发布

这是 V8Ray 的第一个可用版本，实现了基本的代理功能和简单模式 UI。

### ✨ 新增功能

#### 核心功能
- **代理连接**: 支持连接/断开代理服务器
- **订阅管理**: 支持添加、更新、删除订阅源
- **节点管理**: 自动解析订阅中的节点配置
- **系统代理**: 自动配置系统代理设置（连接时启用，断开时禁用）
- **代理模式**: 支持全局模式、智能分流、直连模式

#### 协议支持
- ✅ VMess 协议（完整支持，包括名称解析）
- ✅ VLESS 协议（支持 fragment 和 query 参数名称解析）
- ✅ Trojan 协议（支持 URL 解码的名称）
- ✅ Shadowsocks 协议（支持 URL 解码的名称）

#### 订阅格式
- ✅ Base64 编码的订阅链接
- ✅ V2Ray JSON 格式
- ✅ Clash YAML 格式

#### 用户界面
- **简单模式**: 极简操作界面，一键连接
  - 连接状态卡片（显示节点名称、延迟、流量统计）
  - 订阅管理卡片（添加、更新、删除订阅）
  - 节点选择器（显示所有可用节点）
  - 代理模式选择（全局/智能分流/直连）
- **高级模式**: 占位页面（待实现）
- **模式切换**: 支持简单模式和高级模式之间切换
- **语言切换**: 支持中文和英文界面
- **主题支持**: 支持浅色和深色主题

#### 平台支持
- ✅ Linux (Ubuntu 20.04+)
  - 系统代理自动配置（gsettings）
  - Xray Core 进程管理
  - 普通用户权限运行
- ⏳ Windows (待测试)
- ⏳ macOS (待测试)

#### 技术特性
- **Rust 后端**: 高性能、内存安全的核心逻辑
- **Flutter 前端**: 跨平台 UI 框架
- **FFI 桥接**: Flutter Rust Bridge 2.11.1
- **异步架构**: 基于 Tokio 的异步运行时
- **数据库**: SQLite 持久化存储
- **日志系统**: 结构化日志，支持文件输出
- **错误处理**: 统一的错误处理机制

### 🐛 Bug 修复

#### 系统代理问题
- 修复了使用 sudo 运行时系统代理配置到 root 用户的问题
- 修复了 gsettings 权限问题（检测 SUDO_USER 并以实际用户运行）
- 修复了系统代理未自动启用的问题

#### Xray Core 问题
- 修复了 Xray 进程启动权限错误（config.json 文件权限问题）
- 修复了 Xray 进程僵尸进程问题
- 添加了详细的错误日志以便调试

#### 日志系统问题
- 修复了 release 模式下日志不显示的问题
- 添加了 Rust 日志初始化调用
- 配置 Cargo.toml 在 release 模式保留调试信息

#### UI 问题
- 修复了高级模式无法切换回简单模式的问题
- 移除了不需要的设置按钮
- 修复了当前节点显示 ID 而不是名称的问题
- 修复了 VLESS、Trojan、Shadowsocks 节点名称解析问题（添加 URL 解码）

#### 配置解析问题
- 修复了 VLESS URL 名称解析（优先使用 fragment）
- 修复了 Trojan URL 名称解析（添加 URL 解码）
- 修复了 Shadowsocks URL 名称解析（添加 URL 解码）
- 添加了 `urlencoding` 依赖以正确处理中文节点名

### 🔧 改进

#### 性能优化
- 使用全局 Tokio 运行时避免任务取消
- 优化了数据库查询性能
- 减少了不必要的状态更新

#### 用户体验
- 连接时自动启用系统代理
- 断开时自动禁用系统代理
- 显示实际节点名称而不是 ID
- 改进了错误提示信息

#### 开发体验
- 添加了详细的日志输出
- 改进了错误处理和调试信息
- 优化了构建脚本

### 📝 已知问题

1. **权限问题**: 
   - Linux 上首次运行可能需要手动删除 root 创建的 config.json
   - 建议始终以普通用户身份运行应用

2. **平台支持**:
   - Windows 和 macOS 平台未经充分测试
   - 移动平台（iOS、Android）尚未实现

3. **功能限制**:
   - 高级模式尚未实现
   - 缺少节点延迟测试功能
   - 缺少流量统计功能
   - 缺少日志查看界面

### 🚀 下一步计划

#### v0.2.0 (计划中)
- [ ] 实现高级模式 UI
- [ ] 添加节点延迟测试
- [ ] 添加实时流量统计
- [ ] 添加日志查看界面
- [ ] 完善 Windows 和 macOS 支持
- [ ] 添加自动更新功能

#### v0.3.0 (计划中)
- [ ] 实现路由规则编辑
- [ ] 添加自定义 DNS 配置
- [ ] 支持分应用代理
- [ ] 添加流量统计图表
- [ ] 实现配置导入/导出

### 📦 安装说明

#### Linux
```bash
# 下载并解压
tar -xzf v8ray-linux-x64.tar.gz
cd v8ray

# 运行应用
./v8ray
```

#### Windows
```powershell
# 解压 zip 文件
Expand-Archive v8ray-windows-x64.zip -DestinationPath v8ray

# 运行应用
cd v8ray
.\v8ray.exe
```

#### macOS
```bash
# 下载并解压
tar -xzf v8ray-macos-x64.tar.gz
cd v8ray

# 运行应用
./v8ray
```

### 🙏 致谢

感谢所有为这个项目做出贡献的开发者和测试者！

---

## [0.2.0] - 2025-10-15

### 🎉 自动更新功能发布

这是 V8Ray 的第二个版本，主要添加了应用和 Xray Core 的自动更新功能。

### ✨ 新增功能

#### 应用自动更新
- **版本检查**: 从 GitHub Releases 自动检查最新版本
- **智能下载**: 根据平台自动选择正确的安装包
  - Windows: `.zip` 格式
  - Linux: `.tar.gz` 格式
  - macOS: `.tar.gz` 格式
- **自动安装**:
  - Windows: PowerShell 自动解压 + 批处理脚本延迟安装 + 自动重启
  - Linux: tar 自动解压 + 权限设置 + 手动重启提示
  - macOS: tar 自动解压 + 权限设置 + 手动重启提示
- **进度显示**: 实时显示下载进度和百分比
- **错误处理**: 完善的错误提示和重试机制
- **统一入口**: 应用更新和 Xray Core 更新共享同一个"系统更新"图标

#### Xray Core 自动更新
- **版本检查**: 从 XTLS/Xray-core GitHub Releases 检查最新版本
- **智能下载**: 根据平台自动选择正确的二进制文件
- **自动安装**: 下载完成后自动替换旧版本
- **即时生效**: 无需重启应用，新版本立即可用
- **进度监控**: 实时显示下载进度

#### 版本管理优化
- **统一版本号**: 在一个位置管理所有版本信息
  - Flutter: `app/lib/core/constants/app_constants.dart`
  - Rust: `core/src/version.rs`
  - 自动从 `Cargo.toml` 和 `pubspec.yaml` 读取版本号
- **User-Agent 统一**: 所有 HTTP 请求使用统一的 User-Agent 字符串
  - 格式: `V8Ray/0.2.0`
  - 自动从版本常量生成

### 🔧 技术改进

#### 平台兼容性
- **Windows**:
  - 使用 PowerShell `Expand-Archive` 解压 zip 文件
  - 批处理脚本延迟复制文件（避免覆盖正在运行的程序）
  - 自动重启应用
- **Linux**:
  - tar 参数兼容性优化（支持 `--overwrite-dir` 和回退）
  - 自动设置可执行权限（主程序 + bin 目录）
- **macOS**:
  - 简化 tar 参数，提高兼容性
  - 自动设置可执行权限

#### 代码质量
- **精确的平台匹配**:
  - 匹配 `windows-x64`、`linux-x64`、`macos-x64`
  - 验证文件扩展名（`.zip` 或 `.tar.gz`）
- **详细的日志**: 便于调试和问题排查
- **完善的错误处理**: 所有平台都有详细的错误提示
- **状态管理**: 使用 Riverpod StateNotifier 实现响应式状态管理

### 🐛 Bug 修复

#### 自动更新相关
- 修复了 Windows 平台文件格式不匹配问题（期望 `.exe` 但实际是 `.zip`）
- 修复了平台资源匹配不精确的问题（可能匹配到错误的文件）
- 修复了 tar 参数兼容性问题（`--overwrite` 在某些版本中不存在）
- 移除了未使用的导入（`package:flutter/foundation.dart`）

#### 协议连接相关
- **修复了无法连接 Shadowsocks 和 Trojan 协议服务器的问题**
  - 修复了 Shadowsocks URL 解析：支持两种格式
    - 格式1: `ss://base64(method:password)@server:port#name`
    - 格式2: `ss://base64(method:password@server:port)#name`
  - 修复了 Trojan URL 解析：正确处理密码和流设置
  - 添加了 URL 解码支持（使用 `urlencoding` crate）
  - 修复了节点名称中特殊字符的解码问题（如 `%20` → 空格）
  - 完善了 VLESS 协议的 URL 解析和参数处理

### 📁 新增文件

#### Flutter (Dart)
- `app/lib/core/providers/app_update_provider.dart` - 应用更新状态管理
- `app/lib/core/providers/xray_core_update_provider.dart` - Xray Core 更新状态管理
- `app/lib/presentation/widgets/app_update_checker.dart` - 统一的更新检查 UI 组件
- `app/test/xray_core_update_test.dart` - Xray Core 更新单元测试

#### Rust
- `core/src/version.rs` - 统一的版本信息管理
- `core/src/xray/updater.rs` - Xray Core 更新器（已存在，已优化）

#### 文档
- `docs/xray-core-update-feature.md` - Xray Core 更新功能文档
- `docs/xray-core-update-implementation-summary.md` - 实现总结
- `docs/xray-core-update-final-summary.md` - 最终总结
- `docs/app-update-auto-install-fix.md` - 自动安装修复文档
- `docs/app-update-platform-analysis.md` - 三平台深度分析报告
- `docs/app-update-verification-summary.md` - 验证总结

### 📊 国际化

新增 36 个国际化字符串（中英文）：
- 应用更新相关: 18 个
- Xray Core 更新相关: 18 个

### 🧪 测试

- ✅ 11 个 Xray Core 更新单元测试全部通过
- ✅ 7 个版本管理单元测试全部通过
- ✅ Shadowsocks 和 Trojan 协议解析测试通过
- ✅ Rust 编译成功
- ✅ Flutter 编译成功
- ✅ make build-release 成功

### 📝 已知限制

#### Windows
- 需要 PowerShell（Windows 7+ 默认包含）
- 批处理延迟 2 秒（可调整）
- 安装在 Program Files 可能需要管理员权限

#### Linux
- 需要对应用目录有写权限
- 需要手动重启应用
- 某些旧版本 tar 可能不支持 `--overwrite-dir`

#### macOS
- 需要对应用目录有写权限
- 需要手动重启应用
- 首次运行可能需要 Gatekeeper 授权

### 🚀 下一步计划

#### v0.3.0 (计划中)
- [ ] SHA256 校验和验证
- [ ] 回滚功能（安装失败时恢复旧版本）
- [ ] 增量更新（只下载变化的文件）
- [ ] 断点续传（支持下载中断后继续）
- [ ] Linux/macOS 自动重启支持

---

## [Unreleased]

### 计划中的功能
- 高级模式完整实现
- 节点延迟测试
- 实时流量统计
- 日志查看界面
- 更新功能增强（SHA256 校验、回滚、增量更新）

---

**注意**: 本软件仅供学习和研究使用，请遵守当地法律法规。

