# Handoff — issue #19 T4.4 — Orchestrator wiring for Chat

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #19 (T4.4) |
| Epic | #4 (Epic 4 — Chat) |
| Milestone | M3 - Chat |
| Status | agent:done |
| Branch | `issue-19-orchestrator-wiring-for-chat` |
| Worktree | `build/worktrees/issue-19-orchestrator-wiring-for-chat` |
| Base commit | `65a7526f1c5b6f268a90108f317e0b8f574f3161` |
| Last commit | `c6562ea` |
| Updated | 2026-10-05 |

## 1. What this task is

T4.4 connects the already-built Chat UI to the orchestrator. Before this, selecting
the Chat style in the picker would fall through to the summary popup. Now the picker
routes the `.chat` category to a `ChatPopup`, the orchestrator owns exactly one chat
popup and tears it down (stopping any stream) before opening a summary or custom-prompt
popup, and the result popup's "Continue in Chat" (`⌘T`) seeds a chat with the summary
as the first assistant turn.

## 2. Plan

- [x] Add `private var chatPopup: ChatPopup?` to the orchestrator.
- [x] Route `.chat` category in the picker callback to `showChat(for:seed:)`.
- [x] Add `showChat(for:seed:)` and `closeChat()` helpers (stop stream, close, one popup at a time).
- [x] Wire `viewModel.onContinueInChat` in `configureActions` (seed + close result popup + open chat).
- [x] Call `closeChat()` first in `showSummaryPopup` and `showCustomPromptPanel`.
- [x] Build check.
- [x] Reviewer pass.
- [ ] Open PR, merge, remove worktree (SYNC phase).

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Core/SummarizationOrchestrator.swift` | Add `chatPopup`; route `.chat` to `showChat`; add `showChat`/`closeChat`; wire `onContinueInChat`; close chat in summary/custom-prompt paths |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`, no errors/warnings).
- **"Done when" checklist** (from the issue):
  - [x] `⌥⇧S → a` opens Chat with selection pinned (implemented; needs running-app check below).
  - [x] Starter chip streams an answer (implemented via T4.2 `ChatPopupView`; now reachable from the picker).
  - [x] Stop halts mid-stream (implemented via `ChatViewModel.stop()`; wired through `closeChat`/`showChat`).
  - [x] Follow-ups reference the text (implemented via `ChatViewModel` system prompt; unchanged).
  - [x] `⌘W` cancels streaming (implemented via `ChatPopupView` close → `viewModel.close()` → `closeChat()`).
  - [x] From a Fix Grammar result, `⌘T` opens chat seeded with the result (implemented via `onContinueInChat`).

## 5. How to test manually

> Copy-pasteable steps a human can follow in the running app. Implemented; the
> checklist marks them done-when-verified-by-hand per PRD §7.

1. Build & run the app from this worktree (open `TextAssist.xcodeproj`, Run). In **TextEdit**, type a few sentences, select them, press `⌥⇧S`, then press `a` (Chat with Selection).
   - **Expected:** A floating "Chat" panel opens near the cursor with the selection pinned in the context area; the conversation is empty and shows starter chips.
2. Click a starter chip (e.g. "What's the main point?").
   - **Expected:** The chip becomes a user message and the assistant reply streams in token by token.
3. While it is still streaming, click **Stop**.
   - **Expected:** Streaming halts immediately; the partial text so far stays in the assistant bubble.
4. Type a follow-up ("Can you give an example?") and send.
   - **Expected:** The reply references the pinned selection (it is the primary source), not some unrelated topic.
5. Press **⌘W** (or click the header ✕) while a reply is streaming.
   - **Expected:** The panel closes and the in-flight stream is cancelled (no further tokens appear, no crash).
6. Select text again, `⌥⇧S`, choose **g** (Fix Grammar), let it finish, then press **⌘T** (Continue in Chat).
   - **Expected:** The result popup closes and a Chat panel opens whose first exchange is a user turn "Apply: Fix Grammar" and an assistant turn containing the grammar-fixed result.

**Edge cases to try:** Opening Chat (`a`) while a previous Chat is open should replace it, never show two chats; choosing a Transform/Write style while a Chat is open should close the chat first. **Not testable yet because:** n/a.

## 6. Decisions

- Used the PRD §7 T4.4 code verbatim (picker routing, `showChat`/`closeChat`, `onContinueInChat` seed). (Rejected: none — the PRD is explicit.)
- Wired both `viewModel.onClose` and `popup.onClose` to `closeChat()` so the close button/`⌘W` path and the window-close path both release the popup. (Rejected: wiring only one, which would leak the popup on the other close path.)
- `showStylePicker` intentionally does **not** call `closeChat()` — the PRD only requires the summary/custom-prompt paths to close chat, and the picker is transient. (Rejected: closing chat on picker open, which deviates from the PRD.)

## 7. Blockers / open questions

- None.

## 8. Known limitations

- Pressing `⌘T` mid-stream seeds whatever partial text has arrived so far (PRD-provided behavior; the Done-when only requires the completed-result case).
- This file is in `sequentialTasks` (T3.5, T4.4, T6.1, T6.2) — the next orchestrator edits (T6.1/T6.2) must run one at a time, in order, after T4.4 merges.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-19-orchestrator-wiring-for-chat` (branch `issue-19-orchestrator-wiring-for-chat`)
- **Next action:** Open a PR from the branch (PR body from `.agents/templates/pr-body.md`), run `sync-overview`, and merge; remove the worktree after merge.
- **Files in play:** `TextAssist/Core/SummarizationOrchestrator.swift`
- **Watch out for:** This file is in `sequentialTasks` (T3.5, T4.4, T6.1, T6.2) — T6.1 (`startDirect`) and T6.2 both touch it and are blocked on T4.4; run them sequentially after this merges.
- **Do not redo:** Implementation, build check, and reviewer are all done; only PR/merge/sync remain.

## 10. Review

- Reviewer verdict: **approve** (no blocking findings).
- Findings: Three non-blocking notes — (a) handoff §5 absent at review time (now filled above); (b) `showStylePicker` does not close chat on open (spec-conformant); (c) `⌘T` mid-stream seeds a partial result (PRD-provided code). None block T4.4.
