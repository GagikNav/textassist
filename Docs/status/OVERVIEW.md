# Text Assist — Work Overview

_Generated 2026-10-05 20:53 by `Scripts/agent/overview.sh`. Do not edit by hand._

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
| M5 - Polish (P1) | 5 | 5 | `##########` 100% |

## Now

**In progress**

**Ready**
- #51 Prevent superseded streams from clobbering popup state
- #50 Cancel the in-flight Ollama stream immediately on style change
- #49 Add repeat_penalty/top_p/stop to Ollama chat options

**Blocked**

**Epics ready to delegate**
- #52 Epic: Fix Ollama prompt repetition on style change
- #47 Epic: Fix Ollama prompt repetition on style change

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
| T6.3 Settings: hotkey recorders and launch at login | #24 | closed |
| T6.1 Direct-action hotkeys (skip the picker) | #25 | closed |
| T6.2 Recent history | #26 | closed |
| T6.4 Menu-bar model picker | #27 | closed |

### #29 Epic 0 — Design and mockup (gate)

| Task | Issue | State |
|:--|--:|:--|
| T0.1 Design mockup for all v2 surfaces (blocks Epics 1–6) | #28 | closed |

## Recent handoffs

- [issue-16-orchestrator-clean-diff-replace-filter-styles.md](../handoffs/issue-16-orchestrator-clean-diff-replace-filter-styles.md)
- [issue-19-orchestrator-wiring-for-chat.md](../handoffs/issue-19-orchestrator-wiring-for-chat.md)
- [issue-9-summarystyle.md](../handoffs/issue-9-summarystyle.md)
- [issue-26-recent-history.md](../handoffs/issue-26-recent-history.md)
- [issue-14-summarypopupviewmodel-additions.md](../handoffs/issue-14-summarypopupviewmodel-additions.md)
- [issue-11-size-the-picker-panel-to-its-content.md](../handoffs/issue-11-size-the-picker-panel-to-its-content.md)
- [issue-12-generalize-the-provider-multi-turn-per-request-system-prompt.md](../handoffs/issue-12-generalize-the-provider-multi-turn-per-request-system-prompt.md)
- [issue-20-chatpopupview.md](../handoffs/issue-20-chatpopupview.md)
- [issue-15-pasteboardsnapshot-and-textreplacementservice.md](../handoffs/issue-15-pasteboardsnapshot-and-textreplacementservice.md)
- [issue-21-chatviewmodel.md](../handoffs/issue-21-chatviewmodel.md)
