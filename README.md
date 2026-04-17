# Anji

<p align="center">
  <img src="AnjiApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Anji Logo">
</p>

<p align="center">
  <strong>An iOS flashcard app powered by the official Anki Rust backend</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_CN.md">简体中文</a>
</p>

<p align="center">
  <a href="https://github.com/yingluom/anji/releases">
    <img src="https://img.shields.io/github/v/release/yingluom/anji?color=blue" alt="Release">
  </a>
  <a href="https://github.com/yingluom/anji/actions">
    <img src="https://img.shields.io/github/workflow/status/yingluom/anji/CI?label=CI" alt="CI">
  </a>
  <img src="https://img.shields.io/badge/iOS-18+-blue?logo=apple" alt="iOS 18+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-AGPL--3.0-green" alt="License">
  </a>
</p>

---

Anji is an open-source iOS flashcard application that brings the full power of [Anki](https://apps.ankiweb.net/) to your iPhone and iPad. Built on the official Anki Rust backend (`rslib`), it ensures 100% compatibility with AnkiWeb sync, FSRS scheduling, and all Anki card features.

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 **AnkiWeb Sync** | Full bidirectional sync for collections and media files |
| 🧠 **FSRS Algorithm** | Next-generation spaced repetition scheduling |
| 📊 **Statistics** | Today overview, Forecast, Review History, Intervals, and Ease charts |
| 🎨 **Beautiful Themes** | Light/Dark/System mode with 6 accent colors |
| 🌐 **Bilingual UI** | English and Simplified Chinese interface |
| 🎵 **Rich Media** | Images, audio, and video support in cards |
| 🔍 **Card Browser** | Search, filter, and manage your cards |
| 📱 **Native iOS** | Built with SwiftUI for optimal performance |
| ⚙️ **Advanced Settings** | Customizable review options, sync settings, and debug tools |

## 📥 Installation

### Sideload (Recommended)

Anji is distributed as an unsigned IPA. You can install it using:

| Tool | Cost | Computer Required | Notes |
|------|------|-------------------|-------|
| [SideStore](https://sidestore.io/) | Free | Once for setup | Recommended - no computer needed after initial setup |
| [Sideloadly](https://sideloadly.io/) | Free | Yes | Via USB connection |
| [AltStore](https://altstore.io/) | Free | Yes | Popular alternative |
| ESign / Scarlet | Paid | No | Uses developer certificates |

📦 **[Download Latest IPA →](https://github.com/yingluom/anji/releases/latest)**

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI Views (iOS 18+)                                │
│  - Review Interface                                     │
│  - Statistics & Charts                                  │
│  - Settings & Browser                                   │
└─────────────────────────────────────────────────────────┘
                          ↕ @DependencyClient
┌─────────────────────────────────────────────────────────┐
│  AnkiClients (App-facing API)                           │
│  Type-safe interfaces using swift-dependencies          │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│  AnkiServices (Business Logic)                        │
│  Sync, Review, Statistics, Media management            │
└─────────────────────────────────────────────────────────┘
                          ↕ Protocol Buffers
┌─────────────────────────────────────────────────────────┐
│  AnkiBackend (Swift FFI)                                │
│  C ABI bindings to Rust library                         │
└─────────────────────────────────────────────────────────┘
                          ↕ C ABI
┌─────────────────────────────────────────────────────────┐
│  Rust (ankitects/anki rslib)                            │
│  - SQLite storage                                       │
│  - AnkiWeb sync protocol                                │
│  - FSRS scheduler                                       │
│  - Card rendering engine                                │
└─────────────────────────────────────────────────────────┘
```

**Key FFI Functions:**
- `anki_open_backend` / `anki_close_backend`
- `anki_run_method` (protobuf request → response)
- `anki_free_response`

## 🛠️ Build from Source

### Requirements

- macOS with Xcode 16+ (iOS 18 SDK)
- Rust toolchain with iOS targets
- Homebrew packages

```bash
# Install Rust iOS targets
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# Install required tools
brew install protobuf swift-protobuf xcodegen
```

### Build Steps

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

# 5. Open in Xcode
open AnjiApp/AnjiApp.xcodeproj
```

## 🚀 Continuous Integration

Automated builds powered by [Codemagic](https://codemagic.io):

- ✅ Every commit triggers a full build
- ✅ Produces unsigned IPA artifacts
- ✅ Runs unit tests and linting

See [`codemagic.yaml`](codemagic.yaml) for configuration.

## � License

**AGPL-3.0** — This project uses the [ankitects/anki](https://github.com/ankitects/anki) Rust backend, which is licensed under AGPL-3.0. All derivative work must comply with this license.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

## 🙏 Acknowledgments

- [Anki](https://apps.ankiweb.net/) by Damien Elmes - The original spaced repetition software
- [ankitects/anki](https://github.com/ankitects/anki) - The official Anki Rust backend
- [PointFree](https://www.pointfree.co/) - For swift-dependencies and excellent Swift libraries

---

<p align="center">
  Made with ❤️ for learners worldwide
</p>
