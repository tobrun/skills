---
name: to-tasks
description: Split a plan at docs/plan/{plan-name}/plan.md into numbered task files (task_1.md, task_2.md, ...) sized for individual implementation. Use after to-plan when execution spans multiple tasks, or to break an existing plan into tasks.
disable-model-invocation: true
---

# To Tasks

Split a plan's execution into ordered tasks, each its own file next to the plan.

Input: an existing `docs/plan/{plan-name}/plan.md`.
Output: `task_1.md`, `task_2.md`, ... plus a task index in the plan's Execution section.

If the user didn't name a plan, find it yourself before asking: match the current branch name to a `docs/plan/{plan-name}/` slug, or use the only plan directory that has no `task_N.md` files yet.
Ask which plan only if more than one is a plausible match; otherwise proceed without waiting for clarification.

## Sizing tasks

- Vertical slice: a verifiable piece of behavior, not a horizontal layer (all models, then all endpoints).
- Sized to hand to `implement` as a standalone spec, completed in one sitting.
- INVEST: independent where possible, negotiable in detail, valuable on its own, estimable, small, testable at its seam. Quick check: can you demo it working by itself?
- Order so each task builds only on tasks before it.
- If the plan honestly fits in one task, say so - don't split artificially; `to-plan` embeds it directly.
- No catch-all tasks ("cleanups", "remaining items"); leftover work belongs to a real task or goes back to the plan as a scope decision.
- Unknowns that block estimation mean the task is too big or vague: split it, or make the first task a spike whose deliverable is the knowledge needed to plan the rest.

## Writing the task

- Title: a verb-led imperative completing "to finish this task, I need to {title}" ("Add one-click rollback to the deploy UI", not "Rollback work") - keeps the task index scannable.
- Self-contained: the implementer must not need this conversation. Decisions reached in discussion get written into the file, not left in chat.
- User-story framing ("As a [user], I want [goal], so that [benefit]") only for user-facing value; technical work reads better as a plain imperative. An empty "so that" means you forced it.
- A defect task's Goal includes numbered reproduction steps, expected vs actual, and environment, so the implementer can reproduce before fixing.

## Numbering

Number from 1.
If task files already exist for this plan, continue from the highest index - never renumber or overwrite.

## Task structure

Use this template for each `task_N.md`:

```markdown
# Task {N}: {title}

Part of [{plan-name}](plan.md).

## Goal

The behavior this task delivers, verifiable on its own.

## Scope

In: what this task changes.
Out: what is deliberately left to other tasks.

## Files and docs touched

Concrete files to change, including the Documentation impact rows this task owns.

## Suggested seams

The public interfaces where tests should live - proposals; `implement` confirms them with the user.

## Acceptance criteria

2-5 checkable statements from an independent source of truth (spec or plan), not the intended implementation.
Given-When-Then for behavioral ones; cover error and edge cases, not just the happy path.
More than 5 means split the task.
Task done is not plan done - Success criteria are judged at review.

## Depends on

Task numbers this builds on, or "None".
```

## Updating the plan

After writing the tasks, add an index to the plan's Execution section:

```markdown
| Task | Title | Depends on |
| ---- | ----- | ---------- |
| [task_1.md](task_1.md) | ... | None |
```

Every doc in the plan's Documentation impact section must be owned by exactly one task, or the update won't happen.
