#!/usr/bin/env bash
# Shared helpers for the Text Assist agent workflow.
# Sourced by the other Scripts/agent/*.sh scripts. Bash 3.2 compatible (macOS).
# shellcheck shell=bash

set -euo pipefail

AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$AGENT_DIR" rev-parse --show-toplevel)"
CONFIG="$REPO_ROOT/.agents/config.json"

[[ -f "$CONFIG" ]] || { echo "missing $CONFIG" >&2; exit 1; }

REPO="$(jq -r '.repo' "$CONFIG")"
DEFAULT_BRANCH="$(jq -r '.defaultBranch' "$CONFIG")"
BUILD_CMD="$(jq -r '.build.command' "$CONFIG")"
MAX_DEPTH="$(jq -r '.maxDepth' "$CONFIG")"
PROJECT_OWNER="$(jq -r '.project.owner' "$CONFIG")"
PROJECT_NUMBER="$(jq -r '.project.number // empty' "$CONFIG")"
PROJECT_STATUS_FIELD="$(jq -r '.project.statusField' "$CONFIG")"

# Agent state labels (exactly one applies to an issue at a time).
AGENT_STATE_LABELS="agent:ready agent:in-progress agent:blocked agent:review agent:done"

c_reset=$'\033[0m'; c_dim=$'\033[2m'; c_bold=$'\033[1m'
c_red=$'\033[31m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_blue=$'\033[34m'

log()  { printf '%b\n' "${c_blue}▸${c_reset} $*"; }
ok()   { printf '%b\n' "${c_green}✓${c_reset} $*"; }
warn() { printf '%b\n' "${c_yellow}!${c_reset} $*" >&2; }
die()  { printf '%b\n' "${c_red}✗${c_reset} $*" >&2; exit 1; }

require_gh() {
  command -v gh >/dev/null 2>&1 || die "gh CLI not found"
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated (run: gh auth login)"
  command -v jq >/dev/null 2>&1 || die "jq not found"
}

# --- config accessors -------------------------------------------------------

cfg_raw()  { jq -r "$1" "$CONFIG"; }
task_of()  { jq -r --arg n "$1" '.issues[$n].task // empty' "$CONFIG"; }
epic_of()  { jq -r --arg n "$1" '.issues[$n].epic // empty' "$CONFIG"; }
field_of() { jq -r --arg n "$1" --arg f "$2" '.issues[$n][$f] // empty' "$CONFIG"; }
deps_of()  { jq -r --arg n "$1" '.issues[$n].blockedBy[]? // empty' "$CONFIG"; }

milestone_name() { jq -r --arg m "$1" '.milestones[$m] // empty' "$CONFIG"; }
issue_milestone() { jq -r --arg n "$1" '.issues[$n].milestone // empty' "$CONFIG"; }

state_label_for() {
  case "$1" in
    ready)       printf 'agent:ready' ;;
    in-progress) printf 'agent:in-progress' ;;
    blocked)     printf 'agent:blocked' ;;
    review)      printf 'agent:review' ;;
    done)        printf 'agent:done' ;;
    *) die "unknown state: $1" ;;
  esac
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' \
    | cut -c1-60
}

handoff_path() {
  local n="$1" f
  f="$(ls -1 "$REPO_ROOT/Docs/handoffs/issue-$n-"*.md 2>/dev/null | head -1 || true)"
  printf '%s' "$f"
}

# --- gh helpers -------------------------------------------------------------

issue_is_closed() {
  local state
  state="$(gh issue view "$1" --repo "$REPO" --json state --jq '.state' 2>/dev/null || echo UNKNOWN)"
  [[ "$state" == "CLOSED" ]]
}

# Remove every agent state label, then add exactly one. Best-effort Project sync.
set_state_label() {
  local n="$1" state="$2" target rm_args=""
  target="$(state_label_for "$state")"
  local l
  for l in $AGENT_STATE_LABELS; do
    [[ "$l" == "$target" ]] || rm_args="$rm_args --remove-label $l"
  done
  # shellcheck disable=SC2086
  gh issue edit "$n" --repo "$REPO" --add-label "$target" $rm_args >/dev/null
  sync_project_status "$n" "$state" || true
}

has_project_scope() {
  gh auth status 2>&1 | grep -q "'project'"
}

# Best-effort sync of the GitHub Project v2 Status field with the state label.
# Skipped (non-fatal) when the token lacks the `project` scope or no Project exists.
sync_project_status() {
  local n="$1" state="$2"
  [[ "${AGENT_PROJECT_SYNC:-1}" == "0" ]] && return 0
  has_project_scope || { warn "Project sync skipped: gh token lacks 'project' scope (run: gh auth refresh -s project)"; return 0; }

  local number project_id field_id option_id item_id status_name
  number="$PROJECT_NUMBER"
  if [[ -z "$number" ]]; then
    number="$(gh project list --owner "$PROJECT_OWNER" --format json 2>/dev/null | jq -r '(.projects // .)[0].number // empty' || true)"
  fi
  [[ -n "$number" ]] || { warn "Project sync skipped: no Project found for $PROJECT_OWNER"; return 0; }

  status_name="$(jq -r --arg l "$(state_label_for "$state")" '.project.statusMap[$l] // empty' "$CONFIG")"
  project_id="$(gh project view "$number" --owner "$PROJECT_OWNER" --format json 2>/dev/null | jq -r '.id // empty')"
  field_id="$(gh project field-list "$number" --owner "$PROJECT_OWNER" --format json 2>/dev/null | jq -r --arg f "$PROJECT_STATUS_FIELD" '.fields[]? | select(.name==$f) | .id')"
  option_id="$(gh project field-list "$number" --owner "$PROJECT_OWNER" --format json 2>/dev/null | jq -r --arg f "$PROJECT_STATUS_FIELD" --arg o "$status_name" '.fields[]? | select(.name==$f) | .options[]? | select(.name==$o) | .id')"
  [[ -n "$project_id" && -n "$field_id" && -n "$option_id" ]] || { warn "Project sync skipped: Status field/option '$status_name' not found"; return 0; }

  item_id="$(gh project item-list "$number" --owner "$PROJECT_OWNER" --format json --limit 500 2>/dev/null | jq -r --argjson n "$n" '.items[]? | select(.content.number==$n) | .id' | head -1)"
  if [[ -z "$item_id" ]]; then
    item_id="$(gh project item-add "$number" --owner "$PROJECT_OWNER" --url "https://github.com/$REPO/issues/$n" --format json 2>/dev/null | jq -r '.id // empty')"
  fi
  [[ -n "$item_id" ]] || { warn "Project sync skipped: could not resolve item for #$n"; return 0; }

  gh project item-edit --id "$item_id" --project-id "$project_id" \
    --field-id "$field_id" --single-select-option-id "$option_id" >/dev/null
  ok "Project status → $status_name"
}
