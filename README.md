# Anji

An iOS flashcard app powered by the official [Anki](https://github.com/ankitects/anki) Rust backend.
Compatible with AnkiWeb sync, supporting images, audio, and cloze deletions.

> **License**: AGPL-3.0 (required by the ankitects/anki dependency)

## Features

- 🔄 **AnkiWeb Sync** — Full bi-directional sync (collection + media files)
- 🧠 **FSRS Scheduling** — State-of-the-art spaced repetition algorithm
- 📊 **Statistics** — Today, Forecast, Review History, Intervals, and Ease charts
- 🎨 **Themes** — Light/Dark/System mode with 6 accent color choices
- 🌐 **Bilingual** — English and 简体中文 (Simplified Chinese) interface
- 🎵 **Media Support** — Images and audio playback in cards
- ⚙️ **Settings** — Language, theme, sync options, and debug tools

## Installation

### Sideload (Recommended)

The CI produces an unsigned IPA that can be sideloaded with:
- [SideStore](https://sidestore.io/) (free, no computer required after initial setup)
- [Sideloadly](https://sideloadly.io/) (free, via computer)
- [AltStore](https://altstore.io/) (free)
- ESign / Scarlet / Feather (paid developer certificate method)

Download the latest IPA from the [Releases](https://github.com/yingluom/anji/releases) page.

## Architecture

```
SwiftUI Views (iOS 18+)
    ↕ @DependencyClient (swift-dependencies)
AnkiClients  (app-facing API)
    ↕
AnkiServices (business logic)
    ↕ protobuf
AnkiBackend  (Swift FFI)
    ↕ C ABI
Rust (ankitects/anki rslib)
    — SQLite, sync protocol, FSRS, card rendering
```

All data operations go through the official Anki Rust backend via 4 C functions:
- `anki_open_backend` / `anki_close_backend`
- `anki_run_method` (protobuf request → response)
- `anki_free_response`

## Build Locally

**Requirements:**
- Xcode 16+ (iOS 18 SDK)
- Rust with iOS targets: `rustup target add aarch64-apple-ios aarch64-apple-ios-sim`
- `brew install protobuf swift-protobuf xcodegen`

**Steps:**
```bash
# 1. Clone with submodules
git clone --recurse-submodules https://github.com/yingluom/anji.git
cd anji

# 2. Build Rust XCFramework
./scripts/build-xcframework.sh

# 3. Generate Swift protobuf types
./scripts/generate-protos.sh

# 4. Generate Xcode project
cd AnjiApp && xcodegen generate && cd ..

# 5. Open and build
open AnjiApp/AnjiApp.xcodeproj
```

## CI/CD

Automated builds on [Codemagic](https://codemagic.io) — see `codemagic.yaml`.
Each commit triggers a full build producing an unsigned IPA.

---

# Anji (中文)

基于官方 [Anki](https://github.com/ankitects/anki) Rust 后端的 iOS 记忆卡片应用。
支持 AnkiWeb 同步、图片音频、填空题等多种卡片格式。

> **许可证**: AGPL-3.0（因依赖 ankitects/anki）

## 功能特性

- 🔄 **AnkiWeb 同步** — 完整的双向同步（牌组 + 媒体文件）
- 🧠 **FSRS 算法** — 最先进的间隔重复调度算法
- 📊 **统计图表** — 今日概览、预测、复习历史、间隔分布、简易度
- 🎨 **主题系统** — 浅色/深色/跟随系统，6 种强调色可选
- 🌐 **中英双语** — 支持 English 和 简体中文界面
- 🎵 **媒体支持** — 卡片内显示图片、播放音频
- ⚙️ **详细设置** — 语言、主题、同步选项、调试工具

## 安装方法

### 侧载安装（推荐）

CI 构建的未签名 IPA 可通过以下工具安装：
- [SideStore](https://sidestore.io/)（免费，初次设置后无需电脑）
- [Sideloadly](https://sideloadly.io/)（免费，需电脑）
- [AltStore](https://altstore.io/)（免费）
- ESign / Scarlet / Feather（付费开发者证书方式）

从 [Releases](https://github.com/yingluom/anji/releases) 下载最新 IPA。

## 技术架构

```
SwiftUI 视图层 (iOS 18+)
    ↕ @DependencyClient (swift-dependencies)
AnkiClients  （面向应用的接口层）
    ↕
AnkiServices （业务逻辑层）
    ↕ protobuf
AnkiBackend  （Swift FFI 封装）
    ↕ C ABI
Rust (ankitects/anki rslib)
    — SQLite、同步协议、FSRS、卡片渲染
```

所有数据操作均通过官方 Anki Rust 后端完成，通过 4 个 C 函数交互：
- `anki_open_backend` / `anki_close_backend`
- `anki_run_method`（protobuf 请求 → 响应）
- `anki_free_response`

## 本地构建

**环境要求：**
- Xcode 16+（iOS 18 SDK）
- Rust 并安装 iOS 目标：`rustup target add aarch64-apple-ios aarch64-apple-ios-sim`
- `brew install protobuf swift-protobuf xcodegen`

**构建步骤：**
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

# 5. 打开并构建
open AnjiApp/AnjiApp.xcodeproj
```

## 持续集成

使用 [Codemagic](https://codemagic.io) 自动构建，配置见 `codemagic.yaml`。
每次提交触发完整构建，产出未签名 IPA。
