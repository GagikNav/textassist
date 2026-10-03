---
description: "Independently review a change against the issue's Done-when, the AGENTS.md constraints, and scope. Runs the build."
argument-hint: "<issue-number>"
---

Use the **Reviewer** agent (or apply the **review-change** skill,
`.agents/skills/review-change/SKILL.md`) for the issue the user gave.

1. Read the issue's **Done when**, the handoff Plan, and the diff.
2. Run the build check from `.agents/config.json`.
3. Verify the `AGENTS.md` hard constraints (no `project.pbxproj` edits, macOS 13 APIs,
   MainActor isolation, sandbox off, non-activating panels, doc comments, no scope creep).
4. Fill `.agents/templates/review.md`: verdict, build, Done-when checklist, blocking
   findings, non-blocking notes, scope check.

Read-only: never edit the change under review.
