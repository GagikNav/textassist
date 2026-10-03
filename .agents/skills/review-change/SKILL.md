---
name: review-change
description: "Independently review a Text Assist change against the issue's Done-when, the AGENTS.md hard constraints, and scope. Runs the build check and returns blocking/non-blocking findings. Use after implementation, before handoff, or when asked to 'review', 'check the diff', 'is this done'."
argument-hint: "<issue-number>"
---

# Review a change

## When to use
- After implementation, before writing the handoff.
- Whenever a second, independent look is wanted.

## Procedure
1. Read the issue's **Done when**, the handoff's Plan, and the diff
   (`git diff <base>...HEAD`).
2. Run the build check from `.agents/config.json`.
3. Verify each constraint that the diff could touch:
   - no `TextAssist.xcodeproj/project.pbxproj` changes;
   - only macOS 13-safe APIs (`AGENTS.md` §3);
   - MainActor isolation handled like `OllamaProvider`;
   - sandbox off, panels non-activating;
   - `///` doc comments preserved on new public API;
   - no unrelated edits, no renames of existing types.
4. Check every "Done when" item; mark **pass / fail / can't verify** with evidence.
5. Fill `.agents/templates/review.md`.

## Rules
- Read-only. Never edit the change under review.
- Blocking = the task is not done or a hard constraint is broken. Everything else is a
  non-blocking note and must be labelled as such.
- If you cannot verify something (needs the running app), say so — do not assume pass.
