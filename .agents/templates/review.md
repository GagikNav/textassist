# Review — issue #{{ISSUE}} {{TASK}}

Produced by the Reviewer subagent (independent, read-only).

## Verdict
{{APPROVE / CHANGES REQUIRED}}

## Build
`{{build command}}` → {{pass/fail + one-line summary}}

## Done-when checklist
| Item (from the issue) | Verdict | Evidence |
|:--|:--|:--|
| … | pass / fail / can't verify | … |

## Manual test check
| Step (from handoff §5) | Testable? | Would it catch a regression? |
|:--|:--|:--|
| … | yes / no | yes / no |

If the manual test steps are missing, incomplete, or don't exercise the change, that is
a **blocking** finding.

## Blocking findings
1. **{{file:line}}** — {{what is wrong}} → {{smallest fix}}

## Non-blocking notes
- {{preference / follow-up, explicitly not blocking}}

## Scope check
- Unrelated changes? {{none / list}}
- `project.pbxproj` touched? {{no / yes — blocking}}
- Protected constraints respected? {{yes / list violations}}
