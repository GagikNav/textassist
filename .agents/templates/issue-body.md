# Issue contract — canonical task body

Task issues follow this shape so agents can parse them deterministically. Epics follow
a short variant (goal + blocked-by + task list). Bodies created before this contract
already carry **Depends on** / **Size** / **Done when** and only need labels/milestone.

```markdown
{{One-paragraph goal, in plain language. Link the PRD section.}}

- **Depends on:** {{comma-separated issue refs, or "none"}} · **Size:** {{S|M|L}}

**Files**
- `TextAssist/path/File.swift` (new | edit | replace)

**Changes**
- {{bullet list of the concrete change}}

**Done when:**
- {{verifiable item 1}}
- {{verifiable item 2}}
```

Rules:
- "Depends on" lists **issue numbers**, not task IDs.
- "Done when" items are checkable by hand in the running app or by the build check.
- A task that has sub-issues is an epic and does not carry "Done when" itself.
