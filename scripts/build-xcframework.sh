#!/bin/bash
# build-xcframework.sh — Cross-compile the Rust bridge and package as XCFramework.
# Simple, reliable version: builds device + simulator in parallel, packages the result.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BRIDGE_DIR="$ROOT_DIR/anki-bridge-rs"
UPSTREAM_DIR="$ROOT_DIR/anki-upstream"
HEADER_DIR="$BRIDGE_DIR/include"
OUTPUT_DIR="$ROOT_DIR/AnkiRust.xcframework"

export PROTOC="${PROTOC:-$(command -v protoc || echo /opt/homebrew/bin/protoc)}"
export IPHONEOS_DEPLOYMENT_TARGET="17.0"

# ---- Sanity checks -------------------------------------------------------
[ -x "$PROTOC" ]             || { echo "ERROR: protoc not found (set PROTOC or install protobuf)"; exit 1; }
[ -d "$UPSTREAM_DIR/rslib" ] || { echo "ERROR: anki-upstream submodule missing; run git submodule update --init --recursive"; exit 1; }
command -v cargo >/dev/null  || { echo "ERROR: cargo not found; source \$HOME/.cargo/env"; exit 1; }

echo "==> protoc:  $PROTOC"
echo "==> cargo:   $(cargo --version)"

# ---- Build both targets in parallel --------------------------------------
echo "==> Building device + simulator in parallel..."
(
    cargo build --manifest-path "$BRIDGE_DIR/Cargo.toml" \
        --target aarch64-apple-ios --release 2>&1 | sed 's/^/[device] /'
) &
DEVICE_PID=$!
(
    cargo build --manifest-path "$BRIDGE_DIR/Cargo.toml" \
        --target aarch64-apple-ios-sim --release 2>&1 | sed 's/^/[sim]    /'
) &
SIM_PID=$!

wait "$DEVICE_PID" || { echo "ERROR: device build failed"; kill "$SIM_PID" 2>/dev/null || true; exit 1; }
wait "$SIM_PID"    || { echo "ERROR: simulator build failed"; exit 1; }

DEVICE_LIB="$BRIDGE_DIR/target/aarch64-apple-ios/release/libanki_bridge_ios.a"
SIM_LIB="$BRIDGE_DIR/target/aarch64-apple-ios-sim/release/libanki_bridge_ios.a"

[ -f "$DEVICE_LIB" ] || { echo "ERROR: device lib not at $DEVICE_LIB"; exit 1; }
[ -f "$SIM_LIB" ]    || { echo "ERROR: simulator lib not at $SIM_LIB"; exit 1; }

echo "==> Device lib:    $(du -h "$DEVICE_LIB" | cut -f1)"
echo "==> Simulator lib: $(du -h "$SIM_LIB" | cut -f1)"

# ---- Package as XCFramework ----------------------------------------------
echo "==> Packaging XCFramework..."
rm -rf "$OUTPUT_DIR"
xcodebuild -create-xcframework \
    -library "$DEVICE_LIB" -headers "$HEADER_DIR" \
    -library "$SIM_LIB"    -headers "$HEADER_DIR" \
    -output "$OUTPUT_DIR"

# Inject module maps so Swift can `import AnkiRustLib`
echo "==> Injecting module maps..."
for HEADERS in "$OUTPUT_DIR"/*/Headers; do
    cat > "$HEADERS/module.modulemap" <<'EOF'
module AnkiRustLib {
    header "anki_bridge.h"
    export *
}
EOF
done

echo "==> Done: $OUTPUT_DIR"
du -sh "$OUTPUT_DIR"
