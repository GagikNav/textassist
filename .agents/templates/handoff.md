# Handoff — issue #{{ISSUE}} {{TASK}} — {{TITLE}}

> Committed on the task branch and mirrored to the GitHub issue. This is the durable
> memory for the task: any model or session resumes from **Resume here**.

| | |
|:--|:--|
| Issue | #{{ISSUE}} ({{TASK}}) |
| Epic | #{{EPIC}} |
| Milestone | {{MILESTONE}} |
| Status | {{STATUS}} |
| Branch | `{{BRANCH}}` |
| Worktree | `build/worktrees/{{BRANCH}}` |
| Base commit | `{{BASE_COMMIT}}` |
| Last commit | `{{HEAD_COMMIT}}` |
| Updated | {{DATE}} |

## 1. What this task is

{{ONE_PARAGRAPH — the issue goal and why, in plain language}}

## 2. Plan

- [ ] Step 1 …
- [ ] Step 2 …

## 3. What changed

| File | Change |
|:--|:--|
| `path/to/file.swift` | … |

## 4. Verification

- **Build check:** `{{BUILD_COMMAND}}` → {{PASS/FAIL + one-line summary}}
- **"Done when" checklist** (from the issue):
  - [x] …
  - [ ] … (needs running app / not yet)

## 5. How to test manually

> Copy-pasteable steps a human can follow to see this feature work. Expected result
> last. If the step cannot be tested yet (needs a later task), say so explicitly.

1. {{Launch: open `TextAssist.xcodeproj` and Run, or open the built `.app`.}}
2. {{Do the thing — e.g. select text in TextEdit, press ⌥⇧S, choose …}}
3. {{Next action the tester takes}}
4. **Expected:** {{exactly what should appear / happen}}

**Edge cases to try:** {{…}} · **Not testable yet because:** {{… / n/a}}

## 6. Decisions

- {{Decision}} — {{why}}. (Rejected: {{alternative}}.)

## 7. Blockers / open questions

- {{None.}} / {{Blocker + who can unblock}}

## 8. Known limitations

- {{Anything deliberately not done, and where it is tracked.}}

## 9. Resume here

- **Worktree:** `build/worktrees/{{BRANCH}}` (branch `{{BRANCH}}`)
- **Next action:** {{the single next concrete step}}
- **Files in play:** `…`
- **Watch out for:** {{gotcha another agent would miss}}
- **Do not redo:** {{work already finished this session}}

## 10. Review

- Reviewer verdict: {{approve / changes required}}
- Findings: {{blocking items and resolution, or "none"}}
