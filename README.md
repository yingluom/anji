# Anji

<p align="center">
  <img src="AnjiApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Anji Logo">
</p>

<p align="center">
  <strong>An iOS flashcard app powered by the official Anki Rust backend</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_CN.md">简体中文</a> | <a href="README_JP.md">日本語</a>
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

## Features

Anji provides a complete set of features for effective spaced repetition learning:

**Sync & Data**
- AnkiWeb Sync: Full bidirectional synchronization for both collection data and media files
- Incremental sync with progress tracking
- Media file integrity verification with MD5 checksums
- Automatic download of missing or corrupted media files

**Learning System**
- FSRS Algorithm: Next-generation spaced repetition scheduling algorithm for optimal retention
- Card Browser: Search, filter, and manage your cards with advanced query support
- Custom Study: Create filtered decks for focused review sessions
- Tag Management: Organize cards with hierarchical tags
- **Smart Card Editor**: Field categorization, tags management, formatting toolbar, multi-language support

**Study Interface**
- Clean, distraction-free review interface
- Support for all Anki card types: Standard, Cloze, Type-in answers, and more
- Rich media support: Images, audio, and video playback in cards
- Night mode and three theme variants (Light, Dark, System)
- **Undo/Redo**: Reverse last review action
- **Live Activity**: Dynamic Island & Lock Screen widget support (iOS 16.1+)

**Statistics & Analytics**
- Today Overview: See due cards, reviews completed, and study time
- Forecast Chart: Visualize upcoming review workload
- Review History: Track your learning progress over time
- Intervals & Ease Charts: Understand card difficulty distributions
- **10+ Stat Cards**: Retention, card counts, streaks, and more
- **Customizable Home**: Choose which statistics appear on the main deck list

**Daily Inspiration**
- **Daily Quote**: Toggle daily quotes from Hitokoto/Jinrishici APIs
- **Multiple Quote Providers**: Switch between different quote sources

**Localization**
- Full English, Simplified Chinese, Traditional Chinese, and Japanese interface
- RTL language support preparation
- Locale-aware date and number formatting

## Download

Get the latest pre-built IPA from GitHub Releases:

<p align="center">
  <a href="https://github.com/yingluom/anji/releases/latest">
    <img src="https://img.shields.io/github/v/release/yingluom/anji?label=Download%20IPA&color=blue&style=for-the-badge" alt="Download Latest Release">
  </a>
</p>

| Release Type | Link | Description |
|-------------|------|-------------|
| **Latest Stable** | [Releases](https://github.com/yingluom/anji/releases/latest) | Production-ready builds |
| **All Releases** | [Releases](https://github.com/yingluom/anji/releases) | Version history |
| **Nightly** | [Codemagic](https://codemagic.io) | Latest CI artifacts |

### System Requirements

- iOS 18.0 or later
- iPhone or iPad
- ~200MB free space

## Installation

### Sideload (Recommended)

Anji is distributed as an unsigned IPA. You can install it using one of the following tools:

#### 1. SideStore (Recommended ⭐)
The best option for most users. No computer required after initial setup.

1. Install [SideStore](https://sidestore.io/) on your device
2. Download the latest `AnjiApp-unsigned.ipa`
3. Open SideStore → "My Apps" → "+" → Select the IPA
4. Sign in with your Apple ID (free developer account)

#### 2. Sideloadly (Free, Computer Required)
Good for one-time installations via USB.

1. Download [Sideloadly](https://sideloadly.io/) for Windows/macOS
2. Connect your device via USB
3. Drag the IPA into Sideloadly
4. Enter your Apple ID and install

#### 3. AltStore (Free, Computer Required)
Popular alternative with auto-refresh.

1. Install [AltStore](https://altstore.io/) on your computer
2. Connect device and install AltStore
3. Open AltStore on device → "My Apps" → "+"
4. Select the downloaded IPA

#### 4. ESign / Scarlet (Paid Certificates)
No computer needed, uses enterprise certificates.

| Tool | Cost | Computer | Auto-Refresh | Notes |
|------|------|----------|--------------|-------|
| [SideStore](https://sidestore.io/) | Free | Once | ✅ 7 days | **Recommended** |
| [Sideloadly](https://sideloadly.io/) | Free | Always | ❌ Manual | Simple USB install |
| [AltStore](https://altstore.io/) | Free | Always | ✅ WiFi | Popular alternative |
| ESign / Scarlet | Paid | No | ✅ 1 year | Uses certificates |

## Architecture

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

## Build from Source

### Requirements

- macOS 14+ (Sonoma or later)
- Xcode 16+ with iOS 18 SDK
- Rust toolchain (stable)
- Homebrew

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# Install build tools
brew install protobuf swift-protobuf xcodegen
```

### Quick Build (Recommended)

One command to clone, set permissions, and build:

```bash
git clone --recurse-submodules https://github.com/yingluom/anji.git && cd anji && bash scripts/build-local.sh
```

The script automatically handles `chmod`, submodule initialization, dependency checks, Rust compilation, protobuf generation, Xcode project setup, archiving, and IPA packaging.

Other modes:

```bash
bash scripts/build-local.sh --skip-rust  # Reuse existing XCFramework
bash scripts/build-local.sh --sim        # Simulator build (fast iteration)
bash scripts/build-local.sh --clean      # Clean all artifacts and rebuild
```

Build logs are saved to `build/build.log`. On failure, errors are displayed with file paths and line numbers. Output IPA is at `build/AnjiApp-unsigned.ipa`.

### Manual Build Steps

If you prefer to run each step yourself:

```bash
git clone --recurse-submodules https://github.com/yingluom/anji.git
cd anji

# 1. Build Rust XCFramework (device + simulator)
./scripts/build-xcframework.sh

# 2. Generate Swift protobuf types from upstream .proto files
./scripts/generate-protos.sh

# 3. Generate Xcode project from project.yml
cd AnjiApp && xcodegen generate && cd ..

# 4. Open in Xcode and build
open AnjiApp/AnjiApp.xcodeproj
```

## Screenshots

<p align="center">
  <img src="screenshots/deck_list.png" width="200" alt="Deck List">
  <img src="screenshots/review_mode.png" width="200" alt="Review Mode">
  <img src="screenshots/card_editor.png" width="200" alt="Card Editor">
  <img src="screenshots/statistics.png" width="200" alt="Statistics">
</p>

> Note: Add your screenshots to the `screenshots/` folder

## Continuous Integration

Automated builds powered by [Codemagic](https://codemagic.io):

- Every commit triggers a full build
- Produces unsigned IPA artifacts
- Runs unit tests and linting

See [`codemagic.yaml`](codemagic.yaml) and [`.github/workflows/`](.github/workflows/) for CI configuration.

## License

**AGPL-3.0** — This project uses the [ankitects/anki](https://github.com/ankitects/anki) Rust backend, which is licensed under AGPL-3.0. All derivative work must comply with this license.

## Tech Stack

- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: Swift Dependencies + The Composable Architecture patterns
- **Backend**: Rust FFI (Anki rslib)
- **Sync Protocol**: AnkiWeb REST API
- **CI/CD**: GitHub Actions + Codemagic

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

### Quick Start for Contributors

```bash
# Fork and clone
git clone --recurse-submodules https://github.com/YOUR_USERNAME/anji.git
cd anji

# Build everything
bash scripts/build-local.sh

# Or open in Xcode for development
cd AnjiApp && xcodegen generate && open AnjiApp.xcodeproj
```

## Acknowledgments

- [Anki](https://apps.ankiweb.net/) by Damien Elmes - The original spaced repetition software
- [ankitects/anki](https://github.com/ankitects/anki) - The official Anki Rust backend
- [PointFree](https://www.pointfree.co/) - For swift-dependencies and excellent Swift libraries
- [Swift Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) - Architecture inspiration

---

<p align="center">
  <sub>Made with ❤️ for learners worldwide</sub>
</p>

---

<p align="center">
  Made for learners worldwide
</p>
