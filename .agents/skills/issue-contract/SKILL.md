---
name: issue-contract
description: "Create or normalize a Text Assist GitHub issue to the agent-parsable contract: Depends on, Size, Files, Done when, plus labels (kind/size/area/epic/agent state) and milestone. Use when filing an issue, splitting an epic, or when an issue is missing fields an agent needs."
argument-hint: "<issue-number or 'new'>"
---

# Issue contract

## When to use
- Filing a new task or epic.
- An existing issue lacks the fields agents parse (`Depends on`, `Size`, `Done when`).

## Procedure
1. Use the body shape in `.agents/templates/issue-body.md`.
   - Task: goal, **Depends on / Size**, **Files**, **Done when**.
   - Epic: goal, **Blocked by**, and a task list; no "Done when" of its own.
2. Apply exactly one of each label: `kind:` (`task`/`epic`), `size:` (`S`/`M`/`L`),
   `area:`, and one `agent:` state (default `agent:ready`). Add an `epic:` label
   (`epic:0…6`) only for the v2 plan; later work belongs to its epic through the native
   sub-issue link (step 5).
3. Assign the milestone (`M0`–`M5`) per `.agents/config.json`.
4. Set `agent:blocked` if any issue in **Depends on** is open; else `agent:ready`.
5. Link the task as a **native sub-issue** of its epic.
6. For a bulk pass over existing issues, run `Scripts/agent/normalize-issues.sh`.

## Rules
- A task whose human step cannot be done by an agent (creating a key or certificate,
  adding a package in Xcode, publishing a release) says **Maintainer action** near the top
  and names exactly what the maintainer does. Agents never handle secrets.
- Two tasks that edit the same file (see `sequentialFiles` in `.agents/config.json`) get a
  real **Depends on** from the later to the earlier one, plus a **Sequencing** line.
- Every task ends with **How to test manually** (workflow §2); say what cannot be tested
  yet and why.
- If the task touches `project.pbxproj`, say so and that it needs the maintainer's
  approval (workflow §11).
- "Depends on" lists issue numbers, not task IDs.
- "Done when" items must be checkable by hand or by the build check.
- One task = one reviewable change; split anything larger.
