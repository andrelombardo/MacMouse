#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
SWIFTC="$(xcrun --find swiftc)"
PLUGIN="$(dirname "$SWIFTC")/../lib/swift/host/plugins/testing/libTestingMacros.dylib"
FLAGS=()
# CLT 27 ships Swift Testing's macro plugin in a nested directory.
if [[ -f "$PLUGIN" ]]; then FLAGS=(-Xswiftc -load-plugin-library -Xswiftc "$PLUGIN"); fi
swift test "${FLAGS[@]}"
