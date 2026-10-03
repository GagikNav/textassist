# Handoff — issue #17 T3.4 — Result popup UI: plain-text rendering, Diff toggle, original disclosure, Replace and Chat buttons

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #17 (T3.4) |
| Epic | #1 (Epic 3 — Write experience in the result popup) |
| Milestone | M2 - Write + Replace |
| Status | agent:review |
| Branch | `issue-17-result-popup-ui-plain-text-rendering-diff-toggle-original-di` |
| Worktree | `build/worktrees/issue-17-result-popup-ui-plain-text-rendering-diff-toggle-original-di` |
| Base commit | `b00f21f` |
| Last commit | `32c8df2` |
| Updated | 2026-10-04 |

## 1. What this task is

Give the result popup its Write-mode affordances. `SummaryPopupView` currently renders
every result as a single `Markdown(...)` block. T3.4 makes Write results render as plain
selectable text (Markdown would reflow line breaks and eat `*`/`_`), adds an "Original"
disclosure above the result, a Clean/Diff segmented toggle in the top toolbar, and
Replace (`⌘↩`) / Chat (`⌘T`) buttons in the bottom toolbar. The view model
(`SummaryPopupViewModel`, wired by T3.1) already exposes all the state and callbacks this
view needs; T3.4 only edits `UI/Popup/SummaryPopupView.swift`.

## 2. Plan

- [ ] Add a `resultBody` `@ViewBuilder` and replace the single `Markdown(...)` call in
      `content` with it — plain selectable `Text` for `viewModel.isWriteMode`, existing
      `Markdown(...)` otherwise. Diff branch shows `viewModel.diffText`.
- [ ] Add an "Original (N words)" `DisclosureGroup(isExpanded: $viewModel.showsOriginal)`
      at the top of the scroll content (above `errorBanner`), with the captured text in
      `.secondary`, `.textSelection(.enabled)`, max height 160 inside a `ScrollView`.
- [ ] Add the Clean/Diff segmented `Picker` in `topToolbar` (Write mode only), between
      `stylePicker` and the `Spacer`, disabled while streaming or when no diff.
- [ ] Add Replace (`⌘↩`, `.borderedProminent`, disabled unless `canReplace`) and Chat
      (`⌘T`, disabled while streaming) buttons to `bottomToolbar`.
- [ ] Keep the `#Preview` compiling; run the build check.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/Popup/SummaryPopupView.swift` | Added `resultBody` `@ViewBuilder` (plain selectable `Text` for Write, existing `Markdown` for Transform); `originalDisclosure` + `wordCount`; Clean/Diff segmented `Picker` in `topToolbar` (Write only, disabled while streaming/no diff); Replace (`⌘↩`, `.borderedProminent`, disabled unless `canReplace`) and Chat (`⌘T`) buttons in `bottomToolbar`. Only file changed. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **BUILD SUCCEEDED**
- **"Done when" checklist** (from the issue):
  - [x] builds
  - [ ] Write result is plain text (code in place; needs running app)
  - [ ] Diff toggle disabled while streaming (code in place; needs running app)
  - [ ] "Original" expands (code in place; needs running app)
  - [ ] Transform still renders Markdown (code in place; needs running app)

## 5. How to test manually

1. Open `TextAssist.xcodeproj`, Run the "Text Assist" scheme.
2. In TextEdit, type a paragraph, select it, press `⌥⇧S`, pick a **Write** style (e.g.
   Grammar/Concise).
3. **Expected:** the result body is plain selectable text (not reflowed Markdown); the
   top toolbar shows a Clean/Diff segmented control; the bottom toolbar shows Replace
   (prominent) and Chat buttons; "Original (N words)" sits above the result.
4. Click "Original (N words)".
   **Expected:** the disclosure expands to show the captured selection, secondary style.
5. While the result is still streaming, look at the Diff segment.
   **Expected:** the segmented control is disabled during streaming.
6. Pick a **Transform** style (e.g. Bullet points).
   **Expected:** the result renders via Markdown as before; Diff toggle and Replace
   button disappear (Write-only); Chat remains.

**Edge cases to try:** empty/whitespace selection → "Original (0 words)" label.
**Not testable yet because:** Diff content and Replace behavior are wired in T3.5
(`SummarizationOrchestrator` calls `recomputeDiff()` and supplies `onReplace`); until
then the Diff segment stays disabled because `diffText` is empty, and Replace is disabled
unless `canReplace` is true. The UI affordances themselves are verifiable now.

## 6. Decisions

- Render Write results with plain `Text` (not Markdown) — per PRD T3.4: Markdown reflows
  line breaks and eats `*`/`_`. (Rejected: unified Markdown renderer.)

## 7. Blockers / open questions

- None.

## 8. Known limitations

- Diff is inert until T3.5 calls `recomputeDiff()`; the toggle is visible but disabled
  (correctly, via `isDiffAvailable`).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-17-result-popup-ui-plain-text-rendering-diff-toggle-original-di` (branch `issue-17-result-popup-ui-plain-text-rendering-diff-toggle-original-di`)
- **Next action:** verify manually in the running app (§5), then merge the PR.
- **Files in play:** `TextAssist/UI/Popup/SummaryPopupView.swift` (edit only).
- **Watch out for:** `Text` ternary must keep both branches `AttributedString` (wrap the
  plain branch in `AttributedString(...)`) or it won't type-check on macOS 13.
- **Do not redo:** implementation is complete and review-approved — do not re-edit the
  view. `SummaryPopupViewModel` already has `isWriteMode`, `viewMode`,
  `isDiffAvailable`, `diffText`, `showsOriginal`, `canReplace`, `onReplace`,
  `onContinueInChat` (from T3.1) — no view-model changes in this task.

## 10. Review
APPROVE (no blocking findings)
- Findings: none blocking. Non-blocking: `⌘T` may collide with the system "Show Fonts"
  shortcut in some apps (spec-mandated); Replace-disabled state is not manually testable
  until T3.5 wires `onReplace`/`recomputeDiff()`.ict: TBD
- Findings: TBD
