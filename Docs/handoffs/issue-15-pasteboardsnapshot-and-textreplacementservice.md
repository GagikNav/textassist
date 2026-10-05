# Handoff — issue #15 T3.3 — PasteboardSnapshot and TextReplacementService

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #15 (T3.3) |
| Epic | #1 (Epic 3 — Write experience in the result popup) |
| Milestone | M2 - Write + Replace |
| Status | agent:done |
| Branch | `issue-15-pasteboardsnapshot-and-textreplacementservice` |
| Worktree | `build/worktrees/issue-15-pasteboardsnapshot-and-textreplacementservice` |
| Base commit | `b00f21f` |
| Last commit | `c632b1e` |
| Updated | 2026-10-04 |

## 1. What this task is

Add the two low-level building blocks for the Write/Replace flow: `PasteboardSnapshot`,
which deep-copies the whole pasteboard (every item, every type) so it can be restored
after a paste, and `TextReplacementService`, which replaces the user's selection in the
source app by simulating a ⌘V while temporarily putting the result on the clipboard.
Both are used later by `SummarizationOrchestrator` in T3.5.

## 2. Plan

- [x] Create `TextAssist/Utilities/PasteboardSnapshot.swift` with the exact code from
      PRD-v2 §7 T3.3.
- [x] Create `TextAssist/Core/TextReplacementService.swift` with the exact code from
      PRD-v2 §7 T3.3.
- [x] Run the build check.
- [x] Reviewer subagent review.
- [x] Write handoff, mirror to issue, sync labels/Project.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Utilities/PasteboardSnapshot.swift` | New file (code from PRD-v2 §7 T3.3): deep copy of all pasteboard items/types; `restore(to:)` puts them back. |
| `TextAssist/Core/TextReplacementService.swift` | New file (code from PRD-v2 §7 T3.3): `@MainActor` service + `ReplacementError` enum. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`).
- **"Done when" checklist** (from the issue):
  - [x] builds — verified with the CLI build check from the worktree.

## 5. How to test manually

Not testable yet: the task's Done-when is **builds only** — behavior is verified in
T3.5, when `SummarizationOrchestrator` wires `TextReplacementService` into the Replace
action.

To confirm this step, build the project:

1. Open `TextAssist.xcodeproj` in Xcode and build (⌘B) — or run the CLI build check.
2. **Expected:** the build succeeds with no errors; `PasteboardSnapshot.swift` and
   `TextReplacementService.swift` compile cleanly.

**Not testable yet because:** nothing calls `TextReplacementService.replaceSelection`
until T3.5.

## 6. Decisions

- Used the PRD-provided code verbatim for both files — the PRD says "full code provided
  there", and the design is frozen. Rejected: adding `nonisolated` to the pure
  `PasteboardSnapshot` (defensible, but a deviation from the spec; it is MainActor by
  the project's default isolation and harmless).
- Did **not** touch `TextCaptureService`'s own clipboard code, per the issue — even
  though `PasteboardSnapshot` intentionally overlaps its inline deep-copy/restore logic.

## 7. Blockers / open questions

- None.

## 8. Known limitations

- `PasteboardSnapshot` duplicates the deep-copy/restore logic already inline in
  `TextCaptureService.captureViaClipboard()`. Keeping them independent is deliberate for
  this task (one-task-one-change); the two must not drift semantically. Tracked in the
  issue's scope.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-15-pasteboardsnapshot-and-textreplacementservice` (branch `issue-15-pasteboardsnapshot-and-textreplacementservice`)
- **Next action:** merge the PR / mark `agent:done` after review; behavior is exercised in T3.5.
- **Files in play:** `TextAssist/Utilities/PasteboardSnapshot.swift`, `TextAssist/Core/TextReplacementService.swift`
- **Watch out for:** this is one of several `area:core` tasks landed on top of `b00f21f`; keep the branch rebased before opening the PR.
- **Do not redo:** the two files are already created, committed, and the build passes.

## 10. Review

- Reviewer verdict: **approve**
- Findings: none blocking; only note was that the files were untracked at review time (committed since).
