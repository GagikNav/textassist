#!/usr/bin/env bash
# Build Text Assist in Release mode, export the .app, and package it as a DMG.
#
# Usage:
#   Scripts/build-dmg.sh [version]     # e.g. Scripts/build-dmg.sh 1.0.0
#
# Output:
#   build/Export/Text Assist.app       # the exported app bundle
#   build/Text-Assist[-<version>].dmg  # the disk image
#
# Signing: uses export-options.plist at the repo root. The shipped plist exports
# an UNSIGNED app (method: mac-application) — fine for local use. For public
# releases switch it to method: developer-id with your Team ID and notarize
# (see Docs/setup-guide.md §10–11).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-}"
APP_NAME="Text Assist"
SCHEME="Text Assist"
ARCHIVE_PATH="build/TextAssist.xcarchive"
EXPORT_PATH="build/Export"
DMG_PATH="build/Text-Assist${VERSION:+-$VERSION}.dmg"

# Fail early with a clear message if the tools are missing.
command -v xcodebuild >/dev/null \
  || { echo "error: xcodebuild not found — run: xcode-select --install" >&2; exit 1; }

# Step 1: compile the app in Release mode into an .xcarchive (the intermediate
# package Xcode uses for distribution). -quiet shows only warnings/errors.
echo "==> 1/3 Archive (Release)"
xcodebuild archive \
  -project TextAssist.xcodeproj \
  -scheme "$SCHEME" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  -configuration Release \
  -quiet

# Step 2: export the final .app bundle using the rules in export-options.plist.
echo "==> 2/3 Export .app"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist export-options.plist \
  -quiet

[[ -d "$EXPORT_PATH/$APP_NAME.app" ]] \
  || { echo "error: $EXPORT_PATH/$APP_NAME.app missing after export" >&2; exit 1; }

# Step 3: wrap the .app in a DMG. create-dmg gives the classic installer window
# with a drag-to-Applications link; if it is not installed, fall back to the
# built-in hdiutil, which makes a plain DMG with no fancy layout.
echo "==> 3/3 Package DMG ($DMG_PATH)"
rm -f "$DMG_PATH"
if command -v create-dmg >/dev/null; then
  create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --app-drop-link 600 185 \
    --overwrite \
    "$DMG_PATH" \
    "$EXPORT_PATH/$APP_NAME.app"
else
  echo "note: create-dmg not installed — using hdiutil fallback"
  echo "      (brew install create-dmg for a nicer installer window)"
  hdiutil create -volname "$APP_NAME" -srcfolder "$EXPORT_PATH/$APP_NAME.app" \
    -ov -format UDZO "$DMG_PATH" >/dev/null
fi

# Print the results plus a SHA-256 checksum (needed for a Homebrew cask later).
echo
echo "Done:"
echo "  app: $EXPORT_PATH/$APP_NAME.app"
echo "  dmg: $DMG_PATH"
shasum -a 256 "$DMG_PATH" | awk '{print "  sha256: " $1}'
