---
description: "Resume work in a fresh session or with a different model/harness: find in-progress work, read the handoff, and continue from the recorded next action."
---

Apply the **resume-session** skill (`.agents/skills/resume-session/SKILL.md`).

1. Read `AGENTS.md` and `.agents/workflow.md` §9.
2. Run `Scripts/agent/pickup.sh` (no argument) and `gh pr list`.
3. Show `Docs/status/OVERVIEW.md`.
4. For the single in-progress issue, open its `Docs/handoffs/issue-<n>-*.md`, print the
   **Resume here** section, check out the branch, and continue from **Next action**.
5. If none or several, print the brief and ask which to continue or pick up.

Never restart a task that already has a handoff — continue it.
