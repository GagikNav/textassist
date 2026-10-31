# AGENTS.md — Text Assist

Agent onboarding: the project facts and the hard rules. The process lives in
`.agents/workflow.md`.

## What this is

Text Assist is a macOS menu-bar utility (agent app, no Dock icon). The user selects
text in any app, presses `⌥⇧S`, picks an action from a non-activating floating picker,
and sees the result in a floating panel. The actions are grouped as **Transform**
(summarize), **Write** (rewrite in place) and **Chat** (multi-turn with a pinned
selection).

Stack: Swift 5 language mode, SwiftUI + AppKit, local Ollama (`/api/chat`, NDJSON
streaming). **No automated tests** — verification is "it builds + a manual check in
the running app".

## Where the work comes from

GitHub issues are the only task list. **Any issue with no open dependency can be picked
up** — there is no global order, no milestone gate, and no privileged "next" ticket. The
issue's own `Depends on:` line is the whole sequencing rule.

An issue may point at background material: a spec or PRD under `tickets/`, design tokens
under `Docs/design/`, or a previous handoff under `Docs/handoffs/`. Read the part the
issue names, when it names one. Otherwise the issue body and the code are the
specification.

Where the work stands across all issues: `Docs/status/OVERVIEW.md` and the handoffs in
`Docs/handoffs/`. Releases and versioning: `Docs/releasing.md`.

## Agent workflow

Tasks are GitHub issues. Agents follow `.agents/workflow.md` (the canonical loop:
INTAKE → CONTEXT → PLAN → DELEGATE → IMPLEMENT → VERIFY → REVIEW → HANDOFF → SYNC).

- **New here?** Read `.agents/MANUAL.md` — what every skill, agent, prompt and script
  does, and how to use them.
- **Start** a session with the `resume-session` skill (`/resume`) or the `pickup-task`
  skill (`/pickup <n>`). The handoff docs in `Docs/handoffs/` are the durable memory, so
  switching session or model loses nothing.
- **Isolate** — each task runs in its own git worktree (`Scripts/agent/pickup.sh <n> --start`,
  or `Scripts/agent/worktree.sh <n>`), so parallel agents never collide. Never edit files
  for a task in the main checkout.
- **Manual tests** — every step ends with instructions on how to test the result by hand;
  the handoff collects the final set (§5).
- **Delegate** — an issue with open sub-issues is an epic: hand each sub-issue to a child
  Orchestrator subagent (max depth 2). Never implement a child's work in the parent.
- **Context and review** use read-only subagents (Explorer, Reviewer).
- **Finish** with the `write-handoff` skill (`/handoff <n>`): commits the handoff, mirrors
  it to the issue, and syncs the `agent:*` label and Project status.
- Deterministic helpers live in `Scripts/agent/*.sh`; config and skills in `.agents/`.
- The holistic picture is `Docs/status/OVERVIEW.md` (regenerate with
  `Scripts/agent/overview.sh`).

### GitHub operations — try MCP first

For anything GitHub-facing (issues, sub-issues, comments, labels, milestones, PRs,
reviews, branches, releases, code search), **look for a GitHub MCP tool first** and use
it. Only fall back to the `gh` CLI or `Scripts/agent/*.sh` when no MCP tool covers the
operation, the MCP server is unavailable, or a script is the documented path (e.g. the
deterministic handoff/label sync). Do not reach for `gh` by reflex.


## Build check — run after every task

```bash
xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" \
  -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData
```

## Hard constraints — do not violate

1. **Never edit `TextAssist.xcodeproj/project.pbxproj`** (one approved exception path:
   `.agents/workflow.md` §11). The target uses a
   file-system-synchronized group: any `.swift` file created under `TextAssist/` is
   compiled automatically. New folders are fine.
2. **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, Swift 5 language mode.** Types are
   `@MainActor` by default. Cross isolation the way `OllamaProvider` does
   (`await MainActor.run { ... }`); mark pure helpers `nonisolated`.
3. **Deployment target macOS 13.0.** Do not use `@Observable`, `onKeyPress`, the
   two-parameter `.onChange(of:)`, `Inspector`, or any API newer than macOS 13.
   Allowed: `TextField(axis: .vertical)`, `ScrollView` `.scrollContentBackground`,
   `formStyle(.grouped)`, `SMAppService`, `AttributedString`, `Layout`.
4. **App Sandbox stays off.** `CGEvent` posting and Accessibility capture depend on it.
5. **Panels stay non-activating** (`KeyablePanel`, `.nonactivatingPanel`). The source
   app must stay frontmost so Replace works.
6. Preserve the `///` doc-comment style on new public types and methods.

## Working agreements

- One task = one reviewable change. Run the build check before declaring done.
- Do not refactor unrelated code. Do not rename existing types.
- "Done when" is checked by hand in the running app. There are no tests to write.
- Two tasks that edit the same file do not run at once. `sequentialFiles` in
  `.agents/config.json` lists the files known to collide; add to it when you find another.

## Layout

`TextAssist/` holds `App`, `Core`, `Models`, `Providers`, `Stores`, `UI`, `Utilities`
(all file-system-synchronized). Shared view helpers live in `UI/Shared/`.
