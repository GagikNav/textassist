---
description: "Regenerate the holistic project overview and handoff index from GitHub issues, labels, milestones, and handoffs."
---

Apply the **sync-overview** skill (`.agents/skills/sync-overview/SKILL.md`).

1. Run `Scripts/agent/overview.sh`.
2. Show the user the milestone progress table and the "Now" section from
   `Docs/status/OVERVIEW.md`.
3. Note whether Project sync is active; if not, tell the user to run
   `gh auth refresh -s project`.

Generated files — never hand-edit them.
