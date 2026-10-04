# Handoff — issue #20 T4.2 — ChatPopupView

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #20 (T4.2) |
| Epic | #4 |
| Milestone | M3 - Chat |
| Status | review |
| Branch | `issue-20-chatpopupview` |
| Worktree | `build/worktrees/issue-20-chatpopupview` |
| Base commit | `574155e` |
| Last commit | `79282a2` (implementation) |
| Updated | 2026-10-05 |

## 1. What this task is

Add the SwiftUI content of the v2 Chat surface: a header with close (`⌘W`), a
collapsible pinned-context card, a streaming message list (user bubbles right,
assistant Markdown left), starter chips when empty, per-message Copy + Regenerate on
the last assistant message, an error banner, and a plain-Return vertical `TextField`
input bar with a send/stop button. One new file, `UI/Chat/ChatPopupView.swift`, built
exactly to the PRD-v2 §7 (T4.2) layout spec. `ChatViewModel` (T4.1) owns streaming;
this view only renders state and forwards user actions.

## 2. Plan

- [x] Create `TextAssist/UI/Chat/ChatPopupView.swift` per the PRD T4.2 spec.
- [x] Build check in the worktree.
- [x] Independent review (verdict: APPROVE); addressed the non-blocking note by adding
      an empty-state `#Preview` so chips are visible.
- [x] Commit implementation; write this handoff; mirror to the issue; sync labels.
- [ ] Push the branch, open the PR (squash), merge, remove the worktree, flip `agent:done`.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/Chat/ChatPopupView.swift` | New. `ChatPopupView` (`@ObservedObject`): header (bubble icon + "Chat with Selection" + xmark `⌘W` close), `DisclosureGroup` pinned-context card, `ScrollViewReader` message list (starter chips, user/assistant bubbles, Copy/Regenerate, red error banner, auto-scroll to `"bottom"`), input bar (vertical `TextField`, focused on appear, Return sends, send/stop button), and two `#Preview`s (seeded + empty state). |

No `project.pbxproj` changes — the file-system-synchronized group picked the new file up.

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`, zero errors/warnings).
- **"Done when" checklist** (from the issue):
  - [x] builds.
  - [x] preview shows pinned card — `DisclosureGroup` + `Label("Selected text · N words · from …")`.
  - [x] preview shows chips — the empty-state `#Preview` renders `starterChips`.
  - [x] preview shows bubbles — the seeded `#Preview` renders user + assistant messages.
  - [x] preview shows input bar — `TextField(axis: .vertical)` + send/stop button.

## 5. How to test manually

> The Chat surface is not wired into the running app yet: the `ChatPopup` panel and the
> orchestrator wiring land in T4.3/T4.4. The only executable check for this diff today
> is the Xcode **preview**. The end-to-end steps are listed below for those later tasks.

**Executable now — Xcode preview:**

1. Open `TextAssist.xcodeproj` in Xcode and open
   `TextAssist/UI/Chat/ChatPopupView.swift`.
2. Select the **"Empty state"** preview in the canvas.
3. **Expected:** you see the header ("Chat with Selection" + ✕), the pinned-context
   card ("Selected text · N words · from Preview"), four starter chips, and the input
   bar with an up-arrow send button (disabled until you type).
4. Select the **seeded** preview (two messages).
5. **Expected:** a right-aligned accent user bubble, a left-aligned Markdown assistant
   bubble with a Copy (doc.on.doc) button and a Regenerate (arrow.clockwise) button,
   plus the pinned-context card and input bar.

**End-to-end (not testable yet — needs T4.3/T4.4):**

1. Launch the app; in TextEdit type some text, select it, press `⌥⇧S`, and open Chat.
2. **Expected:** the chat panel shows the pinned-context card and starter chips.
3. Type a question and press Return (or tap a chip).
4. **Expected:** your message appears as a right bubble; the assistant reply streams in
   as left-aligned Markdown; the send button becomes a stop button while streaming.

**Edge cases to try:** empty draft keeps send disabled; stop mid-stream keeps the partial
text · **Not testable yet because:** no panel/orchestrator wiring (T4.3/T4.4).

## 6. Decisions

- **`@ObservedObject` (not `@StateObject`)** for `viewModel` — `ChatPopup` (T4.3)
  creates and owns the `ChatViewModel`, so the view must not take ownership. Matches
  the v2 Chat architecture; `SummaryPopupView` uses `@StateObject` because it owns a
  fresh model per popup.
- **Two `#Preview`s** (seeded + empty state) — the spec mandates a seeded preview and
  "Done when" wants chips visible; chips only render when `messages.isEmpty`, so an
  empty-state preview is the only way to show both.
- **Copy/Regenerate as borderless icon buttons** — per the T4.2 spec (`doc.on.doc`,
  `arrow.clockwise`), kept small with `.font(.system(size: 12))` + secondary styling.
- **Error banner without extra padding** — the surrounding `LazyVStack` already applies
  `.padding(16)` + `spacing: 12`, so no duplicate horizontal/top padding.

## 7. Blockers / open questions

- None.

## 8. Known limitations

- No wiring into the running app yet — the `ChatPopup` panel (T4.3) and the
  `SummarizationOrchestrator` wiring (T4.4) are separate tasks. Copy/Regenerate on an
  empty stopped assistant message still appear (cosmetic; not in spec).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-20-chatpopupview` (branch `issue-20-chatpopupview`)
- **Next action:** push the branch and open the PR (body from `.agents/templates/pr-body.md`, references "Closes #20"); squash-merge, then `Scripts/agent/worktree.sh 20 --remove` and flip the label to `agent:done`.
- **Files in play:** `TextAssist/UI/Chat/ChatPopupView.swift`, `Docs/handoffs/issue-20-chatpopupview.md`.
- **Watch out for:** branch is based on `574155e`; `main` has since advanced — if the PR reports "out of date", merge `origin/main` into the branch before merging.
- **Do not redo:** the `ChatPopupView` implementation (committed `79282a2`, reviewed APPROVE); the build check (passes).

## 10. Review

- Reviewer verdict: approve
- Findings: none blocking. Non-blocking note (chips hidden by the seeded preview) —
  resolved by adding an empty-state `#Preview`.
