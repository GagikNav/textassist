# Handoff — issue #21 T4.1 — ChatViewModel

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #21 (T4.1) |
| Epic | #4 |
| Milestone | M3 - Chat |
| Status | done |
| Branch | `issue-21-chatviewmodel` |
| Worktree | `build/worktrees/issue-21-chatviewmodel` |
| Base commit | `559a8aa` |
| Last commit | `96ae2ff` (implementation) |
| Updated | 2026-10-04 |

## 1. What this task is

Add the view model that powers the v2 Chat surface: multi-turn conversation about a
pinned selection, with its own streaming loop (the view model owns streaming so the
orchestrator stays small). One file, `UI/Chat/ChatViewModel.swift`, with the full code
specified in PRD-v2 §7 (T4.1).

## 2. Plan

- [x] Create `TextAssist/UI/Chat/ChatViewModel.swift` with the PRD-provided code
      (`ChatMessage` + `@MainActor ChatViewModel`).
- [x] Build check in the worktree.
- [x] Independent review (verdict: APPROVE).
- [x] Commit implementation; write this handoff; mirror to the issue; sync labels.
- [ ] Open the PR and merge (squash), then remove the worktree.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/Chat/ChatViewModel.swift` | New. `ChatMessage` model + `ChatViewModel` (`@MainActor`, `ObservableObject`) that owns streaming: `sendDraft`/`send`/`regenerateLast`/`stop`/`close`, system prompt pinning `<selected_text>`, last-20-message history, starter prompts, clean cancellation, word count for the pinned context. |

No `project.pbxproj` changes (file-system-synchronized group picked the new file up).

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`, zero errors/warnings).
- **"Done when" checklist** (from the issue):
  - [x] builds.

## 5. How to test manually

> T4.1 is a compile-only task — its `Done when` is literally "builds." There is no UI
> surface to interact with yet: the chat popup and its preview arrive in T4.2
> (`ChatPopupView`) and the orchestrator wiring in T4.4.

1. Open `TextAssist.xcodeproj` and build (⌘B), or run the build command above.
2. **Expected:** build succeeds with no errors.

**Edge cases to try:** n/a · **Not testable yet because:** the view model has no view or
wiring until T4.2/T4.4; the interactive chat manual test belongs to those tasks.

## 6. Decisions

- View model owns streaming (not the orchestrator) — per PRD T4.1, to keep
  `SummarizationOrchestrator` small. (Rejected: routing streams through the
  orchestrator like the summary popup.)
- `ChatMessage` is a module-level type distinct from `OllamaProvider.ChatMessage`
  (nested, Encodable) — no rename, no collision (build confirms).

## 7. Blockers / open questions

- None.

## 8. Known limitations

- No view/wiring yet — that is T4.2 (view) and T4.4 (orchestrator), both tracked in
  their own issues.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-21-chatviewmodel` (branch `issue-21-chatviewmodel`)
- **Next action:** push the branch and open the PR (body from `.agents/templates/pr-body.md`, references "Closes #21"); squash-merge, then `Scripts/agent/worktree.sh 21 --remove`.
- **Files in play:** `TextAssist/UI/Chat/ChatViewModel.swift`, `Docs/handoffs/issue-21-chatviewmodel.md`.
- **Watch out for:** branch is based on `559a8aa`; `main` has since advanced — if the PR
  reports "out of date", merge `origin/main` into the branch before merging.
- **Do not redo:** the `ChatViewModel` implementation (already committed and reviewed
  APPROVE); the build check (passes).

## 10. Review

- Reviewer verdict: approve
- Findings: none blocking. Non-blocking: `canSend`/`wordCount` lack `///` (internal,
  matches PRD verbatim); T4.1 is build-only so no runtime manual step.
