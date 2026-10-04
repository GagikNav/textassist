# Handoff — issue #27 T6.4 — Menu-bar model picker

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #27 (T6.4) |
| Epic | #6 (Epic 6 — Polish (P1)) |
| Milestone | M5 - Polish (P1) |
| Status | agent:review |
| Branch | `issue-27-menu-bar-model-picker` |
| Worktree | `build/worktrees/issue-27-menu-bar-model-picker` |
| Base commit | `574155e` |
| Last commit | `06b4f5e` (code) + handoff commit on top |
| Updated | 2026-10-05 |

## 1. What this task is

Add a model picker to the menu-bar popover so the user can switch the Ollama model
directly from the menu bar, without opening Settings. When the server is online and the
status monitor has a non-empty `availableModels` list, show a menu-style
`Picker("Model", selection: $settings.model)` listing those models — including the
currently configured model if the server did not report it (the same pattern as
`ProviderSettingsView`). Because the picker binds to `SettingsStore.model`, which
`OllamaProvider` reads when building each request, the next request uses the newly
selected model.

## 2. Plan

- [x] Confirm `OllamaStatusMonitor.availableModels` + `status` (T5.1) and the
      `ProviderSettingsView` picker pattern (current-model fallback).
- [x] Add the conditional menu-style `Picker` to `MenuBarStatusView` below the status
      row, shown only when `monitor.status == .online && !monitor.availableModels.isEmpty`.
- [x] Run the build check.
- [x] Reviewer subagent review (no blocking code findings).
- [x] Write handoff, mirror to issue, sync labels/Project.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/UI/MenuBar/MenuBarStatusView.swift` | Added a `Picker("Model", selection: $settings.model)` with `.pickerStyle(.menu)` between the status row and the `Divider`, gated on `monitor.status == .online && !monitor.availableModels.isEmpty`. It lists `monitor.availableModels` via `ForEach(..., id: \.self)` and prepends `Text(settings.model).tag(settings.model)` when the current model is not in the list (same pattern as `ProviderSettingsView`). |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`).
- **"Done when" checklist** (from the issue):
  - [x] When monitor is online and `availableModels` is non-empty, a menu-style `Picker("Model", selection: $settings.model)` is shown — implemented and build-verified.
  - [x] Lists `availableModels`; includes the current model if missing — implemented (same pattern as `ProviderSettingsView`).
  - [x] Binding to `$settings.model` means the next request uses the newly selected model (static trace: `OllamaProvider` reads `settings.model` when building a request).
  - [ ] Switching the model in the popover changes the model used by the next request — **needs the running app** (pending human check).

## 5. How to test manually

1. Build and run: open `TextAssist.xcodeproj` in Xcode and Run, or launch
   `build/DerivedData/Build/Products/Debug/Text Assist.app`.
2. **Start Ollama** (`ollama serve`) and make sure at least one model is pulled
   (`ollama list`). Click the menu-bar icon to open the popover.
   **Expected:** below the green `Ollama · <model>` status row, a **Model** menu picker
   appears listing the models from `ollama list`. The selected value matches the current
   `settings.model`; if the current model isn't in the list, it is still shown as an extra
   entry at the top.
3. **Switch to a different model** in the picker, then select some text in another app and
   run **Assist with Selection** (`⌥⇧S`).
   **Expected:** the next summary/request targets the newly selected model (e.g. watch
   `ollama ps` while the request runs, or compare the response style/verbosity vs. the old
   model).
4. **Stop Ollama** and reopen the popover.
   **Expected:** the Model picker is **not** shown; only the red dot + "Not running.
   Start Ollama and try again." caption appears (the picker is gated on `.online`).

**Edge cases to try:** configure a model name in Settings that the server does not
advertise, then open the popover — the picker should still show it as an extra entry so the
selection stays stable. · **Not testable yet because:** n/a — all of the above is runnable
today once Ollama is serving.

## 6. Decisions

- **`.pickerStyle(.menu)`** — the issue explicitly asks for a "menu-style" picker; on macOS
  13 this renders as a pull-down button in the popover, which fits the compact menu-bar
  layout. (Rejected: the default form picker style, which is wider and not menu-like.)
- **Gate on `monitor.status == .online && !monitor.availableModels.isEmpty`** — matches the
  issue's exact condition and keeps the offline caption ("Not running…") as the only
  fallback. (Rejected: always showing the picker with an empty list, which would render an
  empty pop-up button while offline.)
- **Reuse the `ProviderSettingsView` current-model fallback** (`if !models.contains(settings.model)`)
  verbatim — consistent behavior between Settings and the menu bar, and keeps the selected
  model selectable even when the server doesn't list it. (Rejected: introducing a new
  normalization helper, which would be scope creep for a size-S task.)

## 7. Blockers / open questions

- None.

## 8. Known limitations

- The picker only appears after `monitor.refresh()` completes successfully (it reuses the
  T5.2 `.onAppear` refresh). If the popover window is reused by macOS and `.onAppear` does
  not re-fire, the picker may briefly lag behind the server state — same caveat already
  noted in the #23 handoff; revisit only if the manual check shows it.
- Model list is not sorted/filtered; it mirrors whatever `provider.listModels()` returns
  (same as `ProviderSettingsView`).

## 9. Resume here

- **Worktree:** `build/worktrees/issue-27-menu-bar-model-picker` (branch `issue-27-menu-bar-model-picker`)
- **Next action:** open the PR for `issue-27-menu-bar-model-picker` (body from
  `.agents/templates/pr-body.md`); after a human confirms the model-switch "Done when" and
  the PR merges, flip #27 to `agent:done` and remove the worktree
  (`Scripts/agent/worktree.sh 27 --remove`).
- **Files in play:** `TextAssist/UI/MenuBar/MenuBarStatusView.swift`,
  `Docs/handoffs/issue-27-menu-bar-model-picker.md`.
- **Watch out for:** this view is also touched by T6.2; keep the picker gated on
  `monitor.status == .online && !monitor.availableModels.isEmpty` and bind to
  `$settings.model`. Do not touch `project.pbxproj`.
- **Do not redo:** the picker, the build check, and the reviewer approval are complete.

## 10. Review

- Reviewer verdict: **changes required (process only)** — code diff correct and scoped,
  build passes; no handoff/§5 existed at review time (now written below).
- Findings: non-blocking — (1) `.pickerStyle(.menu)` in a plain `VStack` may render as a
  pull-down showing only the selected value (cosmetic, matches the issue ask); (2) the
  bottom padding was normalized to `8` to match the existing vertical rhythm.
