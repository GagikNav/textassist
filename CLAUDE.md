# CLAUDE.md

This repository uses a single, harness-agnostic agent workflow. **Do not add
Claude-specific rules here** — read the shared files instead:

1. [`AGENTS.md`](./AGENTS.md) — project onboarding and hard constraints.
2. [`.agents/workflow.md`](./.agents/workflow.md) — the canonical agent loop, roles,
   delegation (max depth 2), git policy, Definition of Ready/Done, and the resume
   protocol.

Canonical agent definitions live in `.agents/agents/`, shared skills in
`.agents/skills/`, templates in `.agents/templates/`, and the deterministic scripts in
`Scripts/agent/`.

Start a session with the `resume-session` skill (or run `Scripts/agent/pickup.sh`), and
finish with the `write-handoff` skill (or `Scripts/agent/handoff.sh <issue#>`).
