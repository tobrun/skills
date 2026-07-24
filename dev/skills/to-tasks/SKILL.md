---
name: to-tasks
description: Split a plan at docs/plan/{plan-name}/plan.md into numbered task files (task_1.md, task_2.md, ...) sized for individual implementation. Use after to-plan when execution spans multiple tasks, or to break an existing plan into tasks.
disable-model-invocation: true
---

# To Tasks

Split the execution of a plan into ordered tasks, each one written as its own file next to the plan.

Input: an existing `docs/plan/{plan-name}/plan.md`.
Output: `docs/plan/{plan-name}/task_1.md`, `task_2.md`, and so on, plus a task index in the plan's Execution section.

## Sizing tasks

- Each task is a vertical slice: it delivers a verifiable piece of behavior, not a horizontal layer (all models, then all endpoints).
- Size each task so it can be handed to the `implement` skill as a standalone spec and completed in one sitting.
- Apply the INVEST test: independent where possible, negotiable in detail, valuable on its own, estimable, small, and testable at its seam.
  The demo question is the quick check: if you cannot show the task's behavior working by itself, it is not sliced right.
- Order tasks so every task builds only on tasks before it.
- If the plan honestly fits in one task, say so instead of splitting artificially; to-plan then embeds it in the plan directly.
- Never create a catch-all task ("cleanups", "remaining items"); leftover work either belongs to a real task or goes back to the plan as a scope decision.
- If unknowns make a task impossible to estimate, it is too big or too vague: split it, or make the first task a spike whose deliverable is the knowledge needed to plan the rest, written back into the plan.

## Writing the task

- The title is a verb-led imperative that completes the sentence "to finish this task, I need to {title}", so the plan's task index reads as a scannable checklist.
  "Add one-click rollback to the deploy UI" beats "Rollback work".
- Each task file is self-contained: the implementer must not need this conversation.
  The what and the why live in Goal, and decisions reached in discussion are written into the file, not left in chat.
- Use user-story framing ("As a [user], I want [goal], so that [benefit]") only when the slice is user-facing value; technical work reads better as a plain imperative.
  Never force the form; an empty "so that" is the tell.
- When a task fixes a defect, the Goal includes numbered reproduction steps, expected vs actual behavior, and the environment, so the implementer can reproduce end to end before fixing.

## Numbering

Task files are numbered from 1.
If task files already exist for this plan, do not renumber or overwrite them; continue from the highest existing index.

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

Concrete files to change, including the docs rows from the plan's
Documentation impact section that this task is responsible for.

## Suggested seams

The public interfaces where tests for this task should live.
These are proposals; the implement skill confirms them with the user.

## Acceptance criteria

2-5 checkable statements that define done, from an independent
source of truth (the spec or plan), not from the intended
implementation. Use Given-When-Then for behavioral ones, and
cover the error and edge cases that matter, not just the happy
path. More than 5 means the task should be split. Task done is
not plan done: the plan's Success criteria are judged at review,
not here.

## Depends on

Task numbers this task builds on, or "None".
```

## Updating the plan

After writing the task files, update the plan's Execution section with an index:

```markdown
| Task | Title | Depends on |
| ---- | ----- | ---------- |
| [task_1.md](task_1.md) | ... | None |
```

Every doc listed in the plan's Documentation impact section must be owned by exactly one task; a doc update nobody owns will not happen.
