# Handoff — issue #10 T2.1 — Grouped StylePickerView

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #10 (T2.1) |
| Epic | #3 (Epic 2 — Picker v2) |
| Milestone | M2 - Write + Replace |
| Status | agent:done |
| Branch | `issue-10-grouped-stylepickerview` |
| Worktree | `build/worktrees/issue-10-grouped-stylepickerview` |
| Base commit | `f6f2940` |
| Last commit | `46f45f9` |
| Updated | 2026-10-03 |

## 1. What this task is

T2.1 replaces the flat style-picker list with the v2 grouped picker. Styles are now
shown in three labeled sections — **Transform**, **Write**, **Chat** — followed by a
divider and the **Custom** entry. Every row keeps its shortcut key (digits for
Transform, letters for Write/Chat, `0` for Custom), its name, and the checkmark on the
last-used style; `esc` still cancels. This is the first half of Picker v2 (the panel
auto-sizing lands in T2.2, #11).

## 2. Plan

- [x] Read `AGENTS.md`, `.agents/workflow.md`, PRD-v2 §7 T2.1, design tokens, and `swift-ui.instructions.md`.
- [x] Verify `SummaryStyle` already carries `category`, `shortcutKey`, `name`, `id`, and the built-ins (`fixGrammar`, `chatWithSelection`, `customPrompt`) — T1.1 (#9) is closed.
- [x] Replace `TextAssist/UI/StylePicker/StylePickerView.swift` with the PRD-v2 §7 T2.1 code.
- [x] Run the build check (`BUILD SUCCEEDED`).
- [x] Review against the issue's Done-when, AGENTS.md hard constraints, and scope.
- [x] Write/commit the handoff, mirror it to the issue, sync the label (this document).

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/StylePicker/StylePickerView.swift` | Replaced. Added `PickerGroup` (title + styles) and a computed `groups` array built from `style.category`; body renders header labels (`Text(title.uppercased())`), a divider for the nil-title Custom group, and extracted `row(for:)`. Width 220 → 240. Preview now uses `SummaryStyle.fixGrammar` as the last-used style. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`).
- **"Done when" checklist** (from the issue):
  - [x] Builds.
  - [x] Preview shows 4 groups — `groups` derives from the 4 non-empty categories: Transform (6), Write (8), Chat (1), Custom (1).
  - [x] `g` → Fix Grammar — `fixGrammar.shortcutKey == "g"`, wired via `keyboardShortcut`.
  - [x] `a` → Chat — `chatWithSelection.shortcutKey == "a"`.
  - [x] `0` → Custom — `customPrompt.shortcutKey == "0"`.
  - [x] `esc` cancels — Cancel row uses `.keyboardShortcut(.cancelAction)`.

## 5. How to test manually

> Run these in the app. Expected result listed after each step.

1. **Launch:** open `TextAssist.xcodeproj`, select the **Text Assist** scheme, Run (⌘R). The app appears as a menu-bar item (no Dock icon).
2. **Open the picker:** in TextEdit (or any app), select a sentence, then press `⌥⇧S`.
3. **Expected:** the floating picker shows four sections in order — **TRANSFORM** (Short Summary…Chat Thread), **WRITE** (Fix Grammar…Longer), **CHAT** (Chat with Selection), then a divider and **Custom Prompt**; each row shows its shortcut key on the left, and the most recently used style shows a ✓ on the right.
4. **Shortcut keys:** press `g` → Fix Grammar is selected and the action runs on the selection. Reopen the picker: press `a` → Chat with Selection is selected. Reopen: press `0` → Custom Prompt is selected.
5. **Cancel:** reopen the picker and press `esc` → the picker dismisses with nothing selected.

**Edge cases to try:** a shortcut letter that has no style (`x`) should do nothing; the ✓ moves to whichever style you last used.

**Not testable yet:** panel auto-sizing. The panel's hard-coded `CGSize(width: 220, height: 200)` (set in `StylePickerPanel.swift`) may clip the 16 rows until T2.2 (#11) sizes it to content.

## 6. Decisions

- **Used the PRD-v2 §7 T2.1 code verbatim.** The task says "full code provided there"; it is authoritative for T2.1.
- **Group header font** is `.caption2.weight(.semibold)` + `.uppercased()` (from the PRD) rather than `IMPLEMENTATION.md`'s suggested `10.5pt .textCase(.uppercase)` — the PRD code wins for this task; the two are visually near-identical.
- **Width 240** (was 220) matches `Metric.pickerWidth` in `IMPLEMENTATION.md`.

## 7. Blockers / open questions

- None.

## 8. Known limitations

- Panel still uses the old hard-coded size; the grouped picker needs T2.2 (#11) to fit its content. Tracked in #11, which is unblocked by this task.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-10-grouped-stylepickerview` (branch `issue-10-grouped-stylepickerview`)
- **Next action:** open the PR for this branch and merge; then T2.2 (#11) can start.
- **Files in play:** `TextAssist/UI/StylePicker/StylePickerView.swift` (done), `TextAssist/UI/StylePicker/StylePickerPanel.swift` (next, T2.2).
- **Watch out for:** T2.2 touches `StylePickerPanel.swift` (`show()`), not this file — no conflict.
- **Do not redo:** the grouped picker is already implemented and building.

## 10. Review

- Reviewer verdict: approve (self-review; no Reviewer subagent tool available in this session).
- Findings: none blocking. Verified: no `project.pbxproj` edit; macOS 13-safe (no `@Observable`, `onKeyPress`, two-parameter `.onChange(of:)`, `Inspector`); `///` doc-comments preserved; no unrelated refactors or renames.
