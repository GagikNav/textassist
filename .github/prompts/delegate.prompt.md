---
description: "Delegation: list an epic's open sub-issues and spawn a child Orchestrator subagent per sub-issue (recursive, max depth 2)."
argument-hint: "<epic-issue-number>"
---

Apply the **delegate-subissue** skill (`.agents/skills/delegate-subissue/SKILL.md`).

1. Run `Scripts/agent/delegate.sh <epic#>` for the issue the user gave.
2. For each open sub-issue, start a **child Orchestrator** subagent (`Orchestrator`
   agent) scoped to that sub-issue; it runs the full workflow loop.
3. The parent aggregates only — it must not implement a child's work.
4. Enforce `maxDepth` = 2 and serialise `T3.5`, `T4.4`, `T6.1`, `T6.2`.
5. Report the sub-issue → child → state table and what is blocked.
