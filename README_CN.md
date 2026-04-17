# Anji

<p align="center">
  <img src="AnjiApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Anji 图标">
</p>

<p align="center">
  <strong>基于官方 Anki Rust 后端的 iOS 记忆卡片应用</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_CN.md">简体中文</a>
</p>

<p align="center">
  <a href="https://github.com/yingluom/anji/releases">
    <img src="https://img.shields.io/github/v/release/yingluom/anji?color=blue" alt="版本">
  </a>
  <a href="https://github.com/yingluom/anji/actions">
    <img src="https://img.shields.io/github/workflow/status/yingluom/anji/CI?label=CI" alt="CI">
  </a>
  <img src="https://img.shields.io/badge/iOS-18+-blue?logo=apple" alt="iOS 18+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-AGPL--3.0-green" alt="许可证">
  </a>
</p>

---

Anji 是一款开源的 iOS 记忆卡片应用，将 [Anki](https://apps.ankiweb.net/) 的完整功能带到你的 iPhone 和 iPad。基于官方 Anki Rust 后端（`rslib`）构建，确保与 AnkiWeb 同步、FSRS 调度算法以及所有 Anki 卡片功能 100% 兼容。

## ✨ 功能特性

| 功能 | 描述 |
|------|------|
| 🔄 **AnkiWeb 同步** | 牌组与媒体文件的完整双向同步 |
| 🧠 **FSRS 算法** | 新一代间隔重复调度算法 |
| 📊 **统计图表** | 今日概览、预测、复习历史、间隔分布、简易度 |
| 🎨 **精美主题** | 浅色/深色/跟随系统，6 种强调色可选 |
| 🌐 **双语界面** | 支持英文和简体中文 |
| 🎵 **丰富媒体** | 卡片内支持图片、音频和视频 |
| 🔍 **卡片浏览器** | 搜索、筛选和管理你的卡片 |
| 📱 **原生 iOS** | 使用 SwiftUI 构建，性能卓越 |
| ⚙️ **高级设置** | 可自定义复习选项、同步设置和调试工具 |

## 📥 安装方法

### 侧载安装（推荐）

Anji 以未签名 IPA 形式分发。你可以使用以下工具安装：

| 工具 | 费用 | 是否需要电脑 | 说明 |
|------|------|-------------|------|
| [SideStore](https://sidestore.io/) | 免费 | 仅需初次设置 | 推荐 - 设置后无需电脑 |
| [Sideloadly](https://sideloadly.io/) | 免费 | 是 | 通过 USB 连接 |
| [AltStore](https://altstore.io/) | 免费 | 是 | 流行的替代方案 |
| ESign / Scarlet | 付费 | 否 | 使用开发者证书 |

📦 **[下载最新 IPA →](https://github.com/yingluom/anji/releases/latest)**

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI 视图层 (iOS 18+)                               │
│  - 复习界面                                             │
│  - 统计图表                                             │
│  - 设置与浏览器                                         │
└─────────────────────────────────────────────────────────┘
                          ↕ @DependencyClient
┌─────────────────────────────────────────────────────────┐
│  AnkiClients （面向应用的接口层）                       │
│  使用 swift-dependencies 的类型安全接口                   │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│  AnkiServices （业务逻辑层）                            │
│  同步、复习、统计、媒体管理                               │
└─────────────────────────────────────────────────────────┘
                          ↕ Protocol Buffers
┌─────────────────────────────────────────────────────────┐
│  AnkiBackend （Swift FFI 封装）                         │
│  绑定到 Rust 库的 C ABI                                   │
└─────────────────────────────────────────────────────────┘
                          ↕ C ABI
┌─────────────────────────────────────────────────────────┐
│  Rust (ankitects/anki rslib)                            │
│  - SQLite 存储                                          │
│  - AnkiWeb 同步协议                                     │
│  - FSRS 调度器                                          │
│  - 卡片渲染引擎                                         │
└─────────────────────────────────────────────────────────┘
```

**关键 FFI 函数：**
- `anki_open_backend` / `anki_close_backend`
- `anki_run_method`（protobuf 请求 → 响应）
- `anki_free_response`

## 🛠️ 从源码构建

### 环境要求

- macOS 系统，安装 Xcode 16+（iOS 18 SDK）
- Rust 工具链，带 iOS 目标支持
- Homebrew 包管理器

```bash
# 安装 Rust iOS 目标
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# 安装必需工具
brew install protobuf swift-protobuf xcodegen
```

### 构建步骤

```bash
# 1. 克隆（包含子模块）
git clone --recurse-submodules https://github.com/yingluom/anji.git
cd anji

# 2. 构建 Rust XCFramework
./scripts/build-xcframework.sh

# 3. 生成 Swift protobuf 类型
./scripts/generate-protos.sh

# 4. 生成 Xcode 项目
cd AnjiApp && xcodegen generate && cd ..

# 5. 在 Xcode 中打开
open AnjiApp/AnjiApp.xcodeproj
```

## 🚀 持续集成

由 [Codemagic](https://codemagic.io) 提供自动化构建：

- ✅ 每次提交触发完整构建
- ✅ 产出未签名 IPA 文件
- ✅ 运行单元测试和代码检查

详见 [`codemagic.yaml`](codemagic.yaml) 配置。

## 📄 许可证

**AGPL-3.0** — 本项目使用 [ankitects/anki](https://github.com/ankitects/anki) Rust 后端，其采用 AGPL-3.0 许可证。所有衍生作品必须遵守此许可证。

## 🤝 参与贡献

欢迎贡献代码！在提交 PR 之前，请先阅读我们的[贡献指南](CONTRIBUTING.md)。

## 🙏 致谢

- [Anki](https://apps.ankiweb.net/) by Damien Elmes - 原创的间隔重复软件
- [ankitects/anki](https://github.com/ankitects/anki) - 官方 Anki Rust 后端
- [PointFree](https://www.pointfree.co/) - 提供 swift-dependencies 和优秀的 Swift 库

---

<p align="center">
  用 ❤️ 为全球学习者打造
</p>
