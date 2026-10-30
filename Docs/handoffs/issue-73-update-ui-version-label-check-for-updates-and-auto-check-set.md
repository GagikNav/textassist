# Handoff — issue #73 — Update UI: version label, Check for Updates… and auto-check setting

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #73 (unmapped task) |
| Epic | #69 — In-app updates and versioned releases |
| Milestone | — |
| Status | In Review |
| Branch | `issue-73-update-ui-version-label-check-for-updates-and-auto-check-set` |
| Worktree | `build/worktrees/issue-73-update-ui-version-label-check-for-updates-and-auto-check-set` |
| Base commit | `2968638` |
| Last commit | `8137b96` |
| Updated | 2026-10-30 |

## 1. What this task is

Give the user visible control over updates: the current version in the menu-bar window, a
"Check for Updates…" button, and an automatic-check toggle in Settings. Part of epic #69.

## 2. Plan

- [x] INTAKE — `pickup.sh 73`: known missing `epic:` label; started anyway.
- [x] IMPLEMENT — menu-bar button and version line; Settings "Updates" section; plumbing.
- [x] VERIFY — Debug build check passes.
- [ ] VERIFY BY HAND — the UI itself was not run (see §7).
- [ ] REVIEW — no reviewer subagent run.
- [ ] SYNC — PR, merge, remove worktree.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/MenuBar/MenuBarStatusView.swift` | New `updater` property. "Check for Updates…" button after "Settings…", disabled while `canCheckForUpdates` is false. "Version X (build N)" caption at the bottom, read from the bundle. Preview updated. |
| `TextAssist/UI/Settings/ProviderSettingsView.swift` | New "Updates" section with a "Check for updates automatically" toggle bound to `UpdaterService.automaticallyChecksForUpdates`, plus a one-line footer. |
| `TextAssist/UI/Settings/SettingsWindow.swift`, `SettingsPanel.swift` | Pass the updater through to the settings view. Panel height 400 → 500 so the new section fits (an estimate, not looked at). |
| `TextAssist/App/TextAssistApp.swift` | Creates the updater once, passes it to the settings panel and the menu-bar view. |
| `TextAssist/Core/UpdaterService.swift` | `checkForUpdates()` first brings the app forward (`activate()` on macOS 14+, `activate(ignoringOtherApps:)` before), because a menu-bar-only app would open Sparkle's window behind other apps. |

`SettingsPanel.swift` and `SettingsWindow.swift` are not in the ticket's file list; the settings view is built there, so the updater had to pass through them.

## 4. Verification

- **Build check:** `xcodebuild build … -configuration Debug …` → **BUILD SUCCEEDED**; no warnings from the changed files.
- **"Done when" checklist** (from the issue):
  - [ ] Version line matches the built app's version/build — **not run** (reads `CFBundleShortVersionString` / `CFBundleVersion`; Debug shows `1.0 (build 1)`).
  - [ ] "Check for Updates…" opens Sparkle's window in front — **not run**.
  - [ ] Toggle persists across relaunch — **not run**.
  - [ ] `⌥⇧S` picker/popup still leaves the source app frontmost — **not run**; the only activation added is inside the explicit button action.

## 5. How to test manually

1. From the task worktree run `Scripts/run.sh` (builds Debug and opens it). Quit any running Text Assist first: it shares the bundle id, preferences and global hotkey.
2. Click the menu bar icon. **Expected:** a "Check for Updates…" row under "Settings…" and "Version 1.0 (build 1)" at the bottom.
3. Click "Check for Updates…". **Expected:** Sparkle's window opens in front of other apps. Until a release carries `appcast.xml` (#75) it ends with an error that the update feed could not be loaded; "You're up to date" is only possible after that.
4. Open Settings. **Expected:** an "Updates" section with a toggle, on by default. Turn it off, quit, relaunch, reopen Settings: it stays off. Turn it back on.
5. In TextEdit select text, press `⌥⇧S`. **Expected:** the picker opens, TextEdit stays frontmost, and Replace still works.

**Edge cases to try:** open Settings while a check window is open; check twice in a row (button disables while a check runs). · **Not testable yet because:** a real "update available" needs two published versions (#75).

## 6. Decisions

- Activation lives in `UpdaterService.checkForUpdates()` so every entry point gets it, and only for explicit user requests.
- Version caption sits at the bottom of the menu-bar window, not above the status row, so it does not compete with the Ollama status.
- The auto-check toggle shows Sparkle's stored value; no separate setting is kept.

## 7. Blockers / open questions

- The UI was not launched here: the Debug app shares its bundle id, preferences and global hotkey with an installed copy, and no screenshot tool is available in this session.
- The Settings panel height (500) is an estimate; the form scrolls if it is too small.

## 8. Known limitations

- No "update available" badge in the menu bar; out of scope for this task.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-73-update-ui-version-label-check-for-updates-and-auto-check-set`
- **Next action:** run the steps in §5, then merge the PR and remove the worktree (`Scripts/agent/worktree.sh 73 --remove`). After that #83 and #75 remain.
- **Files in play:** `MenuBarStatusView.swift`, `ProviderSettingsView.swift`, `UpdaterService.swift`
- **Watch out for:** `canCheckForUpdates` is `true` in Debug until the first check, by design.
- **Do not redo:** the plumbing through `SettingsPanel` / `SettingsView`.

## 10. Review

- Reviewer verdict: not run.
- Findings: none open.
