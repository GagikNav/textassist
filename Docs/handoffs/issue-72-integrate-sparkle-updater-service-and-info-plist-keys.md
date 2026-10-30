# Handoff — issue #72 — Integrate Sparkle: updater service and Info.plist keys

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #72 (unmapped task) |
| Epic | #69 — In-app updates and versioned releases |
| Milestone | — |
| Status | In Review |
| Branch | `issue-72-integrate-sparkle-updater-service-and-info-plist-keys` |
| Worktree | `build/worktrees/issue-72-integrate-sparkle-updater-service-and-info-plist-keys` |
| Base commit | `d863f5c` |
| Last commit | `fd6be06` |
| Updated | 2026-10-30 |

## 1. What this task is

Add Sparkle to the app so it can check for, download, verify and install updates. Engine
only: no UI (that is #73). Part of epic #69.

## 2. Plan

- [x] INTAKE — `pickup.sh 72`: known missing `epic:` label; started anyway.
- [x] IMPLEMENT — `UpdaterService`, Info.plist keys, app wiring.
- [x] PACKAGE — Sparkle added to the project (see §6, project-file exception).
- [x] VERIFY — Debug build check; Release build through `release.sh` (see §4).
- [ ] REVIEW — no reviewer subagent run.
- [ ] SYNC — PR, merge, remove worktree.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Core/UpdaterService.swift` (new) | `ObservableObject` wrapping `SPUStandardUpdaterController`. Release builds start the updater at launch. Debug builds start it only on a manual check (they report version `1.0` and would always see an update). Exposes `canCheckForUpdates`, `automaticallyChecksForUpdates` and `checkForUpdates()`. |
| `TextAssist/Info.plist` | `SUFeedURL` (latest release `appcast.xml`), `SUPublicEDKey` (the key from #71), `SUEnableAutomaticChecks` true, `SUScheduledCheckInterval` 86400. |
| `TextAssist/App/TextAssistApp.swift` | One `UpdaterService` kept as a `@StateObject`. |
| `TextAssist.xcodeproj/project.pbxproj` | **Exception, approved by the maintainer in chat:** Sparkle 2.10.1 (up to next major) added as a remote package and linked to the target. 17 added lines, none removed. |
| `…/swiftpm/Package.resolved` | Records Sparkle 2.10.1. |

## 4. Verification

- **Build check:** `xcodebuild build … -configuration Debug …` → **BUILD SUCCEEDED**, no warnings from the new files.
- **"Done when" checklist** (from the issue):
  - [x] A Release build contains `Contents/Frameworks/Sparkle.framework` (built through `release.sh`, 0.1.2 build 125, universal).
  - [x] `codesign --verify --deep --strict` passes on the ad-hoc signed Release app (no individual signing of nested components needed).
  - [x] The built app's `SUPublicEDKey` equals the key in the maintainer's Keychain (`generate_keys -p`); `SUFeedURL`, `SUEnableAutomaticChecks` and the interval are present.
  - [ ] The app launches and the console shows no Sparkle configuration error — **not run** (see §7).
  - [x] `project.pbxproj` changed only by the package reference added for Sparkle.
- The Release run used a temporary copy of `release.sh` without the worktree/branch guards (deleted, not committed) and a throwaway signing key.

## 5. How to test manually

1. Run the Release app: from `main` after merge, `Scripts/release.sh --bump patch --skip-upload`, then open `build/release/Export/Text Assist.app` (quit any running Text Assist first).
2. Open Console.app, filter on `Text Assist` and `Sparkle`, and watch the first minute.
3. **Expected:** no "configuration" or "public key" errors. A failed fetch of `appcast.xml` (404) is expected until the first updater release publishes one.

**Not testable yet because:** there are no update menu items until #73, and no `appcast.xml` is published until #75.

## 6. Decisions

- **pbxproj exception:** the ticket required the maintainer to add the package in Xcode. The maintainer asked the agent to do it instead, which is the explicit approval the rule needs. The edit copies the existing two packages' entries exactly (build file, frameworks phase, target product dependency, project package reference, package reference, product dependency) and was checked by `plutil -lint`, package resolution and builds.
- Debug builds start the updater lazily, not by turning off automatic checks, because the Debug and Release app share one bundle id and one preferences domain; changing the setting would leak into the installed app.
- Version rule `upToNextMajor` from 2.10.1, matching the tools in `~/sparkle-tools`.

## 7. Blockers / open questions

- The app was not launched here. The Debug and Release app share the bundle id and preferences with an installed copy and register the global hotkey, so a test launch could change the maintainer's real settings. The launch check is left for the maintainer (§5).

## 8. Known limitations

- No UI yet (#73). The first real update needs the first updater release (#75).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-72-integrate-sparkle-updater-service-and-info-plist-keys`
- **Next action:** merge the PR, remove the worktree (`Scripts/agent/worktree.sh 72 --remove`), then start #73.
- **Files in play:** `TextAssist/Core/UpdaterService.swift`, `TextAssist/Info.plist`, `TextAssist/App/TextAssistApp.swift`
- **Watch out for:** `canCheckForUpdates` is `true` in Debug until the first check, by design.
- **Do not redo:** the package edit; the Release and signature checks.

## 10. Review

- Reviewer verdict: not run.
- Findings: none open.
