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

**Study Interface**
- Clean, distraction-free review interface
- Support for all Anki card types: Standard, Cloze, Type-in answers, and more
- Rich media support: Images, audio, and video playback in cards
- Night mode and three theme variants (Light, Dark, System)

**Statistics & Analytics**
- Today Overview: See due cards, reviews completed, and study time
- Forecast Chart: Visualize upcoming review workload
- Review History: Track your learning progress over time
- Intervals & Ease Charts: Understand card difficulty distributions

**Localization**
- Full English and Simplified Chinese interface
- RTL language support preparation
- Locale-aware date and number formatting

## Installation

### Sideload (Recommended)

Anji is distributed as an unsigned IPA. You can install it using one of the following tools:

| Tool | Cost | Computer Required | Notes |
|------|------|-------------------|-------|
| [SideStore](https://sidestore.io/) | Free | Once for setup | Recommended - no computer needed after initial setup |
| [Sideloadly](https://sideloadly.io/) | Free | Yes | Via USB connection |
| [AltStore](https://altstore.io/) | Free | Yes | Popular alternative |
| ESign / Scarlet | Paid | No | Uses developer certificates |

[Download Latest IPA](https://github.com/yingluom/anji/releases/latest)

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

## Continuous Integration

Automated builds powered by [Codemagic](https://codemagic.io):

- Every commit triggers a full build
- Produces unsigned IPA artifacts
- Runs unit tests and linting

See [`codemagic.yaml`](codemagic.yaml) for configuration.

## License

**AGPL-3.0** — This project uses the [ankitects/anki](https://github.com/ankitects/anki) Rust backend, which is licensed under AGPL-3.0. All derivative work must comply with this license.

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

## Acknowledgments

- [Anki](https://apps.ankiweb.net/) by Damien Elmes - The original spaced repetition software
- [ankitects/anki](https://github.com/ankitects/anki) - The official Anki Rust backend
- [PointFree](https://www.pointfree.co/) - For swift-dependencies and excellent Swift libraries

---

<p align="center">
  Made for learners worldwide
</p>
