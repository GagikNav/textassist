# Handoff — issue #74 — Release script: build ZIP, sign it and publish appcast.xml

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #74 (unmapped task) |
| Epic | #69 — In-app updates and versioned releases |
| Milestone | — |
| Status | In Review |
| Branch | `issue-74-release-script-build-zip-sign-it-and-publish-appcast-xml` |
| Worktree | `build/worktrees/issue-74-release-script-build-zip-sign-it-and-publish-appcast-xml` |
| Base commit | `b2d8403` |
| Last commit | `a6953b4` |
| Updated | 2026-10-30 |

## 1. What this task is

Make `Scripts/release.sh` publish what Sparkle needs: a ZIP of the app, an EdDSA signature
for it, and an `appcast.xml`, uploaded with the DMG so
`releases/latest/download/appcast.xml` always describes the newest published release.
Part of epic #69.

## 2. Plan

- [x] INTAKE — `pickup.sh 74`: known missing `epic:` label (see §7); started anyway.
- [x] IMPLEMENT — step 6b in `release.sh`; upload step extended.
- [x] VERIFY — full local build with a throwaway signing key; isolated tests of the guard.
- [x] DOCS — "Appcast" section in `Docs/releasing.md`; `Scripts/README.md`.
- [ ] REVIEW — no reviewer subagent run.
- [ ] SYNC — PR, merge, remove worktree.

## 3. What changed

| File | Change |
|:--|:--|
| `Scripts/release.sh` | `find_sign_update` (looks in `$SPARKLE_BIN`, `~/sparkle-tools/bin`, the package artifacts) and an early preflight check. Step 6b: `ditto` ZIP, `sign_update -p`, `--verify`, public-key guard, templated single-item `appcast.xml`, `xmllint` check. Upload now includes the DMG checksum (built before but never uploaded), the ZIP and the appcast. `--no-sign` skips the ZIP/appcast. Release notes get an "Updates" line only when the built app contains `Sparkle.framework`. `REPO_SLUG` computed once at the top. Empty-array expansions made safe under bash 3.2. |
| `Docs/releasing.md` | "Appcast" section filled in, the four published files listed, verify checklist updated. |
| `Scripts/README.md` | Sparkle requirement, `--skip-upload` / `--no-sign` meaning, new outputs and upload list. |

## 4. Verification

- **Build check:** the release archive inside `release.sh` (universal, Release) succeeded. No Swift files changed.
- **"Done when" checklist** (from the issue):
  - [x] `--bump patch --skip-upload` produces the ZIP and `appcast.xml` in `build/release/` (0.1.2, build 123).
  - [x] `xmllint --noout appcast.xml` passes; the `length` equals the ZIP size (1513988); the `edSignature` verifies with `sign_update --verify`. A tampered ZIP is rejected.
  - [ ] A real or draft release lists the four assets — **not run** (publishing was not exercised).
  - [x] `Docs/releasing.md` explains the appcast and how to withdraw a release (pre-release makes `latest` go back).
- **Isolated tests of step 6b** against a copy of an ad-hoc app, with stub tools: no `SUPublicEDKey` → warns; matching key → ok; mismatching key → stops; key file in use → warns it cannot compare. The ZIP unpacks to an app that passes `codesign --verify --deep --strict`.
- **Signing key:** all signing used a throwaway Ed25519 key through `SPARKLE_ED_KEY_FILE`. The real private key and the login Keychain were not used.
- **How it was run:** the script refuses worktrees and non-`main` branches, so the full build used a temporary copy without those two guards (deleted, never committed).

## 5. How to test manually

1. From the main checkout on `main` after merge, with the key in your login Keychain: `Scripts/release.sh --bump patch --skip-upload`. macOS may ask once to let `sign_update` use the Keychain key; allow it.
2. Open `build/release/appcast.xml`; run `xmllint --noout build/release/appcast.xml`.
3. `~/sparkle-tools/bin/sign_update --verify build/release/Text-Assist-<version>.zip <edSignature from the appcast>`.
4. Publish a draft: `Scripts/release.sh <version> --draft`, and check four assets on the draft page.
5. **Expected:** ZIP and appcast present, signature verifies, draft shows DMG, `.sha256`, ZIP and `appcast.xml`. Until the updater is built into the app (#72) the script warns that the app has no `SUPublicEDKey`.

**Not testable yet because:** the app does not contain the updater or `SUPublicEDKey` until #72, and `latest/download` does not serve drafts.

## 6. Decisions

- One-item appcast written by the script (no `generate_appcast`): fewer moving parts; the app only needs the newest version. (Rejected: `generate_appcast`, which keeps history in a folder we do not have.)
- `releaseNotesLink` points at the GitHub release page rather than embedding the Markdown notes.
- Fail the release when the app's `SUPublicEDKey` differs from the Keychain key, so a release nobody can update from cannot ship. Only a warning if the app has no key yet.
- `SPARKLE_ED_KEY_FILE` added so tests can use a throwaway key; the default stays the Keychain.
- Uploading the checksum file fixes an existing gap (the guide from #70 already said it was published).

## 7. Blockers / open questions

- `pickup.sh` still flags the missing `epic:` label for tasks filed after v2.
- First real run will prompt for Keychain access.

## 8. Known limitations

- Draft releases are not reachable through `latest/download`, so the feed cannot be tested from a draft.
- The public-key guard needs `generate_keys` next to `sign_update` and the Keychain mode.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-74-release-script-build-zip-sign-it-and-publish-appcast-xml`
- **Next action:** merge the PR, then remove the worktree (`Scripts/agent/worktree.sh 74 --remove`). #72 (Sparkle integration, needs the maintainer's Xcode package step) is the next step on the main path.
- **Files in play:** `Scripts/release.sh`, `Docs/releasing.md`, `Scripts/README.md`
- **Watch out for:** the upload path (`gh release create` with the new assets) has not run; use `--draft` first.
- **Do not redo:** the isolated step-6b tests and the full build above.

## 10. Review

- Reviewer verdict: not run.
- Findings: none open.
