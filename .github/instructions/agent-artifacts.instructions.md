---
description: "Rules for the agent workflow artifacts — handoff docs, .agents core files, and Scripts/agent. Apply when editing .agents/**, Docs/handoffs/**, Scripts/agent/**, or .github/{agents,prompts,skills}."
applyTo: [".agents/**", "Docs/handoffs/**", "Scripts/agent/**", ".github/agents/**", ".github/prompts/**"]
---

# Agent artifact rules

- **`.agents/` is the single source of truth.** Do not duplicate rules into harness
  folders; `.github/agents` is a symlink to `.agents/agents`.
- **Worktrees.** Each task runs in its own worktree, `build/worktrees/issue-<n>-<slug>`,
  so parallel agents never collide. Create it with `Scripts/agent/worktree.sh <n>` (or
  `pickup.sh <n> --start`); never edit files or run builds for a task in the main checkout.
- **Handoffs** must include a `## 5. How to test manually` section with copy-pasteable
  steps and the expected result, and a `## 9. Resume here` section with a single
  **Next action**. Write them so a different model with no chat history can continue.
- **Generated files are never hand-edited:** `Docs/status/OVERVIEW.md`,
  `Docs/handoffs/INDEX.md`. Regenerate with `Scripts/agent/overview.sh`.
- **`.agents/config.json`** must stay valid JSON and match the real GitHub issues.
- Scripts target **bash 3.2** (macOS) and must stay `bash -n` clean.
- One task = one reviewable change; run the build check before marking `agent:done`.
