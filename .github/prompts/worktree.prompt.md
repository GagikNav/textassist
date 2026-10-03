---
description: "Manage the per-task git worktree used to isolate parallel agents (create, list, remove)."
argument-hint: "<issue-number> | --list | <issue-number> --remove"
---

Worktrees isolate each task so parallel agents never disturb each other's checkout.

- **Create/enter** for an issue: run `Scripts/agent/worktree.sh <n>` — it creates
  `build/worktrees/issue-<n>-<slug>` on branch `issue-<n>-<slug>` off `main` (or checks
  out the existing branch). Then `cd` into it and do all work there.
- **One-step start** (recommended): `Scripts/agent/pickup.sh <n> --start` creates the
  worktree and sets `agent:in-progress`.
- **List**: `Scripts/agent/worktree.sh --list`.
- **Remove** after the PR merges: `Scripts/agent/worktree.sh <n> --remove`
  (`WT_FORCE=1` to force if dirty).

Never edit files or run builds in the main checkout for a task.
