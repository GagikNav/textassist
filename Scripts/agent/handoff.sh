#!/usr/bin/env bash
# Finish/pause a task: validate the handoff, commit it, mirror it to the issue,
# sync the state label, and regenerate the overview.
#
# Usage: handoff.sh <issue-number> [ready|in-progress|blocked|review|done]
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"
require_gh

[[ $# -ge 1 ]] || die "usage: handoff.sh <issue-number> [state]"
n="$1"; state="${2:-review}"

hfile="$(handoff_path "$n")"
[[ -n "$hfile" ]] || die "no handoff at Docs/handoffs/issue-$n-*.md (start from .agents/templates/handoff.md)"

missing=0
for s in "## 2. Plan" "## 4. Verification" "## 5. How to test manually" "## 9. Resume here"; do
  grep -qF "$s" "$hfile" || { warn "handoff missing section: $s"; missing=1; }
done
grep -qF "Next action" "$hfile" || { warn "handoff missing a 'Next action'"; missing=1; }
[[ "$missing" -eq 0 ]] || die "handoff is incomplete — fix it before committing"

log "Regenerating overview"
"$AGENT_DIR/overview.sh" >/dev/null

branch="$(git -C "$REPO_ROOT" branch --show-current)"
if [[ "$branch" != issue-"$n"-* ]]; then
  warn "current branch '$branch' is not issue-$n-* — are you in the task worktree (build/worktrees/)?"
fi

git -C "$REPO_ROOT" add "$hfile" 2>/dev/null || true
[[ -f "$REPO_ROOT/Docs/status/OVERVIEW.md" ]] && git -C "$REPO_ROOT" add "$REPO_ROOT/Docs/status/OVERVIEW.md" 2>/dev/null || true
[[ -f "$REPO_ROOT/Docs/handoffs/INDEX.md" ]] && git -C "$REPO_ROOT" add "$REPO_ROOT/Docs/handoffs/INDEX.md" 2>/dev/null || true

if ! git -C "$REPO_ROOT" diff --cached --quiet; then
  task="$(task_of "$n")"
  git -C "$REPO_ROOT" commit -q -m "chore(agent): handoff for #$n ($task)"
  ok "committed handoff, overview and index"
else
  printf '  no handoff changes to commit\n'
fi

# Mirror as an idempotent issue comment.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
{
  echo '<!-- handoff:start -->'
  echo
  cat "$hfile"
  echo
  echo '<!-- handoff:end -->'
} > "$tmp"

cid="$(gh api "repos/$REPO/issues/$n/comments?per_page=100" \
  --jq '.[] | select(.body | contains("<!-- handoff:start -->")) | .id' 2>/dev/null \
  | awk 'NR==1{print; exit}' || true)"

if [[ -n "$cid" ]]; then
  gh api -X PATCH "repos/$REPO/issues/comments/$cid" -F "body=@$tmp" >/dev/null
  ok "updated the handoff comment on #$n"
else
  gh api -X POST "repos/$REPO/issues/$n/comments" -F "body=@$tmp" >/dev/null
  ok "posted a handoff comment on #$n"
fi

set_state_label "$n" "$state"
ok "issue #$n → $(state_label_for "$state")"
