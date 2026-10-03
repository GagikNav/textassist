#!/usr/bin/env bash
# Create (or remove) a per-task git worktree so parallel agents never disturb each
# other's working tree or branch.
#
# Usage:
#   worktree.sh <issue#>            # create (idempotent); prints the path
#   worktree.sh <issue#> --path     # print the path only (no side effects)
#   worktree.sh <issue#> --remove   # remove it (WT_FORCE=1 to force)
#   worktree.sh --list              # list all worktrees
#
# Worktrees live under build/worktrees/ (already gitignored) and use the task
# branch issue-<n>-<slug>, created from the default branch.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"
require_gh

# Resolve the MAIN checkout (not the current worktree) so paths are stable.
GIT_COMMON="$(git -C "$REPO_ROOT" rev-parse --git-common-dir)"
MAIN_ROOT="$(cd "$GIT_COMMON/.." && pwd)"
WT_ROOT="$MAIN_ROOT/build/worktrees"

if [[ "${1:-}" == "--list" ]]; then
  git -C "$MAIN_ROOT" worktree list
  exit 0
fi

[[ $# -ge 1 ]] || die "usage: worktree.sh <issue#> [--path|--remove] | --list"
n="$1"; action="${2:-}"
printf '%s' "$n" | grep -qE '^[0-9]+$' || die "issue number required"

title="$(gh issue view "$n" --repo "$REPO" --json title --jq '.title' 2>/dev/null || true)"
[[ -n "$title" ]] || die "issue #$n not found in $REPO"

clean="$(printf '%s' "$title" | sed -E 's/^T[0-9]+\.[0-9]+[[:space:]]*//')"
slug="$(slugify "$clean")"
branch="issue-$n-$slug"
path="$WT_ROOT/$branch"

case "$action" in
  --path)   printf '%s\n' "$path"; exit 0 ;;
  --remove)
    if git -C "$MAIN_ROOT" worktree list --porcelain | grep -q "^worktree $path$"; then
      git -C "$MAIN_ROOT" worktree remove "$path" ${WT_FORCE:+--force}
      ok "removed worktree: $path"
    else
      warn "no worktree at $path"
    fi
    exit 0
    ;;
  "") ;;
  *) die "unknown option: $action" ;;
esac

mkdir -p "$WT_ROOT"

if git -C "$MAIN_ROOT" worktree list --porcelain | grep -q "^worktree $path$"; then
  ok "worktree already exists: $path"
elif git -C "$MAIN_ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$MAIN_ROOT" worktree add "$path" "$branch" >/dev/null
  ok "worktree created on existing branch $branch"
else
  git -C "$MAIN_ROOT" worktree add "$path" -b "$branch" "$DEFAULT_BRANCH" >/dev/null
  ok "worktree created (branch $branch off $DEFAULT_BRANCH)"
fi

printf '  cd "%s"\n' "$path"
