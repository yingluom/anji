#!/bin/bash
# build-xcframework.sh — Cross-compile the Rust bridge and package as XCFramework.
#
# Uses a persistent cache at $ANJI_CACHE (default: $HOME/.cache/anji) so that
# Codemagic's workspace wipe doesn't invalidate build artifacts. Only
# rebuilds when the source fingerprint (bridge sources + upstream SHA) changes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BRIDGE_DIR="$ROOT_DIR/anki-bridge-rs"
UPSTREAM_DIR="$ROOT_DIR/anki-upstream"
HEADER_DIR="$BRIDGE_DIR/include"

# Workspace path (what xcodebuild expects) and persistent cache path
WS_XCFRAMEWORK="$ROOT_DIR/AnkiRust.xcframework"
CACHE_ROOT="${ANJI_CACHE:-$HOME/.cache/anji}"
CACHE_XCFRAMEWORK="$CACHE_ROOT/xcframework/AnkiRust.xcframework"
FINGERPRINT_FILE="$CACHE_ROOT/xcframework/.fingerprint"

# Cargo places outputs here (outside workspace for reliable caching on CI)
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$CACHE_ROOT/cargo-target}"

export PROTOC="${PROTOC:-$(command -v protoc || echo /opt/homebrew/bin/protoc)}"
export IPHONEOS_DEPLOYMENT_TARGET="17.0"

# ---- Sanity checks -------------------------------------------------------
[ -x "$PROTOC" ]            || { echo "ERROR: protoc not found"; exit 1; }
[ -d "$UPSTREAM_DIR/rslib" ] || { echo "ERROR: anki-upstream submodule missing"; exit 1; }
command -v cargo >/dev/null || { echo "ERROR: cargo not found"; exit 1; }

mkdir -p "$CACHE_ROOT/xcframework"

echo "==> PROTOC:             $PROTOC"
echo "==> cargo:              $(cargo --version)"
echo "==> CARGO_TARGET_DIR:   $CARGO_TARGET_DIR"
echo "==> CACHE_XCFRAMEWORK:  $CACHE_XCFRAMEWORK"

# ---- Fingerprint: skip rebuild when nothing changed ----------------------
compute_fingerprint() {
    local upstream_sha
    upstream_sha="$(cd "$UPSTREAM_DIR" && git rev-parse HEAD 2>/dev/null || echo unknown)"
    {
        echo "upstream=$upstream_sha"
        find "$BRIDGE_DIR/src" "$BRIDGE_DIR/include" -type f \( -name '*.rs' -o -name '*.h' \) -print0 \
            | xargs -0 shasum -a 256 2>/dev/null | sort
        shasum -a 256 "$BRIDGE_DIR/Cargo.toml" "$BRIDGE_DIR/Cargo.lock" 2>/dev/null || true
    } | shasum -a 256 | cut -d' ' -f1
}

CURRENT_FP="$(compute_fingerprint)"

# ---- Try cache first -----------------------------------------------------
if [ -f "$FINGERPRINT_FILE" ] && [ "$(cat "$FINGERPRINT_FILE")" = "$CURRENT_FP" ] \
   && [ -d "$CACHE_XCFRAMEWORK" ]; then
    echo "==> Cache HIT (fingerprint: ${CURRENT_FP:0:12}) — restoring from $CACHE_XCFRAMEWORK"
    rm -rf "$WS_XCFRAMEWORK"
    cp -R "$CACHE_XCFRAMEWORK" "$WS_XCFRAMEWORK"
    du -sh "$WS_XCFRAMEWORK"
    exit 0
fi
echo "==> Cache MISS (fingerprint: ${CURRENT_FP:0:12}) — rebuilding"

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

DEVICE_LIB="$CARGO_TARGET_DIR/aarch64-apple-ios/release/libanki_bridge_ios.a"
SIM_LIB="$CARGO_TARGET_DIR/aarch64-apple-ios-sim/release/libanki_bridge_ios.a"

[ -f "$DEVICE_LIB" ] || { echo "ERROR: device lib not at $DEVICE_LIB"; exit 1; }
[ -f "$SIM_LIB" ]    || { echo "ERROR: simulator lib not at $SIM_LIB"; exit 1; }

echo "==> Device lib:    $(du -h "$DEVICE_LIB" | cut -f1)"
echo "==> Simulator lib: $(du -h "$SIM_LIB" | cut -f1)"

# ---- Package as XCFramework ----------------------------------------------
echo "==> Packaging XCFramework..."
rm -rf "$WS_XCFRAMEWORK"
xcodebuild -create-xcframework \
    -library "$DEVICE_LIB" -headers "$HEADER_DIR" \
    -library "$SIM_LIB"    -headers "$HEADER_DIR" \
    -output "$WS_XCFRAMEWORK"

# Inject module maps so Swift can `import AnkiRustLib`
echo "==> Injecting module maps..."
for HEADERS in "$WS_XCFRAMEWORK"/*/Headers; do
    cat > "$HEADERS/module.modulemap" <<'EOF'
module AnkiRustLib {
    header "anki_bridge.h"
    export *
}
EOF
done

# ---- Mirror to persistent cache ------------------------------------------
echo "==> Mirroring to cache: $CACHE_XCFRAMEWORK"
rm -rf "$CACHE_XCFRAMEWORK"
mkdir -p "$(dirname "$CACHE_XCFRAMEWORK")"
cp -R "$WS_XCFRAMEWORK" "$CACHE_XCFRAMEWORK"
echo "$CURRENT_FP" > "$FINGERPRINT_FILE"

echo "==> Done: $WS_XCFRAMEWORK (fingerprint: ${CURRENT_FP:0:12})"
du -sh "$WS_XCFRAMEWORK"
