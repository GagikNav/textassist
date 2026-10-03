#!/usr/bin/env bash
# One-time (idempotent) bootstrap for the Text Assist agent workflow.
# Creates the agent labels and milestones, wires the .github/agents symlink,
# and updates .gitignore. Safe to re-run.
#
# Usage: bootstrap.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"

require_gh
cd "$REPO_ROOT"

log "Bootstrapping agent workflow for $REPO"

# --- 1. Labels --------------------------------------------------------------

create_label() {
  local name="$1" color="$2" desc="$3"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null
  printf '  label %s\n' "$name"
}

log "Labels"
while IFS='|' read -r name color desc; do
  [[ -z "${name// }" ]] && continue
  [[ "$name" == \#* ]] && continue
  create_label "$name" "$color" "$desc"
done <<'LABELS'
# state (exactly one per issue)
agent:ready|0e8a16|Dependencies closed; an agent can pick this up
agent:in-progress|1d76db|An agent/session is working on this
agent:blocked|b60205|Waiting on a dependency or a human
agent:review|fbca04|Implemented; awaiting independent review
agent:done|5319e7|Build passed, Done-when checked, handoff written
# kind
kind:epic|6f42c1|Parent issue containing sub-issues
kind:task|c5def5|Leaf task: one reviewable change
# size
size:S|d4c5f9|Small
size:M|a895d6|Medium
size:L|7f6ab3|Large
# area
area:models|bfd4f2|TextAssist/Models
area:providers|bfd4f2|TextAssist/Providers
area:core|bfd4f2|TextAssist/Core
area:stores|bfd4f2|TextAssist/Stores
area:ui|bfd4f2|TextAssist/UI
area:utilities|bfd4f2|TextAssist/Utilities
area:design|f9d0c4|Design docs and mockups
area:agents|d4c5f9|Agent workflow tooling
# epic
epic:0|5319e7|Epic 0 - Design gate
epic:1|5319e7|Epic 1 - Foundation
epic:2|5319e7|Epic 2 - Picker v2
epic:3|5319e7|Epic 3 - Write
epic:4|5319e7|Epic 4 - Chat
epic:5|5319e7|Epic 5 - Menu bar status
epic:6|5319e7|Epic 6 - P1 extras
LABELS
ok "labels ready"

# --- 2. Milestones ----------------------------------------------------------

log "Milestones"
existing_milestones="$(gh api "repos/$REPO/milestones?state=all&per_page=100" --jq '.[].title' 2>/dev/null || true)"
while IFS='|' read -r title desc; do
  [[ -z "${title// }" ]] && continue
  if printf '%s\n' "$existing_milestones" | grep -Fxq "$title"; then
    printf '  milestone exists: %s\n' "$title"
  else
    gh api "repos/$REPO/milestones" -f title="$title" -f description="$desc" >/dev/null
    printf '  milestone created: %s\n' "$title"
  fi
done <<'MILESTONES'
M0 - Design approved|Design gate. Mockup + tokens in Docs/design/v2/, approved (PRD-v2 section 8).
M1 - Foundation|T1.1-T1.4. Foundation compiles; Short Summary works as before.
M2 - Write + Replace|T2.1-T2.2, T3.1-T3.5. Option+Shift+S, g, Command+Return fixes text in TextEdit.
M3 - Chat|T4.1-T4.4. Chat with pinned selection and Continue in Chat.
M4 - Menu bar status|T5.1-T5.2. Green/red Ollama dot and model label.
M5 - Polish (P1)|T6.1-T6.4. Direct hotkeys, history, settings, model picker.
MILESTONES
ok "milestones ready"

# --- 3. .github/agents symlink ----------------------------------------------

log "Harness adapters"
"$AGENT_DIR/link-agents.sh"

# --- 4. .gitignore ----------------------------------------------------------

if ! grep -qxF '.agents/state/session.md' "$REPO_ROOT/.gitignore" 2>/dev/null; then
  {
    printf '\n# Agent workflow - ephemeral session scratch\n'
    printf '.agents/state/session.md\n'
  } >> "$REPO_ROOT/.gitignore"
  ok "added .agents/state/session.md to .gitignore"
else
  printf '  .gitignore already covers session.md\n'
fi

# --- 5. Project scope -------------------------------------------------------

log "GitHub Project"
if has_project_scope; then
  if gh project list --owner "$PROJECT_OWNER" --format json >/dev/null 2>&1; then
    ok "Project scope available; boards under $PROJECT_OWNER are reachable"
  else
    warn "Project scope present but no project could be listed for $PROJECT_OWNER"
  fi
else
  warn "gh token lacks the 'project' scope - Project board sync is disabled."
  warn "Enable it with:  gh auth refresh -s project"
fi

ok "bootstrap complete"
