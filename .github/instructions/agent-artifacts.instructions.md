---
description: "Rules for the agent workflow artifacts — handoff docs, .agents core files, and Scripts/agent. Apply when editing .agents/**, Docs/handoffs/**, Scripts/agent/**, or .github/{agents,prompts,skills}."
applyTo: [".agents/**", "Docs/handoffs/**", "Scripts/agent/**", ".github/agents/**", ".github/prompts/**"]
---

# Agent artifact rules

- **`.agents/` is the single source of truth.** Do not duplicate rules into harness
  folders; `.github/agents` is a symlink to `.agents/agents`.
- **Handoffs** use `.agents/templates/handoff.md` and must keep a
  `## 8. Resume here` section with a single **Next action**. Write them so a different
  model with no chat history can continue.
- **Generated files are never hand-edited:** `Docs/status/OVERVIEW.md`,
  `Docs/handoffs/INDEX.md`. Regenerate with `Scripts/agent/overview.sh`.
- **`.agents/config.json`** must stay valid JSON and match the real GitHub issues.
- Scripts target **bash 3.2** (macOS) and must stay `bash -n` clean.
- One task = one reviewable change; run the build check before marking `agent:done`.
