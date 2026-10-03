# `.agents/state/` — ephemeral session scratch

Not the source of truth. Kept for the current session's short-lived working notes.

- `session.md` is **git-ignored** (see the repo `.gitignore`). Delete it any time.
- Durable state lives in:
  1. `Docs/handoffs/issue-<n>-<slug>.md` (committed) — the **Resume here** section.
  2. The issue's `agent:*` label and its mirrored handoff comment.
  3. `Docs/status/OVERVIEW.md` (generated).

If `session.md` and a handoff disagree, the handoff wins. When you finish a session,
fold anything worth keeping into the handoff and remove `session.md`.
