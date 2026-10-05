# Handoff — issue #24 T6.3 — Settings: hotkey recorders and launch at login

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #24 (T6.3) |
| Epic | #6 |
| Milestone | M5 - Polish (P1) |
| Status | agent:review (code committed; awaiting human manual check + PR) |
| Branch | `issue-24-settings-hotkey-recorders-and-launch-at-login` |
| Worktree | `build/worktrees/issue-24-settings-hotkey-recorders-and-launch-at-login` |
| Base commit | `dd14cfe` |
| Last commit | `7fd6fc9` — "T6.3 — Settings: hotkey recorders and launch at login" |
| Updated | 2026-10-05 |

## 1. What this task is

T6.1 added the three global hotkeys (Assist `⌥⇧S`, Chat `⌥⇧C`, Fix grammar `⌥⇧G`),
but the user had no way to see or change them. T6.3 surfaces them in Settings: a new
"General" section shows a `KeyboardShortcuts.Recorder` for each shortcut (recording a
new key combination takes effect immediately through the existing
`KeyboardShortcuts.onKeyUp` registrations) and adds a "Launch at login" toggle backed
by `SMAppService.mainApp`, so the app can start at login and that choice survives a
reboot. The settings panel grows from 220pt to 400pt tall to fit the new controls.

## 2. Plan

- [x] Add `import KeyboardShortcuts` and `import ServiceManagement` to
      `ProviderSettingsView`.
- [x] Add a `Section("General")` with the three `KeyboardShortcuts.Recorder` views
      (Assist, Chat, Fix grammar) and the "Launch at login" `Toggle` (PRD §7 T6.3 code
      verbatim: register/unregister on change, revert on error).
- [x] Add `@State private var launchAtLogin = SMAppService.mainApp.status == .enabled`.
- [x] Grow the settings panel: `SettingsPanel.show()` hosting frame 220 → 400 and the
      view `minHeight` 180 → 400.
- [x] Run the build check from the worktree.
- [x] Independent Reviewer pass on the diff.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/Settings/ProviderSettingsView.swift` | New "General" section: three `KeyboardShortcuts.Recorder`s and a launch-at-login `Toggle`; imports `KeyboardShortcuts`/`ServiceManagement`; `@State launchAtLogin`; view `minHeight` 180 → 400. |
| `TextAssist/UI/Settings/SettingsPanel.swift` | Hosting controller frame height 220 → 400. |

No files were added or removed; `project.pbxproj` was not touched (the target uses a
file-system-synchronized group; `ServiceManagement`/`KeyboardShortcuts` link
automatically via Swift module auto-linking).

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData"`
  → **BUILD SUCCEEDED**, no compiler warnings introduced.
- **"Done when" checklist** (from the issue):
  - [ ] Changing a hotkey in Settings takes effect immediately — **not runtime-verified**; mechanism in place (see §5). Code-level: the recorders bind to the same `KeyboardShortcuts.Name` values (`summarizeSelection`, `chatWithSelection`, `fixGrammar`) that `HotkeyManager.registerShortcuts()` already observes via `onKeyUp`, and `KeyboardShortcuts` re-registers the global hotkey when a recorder changes it.
  - [ ] The toggle persists across reboot — **not runtime-verified**; mechanism in place. `SMAppService.mainApp.register()`/`unregister()` write the system login item, which macOS persists across reboots.

  Both items need a human check in the running app (§5) — the project has no test
  target by design, and these behaviours depend on Accessibility permission and a real
  login-item registration.

## 5. How to test manually

> The launch-at-login step requires the app to live in `~/Applications` or
> `/Applications` (the issue notes this); a DerivedData build path can make
> `SMAppService` reject registration. For the hotkey steps any build works.

1. **Run the worktree's build:**
   ```bash
   osascript -e 'tell application "Text Assist" to quit'   # quit any running instance first
   cd build/worktrees/issue-24-settings-hotkey-recorders-and-launch-at-login
   open "build/DerivedData/Build/Products/Debug/Text Assist.app"
   ```
   Or open this worktree's `TextAssist.xcodeproj` in Xcode and Run.
2. Click the menu-bar icon → **Settings** to open the settings panel.
3. **Expected:** the panel is taller (~400pt) and shows a **General** section at the
   top with three recorder rows — "Assist:", "Chat:", "Fix grammar:" — each showing
   its current shortcut (`⌥⇧S`, `⌥⇧C`, `⌥⇧G`), followed by a "Launch at login" toggle
   and the existing **Ollama** section underneath.
4. Click the **"Assist:"** recorder and press a new combination (e.g. `⌥⇧K`). The
   recorder displays the new shortcut.
5. In TextEdit, select text and press your new combination.
6. **Expected:** the style picker opens immediately (the new Assist shortcut is live
   with no restart). Repeat for **"Chat:"** (`⌥⇧C` → Chat popup) and
   **"Fix grammar:"** (`⌥⇧G` → grammar-fix summary) if desired — the mechanism is
   identical for all three.
7. Toggle **"Launch at login"** on. (If it immediately snaps back off, `SMAppService`
   refused registration — usually because the app isn't in `~/Applications` or
   `/Applications`; copy the built app there first and retry.)
8. Reboot (or log out and back in).
9. **Expected:** Text Assist starts automatically at login, and opening Settings shows
   the toggle still on.

**Edge cases to try:**

- Toggle "Launch at login" off and reboot — the app no longer auto-starts.
- Record the same shortcut for two different actions — `KeyboardShortcuts` warns and
  the recorder shows a conflict; the earlier registration is expected to keep working.

**Not testable automatically because:** no test target by design (`AGENTS.md`);
verification is "it builds + a manual check in the running app", and both Done-when
items need Accessibility permission and a real login-item registration on the host.

## 6. Decisions

- **Followed the PRD §7 T6.3 code verbatim** for the launch-at-login toggle, including
  the `launchAtLogin = !enabled` revert-on-error. (Rejected: a computed `Binding` over
  `SMAppService.mainApp.status` — more robust, but deviates from the frozen spec.)
- **Added the "General" section above "Ollama"** in the existing single `Form`, rather
  than a new view/file, because the issue lists only `ProviderSettingsView.swift` and
  `SettingsPanel.swift` as files in play.
- **Kept the `///` doc-comment style** and updated `ProviderSettingsView`'s doc comment
  to reflect that it now hosts both General and Ollama sections (not just Ollama).
- **Panel + view `minHeight` both set to 400**, matching the issue's "grow … to about
  400 (panel and view minHeight)".

## 7. Blockers / open questions

- None.

## 8. Known limitations

- **Fixed 400pt panel height.** The hosting controller uses a fixed 400pt frame while
  the SwiftUI view only declares `minHeight: 400`; if the Ollama error text grows the
  content beyond 400 the panel could clip. Deliberately kept to the issue's "about
  400" instruction; a scrollable `Form` would be the follow-up if it ever clips.
- **Revert-on-error re-fires `.onChange`.** If `register()` throws, the revert sets
  `launchAtLogin = false`, which re-fires `.onChange` and calls `unregister()`; a
  pathological case where both always throw could oscillate. This is the PRD's exact
  code and matches the spec, so it is left as-is.
- **Launch-at-login needs a real app bundle location.** Registration works best from
  `~/Applications` or `/Applications` (noted on the issue); from a DerivedData path
  `SMAppService` may refuse, which is environmental, not a code defect.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-24-settings-hotkey-recorders-and-launch-at-login` (branch `issue-24-settings-hotkey-recorders-and-launch-at-login`)
- **Next action:** open the PR for this branch and hand it to a human for the §5
  manual checks; after the PR merges, remove the worktree
  (`Scripts/agent/worktree.sh 24 --remove`).
- **Files in play:** `TextAssist/UI/Settings/ProviderSettingsView.swift`,
  `TextAssist/UI/Settings/SettingsPanel.swift`
- **Watch out for:** `T6.1` (issue #25) must already be merged for the
  `KeyboardShortcuts.Name` values to exist — it is (closed). The toggle state is read
  once when the view is created, so the panel reflects the login-item status only when
  it is (re)opened.
- **Do not redo:** the implementation, build check, and reviewer pass are all done.

## 10. Review

- Reviewer verdict: **Approve — no blocking findings.** Independent Reviewer subagent
  ran the build from the worktree (BUILD SUCCEEDED, zero warnings) and checked the diff
  against the issue's Done-when, the PRD T6.3 code, the `AGENTS.md` hard constraints,
  and scope (exactly the two specified files; no `project.pbxproj`; macOS 13-only APIs;
  single-parameter `.onChange(of:)`; non-activating panel preserved).
- Findings: **none blocking.** Non-blocking notes, both recorded in §8:
  1. revert-on-error can re-fire `.onChange` (PRD-verbatim, left as-is);
  2. fixed 400pt panel height could clip if content ever grows (left as-is per spec).
