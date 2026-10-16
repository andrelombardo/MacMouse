#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if pgrep -f '^/Applications/MacMouse[.]app/Contents/MacOS/MacMouse([[:space:]]|$)' > /dev/null; then
  echo 'Esci da MacMouse prima di installare la nuova build.' >&2; exit 1
fi
IDENTITY="${SIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
  IDENTITIES="$(security find-identity -v -p codesigning)"
  IDENTITY="$(printf '%s\n' "$IDENTITIES" | sed -n '/Developer ID Application/s/.*) \([A-F0-9]*\) .*/\1/p' | head -1)"
  if [[ -z "$IDENTITY" ]]; then
    IDENTITY="$(printf '%s\n' "$IDENTITIES" | sed -n '/Apple Development/s/.*) \([A-F0-9]*\) .*/\1/p' | head -1)"
  fi
fi
if [[ -z "$IDENTITY" ]]; then
  echo 'Nessun certificato locale disponibile: firma ad hoc. Gli aggiornamenti possono richiedere un nuovo consenso.'
else
  echo 'Uso del certificato locale per mantenere un’identità verificabile fra le build.'
fi
SIGN_IDENTITY="$IDENTITY" scripts/build.sh
STAGING="$(mktemp -d /Applications/.MacMouse-install.XXXXXX)"
trap 'rm -rf "$STAGING"' EXIT
ditto build/MacMouse.app "$STAGING/MacMouse.app"
codesign --verify --strict "$STAGING/MacMouse.app"
if [[ -d /Applications/MacMouse.app ]]; then
  mkdir -p build/backups
  ditto -c -k --sequesterRsrc --keepParent /Applications/MacMouse.app "build/backups/MacMouse-$(date +%Y%m%d-%H%M%S).zip"
  mv /Applications/MacMouse.app "$STAGING/Previous.app"
fi
if ! mv "$STAGING/MacMouse.app" /Applications/MacMouse.app; then
  if [[ -d "$STAGING/Previous.app" ]]; then mv "$STAGING/Previous.app" /Applications/MacMouse.app; fi
  exit 1
fi
codesign --verify --strict --verbose=2 /Applications/MacMouse.app
# Keep one installed copy; the compiled executable remains in SwiftPM's hidden build directory.
rm -rf build/MacMouse.app
echo 'Installata /Applications/MacMouse.app. Preferenze e stato del login conservati.'
