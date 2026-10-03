# Handoff — issue #14 T3.1 — SummaryPopupViewModel additions

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #14 (T3.1) |
| Epic | #1 (Epic 3 — Write experience in the result popup) |
| Milestone | M2 - Write + Replace |
| Status | agent:review |
| Branch | `issue-14-summarypopupviewmodel-additions` |
| Worktree | `build/worktrees/issue-14-summarypopupviewmodel-additions` |
| Base commit | `559a8aa` |
| Last commit | `559a8aa` |
| Updated | 2026-10-04 |

## 1. What this task is

Add the Write-mode state and helpers to `SummaryPopupViewModel`, the view model behind
the result popup. This is the pure-state foundation the Write flow consumes later:
the `ResultViewMode` enum (Clean/Diff), the published `viewMode` / `showsOriginal` /
`diffText` state, the `onReplace` / `onContinueInChat` callbacks, the
`isWriteMode` / `isDiffAvailable` / `canReplace` computed properties, and
`recomputeDiff()` which builds a word-level diff (skipping inputs over 20k chars).

## 2. Plan

- [x] Pick up #14, create the isolated worktree, set `agent:in-progress`.
- [x] Explorer context brief (files, symbols, constraints, verification plan).
- [x] Add `ResultViewMode` and the 10 VM members to `SummaryPopupViewModel.swift`
      using the code from PRD-v2 §7 T3.1 verbatim.
- [x] Run the build check.
- [x] Reviewer subagent review.
- [x] Write handoff, mirror to issue, sync labels/Project.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/Popup/SummaryPopupViewModel.swift` | Added `ResultViewMode` enum above the class; added `viewMode`, `showsOriginal`, `diffText`, `onReplace`, `onContinueInChat`, `isWriteMode`, `isDiffAvailable`, `canReplace`, `recomputeDiff()` inside the class. Purely additive. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`; `SummaryPopupViewModel.swift` compiled cleanly, no errors).
- **"Done when" checklist** (from the issue):
  - [x] builds

## 5. How to test manually

1. Open `TextAssist.xcodeproj` in Xcode and build (⌘B) — or run the CLI build check
   from the worktree root.
2. **Expected:** `** BUILD SUCCEEDED **` with no errors or warnings in
   `SummaryPopupViewModel.swift`.

**Edge cases to try:** n/a — this task only adds inert state.
**Not testable yet because:** no view consumes `viewMode` / `showsOriginal` / `diffText`
/ `onReplace` / `onContinueInChat` until T3.4 (#17) wires the view model into the
popup UI. The diff UI, Replace (⌘↩), and Chat (⌘T) routing are out of scope for T3.1.

## 6. Decisions

- Used the PRD-provided code verbatim — it is the approved, frozen design; no need to
  invent anything new.
- Added `///` doc comments on `isWriteMode` and `canReplace` where the PRD snippet had
  none, matching the repo's doc-comment convention (AGENTS.md hard rule 6). Rejected:
  leaving them bare (would break the convention; reviewer noted this as non-blocking).

## 7. Blockers / open questions

- None.

## 8. Known limitations

- The new state is inert until T3.4 (#17) consumes it; the diff is only computed for
  Write styles and skips inputs ≥ 20k chars (per PRD).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-14-summarypopupviewmodel-additions` (branch `issue-14-summarypopupviewmodel-additions`)
- **Next action:** open the PR for `issue-14-summarypopupviewmodel-additions` (body from `.agents/templates/pr-body.md`); once merged, flip #14 to `agent:done` and remove the worktree.
- **Files in play:** `TextAssist/UI/Popup/SummaryPopupViewModel.swift`;
  `Docs/handoffs/issue-14-summarypopupviewmodel-additions.md`.
- **Watch out for:** T3.4 (#17) depends on #14 and #13 — do not rename `ResultViewMode`,
  `diffText`, `recomputeDiff()`, or the `onReplace` / `onContinueInChat` signatures.
  Keep `viewMode` defaulting to `.clean` and `canReplace` semantics intact.
- **Do not redo:** the file is implemented, build-verified, and reviewer-approved.

## 10. Review

- Reviewer verdict: **approve** — no blocking findings.
- Findings: non-blocking only — added `///` doc comments on `isWriteMode` /
  `canReplace` where the PRD snippet had none (matches repo convention).
