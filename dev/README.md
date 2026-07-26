# dev

Development workflow skills for Claude Code.
The skills chain into one flow: `/install` initializes the standing `docs/` knowledge base, `/to-plan` produces a reviewable plan, `/to-tasks` splits it into task files when needed, `/implement` executes a task test-first, and `/to-review` verifies the result against the plan.
`/to-human-plan` and `/to-human-docs` sit alongside that chain, turning a plan or the whole `docs/` tree into an interactive HTML artifact for human review - never markdown scrolling, never committed to the repo.
Every skill is human-triggered (`disable-model-invocation: true`); skills recommend the next step but never launch each other.

## Skills

### install

Creates the standing `docs/` knowledge base: product (with non-goals and glossary), architecture (with one-file-per-decision ADRs), engineering, operations, governance, and `docs/agents.md` with a root `AGENTS.md` pointer.
The bundled init script is idempotent; it never overwrites existing files.
If a `docs/` directory already exists and isn't one this skill produced, it's moved to `docs-old/` first so nothing is lost, and the skill migrates its knowledge into the new structure before offering to delete it.
On an existing codebase it populates what the code can prove (stack, conventions, architecture, tests, operations), then closes every remaining gap with you through focused question rounds, so no doc is ever left half-finished; anything you defer is tracked under Potential improvements in `docs/backlog.md` instead of living as open questions inside the docs.
On a new project the stubs fill up through the normal plan/implement/review loop: every plan's Documentation impact table checks these docs, and reviews block on missed rows.

### to-plan

Turns a feature request, spec, or problem statement into a plan for human review at `docs/plan/{plan-name}/plan.md`.
The plan describes the current state, the proposed approach as a before/after picture, and an explicit table of every doc that needs updating.
If execution spans multiple tasks it recommends `/to-tasks`; otherwise the execution detail is embedded directly in the plan.
Invoke it explicitly with `/to-plan`; it never implements anything.

### to-tasks

Splits an existing plan into `docs/plan/{plan-name}/task_1.md`, `task_2.md`, and so on, plus a task index in the plan.
Each task is a vertical slice sized to hand to `/implement` as a standalone spec, with scope, suggested seams, and acceptance criteria.
Normally run right after `/to-plan`, but can be used directly on an existing plan.

### implement

Implements a piece of work based on a spec or set of tickets, test-first.
When the input is a plan with multiple task files, it runs every task in dependency order, back to back, without stopping in between - review only happens once, after everything is done.
The skill drives a strict TDD loop at pre-agreed seams:

1. Read the spec, tickets, or plan (with all its tasks) and explore the codebase.
2. Per task: agree the seams under test with the user, implement in vertical slices with the red -> green loop, typecheck and run single test files regularly, run the full suite once at the end, and commit.
3. Once every task is done, hand the work back to you to run `/to-review`.

The skill bundles reference docs on what makes a good test (`references/tests.md`) and when mocking is appropriate (`references/mocking.md`).
Invoke it explicitly with `/implement` and point it at a spec or tickets.
Model-triggered invocation is disabled; the workflow commits code, so it only runs when you ask for it.

### to-review

Reviews a branch or PR with a panel of concern-focused agents (correctness, security, architecture, tests, and more), selected per diff rather than launched blindly.
Every non-trivial finding is adversarially verified against the repo before it is reported, so the report contains confirmed problems instead of plausible guesses.
When a plan exists it also checks conformance: acceptance criteria met, tests at the agreed seams, and every Documentation impact row honored.
The report lands at `docs/plan/{plan-name}/review_N.md`, and accepted findings can be turned into new task files via `to-tasks`.
Invoke it explicitly with `/to-review`; model-triggered invocation is disabled, so a review panel never launches unless you ask for it.

### to-human-plan

Renders an existing plan (`docs/plan/{plan-name}/plan.md` and its tasks) as a single self-contained interactive HTML file: Goal and Context at the top, a file dependency graph sized and colored by blast radius (including consumers outside the repo), a walkable timeline that highlights each step's files as it lands, and steps you can flag with an inline question, compiled into a copyable review-notes block.
Saved to `~/tmp/{project-slug}/reports/{plan-name}.html`, never inside the repo.
Requires a plan already produced by `/to-plan`; it visualizes a plan, it doesn't write one.

### to-human-docs

Renders the whole `docs/` tree as a single self-contained interactive HTML map: docs clustered by area with cross-references, a decisions timeline, plan status with success criteria and review verdicts, and the open backlog - all searchable, click any doc for its full content inline.
Saved to `~/tmp/{project-slug}/reports/docs-map.html`, never inside the repo.
Requires a `docs/` tree already produced by `/install`; it's a snapshot, regenerate it after the docs change.

## Installation

```bash
/plugin marketplace add ~/ws/skills
/plugin install dev@nurbot
```
