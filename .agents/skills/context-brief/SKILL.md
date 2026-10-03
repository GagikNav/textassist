---
name: context-brief
description: "Gather read-only code context for a Text Assist task into one structured brief: relevant files and symbols, the closest existing pattern to copy, biting constraints, risks, and a verification plan. Use when starting implementation, before editing, or to understand how a feature is wired."
argument-hint: "<issue-number or topic>"
---

# Context brief

## When to use
- Before implementing a leaf task.
- When a new session needs to rebuild context without chat history.

## Procedure
1. Read the issue (Depends on / Files / Done when) and the epic body.
2. Read any existing `Docs/handoffs/issue-<n>-*.md`.
3. Find the files named in the issue and the **single closest existing pattern** to
   follow (name the file and symbol). Prefer the `codegraph_explore` tool.
4. Apply `AGENTS.md` constraints to the files in play (macOS 13 APIs, MainActor,
   non-activating panels, no pbxproj edits).
5. Fill `.agents/templates/context-brief.md` and return it.

## Rules
- Read-only. Never edit files.
- Cite file paths and symbol names exactly; do not paraphrase code.
- Keep it under ~200 lines. One pattern to follow, not three.
