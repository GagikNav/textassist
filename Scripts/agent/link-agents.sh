#!/usr/bin/env bash
# Create (or refresh) the `.github/agents` -> `.agents/agents` symlink so VS Code
# Copilot discovers the canonical agent definitions in their single source location.
#
# Usage:
#   link-agents.sh          # create the symlink (default)
#   link-agents.sh --copy   # copy instead of symlink (fallback for filesystems
#                           # that do not follow symlinks, e.g. a Windows checkout)
#   link-agents.sh --status # print the current state
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"

SRC="$REPO_ROOT/.agents/agents"
DEST="$REPO_ROOT/.github/agents"

mode="link"
case "${1:-}" in
  --copy)   mode="copy" ;;
  --status) mode="status" ;;
  "")       ;;
  *) die "unknown option: $1 (use --copy or --status)" ;;
esac

[[ -d "$SRC" ]] || die "missing source directory: $SRC"

if [[ "$mode" == "status" ]]; then
  if [[ -L "$DEST" ]]; then
    ok "$DEST → $(readlink "$DEST") (symlink)"
  elif [[ -d "$DEST" ]]; then
    warn "$DEST is a real directory (copied, not a symlink)"
  else
    warn "$DEST does not exist (run link-agents.sh)"
  fi
  exit 0
fi

mkdir -p "$REPO_ROOT/.github"

# Remove whatever is currently at DEST (symlink or copy) so we can recreate it.
if [[ -L "$DEST" || -e "$DEST" ]]; then
  rm -rf "$DEST"
fi

if [[ "$mode" == "copy" ]]; then
  cp -R "$SRC" "$DEST"
  ok "copied agents → $DEST"
else
  # Relative target so the symlink survives clones at any absolute path.
  ln -s "../.agents/agents" "$DEST"
  ok "$DEST → ../.agents/agents"
fi
