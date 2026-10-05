# Text Assist — PRD v3: Multi-Provider Support

**Status:** Draft
**Builds on:** PRD v2 (implemented)
**Scope level:** Fast personal-use POC, native macOS. Written so LLM agents can implement it sub-task by sub-task. No automated tests; each milestone ends with a manual check.

---

## 1. Summary

Text Assist currently talks to one backend: a local Ollama server. This version adds four providers alongside it, all behind the existing `LLMProvider` protocol:

1. **Apple Foundation Models**: the on-device model built into macOS. **Default.**
2. **Ollama**: the existing local provider and today's main backend. Stays fully supported and selectable.
3. **OpenAI**
4. **Anthropic**
5. **Google Gemini**

The user picks the active provider in Settings. Foundation Models is selected out of the box. Ollama keeps working exactly as it does today, with its saved base URL and model preserved, so nothing that works now is removed.

## 2. Goals and Non-Goals

### Goals

- Foundation Models is the default provider and works with zero configuration on a supported Mac.
- OpenAI, Anthropic, and Gemini are selectable in Settings, each with its own API key and model.
- All providers stream tokens into the existing popup with no changes to the popup flow.
- API keys are stored only in the macOS Keychain.
- The user can always tell which provider produced a summary, and knows when text leaves the Mac.

### Non-Goals

- No automatic fallback from one provider to another, especially none from local to cloud.
- No per-style or per-request provider override (a global active provider only).
- No multi-turn chat, tool calling, image input, or structured output. Those belong to the later chat feature.
- No cost tracking, usage dashboards, or token counting UI.
- No OpenAI-compatible custom endpoints (future work).
- No automated tests.

## 3. User Stories

| # | As a user… | So that… |
| :- | :--------- | :------- |
| 1 | I install the app and press the hotkey | It works immediately, privately, on-device, with no setup. |
| 2 | I open Settings and choose OpenAI, Anthropic, or Gemini | I can use a stronger model when I want one. |
| 3 | I paste an API key once | It is stored securely and I never have to enter it again. |
| 4 | I tap "Test connection" | I know my key and model work before I use them. |
| 5 | I look at the summary popup | I can see which provider and model produced it. |
| 6 | The default model is unavailable on my Mac | I get a clear message explaining why and what to do. |
| 7 | I use a cloud provider | I'm told once that my selected text will be sent to that company. |

## 4. Functional Requirements

### 4.1 Provider selection

- **FR-1** Settings has a provider picker with: Apple Foundation Models, Ollama, OpenAI, Anthropic, Gemini.
- **FR-2** On first launch, the selected provider is Apple Foundation Models.
- **FR-3** The selection is persisted in `UserDefaults` and applies on the next summary. No restart needed.
- **FR-4** Each provider keeps its own model selection, so switching providers does not overwrite another provider's choice.
- **FR-5** There is no automatic fallback. If the active provider fails or is unavailable, show the error in the popup banner. The user decides what to change.

### 4.2 Apple Foundation Models (default)

- **FR-6** Uses the on-device `SystemLanguageModel` via the `FoundationModels` framework. No network, no API key, no model list. Display name: "Apple Foundation Model (on-device)".
- **FR-7** Before each request, check `SystemLanguageModel.default.availability`. When unavailable, throw a friendly error per reason:
  - Device not eligible: "This Mac doesn't support Apple Intelligence. Choose another provider in Settings."
  - Apple Intelligence not enabled: "Turn on Apple Intelligence in System Settings, or choose another provider."
  - Model not ready: "The on-device model is still downloading. Try again shortly."
  - macOS older than 26: "Apple Foundation Models requires macOS 26 or later. Choose another provider in Settings."
- **FR-8** The shared system prompt is passed as the session `instructions`. The style prompt is the user prompt.
- **FR-9** Streaming: Foundation Models yields **cumulative snapshots**, not deltas. The provider must convert snapshots to deltas (yield only the new suffix) so the popup's `streamedText += delta` logic keeps working.
- **FR-10** The on-device model has a small context window (currently about 4,096 tokens, shared between input and output). Handle this explicitly:
  - Cap generated tokens for this provider well below the shared `4096` default.
  - If the input is too long, catch the context-window error and show: "This selection is too long for the on-device model. Choose a shorter selection or switch to another provider."
  - Chunking or map-reduce summarization is **out of scope**.
- **FR-11** Catch guardrail refusals and show a readable message instead of a raw error.
- **FR-12** Temperature from `SummaryRequest` is mapped to the framework's generation options.

### 4.3 OpenAI

- **FR-13** Endpoint: `POST https://api.openai.com/v1/chat/completions` with `stream: true`. Auth: `Authorization: Bearer <key>`.
- **FR-14** Messages: system prompt as the `system` message, style prompt as the `user` message.
- **FR-15** Parse Server-Sent Events: for each `data:` line, decode and yield `choices[0].delta.content`. A `data: [DONE]` line ends the stream.
- **FR-16** Model list from `GET /v1/models`. The user picks one in Settings. If the list can't be loaded, fall back to a plain text field.
- **FR-17** Verify the correct token-limit parameter name for the chosen model family against current OpenAI docs (newer models use `max_completion_tokens` rather than `max_tokens`) before implementing.

### 4.4 Anthropic

- **FR-18** Endpoint: `POST https://api.anthropic.com/v1/messages` with `stream: true`. Headers: `x-api-key: <key>`, `anthropic-version: 2023-06-01`, `content-type: application/json`.
- **FR-19** Body: `model`, `max_tokens` (**required**), `temperature`, `system` as a top-level string, and `messages` containing one `user` message.
- **FR-20** Parse SSE: yield `delta.text` from `content_block_delta` events whose delta type is `text_delta`. End on `message_stop`. Surface `error` events as errors.
- **FR-21** Model list from `GET /v1/models` with the same headers.

### 4.5 Google Gemini

- **FR-22** Endpoint: `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?alt=sse`. Auth via the `x-goog-api-key` header (not a query parameter, so keys don't end up in logs or URLs).
- **FR-23** Body: `systemInstruction` (the system prompt), `contents` (one `user` entry with the style prompt), and `generationConfig` with `temperature` and `maxOutputTokens`.
- **FR-24** Parse SSE: yield the concatenated text of `candidates[0].content.parts[*].text` from each event.
- **FR-25** Model list from `GET /v1beta/models`. Keep only models whose `supportedGenerationMethods` include `generateContent`, and strip the `models/` prefix from names.

### 4.6 API keys and Keychain

- **FR-26** Add `KeychainStore` (a thin wrapper over `kSecClassGenericPassword`) with `save`, `load`, `delete`, keyed by provider.
- **FR-27** Keys are never stored in `UserDefaults`, never logged, and never printed to the console (including in `print` debugging).
- **FR-28** In Settings, the key field is a `SecureField`. After saving, show a masked placeholder ("Key saved") plus a **Remove key** button. The saved key is never re-displayed.
- **FR-29** If a cloud provider is active and no key is saved, the request fails immediately with: "Add your <Provider> API key in Settings." No network call is made.

### 4.7 Settings UI

- **FR-30** `ProviderSettingsView` becomes provider-aware: provider picker at the top, then a section that changes with the selection:
  - Foundation Models: availability status line ("Available" or the reason it isn't). No other fields.
  - Ollama: existing Base URL + model controls (unchanged behavior).
  - OpenAI / Anthropic / Gemini: API key field, model picker (with text-field fallback), **Test connection** button.
- **FR-31** **Test connection** calls `listModels()` and shows success or the readable error inline.
- **FR-32** The settings panel is currently a fixed 420×220. Increase the height (about 320–360) so the cloud form fits without clipping.
- **FR-33** Each cloud provider section shows a one-line privacy note: "Selected text is sent to <Company> when you summarize."

### 4.8 Popup changes

- **FR-34** The popup shows the active provider and model (for example "Anthropic · <model>") in the bottom toolbar next to the timer.
- **FR-35** Error banner behavior is unchanged. All new errors conform to `LocalizedError`, so the existing banner displays them.

### 4.9 Privacy and consent

- **FR-36** The first time a given cloud provider is used, show a one-time confirmation: "Your selected text will be sent to <Company>. Continue?" with Continue / Cancel. Persist acceptance per provider. Cancel aborts the request and leaves the provider selected.
- **FR-37** Foundation Models and Ollama (localhost) never show this prompt.
- **FR-38** Update the README and `Docs/setup-guide.md` privacy note: still no telemetry and keys in Keychain, but cloud providers transmit selected text when chosen.

## 5. Technical Design

### 5.1 Architecture

The orchestrator currently receives one fixed `llmProvider` at init. To avoid touching the capture → picker → popup flow, introduce a **router** that implements `LLMProvider` and delegates to whichever provider is active.

```text
TextAssistApp
  └─ ProviderRouter (LLMProvider)           ← passed to SummarizationOrchestrator + SettingsPanel
        ├─ AppleFoundationProvider          (macOS 26+, gated)
        ├─ OllamaProvider                   (existing)
        ├─ OpenAIProvider
        ├─ AnthropicProvider
        └─ GeminiProvider
```

`SummarizationOrchestrator` and the popup flow stay as they are, apart from FR-34.

### 5.2 New and changed files

| File | Change |
| :--- | :----- |
| `Models/ProviderKind.swift` | **New.** `enum ProviderKind: String, CaseIterable, Identifiable` with cases `appleFoundation`, `ollama`, `openAI`, `anthropic`, `gemini`. Properties: `displayName`, `requiresAPIKey`, `isCloud`, `companyName`. |
| `Providers/ProviderRouter.swift` | **New.** Reads `settings.selectedProvider`, lazily creates and caches provider instances, forwards `listModels()` and `summarize(_:)`. `displayName` returns "<Provider> · <model>". |
| `Providers/AppleFoundationProvider.swift` | **New.** Wrapped in `#if canImport(FoundationModels)` and `@available(macOS 26.0, *)`. |
| `Providers/OpenAIProvider.swift` | **New.** |
| `Providers/AnthropicProvider.swift` | **New.** |
| `Providers/GeminiProvider.swift` | **New.** |
| `Providers/ProviderError.swift` | **New.** Shared `LocalizedError` for: `missingAPIKey(ProviderKind)`, `unauthorized`, `rateLimited`, `unavailable(String)`, `inputTooLong`, `refused`, `serverMessage(String)`, `unexpectedStatus(Int)`, `decodingFailed`. Ollama keeps `OllamaError`. |
| `Providers/LLMProvider.swift` | Add `var maxInputCharacters: Int? { get }` with a default of `nil` via protocol extension, so `OllamaProvider` compiles unchanged. |
| `Utilities/KeychainStore.swift` | **New** (FR-26). |
| `Utilities/StreamParsers.swift` | Add an SSE helper: extract the payload from `data:` lines and ignore everything else. |
| `Stores/SettingsStore.swift` | Add `selectedProvider` (default `.appleFoundation`) and per-provider model values. Keep the existing `baseURL` and `model` as the Ollama values so existing users' settings survive. |
| `Stores/ConsentStore.swift` | **New, small.** Tracks per-provider cloud-consent acceptance in `UserDefaults`. |
| `UI/Settings/ProviderSettingsView.swift` | Rework per FR-30 to FR-33. |
| `UI/Settings/SettingsPanel.swift` | Taller panel (FR-32). Pass the router as the provider. |
| `UI/Popup/SummaryPopupViewModel.swift` + `SummaryPopupView.swift` | Add `providerLabel` and show it (FR-34). |
| `Core/SummarizationOrchestrator.swift` | Set `viewModel.providerLabel`, run the consent check (FR-36) before streaming. |
| `App/TextAssistApp.swift` | Create `ProviderRouter` instead of `OllamaProvider`. |
| `Docs/PRD-v3.md`, `README.md`, `Docs/setup-guide.md` | Add this PRD and update the privacy text (FR-38). |

### 5.3 Implementation notes for agents

- **Concurrency.** The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, and `LLMProvider` is `Sendable`. Follow the pattern in `OllamaProvider`: read settings with `await MainActor.run { ... }` inside the streaming `Task`, build the `URLRequest` there, and keep network parsing off the main actor.
- **Streaming template.** Copy the structure of `OllamaProvider.summarize`: `AsyncThrowingStream`, an inner `Task`, `continuation.onTermination = { _ in task.cancel() }`, and the same `mapError` approach. Reuse `streamingSession` (long timeouts) for cloud providers.
- **SSE and blank lines.** `URLSession.AsyncBytes.lines` drops empty lines. That is fine here, because only `data:` lines matter. Do not build parsing that relies on blank-line event separators.
- **HTTP errors.** Map 401/403 to `unauthorized`, 429 to `rateLimited`, and everything else to `unexpectedStatus`. Where practical, read the error body and surface the provider's own message through `serverMessage`.
- **Foundation Models API.** This framework is new, so confirm exact type and property names (session creation, `streamResponse`, snapshot content property, generation-options type, error cases) against the current Apple documentation and the installed Xcode SDK before writing code. Do not guess signatures.
- **Deployment target.** Keep `MACOSX_DEPLOYMENT_TARGET = 13.0`. All `FoundationModels` code must be availability-gated so the app still builds and runs on older macOS, where the Foundation Models option reports "requires macOS 26".
- **No hardcoded model IDs.** Model names change often. Populate model pickers from each provider's list endpoint. Start with no model selected for cloud providers, and require the user to pick one. If none is chosen, the error is "Choose a model in Settings."
- **Cloud input limits.** The existing 100,000-character capture limit stays. `AppleFoundationProvider.maxInputCharacters` should be set to a conservative value (for example 8,000) and checked before sending.
- **Secrets hygiene.** Remove or avoid `print` statements that include request headers or bodies in any new provider.

## 6. Milestones and Sub-Tasks

### M1: Provider abstraction, settings, Keychain

1. Add `ProviderKind`.
2. Add `ProviderError`.
3. Add `KeychainStore`.
4. Extend `SettingsStore` with `selectedProvider` and per-provider model storage. Verify the existing Ollama base URL and model still load.
5. Add `ProviderRouter`, initially forwarding only to `OllamaProvider`.
6. Switch `TextAssistApp` to the router.

**Manual check:** The app behaves exactly as before, using Ollama through the router.

### M2: Apple Foundation Models (default)

1. Add `AppleFoundationProvider` with the availability check, snapshot-to-delta streaming, guardrail and context-size errors.
2. Register it in the router and make it the default `selectedProvider`.
3. Add the Settings section with the availability status line.
4. Add the macOS-below-26 path.

**Manual check:** On a clean first launch (no saved settings), the hotkey → picker → popup flow summarizes using the on-device model with no setup. A very long selection shows the "too long" message. Switching to Ollama and back works.

### M3: OpenAI

1. Add SSE helper to `StreamParsers.swift`.
2. Add `OpenAIProvider` (streaming, model list).
3. Add key field, model picker, and Test connection to Settings.
4. Add `ConsentStore` and the first-use confirmation in the orchestrator.

**Manual check:** With a valid key, summaries stream. With no key, the "Add your OpenAI API key" error appears and no request is sent. A bad key shows the unauthorized message. The consent prompt appears once.

### M4: Anthropic

1. Add `AnthropicProvider` (streaming, model list, required headers).
2. Wire it into the router and Settings.

**Manual check:** Same checks as M3, using an Anthropic key.

### M5: Gemini

1. Add `GeminiProvider` (streaming, model list with `generateContent` filter).
2. Wire it into the router and Settings.

**Manual check:** Same checks as M3, using a Gemini key.

### M6: Polish

1. Show the provider/model label in the popup (FR-34).
2. Update README and `Docs/setup-guide.md` (FR-38).
3. Run through the full checklist in section 7.

## 7. Acceptance Checklist (manual)

- [ ] Fresh install, no settings: Foundation Models is selected, and a summary works with no configuration.
- [ ] Foundation Models unavailable (older macOS, Apple Intelligence off, or model not ready): the popup shows the matching message and no network request is made.
- [ ] Switching providers in Settings takes effect on the next summary without restarting.
- [ ] Each of OpenAI, Anthropic, and Gemini: save key → Test connection succeeds → pick model → summary streams.
- [ ] Each cloud provider with no key: immediate "Add your … API key" error.
- [ ] Each cloud provider with a wrong key: unauthorized error, no crash.
- [ ] Rate-limit and network errors surface as readable messages.
- [ ] Closing the popup mid-stream cancels the request for every provider.
- [ ] Regenerate and style change work with every provider.
- [ ] Popup shows the provider and model for every provider.
- [ ] Consent prompt appears once per cloud provider and never for Foundation Models or Ollama.
- [ ] API keys do not appear in `UserDefaults`, the console output, or the git working tree.
- [ ] Existing Ollama users keep their saved base URL and model after upgrading.
- [ ] The app still builds with the macOS 13 deployment target.

## 8. Risks

| Risk | Impact | Mitigation |
| :--- | :----- | :--------- |
| Foundation Models context window is small | Long selections fail on the default provider | Clear error (FR-10), conservative input cap, message suggesting another provider. Chunking is future work. |
| Default provider isn't available on every Mac | First-run failure for some users | Specific, actionable messages (FR-7). No silent cloud fallback, to protect privacy. |
| Provider APIs and model names change | Broken requests | Populate model lists from API; keep each provider in its own file; verify request shapes against current docs during implementation. |
| Foundation Models API surface is new | Compile or runtime mismatches | Verify against Apple docs and the installed SDK; gate with availability checks. |
| Cloud use sends private text off-device | Privacy surprise | One-time consent (FR-36), per-section notice (FR-33), popup provider label (FR-34), README update (FR-38). |
| API key leakage | Credential exposure | Keychain only, header-based auth, no logging of requests. |

## 9. Open Questions

1. **Ollama's place.** This PRD keeps it as a selectable provider. If you'd rather retire it now that Foundation Models is the local default, remove it from `ProviderKind` and migrate its settings.
2. **Deployment target.** Keeping macOS 13 with availability gating means the default provider only works on macOS 26+. If the app is only for your own Mac, raising the target to 26 would simplify the code. Decide before M2.
3. **Unavailable default on first launch.** The current design shows an error until the user picks another provider. A friendlier option is a one-time first-run prompt that offers to open Settings. Worth adding if you expect other people to run it.
4. **Per-style provider.** A later enhancement could let styles pick a provider (for example, quick summaries on-device, detailed ones in the cloud).
