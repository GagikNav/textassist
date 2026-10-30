# Handoff — issue #103 — Release notes: list what changed since the previous release

| | |
|:--|:--|
| Issue | #103 |
| Epic | #69 |
| Status | review |
| Branch | `issue-103-release-notes-list-what-changed-since-the-previous-release` |
| Worktree | `build/worktrees/issue-103-release-notes-list-what-changed-since-the-previous-release` |

## 1. What this task is

`Scripts/release.sh` wrote fixed release notes. They now include a "What's new" list of first-parent commit subjects (squash-merged PR titles) since the previous `v*` tag.

## 2. Plan

- [x] Add `previous_tag_below` and `whats_new_section` to the script.
- [x] Fetch tags for explicit versions too (remote-only tags).
- [x] Insert the section after the intro line; keep Install, Updates, SHA-256.
- [x] Document in `Docs/releasing.md`.

## 3. What changed

| File | Change |
|:--|:--|
| `Scripts/release.sh` | Previous-tag lookup, What's new block, tag fetch for explicit versions. |
| `Docs/releasing.md` | Describes where the list comes from. |

## 4. Verification

- **Build check:** not run; shell script only, no Swift change.
- `bash -n Scripts/release.sh` passes.
- Dry run with a temporary copy (guards removed, build skipped, stopped before `gh release create`; deleted afterwards) under LC_ALL=C and en_US.UTF-8: list correct; fallbacks correct (no previous tag; no new commits).
  - [x] bash -n passes
  - [x] dry run shows the list
  - [x] docs mention the source

## 5. How to test manually

1. From the main checkout on `main` after merge, run `Scripts/release.sh --bump patch --skip-upload`... the notes file is only written after the skip-upload exit, so use a temporary copy that prints `$NOTES_FILE` before `gh release create` (workflow §11), or run `Scripts/release.sh --bump patch --draft` and read the draft release.
2. **Expected:** a `### What's new` bullet list of commit subjects since the last tag, before `### Install`.

## 6. Decisions

- Subjects kept verbatim, no noise filter (optional in the issue).
- `--skip-upload` exits before notes are written, so the notes are only visible in a draft or a test copy.

## 7. Blockers / open questions

- None.

## 8. Known limitations

- Notes are not written under `--skip-upload`.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-103-release-notes-list-what-changed-since-the-previous-release` (branch `issue-103-release-notes-list-what-changed-since-the-previous-release`)
- **Next action:** maintainer reviews and merges the PR.
- **Files in play:** `Scripts/release.sh`, `Docs/releasing.md`
- **Do not redo:** the dry run and review.

## 10. Review

- Reviewer verdict: approve
- Findings: no blocking. Non-blocking: subjects used verbatim (@mentions would notify; documented); git log errors hidden.
