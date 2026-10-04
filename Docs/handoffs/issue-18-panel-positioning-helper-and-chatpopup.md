# Handoff — issue #18 T4.3 — Panel positioning helper and ChatPopup

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #18 (T4.3) |
| Epic | #4 |
| Milestone | M3 - Chat |
| Status | in-progress |
| Branch | `issue-18-panel-positioning-helper-and-chatpopup` |
| Worktree | `build/worktrees/issue-18-panel-positioning-helper-and-chatpopup` |
| Base commit | `0776a1a` |
| Last commit | `60ab1d0` |
| Updated | 2026-10-05 |

## 1. What this task is

Add the Chat panel shell and a shared cursor-positioning helper. `ChatPopup` is the
non-activating floating panel that hosts `ChatPopupView` (built in T4.2), and
`PanelPositioning.positionNearCursor(_:)` centralizes the "center on mouse, clamp to the
screen's visible frame" math. This is the last UI piece before T4.4 wires Chat into the
orchestrator.

## 2. Plan

- [x] Add `UI/Shared/PanelPositioning.swift` with the PRD-provided `positionNearCursor(_:)`.
- [x] Add `UI/Chat/ChatPopup.swift` adapted from `SummaryPopup`.
- [x] Run the build check.
- [x] Commit and write the handoff.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/Shared/PanelPositioning.swift` | New `PanelPositioning` enum with `positionNearCursor(_:)`. |
| `TextAssist/UI/Chat/ChatPopup.swift` | New `ChatPopup` panel class (copy of `SummaryPopup` adapted for Chat). |

The three existing `positionPanelNearCursor` copies (SummaryPopup, CustomPromptPanel,
StylePickerPanel) are intentionally left alone.

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → PASS (`** BUILD SUCCEEDED **`, 0 errors, 0 warnings).
- **"Done when" checklist** (from the issue):
  - [x] `PanelPositioning.positionNearCursor(_:)` centers on mouse, clamped to `screen.visibleFrame`.
  - [x] `ChatPopup` uses `KeyablePanel` with `[.titled, .closable, .resizable, .nonactivatingPanel]`.
  - [x] Default size 520×560, min 380×320.
  - [x] Positions near cursor via `PanelPositioning`.
  - [x] Close/delegate wiring mirrors `SummaryPopup`.
  - [x] Three existing `positionPanelNearCursor` copies left alone.
  - [x] Builds.

## 5. How to test manually

> `ChatPopup` has no reachable in-app surface yet — the orchestrator only instantiates it
> in T4.4. The only executable verification for T4.3 itself is the build.

1. In the task worktree, run:
   `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData`
2. **Expected:** `** BUILD SUCCEEDED **` with no errors (the file-system-synchronized
   group compiles both new files automatically).

**Edge cases to try:** n/a · **Not testable yet because:** the panel is not shown until T4.4 wires `showChat(for:seed:)` in `SummarizationOrchestrator.swift`.

## 6. Decisions

- Added a `///` doc comment to `PanelPositioning` beyond the PRD snippet — matches the repo's doc-comment style. (Rejected: leaving it undocumented.)
- Kept `@MainActor` on `positionNearCursor(_:)` exactly as the PRD snippet specifies, even though it is redundant under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

## 7. Blockers / open questions

- None.

## 8. Known limitations

- `ChatPopup` is not yet reachable from the UI; that is T4.4's job (orchestrator wiring).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-18-panel-positioning-helper-and-chatpopup` (branch `issue-18-panel-positioning-helper-and-chatpopup`)
- **Next action:** Run `Scripts/agent/handoff.sh 18 review`, then open a PR and continue to T4.4 (orchestrator wiring).
- **Files in play:** `TextAssist/UI/Shared/PanelPositioning.swift`, `TextAssist/UI/Chat/ChatPopup.swift`
- **Watch out for:** T4.4 edits `Core/SummarizationOrchestrator.swift` (a `sequentialTasks` file) — run it alone, and call `closeChat()` in `showSummaryPopup`/`showCustomPromptPanel`.
- **Do not redo:** the two new files are committed (`60ab1d0`).

## 10. Review

- Reviewer verdict: changes required → resolved by committing and writing this handoff.
- Findings: (1) files uncommitted → now committed; (2) missing handoff → this document. Code itself approved: correct, in scope, no constraint violations.
