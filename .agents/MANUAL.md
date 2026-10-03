# Text Assist — Agent Workflow Manual

The human-readable map of the agent system: **what every skill, agent, prompt and
script does, and how to use it.** This manual is the map; `.agents/workflow.md` is the
law (the rules every agent must follow). `AGENTS.md` is project onboarding.

---

## 60-second version

Starting a task:

```
Scripts/agent/pickup.sh 7 --start      # validates readiness, makes a worktree, sets in-progress
cd build/worktrees/issue-7-…           # ALL work happens here
```
then: **Explorer** subagent (context) → implement → build check → **Reviewer** subagent →
`Scripts/agent/handoff.sh 7` → open a PR → merge → `Scripts/agent/worktree.sh 7 --remove`.

Starting a new session (any model): `/resume` — it finds work-in-progress, reads the
handoff, and continues from the recorded next action.

---

## Agents (roles)

Invoke by asking for the agent by name (e.g. *"Use the Explorer agent on issue #7"*), or
via the agent picker in Copilot chat. Definitions: `.agents/agents/*.agent.md`
(also visible to Copilot through the `.github/agents` symlink).

| Agent | What it does | When to use | Tools |
|:--|:--|:--|:--|
| **Orchestrator** | Owns one issue end to end: plans, delegates sub-issues to child Orchestrators, coordinates Explorer/Reviewer, drives handoff and PR. Never implements a child's work. | To run an issue or an epic. | read, search, edit, execute, agent, todo, web |
| **Explorer** | Read-only. Produces one context brief: relevant files/symbols, the closest pattern to copy, constraints, risks, verification plan. | Before implementing a leaf task. | read, search, execute |
| **Implementer** | Makes the smallest change that satisfies the issue's "Done when". Reports, per step, **how to test it manually**. | To execute one bounded leaf change. | read, search, edit, execute |
| **Reviewer** | Independent, read-only. Checks the diff against "Done when", the `AGENTS.md` constraints, and scope; runs the build; checks the manual-test steps. | After implementation, before handoff. | read, search, execute |

**Delegation rule:** an issue with open sub-issues is an epic → the Orchestrator delegates
**each** sub-issue to a child Orchestrator (max depth 2: epic → task → leaf). The parent
aggregates only.

---

## Skills

On-demand workflows (`.agents/skills/<name>/SKILL.md`). Copilot discovers
`.agents/skills/` natively — type `/` to see them. Any other harness can invoke them by
name.

| Skill | What it does | Use when |
|:--|:--|:--|
| `pickup-task` | Validate Definition of Ready, start an isolated worktree, set `agent:in-progress`, print a readiness brief. | Starting a task. |
| `context-brief` | Gather read-only context into one structured brief. | Before editing. |
| `delegate-subissue` | List an epic's open sub-issues and spawn a child Orchestrator per sub-issue. | Running an epic. |
| `review-change` | Independently review a diff against "Done when", constraints and scope; run the build. | Before handoff. |
| `write-handoff` | Write the per-issue handoff, commit it, mirror it to the issue, sync the label. | Finishing or pausing a task. |
| `resume-session` | Find in-progress work, read the handoff, continue from the next action. | Start of any session / after switching model. |
| `sync-overview` | Regenerate `Docs/status/OVERVIEW.md` and `Docs/handoffs/INDEX.md`. | Status checks, after a task. |
| `issue-contract` | Create/normalize an issue to the agent-parsable shape. | Filing or splitting issues. |

---

## Prompts (Copilot slash commands)

Thin wrappers in `.github/prompts/` that call a skill plus a script.

| Command | Does | Example |
|:--|:--|:--|
| `/pickup <n>` | Readiness brief; with `--start`, creates the worktree and sets in-progress. | `/pickup 7` |
| `/resume` | Resume across sessions/models from the latest handoff. | `/resume` |
| `/delegate <epic#>` | Show the sub-issue plan and spawn child Orchestrators. | `/delegate 2` |
| `/review <n>` | Run the Reviewer on a change. | `/review 7` |
| `/handoff <n>` | Write/commit/mirror the handoff and sync state. | `/handoff 7` |
| `/overview` | Regenerate and show the project dashboard. | `/overview` |
| `/worktree <n>` | Create/list/remove the per-task worktree. | `/worktree 7` |

> If a slash command doesn't appear, reload the VS Code window — prompt files are
> discovered at startup.

---

## Scripts (deterministic layer)

`Scripts/agent/*.sh` — bash 3.2 (macOS), safe to run by hand. They do the parts that must
be exact: worktrees, GitHub labels, commits, comments, the overview.

| Script | What it does | Usage |
|:--|:--|:--|
| `worktree.sh` | Create/list/remove the per-task git worktree. | `worktree.sh 7` · `worktree.sh 7 --remove` · `worktree.sh --list` |
| `pickup.sh` | Readiness brief; `--start` also makes the worktree + sets in-progress. | `pickup.sh 7 [--start]` · `pickup.sh` (list) |
| `issue-state.sh` | Set one `agent:*` state label (+ Project status). | `issue-state.sh 7 blocked` |
| `delegate.sh` | Dependency-ordered sub-issue plan for an epic. | `delegate.sh 2` |
| `handoff.sh` | Validate + commit the handoff, mirror it to the issue, sync label, regenerate overview. | `handoff.sh 7 [done]` |
| `overview.sh` | Regenerate `Docs/status/OVERVIEW.md` and `Docs/handoffs/INDEX.md`. | `overview.sh` |
| `normalize-issues.sh` | Apply labels/milestones/states to all mapped issues. | `normalize-issues.sh [--skip-m0] [--sync-project]` |
| `bootstrap.sh` | One-time: labels, milestones, symlink, gitignore, Project check. | `bootstrap.sh` |
| `link-agents.sh` | Create/refresh the `.github/agents` symlink (or `--copy`). | `link-agents.sh [--copy\|--status]` |
| `agent-lib.sh` | Shared library (config, gh helpers, state labels). | sourced by the others |

---

## Worktrees — isolating parallel agents

Every task runs in its **own git worktree** under `build/worktrees/issue-<n>-<slug>`, on
branch `issue-<n>-<slug>`. Parallel agents therefore never touch each other's checkout or
files. `build/` is gitignored, so worktrees never appear in the repo.

```
Scripts/agent/pickup.sh 7 --start          # create + enter + in-progress
Scripts/agent/worktree.sh --list           # see them all
Scripts/agent/worktree.sh 7 --remove       # after the PR merges (WT_FORCE=1 to force)
```

**Rule:** never edit files or run builds for a task in the main checkout.

---

## Manual testing — required at every step

At the end of **every step** (and every phase) the agent must say **how a human can verify
the result by hand**: the exact actions (and which app) plus the expected outcome. When a
result can't be tested yet, say so and why. The handoff's **§5 How to test manually**
collects the final, complete set; the Reviewer treats missing or weak steps as a
**blocking** finding.

---

## Memory & resumability

| Store | What | Where |
|:--|:--|:--|
| Handoff doc | The durable per-task memory, incl. **Resume here → Next action**. | `Docs/handoffs/issue-<n>-<slug>.md` (committed) |
| Issue comment | Same content, next to the issue (idempotent, marked). | GitHub issue |
| State label | Machine state. | `agent:*` label |
| Overview | Holistic dashboard. | `Docs/status/OVERVIEW.md` |
| Index | Handoff → issue → status. | `Docs/handoffs/INDEX.md` |
| Session scratch | Ephemeral, git-ignored. Never the source of truth. | `.agents/state/session.md` |

Switching session, model, or harness loses nothing: run `/resume`.

---

## GitHub labels & milestones

- **State (exactly one per issue):** `agent:ready`, `agent:in-progress`, `agent:blocked`,
  `agent:review`, `agent:done`.
- **Kind:** `kind:epic`, `kind:task` · **Size:** `size:S|M|L` · **Area:** `area:*` ·
  **Epic:** `epic:0` … `epic:6`.
- **Milestones:** `M0 - Design approved` … `M5 - Polish (P1)` (PRD §8).

---

## Troubleshooting

| Symptom | Fix |
|:--|:--|
| Slash commands missing | Reload the VS Code window. |
| Custom agents missing in the picker | `Scripts/agent/link-agents.sh --status`; if it's not a symlink, run `link-agents.sh` (or `--copy`). |
| Project board not updating | `gh auth refresh -s project`, then `Scripts/agent/overview.sh`. |
| `handoff.sh` refuses | The handoff is missing a section — needs `## 5. How to test manually` and `## 9. Resume here` (with a **Next action**). |
| Warning "not issue-<n>-*" | You're not in the task worktree — `cd build/worktrees/issue-<n>-<slug>`. |
| Task shows `agent:blocked` | A **Depends on** issue is open; the pickup brief lists which. |
