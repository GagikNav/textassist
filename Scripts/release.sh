#!/usr/bin/env bash
# Build a universal (arm64 + x86_64), ad-hoc-signed DMG of Text Assist and publish
# it as a GitHub Release. Local-only (no CI); notarization is out of scope (PRD-v2 §2).
#
# Usage:
#   Scripts/release.sh [version] [options]
#
#   version        Optional. Defaults to MARKETING_VERSION in project.pbxproj.
#                  Must match X.Y[.Z] (e.g. 0.9.0). The git tag is v<version>.
#
#   Options:
#     --skip-upload   Build the DMG but do not create the GitHub release.
#     --no-sign       Skip the ad-hoc codesign step (local testing only).
#     --draft         Pass --draft to gh release create (eyeball before public).
#     -h, --help      Print this help.
#
# Requirements: xcodebuild, create-dmg (brew install create-dmg), gh (authenticated).
#
# The script must run from the MAIN checkout on the main branch — never from a
# task worktree under build/worktrees/ (releases are cut from main only).
set -euo pipefail

# --- pretty output (style of Scripts/agent/agent-lib.sh) ----------------------

c_reset=$'\033[0m'; c_dim=$'\033[2m'; c_bold=$'\033[1m'
c_red=$'\033[31m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_blue=$'\033[34m'

log()  { printf '%b\n' "${c_blue}▸${c_reset} $*"; }
ok()   { printf '%b\n' "${c_green}✓${c_reset} $*"; }
warn() { printf '%b\n' "${c_yellow}!${c_reset} $*" >&2; }
die()  { printf '%b\n' "${c_red}✗${c_reset} $*" >&2; exit 1; }

usage() {
  sed -n '2,20p' "$0" | sed -e 's/^# \{0,1\}//'
  exit 0
}

# --- constants ----------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$REPO_ROOT/TextAssist.xcodeproj"
SCHEME="Text Assist"
CONFIGURATION="Release"
EXPORT_OPTIONS="$REPO_ROOT/export-options.plist"
BUILD_DIR="$REPO_ROOT/build/release"
APP_NAME="Text Assist"
DMG_PREFIX="Text-Assist"
DEFAULT_BRANCH="main"

# --- parse args ---------------------------------------------------------------

VERSION=""
SKIP_UPLOAD=0
NO_SIGN=0
DRAFT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --skip-upload) SKIP_UPLOAD=1 ;;
    --no-sign)     NO_SIGN=1 ;;
    --draft)       DRAFT=1 ;;
    -*) die "unknown option: $1 (see --help)" ;;
    *)
      [[ -z "$VERSION" ]] || die "version already set to '$VERSION'"
      VERSION="$1"
      ;;
  esac
  shift
done

# --- preflight ----------------------------------------------------------------

log "preflight"

# Must run from the main checkout, not a task worktree.
case "$REPO_ROOT" in
  */build/worktrees/*) die "refusing to run from a task worktree ($REPO_ROOT). Run from the main checkout." ;;
esac

# Must be on the default branch.
BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" == "$DEFAULT_BRANCH" ]] || die "not on '$DEFAULT_BRANCH' (on '$BRANCH'). Releases are cut from $DEFAULT_BRANCH only."

# Clean tree (warn only — untracked build output is fine).
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
  warn "working tree is not clean — the DMG may not match the committed state."
fi

# Tooling.
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found (install Xcode Command Line Tools)."
command -v create-dmg >/dev/null 2>&1 || die "create-dmg not found (brew install create-dmg)."
command -v gh >/dev/null 2>&1 || die "gh not found (brew install gh)."
command -v jq >/dev/null 2>&1 || die "jq not found (brew install jq)."
if [[ "$SKIP_UPLOAD" -eq 0 ]]; then
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated (run: gh auth login)."
fi

# Version: explicit arg, else MARKETING_VERSION from the project file (read-only).
if [[ -z "$VERSION" ]]; then
  VERSION="$(sed -n 's/^[[:space:]]*MARKETING_VERSION = \([^;]*\);.*$/\1/p' \
    "$REPO_ROOT/TextAssist.xcodeproj/project.pbxproj" | head -1)"
  [[ -n "$VERSION" ]] || die "could not read MARKETING_VERSION from project.pbxproj; pass a version argument."
  log "using MARKETING_VERSION from the project: $VERSION"
fi
printf '%s' "$VERSION" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$' \
  || die "invalid version '$VERSION' (expected X.Y or X.Y.Z, e.g. 0.9.0)."
TAG="v$VERSION"

# Tag/release must not already exist.
if git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  die "tag $TAG already exists."
fi
if [[ "$SKIP_UPLOAD" -eq 0 ]]; then
  if gh release view "$TAG" --repo "$(git -C "$REPO_ROOT" remote get-url origin | sed -E 's#.*github.com[:/]##; s#\.git$##')" >/dev/null 2>&1; then
    die "release $TAG already exists on GitHub."
  fi
fi

ok "preflight passed (branch: $BRANCH, version: $VERSION, tag: $TAG)"

# --- 1. archive (deterministic ad-hoc signing) ---------------------------------

log "archiving $SCHEME ($CONFIGURATION, universal)…"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

BUILD_NUMBER="$(git -C "$REPO_ROOT" rev-list --count HEAD)"
ARCHIVE_PATH="$BUILD_DIR/TextAssist.xcarchive"
XCODEBUILD_LOG="$BUILD_DIR/xcodebuild-archive.log"

log "archiving (log: $XCODEBUILD_LOG)…"

if ! xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "generic/platform=macOS" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  > "$XCODEBUILD_LOG" 2>&1; then
  tail -40 "$XCODEBUILD_LOG" >&2
  die "archive failed (full log: $XCODEBUILD_LOG)."
fi
[[ -d "$ARCHIVE_PATH" ]] || die "archive failed (no $ARCHIVE_PATH; log: $XCODEBUILD_LOG)."
ok "archive created: $ARCHIVE_PATH"

# --- 2. export the .app ---------------------------------------------------------

log "exporting $APP_NAME.app…"

EXPORT_DIR="$BUILD_DIR/Export"
APP_PATH="$EXPORT_DIR/$APP_NAME.app"
EXPORT_LOG="$BUILD_DIR/xcodebuild-export.log"

if xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  > "$EXPORT_LOG" 2>&1 && [[ -d "$APP_PATH" ]]; then
  ok "exported via -exportArchive: $APP_PATH"
else
  warn "-exportArchive failed (log: $EXPORT_LOG); falling back to copying from the archive products."
  mkdir -p "$EXPORT_DIR"
  cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_DIR/"
  [[ -d "$APP_PATH" ]] || die "could not obtain $APP_NAME.app from the archive."
  ok "copied from archive products: $APP_PATH"
fi

# --- 3. verify universal binary -------------------------------------------------

log "verifying architectures…"

ARCHS="$(lipo -archs "$APP_PATH/Contents/MacOS/$APP_NAME" 2>/dev/null || true)"
printf '%s' "$ARCHS" | grep -q 'arm64'   || die "app binary is missing arm64 (found: ${ARCHS:-none})."
printf '%s' "$ARCHS" | grep -q 'x86_64'  || die "app binary is missing x86_64 (found: ${ARCHS:-none})."
ok "universal binary: $ARCHS"

# --- 4. ad-hoc codesign ----------------------------------------------------------

if [[ "$NO_SIGN" -eq 1 ]]; then
  warn "skipping codesign (--no-sign)."
else
  log "ad-hoc codesigning…"
  codesign --force --deep --sign - "$APP_PATH" >/dev/null 2>&1 \
    || die "codesign failed."
  codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1 \
    || die "codesign --verify failed."
  ok "ad-hoc signature verified."
fi

# --- 5. package the DMG ----------------------------------------------------------

log "creating $DMG_PREFIX-$VERSION.dmg…"

DMG_PATH="$BUILD_DIR/$DMG_PREFIX-$VERSION.dmg"
rm -f "$DMG_PATH"

# create-dmg returns non-zero when its AppleScript window-positioning step fails,
# even though the DMG was produced. Treat non-zero as OK as long as the file exists.
create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  "$DMG_PATH" \
  "$APP_PATH" >/dev/null 2>&1 || true

[[ -f "$DMG_PATH" ]] || die "create-dmg did not produce $DMG_PATH."
ok "DMG created: $DMG_PATH"

# --- 6. checksum -----------------------------------------------------------------

log "computing SHA-256…"

SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
printf '%s  %s\n' "$SHA256" "$DMG_PREFIX-$VERSION.dmg" > "$DMG_PATH.sha256"
ok "SHA-256: $SHA256"

# --- 7. publish ------------------------------------------------------------------

if [[ "$SKIP_UPLOAD" -eq 1 ]]; then
  ok "done (--skip-upload): $DMG_PATH"
  exit 0
fi

log "creating GitHub release $TAG…"

REPO_SLUG="$(git -C "$REPO_ROOT" remote get-url origin | sed -E 's#.*github.com[:/]##; s#\.git$##')"
NOTES_FILE="$BUILD_DIR/release-notes.md"

{
  echo "## Text Assist v$VERSION"
  echo
  echo "Universal (Apple Silicon + Intel) build for macOS 13+."
  echo
  echo "### Install"
  echo
  echo "1. Open the DMG and drag **Text Assist** to **Applications**."
  echo "2. The app is ad-hoc signed (not notarized). The first time you open it, macOS will block it:"
  echo "   - Right-click **Text Assist** in Applications → **Open** → **Open**, or"
  echo "   - System Settings → **Privacy & Security** → **Open Anyway**, or"
  echo "   - In Terminal: \`xattr -dr com.apple.quarantine \"/Applications/Text Assist.app\"\`"
  echo
  echo "### SHA-256"
  echo
  echo "\`\`\`"
  echo "$SHA256"
  echo "\`\`\`"
} > "$NOTES_FILE"

DRAFT_ARGS=()
if [[ "$DRAFT" -eq 1 ]]; then DRAFT_ARGS+=(--draft); fi

gh release create "$TAG" \
  "$DMG_PATH" \
  --repo "$REPO_SLUG" \
  --title "Text Assist $TAG" \
  --notes-file "$NOTES_FILE" \
  --target "$DEFAULT_BRANCH" \
  "${DRAFT_ARGS[@]}"

ok "release created: https://github.com/$REPO_SLUG/releases/tag/$TAG"
ok "done: $DMG_PATH"
