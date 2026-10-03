---
name: resume-session
description: "Resume work in a fresh session or with a different model/harness: find in-progress and ready issues, read the latest handoff, rebuild context, and continue from the recorded next action. Use at the start of a session, when asked to 'resume', 'continue where I left off', 'catch me up'."
---

# Resume a session

## When to use
- At the start of any new session.
- After switching model or harness.

## Procedure
1. Read `AGENTS.md`, then `.agents/workflow.md` §9.
2. Run `Scripts/agent/pickup.sh` with no args to list `agent:ready` and
   `agent:in-progress` issues, plus open PRs (`gh pr list`).
3. Show `Docs/status/OVERVIEW.md` for the holistic picture.
4. If exactly one issue is `agent:in-progress`, open its
   `Docs/handoffs/issue-<n>-*.md`, print the **Resume here** section, check out its
   branch, and continue from **Next action**.
5. If several, or none, print the brief and ask which to continue (or which ready task
   to pick up).

## Rules
- Never restart a task that has a handoff — continue it; "Do not redo" lists finished work.
- Never rely on chat history; if the handoff is missing a Resume-here section, fix the
  handoff before continuing.
