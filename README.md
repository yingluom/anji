# Anji

An iOS flashcard app powered by the official [Anki](https://github.com/ankitects/anki) Rust backend.

> **License**: AGPL-3.0 (required by the ankitects/anki dependency)

## Features

- 🔄 **AnkiWeb sync** — Full bi-directional sync with AnkiWeb (collection + media)
- 🧠 **FSRS scheduling** — State-of-the-art spaced repetition via the official Anki scheduler
- 📚 **Deck browser** — Hierarchical deck tree with new/learn/review counts
- ✏️ **Note editor** — Search and edit your notes
- 📊 **Statistics** — Review history powered by the Anki stats engine
- 📦 **Import/Export** — `.apkg` and `.colpkg` support

## Architecture

```
SwiftUI Views
    ↕ @DependencyClient
AnkiClients  (app-facing interface)
    ↕
AnkiServices (backend service layer)
    ↕
AnkiBackend  (Swift FFI wrapper)
    ↕  protobuf over C ABI
Rust (ankitects/anki rslib)
    — SQLite, sync protocol, FSRS, card rendering
```

All data operations go through the Rust backend via 4 C functions:
- `anki_open_backend` / `anki_close_backend`
- `anki_run_method` (protobuf request → protobuf response)
- `anki_free_response`

## Build Requirements

- Xcode 16+
- Rust + `aarch64-apple-ios` + `aarch64-apple-ios-sim` targets
- `protobuf` + `swift-protobuf` (for proto generation)
- `xcodegen`

## Build Steps

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

## CI/CD

The project builds on [Codemagic](https://codemagic.io).
See `codemagic.yaml` for the full pipeline configuration.
The CI run installs Rust, compiles the XCFramework, generates protos, and produces an unsigned IPA.

## Sync Setup

On first launch, choose AnkiWeb sync and sign in with your AnkiWeb email and password.
The app stores your auth token securely in the iOS Keychain.
