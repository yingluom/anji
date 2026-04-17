#!/bin/bash
# ============================================================================
# Anji Release Helper - Package IPA and create GitHub Release
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}ERROR: GitHub CLI (gh) not found${NC}"
    echo "Install from: https://cli.github.com/"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo -e "${RED}ERROR: Not logged in to GitHub${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get version
VERSION=$(grep -o 'MARKETING_VERSION.*=.*".*"' "$ROOT_DIR/AnjiApp/Info.plist" 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/' || echo "")
if [ -z "$VERSION" ]; then
    read -rp "Enter version (e.g., 1.0.0): " VERSION
fi

TAG="v${VERSION}"
IPA_PATH="$ROOT_DIR/build/AnjiApp-unsigned.ipa"

echo -e "${CYAN}${BOLD}Anji Release Helper${NC}"
echo "Version: $VERSION"
echo "Tag: $TAG"
echo ""

# Check if IPA exists
if [ ! -f "$IPA_PATH" ]; then
    echo -e "${YELLOW}IPA not found at $IPA_PATH${NC}"
    echo "Building first..."
    bash "$SCRIPT_DIR/build-local.sh"
fi

if [ ! -f "$IPA_PATH" ]; then
    echo -e "${RED}ERROR: IPA still not found after build${NC}"
    exit 1
fi

# Get file size
IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
echo -e "IPA: ${BOLD}$IPA_PATH${NC} ($IPA_SIZE)"
echo ""

# Check if tag exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${YELLOW}Tag $TAG already exists${NC}"
    read -rp "Delete and recreate? [y/N] " RECREATE
    if [[ $RECREATE =~ ^[Yy]$ ]]; then
        git tag -d "$TAG" 2>/dev/null || true
        git push origin ":refs/tags/$TAG" 2>/dev/null || true
    fi
fi

# Create tag
echo -e "${CYAN}Creating tag $TAG...${NC}"
git tag -a "$TAG" -m "Release $VERSION"
git push origin "$TAG"

# Create release
echo -e "${CYAN}Creating GitHub Release...${NC}"
gh release create "$TAG" \
    "$IPA_PATH" \
    --title "Anji $VERSION" \
    --notes "## Anji iOS $VERSION

### Installation
This is an unsigned IPA. Install using:
- **Sideloadly** (recommended)
- **AltStore**
- **SideStore**

### Requirements
- iOS 18+
- AnkiWeb account for sync

### What's Included
- Full Anki desktop compatibility
- Media sync support
- Dark mode support
- Custom accent colors

SHA256: \`$(shasum -a 256 "$IPA_PATH" | cut -d' ' -f1)\`
" \
    || {
        echo -e "${YELLOW}Release may already exist, trying to upload asset...${NC}"
        gh release upload "$TAG" "$IPA_PATH" --clobber
    }

echo ""
echo -e "${GREEN}${BOLD}Release $VERSION published!${NC}"
echo -e "URL: ${CYAN}https://github.com/yingluom/anji/releases/tag/$TAG${NC}"
