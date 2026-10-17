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
if [[ ! -x .build/packaging/bin/python ]]; then
  if ! "${PYTHON:-python3}" -c 'import sys; sys.exit(sys.version_info < (3, 10))'; then
    echo 'Il packaging richiede Python 3.10+. Specifica PYTHON=/percorso/python3.' >&2
    exit 1
  fi
  "${PYTHON:-python3}" -m venv .build/packaging
fi
.build/packaging/bin/python -m pip install --disable-pip-version-check -q -r scripts/requirements-packaging.txt
swift scripts/dmg-background.swift build/dmg-background.png
.build/packaging/bin/python -m dmgbuild -s scripts/dmg-settings.py MacMouse "dist/$BASE.dmg"
hdiutil verify "dist/$BASE.dmg"
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  codesign --timestamp --sign "$SIGN_IDENTITY" "dist/$BASE.dmg"
  xcrun notarytool submit "dist/$BASE.dmg" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
  xcrun stapler staple "dist/$BASE.dmg"
  xcrun stapler validate "dist/$BASE.dmg"
fi
(cd dist && shasum -a 256 "$BASE.zip" "$BASE.dmg" > SHA256SUMS.txt)
echo "Pacchetti e checksum disponibili in $PWD/dist"
