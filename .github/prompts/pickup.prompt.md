---
description: "Pick up a Text Assist task: validate Definition of Ready, check dependencies, and print a readiness brief."
argument-hint: "<issue-number>"
---

Apply the **pickup-task** skill (`.agents/skills/pickup-task/SKILL.md`) to the issue
number the user gave (default: list what is ready).

1. Run `Scripts/agent/pickup.sh` with the issue number (or no argument to list ready
   and in-progress issues).
2. If the Definition of Ready is unmet, set `agent:blocked` via
   `Scripts/agent/issue-state.sh <n> blocked`, comment why, and stop.
3. If it is an epic with open sub-issues, do not implement — delegate instead.
4. Otherwise, set `agent:in-progress`, run `Scripts/agent/pickup.sh <n>` again if needed,
   and continue with the workflow in `.agents/workflow.md`.
