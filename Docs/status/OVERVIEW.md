# Text Assist — Work Overview

_Generated 2026-11-01 12:06 by `Scripts/agent/overview.sh`. Do not edit by hand._

- Repo: [GagikNav/textassist](https://github.com/GagikNav/textassist)
- Project: [#4](https://github.com/users/GagikNav/projects/4)
- Total issues: 61

## Milestones

| Milestone | Done | Total | Progress |
|:--|--:|--:|:--|
| M0 - Design approved | 2 | 2 | `##########` 100% |
| M1 - Foundation | 5 | 5 | `##########` 100% |
| M2 - Write + Replace | 10 | 10 | `##########` 100% |
| M3 - Chat | 5 | 5 | `##########` 100% |
| M4 - Menu bar status | 4 | 4 | `##########` 100% |
| M5 - Polish (P1) | 5 | 5 | `##########` 100% |

## Now

**In progress**

**Ready**
- #106 Use Apple's on-device Foundation Model instead of Ollama (selectable provider)
- #85 Add the Refine as Prompt style to the Write group
- #79 Add ↑/↓/Return keyboard navigation to the style picker
- #76 Homebrew tap and cask (optional second channel)
- #50 Cancel the in-flight Ollama stream immediately on style change
- #49 Add repeat_penalty/top_p/stop to Ollama chat options

**Blocked**
- #88 Document Refine as Prompt and verify it appears everywhere styles are listed
- #87 Make the Write result flow handle restructured, multi-line output
- #86 Tune the prompt-refinement system prompt and add a sample set
- #81 Document picker keys and verify the keyboard flow end to end
- #80 Highlight the selected picker row and add a key hint
- #51 Prevent superseded streams from clobbering popup state

**Epics ready to delegate**
- #89 Epic: Refine as Prompt — turn selected text into a better LLM prompt
- #82 Epic: Keyboard navigation in the style picker menu
- #52 Epic: Fix Ollama prompt repetition on style change

## Epics

### #1 Epic 3 — Write experience in the result popup

| Task | Issue | State |
|:--|--:|:--|
| T3.2 TextDiffer | #13 | closed |
| T3.1 SummaryPopupViewModel additions | #14 | closed |
| T3.3 PasteboardSnapshot and TextReplacementService | #15 | closed |
| T3.5 Orchestrator: clean, diff, replace, filter styles | #16 | closed |
| T3.4 Result popup UI: plain-text rendering, Diff toggle, original disclosure, Replace and Chat buttons | #17 | closed |
| Replace-in-place fails or beeps instead of replacing selection | #59 | closed |

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
| Menu-bar Assist with Selection beeps and does not start capture | #60 | closed |

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

### #47 Epic: Fix Ollama prompt repetition on style change

| Task | Issue | State |
|:--|--:|:--|

### #52 Epic: Fix Ollama prompt repetition on style change

| Task | Issue | State |
|:--|--:|:--|
| Add repeat_penalty/top_p/stop to Ollama chat options | #49 | open |
| Cancel the in-flight Ollama stream immediately on style change | #50 | open |
| Prevent superseded streams from clobbering popup state | #51 | open |

### #68 Epic: Esc dismisses every Text Assist window

| Task | Issue | State |
|:--|--:|:--|
| Close KeyablePanel windows on Esc (result popup, chat popup, settings) | #65 | closed |
| Make Esc dismiss the menu-bar window | #66 | closed |
| Make Esc work while a text input has focus | #67 | closed |

### #69 Epic: In-app updates and versioned releases

| Task | Issue | State |
|:--|--:|:--|
| Versioning policy, release guide and a reliable release version | #70 | closed |
| Generate and document the Sparkle update-signing key (maintainer action) | #71 | closed |
| Integrate Sparkle: updater service and Info.plist keys | #72 | closed |
| Update UI: version label, Check for Updates… and auto-check setting | #73 | closed |
| Release script: build ZIP, sign it and publish appcast.xml | #74 | closed |
| Cut the first updater-enabled release and verify updating end to end | #75 | closed |
| Homebrew tap and cask (optional second channel) | #76 | open |
| Spike: stable signing so Accessibility survives updates | #77 | closed |
| Sign releases with a stable self-signed certificate | #83 | closed |
| Release notes: list what changed since the previous release | #103 | closed |

### #82 Epic: Keyboard navigation in the style picker menu

| Task | Issue | State |
|:--|--:|:--|
| Add ↑/↓/Return keyboard navigation to the style picker | #79 | open |
| Highlight the selected picker row and add a key hint | #80 | open |
| Document picker keys and verify the keyboard flow end to end | #81 | open |

### #89 Epic: Refine as Prompt — turn selected text into a better LLM prompt

| Task | Issue | State |
|:--|--:|:--|
| Add the Refine as Prompt style to the Write group | #85 | open |
| Tune the prompt-refinement system prompt and add a sample set | #86 | open |
| Make the Write result flow handle restructured, multi-line output | #87 | open |
| Document Refine as Prompt and verify it appears everywhere styles are listed | #88 | open |

## Recent handoffs

- [issue-67-make-esc-work-while-a-text-input-has-focus.md](../handoffs/issue-67-make-esc-work-while-a-text-input-has-focus.md)
- [issue-103-release-notes-list-what-changed-since-the-previous-release.md](../handoffs/issue-103-release-notes-list-what-changed-since-the-previous-release.md)
- [issue-66-make-esc-dismiss-the-menu-bar-window.md](../handoffs/issue-66-make-esc-dismiss-the-menu-bar-window.md)
- [issue-65-close-keyablepanel-on-esc.md](../handoffs/issue-65-close-keyablepanel-on-esc.md)
- [issue-75-cut-the-first-updater-enabled-release-and-verify-updating-end-to-end.md](../handoffs/issue-75-cut-the-first-updater-enabled-release-and-verify-updating-end-to-end.md)
- [issue-83-sign-releases-with-a-stable-self-signed-certificate.md](../handoffs/issue-83-sign-releases-with-a-stable-self-signed-certificate.md)
- [issue-69-epic-in-app-updates-and-versioned-releases.md](../handoffs/issue-69-epic-in-app-updates-and-versioned-releases.md)
- [issue-73-update-ui-version-label-check-for-updates-and-auto-check-set.md](../handoffs/issue-73-update-ui-version-label-check-for-updates-and-auto-check-set.md)
- [issue-72-integrate-sparkle-updater-service-and-info-plist-keys.md](../handoffs/issue-72-integrate-sparkle-updater-service-and-info-plist-keys.md)
- [issue-74-release-script-build-zip-sign-it-and-publish-appcast-xml.md](../handoffs/issue-74-release-script-build-zip-sign-it-and-publish-appcast-xml.md)
