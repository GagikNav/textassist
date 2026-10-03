# Handoff — issue #9 T1.1 — Extend SummaryStyle and add Write and Chat styles

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #9 (T1.1) |
| Epic | #2 |
| Milestone | M1 - Foundation |
| Status | agent:review |
| Branch | `issue-9-extend-summarystyle-and-add-write-and-chat-styles` |
| Worktree | `build/worktrees/issue-9-extend-summarystyle-and-add-write-and-chat-styles` |
| Base commit | `b0d355c` |
| Last commit | `2457e0b` |
| Updated | 2026-10-03 |

## 1. What this task is

T1.1 is the foundation of v2's data model: it replaces
`TextAssist/Models/SummaryStyle.swift` with the version in PRD-v2 §7 T1.1. It adds two
enums (`StyleCategory`, `OutputFormat`), four additive `SummaryStyle` properties
(`category`, `outputFormat`, `systemPrompt`, `temperature`), two shared system prompts
(`defaultSystemPrompt`, `writingSystemPrompt`), and grows the built-in set from 7 to 16
styles (6 Transform + 8 Write + 1 Chat + 1 Custom). It is a pure model change: no
caller is edited, and everything downstream (picker, provider, orchestrator) still
compiles because the new properties all have defaults.

## 2. Plan

- [x] Replace `TextAssist/Models/SummaryStyle.swift` with the verbatim PRD-v2 §7 T1.1 code.
- [x] Run the build check from `.agents/config.json`.
- [x] Independent review against the issue's Done-when, AGENTS.md constraints, scope.
- [x] Write/commit the handoff, mirror it to the issue, sync the label + handoff comment.

## 3. What changed

| File | Change |
|:--|:--|
| `TextAssist/Models/SummaryStyle.swift` | Replaced: adds `StyleCategory`/`OutputFormat` enums, `category`/`outputFormat`/`systemPrompt`/`temperature` properties, `defaultSystemPrompt`/`writingSystemPrompt`, and 16 built-in styles. |

## 4. Verification

- **Build check:** `xcodebuild build -project TextAssist.xcodeproj -scheme "Text Assist" -configuration Debug -destination "platform=macOS" -derivedDataPath build/DerivedData` → **PASS** (`** BUILD SUCCEEDED **`).
- **"Done when" checklist** (from the issue):
  - [x] Project builds.
  - [x] `SummaryStyle.builtIn.count == 16` (6 Transform + 8 Write + 1 Chat + 1 Custom; confirmed by inspection and by the reviewer).
  - [x] `CustomPromptPanel` still compiles unchanged (file untouched; build passes).
- **Independent review:** approve, no blocking findings (see §10).

## 5. How to test manually

> This is a model-only task; the visible effect is that the style picker now offers
> 16 styles. Write-specific behaviour (routing, cleaning, replace) is later work.

1. Open `TextAssist.xcodeproj` in Xcode, select the **Text Assist** scheme, and Run (`⌘R`).
2. In TextEdit (or any app), type some text, select it, and press `⌥⇧S`.
3. Look at the floating picker.
4. **Expected:** 16 rows, in this order — Short Summary `1`, Bullet Points `2`, Detailed Summary `3`, Key Takeaways & Action Items `4`, ELI5 `5`, Chat Thread `6`, Fix Grammar `g`, Improve Writing `i`, Professional tone `p`, Friendly tone `f`, Casual tone `c`, Confident tone `o`, Shorter `s`, Longer `l`, Chat with Selection `a`, Custom Prompt `0`.
5. Press `esc` to dismiss.

**Edge cases to try:** press `1` with Ollama running — the existing Transform
(Short Summary) flow must still stream as before (regression check). Press `esc` —
the picker closes. · **Not testable yet because:** a Write style selected now runs the
existing single-shot summary path; grouped section headers arrive in T2.1 (#10) and
Write cleaning/Replace in T3.5 (#16). Those are out of scope for T1.1.

## 6. Decisions

- Used the PRD §7 T1.1 code **verbatim** (verified byte-for-byte by the reviewer) — no
  `nonisolated`; the type is `@MainActor` under the project default, matching the
  existing `Models/` types. Rejected: any local variation (the design is frozen).
- Dropped the old `- Parameter`/`- Returns` doc lines on `prompt(for:)` and the slug
  example, because the PRD block omits them. `///` doc-comment style is preserved on
  all new types and members (constraint 5).

## 7. Blockers / open questions

- None.
- Note: `Scripts/agent/*.sh` reported the GitHub Project status sync was skipped
  (`Status field/option 'In Progress'/'In Review' not found`; `gh` token also lacks the
  `project` scope). Label changes still applied. Run `gh auth refresh -s project` to
  restore Project sync.

## 8. Resume here

- **Worktree:** `build/worktrees/issue-9-extend-summarystyle-and-add-write-and-chat-styles` (branch `issue-9-extend-summarystyle-and-add-write-and-chat-styles`)
- **Next action:** Open the PR for `issue-9-extend-summarystyle-and-add-write-and-chat-styles` (body from `.agents/templates/pr-body.md`, referencing #9 and this handoff); once merged, flip #9 to `agent:done`.
- **Files in play:** `TextAssist/Models/SummaryStyle.swift`; `Docs/handoffs/issue-9-summarystyle.md`.
- **Watch out for:** downstream tasks depend on the exact symbols here — `StyleCategory` (`transform/write/chat/custom`), `OutputFormat` (`markdown/plainText`), `SummaryStyle.chatWithSelection` (id `chat-with-selection`, key `a`), the 8 Write style factories, and `SummaryStyle.writingSystemPrompt` / `defaultSystemPrompt`. Do not rename them. Keep the additive-with-defaults shape so existing call sites keep compiling.
- **Do not redo:** the file is implemented, build-verified, and reviewer-approved.

## 9. Known limitations

- No caller is updated in this task; the picker shows the 8 Write + Chat styles before
  their routing exists (intended sequencing — routing is T1.2/T3.5, grouping is T2.1).
- This is a model-only change, so there is no new runtime behaviour to exercise beyond
  the picker listing 16 styles.

## 10. Review

- Reviewer verdict: **approve** — no blocking findings.
- Findings: non-blocking only — (a) the picker now surfaces all 16 styles before their routing lands (intended sequencing, no action); (b) prior `- Parameter`/`- Returns` doc lines on `prompt(for:)` and the slug example were dropped — exactly what the PRD block specifies. Scope confirmed: one changed file, no `project.pbxproj` edit, no renames, macOS 13 APIs only.
