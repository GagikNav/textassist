# Handoff — issue #7 T1.3 — OutputCleaner for rewrite results

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #7 (T1.3) |
| Epic | #2 |
| Milestone | M1 - Foundation |
| Status | agent:done |
| Branch | `issue-7-outputcleaner` |
| Base commit | `43292ad` |
| Last commit | `843859a` |
| Updated | 2026-10-03 |

## 1. What this task is

`OutputCleaner` is a small utility that removes common LLM wrapper noise from
rewritten-text results — wrapping code fences, single-line preambles like
"Here is the revised text:", and wrapping quotes. It normalises the raw streamed
string so the Write flow can show clean output. The task creates one new file,
`TextAssist/Utilities/OutputCleaner.swift`, with a single pure static helper
`cleanRewrite(_:)`. It is not wired into any caller here; T3.5 (#16) calls it once
after streaming finishes.

## 2. Plan

- [x] Create `TextAssist/Utilities/OutputCleaner.swift` with the verbatim PRD §7
      T1.3 code (`enum OutputCleaner`, `static func cleanRewrite(_:) -> String`).
- [x] Run the build check from `.agents/config.json`.
- [x] Independent review against the issue's Done-when, AGENTS.md constraints, scope.
- [x] Write/commit the handoff, mirror to the issue, sync labels + open the PR.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Utilities/OutputCleaner.swift` | New: `OutputCleaner.cleanRewrite(_:)` — strips wrapping code fences, single-line preambles, wrapping quotes. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`; new file compiled — `OutputCleaner.o` emitted).
- **"Done when" checklist** (from the issue):
  - [x] Builds (exercised in T3.5 — runtime exercise is T3.5's job and is not verifiable here).

## 5. Decisions

- Used the PRD §7 T1.3 code **verbatim** (no `nonisolated`) — T1.3's caller (T3.5 `streamSummary`) is `@MainActor`, and this matches the existing `Utilities/` precedent in `StreamParsers.swift`. Rejected: adding `nonisolated` (defensible but a deviation from the frozen spec; can be added later if a non-main caller needs it).

## 6. Blockers / open questions

- None.
- Note: `Scripts/agent/issue-state.sh` reported the Project status sync was skipped — `gh` token lacks the `project` scope. Label changes still applied; run `gh auth refresh -s project` to restore Project sync.

## 7. Known limitations

- Not exercised at runtime by this task; real exercise happens in T3.5 (#16), which calls `OutputCleaner.cleanRewrite(...)` once after streaming finishes.
- Inherent to the PRD code (not introduced here): a single-line fence like `` ```code``` `` is not unwrapped (the `lines.count >= 2` guard), and a 2-character quoted body (`""`) is left wrapped (`count > 2` guard). Neither blocks T1.3.

## 8. Resume here

- **Next action:** Open the PR for `issue-7-outputcleaner` (body from `.agents/templates/pr-body.md`) and, once merged, flip #7 to `agent:done`.
- **Files in play:** `TextAssist/Utilities/OutputCleaner.swift`; `Docs/handoffs/issue-7-outputcleaner.md`.
- **Watch out for:** T3.5 (#16) depends on the exact signature `cleanRewrite(_ raw: String) -> String`; do not rename or change it. Keep the no-`nonisolated` decision unless a non-main caller appears.
- **Do not redo:** the file is implemented, build-verified, and reviewer-approved.

## 9. Review

- Reviewer verdict: **approve** — no blocking findings.
- Findings: non-blocking only — (a) single-line fence not cleaned, (b) 2-char quoted body `count > 2` guard, (c) `enum` is `@MainActor` under default isolation (all match the PRD verbatim); (d) handoff sections were still `_pending_` at review time (now filled).
