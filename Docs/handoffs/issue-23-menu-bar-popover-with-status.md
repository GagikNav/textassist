# Handoff — issue #23 T5.2 — Menu-bar popover with status

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #23 (T5.2) |
| Epic | #5 (Epic 5 — Menu bar status) |
| Milestone | M4 - Menu bar status |
| Status | agent:review |
| Branch | `issue-23-menu-bar-popover-with-status` |
| Worktree | `build/worktrees/issue-23-menu-bar-popover-with-status` |
| Base commit | `b00f21f` |
| Last commit | `b00f21f` (handoff committed on top) |
| Updated | 2026-10-04 |

## 1. What this task is

Replace the menu-bar popover content so it shows an Ollama status row — an 8 pt colored
dot (green online, red offline, gray unknown) plus `Ollama · <model>` — wired to the
`OllamaStatusMonitor` built in T5.1, while keeping the existing actions (Assist with
Selection, Settings…, Quit). Also add a `@StateObject statusMonitor` to the app and pass
it into the view.

## 2. Plan

- [x] Confirm `OllamaStatusMonitor` (T5.1) API and `LLMProvider.listModels()`.
- [x] Replace `UI/MenuBar/MenuBarStatusView.swift` with the new status + actions layout.
- [x] Edit `App/TextAssistApp.swift` to own and pass the `statusMonitor`.
- [x] Run the build check.
- [x] Reviewer subagent review (approved, no blocking findings).
- [x] Write handoff, mirror to issue, sync labels/Project.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/MenuBar/MenuBarStatusView.swift` | Replaced: new `@ObservedObject settings` + `@ObservedObject monitor` signature; status row (8 pt `Circle()` dot + `Ollama · \(settings.model)`), offline caption "Not running. Start Ollama and try again.", `Divider`s, "Assist with Selection" with trailing `⌥⇧S`, "Settings…", "Quit" with `⌘Q` hint + `.keyboardShortcut("Q")`, `.onAppear` refresh, updated `#Preview`. |
| `TextAssist/App/TextAssistApp.swift` | Added `@StateObject private var statusMonitor: OllamaStatusMonitor`; created it in `init()` from the shared `provider` via `_statusMonitor = StateObject(wrappedValue:)`; passed `settings` and `statusMonitor` into `MenuBarStatusView`. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`).
- **"Done when" checklist** (from the issue):
  - [x] Popover code shows a status dot + model name (`statusColor` maps `.online`→green, `.offline`→red, `.unknown`→gray) — implemented and build-verified.
  - [x] Build passes.
  - [ ] Green dot with the model name while Ollama runs — **needs the running app** (pending human check).
  - [ ] Red dot after stopping Ollama and reopening the popover — **needs the running app** (pending human check).

## 5. How to test manually

1. Build and run: open `TextAssist.xcodeproj` in Xcode and Run, or launch
   `build/DerivedData/Build/Products/Debug/Text Assist.app`.
2. **Start Ollama** (`ollama serve`), then click the menu-bar icon.
   **Expected:** popover shows a **green** 8 pt dot next to `Ollama · <model>` (the
   configured model, default `phi3:instruct`).
3. **Stop Ollama** (quit the server / `ollama stop`), close the popover, then click the
   menu-bar icon **again** (reopens → `.onAppear` re-refreshes).
   **Expected:** **red** dot, same `Ollama · <model>` line, plus the secondary caption
   "Not running. Start Ollama and try again." below it.
4. Click **Assist with Selection** (trailing `⌥⇧S` hint) with text selected elsewhere.
   **Expected:** the style picker opens and summarizing works as before.
5. Click **Settings…**. **Expected:** the floating settings panel opens.
6. Click **Quit** (or press `⌘Q`). **Expected:** the app terminates.

**Edge cases to try:** reopen the popover several times while toggling Ollama on/off —
the dot should track the latest refresh. · **Not testable yet because:** n/a — all of the
above is runnable today.

## 6. Decisions

- **`.buttonStyle(.plain)` + full-width `HStack` labels** on all three buttons, with the
  shortcut hint right-aligned via `Spacer()` and `.foregroundStyle(.secondary)` — matches
  the frozen mockup's `.prow` menu rows (PRD §4.5). (Rejected: leaving the default
  bordered `Button` style, which does not render as menu rows.)
- **Visible `⌘Q` hint on Quit** — the spec only required `.keyboardShortcut("Q")`, but the
  mockup shows `Quit ⌘Q` and it mirrors the `⌥⇧S` hint; the terminate action + shortcut are
  unchanged ("keep the current behavior"). (Rejected: hint-less Quit, for visual consistency.)
- **`Color.green` / `.red` / `.gray`** for the dot — the issue spec says green/red/gray and
  `UI/Shared/Palette.swift` (T1.1's `Tok` tokens) does not exist in the codebase yet. When
  T1.1 lands, swap these for `Tok.ok/bad/unknown(scheme)`. (Rejected: introducing the token
  file here — that is T1.1's scope.)
- **No explicit `init`** written — the synthesized memberwise initializer yields the exact
  `init(settings:monitor:onSummarize:onSettings:)` signature, and stored closure parameters
  are `@escaping`. Behavior is identical to the spec. (Rejected: a hand-written `init`, which
  adds noise for no gain.)

## 7. Blockers / open questions

- None.

## 8. Known limitations

- `.onAppear` on a `.menuBarExtraStyle(.window)` popover may not fire on every reopen if
  macOS reuses the window. If the dot does not update after stopping/starting Ollama and
  reopening, the refresh trigger will need revisiting (e.g. a window delegate or single-param
  `.onChange`). Flag in the manual check.
- The gray `.unknown` state is transient — only visible before the first `refresh()`
  completes — so it is not a practical "Done when" check.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-23-menu-bar-popover-with-status` (branch `issue-23-menu-bar-popover-with-status`)
- **Next action:** open the PR for `issue-23-menu-bar-popover-with-status` (body from
  `.agents/templates/pr-body.md`); after a human confirms the green/red "Done when" and the
  PR merges, flip #23 to `agent:done` and remove the worktree
  (`Scripts/agent/worktree.sh 23 --remove`).
- **Files in play:** `TextAssist/UI/MenuBar/MenuBarStatusView.swift`,
  `TextAssist/App/TextAssistApp.swift`, `Docs/handoffs/issue-23-menu-bar-popover-with-status.md`.
- **Watch out for:** keep `OllamaStatusMonitor`'s `Status` cases (`unknown`/`online`/`offline`)
  and `refresh()` exactly as T5.1 shipped. T6.2 and T6.4 both extend this same view — merge
  order matters. The popover window is `.window`-style, so test the reopen-refresh path by hand.
- **Do not redo:** the view rewrite, the `statusMonitor` wiring, the build check, and the
  reviewer approval are all complete.

## 10. Review

- Reviewer verdict: **approve** — no blocking findings.
- Findings: non-blocking only — (1) the `⌘Q` trailing hint is not spelled out in §T5.2 but
  matches the §4.5 mockup; (2) no explicit `init` (synthesized memberwise init is used, which
  satisfies the signature); (3) offline caption uses bottom padding only (12 horizontal × 8
  vertical, per the spec's "Padding 12 × 8").
