# workflow

Development workflow skills for Claude Code.
The skills chain into one flow: `/to-plan` produces a reviewable plan, `to-tasks` splits it into task files when needed, and `/implement` executes a task test-first.

## Skills

### to-plan

Turns a feature request, spec, or problem statement into a plan for human review at `docs/plan/{plan-name}/plan.md`.
The plan describes the current state, the proposed approach as a before/after picture, and an explicit table of every doc that needs updating.
If execution spans multiple tasks it uses the `to-tasks` skill; otherwise the execution detail is embedded directly in the plan.
Invoke it explicitly with `/to-plan`; it never implements anything.

### to-tasks

Splits an existing plan into `docs/plan/{plan-name}/task_1.md`, `task_2.md`, and so on, plus a task index in the plan.
Each task is a vertical slice sized to hand to `/implement` as a standalone spec, with scope, suggested seams, and acceptance criteria.
Normally invoked from `to-plan`, but can be used directly on an existing plan.

### implement

Implements a piece of work based on a spec or set of tickets, test-first.
The skill drives a strict TDD loop at pre-agreed seams:

1. Read the spec or tickets and explore the codebase.
2. Agree the seams under test with the user.
3. Implement in vertical slices with the red -> green loop.
4. Typecheck and run single test files regularly; run the full suite once at the end.
5. Review the work with the `code-review` skill.
6. Commit to the current branch.

The skill bundles reference docs on what makes a good test (`references/tests.md`) and when mocking is appropriate (`references/mocking.md`).

Invoke it explicitly with `/implement` and point it at a spec or tickets.
Model-triggered invocation is disabled; the workflow commits code, so it only runs when you ask for it.

## Installation

```bash
/plugin marketplace add ~/ws/skills
/plugin install workflow@tobrun-skills
```
