---
name: sync-overview
description: "Regenerate the holistic project overview and handoff index from GitHub issues, labels, milestones, and handoff docs. Use after finishing a task, before a status update or standup, or when asked for 'overview', 'status', 'where are we'."
---

# Sync the overview

## When to use
- After any handoff.
- When asked for a holistic status of the whole project.

## Procedure
1. Run `Scripts/agent/overview.sh`. It reads `gh issue list` (all states), milestones,
   labels, and `Docs/handoffs/`, then writes:
   - `Docs/status/OVERVIEW.md` — milestones M0–M5 with progress, per-epic tables,
     in-progress/blocked lists, and the latest handoffs.
   - `Docs/handoffs/INDEX.md` — issue → handoff file → status → date.
2. If the Project scope is available, it also prints a link to the board; otherwise it
   notes that Project sync is skipped (see `Scripts/agent/bootstrap.sh` output).
3. Commit the regenerated files with the task's handoff (not as a separate change).

## Rules
- Generated files — never hand-edit them; edit the source (issues, labels, handoffs).
- Keep the overview short enough to read in a minute.
