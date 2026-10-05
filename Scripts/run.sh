#!/usr/bin/env bash
# Build Text Assist in Debug mode and launch the built app.
#
# Usage:
#   Scripts/run.sh            # build + open the app
#   Scripts/run.sh --no-open  # build only, don't launch
#
# Output:
#   build/DerivedData/Build/Products/Debug/Text Assist.app
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

APP_NAME="Text Assist"
SCHEME="Text Assist"
APP_PATH="build/DerivedData/Build/Products/Debug/${APP_NAME}.app"

# Fail early with a clear message if the tools are missing.
command -v xcodebuild >/dev/null \
  || { echo "error: xcodebuild not found — run: xcode-select --install" >&2; exit 1; }

# Step 1: compile the app in Debug mode. -quiet shows only warnings/errors.
echo "==> 1/2 Build (Debug)"
xcodebuild build \
  -project TextAssist.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath build/DerivedData \
  -quiet

[[ -d "$APP_PATH" ]] \
  || { echo "error: $APP_PATH missing after build" >&2; exit 1; }

# Step 2: launch the freshly built app.
if [[ "${1:-}" == "--no-open" ]]; then
  echo "==> 2/2 Skipping launch (--no-open)"
else
  echo "==> 2/2 Launch $APP_PATH"
  open "$APP_PATH"
fi
