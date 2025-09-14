#!/usr/bin/env bash
set -euo pipefail

# Generate all required iOS app icon sizes from a 1024x1024 source PNG
# Usage: bash scripts/generate_app_icons.sh [source_png]

SRC_DEFAULT="simple-navi Exports/simple-navi-iOS-Default-1024x1024@1x.png"
SRC="${1:-$SRC_DEFAULT}"
DEST="SimpleNavi/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SRC" ]]; then
  echo "[Error] Source icon not found: $SRC" >&2
  exit 1
fi

mkdir -p "$DEST"

# Ensure no-alpha by flattening to JPEG first, then generate PNGs from the flattened image
FLAT_JPG="/tmp/simple-navi-icon-opaque.jpg"
echo "Flattening source to opaque JPEG (no alpha): $FLAT_JPG"
sips -s format jpeg "$SRC" --out "$FLAT_JPG" >/dev/null
INPUT="$FLAT_JPG"

copy() {
  local SIZE="$1" # e.g., 120
  local NAME="$2" # e.g., AppIcon-60@2x-iphone
  echo "Generating $NAME (${SIZE}x${SIZE})"
  sips -s format png -z "$SIZE" "$SIZE" "$INPUT" --out "$DEST/$NAME.png" >/dev/null
}

# Marketing icon (1024x1024) — ensure PNG w/o alpha
sips -s format png -z 1024 1024 "$INPUT" --out "$DEST/AppIcon-1024.png" >/dev/null

# iPhone
copy 40  "AppIcon-20@2x-iphone"
copy 60  "AppIcon-20@3x-iphone"
copy 58  "AppIcon-29@2x-iphone"
copy 87  "AppIcon-29@3x-iphone"
copy 80  "AppIcon-40@2x-iphone"
copy 120 "AppIcon-40@3x-iphone"
copy 120 "AppIcon-60@2x-iphone"
copy 180 "AppIcon-60@3x-iphone"

# iPad
copy 20  "AppIcon-20@1x-ipad"
copy 40  "AppIcon-20@2x-ipad"
copy 29  "AppIcon-29@1x-ipad"
copy 58  "AppIcon-29@2x-ipad"
copy 40  "AppIcon-40@1x-ipad"
copy 80  "AppIcon-40@2x-ipad"
copy 152 "AppIcon-76@2x-ipad"
copy 167 "AppIcon-83_5@2x-ipad"

echo "All app icon sizes generated in $DEST"
