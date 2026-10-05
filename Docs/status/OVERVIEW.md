# Text Assist — Work Overview

_Generated 2026-10-05 19:25 by `Scripts/agent/overview.sh`. Do not edit by hand._

- Repo: [GagikNav/textassist](https://github.com/GagikNav/textassist)
- Project: [#4](https://github.com/users/GagikNav/projects/4)
- Total issues: 34

## Milestones

| Milestone | Done | Total | Progress |
|:--|--:|--:|:--|
| M0 - Design approved | 2 | 2 | `##########` 100% |
| M1 - Foundation | 5 | 5 | `##########` 100% |
| M2 - Write + Replace | 9 | 9 | `##########` 100% |
| M3 - Chat | 5 | 5 | `##########` 100% |
| M4 - Menu bar status | 3 | 3 | `##########` 100% |
| M5 - Polish (P1) | 2 | 5 | `####......` 40% |

## Now

**In progress**

**Ready**
- #51 Prevent superseded streams from clobbering popup state
- #50 Cancel the in-flight Ollama stream immediately on style change
- #49 Add repeat_penalty/top_p/stop to Ollama chat options
- #26 T6.2 Recent history

**Blocked**
- #24 T6.3 Settings: hotkey recorders and launch at login

**Epics ready to delegate**
- #52 Epic: Fix Ollama prompt repetition on style change
- #47 Epic: Fix Ollama prompt repetition on style change
- #6 Epic 6 — P1 extras

## Epics

### #1 Epic 3 — Write experience in the result popup

| Task | Issue | State |
|:--|--:|:--|
| T3.2 TextDiffer | #13 | closed |
| T3.1 SummaryPopupViewModel additions | #14 | closed |
| T3.3 PasteboardSnapshot and TextReplacementService | #15 | closed |
| T3.5 Orchestrator: clean, diff, replace, filter styles | #16 | closed |
| T3.4 Result popup UI: plain-text rendering, Diff toggle, original disclosure, Replace and Chat buttons | #17 | closed |

### #2 Epic 1 — Foundation: models, provider, capture metadata

| Task | Issue | State |
|:--|--:|:--|
| T1.3 OutputCleaner for rewrite results | #7 | closed |
| T1.4 Capture metadata: source app PID and capture origin | #8 | closed |
| T1.1 Extend SummaryStyle and add Write and Chat styles | #9 | closed |
| T1.2 Generalize the provider (multi-turn, per-request system prompt) | #12 | closed |

### #3 Epic 2 — Picker v2

| Task | Issue | State |
|:--|--:|:--|
| T2.1 Grouped StylePickerView | #10 | closed |
| T2.2 Size the picker panel to its content | #11 | closed |

### #4 Epic 4 — Chat

| Task | Issue | State |
|:--|--:|:--|
| T4.4 Orchestrator wiring for Chat | #19 | closed |
| T4.3 Panel positioning helper and ChatPopup | #18 | closed |
| T4.2 ChatPopupView | #20 | closed |
| T4.1 ChatViewModel | #21 | closed |

### #5 Epic 5 — Menu bar status

| Task | Issue | State |
|:--|--:|:--|
| T5.1 OllamaStatusMonitor | #22 | closed |
| T5.2 Menu-bar popover with status | #23 | closed |

### #6 Epic 6 — P1 extras

| Task | Issue | State |
|:--|--:|:--|
| T6.3 Settings: hotkey recorders and launch at login | #24 | open |
| T6.1 Direct-action hotkeys (skip the picker) | #25 | closed |
| T6.2 Recent history | #26 | open |
| T6.4 Menu-bar model picker | #27 | closed |

### #29 Epic 0 — Design and mockup (gate)

| Task | Issue | State |
|:--|--:|:--|
| T0.1 Design mockup for all v2 surfaces (blocks Epics 1–6) | #28 | closed |

## Recent handoffs

- [issue-25-direct-action-hotkeys-skip-the-picker.md](../handoffs/issue-25-direct-action-hotkeys-skip-the-picker.md)
- [issue-19-orchestrator-wiring-for-chat.md](../handoffs/issue-19-orchestrator-wiring-for-chat.md)
- [issue-18-panel-positioning-helper-and-chatpopup.md](../handoffs/issue-18-panel-positioning-helper-and-chatpopup.md)
- [issue-20-chatpopupview.md](../handoffs/issue-20-chatpopupview.md)
- [issue-27-menu-bar-model-picker.md](../handoffs/issue-27-menu-bar-model-picker.md)
- [issue-16-orchestrator-clean-diff-replace-filter-styles.md](../handoffs/issue-16-orchestrator-clean-diff-replace-filter-styles.md)
- [issue-17-result-popup-ui-plain-text-rendering-diff-toggle-original-di.md](../handoffs/issue-17-result-popup-ui-plain-text-rendering-diff-toggle-original-di.md)
- [issue-23-menu-bar-popover-with-status.md](../handoffs/issue-23-menu-bar-popover-with-status.md)
- [issue-22-ollamastatusmonitor.md](../handoffs/issue-22-ollamastatusmonitor.md)
- [issue-15-pasteboardsnapshot-and-textreplacementservice.md](../handoffs/issue-15-pasteboardsnapshot-and-textreplacementservice.md)
