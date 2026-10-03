#!/usr/bin/env bash
# Pick up a task: validate Definition of Ready and print a readiness brief.
# Read-only by design; the caller flips the state label via issue-state.sh.
#
# Usage:
#   pickup.sh            # list agent:ready and agent:in-progress issues
#   pickup.sh <issue#>   # readiness brief for one issue
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"
require_gh

if [[ $# -eq 0 ]]; then
  log "Ready tasks (agent:ready + kind:task)"
  gh issue list --repo "$REPO" --label agent:ready --label kind:task --state open --limit 100 \
    --json number,title,milestone \
    --jq '.[] | "  #\(.number)\t\(.milestone.title // "-")\t\(.title)"' | sort || true
  echo
  log "Epics ready to delegate (agent:ready + kind:epic)"
  gh issue list --repo "$REPO" --label agent:ready --label kind:epic --state open --limit 100 \
    --json number,title \
    --jq '.[] | "  #\(.number)\t\(.title)"' | sort || true
  echo
  log "In progress (agent:in-progress)"
  gh issue list --repo "$REPO" --label agent:in-progress --state open --limit 100 \
    --json number,title \
    --jq '.[] | "  #\(.number)\t\(.title)"' || true
  exit 0
fi

n="$1"
gh issue view "$n" --repo "$REPO" --json number,title,state,labels,milestone,body >/dev/null 2>&1 \
  || die "issue #$n not found in $REPO"

task="$(task_of "$n")"; [[ -n "$task" ]] || task="(unmapped)"
epic="$(epic_of "$n")"
ms="$(issue_milestone "$n")"
printf '%b\n' "${c_bold}#$n  $task${c_reset}"
printf 'state      : %s\n' "$(gh issue view "$n" --repo "$REPO" --json state --jq '.state')"
printf 'title      : %s\n' "$(gh issue view "$n" --repo "$REPO" --json title --jq '.title')"
printf 'epic       : %s\n' "${epic:-—}"
printf 'milestone  : %s\n' "${ms:-—}"
printf 'labels     : %s\n' "$(gh issue view "$n" --repo "$REPO" --json labels --jq '[.labels[].name] | join(", ")')"

# Dependencies
echo
log "Dependencies"
deps="$(deps_of "$n")"
unmet=0
if [[ -z "$deps" ]]; then
  printf '  none\n'
else
  for d in $deps; do
    if issue_is_closed "$d"; then
      printf '  #%s closed  ✓\n' "$d"
    else
      printf '  #%s OPEN    ✗ (blocker)\n' "$d"
      unmet=$((unmet + 1))
    fi
  done
fi

# Sub-issues (is this an epic?)
subs="$(gh api "repos/$REPO/issues/$n/sub_issues" --jq 'length' 2>/dev/null || echo 0)"
echo
if [[ "${subs:-0}" -gt 0 ]]; then
  printf 'sub-issues : %s open → this is an EPIC. Delegate via the delegate-subissue skill.\n' "$subs"
else
  printf 'sub-issues : none → leaf task.\n'
fi

# Definition of Ready
echo
log "Definition of Ready"
dor_ok=1
[[ "$unmet" -eq 0 ]] || { warn "unmet dependencies ($unmet)"; dor_ok=0; }
labels="$(gh issue view "$n" --repo "$REPO" --json labels --jq '[.labels[].name] | join(" ")')"
for need in "kind:" "size:" "area:" "epic:"; do
  printf '%s' "$labels" | grep -q "$need" || { warn "missing a $need label"; dor_ok=0; }
done
if printf '%s' "$labels" | grep -qE 'agent:(ready|in-progress|blocked|review|done)'; then
  printf '  state label present\n'
else
  warn "no agent:* state label"; dor_ok=0
fi
if [[ "${subs:-0}" -gt 0 ]]; then
  warn "epic with open sub-issues — delegate, do not implement"; dor_ok=0
fi

# Existing handoff
hp="$(handoff_path "$n")"
echo
if [[ -n "$hp" ]]; then
  log "Existing handoff: ${hp#"$REPO_ROOT"/}"
  printf '  continue from its "Resume here" section (do not restart).\n'
else
  printf 'No handoff yet — this is a fresh task.\n'
fi

echo
if [[ "$dor_ok" -eq 1 ]]; then
  ok "READY — start with: Scripts/agent/issue-state.sh $n in-progress"
else
  warn "NOT READY — resolve the items above (set agent:blocked if a dependency is open)"
  exit 2
fi
