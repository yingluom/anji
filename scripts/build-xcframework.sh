#!/bin/bash
# Cross-compile anki-bridge-rs for iOS (device + simulator) and package as XCFramework.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BRIDGE_DIR="$ROOT_DIR/anki-bridge-rs"
HEADER_DIR="$BRIDGE_DIR/include"
OUTPUT_DIR="$ROOT_DIR/AnkiRust.xcframework"

export PROTOC="${PROTOC:-$(command -v protoc)}"
export IPHONEOS_DEPLOYMENT_TARGET="17.0"

echo "==> PROTOC: $PROTOC"
echo "==> Building aarch64-apple-ios (device)..."
cargo build --manifest-path "$BRIDGE_DIR/Cargo.toml" \
    --target aarch64-apple-ios --release

echo "==> Building aarch64-apple-ios-sim (simulator)..."
cargo build --manifest-path "$BRIDGE_DIR/Cargo.toml" \
    --target aarch64-apple-ios-sim --release

DEVICE_LIB="$BRIDGE_DIR/target/aarch64-apple-ios/release/libanki_bridge_ios.a"
SIM_LIB="$BRIDGE_DIR/target/aarch64-apple-ios-sim/release/libanki_bridge_ios.a"

[ -f "$DEVICE_LIB" ] || { echo "ERROR: device lib missing"; exit 1; }
[ -f "$SIM_LIB" ]    || { echo "ERROR: simulator lib missing"; exit 1; }

echo "==> Packaging XCFramework..."
rm -rf "$OUTPUT_DIR"
xcodebuild -create-xcframework \
    -library "$DEVICE_LIB" -headers "$HEADER_DIR" \
    -library "$SIM_LIB"    -headers "$HEADER_DIR" \
    -output "$OUTPUT_DIR"

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
