# Handoff — issue #71 — Generate and document the Sparkle update-signing key (maintainer action)

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #71 (unmapped task) |
| Epic | #69 — In-app updates and versioned releases |
| Milestone | — |
| Status | In Review |
| Branch | `issue-71-generate-and-document-the-sparkle-update-signing-key-maintai` |
| Worktree | `build/worktrees/issue-71-generate-and-document-the-sparkle-update-signing-key-maintai` |
| Base commit | `f05ed66` |
| Last commit | `63c7515` |
| Updated | 2026-10-30 |

## 1. What this task is

Create the Ed25519 key pair that signs Sparkle updates and document where it lives. The
maintainer ran Sparkle 2.10.1 `generate_keys` on their Mac; the agent only wrote the
documentation and never saw the private key.

## 2. Plan

- [x] Maintainer downloads Sparkle tools, runs `generate_keys` (private key stored in their login Keychain).
- [x] Public key posted on the issue; `generate_keys` re-run shows the same key ("pre-existing signing key").
- [x] Maintainer exported the private key, saved it outside the repository, and deleted the local file; confirmed in chat.
- [x] "Update signing key" section written in `Docs/releasing.md`.
- [ ] SYNC — PR, merge, remove worktree.

## 3. What changed

| File | Change |
|:--|:--|
| `Docs/releasing.md` | Filled the "Update signing key" section: public key, where the private key lives, check / back up / restore commands, loss warning, rules. |

## 4. Verification

- **Build check:** n/a, documentation only.
- **"Done when" checklist** (from the issue):
  - [x] Public key is in `Docs/releasing.md` and in a comment on the issue.
  - [x] Maintainer confirmed in chat that the backup exists outside the repository (the agent cannot verify where it is stored).
  - [x] No key material in the repository: only the public key is present; the private export file was deleted and never read by the agent.

## 5. How to test manually

1. Run `~/sparkle-tools/bin/generate_keys -p`.
2. **Expected:** it prints `mz2T+2yu4+J62XHpDoH7OqL1K0age+o6HxVENvWPvzc=`, the same as the table in `Docs/releasing.md`, and creates no new key.

**Not testable yet because:** the key is first used in #72 (Info.plist) and #74 (signing).

## 6. Decisions

- The public key lives in the doc and, from #72, in `Info.plist`. It is not secret.
- Documented `generate_keys -p` as the check command because it never creates a key.

## 7. Blockers / open questions

- None. #72 (Sparkle integration) is unblocked once this merges; #74 also needs #70, which is merged.

## 8. Known limitations

- The backup location is not recorded anywhere (deliberately); only the maintainer knows it.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-71-generate-and-document-the-sparkle-update-signing-key-maintai`
- **Next action:** merge the PR, remove the worktree (`Scripts/agent/worktree.sh 71 --remove`), then set #72 and #74 to ready.
- **Files in play:** `Docs/releasing.md`
- **Watch out for:** #72 needs the maintainer to add the Sparkle package in Xcode (project file exception).
- **Do not redo:** key generation; never regenerate, it would orphan existing installs.

## 10. Review

- Reviewer verdict: not run (documentation only).
- Findings: none.
