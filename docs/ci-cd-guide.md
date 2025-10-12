# CI/CD 工作流程指南

## 概述

V8Ray 项目采用分级 CI/CD 策略，根据不同的触发条件执行不同级别的检查和构建，以优化开发效率和资源使用。

## 工作流程类型

### 1. 快速检查 (Quick Check)

**触发条件**: `push` 到 `main` 或 `develop` 分支

**执行内容**:
- ✅ Rust 代码格式检查 (`cargo fmt`)
- ✅ Rust 快速 Clippy 检查 (仅检查库代码)
- ✅ Flutter 代码格式检查 (`dart format`)
- ✅ Flutter 代码分析 (`flutter analyze`)

**运行平台**: Ubuntu (单平台)

**预计时间**: 2-3 分钟

**目的**: 快速反馈代码格式和基本语法问题，不阻塞开发流程

### 2. 完整测试 (Full Tests)

**触发条件**: 
- Pull Request 到 `main` 或 `develop` 分支
- 手动触发 (workflow_dispatch)

**执行内容**:
- ✅ 所有快速检查项
- ✅ Rust 完整 Clippy 检查 (所有目标和特性)
- ✅ Rust 单元测试和集成测试
- ✅ Rust Release 构建
- ✅ Flutter 单元测试
- ✅ 安全审计 (cargo-audit)
- ✅ 代码覆盖率分析

**运行平台**: Ubuntu, Windows, macOS (三平台)

**预计时间**: 15-20 分钟

**目的**: 确保代码质量，在合并前发现潜在问题

### 3. 完整构建 (Full Build)

**触发条件**:
- 手动触发 (workflow_dispatch)
- 发布标签 (tags: v*)

**执行内容**:
- ✅ 所有完整测试项
- ✅ 多平台 Release 构建
  - Linux (x86_64)
  - Windows (x86_64)
  - macOS (x86_64)
- ✅ 构建产物上传

**运行平台**: Ubuntu, Windows, macOS

**预计时间**: 30-40 分钟

**目的**: 生成可发布的构建产物

### 4. 自定义构建 (Custom Build)

**触发条件**: 手动触发 (full-build.yml)

**可配置选项**:
- 构建类型: `debug` 或 `release`
- 目标平台: `linux`, `windows`, `macos`, `android`, `ios` (可多选)

**执行内容**:
- ✅ 根据选择的平台进行构建
- ✅ 打包构建产物
- ✅ 上传 artifacts (保留 7 天)

**预计时间**: 根据选择的平台数量而定

**目的**: 灵活的按需构建，用于测试特定平台或配置

### 5. 发布构建 (Release)

**触发条件**: 推送版本标签 (例如: `v0.1.0`)

**执行内容**:
- ✅ 创建 GitHub Release
- ✅ 多平台 Release 构建
- ✅ 打包并上传到 Release

**运行平台**: Ubuntu, Windows, macOS

**目的**: 自动化发布流程

## 使用指南

### 日常开发 (Push)

```bash
# 提交代码前，确保格式正确
cd core
cargo fmt --all

cd ../app
dart format .

# 提交代码
git add .
git commit -m "feat: 添加新功能"
git push origin develop
```

**结果**: 触发快速检查，2-3 分钟内获得反馈

### 创建 Pull Request

```bash
# 创建 PR
gh pr create --base main --head develop --title "Feature: 新功能"
```

**结果**: 触发完整测试，15-20 分钟内完成所有检查

### 手动触发完整测试

1. 访问 GitHub Actions 页面
2. 选择 "CI/CD Pipeline" 工作流
3. 点击 "Run workflow"
4. 选择分支并运行

**结果**: 执行完整测试，包括所有平台

### 手动触发自定义构建

1. 访问 GitHub Actions 页面
2. 选择 "Full Build" 工作流
3. 点击 "Run workflow"
4. 配置选项:
   - **Build type**: 选择 `debug` 或 `release`
   - **Platforms**: 输入平台列表，例如 `linux,windows` 或 `linux,windows,macos,android,ios`
5. 点击 "Run workflow"

**结果**: 根据配置构建指定平台，构建产物保留 7 天

### 发布新版本

```bash
# 确保在 main 分支
git checkout main
git pull origin main

# 创建并推送标签
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

**结果**: 自动创建 GitHub Release 并上传构建产物

## CI/CD 优化策略

### 1. 分级检查
- **Push**: 只做格式和基本检查，快速反馈
- **PR**: 完整测试，确保质量
- **Release**: 完整构建，生成产物

### 2. 缓存策略
- Rust 依赖缓存 (Cargo registry, target/)
- Flutter 依赖缓存 (pub cache)
- 减少重复下载和编译时间

### 3. 并行执行
- 多平台测试并行运行
- 独立的 job 可以同时执行

### 4. 失败快速
- 格式检查失败立即停止
- 测试失败不影响其他平台

### 5. 可选任务
- 安全审计和代码覆盖率设置为 `continue-on-error`
- 不阻塞主要流程

## 故障排查

### 快速检查失败

**常见原因**:
- 代码格式不符合规范
- Clippy 警告

**解决方法**:
```bash
# 修复格式
cargo fmt --all
dart format .

# 检查 Clippy 警告
cargo clippy --lib -- -W clippy::all
```

### 完整测试失败

**常见原因**:
- 测试用例失败
- 跨平台兼容性问题

**解决方法**:
```bash
# 本地运行测试
cargo test --all
flutter test

# 检查特定平台问题
cargo build --target <target-triple>
```

### 构建失败

**常见原因**:
- 依赖问题
- 平台特定代码错误

**解决方法**:
- 查看 CI 日志定位具体错误
- 在对应平台上本地复现和修复

## 最佳实践

### 1. 提交前检查
```bash
# 运行本地检查脚本
./scripts/pre-commit-check.sh
```

### 2. 小步提交
- 频繁提交小的改动
- 快速检查能快速发现问题

### 3. PR 前测试
- 在本地运行完整测试
- 确保 PR 能通过 CI

### 4. 合理使用手动触发
- 测试特定平台时使用自定义构建
- 避免不必要的完整构建

### 5. 关注 CI 反馈
- 及时修复 CI 失败
- 不要忽略警告信息

## 性能指标

| 工作流 | 平台数 | 预计时间 | 资源消耗 |
|--------|--------|----------|----------|
| 快速检查 | 1 | 2-3 分钟 | 低 |
| 完整测试 | 3 | 15-20 分钟 | 中 |
| 完整构建 | 3 | 30-40 分钟 | 高 |
| 自定义构建 | 可变 | 可变 | 可变 |
| 发布构建 | 3 | 30-40 分钟 | 高 |

## 更新日志

- **2025-10-12**: 实现分级 CI/CD 策略
  - 添加快速检查工作流
  - 优化完整测试触发条件
  - 新增自定义构建工作流
  - 更新文档

---

**维护者**: V8Ray 开发团队  
**最后更新**: 2025-10-12

