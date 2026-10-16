#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUTPUT_APP="$PWD/build/MacMouse.app"
ARCH="${ARCH:-arm64}"
if [[ "$ARCH" != arm64 && "$ARCH" != x86_64 ]]; then echo 'ARCH deve essere arm64 o x86_64' >&2; exit 1; fi
swift build -c release --arch "$ARCH" --product MacMouse
BIN_DIR="$(swift build -c release --arch "$ARCH" --show-bin-path)"
if pgrep -f "^$OUTPUT_APP/Contents/MacOS/MacMouse([[:space:]]|$)" > /dev/null; then
  echo 'Esci dalla copia in build/MacMouse.app prima di sostituirla.' >&2; exit 1
fi
mkdir -p build
STAGING_ROOT="$(mktemp -d "$PWD/build/.bundle.XXXXXX")"
trap 'rm -rf "$STAGING_ROOT"' EXIT
APP="$STAGING_ROOT/MacMouse.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MacMouse" "$APP/Contents/MacOS/MacMouse"
cp Sources/MacMouse/Resources/Info.plist "$APP/Contents/Info.plist"
cp Sources/MacMouse/Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
printf 'APPL????' > "$APP/Contents/PkgInfo"
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi
codesign --verify --strict --verbose=2 "$APP"
# Replace complete bundles; never overwrite the executable of an existing app.
if [[ -d "$OUTPUT_APP" ]]; then mv "$OUTPUT_APP" "$STAGING_ROOT/Previous.app"; fi
if ! mv "$APP" "$OUTPUT_APP"; then
  if [[ -d "$STAGING_ROOT/Previous.app" ]]; then mv "$STAGING_ROOT/Previous.app" "$OUTPUT_APP"; fi
  exit 1
fi
echo "Build completata: $OUTPUT_APP ($ARCH)"
