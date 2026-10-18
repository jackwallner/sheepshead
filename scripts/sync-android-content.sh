#!/bin/zsh
# Exports the iOS content and engine fixtures into the Android project.
# Rerun after changing anything in Shared/Models, Shared/Content,
# Shared/Services/WhatsNew.swift or Sheepshead/Utilities/ChoiceShuffle.swift.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
swiftc -O \
  "$repo"/Shared/Models/*.swift \
  "$repo"/Shared/Content/*.swift \
  "$repo"/Shared/Services/WhatsNew.swift \
  "$repo"/Sheepshead/Utilities/ChoiceShuffle.swift \
  "$repo"/scripts/android-export/main.swift \
  -o "$work/export"
mkdir -p "$repo/android/app/src/main/resources" "$repo/android/app/src/test/resources"
"$work/export" \
  "$repo/android/app/src/main/resources/sheepshead-content.json" \
  "$repo/android/app/src/test/resources/sheepshead-parity.json"
echo "Exported content and parity fixtures."
