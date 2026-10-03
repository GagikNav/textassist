---
name: write-handoff
description: "Write the per-issue handoff document, commit it on the task branch, mirror it as an idempotent comment on the GitHub issue, and sync labels/Project status. Use when finishing or pausing a task, when handing off to another session/model, or when asked to 'write the handoff', 'save state', 'hand off'."
argument-hint: "<issue-number>"
---

# Write the handoff

## When to use
- Finishing or pausing a task.
- Before switching session, model, or harness.
- After the reviewer reports a verdict.

## Procedure
1. Fill `.agents/templates/handoff.md` at
   `Docs/handoffs/issue-<n>-<slug>.md`. The **Resume here** section is mandatory and
   must name the single next action.
2. Include the build-check result, the "Done when" checklist with pass/fail, and a
   complete **How to test manually** section (§5): copy-pasteable steps plus the
   expected result for each.
3. Run `Scripts/agent/handoff.sh <n>` **from the task worktree**. It:
   - validates the file has all sections,
   - commits it on the current branch,
   - mirrors it to the issue inside `<!-- handoff:start --> … <!-- handoff:end -->`
     markers (idempotent — updates the existing comment rather than duplicating),
   - sets the state label and syncs the Project status,
   - regenerates `Docs/status/OVERVIEW.md` and `Docs/handoffs/INDEX.md`.
4. Never mark `agent:done` unless the build passed and "Done when" is fully checked.

## Rules
- The handoff is the durable memory: write it so a different model with no chat history
  can continue from it alone.
- Do not paste whole files; reference paths and symbols.
