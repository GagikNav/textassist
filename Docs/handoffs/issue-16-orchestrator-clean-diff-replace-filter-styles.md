# Handoff — issue #16 T3.5 — Orchestrator: clean, diff, replace, filter styles

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #16 (T3.5) |
| Epic | #1 (Epic 3 — Write experience in the result popup) |
| Milestone | M2 - Write + Replace |
| Status | agent:done |
| Branch | `issue-16-orchestrator-clean-diff-replace-filter-styles` |
| Worktree | `build/worktrees/issue-16-orchestrator-clean-diff-replace-filter-styles` |
| Base commit | `621d7276e3c588efcab399bcebbcbbde963df332` |
| Last commit | `e59e09e91677d35705797af5c12fd5bb3884758d` |
| Updated | 2026-10-05 |

## 1. What this task is

T3.5 finishes the Write/Replace flow in `SummarizationOrchestrator`. It wires three
things that were built earlier but not yet connected: (1) the popup's style dropdown is
narrowed to only Transform + Write styles, hiding Chat and Custom; (2) `onReplace` now
calls `TextReplacementService` to paste the result back over the original selection and
closes the popup on success; (3) after streaming, Write results are cleaned with
`OutputCleaner` and the clean-vs-diff state is recomputed, with `viewMode` reset to
`.clean` at the start of every stream.

## 2. Plan

- [x] Filter `availableStyles` to `.transform` + `.write` in `showSummaryPopup`.
- [x] Wire `viewModel.onReplace` in `configureActions`.
- [x] Reset `viewMode = .clean` at stream start; clean Write output and `recomputeDiff()` after streaming.
- [x] Build check.
- [x] Reviewer pass.
- [ ] Open PR, merge, remove worktree (SYNC phase).

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Core/SummarizationOrchestrator.swift` | Filter dropdown styles; wire `onReplace`; clean + recompute diff; reset `viewMode` |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`, no errors/warnings).
- **"Done when" checklist** (from the issue):
  - [x] TextEdit: `⌥⇧S → g` streams a cleaned result, Diff toggle works (implemented; needs running-app check below).
  - [x] `⌘↩` replaces in place and the previous clipboard is restored (implemented; needs running-app check below).
  - [x] Safari non-editable selection: Replace does nothing harmful, Copy works (implemented; needs running-app check below).
  - [x] Focused field with no selection: Replace disabled (origin `fieldValue`) (implemented via `canReplaceSelection` + `canReplace`; needs running-app check below).

## 5. How to test manually

> A human verifies these in the running app. All four are implemented; the checklist
> marks them done-when-verified-by-hand per PRD §7.

1. Build & run the app from this worktree (open `TextAssist.xcodeproj`, Run), then open **TextEdit**, type `I has a apple and she dont like it`, select all of it, and press `⌥⇧S`, then `g` (Fix Grammar).
   - **Expected:** The result streams in, appears cleaned (no "Here is…" preamble / fences / wrapping quotes), and the **Clean/Diff** toggle shows the word-level diff against the original.
2. With the Fix Grammar result still open, press `⌘↩` (Replace).
   - **Expected:** The popup closes and the selected sentence in TextEdit is replaced by the cleaned result; the clipboard you had before is restored afterward (not the result text).
3. In **Safari**, select text on a non-editable page, `⌥⇧S`, pick a Transform style, then `⌘C` and try Replace if shown.
   - **Expected:** Copy works; Replace does nothing harmful (nothing is pasted into the page). For Transform styles Replace is disabled entirely; for a Write style on an editable-unfriendly origin, no paste occurs.
4. Click into a text field (e.g. Notes) with **nothing selected**, `⌥⇧S`, pick a Write style, let it stream, then look at Replace.
   - **Expected:** Replace is **disabled** (the capture origin is `fieldValue`, so `canReplaceSelection` is false).

**Edge cases to try:** Chat/Custom Prompt styles must not appear in the popup's style dropdown (only Transform + Write). **Not testable yet because:** n/a.

## 6. Decisions

- Used the PRD-provided code verbatim (filter predicate, `onReplace` closure, clean/recompute placement). (Rejected: none — the PRD is explicit.)
- Placed `viewMode = .clean` reset next to the other `streamedText = ""` state resets at the top of `streamSummary`. (Rejected: resetting inside the loop, which would thrash the UI.)

## 7. Blockers / open questions

- None.

## 8. Known limitations

- Opening the popup with the Custom Prompt style (`category: .custom`) or Chat style (`category: .chat`) means `currentStyle.id` is absent from the filtered `availableStyles`, so the dropdown's current-selection highlight may be blank until the user picks a listed style. Non-blocking; chat routing is wired in T4.4.
- `onContinueInChat` remains the default empty closure (deliberately; T4.4 wires it).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-16-orchestrator-clean-diff-replace-filter-styles` (branch `issue-16-orchestrator-clean-diff-replace-filter-styles`)
- **Next action:** Open a PR from the branch, then run `sync-overview` and merge; remove the worktree after merge.
- **Files in play:** `TextAssist/Core/SummarizationOrchestrator.swift`
- **Watch out for:** This file is in `sequentialTasks` (T3.5, T4.4, T6.1, T6.2) — run those one at a time, in order.
- **Do not redo:** Implementation, build check, and reviewer are all done; only PR/merge/sync remain.

## 10. Review

- Reviewer verdict: **approve** (no blocking findings).
- Findings: Two non-blocking notes — (a) custom/chat style absent from filtered dropdown can leave the current-selection highlight blank; (b) the pre-existing streaming `catch` uses `localizedDescription` rather than `errorDescription`. Neither blocks T3.5.
