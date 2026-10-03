# Handoff — issue #12 T1.2 — Generalize the provider (multi-turn, per-request system prompt)

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #12 (T1.2) |
| Epic | #1 |
| Milestone | M1 - Foundation |
| Status | agent:review |
| Branch | `issue-12-generalize-the-provider-multi-turn-per-request-system-prompt` |
| Worktree | `build/worktrees/issue-12-generalize-the-provider-multi-turn-per-request-system-prompt` |
| Base commit | `c3a4d9b` |
| Last commit | `e93e1e0` |
| Updated | 2026-10-03 |

## 1. What this task is

T1.2 is the provider-layer foundation for v2's Write and Chat: it replaces the
summarize-only provider API with a generic multi-turn streaming API and moves the
system prompt out of the provider and into the request. `Models/LLMMessage.swift` is
new (`LLMMessage`, `ChatCompletionRequest`); `Models/SummaryRequest.swift` gains a
style-temperature fallback and a `completionRequest` bridge;
`Providers/LLMProvider.swift` now requires `stream(_:)` and provides a default
`summarize(_:)` on top of it; `Providers/OllamaProvider.swift` maps the whole message
array and sizes its context window from the whole conversation. Short Summary keeps
the exact same prompt, temperature and token budget as before.

## 2. Plan

- [x] Create `TextAssist/Models/LLMMessage.swift` (PRD-v2 §7 T1.2 verbatim).
- [x] Replace `TextAssist/Models/SummaryRequest.swift` (temperature fallback + `completionRequest`).
- [x] Replace `TextAssist/Providers/LLMProvider.swift` (`stream(_:)` + default `summarize(_:)`).
- [x] Edit `TextAssist/Providers/OllamaProvider.swift` (rename `summarize` → `stream`, drop fixed `systemPrompt`, map `request.messages`, whole-conversation `contextWindowSize`).
- [x] Run the build check (`BUILD SUCCEEDED`).
- [x] Independent review against the issue's Done-when, AGENTS.md constraints, scope.
- [x] Write/commit the handoff, mirror it to the issue, sync the label (this document).

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Models/LLMMessage.swift` | **New.** `LLMMessage` (role + content) and `ChatCompletionRequest` (messages, maxTokens, temperature). |
| `TextAssist/Models/SummaryRequest.swift` | Replaced: `temperature` resolves via `style.temperature ?? 0.2`; new `completionRequest` builds the `[system, user]` conversation. |
| `TextAssist/Providers/LLMProvider.swift` | Replaced: requires `stream(_ request: ChatCompletionRequest)`; default `summarize(_:)` calls `stream(request.completionRequest)`. |
| `TextAssist/Providers/OllamaProvider.swift` | Edited: `summarize` → `stream(ChatCompletionRequest)` (body unchanged); fixed `systemPrompt` deleted; `makeChatRequest` maps `request.messages`; `contextWindowSize` measures all messages. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (exit 0, `** BUILD SUCCEEDED **`, ~21 s).
- **"Done when" checklist** (from the issue):
  - [x] Builds.
  - [ ] Short Summary behaves exactly as before — **needs the running app** (see §5). Static reasoning: Short Summary has `systemPrompt == nil` and `temperature == nil`, so the request resolves to `SummaryStyle.defaultSystemPrompt` + `0.2` + `4096` — the same values the old hardcoded provider path used; only `num_ctx` grows slightly (whole-conversation formula).
  - [x] `orchestrator.streamSummary` still calls `llmProvider.summarize(request)` unchanged (grep: `Core/SummarizationOrchestrator.swift:189`).
- **Static checks:** no `Self.systemPrompt` remains; exactly one `stream(_:)` requirement and one implementation; no `project.pbxproj` change; no files outside the four above touched.
- **Independent review:** **approve** — no blocking findings (see §10). Reviewer reproduced the build (exit 0) and confirmed all PRD-v2 §T1.2 blocks match line-for-line.

## 5. How to test manually

1. Start Ollama with the configured model (default `phi3:instruct`) and confirm `http://localhost:11434` responds.
2. Open `TextAssist.xcodeproj`, select the **Text Assist** scheme, press `⌘R` (or launch `build/DerivedData/Build/Products/Debug/Text Assist.app`).
3. In TextEdit, type a paragraph, select it, press `⌥⇧S`, and choose **Short Summary** (`1`).
4. **Expected:** the floating panel streams a 2–4 sentence summary, no error, elapsed time appears — identical to before this change.
5. Press `↻` (regenerate) in the popup. **Expected:** a fresh stream, same behavior.
6. Use Replace on the result. **Expected:** the selection is replaced as before.

**Edge cases to try:** a long paragraph (context >2048 tokens) still streams without truncation; a Write style (e.g. Improve Writing `i`) now streams using `writingSystemPrompt` and its own temperature — intended T1.2 behavior, not a regression. · **Not testable by the agent:** steps 2–6 need the running GUI app, Accessibility permission and a local Ollama server; the build check plus the static equivalence argument above is what an agent can verify.

## 6. Decisions

- PRD-v2 §7 T1.2 code used **verbatim** across the four files (exact-block compare in review).
- Kept `summarize(_:)` as a protocol requirement with a default implementation, so the only production call site (`streamSummary`) stays byte-identical — required by "Done when".
- Renamed the `// MARK: - Streaming summary` heading to `// MARK: - Streaming` (the method is no longer summary-specific).
- `temperature` fallback chain is `parameter → style.temperature → 0.2`; Short Summary stays at `0.2`, Write styles use their own temperature.
- `contextWindowSize` now counts every message, with the old 2048…32768 clamp.

## 7. Blockers / open questions

- None.
- Same environment note as #9: `Scripts/agent/*.sh` reports the GitHub Project status sync is skipped in this environment (`gh` token lacks the needed project scope); labels still apply. Run `gh auth refresh -s project` to restore Project sync.

## 8. Known limitations

- No automated tests exist in this repo (manual verification only).
- Write/Chat UI is not wired yet; Write styles already route through the generic path and now pick up their system prompt and temperature (intended per PRD-v2 §7 T1.2).
- Streams remain single-turn from the UI's perspective; multi-turn Chat arrives in a later task.

## 9. Resume here

- **Worktree:** `build/worktrees/issue-12-generalize-the-provider-multi-turn-per-request-system-prompt` (branch `issue-12-generalize-the-provider-multi-turn-per-request-system-prompt`)
- **Next action:** Open the PR for `issue-12-generalize-the-provider-multi-turn-per-request-system-prompt` (body from `.agents/templates/pr-body.md`, referencing #12 and this handoff); after merge, flip #12 to `agent:done`.
- **Files in play:** `TextAssist/Models/LLMMessage.swift`, `TextAssist/Models/SummaryRequest.swift`, `TextAssist/Providers/LLMProvider.swift`, `TextAssist/Providers/OllamaProvider.swift`; this handoff.
- **Watch out for:** downstream tasks depend on the exact symbols — `LLMMessage.Role` (`system/user/assistant`), `ChatCompletionRequest`, `LLMProvider.stream(_:)`, `SummaryRequest.completionRequest`. Do not rename or change signatures. `OllamaProvider` intentionally no longer declares `summarize(_:)` — it uses the protocol default.
- **Do not redo:** the implementation is committed (`e93e1e0`), build-verified, and independent-reviewed (see §10).

## 10. Review

- Reviewer verdict: **approve** — no blocking findings.
- Findings: none blocking. Non-blocking notes: (a) the `// MARK: - Streaming` rename goes beyond the PRD's three listed edits — harmless, tied to the renamed method, disclosed in §6; (b) `contextWindowSize` also widens single-turn requests by ~30 tokens (system message now counted) — same formula and clamp, benign; (c) a payload-level check (`OLLAMA_DEBUG=1`) could harden §5 step 4 if stronger evidence is ever wanted. Scope confirmed: exactly the four spec'd files, no `project.pbxproj`, no unrelated edits, no existing type renames; orchestrator byte-identical; manual-test steps present and adequate.
