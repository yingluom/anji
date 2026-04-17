#!/bin/bash
# ============================================================================
# Anji — Local Build Script for macOS
# Builds the complete project from source and produces an unsigned IPA.
#
# Usage:
#   ./scripts/build-local.sh              # Full build (Rust + Swift)
#   ./scripts/build-local.sh --skip-rust  # Skip Rust if XCFramework exists
#   ./scripts/build-local.sh --clean      # Clean everything and rebuild
#   ./scripts/build-local.sh --sim        # Build for simulator (debug)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/build"
LOG_FILE="$BUILD_DIR/build.log"

# Ensure all scripts are executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Flags
SKIP_RUST=false
CLEAN=false
SIM_ONLY=false

for arg in "$@"; do
  case $arg in
    --skip-rust) SKIP_RUST=true ;;
    --clean)     CLEAN=true ;;
    --sim)       SIM_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [--skip-rust] [--clean] [--sim]"
      echo "  --skip-rust  Skip Rust build if AnkiRust.xcframework exists"
      echo "  --clean      Remove all build artifacts and rebuild"
      echo "  --sim        Build for simulator in Debug mode"
      exit 0
      ;;
  esac
done

# ---------- Helpers ----------

step() { echo -e "\n${CYAN}${BOLD}==> $1${NC}"; }
ok()   { echo -e "${GREEN}    $1${NC}"; }
warn() { echo -e "${YELLOW}    WARNING: $1${NC}"; }
fail() { echo -e "${RED}    ERROR: $1${NC}"; exit 1; }

timer_start() { STEP_START=$(date +%s); }
timer_end()   { echo -e "    ${BOLD}($(( $(date +%s) - STEP_START ))s)${NC}"; }

# ---------- Preflight ----------

step "Checking prerequisites"
MISSING=()
command -v rustup    >/dev/null || MISSING+=("rustup (https://rustup.rs)")
command -v cargo     >/dev/null || MISSING+=("cargo")
command -v protoc    >/dev/null || MISSING+=("protoc (brew install protobuf)")
command -v protoc-gen-swift >/dev/null || MISSING+=("protoc-gen-swift (brew install swift-protobuf)")
command -v xcodegen  >/dev/null || MISSING+=("xcodegen (brew install xcodegen)")
command -v xcodebuild >/dev/null || MISSING+=("xcodebuild (install Xcode)")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${RED}Missing tools:${NC}"
  for tool in "${MISSING[@]}"; do echo "  - $tool"; done
  echo ""
  echo "Install all at once:"
  echo "  brew install protobuf swift-protobuf xcodegen"
  echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  echo "  rustup target add aarch64-apple-ios aarch64-apple-ios-sim"
  exit 1
fi

ok "rustc $(rustc --version | awk '{print $2}')"
ok "protoc $(protoc --version | awk '{print $2}')"
ok "xcodegen $(xcodegen --version 2>&1 | head -1)"
ok "Xcode $(xcodebuild -version | head -1)"

# ---------- Clean ----------

if $CLEAN; then
  step "Cleaning build artifacts"
  rm -rf "$BUILD_DIR"
  rm -rf "$ROOT_DIR/AnkiRust.xcframework"
  rm -rf "$ROOT_DIR/AnjiApp/AnjiApp.xcodeproj"
  rm -f "$ROOT_DIR/Sources/AnkiProto"/*.pb.swift
  ok "Clean complete"
fi

mkdir -p "$BUILD_DIR"

# ---------- Submodules ----------

step "Updating submodules"
timer_start
cd "$ROOT_DIR"
git submodule update --init --recursive
timer_end

# ---------- Rust XCFramework ----------

XCFW="$ROOT_DIR/AnkiRust.xcframework"

if $SKIP_RUST && [ -d "$XCFW" ]; then
  step "Skipping Rust build (XCFramework exists)"
  ok "$XCFW"
else
  step "Building Rust XCFramework"
  timer_start

  # Ensure iOS targets are installed
  rustup target add aarch64-apple-ios aarch64-apple-ios-sim 2>/dev/null || true

  bash "$SCRIPT_DIR/build-xcframework.sh"
  timer_end

  [ -d "$XCFW" ] || fail "XCFramework not found after build"
  ok "$(du -sh "$XCFW" | cut -f1) — $XCFW"
fi

# ---------- Protobuf Generation ----------

step "Generating Swift protobuf types"
timer_start
bash "$SCRIPT_DIR/generate-protos.sh"
PB_COUNT=$(find "$ROOT_DIR/Sources/AnkiProto" -name '*.pb.swift' | wc -l | tr -d ' ')
timer_end
ok "$PB_COUNT .pb.swift files generated"

# ---------- Xcode Project ----------

step "Generating Xcode project"
timer_start
cd "$ROOT_DIR/AnjiApp"
xcodegen generate
cd "$ROOT_DIR"
timer_end
ok "AnjiApp.xcodeproj"

# ---------- Trust macros ----------

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES 2>/dev/null || true
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES 2>/dev/null || true

# ---------- Build ----------

if $SIM_ONLY; then
  step "Building for Simulator (Debug)"
  timer_start
  xcodebuild build \
    -project AnjiApp/AnjiApp.xcodeproj \
    -scheme AnjiApp \
    -configuration Debug \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -skipMacroValidation \
    -skipPackagePluginValidation \
    -parallelizeTargets \
    COMPILER_INDEX_STORE_ENABLE=NO \
    2>&1 | tee "$LOG_FILE"

  RESULT=${PIPESTATUS[0]}
  timer_end

  if [ $RESULT -ne 0 ]; then
    echo ""
    echo -e "${RED}${BOLD}========== BUILD ERRORS ==========${NC}"
    grep -n "error:" "$LOG_FILE" | head -20
    echo ""
    grep -B2 -A3 "error:" "$LOG_FILE" | head -60
    echo -e "${RED}${BOLD}==================================${NC}"
    echo -e "Full log: ${BOLD}$LOG_FILE${NC}"
    exit $RESULT
  fi

  ok "Simulator build succeeded"
  echo -e "\nRun in Xcode: ${BOLD}open AnjiApp/AnjiApp.xcodeproj${NC}"
  exit 0
fi

step "Archiving for iOS device (Release)"
timer_start
xcodebuild archive \
  -project AnjiApp/AnjiApp.xcodeproj \
  -scheme AnjiApp \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$BUILD_DIR/AnjiApp.xcarchive" \
  -skipMacroValidation \
  -skipPackagePluginValidation \
  -parallelizeTargets \
  DEBUG_INFORMATION_FORMAT=dwarf \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES \
  AD_HOC_CODE_SIGNING_ALLOWED=YES \
  ENABLE_BITCODE=NO \
  DEVELOPMENT_TEAM="" \
  COMPILER_INDEX_STORE_ENABLE=NO \
  2>&1 | tee "$LOG_FILE"

RESULT=${PIPESTATUS[0]}
timer_end

if [ $RESULT -ne 0 ]; then
  echo ""
  echo -e "${RED}${BOLD}========== BUILD ERRORS ==========${NC}"
  grep -n "error:" "$LOG_FILE" | head -20
  echo ""
  echo -e "${RED}${BOLD}========== ERROR CONTEXT ==========${NC}"
  grep -B2 -A3 "error:" "$LOG_FILE" | head -60
  echo -e "${RED}${BOLD}===================================${NC}"
  echo -e "Full log: ${BOLD}$LOG_FILE${NC}"
  exit $RESULT
fi

# ---------- Package IPA ----------

step "Packaging IPA"
APP="$BUILD_DIR/AnjiApp.xcarchive/Products/Applications/AnjiApp.app"

[ -f "$APP/AnjiApp" ] || fail "Executable missing at $APP/AnjiApp"

APP_KB=$(du -sk "$APP" | cut -f1)
if [ "$APP_KB" -lt 500 ]; then
  fail "Bundle is only ${APP_KB}KB — likely an empty build"
fi

rm -rf "$BUILD_DIR/ipa"
mkdir -p "$BUILD_DIR/ipa/Payload"
cp -R "$APP" "$BUILD_DIR/ipa/Payload/"
cd "$BUILD_DIR/ipa"
zip -ry ../AnjiApp-unsigned.ipa Payload >/dev/null
cd "$ROOT_DIR"

IPA="$BUILD_DIR/AnjiApp-unsigned.ipa"
IPA_SIZE=$(du -sh "$IPA" | cut -f1)

# ---------- Summary ----------

echo ""
echo -e "${GREEN}${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}  Build Successful${NC}"
echo -e "${GREEN}${BOLD}========================================${NC}"
echo -e "  IPA:    ${BOLD}$IPA${NC}"
echo -e "  Size:   ${BOLD}$IPA_SIZE${NC}"
echo -e "  Bundle: ${BOLD}${APP_KB}KB${NC}"
echo -e "  Log:    ${BOLD}$LOG_FILE${NC}"
echo ""
echo -e "Install with SideStore / Sideloadly / AltStore"
echo ""
