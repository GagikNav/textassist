#!/usr/bin/env bash
# Normalize every mapped issue: apply kind/size/area/epic labels, assign the
# milestone, and set exactly one agent state label from the dependency graph.
# Idempotent. Also closes the approved M0 design gate (#28, #29).
#
# Usage:
#   normalize-issues.sh                 # labels + milestones + states, closes M0
#   normalize-issues.sh --skip-m0       # do not close the M0 gate
#   normalize-issues.sh --sync-project  # also push status to the GitHub Project
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"
require_gh

close_m0=1; sync=0
for a in "$@"; do
  case "$a" in
    --skip-m0)      close_m0=0 ;;
    --sync-project) sync=1 ;;
    *) die "unknown option: $a" ;;
  esac
done
[[ "$sync" -eq 1 ]] || export AGENT_PROJECT_SYNC=0

# --- tasks ------------------------------------------------------------------

log "Tasks"
for n in $(jq -r '.issues | keys[]' "$CONFIG" | sort -n); do
  task="$(task_of "$n")"
  size="$(field_of "$n" size)"
  area="$(field_of "$n" area)"
  epic="$(field_of "$n" epic)"
  ms="$(milestone_name "$(field_of "$n" milestone)")"

  unmet=0
  for d in $(deps_of "$n"); do
    issue_is_closed "$d" || unmet=$((unmet + 1))
  done
  if [[ "$unmet" -eq 0 ]]; then state="ready"; else state="blocked"; fi

  gh issue edit "$n" --repo "$REPO" \
    --add-label "kind:task" --add-label "size:$size" --add-label "area:$area" --add-label "epic:$epic" \
    ${ms:+--milestone "$ms"} >/dev/null
  set_state_label "$n" "$state"
  printf '  #%-3s %-6s %-7s %s\n' "$n" "$task" "$state" "$ms"
done

# --- epics ------------------------------------------------------------------

log "Epics"
for n in $(jq -r '.epics | keys[]' "$CONFIG" | sort -n); do
  ep="$(jq -r --arg n "$n" '.epics[$n].taskEpic' "$CONFIG")"
  ms="$(milestone_name "$(jq -r --arg n "$n" '.epics[$n].milestone' "$CONFIG")")"

  if [[ "$n" == "29" ]]; then
    state="blocked"; [[ "$close_m0" -eq 1 ]] && state="done"
  elif [[ "$close_m0" -eq 1 ]] || issue_is_closed 28; then
    state="ready"
  else
    state="blocked"
  fi

  gh issue edit "$n" --repo "$REPO" \
    --add-label "kind:epic" --add-label "epic:$ep" ${ms:+--milestone "$ms"} >/dev/null
  set_state_label "$n" "$state"
  printf '  #%-3s Epic %-2s %-7s %s\n' "$n" "$ep" "$state" "$ms"
done

# --- M0 gate ----------------------------------------------------------------

if [[ "$close_m0" -eq 1 ]]; then
  log "Closing approved M0 design gate"
  for n in 28 29; do
    set_state_label "$n" done
    if ! issue_is_closed "$n"; then
      gh issue close "$n" --repo "$REPO" --reason completed \
        --comment "M0 design gate approved (see AGENTS.md). Closing so Epics 1-6 can start." >/dev/null
      ok "closed #$n"
    else
      printf '  #%s already closed\n' "$n"
    fi
  done
fi

ok "normalization complete"
