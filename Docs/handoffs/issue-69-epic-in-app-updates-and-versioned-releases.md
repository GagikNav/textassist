# Handoff — epic #69 — In-app updates and versioned releases

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the epic and for the session that created it: any model or session resumes
> from **Resume here**. Read §11 first if you are a fresh session.

| | |
|:--|:--|
| Issue | #69 (epic) |
| Epic | — |
| Milestone | — |
| Status | In Progress |
| Branch | `issue-69-epic-in-app-updates-and-versioned-releases` |
| Worktree | `build/worktrees/issue-69-epic-in-app-updates-and-versioned-releases` |
| Base commit | `6811f57` |
| Last commit | `5bc3bbc` |
| Updated | 2026-10-30 |

## 1. What this epic is

Let Text Assist update itself without a manual reinstall: the app checks GitHub for a newer
release, downloads it, verifies it and relaunches. Along the way releases got a version
scheme and written instructions. Homebrew is an optional second install channel.

**Chosen approach:** Sparkle (standard macOS updater) reading
`https://github.com/GagikNav/textassist/releases/latest/download/appcast.xml`. Each release
uploads a signed ZIP and an `appcast.xml` next to the DMG; no server. Rejected: a hand-written
updater (we would own signature checks and relaunch) and Homebrew as the only mechanism
(needs the user to run `brew`).

## 2. Plan

| # | Task | State |
|:--|:--|:--|
| #70 | Versioning policy, release guide, reliable release version | done (PR #78) |
| #71 | Sparkle update-signing key (maintainer action) | done (PR #90) |
| #72 | Integrate Sparkle (service, Info.plist keys, package) | done (PR #92) |
| #73 | Update UI: version line, Check for Updates…, auto-check toggle | done (PR #93) |
| #74 | Release script: ZIP, signature, `appcast.xml`, upload | done (PR #91) |
| #77 | Spike: stable signing so Accessibility survives updates | done (PR #84) |
| #83 | Sign releases with a stable self-signed certificate | **ready** |
| #75 | Cut the first updater release and verify an end-to-end update | blocked by #83 |
| #76 | Homebrew tap and cask | ready, optional |

## 3. What changed (epic so far)

| Area | Change |
|:--|:--|
| `Scripts/release.sh` | Version from an explicit `X.Y.Z` or `--bump patch|minor|major` (highest `v*` tag); checks the built app reports it; builds the update ZIP, signs it with Sparkle's `sign_update`, verifies it, checks the app's `SUPublicEDKey` against the Keychain key, writes `appcast.xml`, uploads DMG, checksum, ZIP and appcast. |
| `Docs/releasing.md` | Versioning scheme, how to cut/verify/withdraw a release, update signing key, appcast, signing and permissions. |
| `TextAssist/Core/UpdaterService.swift` | Wraps `SPUStandardUpdaterController`; Release starts it at launch, Debug only on a manual check; brings the app forward before a check. |
| `TextAssist/Info.plist` | `SUFeedURL`, `SUPublicEDKey`, `SUEnableAutomaticChecks`, `SUScheduledCheckInterval` (86400). |
| `project.pbxproj` | Sparkle 2.10.1 added (one approved exception; `Package.resolved` updated). |
| UI | Menu-bar window: "Check for Updates…" and "Version X (build N)"; Settings: "Updates" toggle. |
| Agent tooling | `pickup.sh` accepts a native parent epic instead of an `epic:` label; `workflow.md` §7.3 and new §11; issue-contract skill and issue-body template updated; `AGENTS.md` pointers. |

## 4. Verification

- **Build check:** Debug build passes on every merged task; a full Release build through `release.sh` passed after #72.
- **Verified:** versions and build numbers in the built app; ZIP unpacks to a validly signed app; `edSignature` verifies and a tampered ZIP is rejected (throwaway key); the key-mismatch guard stops/warns correctly (stub tests); the app's `SUPublicEDKey` equals the Keychain key; `codesign --verify --deep --strict` passes with Sparkle embedded; the menu-bar "Check for Updates…" works and ends with "An error occurred in retrieving update information", which is correct because the feed currently returns **404** (v0.1.1 has no `appcast.xml`).
- **Measured (#77):** an ad-hoc signature's requirement (`cdhash`) is **not** satisfied by the next version; a self-signed certificate's requirement **is**.
- **Not verified:** the real upload path (`gh release create` with four assets); signing with the Keychain key through `release.sh`; the live Accessibility behaviour after an update; the Settings panel layout (height 500 is a guess); a real "update available" install. No reviewer subagent was run on any PR in this epic.

## 5. How to test manually

1. Build and open the Debug app (`Scripts/run.sh` from a worktree). Click the menu-bar icon: "Check for Updates…" and "Version 1.0 (build 1)" are there; the check ends in the feed error above.
2. After the first updater release (#75): install it, publish the next patch release, press "Check for Updates…". **Expected:** it offers the new version, downloads, relaunches, and the version line shows the new number.

**Not testable yet because:** no published release carries an `appcast.xml`.

## 6. Decisions

- Version scheme: tag `vX.Y.Z`; `CFBundleShortVersionString` = `X.Y.Z`; `CFBundleVersion` = commit count on `main` (always increases; Sparkle compares it). `MARKETING_VERSION` in the project file stays `1.0` and is overridden at build time.
- One-item appcast written by the script; no `generate_appcast`.
- Sign with a free **self-signed certificate** from the first updater release on (#83), so Accessibility survives updates and users re-grant only once. Apple Developer ID plus notarization is the later upgrade.
- The Sparkle private key is in the maintainer's login Keychain, with a backup the maintainer holds. The public key is `mz2T+2yu4+J62XHpDoH7OqL1K0age+o6HxVENvWPvzc=`. Never regenerate it after users have the updater.

## 7. Blockers / open questions

- #83 needs the maintainer to create the certificate in Keychain Access (Certificate Assistant, name `Text Assist Release`, Self Signed Root, Code Signing, about 10 years) and back it up.
- #75 publishes real releases and needs the Keychain key (macOS will ask once to allow `sign_update`).
- The first updater release must tell `0.1.x` users to install it by hand once (`v0.1.1` has no updater). `release.sh` notes do not say this yet; edit the draft release notes, or add the sentence in #75.
- Not reviewed by this session: other epics #82 (keyboard navigation in the style picker) and #89 (Refine as Prompt) and their tasks. Check them against `sequentialFiles` before running tasks in parallel.

## 8. Known limitations

- Draft releases are not served by `releases/latest/download`, so the feed cannot be tested from a draft.
- Until #83 lands, releases are ad-hoc signed and the Accessibility permission is expected to reset after each update.
- Existing unrelated work is described in §11.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-69-epic-in-app-updates-and-versioned-releases` (this docs change; merge its PR and remove the worktree).
- **Next action:** do **#83** — start it with `Scripts/agent/pickup.sh 83 --start`. The maintainer first creates the certificate (steps in §7); then the agent adds `RELEASE_SIGN_IDENTITY` to `Scripts/release.sh`, the designated-requirement guard, and the docs, following the issue body.
- **Then #75** — from the main checkout on `main`, with the certificate and the Keychain key: `Scripts/release.sh --bump minor --draft` (gives `0.2.0`), inspect the four assets and edit the notes, publish, install it, then publish `--bump patch`, and update from inside the app. Record the Gatekeeper, relaunch and Accessibility results in `Docs/releasing.md`.
- **Files in play:** `Scripts/release.sh`, `Docs/releasing.md`
- **Watch out for:** the release script refuses worktrees; test with a temporary copy that has the two guards removed (workflow §11). The Debug app shares bundle id, preferences and hotkey with an installed copy.
- **Do not redo:** key generation; the Sparkle integration; the appcast code.

## 10. Review

- Reviewer verdict: not run (docs and tooling change).
- Findings: none open.

## 11. Fresh-session briefing

**Start here:** run `Scripts/agent/pickup.sh` (no argument) for the ready list, `Docs/status/OVERVIEW.md` for the big picture, then this file. GitHub MCP is not connected in these sessions; use `gh`.

**Open work created in the 2026-10-30 session (all fully described in the issue bodies, no code written):**

| Epic | Tasks | State |
|:--|:--|:--|
| #52 Ollama prompt repetition on style change | #49 sampling options (ready), #50 cancel the old stream (ready), #51 generation guard (blocked by #50; same file as #50) | Findings to keep: Ollama's documented defaults are already `repeat_penalty` 1.1 / `top_p` 0.9, so #49 starts at 1.15 and is tuned on `phi4-mini`; a request `stop` list replaces the model's own, so it stays empty. #50 must first measure whether the old request really stays open. |
| #68 Esc dismisses every window | #65 `KeyablePanel.cancelOperation` (ready), #66 menu-bar window (ready), #67 text-input focus (blocked by #65) | Cause: Esc is wired only by hidden `.cancelAction` buttons in the picker and custom prompt; `KeyablePanel` has no handler. |
| #69 this epic | see §2 | |

**Environment facts**
- Sparkle tools: `~/sparkle-tools/bin/{generate_keys,sign_update}` (Sparkle 2.10.1). `generate_keys -p` prints the public key; `-x` exports and `-f` imports the private key.
- Testing without the real key: `openssl genpkey -algorithm ed25519 -outform DER | tail -c 32 | base64 > key` and run the script with `SPARKLE_ED_KEY_FILE=key`.
- A self-signed identity for tests: OpenSSL 4 writes PKCS12 files macOS cannot import; use `-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1`, and use a throwaway keychain, not the login keychain.
- Compare signing requirements with `codesign -dr - <app>` and `codesign -v --test-requirement="=<requirement>" <app>`.
- zsh does not word-split `$var`; the safety hook blocks `rm -rf` on a variable path (use fresh directories instead).
- The update-feed error is expected until a release carries `appcast.xml`.

**Habits that worked:** `pickup.sh <n>` then `worktree.sh <n>` and `issue-state.sh <n> in-progress`; one worktree and one PR per task; `handoff.sh <n> review` writes the handoff comment and syncs labels; the maintainer merges (or asks the agent to squash-merge); afterwards update the main checkout, `worktree.sh <n> --remove`, `issue-state.sh <n> done`, and set unblocked dependents to `ready`.
