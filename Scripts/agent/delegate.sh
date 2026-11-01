#!/usr/bin/env bash
# List an epic's open sub-issues in dependency order and emit the child-orchestrator
# delegation plan. Read-only.
#
# Usage: delegate.sh <epic-issue-number>
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"
require_gh

[[ $# -eq 1 ]] || die "usage: delegate.sh <epic-issue-number>"
epic="$1"

gh issue view "$epic" --repo "$REPO" --json number >/dev/null 2>&1 || die "issue #$epic not found"

subs_json="$(gh api "repos/$REPO/issues/$epic/sub_issues" 2>/dev/null || echo '[]')"
count="$(printf '%s' "$subs_json" | jq 'length')"

printf '%b\n' "${c_bold}Delegation plan for epic #$epic${c_reset}"
if [[ "$count" -eq 0 ]]; then
  warn "no sub-issues — this is a leaf; implement it directly (no delegation)."
  exit 0
fi

printf 'depth      : 0 (epic) → 1 (task), maxDepth=%s\n' "$MAX_DEPTH"
echo

printf '%s' "$subs_json" | jq -r '.[] | [.number, (.state // "OPEN"), (.title // "")] | @tsv' \
| while IFS=$'\t' read -r num state title; do
    label="$(task_of "$num")"; [[ -n "$label" ]] || label="$(printf '%.44s' "$title")"
    deps="$(deps_of "$num")"
    ready="yes"
    blocked_list=""
    for d in $deps; do
      if ! issue_is_closed "$d"; then ready="no"; blocked_list="$blocked_list #$d"; fi
    done
    if [[ "$state" == "CLOSED" ]]; then
      printf '  #%-3s CLOSED     %s\n' "$num" "$label"
    elif [[ "$ready" == "yes" ]]; then
      printf '  #%-3s READY      %s  → spawn Orchestrator subagent on #%s\n' "$num" "$label" "$num"
    else
      printf '  #%-3s BLOCKED    %s  (by%s)\n' "$num" "$label" "$blocked_list"
    fi
  done

echo
log "Sequential constraint"
printf '  %s: only one task that edits these files runs at a time.\n' \
  "$(jq -r '.sequentialFiles | join(", ")' "$CONFIG")"
echo
log "Reminder"
printf '  The parent orchestrator aggregates only; it must not implement a child task.\n'
