# Handoff — issue #59 — Replace-in-place fails or beeps instead of replacing selection

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #59 (—, unmapped task) |
| Epic | Epic 3 — Write (label `epic:3`) |
| Milestone | M2 — Write + Replace |
| Status | In Review |
| Branch | `issue-59-replace-in-place-fails-or-beeps-instead-of-replacing-selecti` |
| Worktree | `build/worktrees/issue-59-replace-in-place-fails-or-beeps-instead-of-replacing-selecti` |
| Base commit | `ef56cd3` |
| Last commit | `ef56cd3` |
| Updated | 2026-10-05 |

## 1. What this task is

Pressing ⌘↩ (**Replace**) in the Write result popup did not replace the selected text
and produced a beep. The goal is to make Replace reliably paste the result over the
selection, restore the user's original clipboard, surface failures clearly, and remove
the unexplained sound — without violating the non-activating panel requirement.

## 2. Plan

- [x] INTAKE — `pickup-task 59`: DoR met (leaf, no deps), worktree started, `agent:in-progress`.
- [x] CONTEXT — Explorer subagent produced the context brief (files, flow trace, ranked risks).
- [x] REPRODUCE — empirical Swift harness proved the root cause (see §6 / §8).
- [x] IMPLEMENT — fix `TextReplacementService` (post ⌘V to the source PID; fail loudly on CGEvent creation).
- [x] VERIFY — build check passed; harness confirmed selection replacement via the new path.
- [ ] REVIEW — Reviewer subagent on the diff.
- [ ] HANDOFF — commit handoff on branch, mirror to issue, sync `agent:` label + Project.
- [ ] SYNC — open/update the PR, regenerate overview.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Core/TextReplacementService.swift` | Post the synthetic ⌘V directly to the source app's PID (`CGEvent.postToPid`) instead of the HID event tap; check CGEvent creation and throw a new `ReplacementError.eventCreationFailed` instead of a silent no-op. |
| `TextAssist/UI/Popup/SummaryPopupView.swift` | Copy stays enabled when an error is shown, so a failed Replace still leaves the result copyable (drop `errorMessage` from the Copy `.disabled` condition). |

`SummarizationOrchestrator.swift` already surfaced errors via `viewModel.errorMessage`
(shown in the popup's red banner) and kept the popup open for Copy/retry on failure, so
it needed no edit.

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **BUILD SUCCEEDED**.
- **"Done when" checklist** (from the issue):
  - [x] Reported behavior reproduced / likely boundary narrowed with a documented test and observed outcome (Swift harness, see §8).
  - [ ] Replace reliably updates the selection in TextEdit and one other editable app; clipboard preserved; no unexplained sound. *(build-level + harness-level verified; final running-app check in §5)*
  - [x] Failure → clear explanation + popup remains usable for Copy/retry (error banner already wired; new `eventCreationFailed` case added; Copy now stays enabled on error).
  - [x] Build passes.
  - [x] Manual verification steps recorded (see §5).

## 5. How to test manually

1. **Launch** Text Assist from Xcode (Run) or the built app. Confirm Accessibility
   permission is granted (System Settings → Privacy & Security → Accessibility; re-add
   the app if you rebuilt it).
2. **Prime the clipboard:** copy a known string, e.g. `ORIGINAL-CLIP`, from anywhere.
3. Open **TextEdit**, type `I has a apple and she dont like it`, and select the whole
   sentence.
4. Press **⌥⇧S**, choose **Fix Grammar** (key `g`), and wait for the result to stream.
5. Press **⌘↩** (**Replace**).
6. **Expected:** the selected sentence is replaced by the fixed text; the popup closes;
   the clipboard is restored to `ORIGINAL-CLIP` (⌘V elsewhere pastes it); no beep.
7. **Repeat** steps 2–6 in a second editable app (Notes, or VS Code).
8. **Failure path:** revoke Accessibility for Text Assist, retry Replace → the popup
   shows the red error banner ("Text Assist needs Accessibility permission…") and stays
   open so Copy still works.

**Edge cases to try:** nothing selected but a field focused → Replace stays disabled
(origin `fieldValue`); Safari non-editable selection → nothing is pasted, Copy works.
**Not testable yet because:** n/a — this is the full, self-contained change.

## 6. Decisions

- **Post the paste to the PID, not the HID event tap.** The popup is the key window
  while Replace runs (`KeyablePanel.canBecomeKey`, `becomesKeyOnlyIfNeeded = false`,
  `makeKeyAndOrderFront`). A `.cghidEventTap` ⌘V is delivered to the key window — the
  popup — which has no editable responder, so the paste is dropped and the system beeps.
  `CGEvent.postToPid` delivers the event to the source app regardless of the popup's key
  status. (Rejected: resigning the popup key before posting — more moving parts, and the
  popup must stay usable for Copy/retry on failure.)
- **Throw on CGEvent creation failure** (`eventCreationFailed`) instead of `?.post`
  silently no-opping and the popup closing as if it succeeded.
- **Keep Copy enabled on error.** A failed Replace sets `errorMessage` (shown in the red
  banner) but the streamed result is still valid, so Copy must remain available —
  `SummaryPopupView` now disables Copy only when `streamedText` is empty. (Rejected:
  leaving `errorMessage != nil` in the Copy `.disabled` condition, which made the popup
  unusable for Copy exactly when the issue requires it.)
- **Keep the 400 ms post-paste wait** for pasteboard restore. The reproduced race is the
  key-window delivery, not the restore timing, so the fixed delay was left alone.

## 7. Blockers / open questions

- None. (The only unverified item is the human running-app pass in §5; all other Done-when
  items are met.)

## 8. Known limitations

- Success is "no throw", not a read-back assertion: the service does not AX-verify that
  the destination field changed. This was deliberately left out to avoid false-negative
  errors on apps with flaky AX read-back; it is the remaining silent-failure gap (secure
  input or an app rejecting synthetic events).
- **Reproduction evidence (Swift harness, run 2026-10-05):** with a key non-activating
  `NSPanel` on screen and TextEdit focused — `.cghidEventTap` ⌘V left the field unchanged
  (the reported no-op + beep), while `CGEvent.postToPid` replaced a full selection
  (`MARKERHELLO WORLD` → `FIXED`). Harness deleted after the run.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-59-replace-in-place-fails-or-beeps-instead-of-replacing-selecti` (branch `issue-59-replace-in-place-fails-or-beeps-instead-of-replacing-selecti`)
- **Next action:** run the Reviewer subagent on the uncommitted diff, then commit + mirror the handoff and flip to `agent:done`.
- **Files in play:** `TextAssist/Core/TextReplacementService.swift`, `TextAssist/UI/Popup/SummaryPopupView.swift`
- **Watch out for:** do not edit `project.pbxproj`; the popup must stay non-activating.
- **Do not redo:** the fix itself, the build, and the harness reproduction are done.

## 10. Review

- Reviewer verdict: changes required → one blocking finding resolved (Copy was disabled
  on error, contradicting the "popup remains usable for Copy/retry" requirement; fixed by
  dropping `errorMessage` from the Copy `.disabled` condition).
- Findings: none outstanding. Non-blocking notes: in-app manual pass (§5) not yet run;
  success is "no throw", not AX-read-back verified (documented in §8).
