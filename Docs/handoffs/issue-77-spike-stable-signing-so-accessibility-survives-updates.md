# Handoff — issue #77 — Spike: stable signing so Accessibility survives updates

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #77 (unmapped task) |
| Epic | #69 — In-app updates and versioned releases |
| Milestone | — |
| Status | In Review |
| Branch | `issue-77-spike-stable-signing-so-accessibility-survives-updates` |
| Worktree | `build/worktrees/issue-77-spike-stable-signing-so-accessibility-survives-updates` |
| Base commit | `8fe83ff` |
| Last commit | `b0826bb` |
| Updated | 2026-10-30 |

## 1. What this task is

Find out whether the Accessibility permission survives an in-place update when releases are
ad-hoc signed, compare signing options, and recommend one. Spike: the output is a written
recommendation in `Docs/releasing.md`, not app code.

## 2. Plan

- [x] INTAKE — `pickup.sh 77` reported the known missing `epic:` label (see §7); started anyway.
- [x] MEASURE — two ad-hoc builds (9.0.1 / 9.0.2), then the same two signed with a throwaway self-signed certificate.
- [x] WRITE — "Signing and permissions" section in `Docs/releasing.md`.
- [x] FOLLOW-UP — created #83 (sign releases with a stable certificate), linked under #69, added to #75's dependencies.
- [ ] REVIEW — no reviewer subagent run; inline check only.
- [ ] SYNC — PR, merge, remove worktree.

## 3. What changed

| File | Change |
|:--|:--|
| `Docs/releasing.md` | Replaced the #77 placeholder with measurements, an options table, the recommendation, optional by-hand confirmation steps and the lost-certificate note. |

Outside the repo: created issue #83 (sub-issue of #69); edited #75 (depends on #83 too) and the #69 task list.

## 4. Verification

- **Build check:** n/a, documentation only. Both measurement builds used `xcodebuild build` (Release, ad-hoc) and succeeded.
- **"Done when" checklist** (from the issue):
  - [x] Measurement result and macOS version (27.0.1) recorded in `Docs/releasing.md`.
  - [x] Three options compared, one recommended, follow-up listed (#83).
- **Measurements** (`codesign -v --test-requirement="=<requirement of v1>" <v2 app>`):
  - ad-hoc v1 req vs v1 (control): yes; vs v2: **no** (requirement is `cdhash`, differs per build).
  - self-signed v1 req vs v1 (control): yes; vs v2: **yes** (`identifier "com.gagik.TextAssist" and certificate leaf = H"…"`).
  - self-signed req vs ad-hoc v2: no (switching costs one re-grant).
- **Not measured:** the live macOS permission behaviour. Granting Accessibility is a system security setting, so it was not changed; the doc gives the optional hand-check.
- The throwaway keychain, certificate and builds lived in the session scratchpad; the keychain was deleted and the login keychain was not touched.

## 5. How to test manually

1. Read "Signing and permissions" in `Docs/releasing.md`.
2. Optional: follow its "How to confirm by hand" steps with two `release.sh --skip-upload` builds.
3. **Expected:** with ad-hoc signing Replace stops working after copying the second build over the first; with the certificate it keeps working.

**Not testable yet because:** the certificate is not used by `release.sh` until #83.

## 6. Decisions

- Recommend a free self-signed certificate now, switched in with the first updater release so users re-grant only once. (Rejected: keep ad-hoc, since every update would break permission; Developer ID, since it costs money and needs a notarization step, to revisit if distribution grows.)

## 7. Blockers / open questions

- `pickup.sh` still flags the missing `epic:` label for tasks filed after v2 (also seen on #70).
- The hand-check on a real install is optional and still unrun.

## 8. Known limitations

- The result rests on macOS comparing the stored code requirement; that was checked with `codesign`, not by observing the Accessibility prompt.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-77-spike-stable-signing-so-accessibility-survives-updates`
- **Next action:** merge the PR, then remove the worktree (`Scripts/agent/worktree.sh 77 --remove`). #83 becomes ready after merge.
- **Files in play:** `Docs/releasing.md`
- **Watch out for:** `openssl` 4 writes PKCS12 files macOS cannot import; use `-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1`.
- **Do not redo:** the measurements above.

## 10. Review

- Reviewer verdict: not run.
- Findings: none open.
