---
name: pickup-task
description: "Pick up a Text Assist GitHub issue and start work: validate Definition of Ready, check dependencies and blockers, create the branch, flip the state label, and print a readiness brief. Use when starting a task, claiming an issue, or asking 'what should I work on', 'pick up #N', 'start task'."
argument-hint: "<issue-number>"
---

# Pick up a task

## When to use
- Starting work on a task issue.
- Asking which task to do next (no argument = list `agent:ready` issues).

## Procedure
1. If no issue number is given, run `Scripts/agent/pickup.sh` with no args to list
   `agent:ready` issues and stop.
2. Otherwise run `Scripts/agent/pickup.sh <n>`. It prints: the issue, its task ID,
   epic, milestone, dependencies, and the latest handoff — and validates the DoR.
3. Read `.agents/workflow.md` §7 (Definition of Ready). If **not** ready:
   - set `agent:blocked` via `Scripts/agent/issue-state.sh <n> blocked`,
   - comment the unmet condition on the issue, and stop.
4. If ready and it is an **epic** (has open sub-issues), do not work on it directly —
   go to the `delegate-subissue` skill.
5. If ready and it is a **leaf**, start it with `Scripts/agent/pickup.sh <n> --start`.
   That creates an **isolated worktree** (`build/worktrees/issue-<n>-<slug>`) and sets
   `agent:in-progress`. **Do all subsequent work in that worktree** — never the main
   checkout — so parallel agents never collide. If a handoff already exists, run the
   `resume-session` skill first and continue (do not restart).

## Guardrails
- Never start a task whose dependencies are open.
- Never work in the main checkout — always `cd` into the task worktree first.
- Never start a `sequentialTasks` item (`T3.5`, `T4.4`, `T6.1`, `T6.2`) while another
  is in progress — same file (`SummarizationOrchestrator.swift`).
- Remove the worktree after the PR merges: `Scripts/agent/worktree.sh <n> --remove`.
