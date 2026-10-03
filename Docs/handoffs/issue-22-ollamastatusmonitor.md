# Handoff — issue #22 T5.1 — OllamaStatusMonitor

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #22 (T5.1) |
| Epic | #5 (Epic 5 — Menu bar status) |
| Milestone | M4 - Menu bar status |
| Status | agent:done |
| Branch | `issue-22-ollamastatusmonitor` |
| Worktree | `build/worktrees/issue-22-ollamastatusmonitor` |
| Base commit | `559a8aa` |
| Last commit | `002e957` |
| Updated | 2026-10-04 |

## 1. What this task is

Add `OllamaStatusMonitor`, a small `ObservableObject` that tracks whether the local
Ollama server is reachable and which models it advertises. It publishes a
`status` (`unknown`/`online`/`offline`) and `availableModels`, refreshed by calling
`provider.listModels()`. T5.2 will wire it into the menu-bar popover to show the
green/red status dot, so for T5.1 the only acceptance criterion is "it builds".

## 2. Plan

- [x] Confirm `LLMProvider.listModels()` exists (it does — `Providers/LLMProvider.swift:9`).
- [x] Create `TextAssist/Core/OllamaStatusMonitor.swift` with the exact code from PRD-v2 §7 T5.1.
- [x] Run the build check.
- [x] Reviewer subagent review.
- [x] Write handoff, mirror to issue, sync labels/Project.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Core/OllamaStatusMonitor.swift` | New file (code from PRD-v2 §7 T5.1, verbatim) |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`; `OllamaStatusMonitor.swift` compiled cleanly).
- **"Done when" checklist** (from the issue):
  - [x] builds (used in T5.2)

## 5. How to test manually

1. Open `TextAssist.xcodeproj` in Xcode and build (⌘B) — or run the CLI build check
   above from the worktree.
2. **Expected:** the build succeeds with no errors; the app still launches.
3. **Not testable yet because:** no UI references `OllamaStatusMonitor` until T5.2
   (issue #23) wires it into `MenuBarStatusView`. For T5.1, "it builds" is the whole
   acceptance criterion.

**Edge cases to try:** n/a — no runtime surface yet. **Not testable yet because:** see step 3.

## 6. Decisions

- Use the PRD-provided code verbatim — the design is frozen; do not redesign.
- Kept the explicit `@MainActor` even though the project default is MainActor — the
  PRD says "full code provided there", and the annotation is harmless and documents
  intent. Rejected: removing it (deviation from the frozen spec for no benefit).

## 7. Blockers / open questions

- None.

## 8. Known limitations

- `OllamaStatusMonitor` is not referenced by any UI yet; an unused type produces no
  runtime effect until T5.2 consumes it. This matches the PRD's stated scope.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-22-ollamastatusmonitor` (branch `issue-22-ollamastatusmonitor`)
- **Next action:** open the PR for `issue-22-ollamastatusmonitor` (body from
  `.agents/templates/pr-body.md`); once merged, flip #22 to `agent:done` and remove the worktree.
- **Files in play:** `TextAssist/Core/OllamaStatusMonitor.swift` (new); `Docs/handoffs/issue-22-ollamastatusmonitor.md`.
- **Watch out for:** T5.2 (#23) depends on `OllamaStatusMonitor` — keep the type name,
  the `Status` enum cases (`unknown`/`online`/`offline`), the `@Published private(set)`
  properties, and the `init(provider:)`/`refresh()` signatures identical to PRD-v2 §7 T5.1.
  Do not add `@unchecked Sendable` conformance unless a build demands it.
- **Do not redo:** the file is implemented, build-verified, and reviewer-approved.

## 10. Review

- Reviewer verdict: **approve** — no blocking findings.
- Findings: non-blocking only — the file was untracked at review time (now committed
  as `002e957`); no manual runtime check exists for T5.1 (by design).
