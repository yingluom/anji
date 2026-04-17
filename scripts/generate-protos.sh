#!/bin/bash
# Generate Swift protobuf types from upstream .proto files.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROTO_DIR="$ROOT_DIR/anki-upstream/proto"
OUTPUT_DIR="$ROOT_DIR/Sources/AnkiProto"

command -v protoc >/dev/null             || { echo "ERROR: protoc not found"; exit 1; }
command -v protoc-gen-swift >/dev/null   || { echo "ERROR: protoc-gen-swift not found"; exit 1; }
[ -d "$PROTO_DIR/anki" ]                 || { echo "ERROR: anki-upstream/proto/anki missing"; exit 1; }

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.pb.swift

echo "==> Generating Swift protobuf types..."
protoc \
    --proto_path="$PROTO_DIR" \
    --swift_out="$OUTPUT_DIR" \
    --swift_opt=Visibility=Public \
    "$PROTO_DIR"/anki/*.proto

# protoc nests output under anki/ — flatten
if [ -d "$OUTPUT_DIR/anki" ]; then
    mv "$OUTPUT_DIR"/anki/*.pb.swift "$OUTPUT_DIR/"
    rmdir "$OUTPUT_DIR/anki"
fi

COUNT=$(find "$OUTPUT_DIR" -maxdepth 1 -name '*.pb.swift' | wc -l | tr -d ' ')
echo "==> Generated $COUNT .pb.swift files in $OUTPUT_DIR"
[ "$COUNT" -gt 0 ] || { echo "ERROR: no files generated"; exit 1; }
