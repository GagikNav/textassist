# Handoff — issue #67 — Make Esc work while a text input has focus

| | |
|:--|:--|
| Issue | #67 |
| Epic | #68 |
| Milestone | none |
| Status | review (analysis only, NOT verified in the running app) |
| Branch | `issue-67-make-esc-work-while-a-text-input-has-focus` |
| Worktree | `build/worktrees/issue-67-make-esc-work-while-a-text-input-has-focus` |
| Base commit | `ebb7188` |
| Updated | 2026-10-30 |

## 1. What this task is

Check whether Esc closes a `KeyablePanel` while a text input has focus (chat field, custom prompt editor, settings Base URL/Model), and fix what fails. The agent cannot launch the app, so nothing was reproduced; the cases were analysed from the code.

## 2. Plan

- [x] Analyse each input against the panel-level `cancelOperation` from #65.
- [x] Add an IME guard to `KeyablePanel.cancelOperation`.
- [x] Build check, reviewer pass.
- [ ] Maintainer runs the manual steps below.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/Shared/KeyablePanel.swift` | `cancelOperation` returns early when the first responder is an `NSTextInputClient` with marked text, so Esc only cancels an IME composition. |

No change to `ChatPopupView`, `ProviderSettingsView` or `CustomPromptView`.

## 4. Verification

- **Build check:** `xcodebuild build ... -derivedDataPath build/DerivedData` → PASS (BUILD SUCCEEDED).
- **Analysis per case (all unverified in the app):**
  - Chat `TextField(axis: .vertical)`: AppKit text view; plain Esc is not consumed (`complete:` is F5/Opt-Esc), so it goes up the responder chain to `KeyablePanel.cancelOperation`. Expected to work; no change.
  - Settings Base URL / Model: `NSTextField` field editor forwards unhandled `cancelOperation:` up the chain to the panel. Expected to work; no change. (The Model Picker, when shown, is a menu that handles its own Esc.)
  - Custom prompt `TextEditor`: the hidden `.keyboardShortcut(.cancelAction)` Cancel button already handles Esc as a key equivalent and calls `onCancel`, which closes the panel. Expected to work; no change.
  - IME: the input context consumes Esc during composition before `cancelOperation` is reached. The new guard is an explicit backstop on that path.
- **"Done when"**
  - [x] Build passes.
  - [ ] Esc closes chat (empty and with draft), custom prompt, settings (unverified).
  - [ ] Esc during IME composition does not close (unverified).

## 5. How to test manually

1. Run `Scripts/run.sh` from this worktree. `⌥⇧S` → Chat. With the cursor in the message field press Esc. Expected: closes. Reopen, type a draft, press Esc. Expected: closes.
2. `⌥⇧S` → Custom prompt, click into the editor, type, press Esc. Expected: closes.
3. Menu bar → Settings, click into Base URL (and Model if it is a text field), press Esc. Expected: closes.
4. Switch to a Japanese or Chinese input source. In the chat field type until text is underlined; press Esc. Expected: underline discarded, chat stays open. Repeat in the custom prompt editor.
5. If any of 1-3 fails on `main`-like behaviour, apply the fallback below.

## 6. Decisions

- Only the IME guard was added; the three inputs are believed to work already. (Rejected: hidden Cancel buttons or `.onExitCommand` per view, extra code without evidence of failure.)

## 7. Blockers / open questions

- Unverified which inputs swallow Esc, if any. Fallback: override `sendEvent(_:)` in `KeyablePanel` to catch key code 53 before the field editor (skip when `hasMarkedText()`), or add `.onExitCommand` per view.
- Custom prompt: the `.cancelAction` button is a key equivalent and bypasses the new guard. If step 4 shows it closing during composition, remove the button's shortcut and rely on the panel path (then wire `onCancel` through `KeyablePanel.onClose`).

## 8. Known limitations

- Not run in the app (agents may not launch it).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-67-make-esc-work-while-a-text-input-has-focus`
- **Next action:** maintainer runs section 5 and reports; apply the fallback for any failing step.
- **Files in play:** `TextAssist/UI/Shared/KeyablePanel.swift`, `TextAssist/UI/CustomPrompt/CustomPromptView.swift`
- **Watch out for:** `onCancel` in `CustomPromptPanel` does extra work beyond `close()`; a panel-level Esc path skips it.
- **Do not redo:** code analysis, build, review.

## 10. Review

- Reviewer verdict: approve, manual check required.
- Findings: no blocking. Non-blocking: custom prompt `.cancelAction` bypasses the IME guard (check with a real IME).
