# Handoff — issue #60 — Menu-bar Assist with Selection beeps and does not start capture

> **CANCELED (2026-10-05):** the menu-bar "Assist with Selection" action was removed
> entirely and replaced with an inert "Open TextAssist" placeholder (a dashboard will be
> added there later). The global `⌥⇧S` hotkey remains the selection-assist entry point.
> See `tickets/PRD-v2.md` §4.5 and T5.2. The fix described below is superseded.

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #60 (—, unmapped task) |
| Epic | Epic 5 — Menu bar status (label `epic:5`) |
| Milestone | M4 — Menu bar status |
| Status | In Review |
| Branch | `issue-60-menu-bar-assist-with-selection-beeps-and-does-not-start-capt` |
| Worktree | `build/worktrees/issue-60-menu-bar-assist-with-selection-beeps-and-does-not-start-capt` |
| Base commit | `f6a7c29` |
| Last commit | `22f884f` |
| Updated | 2026-10-05 |

## 1. What this task is

Clicking **Assist with Selection** in the menu-bar popover beeped and did nothing.
Opening the `MenuBarExtra` popover activates Text Assist, so by the time the user clicks
the button the frontmost app is no longer the one holding the selection. Capture then
targeted Text Assist, and the ⌘C fallback posted to the popover's key window — which has
no editable responder — so the copy was dropped and the system beeped. The goal is to
make the menu-bar action capture from the app the user was in before opening the menu
(just like ⌥⇧S), keep the clipboard and the hotkey flow intact, and surface capture
failures clearly instead of a beep/no-op.

## 2. Plan

- [x] INTAKE — `pickup-task 60`: DoR met (leaf, dep #23 closed), worktree started, `agent:in-progress`.
- [x] CONTEXT — traced the menu → hotkey → orchestrator → capture path directly (single continuous trace).
- [x] IMPLEMENT — `SourceAppTracker` + thread the source app through capture; `postToPid` fallback; `NSAlert` failure feedback.
- [x] VERIFY — build check passed.
- [x] REVIEW — Reviewer subagent on the diff (blocking item was the missing handoff; resolved by this doc).
- [x] HANDOFF — commit handoff on branch, mirror to issue, sync `agent:` label + Project.
- [ ] SYNC — open/update the PR; flip to `agent:done` after the human running-app pass merges.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Core/SourceAppTracker.swift` | New. Remembers the most recent frontmost app that is not Text Assist, via `NSWorkspace` activate/deactivate notifications. |
| `TextAssist/App/TextAssistApp.swift` | Creates the tracker and passes `sourceAppTracker.lastNonSelfApp` into the menu's `onSummarize`. |
| `TextAssist/Core/HotkeyManager.swift` | `triggerSummarize(from:)` accepts an optional source app (nil for the hotkey). |
| `TextAssist/Core/SummarizationOrchestrator.swift` | `startSummarization`/`startDirect` accept the source app; capture failures now show an actionable `NSAlert` ("Open System Settings" for missing Accessibility). |
| `TextAssist/Core/TextCaptureService.swift` | `captureSelection(from:)` targets the given app, activates it when it isn't frontmost, and posts the ⌘C fallback directly to its PID (`CGEvent.postToPid`) instead of the HID event tap. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **BUILD SUCCEEDED** (no errors or warnings in changed files).
- **"Done when" checklist** (from the issue):
  - [x] Menu action opens the style picker with selected text from TextEdit and a ⌘C-fallback app — *(code path verified + build passed; final running-app check in §5)*
  - [x] Original clipboard unchanged during fallback; global ⌥⇧S flow works — *(save/restore unchanged; hotkey passes `nil` and uses the frontmost app as before)*
  - [x] Missing selection / Accessibility permission → actionable feedback, not a beep/log — *(`NSAlert` in `presentCaptureError`)*
  - [x] Build check passes.
  - [x] Manual verification steps recorded (see §5).

## 5. How to test manually

1. **Launch** Text Assist from Xcode (Run) or the built app. Grant Accessibility permission
   (System Settings → Privacy & Security → Accessibility; re-add the app if you rebuilt it).
2. Open **TextEdit**, type a phrase, select it. Click the Text Assist menu-bar icon, then
   **Assist with Selection**.
3. **Expected:** the popover closes, the style picker opens near the cursor with the
   selected text, and no beep is heard.
4. **Fallback app:** repeat steps 2–3 in an app that doesn't expose `AXSelectedText`
   (e.g. Microsoft Word, or another editor that forces the ⌘C fallback). The picker still
   opens with the copied text.
5. **Clipboard preservation:** copy a known string (e.g. `ORIGINAL-CLIP`) first, then run
   step 4. **Expected:** after capture, pasting elsewhere still yields `ORIGINAL-CLIP`.
6. **Hotkey regression:** with text selected in TextEdit, press **⌥⇧S**. **Expected:** the
   style picker opens exactly as before.
7. **No selection:** with nothing selected, trigger the flow (menu or hotkey). **Expected:**
   an alert appears ("No text selection found.") instead of a beep/console log only.
8. **Accessibility missing:** temporarily revoke Accessibility for Text Assist, trigger the
   flow. **Expected:** an alert appears with an **Open System Settings** button that opens
   the Accessibility pane; no beep.

**Edge cases to try:** select text, then switch away and back before clicking the menu item.
**Not testable yet because:** n/a — this is the full, self-contained change.

## 6. Decisions

- **Track the pre-popover app instead of guessing at capture time.** The popover activates
  Text Assist, so `frontmostApplication` at capture time is wrong. `SourceAppTracker`
  records the last non-self app on activate *and* deactivate, covering the case where the
  source app never activated while the tracker was running. (Rejected: reading
  `frontmostApplication` at capture time — the original bug; polling — racy and wasteful.)
- **Post ⌘C to the source PID, not the HID event tap.** Same reasoning as
  `TextReplacementService`: the popover is the key window and has no editable responder,
  so a `.cghidEventTap` copy is dropped and beeps. `CGEvent.postToPid` delivers directly
  to the source app. (Rejected: activating the source app alone and keeping the HID tap —
  still delivered to the key window if activation hadn't settled.)
- **Activate the source app before capture.** Dismisses the popover, restores the
  source-app focus, and makes the AX/⌘C capture and later Replace behave like the hotkey
  flow. A 50 ms yield follows activation to avoid a race on slower apps.
- **`NSAlert` for failures** rather than a non-activating panel. Capture failures need the
  user's attention (especially the Accessibility case), and `runModal` with an "Open
  System Settings" button is the simplest actionable pattern.

## 7. Blockers / open questions

- None. (The only unverified item is the human running-app pass in §5; all other Done-when
  items are met or code-verified.)

## 8. Known limitations

- `SourceAppTracker` can be stale if the user opens the popover while Text Assist is
  already frontmost (e.g. right after Settings); the normal flow (clicking the icon from
  another app) is unaffected.
- Success is "no throw", not an AX read-back assertion; the remaining silent-failure gap
  is an app that ignores synthetic copy events, which then surfaces as the "No text
  selection found." alert.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-60-menu-bar-assist-with-selection-beeps-and-does-not-start-capt` (branch `issue-60-menu-bar-assist-with-selection-beeps-and-does-not-start-capt`)
- **Next action:** push the branch, open the PR, and after the human running-app pass in §5 merge and flip to `agent:done`.
- **Files in play:** `TextAssist/Core/SourceAppTracker.swift`, `TextAssist/Core/TextCaptureService.swift`, `TextAssist/Core/SummarizationOrchestrator.swift`, `TextAssist/Core/HotkeyManager.swift`, `TextAssist/App/TextAssistApp.swift`
- **Watch out for:** do not edit `project.pbxproj`; keep the popover non-activating; `SourceAppTracker` is a new untracked-by-name file that must be committed with the change.
- **Do not redo:** the fix, the build, and the reviewer pass are done.

## 10. Review

- Reviewer verdict: changes required → one blocking item (missing handoff with manual
  verification steps) resolved by this document. No blocking code findings.
- Findings: none outstanding. Non-blocking notes: activation is asynchronous (addressed
  with a 50 ms yield); `postToPid` bypasses third-party clipboard-manager event taps
  (acceptable, and prevents them from interfering); `runModal` blocks the MainActor for
  the alert's lifetime (standard AppKit practice).
