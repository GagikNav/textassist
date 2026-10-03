# Text Assist — GitHub Copilot instructions

The canonical rules live in [`AGENTS.md`](../AGENTS.md) and the process in
[`.agents/workflow.md`](../.agents/workflow.md). Read both before acting. This file
only adds the Copilot-specific wiring.

## Entry points

- **Custom agents** (`.github/agents/` → symlink to `.agents/agents/`): `Orchestrator`,
  `Explorer`, `Implementer`, `Reviewer`.
- **Skills** (`.agents/skills/`, discovered natively): `/pickup-task`, `/context-brief`,
  `/delegate-subissue`, `/review-change`, `/write-handoff`, `/resume-session`,
  `/sync-overview`, `/issue-contract`.
- **Prompts** (`.github/prompts/`): `/pickup`, `/resume`, `/delegate`, `/handoff`,
  `/review`, `/overview`.
- **Scripts** (`Scripts/agent/*.sh`): the deterministic layer (`gh`-backed).

## GitHub operations — try MCP first

For anything GitHub-facing (issues, sub-issues, comments, labels, milestones, PRs,
reviews, branches, releases, code search), **look for a GitHub MCP tool first** and use
it. Only fall back to the `gh` CLI or `Scripts/agent/*.sh` when no MCP tool covers the
operation, the MCP server is unavailable, or a script is the documented path (e.g. the
deterministic handoff/label sync). Do not reach for `gh` by reflex.

## How to work here

1. Start with `/resume` to continue in-progress work, or `/pickup <n>` to start a task.
2. If the issue has open **sub-issues**, delegate each to a child **Orchestrator**
   subagent (`/delegate <epic>`) — do not implement child work yourself.
3. For a leaf task: **Explorer** subagent → implement → build check → independent
   **Reviewer** subagent.
4. Finish with `/handoff <n>`: commits the handoff, mirrors it to the issue, syncs the
   `agent:*` label and Project status.

## Hard rules (from `AGENTS.md` — never violate)

1. Never edit `TextAssist.xcodeproj/project.pbxproj`.
2. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, Swift 5 mode; cross isolation like
   `OllamaProvider`; mark pure helpers `nonisolated`.
3. Deployment target **macOS 13.0** — no `@Observable`, `onKeyPress`, two-parameter
   `.onChange(of:)`, `Inspector`, or newer APIs.
4. App Sandbox stays **off**; panels stay **non-activating**.
5. One task = one reviewable change; no unrelated refactors; no renaming existing types.
6. Run the build check before declaring any task done.
