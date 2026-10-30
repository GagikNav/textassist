# Handoff — issue #70 — Versioning policy, release guide and a reliable release version

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #70 (unmapped task) |
| Epic | #69 — In-app updates and versioned releases |
| Milestone | — |
| Status | In Review |
| Branch | `issue-70-versioning-policy-release-guide-and-a-reliable-release-versi` |
| Worktree | `build/worktrees/issue-70-versioning-policy-release-guide-and-a-reliable-release-versi` |
| Base commit | `e9c9435` |
| Last commit | `b588431` |
| Updated | 2026-10-30 |

## 1. What this task is

`Scripts/release.sh` defaulted its version to `MARKETING_VERSION` in the project file, which is
stale (`1.0` while the tags are `v0.1.x`). This task makes the version explicit and reliable
(`X.Y.Z` or `--bump patch|minor|major` from the highest `v*` tag), checks the built app
reports it, and writes the versioning scheme and release steps down in `Docs/releasing.md`.
First task of epic #69 (in-app updates).

## 2. Plan

- [x] INTAKE — `pickup.sh 70` reported "missing an epic: label" (see §7); started anyway on the user's instruction.
- [x] IMPLEMENT — `release.sh`: `--bump`, tag-based version, version/build check after export.
- [x] DOCS — `Docs/releasing.md`; links from `README.md` and `Scripts/README.md`.
- [x] VERIFY — error paths, bump arithmetic and a full local build (see §4).
- [ ] REVIEW — read-only reviewer subagent not run; inline self-review only (see §10).
- [ ] SYNC — open the PR, merge, remove the worktree.

## 3. What changed

| File | Change |
|:--|:--|
| `Scripts/release.sh` | New `--bump patch\|minor\|major` (fetches tags from origin, bumps the highest `v*` tag). Exactly one of `<version>` or `--bump` is required; no more `MARKETING_VERSION` fallback. Versions must be `X.Y.Z` (was `X.Y[.Z]`). New step 3b reads `CFBundleShortVersionString` and `CFBundleVersion` from the exported app and stops on a mismatch. `--help` now prints the whole header. |
| `Docs/releasing.md` | New: versioning scheme, how to cut, verify and withdraw a release, how users install today, placeholder sections for #71, #74, #76, #77. |
| `README.md`, `Scripts/README.md` | Updated usage, `--bump` option, links to the guide. |

## 4. Verification

- **Build check:** no Swift files changed. The full release archive (`xcodebuild archive`, Release, universal) inside the script succeeded, which exercises the app build.
- **"Done when" checklist** (from the issue):
  - [x] `release.sh --bump patch --skip-upload` built `Text-Assist-0.1.2.dmg` from tag `v0.1.1`; the app inside reports `0.1.2` and build `120` (= `git rev-list --count HEAD`).
  - [x] No version and no `--bump` stops with "no version given…"; `0.2.0 --bump patch`, `--bump huge`, `--bump` (no level) and `1.2` are rejected with clear messages.
  - [x] Bump arithmetic from `0.1.1`: patch `0.1.2`, minor `0.2.0`, major `1.0.0`; `9.9.9` patch `9.9.10`.
  - [x] `Docs/releasing.md` exists, covers the listed items, and both READMEs link to it.
- **How it was run:** the script refuses worktrees and non-`main` branches, so the build used a temporary copy with those two guards removed (deleted afterwards, never committed). The guards themselves were not changed. The publish path (`gh release create`) was not run.

## 5. How to test manually

1. From the **main checkout** on `main` after merge: `brew install create-dmg` if needed, then `Scripts/release.sh --bump patch --skip-upload`.
2. Mount `build/release/Text-Assist-<version>.dmg` and run `defaults read "/Volumes/Text Assist/Text Assist.app/Contents/Info" CFBundleShortVersionString CFBundleVersion`.
3. Run `Scripts/release.sh --skip-upload` (no version).
4. **Expected:** step 2 prints the next patch version after the latest tag and the commit count; step 3 stops with "no version given. Pass X.Y.Z or --bump …".

**Edge cases to try:** `--bump minor`, an explicit `0.3.0`, a version whose tag exists (must stop) · **Not testable yet:** the upload path was not exercised; cut the next real release with `--draft` first.

## 6. Decisions

- Tag and script are the source of truth; `MARKETING_VERSION` is not edited (project file is off limits) — Debug builds keep showing `1.0`.
- `--bump` runs `git fetch --tags origin` because `gh release create` only creates the tag on the remote; without the fetch a second bump would reuse the same number. (Rejected: reading versions from the GitHub API — an extra network dependency for no gain.)
- Version format tightened to `X.Y.Z` to match `CFBundleShortVersionString` in the guide.
- Withdraw instructions use `gh release edit --prerelease` (keeps files, moves `latest` back) or `gh release delete --cleanup-tag`.

## 7. Blockers / open questions

- `pickup.sh` fails Definition of Ready for every task filed after v2 because it requires an `epic:` label, and only `epic:0`–`epic:6` exist. Tickets #49–#52, #65–#68 and #69–#77 are affected. Needs a decision: add new epic labels or relax the check.

## 8. Known limitations

- The guide's sections for the signing key (#71), appcast (#74), signing and permissions (#77) and Homebrew (#76) are placeholders filled by those tasks.
- `build-dmg.sh` was not changed.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-70-versioning-policy-release-guide-and-a-reliable-release-versi` (branch `issue-70-versioning-policy-release-guide-and-a-reliable-release-versi`)
- **Next action:** push the branch and open a PR (body from `.agents/templates/pr-body.md`); after merge, run `Scripts/agent/worktree.sh 70 --remove`. Then #71 (maintainer creates the Sparkle key) unblocks.
- **Files in play:** `Scripts/release.sh`, `Docs/releasing.md`
- **Watch out for:** the release script cannot be run from this worktree as-is.
- **Do not redo:** the local build and error-path tests above.

## 10. Review

- Reviewer verdict: not run (no read-only reviewer subagent was spawned). Inline self-review checked the argument shifting for `--bump`, `set -e` behaviour of the tag fetch, and the `--help` range.
- Findings: none open.
