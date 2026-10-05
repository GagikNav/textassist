# Handoff — issue #25 T6.1 — Direct-action hotkeys (skip the picker)

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #25 (T6.1) |
| Epic | #6 |
| Milestone | M5 - Polish (P1) |
| Status | agent:done (merged; Done-when confirmed by hand) |
| Branch | `issue-25-direct-action-hotkeys-skip-the-picker` (squash-merged by #55) |
| Worktree | removed after merge |
| Base commit | `f7c1fd44fbf15f2054e00832692e08d193cf96fe` |
| Last commit | `c945775` on `main` — "T6.1 — Direct-action hotkeys (skip the picker) (#55)" |
| Updated | 2026-10-05 |

## 1. What this task is

Until now every action started at the style picker: `⌥⇧S`, capture, then choose. T6.1
adds two direct-action hotkeys that skip that step entirely — `⌥⇧G` runs Fix Grammar on
the selection and shows the streaming summary popup, `⌥⇧C` opens the chat popup pinned
to the selection. Power users get a one-keystroke path to the two most common actions.
The style picker and `⌥⇧S` are unchanged.

## 2. Plan

- [x] Add `chatWithSelection` (`⌥⇧C`) and `fixGrammar` (`⌥⇧G`) names to the
      `KeyboardShortcuts.Name` extension in `Core/HotkeyManager.swift`.
- [x] Register `onKeyUp` for both in `registerShortcuts()`, forwarding through a new
      `triggerDirect(_ style: SummaryStyle)`.
- [x] Add `SummarizationOrchestrator.startDirect(style:)`: capture, then route — chat
      category → `showChat`, otherwise record the style → `showSummaryPopup`.
- [x] Run the build check from the worktree.
- [x] Independent Reviewer pass on the diff.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Core/HotkeyManager.swift` | Two new shortcut names; `onKeyUp` registration for each; new `triggerDirect(_:)` forwarding to the orchestrator. |
| `TextAssist/Core/SummarizationOrchestrator.swift` | New `startDirect(style:)` — capture, then route to chat or to the summary popup. |

No files were added or removed; `project.pbxproj` was not touched (the target uses a
file-system-synchronized group anyway).

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData`
  → **BUILD SUCCEEDED**, no compiler warnings introduced (only the pre-existing
  "Using the first of multiple matching destinations" note from `xcodebuild`).
- **"Done when" checklist** (from the issue):
  - [x] `⌥⇧G` in TextEdit streams a grammar fix immediately — **confirmed by hand** on the merged `main` build (2026-10-05).
  - [x] `⌥⇧C` opens chat — **confirmed by hand** on the merged `main` build (2026-10-05).

  Code-level verification: `startDirect(style:)` mirrors the picker's own routing
  (`style.category == .chat` → `showChat(for:seed:)`, otherwise
  `styleStore.recordSelection` + `showSummaryPopup`, which starts the streaming task),
  so both paths reuse the same code that already produces those behaviours.

  **Post-merge note (2026-10-05):** the first test attempt used the *main checkout's*
  build, which predated T6.1 — the new hotkeys were not registered there, so pressing
  them typed the Option+Shift character instead (`Ç` / `„`). That is expected for an
  unregistered `⌥⇧`+letter combination, not a defect. Re-tested against the worktree
  build, where the app's defaults confirmed all three shortcuts registered
  (`KeyboardShortcuts_chatWithSelection`, `…fixGrammar`, `…summarizeSelection`).
  Since #55 is merged, the `main` build now contains T6.1 — test with `Scripts/run.sh`.
  Both Done-when items were then **confirmed working by hand on that build**.

## 5. How to test manually

1. **Run the worktree's build, not the main checkout's.** `main` does not contain T6.1,
   so in the main build `⌥⇧C` / `⌥⇧G` are not registered at all: instead of doing
   anything they type the Option+Shift character (`Ç` / `„` on a US layout) into
   whatever text field has focus — e.g. the chat input. `⌥⇧S` still works there, which
   makes the leak look like a regression in the new hotkeys when it is not.

   ```bash
   # quit the running instance first — same bundle id, so `open` would just re-activate it
   osascript -e 'tell application "Text Assist" to quit'   # or ⌥-click the menu-bar icon → Quit
   cd build/worktrees/issue-25-direct-action-hotkeys-skip-the-picker
   open "build/DerivedData/Build/Products/Debug/Text Assist.app"   # built by the build check
   ```

   Or open this worktree's `TextAssist.xcodeproj` in Xcode and Run. (Only *after* this
   branch is merged does `Scripts/run.sh` from the main checkout contain T6.1.)
2. Grant Accessibility permission if macOS asks for it (the first capture silently
   prints `Capture failed: …` without it — check the Console if unsure), and make sure
   Ollama is running (`ollama serve`) with a model pulled.
3. Open TextEdit (`/System/Applications/TextEdit.app`) and type a sentence with a
   deliberate error, e.g. `Their going to the store tomorow`.
4. Select the sentence and press **`⌥⇧G`**.
5. **Expected:** no style picker appears. The floating result popup opens immediately
   with "Fix Grammar" as its style and the correction streaming in
   (`They're going to the store tomorrow.`). The elapsed-time readout appears when the
   stream finishes.
6. Select text again and press **`⌥⇧C`**.
7. **Expected:** the chat popup opens directly, pinned to the selection (the selection
   is shown in the popup header / available to the conversation) — again with no style
   picker in between.
8. Regression check: select text and press **`⌥⇧S`**.

**Expected:** the style picker still opens exactly as before, and picking "Fix Grammar"
from it behaves identically to step 5.

**Edge cases to try:**

- Press `⌥⇧G` with **nothing selected** — expect only a console line
  `Capture failed: …` and no popup (same behaviour as `⌥⇧S` with no selection).
- Press `⌥⇧G`, let it finish, quit and relaunch, then `⌥⇧S`: the picker should still
  remember Fix Grammar as the last-used style, because `startDirect` calls
  `styleStore.recordSelection`.
- Press **`⌥⇧G`** while a chat popup is open — expect the summary popup to open and the
  chat popup to close (`showSummaryPopup` calls `closeChat()`).
- Press **`⌥⇧C`** while a summary popup is open — expect the chat popup to open **on
  top of** the still-visible summary popup. This asymmetry is pre-existing (the same
  happens via `⌥⇧S` → picker → Chat, which also never closes the summary popup) and
  T6.1 deliberately keeps the PRD's `startDirect` code verbatim; see §8. Not a failure
  of this step.

**Not testable automatically because:** the project has no test target by design
(`AGENTS.md`); verification is "it builds + a manual check in the running app", and the
hotkeys need Accessibility permission plus a live Ollama backend.

## 6. Decisions

- **Followed the PRD code verbatim**, including catching all errors with a single
  `catch` and printing `Capture failed: …`. `startSummarization()` still splits
  `CaptureError` from other errors; normalising that is out of scope for T6.1.
  (Rejected: rewriting `startSummarization`'s catch blocks to match — unrelated churn.)
- **Placed `startDirect` directly after `startSummarization`** so the two entry points
  (picker flow, direct flow) sit next to each other above the `// MARK:` sections.
- **`triggerDirect` is internal, like `triggerSummarize`** — no new public API surface.
- **Kept the `KeyboardShortcuts.Name.chatWithSelection` name** even though
  `SummaryStyle.chatWithSelection` shares it. They are different types in different
  namespaces (the call site reads `SummaryStyle.chatWithSelection` for the style and
  `.chatWithSelection` for the name), and the PRD specifies this exact identifier.
  (Rejected: renaming the shortcut name — would deviate from the frozen spec.)

## 7. Blockers / open questions

- None.

## 8. Known limitations

- **Panel exclusivity is asymmetric (pre-existing).** `showSummaryPopup` calls
  `closeChat()`, but `showChat` only closes a previous chat popup — so a summary popup
  can stay visible underneath a newly opened chat popup. This is reachable before T6.1
  via `⌥⇧S` → picker → Chat, so it is not a T6.1 regression; it is *not* tracked
  anywhere (`SummarizationOrchestrator`'s doc comment claims "one popup … at a time",
  which the chat path does not enforce). One-line fix if wanted: call `closePopup()`
  in the chat branch of `startDirect`. Deliberately not done here — the PRD supplies
  the T6.1 code verbatim and the change would alter the `⌥⇧S` flow too.
- `⌥⇧G` / `⌥⇧C` are **not yet surfaced in the menu bar**; T6.3 (issue #24) is the
  follow-up that documents the shortcuts in the UI.

## 9. Resume here

- **Worktree:** removed after merge — do all further work from the main checkout.
- **Next action:** none — task complete and Done-when confirmed. No code work remains.
- **Files in play:** `TextAssist/Core/HotkeyManager.swift`,
  `TextAssist/Core/SummarizationOrchestrator.swift`
- **Watch out for:** `SummarizationOrchestrator.swift` is a `sequentialTasks` file —
  T3.5, T4.4, T6.1, T6.2 must not be merged concurrently; T6.2 (issue #26) is the next
  one to touch it, so rebase it on this branch's merge. Manual testing must use **this
  worktree's build** (§5 step 1) — the main checkout's app does not contain T6.1.
- **Do not redo:** the implementation and the build check are done and green.

## 10. Review

- Reviewer verdict: **Approve — no blocking findings.** Independent Reviewer subagent
  ran the build from the worktree (BUILD SUCCEEDED, zero warnings) and checked the diff
  against the PRD's T6.1 code, the `AGENTS.md` hard constraints, and scope.
- Findings: **none blocking.** Explicitly cleared: the `chatWithSelection` name
  collision (different types/namespaces, compiles clean), MainActor/Task isolation, and
  the error path. Non-blocking notes, all resolved in this doc:
  1. the §5 "only one panel visible" claim was wrong for the `⌥⇧C` direction — wording
     corrected and explained in §8;
  2. §5 step 1 now mentions granting Accessibility permission on first run;
  3. `startDirect` collapses `CaptureError` with other errors (PRD-verbatim) — recorded
     in §6, no action for T6.1.
- Scope: `git diff --stat` shows only the two named files (+41/−2); no
  `project.pbxproj` edit, no renames, no post-macOS-13 APIs.
