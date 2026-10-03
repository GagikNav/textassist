# `.agents/` — Text Assist agent workflow (canonical)

This folder is the **single source of truth** for how agents work in this repo. It is
harness-agnostic: GitHub Copilot, Claude Code, or any AGENTS.md-aware tool reads the
same files. Harness-specific folders (`.github/`, `CLAUDE.md`) are thin adapters.

## Layout

| Path | Purpose |
|:--|:--|
| `config.json` | Repo, labels, milestones, issue→task/dependency map, `maxDepth`. Scripts read this. |
| `MANUAL.md` | **Human manual:** what every skill, agent, prompt and script does, and how to use them. Start here. |
| `workflow.md` | The canonical loop, roles, delegation rules, guardrails, DoR/DoD. **Read this first.** |
| `agents/*.agent.md` | Canonical agent definitions (orchestrator, explorer, implementer, reviewer). Copilot reads them via the `.github/agents` symlink. |
| `skills/<name>/SKILL.md` | Shared, on-demand skills. VS Code Copilot discovers `.agents/skills/` natively. |
| `templates/*.md` | Handoff, context brief, review, issue-body, PR-body templates. |
| `state/README.md` | Ephemeral session scratch. Canonical state lives in the handoff + GitHub. |

## How an agent starts a session

1. Read `AGENTS.md` (project onboarding + hard constraints).
2. Read `.agents/workflow.md` (this repo's agent loop).
3. Run the `resume-session` skill (`/resume`) or the `pickup-task` skill (`/pickup <issue#>`).

## Harness adapters (generated, do not edit the core here)

- **GitHub Copilot** — `.github/copilot-instructions.md`, `.github/instructions/`,
  `.github/prompts/`, `.github/agents/` (symlink → `../.agents/agents`).
- **Claude Code / generic** — root `AGENTS.md`; `CLAUDE.md` points here.
- Adding another harness = add a new adapter that points back at this folder. Never fork the rules.

## Scripts

`Scripts/agent/*.sh` implement the deterministic parts (worktrees, pickup, state sync,
handoff, overview). Prompts and skills call them; they are safe to run by hand.

- `worktree.sh <n>` — create/list/remove the per-task worktree (parallel isolation).
- `pickup.sh <n> --start` — validate readiness, create the worktree, set `agent:in-progress`.
- `handoff.sh <n> [state]` — commit the handoff, mirror it to the issue, sync the label.
- `overview.sh` — regenerate `Docs/status/OVERVIEW.md` and `Docs/handoffs/INDEX.md`.
- `normalize-issues.sh` / `bootstrap.sh` / `issue-state.sh` / `delegate.sh` / `link-agents.sh` — supporting.
