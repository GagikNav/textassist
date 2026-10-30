# Handoff — issue #75 — Cut the first updater-enabled release and verify updating end to end

| | |
|:--|:--|
| Issue | #75 |
| Epic | #69 |
| Status | In Review |
| Branch | `issue-75-cut-the-first-updater-enabled-release-and-verify-updating-en` |
| Updated | 2026-10-30 |

## 1. What this task is

Publish the first updater-enabled release and prove an installed copy updates itself.

## 2. Plan

- [x] Publish `v0.2.0` (certificate-signed).
- [x] Publish `v0.2.1` with a visible change (#98).
- [x] Update an installed 0.2.0 to 0.2.1 from inside the app.
- [x] Record results in `Docs/releasing.md`.

## 3. What changed

| File | Change |
|:--|:--|
| `Docs/releasing.md` | "First updater release: verified results". |
| `TextAssist/UI/MenuBar/MenuBarStatusView.swift` | Version line prefix (#98). |
| `Scripts/release.sh` | Fixes found on the way (#96, #97, #99). |

## 4. Verification

- **Build check:** Debug build passed; releases built by `Scripts/release.sh`.
- **Done when:**
  - [x] Both releases public with DMG, SHA-256, ZIP and `appcast.xml`.
  - [x] Installed 0.2.0 updated to 0.2.1 in-app; version shows 0.2.1.
  - [~] Results written; Gatekeeper, relaunch, duration not recorded.

## 5. How to test manually

1. Install an older release, open "Check for Updates…" and accept the update.
2. **Expected:** the version line shows the newest version; Replace still works with no new Accessibility prompt.

## 6. Decisions

- First updater release is 0.2.0 (not 0.1.2), as planned in the issue.

## 7. Blockers / open questions

- Gatekeeper prompt, relaunch and timing were not measured.

## 8. Known limitations

- Not notarized; first install is manual.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-75-cut-the-first-updater-enabled-release-and-verify-updating-en`
- **Next action:** merge the PR, then remove the worktree.
- **Files in play:** `Docs/releasing.md`
- **Do not redo:** the releases are published.

## 10. Review

- Reviewer verdict: not run.
- Findings: none.
