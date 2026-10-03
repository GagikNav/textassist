# AGENTS.md — Text Assist

Agent onboarding. Read this first, then the PRD in the order below.

## What this is

Text Assist is a macOS menu-bar utility (agent app, no Dock icon). The user selects
text in any app, presses `⌥⇧S`, picks an action from a non-activating floating picker,
and sees the result in a floating panel. v2 adds **Write** (rewrite in place) and
**Chat** (multi-turn with a pinned selection) on top of Transform (summarize).

Stack: Swift 5 language mode, SwiftUI + AppKit, local Ollama (`/api/chat`, NDJSON
streaming). **No automated tests** — verification is "it builds + a manual check in
the running app".

## Read order

1. `tickets/PRD-v2.md` — product requirements and the full task breakdown (Epics 0–6).
   §3.2 (constraints) and §7 (working agreements) govern every task.
2. `Docs/design/v2/README.md` — the **approved** design tokens: color, type, spacing,
   radius, panel sizes, states, SwiftUI button mapping.
3. `Docs/design/v2/IMPLEMENTATION.md` — SwiftUI translation of those tokens (drop-in
   values, component → file map, task mapping). Adds no new design decisions.
4. `Docs/design/v2/text-assist-v2-mockup.html` — the visual mockup for all six v2
   surfaces. Open in a browser; it has a Light/Dark switch in the header.

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

1. **Never edit `TextAssist.xcodeproj/project.pbxproj`.** The target uses a
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

## Working agreements (PRD §7)

- One task = one reviewable change. Run the build check before declaring done.
- Do not refactor unrelated code. Do not rename existing types.
- "Done when" is checked by hand in the running app. There are no tests to write.
- Orchestrator edits (`T3.5`, `T4.4`, `T6.1`, `T6.2`) all touch the same file — run
  them **sequentially**. `T1.3`, `T1.4`, `T3.2`, `T3.3`, `T5.1` are parallelizable once
  `T1.1` exists.

## Milestone gate

`M0` (design, task `T0.1`) is **approved**. Implement `M1` → `M5` in order
(`tickets/PRD-v2.md` §8). The design is frozen — build to it, do not redesign flows.
The ASCII sketches in PRD §4 are the flow baseline; the mockup refines them.

## Layout

`TextAssist/` holds `App`, `Core`, `Models`, `Providers`, `Stores`, `UI`, `Utilities`
(all file-system-synchronized). The new v2 files are listed in PRD §6 ("File map").
