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
   `area:`, `epic:` (`epic:0…6`), and one `agent:` state (default `agent:ready`).
3. Assign the milestone (`M0`–`M5`) per `.agents/config.json`.
4. Set `agent:blocked` if any issue in **Depends on** is open; else `agent:ready`.
5. Link the task as a **native sub-issue** of its epic.
6. For a bulk pass over existing issues, run `Scripts/agent/normalize-issues.sh`.

## Rules
- "Depends on" lists issue numbers, not task IDs.
- "Done when" items must be checkable by hand or by the build check.
- One task = one reviewable change; split anything larger.
