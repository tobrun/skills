---
name: to-tasks
description: Split a plan at .dev/{plan-name}/plan.md into numbered task files (task_1.md, task_2.md, ...) sized for individual implementation. Use after to-plan when execution spans multiple tasks, or to break an existing plan into tasks.
disable-model-invocation: true
---

# To Tasks

Split a plan's execution into ordered tasks, each its own file next to the plan.
The audience is a junior engineer: write each task so one can pick it up and execute it in parallel with peers working other tasks, without needing this conversation or constant coordination.
Every task carries its own acceptance criteria, test plan, and self-validation loop, so the engineer can prove their own work is done before handing it on.

Input: an existing `.dev/{plan-name}/plan.md`.
Output: `task_1.md`, `task_2.md`, ... plus a task index in the plan's Execution section.

## Before writing tasks

- **Find the plan.** If the user named one, use it. Otherwise use the only plan directory with no `task_N.md` files yet. If more than one is a plausible match, or none is (every plan is already split, or none exists), ask which plan rather than guessing.
- **Re-running on an already-split plan is an update, not a fresh split.** Read the existing `task_N.md` files first, diff them against the current plan, and add or supersede only what changed (see "Numbering and updates"). Never blindly append a duplicate set starting from index 1.
- **Discover the repo's real commands.** Before writing any self-validation loop, establish the actual test and typecheck invocations from `package.json` scripts, a `Makefile`, `pyproject.toml`/`pytest.ini`, `go.mod`, the CI config, or equivalent. If you cannot determine them, stop and ask the user - never guess `npm test` into a `pytest` repo.

## Sizing tasks

- Vertical slice: a verifiable piece of behavior, not a horizontal layer (all models, then all endpoints).
- Sized to hand to `implement` as a standalone spec, completed in one sitting.
- INVEST: independent where possible, negotiable in detail, valuable on its own, estimable, small, testable at its seam. Quick check: can you demo it working by itself?
- Parallelizable: prefer splits where two engineers can work different tasks at once without editing the same files. When tasks must touch shared files, say so in `Depends on` so they are sequenced, not collided.
- Order so each task builds only on tasks before it.
- If the plan honestly fits in one task, say so - don't split artificially; `to-plan` embeds it directly.
- No catch-all tasks ("cleanups", "remaining items"); leftover work belongs to a real task or goes back to the plan as a scope decision.
- Unknowns that block estimation mean the task is too big or vague: split it, or make the first task a spike whose deliverable is the knowledge needed to plan the rest.

## Writing the task

- Title: a verb-led imperative completing "to finish this task, I need to {title}" ("Add one-click rollback to the deploy UI", not "Rollback work") - keeps the task index scannable.
- Self-contained: the implementer must not need this conversation. Decisions reached in discussion get written into the file, not left in chat.
- User-story framing ("As a [user], I want [goal], so that [benefit]") only for user-facing value; technical work reads better as a plain imperative. An empty "so that" means you forced it.
- A defect task's Goal includes numbered reproduction steps, expected vs actual, and environment, so the implementer can reproduce before fixing.

## Numbering and updates

Number from 1.
If task files already exist for this plan, continue from the highest index - never renumber or overwrite an existing task.
When the plan changes so an existing task no longer matches it, don't edit the task silently: add a `Superseded by task_N` line under its title, write the replacement as a new task, and mark the old row superseded in the index. This keeps the index and the files honest about what is still live.

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

## Files touched

Concrete files to change. If this task updates a README or user-facing doc, list it here too.

## Suggested seams

The public interfaces where tests should live - proposals; `implement` confirms them with the user.

## Acceptance criteria

2-5 checkable statements from an independent source of truth (spec or plan), not the intended implementation.
Each line is tagged with the test layer it belongs at: `- [unit|integration|e2e] Given... When... Then...`.
The layers, inlined so this task stands alone: **unit** is business logic in isolation, no I/O; **integration** is a real seam between two or more components this codebase owns, no outside world; **e2e** drives the actual running application against a realistic scenario.
The tag lets `implement` turn each criterion into a concrete test at the right layer instead of a prose-only check.
Cover error and edge cases, not just the happy path.
More than 5 means split the task.
Task done is not plan done - Success criteria are judged at review.

## Test plan

How each acceptance criterion becomes a real test, concretely enough that a junior engineer writes it without guessing:

| Criterion | Test to add (seam + scenario) | Fixtures / setup needed |
| --------- | ----------------------------- | ----------------------- |

- One row per acceptance criterion, in the same order; the layer already lives on the criterion's tag, so it is not repeated here.
- Name the edge and error scenarios to cover, not just the happy path.
- Call out any setup a junior wouldn't know to build: a fake at a boundary, a seeded record, a running dependency, sample input files.

## Self-validation loop

The exact loop the engineer runs to prove this task is done, before handing it on and without waiting for a reviewer.
Use the repo's real commands (discovered in "Before writing tasks"), copy-pasteable, not placeholders:

1. Run the task's tests and typecheck with this repo's actual invocations, not a guessed default.
2. Green means every acceptance criterion has a passing test at its tagged layer, and the existing suite still passes.
3. If anything is red, fix it and repeat from step 1 - the task is not done until the loop passes clean.

## Depends on

Task numbers this builds on, or "None". Tag each with a one-word reason: `interface` (needs the other task's API or behavior) or `files` (edits the same files, so it must be sequenced to avoid a collision). Only real `interface` and `files` dependencies belong here - anything else keeps tasks parallelizable.
```

## Updating the plan

After writing the tasks, add an index to the plan's Execution section:

```markdown
| Task | Title | Depends on | Status |
| ---- | ----- | ---------- | ------ |
| [task_1.md](task_1.md) | ... | None | active |
```

`Depends on` carries the same one-word reason each task file uses; two tasks that don't chain through it (and don't share files) run in parallel. `Status` is `active` or `superseded by task_N`.

The task index is the deliverable a human scans; the task files are the specs the factory executes.
This skill does not re-render the plan's HTML view - that view is `to-plan`'s approach-review surface, and the task split is implementation detail, not a new thing to review in the browser.

## Verify the split

Before finishing, check the decomposition holds together - a silently dropped scope item is the most common failure here:

- Every In item of the plan's Scope maps to at least one active task; nothing in scope is left unclaimed.
- Every task's acceptance criteria trace back to the plan's Success criteria or Scope; no task invents work the plan never asked for.
- The `Depends on` graph is acyclic, and every pair of tasks that touch a shared file has an ordering declared between them.

If any check fails, fix the split before writing the index - do not ship a decomposition with a hole in it.
