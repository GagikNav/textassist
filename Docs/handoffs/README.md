# Handoffs

One handoff per task issue: `issue-<n>-<slug>.md`. These are the durable memory of the
project — the file a fresh session (or a different model) resumes from. Committed on the
task branch, so the merged commit carries its own record, and mirrored to the issue as a
comment by `Scripts/agent/handoff.sh`.

## Rules

1. Start from `.agents/templates/handoff.md`.
2. The `## 8. Resume here` section is **mandatory** and must name a single **Next action**.
3. Record the build-check result and the issue's "Done when" checklist (pass/fail).
4. Never paste whole files — reference paths and symbols.
5. `INDEX.md` and `Docs/status/OVERVIEW.md` are generated; do not hand-edit them.

## Lifecycle

| State | Meaning |
|:--|:--|
| `agent:ready` | Dependencies closed; not started. |
| `agent:in-progress` | Being worked on; a handoff exists and is kept current. |
| `agent:blocked` | Waiting on a dependency or a human. |
| `agent:review` | Implemented; awaiting independent review. |
| `agent:done` | Build passed, Done-when checked, handoff written, PR merged. |

Pause at any time by updating the handoff and running `Scripts/agent/handoff.sh <n>`;
resume with `Scripts/agent/pickup.sh` and the `resume-session` skill.
