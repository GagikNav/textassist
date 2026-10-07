# Text Assist v5 — Draft Composer

**Draft** — Generate emails, messages, letters, and plain text from a description, on-device, anywhere on macOS.

| | |
|:--|:--|
| Status | Draft for review |
| Platform | macOS 13+, Swift 5 language mode, SwiftUI + AppKit |
| LLM backend | Local Ollama (`/api/chat`, NDJSON streaming) |
| Testing | **None.** Verification is "builds + manual check in the real app" |
| Place this file at | `tickets/PRD-v5-draft.md` |

---

## 1. Overview

Text Assist v2 ships **Transform · Write · Chat** for selected text. v5 adds a fourth job:

| Job | What it does | Trigger |
|:--|:--|:--|
| **Transform** | Summarize, bullets, ELI5, takeaways, custom prompt | `⌥⇧S` → picker digit |
| **Write** | Fix grammar, improve, change tone, shorter/longer | `⌥⇧S` → picker letter |
| **Chat** | Pinned selection as context, multi-turn conversation | `⌥⇧S` → `a` |
| **Draft** | Generate an email, message, letter, or text from a description | `⌥⇧D` |

**Draft** does not require selected text. The user presses `⌥⇧D`, describes what they need in a small floating panel, picks a draft type and tone, and the local LLM generates a ready-to-send draft. The result can be pasted at the cursor, replaced into a selection, refined ("shorter", "more formal", "elaborate"), copied, or continued in Chat.

The flow is intentionally similar to the existing Write/Chat flow so the app stays predictable: hotkey → input panel → stream → result popup → action.

---

## 2. Goals, non-goals, success criteria

### Goals
1. Generate a usable email, message, letter, or plain-text draft in two keystrokes (`⌥⇧D` → describe → generate).
2. Work with or without a text selection. When there is a selection, it can be used as optional context; when there isn't, the draft is pasted at the cursor.
3. Allow one-click refinement after generation: shorter, more formal, or elaborate more.
4. Reuse the existing non-activating panel pattern, replace mechanism, history store, and streaming infrastructure.
5. Keep the menu bar and settings untouched (no new settings needed for v1), but add a "Compose Draft" entry in the menu-bar popover.

### Non-goals (POC)
- No custom draft types or user-defined templates (fixed four types).
- No sub-variants (e.g., "follow-up email" vs "cold email") — flat list only.
- No recipient/subject/structured fields — single free-text description.
- No rich text or Markdown formatting in the generated output (plain text only).
- No automated tests.

### Success criteria (manual)
- In TextEdit with no selection: `⌥⇧D` → type "ask my manager for Friday off" → pick Email + Friendly → generate → draft appears → `⌘↩` pastes it at the cursor.
- In Mail with a paragraph selected: `⌥⇧D` → type "reply saying I agree" → pick Message + Professional → generate → `⌘↩` replaces the selection with the draft.
- After generation, tapping "Shorter" re-streams a more concise version without closing the popup.
- When no editable field is focused, `⌘↩` copies the draft to the clipboard silently, saves it to history, and shows a read-only text box underneath the result with the full draft for manual copying. No beep, no banner.
- The draft appears in the menu-bar history list with a "Draft" label, and reopening it restores the result without re-streaming.

---

## 3. Current state of the repo (read first)

### 3.1 Architecture today

```
Hotkey (⌥⇧S) ─► HotkeyManager ─► SummarizationOrchestrator.startSummarization()
                                   │
                  TextCaptureService.captureSelection()  (AX first, ⌘C fallback)
                                   │
                  StylePickerPanel (StylePickerView)
                     │ custom ─► CustomPromptPanel
                     ▼
                  SummaryPopup (SummaryPopupView + SummaryPopupViewModel)
                                   │
                  OllamaProvider.summarize(SummaryRequest) ─► AsyncThrowingStream<String>
```

### 3.2 What we reuse

| Component | Reuse for Draft |
|:--|:--|
| `TextCaptureService` | Capture optional selection + source app PID (even if text is empty). |
| `TextReplacementService` | Paste/replace via simulated ⌘V (works at cursor when nothing selected). |
| `HistoryStore` / `HistoryEntry` | Extended with a `category` field to distinguish draft entries. |
| `KeyablePanel` | Non-activating NPanel base for the new DraftInputPanel and DraftPopup. |
| `LLMProvider` / `OllamaProvider` | Add a `stream(_: ChatCompletionRequest)` method; `summarize` delegates to it. |
| `SummaryPopupViewModel` pattern | New `DraftPopupViewModel` follows the same `@MainActor` + `ObservableObject` shape. |

---

## 4. Target experience

### 4.1 Flow

```
⌥⇧D ─► capture (optional selection + PID) ─► DRAFT INPUT panel
                                              │
                                              ├── Type description
                                              ├── Draft type: [Email ▼]
                                              └── Tone:       [Friendly ▼]
                                                   [Generate]  Cancel
                                              │
                                              ▼
                                         DRAFT POPUP (streams)
                                              │
                                              ├── Shorter  More formal  Elaborate
                                              └── Copy  Regenerate  [Replace ⌘↩]  Chat ⌘T
```

### 4.2 Draft input panel

```
┌ Compose Draft ─────────────────────────────✕ ┐
│ What do you need?                             │
│ ┌───────────────────────────────────────────┐ │
│ │ Ask my manager for Friday off             │ │
│ └───────────────────────────────────────────┘ │
│                                               │
│ Type      [Email          ▼]                  │
│ Tone      [Friendly       ▼]                  │
│                                               │
│      [Generate]            Cancel             │
└───────────────────────────────────────────────┘
```

- **Description field**: Multi-line `TextField(axis: .vertical)`, focused on open. Return sends (not newline); Shift+Return for newline.
- **Type dropdown**: Email, Message, Letter, Text. Native SwiftUI `Picker` with `.menu` style.
- **Tone dropdown**: Professional, Friendly, Casual, Confident. Same picker style.
- **Generate button**: Primary action, violet accent, enabled when description is non-empty.
- **Cancel / Escape**: Closes the panel with no side effects.

### 4.3 Draft result popup

```
┌ Draft: Email ────────────────────────────────┐
│ [Email ▼]  [Friendly ▼]       [Clean | Diff ]✕│
│ ──────────────────────────────────────────── │
│ Dear [Manager's Name],                        │
│                                               │
│ I hope you're having a great week. I wanted  │
│ to ask if it would be possible to take this  │
│ Friday off...                                 │
│                                               │
│ ──────────────────────────────────────────── │
│ [Shorter] [More formal] [Elaborate]           │
│ Copy  Regenerate  [Replace ⌘↩]  Chat ⌘T  4.2s│
└───────────────────────────────────────────────┘
```

- **Header**: Draft type and tone dropdowns (switching re-streams), close button.
- **Body**: Plain text, selectable, streams in.
- **Refinement chips**: "Shorter", "More formal", "Elaborate". Tapping one appends a refinement instruction and re-streams.
- **Footer**: Copy, Regenerate, Replace (`⌘↩`), Continue in Chat (`⌘T`), elapsed time.
- **Diff toggle**: Optional. Since there's no "original" for drafts, Diff shows changes from the *previous* version when a refinement was applied.

### 4.4 Replace behavior

| Condition | Action |
|:--|:--|
| Selection was captured | Replace selection via `TextReplacementService` (existing behavior). |
| No selection, source app available | Paste at cursor via same ⌘V mechanism. |
| No source app available | Copy to clipboard silently and save to history. A read-only text box appears underneath the result body showing the generated draft for easy manual copying. No beep, no banner. |

---

## 5. Requirements

### 5.1 Hotkey

- **DR-1** Register a new global hotkey `⌥⇧D` (Option+Shift+D) in `HotkeyManager`, alongside the existing `⌥⇧S`.
- **DR-2** `⌥⇧D` triggers `DraftOrchestrator.startDrafting()`.

### 5.2 Capture

- **DR-3** `TextCaptureService` is called to capture the current selection *and* the source app PID, even when no text is selected.
- **DR-4** When no text is selected, `captured.text` may be empty; the flow continues normally. The PID is still required for replace-at-cursor.

### 5.3 Draft input panel

- **DR-5** `DraftInputPanel` (AppKit `NSPanel`, non-activating, `KeyablePanel` subclass) hosts `DraftInputView` (SwiftUI).
- **DR-6** The panel is centered on screen, ~380×280 pt, rounded corners (`.continuous` radius 18), non-activating.
- **DR-7** `DraftInputView` contains:
  - A multi-line `TextField(axis: .vertical)` for the description, focused on appear.
  - A `Picker("Type", selection: …)` with `.menu` style: Email, Message, Letter, Text.
  - A `Picker("Tone", selection: …)` with `.menu` style: Professional, Friendly, Casual, Confident.
  - "Generate" button (primary, disabled when description is empty or whitespace-only).
  - "Cancel" button.
- **DR-8** Return key submits (triggers Generate). Shift+Return inserts a newline in the description field.
- **DR-9** Escape key cancels and closes the panel.

### 5.4 Prompt construction

- **DR-10** Each draft type has a system prompt template:

| Type | System prompt |
|:--|:--|
| Email | "You are a professional email composer. Write a clear, well-structured email based on the user's description. Include appropriate greeting and sign-off. Output only the email text with no preamble or explanations." |
| Message | "You are a messaging assistant. Write a concise, natural message based on the user's description. Output only the message text with no preamble or explanations." |
| Letter | "You are a formal letter writer. Write a well-structured letter based on the user's description. Include appropriate header, greeting, body, and closing. Output only the letter text with no preamble or explanations." |
| Text | "You are a writing assistant. Write plain text content based on the user's description. Output only the text with no preamble or explanations." |

- **DR-11** Tone is appended to the system prompt: "Use a {tone} tone." where tone is lowercase.
- **DR-12** If the user had text selected, the user message is:

```
{description}

Context from current document:
{selectedText}
```

If no text was selected, the user message is just `{description}`.

### 5.5 Streaming and result popup

- **DR-13** `DraftPopup` (non-activating `NSPanel`, `KeyablePanel` subclass) hosts `DraftPopupView` with `DraftPopupViewModel`.
- **DR-14** The popup streams tokens from `OllamaProvider` using the constructed `ChatCompletionRequest`.
- **DR-15** The popup shows:
  - Draft type and tone dropdowns in the header (changing either re-streams with the new choice).
  - Plain-text body (selectable, streams in).
  - Refinement chips: "Shorter", "More formal", "Elaborate more".
  - Footer: Copy, Regenerate, Replace (`⌘↩`), Continue in Chat (`⌘T`), elapsed time.
- **DR-16** The elapsed timer starts when streaming begins and stops when streaming finishes or errors.

### 5.6 Refinement

- **DR-17** Tapping a refinement chip appends a refinement instruction to the current draft and re-streams:
  - "Shorter" → system: "Rewrite the following draft to be more concise and shorter while preserving the key message." user: `{currentDraft}`
  - "More formal" → system: "Rewrite the following draft in a more formal and professional tone." user: `{currentDraft}`
  - "Elaborate more" → system: "Expand the following draft with more detail and depth." user: `{currentDraft}`
- **DR-18** Refinement keeps the same draft type and tone context (they are part of the ongoing conversation, not reset).
- **DR-19** A "Diff" toggle shows word-level changes between the previous version and the current stream. This reuses the existing `TextDiffer` component.

### 5.7 Replace / Paste

- **DR-20** Replace (`⌘↩`) attempts to paste the draft into the source app:
  - If a selection was captured: replace it (existing `TextReplacementService` behavior).
  - If no selection was captured: paste at the cursor position (same ⌘V mechanism, works because there's no selection to replace).
- **DR-21** If the source app is unavailable or accessibility is not granted:
  - Copy the draft to the clipboard silently.
  - Save to history.
  - Show a read-only text box underneath the result body containing the full generated draft, so the user can manually select and copy it. No beep, no banner.

### 5.8 Continue in Chat

- **DR-22** "Chat ⌘T" closes the draft popup and opens `ChatPopup` with the draft as pinned context:
  - Seed messages: assistant = the generated draft.
  - Pinned context label: "Draft: {type}".

### 5.9 History

- **DR-23** Extend `HistoryEntry` with:
  ```swift
  enum HistoryEntryCategory: String, Codable {
      case transform, write, chat, draft
  }
  let category: HistoryEntryCategory
  ```
  For backward compatibility, decode missing `category` as `.transform`.
- **DR-24** Draft results are saved to `HistoryStore` with `category: .draft`, `styleName: "Draft: {type}"`, `input: description + " | \(type) | \(tone)"`.
- **DR-25** Menu-bar history shows draft entries with a "Draft" prefix or icon.
- **DR-26** Reopening a draft history entry restores the result in a `DraftPopup` (no re-streaming), with Replace enabled only if a source PID was stored (it won't be for history replays).
- **DR-27** The menu-bar popover (`MenuBarStatusView`) includes a "Compose Draft" row (with `⌥⇧D` shortcut) above "Open TextAssist". Tapping it triggers `DraftOrchestrator.startDrafting()` without requiring a text selection.

### 5.10 Keyboard shortcuts

| Shortcut | Action |
|:--|:--|
| `⌥⇧D` | Open Draft input panel |
| `Return` | Submit description / Generate |
| `Shift+Return` | Newline in description field |
| `Esc` | Cancel / close panel |
| `⌘↩` | Replace / paste draft |
| `⌘T` | Continue in Chat |
| `⌘C` | Copy draft |

---

## 6. File map

New files to create (all under `TextAssist/`):

| File | Responsibility |
|:--|:--|
| `Models/DraftType.swift` | `DraftType` enum: `email`, `message`, `letter`, `text` with `id`, `name`, `systemPrompt`. |
| `Models/DraftTone.swift` | `DraftTone` enum: `professional`, `friendly`, `casual`, `confident` with `id`, `name`. |
| `Models/DraftRequest.swift` | `DraftRequest` struct: description, type, tone, optionalSelectedText → `ChatCompletionRequest`. |
| `Core/DraftOrchestrator.swift` | `@MainActor` orchestrator: capture → input panel → stream → popup → replace. Owned by `TextAssistApp`. |
| `UI/Draft/DraftInputPanel.swift` | AppKit `NSPanel` wrapper for the draft input form. |
| `UI/Draft/DraftInputView.swift` | SwiftUI form: description, type picker, tone picker, Generate/Cancel. |
| `UI/Draft/DraftPopup.swift` | AppKit `NSPanel` wrapper for the draft result. |
| `UI/Draft/DraftPopupView.swift` | SwiftUI result view: header, body, refinement chips, footer. |
| `UI/Draft/DraftPopupViewModel.swift` | `@MainActor ObservableObject`: stream state, text, actions, refinement logic. |

Modified files:

| File | Change |
|:--|:--|
| `App/TextAssistApp.swift` | Add `DraftOrchestrator` as `@StateObject`, wire hotkey. |
| `Core/HotkeyManager.swift` | Register `⌥⇧D` hotkey; route to `DraftOrchestrator`. |
| `Models/HistoryEntry.swift` | Add `category: HistoryEntryCategory` field with backward-compatible decode. |
| `Stores/HistoryStore.swift` | No changes needed (generic `add(_:)`). |
| `Providers/LLMProvider.swift` | Add `func stream(_: ChatCompletionRequest) -> AsyncThrowingStream<String, Error>`; default implementation delegates from `summarize`. |
| `Providers/OllamaProvider.swift` | Implement `stream(_:)`; refactor `summarize` to delegate to it. |
| `UI/MenuBar/MenuBarStatusView.swift` | Add "Compose Draft" row with `⌥⇧D` shortcut. Show "Draft" prefix for draft history entries. |

---

## 7. Task breakdown

### Milestone D0 — Foundation (prerequisite)

**D0.1** Extend `HistoryEntry` with `category` field  
- Add `HistoryEntryCategory` enum, add `let category: HistoryEntryCategory` to `HistoryEntry`.
- Make `category` optional in decode, defaulting to `.transform`.
- Verify existing history loads without error.

**D0.2** Generalize `LLMProvider` streaming  
- Add `func stream(_ request: ChatCompletionRequest) -> AsyncThrowingStream<String, Error>` to `LLMProvider`.
- Refactor `OllamaProvider.summarize(_:)` to call `stream(request.completionRequest)`.
- Build check.

### Milestone D1 — Draft input panel

**D1.1** Create `DraftType` and `DraftTone` models  
- `DraftType.swift`: enum with 4 cases, `id`, `name`, `systemPrompt`.
- `DraftTone.swift`: enum with 4 cases, `id`, `name`.

**D1.2** Create `DraftRequest` model  
- `DraftRequest.swift`: description, type, tone, optionalSelectedText.
- `completionRequest: ChatCompletionRequest` property that builds the prompt per DR-10/11/12.

**D1.3** Create `DraftInputView` and `DraftInputPanel`  
- `DraftInputView.swift`: SwiftUI form with description field, type picker, tone picker, buttons.
- `DraftInputPanel.swift`: `KeyablePanel` subclass hosting `DraftInputView`.
- Focus description field on open, Return submits, Shift+Return newline, Escape cancels.

**D1.4** Create `DraftOrchestrator` (input flow)  
- `DraftOrchestrator.swift`: `startDrafting()` captures optional selection, shows `DraftInputPanel`.
- `onGenerate` constructs `DraftRequest`, closes input, shows popup.
- Build check.

### Milestone D2 — Draft result popup

**D2.1** Create `DraftPopupViewModel`  
- `@MainActor ObservableObject` with `streamedText`, `isStreaming`, `errorMessage`, `elapsedTime`.
- Actions: `onCopy`, `onReplace`, `onRegenerate`, `onRefine(short:)`, `onContinueInChat`.
- Refinement logic per DR-17.

**D2.2** Create `DraftPopupView`  
- SwiftUI view: header (type/tone dropdowns), body text, refinement chips, footer buttons.
- Reuse existing footer button styling.

**D2.3** Create `DraftPopup`  
- `KeyablePanel` subclass hosting `DraftPopupView`.
- Handle `⌘↩` for Replace, `⌘T` for Chat, `Esc` for close.

**D2.4** Wire `DraftOrchestrator` streaming  
- `showDraftPopup(request:)` creates view model, opens popup, calls `llmProvider.stream()`.
- Save result to `HistoryStore` on completion.
- Build check.

### Milestone D3 — Integration

**D3.1** Register `⌥⇧D` hotkey
- `HotkeyManager`: add `KeyboardShortcuts.Name.composeDraft` for `⌥⇧D`.
- Route to `DraftOrchestrator.startDrafting()`.

**D3.2** Wire `TextAssistApp`  
- Add `DraftOrchestrator` as `@StateObject`.
- Pass shared services (capture, provider, history).

**D3.3** Update history and menu bar  
- `MenuBarStatusView`: add a "Compose Draft" row above "Open TextAssist" with `⌥⇧D` shown as shortcut text. Tapping it calls `DraftOrchestrator.startDraftingFromMenu()`. This path skips text capture and starts with no selection.
- `HistoryEntry` decode backward compatibility.

**D3.4** Replace/paste at cursor  
- `DraftOrchestrator` / `DraftPopupViewModel`: if no selection, still call `TextReplacementService` (⌘V pastes at cursor when nothing is selected).
- Handle error (no source app / no accessibility): copy to clipboard silently, save to history, show the read-only text box underneath the result body per DR-21. No beep, no banner.

**D3.5** Manual verification  
- Test with selection (replace) and without (paste at cursor).
- Test refinement chips.
- Test history save/reopen.
- Test "no app focused" fallback.

---

## 8. Constraints (same as v2)

1. **Never edit `project.pbxproj`.** New `.swift` files under `TextAssist/` are picked up automatically.
2. **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**, Swift 5 mode.
3. **Deployment target macOS 13.0.** No `@Observable`, `onKeyPress`, two-parameter `.onChange(of:)`, `Inspector`.
4. **App Sandbox stays off.**
5. **Panels stay non-activating** (`KeyablePanel`, `.nonactivatingPanel`).
6. Preserve `///` doc-comment style on new public types and methods.
7. Run the build check after every task.

---

## 9. Open questions

1. Should the draft type dropdown include an "Other" or free-text option for future extensibility?
2. Should the description field have a character limit or placeholder examples?
3. Should we support a "Regenerate with same settings" shortcut (e.g., `⌘R`) in the popup?
4. Should draft history entries store the full `DraftRequest` (type, tone, description) so reopening can re-stream, or is static text sufficient?
