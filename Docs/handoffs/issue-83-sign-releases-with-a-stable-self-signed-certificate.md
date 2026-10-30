# Handoff — issue #83 — Sign releases with a stable self-signed certificate

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #83 (unmapped task) |
| Epic | #69 — In-app updates and versioned releases |
| Milestone | — |
| Status | In Review |
| Branch | `issue-83-sign-releases-with-a-stable-self-signed-certificate` |
| Worktree | `build/worktrees/issue-83-sign-releases-with-a-stable-self-signed-certificate` |
| Base commit | `76b66be` |
| Last commit | `b2ddb8d` |
| Updated | 2026-10-30 |

## 1. What this task is

Make `Scripts/release.sh` sign with one stable certificate (from `RELEASE_SIGN_IDENTITY`) instead of ad-hoc, so the Accessibility permission survives updates. Unset keeps ad-hoc signing for local builds.

## 2. Plan

- [x] Read the identity from `RELEASE_SIGN_IDENTITY`; use it in `xcodebuild archive` and the `codesign` step.
- [x] Print the designated requirement; stop without `certificate leaf` when an identity is set.
- [x] Document create / back up / restore / loss in `Docs/releasing.md`; update `Scripts/README.md`.
- [ ] Maintainer: create the certificate and run the certificate-path checks (§5).

## 3. What changed

| File | Change |
|:--|:--|
| `Scripts/release.sh` | `RELEASE_SIGN_IDENTITY` (default `-`); Keychain check in preflight; identity in archive and codesign; prints the requirement and requires `certificate leaf` for a named identity; release notes text follows the signing mode. |
| `Docs/releasing.md` | "Signing and permissions": certificate creation, `.p12` backup and restore, usage, loss; install text no longer says ad-hoc. |
| `Scripts/README.md` | New "Signing" section; `--no-sign` wording. |

## 4. Verification

- **Build check:** a `--skip-upload` release run (temporary copy of the script without the worktree/branch guards, deleted afterwards) with the identity unset → PASS: archive, ad-hoc sign, requirement printed (`cdhash …`), DMG, ZIP, appcast.
- **"Done when" checklist:**
  - [x] Unset identity still signs ad-hoc as before.
  - [x] An identity missing from the Keychain stops the script in preflight.
  - [x] `Docs/releasing.md` explains creating, backing up and restoring the certificate.
  - [ ] With the identity set, `codesign -dr -` shows `certificate leaf =` and two versions match — **not run**: no code-signing identity exists on this machine, and an agent must not create the certificate or its private key (workflow §11).

## 5. How to test manually

1. Create the certificate as in `Docs/releasing.md` ("Create the certificate") and `export RELEASE_SIGN_IDENTITY="Text Assist Release"`.
2. From the main checkout on `main` after merge: `Scripts/release.sh --bump patch --skip-upload`; then `codesign -dr - "build/release/Export/Text Assist.app"`. Repeat with another version and compare.
3. Install the first build, grant Accessibility, replace it with the second, use ⌥⇧S with Replace in TextEdit.
4. **Expected:** both lines show `identifier "com.gagik.TextAssist" and certificate leaf = H"…"` and are identical; no new permission prompt. With the variable unset the script logs "ad-hoc codesigning" and a `cdhash` requirement.

## 6. Decisions

- The identity is also passed to `xcodebuild archive`, then re-signed with `codesign --force --deep` (final signature is the certificate).
- A named identity is checked in the Keychain in preflight, before the long build.

## 7. Blockers / open questions

- Certificate-path verification needs the maintainer's certificate.

## 8. Known limitations

- Developer ID and notarization stay out of scope.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-83-sign-releases-with-a-stable-self-signed-certificate`
- **Next action:** maintainer creates the certificate and runs §5, then merges the PR.
- **Files in play:** `Scripts/release.sh`, `Docs/releasing.md`, `Scripts/README.md`
- **Watch out for:** the first certificate-signed release must be the one containing the updater (#75).
- **Do not redo:** script and docs changes are finished.

## 10. Review

- Reviewer verdict: not run (inline check only).
- Findings: none.
