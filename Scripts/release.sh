#!/usr/bin/env bash
# Build a universal (arm64 + x86_64) DMG of Text Assist, signed with RELEASE_SIGN_IDENTITY
# (ad-hoc when unset), plus the signed
# ZIP and appcast.xml that Sparkle updates use, and publish them as a GitHub Release.
# Local-only (no CI); notarization is out of scope (PRD-v2 §2).
#
# Usage:
#   Scripts/release.sh <version> [options]
#   Scripts/release.sh --bump patch|minor|major [options]
#
#   version        X.Y.Z (e.g. 0.9.0). The git tag is v<version>.
#   --bump LEVEL   Use the highest existing v* tag, raised by one patch, minor or
#                  major step. Exactly one of <version> or --bump is required.
#                  MARKETING_VERSION in project.pbxproj is stale and is not used.
#
#   Options:
#     --skip-upload   Build the DMG, ZIP and appcast but do not create the GitHub release.
#     --no-sign       Skip the codesign step and the update ZIP/appcast
#                     (local testing only).
#     --draft         Pass --draft to gh release create (eyeball before public).
#     -h, --help      Print this help.
#
#   Environment:
#     SPARKLE_BIN           Folder with Sparkle's sign_update. Default: ~/sparkle-tools/bin,
#                           then the Sparkle package artifacts under build/DerivedData.
#     SPARKLE_ED_KEY_FILE   Private key file for sign_update. Default: the login Keychain.
#     RELEASE_SIGN_IDENTITY Code-signing identity for the app (certificate name or SHA-1),
#                           e.g. "Text Assist Release". Keeps the Accessibility permission
#                           across updates (Docs/releasing.md, "Signing and permissions").
#                           When unset the app is signed ad-hoc, as for local builds.
#
# Requirements: xcodebuild, create-dmg (brew install create-dmg), gh (authenticated),
# Sparkle's sign_update (see Docs/releasing.md, "Update signing key").
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
  sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed -e 's/^# \{0,1\}//'
  exit 0
}

# Highest existing v<X.Y[.Z]> tag, normalised to X.Y.Z (empty when there is none).
latest_tag_version() {
  git -C "$REPO_ROOT" tag --list 'v[0-9]*' \
    | sed -n 's/^v\([0-9][0-9]*\.[0-9][0-9]*\(\.[0-9][0-9]*\)\{0,1\}\)$/\1/p' \
    | awk -F. '{ printf "%d.%d.%d\n", $1, $2, $3 }' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1
}

# previous_tag_below X.Y.Z -> name of the highest existing v* tag that is lower than
# X.Y.Z (empty when there is none). Tags like v0.2 count as 0.2.0.
previous_tag_below() {
  git -C "$REPO_ROOT" tag --list 'v[0-9]*' \
    | awk -v new="$1" '
        BEGIN { split(new, n, "."); limit = n[1] * 1000000 + n[2] * 1000 + n[3] }
        /^v[0-9]+\.[0-9]+(\.[0-9]+)?$/ {
          v = substr($0, 2); split(v, p, ".")
          key = p[1] * 1000000 + p[2] * 1000 + p[3]
          if (key < limit && key >= best) { best = key; name = $0 }
        }
        END { if (name != "") print name }'
}

# whats_new_section PREVIOUS_TAG -> the What's new block (heading, blank line,
# bullets, trailing blank line) for the first-parent commit subjects on HEAD since
# PREVIOUS_TAG. Prints a one-line fallback instead when there is nothing to list.
whats_new_section() {
  local previous="$1" subjects="" subject
  if [[ -n "$previous" ]]; then
    subjects="$(git -C "$REPO_ROOT" log --first-parent --format=%s "$previous..HEAD" 2>/dev/null || true)"
  fi
  if [[ -z "$subjects" ]]; then
    if [[ -z "$previous" ]]; then
      echo "See the commit history for what changed in this release."
    else
      echo "No changes since $previous."
    fi
    echo
    return 0
  fi
  echo "### What's new"
  echo
  while IFS= read -r subject; do
    [[ -n "$subject" ]] && printf -- '- %s\n' "$subject"
  done <<<"$subjects"
  echo
}

# Prints the path of Sparkle's sign_update, or returns 1 when it cannot be found.
find_sign_update() {
  local dir candidates=()
  if [[ -n "${SPARKLE_BIN:-}" ]]; then candidates+=("$SPARKLE_BIN"); fi
  candidates+=("$HOME/sparkle-tools/bin"
               "$REPO_ROOT/build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin")
  for dir in "${candidates[@]}"; do
    if [[ -x "$dir/sign_update" ]]; then
      printf '%s\n' "$dir/sign_update"
      return 0
    fi
  done
  return 1
}

# bump_version X.Y.Z patch|minor|major -> next version.
bump_version() {
  local major minor patch
  IFS=. read -r major minor patch <<<"$1"
  case "$2" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "$major.$((minor + 1)).0" ;;
    patch) echo "$major.$minor.$((patch + 1))" ;;
  esac
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
REPO_SLUG="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/]##; s#\.git$##' || true)"

# --- parse args ---------------------------------------------------------------

VERSION=""
BUMP=""
SKIP_UPLOAD=0
NO_SIGN=0
DRAFT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --bump)
      [[ $# -ge 2 ]] || die "--bump needs a level: patch, minor or major."
      BUMP="$2"
      shift
      ;;
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

# Sparkle's sign_update signs the update ZIP. Find it now so a missing tool does not
# fail the release after the long build.
SIGN_UPDATE=""
if [[ "$NO_SIGN" -eq 0 ]]; then
  SIGN_UPDATE="$(find_sign_update)" \
    || die "Sparkle's sign_update not found. Download Sparkle (Docs/releasing.md, \"Update signing key\") or set SPARKLE_BIN to its bin folder."
fi

# Signing identity: "-" is ad-hoc. A named identity must exist in the Keychain. Not
# "-v": a self-signed certificate is listed as not trusted, yet codesign signs with it.
SIGN_IDENTITY="${RELEASE_SIGN_IDENTITY:--}"
if [[ "$SIGN_IDENTITY" != "-" && "$NO_SIGN" -eq 0 ]]; then
  security find-identity -p codesigning | grep -qF -- "$SIGN_IDENTITY" \
    || die "signing identity '$SIGN_IDENTITY' not found in the Keychain (Docs/releasing.md, \"Signing and permissions\")."
fi

# Version: exactly one of an explicit X.Y.Z or --bump. MARKETING_VERSION in the
# project file is stale (1.0) and must never be used as a default.
[[ -z "$VERSION" || -z "$BUMP" ]] || die "pass either a version or --bump, not both."
[[ -n "$VERSION" || -n "$BUMP" ]] \
  || die "no version given. Pass X.Y.Z or --bump patch|minor|major (see --help)."

if [[ -n "$BUMP" ]]; then
  case "$BUMP" in
    patch|minor|major) ;;
    *) die "invalid --bump level '$BUMP' (expected patch, minor or major)." ;;
  esac
  # Releases created on GitHub tag the remote only, so refresh local tags first.
  git -C "$REPO_ROOT" fetch --tags --quiet origin \
    || warn "could not fetch tags from origin; bumping from local tags only."
  PREVIOUS="$(latest_tag_version)"
  [[ -n "$PREVIOUS" ]] || die "no existing v* tag to bump from; pass an explicit version."
  VERSION="$(bump_version "$PREVIOUS" "$BUMP")"
  log "bump $BUMP: v$PREVIOUS → v$VERSION"
fi
printf '%s' "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' \
  || die "invalid version '$VERSION' (expected X.Y.Z, e.g. 0.9.0)."
TAG="v$VERSION"

# Release notes list the changes since the previous tag, so tags must be current even
# for an explicit version (--bump already fetched them above).
if [[ -z "$BUMP" ]]; then
  git -C "$REPO_ROOT" fetch --tags --quiet origin \
    || warn "could not fetch tags from origin; the release notes use local tags only."
fi

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

# --- 1. archive (signed with the identity; re-signed in step 4) -------------------

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
  CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
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

# --- 3b. verify the built app carries the requested version ----------------------

log "verifying app version…"

APP_PLIST="$APP_PATH/Contents/Info.plist"
BUILT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PLIST" 2>/dev/null || true)"
BUILT_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PLIST" 2>/dev/null || true)"
[[ "$BUILT_VERSION" == "$VERSION" ]] \
  || die "built app reports version '${BUILT_VERSION:-none}', expected '$VERSION'."
[[ "$BUILT_BUILD" == "$BUILD_NUMBER" ]] \
  || die "built app reports build '${BUILT_BUILD:-none}', expected '$BUILD_NUMBER'."
ok "app version: $BUILT_VERSION (build $BUILT_BUILD)"

# --- 4. codesign -------------------------------------------------------------------

if [[ "$NO_SIGN" -eq 1 ]]; then
  warn "skipping codesign (--no-sign)."
else
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    log "ad-hoc codesigning (RELEASE_SIGN_IDENTITY is not set)…"
  else
    log "codesigning with '$SIGN_IDENTITY'…"
  fi
  codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_PATH" >/dev/null 2>&1 \
    || die "codesign failed."
  codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1 \
    || die "codesign --verify failed."

  # The designated requirement is what macOS compares for the Accessibility permission.
  # With a certificate it must name the certificate, not the build's own hash.
  DESIGNATED_REQ="$(codesign -dr - "$APP_PATH" 2>&1 | sed -n 's/^#\{0,1\} *designated => //p')"
  log "designated requirement: $DESIGNATED_REQ"
  if [[ "$SIGN_IDENTITY" != "-" ]]; then
    printf '%s' "$DESIGNATED_REQ" | grep -q 'certificate leaf' \
      || die "the signature has no 'certificate leaf' requirement; refusing to release it as if it were certificate-signed."
    ok "signature verified (certificate)."
  else
    ok "ad-hoc signature verified."
  fi
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

# --- 6b. update archive and appcast (Sparkle) ---------------------------------------
#
# The app reads releases/latest/download/appcast.xml, which GitHub serves from the
# newest published (non-draft, non-pre-release) release. One item is enough: the app
# only needs the newest version.

ZIP_PATH="$BUILD_DIR/$DMG_PREFIX-$VERSION.zip"
APPCAST_PATH="$BUILD_DIR/appcast.xml"
EXTRA_ASSETS=()
HAS_UPDATER=0
[[ -d "$APP_PATH/Contents/Frameworks/Sparkle.framework" ]] && HAS_UPDATER=1

if [[ "$NO_SIGN" -eq 1 ]]; then
  warn "skipping the update ZIP and appcast (--no-sign)."
else
  log "creating $DMG_PREFIX-$VERSION.zip…"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH" \
    || die "ditto could not create $ZIP_PATH."
  [[ -f "$ZIP_PATH" ]] || die "ditto did not produce $ZIP_PATH."
  ZIP_LENGTH="$(stat -f%z "$ZIP_PATH")"
  ok "ZIP created: $ZIP_PATH ($ZIP_LENGTH bytes)"

  log "signing the update ZIP with sign_update…"
  SIGN_ARGS=()
  if [[ -n "${SPARKLE_ED_KEY_FILE:-}" ]]; then SIGN_ARGS+=(--ed-key-file "$SPARKLE_ED_KEY_FILE"); fi
  ED_SIGNATURE="$("$SIGN_UPDATE" ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} -p "$ZIP_PATH")" \
    || die "sign_update failed (is the private key in the Keychain? see Docs/releasing.md)."
  [[ -n "$ED_SIGNATURE" ]] || die "sign_update returned an empty signature."
  "$SIGN_UPDATE" ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} --verify "$ZIP_PATH" "$ED_SIGNATURE" >/dev/null 2>&1 \
    || die "the new signature does not verify against the signing key."
  ok "update ZIP signed and verified"

  # The app only accepts updates signed with the key it was built with. Catch a
  # mismatch now, before it ships a release that nobody can update from.
  APP_PUBLIC_KEY="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$APP_PLIST" 2>/dev/null || true)"
  if [[ -z "$APP_PUBLIC_KEY" ]]; then
    warn "the built app has no SUPublicEDKey, so it cannot verify or install updates yet."
  elif [[ -z "${SPARKLE_ED_KEY_FILE:-}" && -x "$(dirname "$SIGN_UPDATE")/generate_keys" ]]; then
    KEYCHAIN_PUBLIC_KEY="$("$(dirname "$SIGN_UPDATE")/generate_keys" -p 2>/dev/null || true)"
    [[ "$KEYCHAIN_PUBLIC_KEY" == "$APP_PUBLIC_KEY" ]] \
      || die "the app's SUPublicEDKey does not match the signing key in the Keychain; installed copies would reject this update."
    ok "app public key matches the signing key"
  else
    warn "could not compare the app's SUPublicEDKey with the signing key (key file in use, or generate_keys not next to sign_update)."
  fi

  RELEASE_URL="https://github.com/$REPO_SLUG/releases/tag/$TAG"
  ZIP_URL="https://github.com/$REPO_SLUG/releases/download/$TAG/$DMG_PREFIX-$VERSION.zip"
  PUB_DATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"

  cat > "$APPCAST_PATH" <<APPCAST
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Text Assist</title>
    <link>https://github.com/$REPO_SLUG</link>
    <description>Text Assist updates</description>
    <language>en</language>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>$RELEASE_URL</sparkle:releaseNotesLink>
      <enclosure url="$ZIP_URL" length="$ZIP_LENGTH" type="application/octet-stream" sparkle:edSignature="$ED_SIGNATURE"/>
    </item>
  </channel>
</rss>
APPCAST
  if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$APPCAST_PATH" || die "appcast.xml is not well-formed XML."
  fi
  ok "appcast written: $APPCAST_PATH"
  EXTRA_ASSETS+=("$ZIP_PATH" "$APPCAST_PATH")
fi

# --- 7. publish ------------------------------------------------------------------

if [[ "$SKIP_UPLOAD" -eq 1 ]]; then
  ok "done (--skip-upload): $DMG_PATH"
  exit 0
fi

log "creating GitHub release ${TAG}…"

NOTES_FILE="$BUILD_DIR/release-notes.md"
PREVIOUS_TAG="$(previous_tag_below "$VERSION")"
SIGNED_DESC="ad-hoc signed"
[[ "$SIGN_IDENTITY" == "-" ]] || SIGNED_DESC="signed with a self-signed certificate"

{
  echo "## Text Assist v$VERSION"
  echo
  echo "Universal (Apple Silicon + Intel) build for macOS 13+."
  echo
  whats_new_section "$PREVIOUS_TAG"
  echo "### Install"
  echo
  echo "1. Open the DMG and drag **Text Assist** to **Applications**."
  echo "2. The app is $SIGNED_DESC (not notarized). The first time you open it, macOS will block it:"
  echo "   - Right-click **Text Assist** in Applications → **Open** → **Open**, or"
  echo "   - System Settings → **Privacy & Security** → **Open Anyway**, or"
  echo "   - In Terminal: \`xattr -dr com.apple.quarantine \"/Applications/Text Assist.app\"\`"
  if [[ "$HAS_UPDATER" -eq 1 ]]; then
    echo
    echo "### Updates"
    echo
    echo "Once installed, Text Assist updates itself from inside the app."
  fi
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
  "$DMG_PATH.sha256" \
  ${EXTRA_ASSETS[@]+"${EXTRA_ASSETS[@]}"} \
  --repo "$REPO_SLUG" \
  --title "Text Assist $TAG" \
  --notes-file "$NOTES_FILE" \
  --target "$DEFAULT_BRANCH" \
  ${DRAFT_ARGS[@]+"${DRAFT_ARGS[@]}"}

ok "release created: https://github.com/$REPO_SLUG/releases/tag/$TAG"
ok "done: $DMG_PATH"
