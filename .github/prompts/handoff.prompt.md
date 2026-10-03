---
description: "Write the handoff for a task: commit the handoff doc, mirror it to the issue, and sync labels/Project status."
argument-hint: "<issue-number>"
---

Apply the **write-handoff** skill (`.agents/skills/write-handoff/SKILL.md`).

1. Fill `.agents/templates/handoff.md` at `Docs/handoffs/issue-<n>-<slug>.md` for the
   issue the user gave. The **Resume here → Next action** section is mandatory.
2. Include the build-check result and the "Done when" checklist.
3. Run `Scripts/agent/handoff.sh <n> [state]` — it validates, commits, mirrors the
   comment on the issue, sets the state label, and regenerates the overview.
4. Never use `done` unless the build passed and every "Done when" item is checked.
