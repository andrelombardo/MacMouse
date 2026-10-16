#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$PWD/build/MacMouse.app"
ARCH="${ARCH:-arm64}"
if [[ "$ARCH" != arm64 && "$ARCH" != x86_64 ]]; then echo 'ARCH deve essere arm64 o x86_64' >&2; exit 1; fi
swift build -c release --arch "$ARCH" --product MacMouse
BIN_DIR="$(swift build -c release --arch "$ARCH" --show-bin-path)"
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
echo "Build completata: $APP ($ARCH)"
