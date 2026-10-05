# Handoff — issue #26 T6.2 — Recent history

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #26 (T6.2) |
| Epic | #6 |
| Milestone | M5 |
| Status | review |
| Branch | `issue-26-recent-history` |
| Worktree | `build/worktrees/issue-26-recent-history` |
| Base commit | `4af430b` |
| Last commit | `163191a` |
| Updated | 2026-10-05 |

## 1. What this task is

Recent history (PRD-v2 §7 T6.2). Text Assist should remember the last results so the
user can reopen one instantly from the menu bar instead of re-running it. Results are
stored in a JSON file under Application Support, so they survive an app restart.

## 2. Plan

- [x] Add `Stores/HistoryStore.swift` with `HistoryEntry` (Codable, Identifiable) and
      `HistoryStore` (insert at 0, cap 25, `clear()`, JSON persistence).
- [x] Wire `HistoryStore` into `SummarizationOrchestrator`; record successful
      non-empty streams; add `reopen(_:)`.
- [x] Create the store in `TextAssistApp` and pass it to the orchestrator and menu bar.
- [x] Add a "Recent" section (up to 5 entries + "Clear history") to `MenuBarStatusView`.
- [x] Build check passes; independent Reviewer reports approve.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Stores/HistoryStore.swift` | New. `HistoryEntry` value type and `@MainActor HistoryStore` with `add`/`clear` and JSON persistence at `~/Library/Application Support/Text Assist/history.json`. |
| `TextAssist/Core/SummarizationOrchestrator.swift` | New `historyStore` dependency; `recordHistory` after a successful non-empty stream; `reopen(_:)` that reopens a stored result pre-filled, without re-streaming. |
| `TextAssist/UI/MenuBar/MenuBarStatusView.swift` | "Recent" section (header, up to 5 entries, "Clear history"), observing `HistoryStore`. |
| `TextAssist/App/TextAssistApp.swift` | Creates `HistoryStore`, passes it to the orchestrator and the menu bar. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`).
- **"Done when" checklist** (from the issue):
  - [x] Results appear under Recent after use — `recordHistory` inserts into the store; the menu bar renders `entries.prefix(5)`. (Code path verified; runtime hand-test below.)
  - [x] Reopen instantly — `reopen(_:)` pre-fills `streamedText` and shows the popup with no stream task.
  - [x] The file survives an app restart — loaded in `init`, saved after every change.

## 5. How to test manually

1. **Run the app:** open `TextAssist.xcodeproj` and Run, or launch the built `.app`.
   Have Ollama running with a model loaded (see the green dot in the menu bar).
2. **Make a result:** in TextEdit (or any app), select some text, press `⌥⇧S`, choose
   **Bullet Points** (or any Transform/Write style), and wait for the stream to finish.
3. **Check Recent:** open the menu bar icon. A **Recent** section now lists the result
   as `"Bullet Points · <first 40 chars of the selection>"`.
   **Expected:** the entry appears after use, newest first.
4. **Reopen instantly:** click that Recent entry.
   **Expected:** the popup opens immediately, pre-filled with the stored output, with no
   streaming spinner. (For a Write result like *Fix Grammar*, the **Replace** button is
   shown but disabled — there is no source PID. **Regenerate** `⌘R` re-streams using the
   stored input.)
5. **Restart persistence:** quit and relaunch the app.
   **Expected:** the Recent entries are still listed — the JSON file survived the restart.
6. **Clear history:** click **Clear history** in the Recent section.
   **Expected:** the Recent section disappears and the saved file is emptied.

**Edge cases to try:** run >5 results → only the 5 most recent show; select >20 000
chars → the stored input is truncated; delete/corrupt `history.json` → the app starts
with an empty Recent section.

## 6. Decisions

- **Truncate input at the call site** (`recordHistory`) rather than inside the store —
  the orchestrator is the only producer, and keeping `HistoryEntry` immutable (`let`
  fields) stays cleaner. (Rejected: truncating inside `add` forces a full struct copy.)
- **Fallback style `.shortSummary`** in `reopen` when `styleID` no longer matches a
  known style, exactly as the PRD specifies.
- **Persist failures are non-fatal** (logged with `print`) so a read-only disk or
  permissions problem never crashes the app, matching the repo's existing logging style.

## 7. Blockers / open questions

- None.

## 8. Known limitations

- Chat results are intentionally **not** recorded — the spec only defines reopening
  summary/transform/write results via the summary popup.
- The 20 000-char truncation is enforced at the single call site in the orchestrator,
  not inside `HistoryStore.add`.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-26-recent-history` (branch `issue-26-recent-history`)
- **Next action:** open a PR for `issue-26-recent-history`; on merge, flip #26 to
  `agent:done` and remove the worktree.
- **Files in play:** `TextAssist/Stores/HistoryStore.swift`, `TextAssist/Core/SummarizationOrchestrator.swift`, `TextAssist/UI/MenuBar/MenuBarStatusView.swift`, `TextAssist/App/TextAssistApp.swift`.
- **Watch out for:** `HistoryStore` must stay a shared instance — it is created once in
  `TextAssistApp.init` and passed to both the orchestrator and the menu bar.
- **Do not redo:** implementation, build check, and review are complete.

## 10. Review

- Reviewer verdict: **approve**
- Findings: none blocking. Non-blocking: cancellation window after the final delta
  (addressed with a `guard !Task.isCancelled` after the stream loop); truncation lives
  at the call site; `FileManager.urls(...).first!` force-unwrap; `#Preview` reads the
  real history file (harmless).
