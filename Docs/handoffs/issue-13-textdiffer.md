# Handoff — issue #13 T3.2 — TextDiffer

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #13 (T3.2) |
| Epic | #1 (Epic 3 — Write experience in the result popup) |
| Milestone | M2 - Write + Replace |
| Status | agent:done |
| Branch | `issue-13-textdiffer` |
| Worktree | `build/worktrees/issue-13-textdiffer` |
| Base commit | `f6f2940` |
| Last commit | `f6f2940` |
| Updated | 2026-10-03 |

## 1. What this task is

Add a small, dependency-free word-level diff utility, `TextDiffer`, used later by the
Write flow (T3.4) to show the user what changed between their original text and the
rewritten text: removed words red + struck through, added words green.

## 2. Plan

- [x] Create `TextAssist/Utilities/TextDiffer.swift` with the exact code from PRD-v2 §7
      T3.2 (`DiffKind`, `DiffToken`, `TextDiffer.tokenize/diff/attributed`).
- [x] Run the build check.
- [x] Reviewer subagent review.
- [x] Write handoff, mirror to issue, sync labels/Project.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Utilities/TextDiffer.swift` | New file (code from PRD-v2 §7 T3.2) |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`; `TextDiffer.swift` compiled cleanly).
- **"Done when" checklist** (from the issue):
  - [x] builds
  - [x] manual check `diff(old: "I has a apple", new: "I have an apple")` shows `has`/`a` removed and `have`/`an` added — logic traced and verified by the reviewer (removed offsets {2,4} → `has`,`a`; inserted offsets {2,4} → `have`,`an`); the visual Xcode-preview render is a human step (see §5).

## 5. How to test manually

1. Open `TextAssist.xcodeproj` in Xcode and build (⌘B) — or run the CLI build check.
2. In a Swift file or Xcode preview, call
   `TextDiffer.diff(old: "I has a apple", new: "I have an apple")`.
3. Inspect the returned `[DiffToken]`:
   - `has` and `a` are `.removed`
   - `have` and `an` are `.added`
   - `I` and `apple` are `.same`
4. **Expected:** removed tokens render red + strikethrough, added tokens green, via
   `TextDiffer.attributed(_:)`.

**Edge cases to try:** leading/trailing whitespace, double spaces, punctuation attached
to words. **Not testable yet because:** no UI consumes `TextDiffer` until T3.4.

## 6. Decisions

- Use the PRD-provided `CollectionDifference`-based implementation verbatim — it is the
  approved design; no need to invent a new diff algorithm.
- Kept the code verbatim (no `nonisolated` on `TextDiffer`, no added `///` on `DiffKind`/
  `DiffToken`) — the PRD says "full code provided there", and the file is stateless with
  no cross-actor hops. Rejected: adding `nonisolated` or extra doc comments (defensible,
  but a deviation from the frozen spec; can be added later if a non-main caller needs it).

## 7. Blockers / open questions

- None.

## 8. Known limitations

- Token diff is positional on the word/whitespace token stream; it does not do
  semantic matching. This matches the PRD's stated scope.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-13-textdiffer` (branch `issue-13-textdiffer`)
- **Next action:** open the PR for `issue-13-textdiffer` (body from `.agents/templates/pr-body.md`); once merged, flip #13 to `agent:done`.
- **Files in play:** `TextAssist/Utilities/TextDiffer.swift` (new); `Docs/handoffs/issue-13-textdiffer.md`.
- **Watch out for:** T3.4 (#17) depends on `TextDiffer` — do not rename `TextDiffer`,
  `DiffToken`, or the `diff`/`attributed`/`tokenize` signatures. Keep the code identical
  to PRD-v2 §7 T3.2; if `foregroundColor` / `strikethroughStyle` ever become ambiguous,
  fall back to SwiftUI `Text` concatenation per PRD.
- **Do not redo:** the file is implemented, build-verified, and reviewer-approved.

## 10. Review

- Reviewer verdict: **approve** — no blocking findings.
- Findings: non-blocking only — (a) `DiffKind`/`DiffToken` lack `///` doc comments and
  the enum is not `nonisolated` (both inherited from the PRD verbatim); (b) handoff §4/§9
  were still draft-state at review time (now filled).
