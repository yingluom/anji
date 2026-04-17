#!/bin/bash
# generate-protos.sh — Generate Swift protobuf types from upstream .proto files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROTO_DIR="$ROOT_DIR/anki-upstream/proto"
OUTPUT_DIR="$ROOT_DIR/Sources/AnkiProto"

# ---- Sanity checks ------------------------------------------------------
command -v protoc >/dev/null || { echo "ERROR: protoc not found (brew install protobuf)"; exit 1; }
command -v protoc-gen-swift >/dev/null || {
    echo "ERROR: protoc-gen-swift not found (brew install swift-protobuf)"
    exit 1
}
[ -d "$PROTO_DIR/anki" ] || {
    echo "ERROR: proto files missing at $PROTO_DIR/anki"
    echo "       Run: git submodule update --init --recursive"
    exit 1
}

echo "==> protoc:            $(protoc --version)"
echo "==> protoc-gen-swift:  $(protoc-gen-swift --version 2>/dev/null || echo 'installed')"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.pb.swift

# ---- Generate -----------------------------------------------------------
echo "==> Generating Swift protobuf types..."
protoc \
    --proto_path="$PROTO_DIR" \
    --swift_out="$OUTPUT_DIR" \
    --swift_opt=Visibility=Public \
    "$PROTO_DIR"/anki/*.proto

# protoc nests output in an anki/ subdirectory — flatten it
if [ -d "$OUTPUT_DIR/anki" ]; then
    mv "$OUTPUT_DIR"/anki/*.pb.swift "$OUTPUT_DIR/"
    rmdir "$OUTPUT_DIR/anki"
fi

COUNT=$(find "$OUTPUT_DIR" -maxdepth 1 -name '*.pb.swift' | wc -l | tr -d ' ')
if [ "$COUNT" -eq 0 ]; then
    echo "ERROR: no .pb.swift files were generated"
    exit 1
fi
echo "==> Generated $COUNT protobuf files in $OUTPUT_DIR"
