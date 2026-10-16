#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$PWD/build/MacMouse.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
BASE="MacMouse-v$VERSION-macOS"
codesign --verify --strict "$APP"
mkdir -p dist
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  codesign --verify --strict --verbose=2 "$APP"
  ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/notarization.zip"
  xcrun notarytool submit dist/notarization.zip --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
  spctl --assess --type execute --verbose=2 "$APP"
  rm dist/notarization.zip
fi
ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/$BASE.zip"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/MacMouse.dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/MacMouse.app"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname MacMouse -srcfolder "$STAGING" -ov -format UDZO "dist/$BASE.dmg"
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  codesign --timestamp --sign "$SIGN_IDENTITY" "dist/$BASE.dmg"
  xcrun notarytool submit "dist/$BASE.dmg" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
  xcrun stapler staple "dist/$BASE.dmg"
  xcrun stapler validate "dist/$BASE.dmg"
fi
(cd dist && shasum -a 256 "$BASE.zip" "$BASE.dmg" > SHA256SUMS.txt)
echo "Pacchetti e checksum disponibili in $PWD/dist"
