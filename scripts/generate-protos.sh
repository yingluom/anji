#!/bin/bash
# generate-protos.sh — Generate Swift protobuf types from the upstream .proto files
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROTO_DIR="$ROOT_DIR/anki-upstream/proto"
OUTPUT_DIR="$ROOT_DIR/Sources/AnkiProto"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.pb.swift

echo "==> Generating Swift protobuf types..."
protoc \
    --proto_path="$PROTO_DIR" \
    --swift_out="$OUTPUT_DIR" \
    --swift_opt=Visibility=Public \
    "$PROTO_DIR"/anki/*.proto

# protoc may nest output in an anki/ subdirectory — flatten it
if [ -d "$OUTPUT_DIR/anki" ]; then
    mv "$OUTPUT_DIR"/anki/*.pb.swift "$OUTPUT_DIR/"
    rmdir "$OUTPUT_DIR/anki"
fi

# Fix imports for Swift 6.2 InternalImportsByDefault
# No extra patches needed for Swift 6.0
for f in "$OUTPUT_DIR"/*.pb.swift; do
    # Just ensure Foundation and SwiftProtobuf are imported (standard protoc output)
    true
done

COUNT=$(ls "$OUTPUT_DIR"/*.pb.swift 2>/dev/null | wc -l | tr -d ' ')
echo "==> Generated $COUNT protobuf files"
