---
name: delegate-subissue
description: "Delegate an epic's sub-issues to child orchestrators that run the same workflow recursively. Use when an issue has open sub-issues, when running an epic, or when asked to 'delegate', 'break down', or 'fan out' work."
argument-hint: "<epic-issue-number>"
---

# Delegate sub-issues

## When to use
- The picked-up issue has open **sub-issues** (it is an epic).
- Asked to fan out an epic's work.

## Procedure
1. Run `Scripts/agent/delegate.sh <epic#>` to list the open sub-issues with their
   dependencies, in dependency order.
2. For **each** open sub-issue, start a **child orchestrator** subagent with the
   **Orchestrator** agent, giving it the sub-issue number. The child runs the full
   loop (`pickup` → `context` → `implement` → `verify` → `review` → `handoff`).
3. The parent orchestrator only tracks, unblocks, and aggregates. **It must not
   implement a child's work.**
4. Enforce `maxDepth` (2) from `.agents/config.json`. If a sub-issue has its own open
   sub-issues at depth 2, stop and report — the plan said depth 2 is leaves.
5. Serialise `sequentialTasks` (`T3.5`, `T4.4`, `T6.1`, `T6.2`): never run two at once.
6. Read-only children (explorer/reviewer) may run in parallel.

## Output
A table of sub-issues → child agent → state, plus what is blocked and why. Update the
parent epic's task checklist as children complete.
