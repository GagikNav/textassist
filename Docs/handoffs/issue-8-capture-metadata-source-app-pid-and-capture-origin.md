# Handoff — issue #8 T1.4 — Capture metadata: source app PID and capture origin

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #8 (T1.4) |
| Epic | #1 (Epic 1 — Foundation) |
| Milestone | M1 - Foundation |
| Status | In Review (`agent:review`) |
| Branch | `issue-8-capture-metadata-source-app-pid-and-capture-origin` |
| Worktree | `build/worktrees/issue-8-capture-metadata-source-app-pid-and-capture-origin` |
| Base commit | `87ac743` |
| Last commit | (handoff commit on this branch) |
| Updated | 2026-10-03 |

## 1. What this task is

Text Assist captures a selection and later (in Write/Replace, T3.x/T4.x) needs to paste
a result back over the user's real selection. To make that safe, `CapturedText` must
record **where** the text came from: which app (its PID) and **how** it was captured
(AX selected text, whole field value, or the ⌘C clipboard fallback). This task adds that
metadata — a `CaptureOrigin` enum, `sourceAppPID`, and a computed `canReplaceSelection` —
and threads the PID and origin through `TextCaptureService`. Behavior is unchanged; the
new fields are inert until later tasks consume them.

## 2. Plan

- [x] Replace `Models/CapturedText.swift` with the PRD §7 T1.4 code (add `CaptureOrigin`, `sourceAppPID`, `origin`, `canReplaceSelection`).
- [x] Edit `Core/TextCaptureService.swift`: `tryCaptureViaAccessibility` returns `(text:origin:)`; `captureSelection()` passes PID + origin; `makeCapturedText` takes and forwards them.
- [x] Run the build check.
- [x] Independent reviewer verifies the diff (verdict: **approve**, no blocking findings).

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Models/CapturedText.swift` | Added `CaptureOrigin` enum (`selectedText`/`fieldValue`/`clipboard`), `sourceAppPID: pid_t? = nil`, `origin: CaptureOrigin = .selectedText`, computed `canReplaceSelection`. |
| `TextAssist/Core/TextCaptureService.swift` | `tryCaptureViaAccessibility` returns `(text: String, origin: CaptureOrigin)?`; `captureSelection()` passes `pid` + `origin` through; `makeCapturedText(text:sourceAppName:pid:origin:)` forwards both. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`)
- **"Done when" checklist** (from the issue):
  - [x] Builds (`** BUILD SUCCEEDED **`)
  - [x] `SummaryPopupView` preview still compiles (new members are `var` with defaults, so the `CapturedText(text:sourceAppName:)` call sites keep compiling)
  - [ ] Capture behavior unchanged (needs running app — manual check below)

## 5. How to test manually

> Copy-pasteable steps a human can follow to see this feature work. Expected result
> last. The behavior must be **identical to before** — this task only records metadata.

1. Open `TextAssist.xcodeproj` and Run the "Text Assist" scheme (or open the built `.app`).
2. Select some text in Safari (or Notes), press `⌥⇧S`, choose an action (e.g. Short Summary).
3. **Expected:** the summary panel appears with the correct result, exactly as before.
4. Focus a text field with **no selection** (e.g. a search box), press `⌥⇧S`.
5. **Expected:** the whole field value is captured and summarized (the `.fieldValue` path).
6. In an app that does not expose AX text (e.g. Microsoft Word), select text and press `⌥⇧S`.
7. **Expected:** the ⌘C fallback runs, the result appears, and your clipboard is restored afterwards.

**Edge cases to try:** a password/secure field (capture is refused as before). · **Not testable yet because:** the new metadata is inert — nothing visible changes until Write/Replace (T3.x/T4.x) consumes `canReplaceSelection`.

## 6. Decisions

- `sourceAppPID`, `origin` are `var` with default values — so the synthesized memberwise initializer keeps existing call sites (`SummaryPopupView` preview, `makeCapturedText`) compiling without touching them. (Rejected: `let` — would have forced edits to the preview and broken "Done when".)
- `canReplaceSelection = sourceAppPID != nil && origin != .fieldValue` — matches the PRD verbatim; clipboard captures are treated as replaceable because the fallback only runs on an actual selection (empty text throws `noSelection`).

## 7. Blockers / open questions

- None.

## 8. Known limitations

- The metadata is recorded but not yet consumed; Replace (T3.x/T4.x) is where `canReplaceSelection` is read. No UI or behavior change in this task.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-8-capture-metadata-source-app-pid-and-capture-origin` (branch `issue-8-capture-metadata-source-app-pid-and-capture-origin`)
- **Next action:** Open the PR for this branch; on merge, flip the issue to `agent:done` and remove the worktree.
- **Files in play:** `TextAssist/Models/CapturedText.swift`, `TextAssist/Core/TextCaptureService.swift`
- **Watch out for:** `captureSelection()` is the only caller of `tryCaptureViaAccessibility`; the tuple return must be unwrapped (`result.text`, `result.origin`), not the old `if let text`.
- **Do not redo:** the code changes, build check, and review are finished — only PR + merge + state flip remain.

## 10. Review

- Reviewer verdict: **approve**
- Findings: none blocking. Non-blocking: `canReplaceSelection` returns `true` for `.clipboard` (defensible — fallback only runs on a real selection); `CapturedText`/`CaptureOrigin` carry no explicit actor marker (consistent with pre-existing style, builds cleanly).
