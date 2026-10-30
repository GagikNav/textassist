# Issue contract — canonical task body

Task issues follow this shape so agents can parse them deterministically. Epics follow
the variant at the end. Bodies created before this contract already carry **Depends on** /
**Size** / **Done when** and only need labels/milestone.

```markdown
{{One-paragraph goal, in plain language. Link the epic (#N) and the PRD section.}}

- **Depends on:** {{comma-separated issue refs, or "none"}} · **Size:** {{S|M|L}}

**Maintainer action.** {{Optional. What only the maintainer may do (create a key or
certificate, add a package in Xcode, publish a release). Agents never handle secrets.}}

**Context**
- {{Optional. Facts the implementer needs: measured behaviour, constraints, links.}}

**Files**
- `TextAssist/path/File.swift` (new | edit | replace)

**Changes**
- {{bullet list of the concrete change, including what is out of scope}}

**Done when:**
- {{verifiable item 1}}
- {{verifiable item 2}}

**How to test manually**
1. {{exact action, with the app to use}}
2. **Expected:** {{what should happen}}

**Sequencing:** {{Optional. Shared files and the order tasks must land in.}}
```

Rules:
- "Depends on" lists **issue numbers**, not task IDs.
- "Done when" items are checkable by hand in the running app or by the build check.
- "How to test manually" is required (workflow §2). If something cannot be tested yet,
  say so and why.
- Tasks that edit the same file depend on each other (see `sequentialFiles` in
  `.agents/config.json`); the later one stays `agent:blocked` until the earlier one is merged.
- A task that has sub-issues is an epic and does not carry "Done when" itself.
- A task that edits `project.pbxproj` says so and needs the maintainer's approval
  (workflow §11).
- Epic membership is the native sub-issue link. `epic:N` labels exist only for the v2 plan.

## Epic variant

```markdown
{{Goal in plain language. What is wrong or missing, and for whom.}}

- **Blocked by:** {{issue refs, or "none"}}

{{Optional: audit table, options considered, constraints and risks.}}

**Tasks**
- [ ] #{{n}} — {{title}}   (tick when the issue is closed)

**Order:** {{what can start now, what waits for what}}

**Out of scope:** {{what this epic deliberately does not do}}

**How to confirm the epic:** {{one end-to-end check a human can run}}
```
