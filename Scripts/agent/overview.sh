#!/usr/bin/env bash
# Regenerate the holistic overview and the handoff index.
#
# Usage: overview.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"
require_gh

mkdir -p "$REPO_ROOT/Docs/status" "$REPO_ROOT/Docs/handoffs"

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
gh issue list --repo "$REPO" --state all --limit 400 \
  --json number,title,state,milestone,labels,updatedAt > "$tmp"

overview="$REPO_ROOT/Docs/status/OVERVIEW.md"
index="$REPO_ROOT/Docs/handoffs/INDEX.md"

project_line="Project: _not linked — run \`gh auth refresh -s project\` then re-run_"
if has_project_scope; then
  num="$PROJECT_NUMBER"
  if [[ -z "$num" ]]; then
    num="$(gh project list --owner "$PROJECT_OWNER" --format json 2>/dev/null \
      | jq -r '(.projects // .)[0].number // empty' || true)"
  fi
  [[ -n "$num" ]] && project_line="Project: [#$num](https://github.com/users/$PROJECT_OWNER/projects/$num)"
fi

bar() {
  local pct="$1" filled=$(( $1 / 10 )) i out=""
  for ((i = 0; i < 10; i++)); do
    if [[ $i -lt $filled ]]; then out="$out#"; else out="$out."; fi
  done
  printf '%s' "$out"
}

{
  echo "# Text Assist — Work Overview"
  echo
  echo "_Generated $(date '+%Y-%m-%d %H:%M') by \`Scripts/agent/overview.sh\`. Do not edit by hand._"
  echo
  echo "- Repo: [$REPO](https://github.com/$REPO)"
  echo "- $project_line"
  echo "- Total issues: $(jq 'length' "$tmp")"
  echo
  echo "## Milestones"
  echo
  echo "| Milestone | Done | Total | Progress |"
  echo "|:--|--:|--:|:--|"
  for m in M0 M1 M2 M3 M4 M5; do
    title="$(milestone_name "$m")"
    [[ -n "$title" ]] || continue
    total=$(jq --arg t "$title" '[.[] | select(.milestone.title==$t)] | length' "$tmp")
    closed=$(jq --arg t "$title" '[.[] | select(.milestone.title==$t and .state=="CLOSED")] | length' "$tmp")
    pct=0; [[ "$total" -gt 0 ]] && pct=$(( closed * 100 / total ))
    printf '| %s | %s | %s | `%s` %s%% |\n' "$title" "$closed" "$total" "$(bar "$pct")" "$pct"
  done
  echo
  echo "## Now"
  echo
  echo "**In progress**"
  gh issue list --repo "$REPO" --label agent:in-progress --label kind:task --state open --limit 50 \
    --json number,title --jq '.[] | "- #\(.number) \(.title)"' || echo "- _none_"
  echo
  echo "**Ready**"
  gh issue list --repo "$REPO" --label agent:ready --label kind:task --state open --limit 50 \
    --json number,title --jq '.[] | "- #\(.number) \(.title)"' || echo "- _none_"
  echo
  echo "**Blocked**"
  gh issue list --repo "$REPO" --label agent:blocked --label kind:task --state open --limit 100 \
    --json number,title --jq '.[] | "- #\(.number) \(.title)"' || echo "- _none_"
  echo
  echo "**Epics ready to delegate**"
  gh issue list --repo "$REPO" --label agent:ready --label kind:epic --state open --limit 50 \
    --json number,title --jq '.[] | "- #\(.number) \(.title)"' || echo "- _none_"
  echo
  echo "## Epics"
  echo
  for n in $(jq -r '.epics | keys[]' "$CONFIG" | sort -n); do
    title="$(gh issue view "$n" --repo "$REPO" --json title --jq '.title' 2>/dev/null || echo "Epic #$n")"
    echo "### #$n $title"
    echo
    sub="$(gh api "repos/$REPO/issues/$n/sub_issues" 2>/dev/null || echo '[]')"
    echo "| Task | Issue | State |"
    echo "|:--|--:|:--|"
    printf '%s' "$sub" | jq -r '.[] | "| \(.title) | #\(.number) | \(.state) |"' || echo "| _none_ | | |"
    echo
  done
  echo "## Recent handoffs"
  echo
  if compgen -G "$REPO_ROOT/Docs/handoffs/issue-*.md" >/dev/null; then
    for f in $(ls -t "$REPO_ROOT/Docs/handoffs/"issue-*.md | awk 'NR<=10'); do
      b="$(basename "$f")"
      echo "- [$b](../handoffs/$b)"
    done
  else
    echo "_None yet._"
  fi
} > "$overview"

{
  echo "# Handoff index"
  echo
  echo "_Generated $(date '+%Y-%m-%d %H:%M') by \`Scripts/agent/overview.sh\`. Do not edit by hand._"
  echo
  echo "| Issue | Task | Status | Updated | File |"
  echo "|--:|:--|:--|:--|:--|"
  if compgen -G "$REPO_ROOT/Docs/handoffs/issue-*.md" >/dev/null; then
    for f in $(ls -t "$REPO_ROOT/Docs/handoffs/"issue-*.md); do
      b="$(basename "$f")"
      num="$(printf '%s' "$b" | sed -E 's/^issue-([0-9]+)-.*/\1/')"
      task="$(task_of "$num")"
      status="$(grep -E '^\| Status \|' "$f" | awk -F'|' '{gsub(/ /,"",$3); print $3}' || true)"
      updated="$(grep -E '^\| Updated \|' "$f" | awk -F'|' '{gsub(/ /,"",$3); print $3}' || true)"
      printf '| #%s | %s | %s | %s | [%s](./%s) |\n' "$num" "${task:-?}" "${status:-?}" "${updated:-?}" "$b" "$b"
    done
  else
    echo "| _none_ | | | | |"
  fi
} > "$index"

ok "wrote Docs/status/OVERVIEW.md and Docs/handoffs/INDEX.md"
