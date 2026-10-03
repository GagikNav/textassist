---
name: sync-board
description: "Reconcile the GitHub Project board with issue ground truth: unblock tasks whose dependencies are all closed, move them to the Ready column, verify the Status column against done work, and push corrections. Use when asked to 'sync the board', 'what's ready', 'unblock', 'move to ready', 'check the board', or after merges close dependencies."
---

# Sync the board

## When to use
- After merges close dependencies, so blocked tasks should become ready.
- When asked "what's ready", "unblock", "sync the board", or to check the board's
  Status column against real state.

## Ground truth
- Machine state = `agent:*` labels, exactly one per issue. The board **Status** column
  only mirrors them (`.agents/config.json` → `project.statusMap`): `agent:ready` →
  **Ready**, `agent:in-progress` → In Progress, `agent:blocked` → **Backlog**,
  `agent:review` → In Review, `agent:done` → Done.
- Dependencies live in `.agents/config.json` → `issues.<n>.blockedBy`. An issue is
  **independently ready** when every dep in `blockedBy` is closed.

## GitHub operations — MCP first, to avoid the rate limit
- **Reads go through the GitHub MCP tools, never `gh`.** Enumerate candidates with
  `list_issues`; check an issue's state/labels with `issue_read`. These hit the REST
  API, which has a far higher quota than the GraphQL endpoints `gh project *` burns.
- **`gh` is reserved for the board only.** No MCP tool covers GitHub Projects, so the
  Status push must use `gh`/`Scripts/agent/*.sh` — but only for items whose label or
  column actually changes. Never blanket re-push.
- **Writes** are `Scripts/agent/issue-state.sh <n> <state>`: the single deterministic
  writer that sets exactly one `agent:` label and pushes the board Status. Call it
  once per changed item, not once per issue in the sweep.

## Procedure

### 1. Unblock what is now ready
1. List candidates with the GitHub MCP `list_issues` tool (`state: OPEN`,
   `labels: [agent:blocked]`; owner/repo from `.agents/config.json`).
2. For each, read its deps:
   `jq -r --arg n "$n" '.issues[$n].blockedBy[]?' .agents/config.json`.
   Skip any issue not in the config map — it needs `issue-contract` first.
3. Check each dep with the GitHub MCP `issue_read` tool (method `get`) — a dep is
   closed when its `state` is `CLOSED`. If every dep is closed, promote with
   `Scripts/agent/issue-state.sh <n> ready`. That sets `agent:ready` and pushes the
   board Status to Ready in one step.
4. If some dep is still open, leave it blocked and name the unmet dep in the report.
   Never promote anything that is already `in-progress`, `review`, or `done` — only
   flip `agent:blocked`.

### 2. Verify done work on the board
1. Dump the board: `gh project item-list <number> --owner <owner> --format json --limit 500`
   (number/owner from `.agents/config.json` → `project`).
2. Compare against ground truth: every **closed** issue and every `agent:done` issue
   must sit in the **Done** column. List them with the GitHub MCP `list_issues` tool
   (`state: CLOSED`, `labels: [agent:done]`).
3. For each mismatch, re-push the state: `Scripts/agent/issue-state.sh <n> done`.
   This is idempotent and only corrects drift (e.g. the token lacked the `project`
   scope when the handoff ran).

### 3. Report
Print a table of what changed:
- moved → ready (naming the closed deps that unblocked each),
- board corrected (issue → Done),
- still blocked (issue → the open dep holding it).

If anything changed, run `Scripts/agent/overview.sh` to refresh
`Docs/status/OVERVIEW.md` and `Docs/handoffs/INDEX.md`.

## Rules
- The board is a mirror, never the source of truth. Fix the label first
  (`issue-state.sh`, which also pushes the board); never edit the board directly.
- Promote blocked → ready only when **all** `blockedBy` deps are closed.
- `gh` needs the `project` scope (`gh auth status` lists it) or board sync is skipped
  with a warning — refresh with `gh auth refresh -s project`.
- Board columns are `Backlog`, `Ready`, `In Progress`, `In Review`, `Done` (the
  board's `Status` field). Blocked tasks sit in **Backlog**; ready tasks in **Ready**.
  `statusMap` is the single source of the label → column mapping.
