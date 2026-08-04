---
name: implement
description: Execute the tasks of a plan at .dev/{plan-name}/, test-first across unit/integration/e2e, running independent tasks in parallel and looping until every task is done and the e2e suite passes. Use when the user asks to implement a plan or its tasks, work through task files, or wants red-green TDD with an e2e report.
disable-model-invocation: true
---

# Implement

Execute every task of a plan, test-first, at the layer each acceptance criterion is tagged with, until all tasks are done and the e2e run is green.

Input: `.dev/{plan-name}/plan.md` with `task_N.md` files (from `to-plan` and `to-tasks`).
If the user didn't name a plan, find it yourself: match the current branch to a `.dev/{plan-name}/` slug, or take the only plan whose tasks aren't all done. Ask only if more than one is plausible.
If there are no task files, ask the user to run `to-tasks` first; a plan without tasks has no layer-tagged criteria to implement against.

Read [references/layers.md](references/layers.md), [references/tests.md](references/tests.md), and [references/mocking.md](references/mocking.md) before starting, and keep consulting them during every cycle, not after.

## Workflow

1. Read `plan.md`, its Execution index, and every `task_N.md`. Explore the relevant code.
2. Build waves from the `Depends on` graph: a wave is the set of tasks whose dependencies are all committed. Every task in the index is in scope, not just the first.
3. For each wave, run its tasks in parallel per [references/parallel.md](references/parallel.md), then commit each finished task on the current branch and append its entry to `implementation-notes.md`.
4. Move straight to the next wave. Never stop after one task or wave to ask about review.
5. When every task is committed, run the full e2e pass per "The e2e layer" below over the whole plan, and loop on failures until it is green.
6. After the e2e report, ask exactly "push and open the PR?" and follow the
   Jira sync and pull request rules below. Only then ask the user to run
   `to-review` on the full body of work - reviews are human-triggered, never
   launch the panel yourself. Point it at `implementation-notes.md` and the
   `{plan-name}-e2e-report.html`.

## Jira sync and pull request

Read `.dev/config.json`; when `jira.enabled` is true, read
`../../references/jira.md` before the first `acli` call. Discover transition
names, then the orchestrator transitions the persisted Epic to In Progress at
run start. The orchestrator alone transitions each task issue to In Progress
when dispatching its wave and to Done after verification and commit. Subagents
never invoke `acli`, and their prompts and the `parallel.md` contract do not
change. Any Jira failure stops and asks the user how to proceed.

On every run, ask exactly: "push and open the PR?" Do not push or open a PR
without a yes. On yes, if on the default branch, create a work branch,
including the Epic key when Jira is enabled, then push and open the PR. With
Jira enabled, put the Epic key at the start of the branch name and PR title. On
no, do not push or open a PR. With an absent or disabled config, perform no
Jira behavior or mention, but still ask the PR question.

## The task loop

Each task, whether you run it yourself or a subagent runs it, follows the same loop:

- Test at the seams the task's `Suggested seams` names. If a suggested seam is wrong or missing, pick the nearest real public boundary, implement against it, and log the change under Deviations - do not stall on it.
- Implement in **vertical slices**: one failing test -> minimal code to pass it -> repeat. Each criterion's test lives at its tagged layer ([references/layers.md](references/layers.md)); a criterion isn't met until a real test exists there.
- Run the task's own tests and typecheck continuously; run the wider suite once the task is green.
- Run the task's `Self-validation loop` verbatim and only report done when it passes clean.

## Rules of the loop

- **Red before green.** Failing test first, then only enough code to pass it.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to `to-review`.
- **Keep going.** A red test, a failing e2e scenario, or an edge case that contradicts the plan is work to do, not a reason to hand back. Fix it, log the deviation, continue. Stop early only when a blocking question makes further work unsafe or wasted.

## The e2e layer

E2E criteria are proven by running the actual application against a **fully mocked environment**: real built artifact, real internal wiring, no real external world - see [references/mocking.md](references/mocking.md#the-e2e-environment). Run this once per plan, after all tasks are committed, covering every `[e2e]` criterion across tasks.

1. **Launch the app.** Invoke an installed `run` skill with the mocked environment configured when the host supports direct skill invocation. Otherwise inspect the repository's documented commands and start the app directly. Ask the user only when no safe launch command can be determined.
2. **Drive it and capture evidence**, per scenario:
   - `kind: "frontend"` - use available browser automation (the host browser integration or Playwright) to exercise the scenario, one screenshot per meaningful step, embedded as a base64 data URI.
   - `kind: "non-frontend"` - capture the entity's real before/after state from the run's own output or fixtures.
3. **Never fabricate a screenshot or a data-model-state entry.** Both come from this actual run.
4. **Loop until green.** A failed scenario is a bug: diagnose it, fix the code (a new red-green cycle at the right layer), re-run and re-capture that scenario. Never flip a status to pass without a fresh capture. If a scenario fails three times on the same root cause, write what you found into Deviations and ask the user before continuing.
5. Map the results onto `E2E_DATA` per [references/e2e-report.md](references/e2e-report.md), copy `templates/e2e-report.html` to `/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`, and replace only the data block.
6. **Open the report locally** with the host's browser integration when available; otherwise give the user a clickable local path. Offer to publish it with an available artifact-publishing tool if they want a shareable link. Only publish when they say yes; if the host has no publisher, keep the local report as the deliverable.

## Implementation notes

Maintain `.dev/{plan-name}/implementation-notes.md`, appended after each task completes, never written once at the end.
It is the shared state across waves - parallel task agents can't see each other's conversation, only this file and the code - and the evidence `to-review`, `to-pitch`, and `to-quiz` read later.

```markdown
## Task {n}: {title}
- What was done: ...
- Seams tested: ...
- Deviations from plan: {edge case found} -> conservative choice made: {what/why}   # only when a deviation occurred
```

This file is a short running log, not a rendered report.

## Anti-patterns

- **Implementation-coupled** - mocks internal collaborators, tests private methods, or verifies through a side channel. Tell: breaks on refactor even when behavior hasn't changed.
- **Tautological** - the assertion recomputes the expected value the way the code does, so it can never disagree with the code. Expected values need an independent source: a literal, a worked example, the plan.
- **Horizontal slicing** - all tests first, then all implementation. Tests then verify an imagined shape and go insensitive to change.
- **Top-heavy testing** - proving business rules through slow browser or CLI runs because that path is already wired. Push each check down to the cheapest layer that can fail for the right reason ([references/layers.md](references/layers.md)).
