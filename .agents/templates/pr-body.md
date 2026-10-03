# {{TASK}} — {{title}}

Closes #{{ISSUE}}.

## What
{{One-paragraph summary of the change}}

## Why
{{The issue goal; link the epic and PRD section}}

## How
- {{Key implementation notes}}

## Verification
- Build: `{{build command}}` → {{pass}}
- Manual: {{what was checked in the running app}}

## Handoff
- `Docs/handoffs/issue-{{ISSUE}}-{{slug}}.md`

## Checklist
- [ ] Build check passes
- [ ] "Done when" verified by hand
- [ ] Reviewer subagent: no blocking findings
- [ ] Handoff written and mirrored to the issue
- [ ] No `project.pbxproj` changes; macOS 13 APIs only
