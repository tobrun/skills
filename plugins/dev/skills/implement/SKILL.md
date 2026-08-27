---
name: implement
description: Execute the change sets of a spec at .dev/{plan-name}/spec.md, proving every scenario with a test at its tagged layer across unit/integration/e2e, running independent change sets in parallel and looping until every change set is done and the e2e suite passes. Use when the user asks to implement a spec or its change sets.
---

# Implement

Execute every change set of a spec, proving each `tests:` scenario with a real test at its tagged layer, until all change sets are done and the e2e run is green.

Input: `.dev/{plan-name}/spec.md` (from `decision-spec`), located per [../../references/plan-layout.md](../../references/plan-layout.md).
If there is no `spec.md` or its change plan is empty, ask the user to run `decision-spec` first; without one there are no layer-tagged scenarios to implement against.

Read [references/layers.md](references/layers.md), [references/tests.md](references/tests.md), and [references/mocking.md](references/mocking.md) before starting, and keep consulting them during every cycle, not after.

## Workflow

1. Read `spec.md` in full: the research section (the decisions and their rationale), the scope section (including its Validation block of real repo commands), and the change plan. Explore the relevant code. If the Validation block is absent, discover the repo's real test and typecheck commands yourself from `package.json`, a `Makefile`, or CI config, and log them in `implementation-notes.md`.
2. Build waves by consecutive-disjoint batching per [references/parallel.md](references/parallel.md): sequential in spec order by default, batched only when file lists are disjoint and nothing a wave-mate introduces is consumed. Every change set in the plan is in scope, not just the first.
3. For each wave, run its change sets in parallel per [references/parallel.md](references/parallel.md), then commit each finished change set on the current branch and append its entry to `implementation-notes.md`.
4. Move straight to the next wave. Never stop after one change set or wave to ask about review.
5. When every change set is committed, run the full e2e pass per "The e2e layer" below over the whole spec, and loop on failures until it is green.
6. After the e2e report, follow the "Jira sync and pull request" rules below.
   Only then suggest the follow-ups, never launching either yourself:
   `to-harden` for the deterministic quality gauntlet (dependency rules,
   complexity scoring, mutation testing), and `to-review` on the full body of
   work. Point the review at `implementation-notes.md` and the
   `{plan-name}-e2e-report.html`.

## Jira sync and pull request

Read `.dev/config.json`; when `jira.enabled` is true, read
`../../references/jira.md` before the first `acli` call and follow its
persistence-and-timing rules: the orchestrator alone invokes `acli` (subagent
prompts and the `parallel.md` contract do not change), and any Jira failure
stops and asks the user how to proceed.

On every run, ask exactly: "push and open the PR?" and act only on a yes: if
on the default branch, create a work branch first, and with Jira enabled put
the Epic key at the start of the branch name and PR title. With an absent or
disabled config, perform no Jira behavior or mention, but still ask the PR
question.

## The change-set loop

Each change set, whether you run it yourself or a subagent runs it, follows the same loop:

- Test at the seams the spec's scope section declares: the seam for a scenario is the public boundary its input crosses. If the scope's boundary is wrong or missing, pick the nearest real public boundary, implement against it, and log the change under Deviations - do not stall on it.
- Implement in **vertical slices**: one scenario's behavior at a time, its test written before or right after the code - the enforced outcome is what matters, not the ritual order. Each `tests:` scenario's test lives at its tagged layer ([references/layers.md](references/layers.md)); a scenario isn't met until a real test exists there.
- **Bug fixes are the exception: strictly test-first.** A defect change set starts with a failing test that reproduces the reported issue - red is the proof the bug was actually reproduced and understood; only then fix, and watch that same test go green.
- Run the change set's own tests and typecheck continuously; once the change set is green, run the spec's Validation block verbatim - it is the wider suite plus typecheck/lint - and only report done when it passes clean.

## Rules of the loop

- **Every test must have been seen red.** A test that has never failed proves nothing: earn its green by writing it before the code, or by briefly breaking the behavior once after. For defect work this collapses back to strict red-first, per the loop above.
- **One slice at a time.** One seam, one behavior, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to `to-review`.
- **Keep going.** A red test, a failing e2e scenario, or an edge case that contradicts the spec is work to do, not a reason to hand back. Fix it, log the deviation, continue. Stop early only when a blocking question makes further work unsafe or wasted.

## The e2e layer

E2E scenarios are proven by running the actual application against a **fully mocked environment**: real built artifact, real internal wiring, no real external world - see [references/mocking.md](references/mocking.md#the-e2e-environment). Run this once per spec, after all change sets are committed, covering every `[e2e]` scenario across change sets.

1. **Launch the app.** Invoke an installed `run` skill with the mocked environment configured when the host supports direct skill invocation. Otherwise inspect the repository's documented commands and start the app directly. Ask the user only when no safe launch command can be determined.
2. **Drive it and capture evidence**, per scenario:
   - `kind: "frontend"` - use available browser automation (the host browser integration or Playwright) to exercise the scenario, one screenshot per meaningful step, embedded as a base64 data URI.
   - `kind: "non-frontend"` - capture the entity's real before/after state from the run's own output or fixtures.
3. **Never fabricate a screenshot or a data-model-state entry.** Both come from this actual run.
4. **Loop until green.** A failed scenario is a bug: diagnose it, fix the code (a new red-green cycle at the right layer), re-run and re-capture that scenario. Never flip a status to pass without a fresh capture. If a scenario fails three times on the same root cause, write what you found into Deviations and ask the user before continuing.
5. Map the results onto `E2E_DATA` per [references/e2e-report.md](references/e2e-report.md) and render `templates/e2e-report.html` to `/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`, opening and publishing per [../../references/reporting.md](../../references/reporting.md).

## Implementation notes

Maintain `.dev/{plan-name}/implementation-notes.md`, appended after each change set completes, never written once at the end.
It is the shared state across waves - parallel change-set agents can't see each other's conversation, only this file and the code - and the evidence `to-review`, `to-pitch`, and `to-quiz` read later.

```markdown
## Change set {n}: {title}
- What was done: ...
- Seams tested: ...
- Deviations from spec: {edge case found} -> conservative choice made: {what/why}   # only when a deviation occurred
```

This file is a short running log, not a rendered report.

## Anti-patterns

- **Implementation-coupled** - mocks internal collaborators, tests private methods, or verifies through a side channel. Tell: breaks on refactor even when behavior hasn't changed.
- **Tautological** - the assertion recomputes the expected value the way the code does, so it can never disagree with the code. Expected values need an independent source: a literal, a worked example, the spec.
- **Horizontal slicing** - all tests first, then all implementation. Tests then verify an imagined shape and go insensitive to change.
- **Top-heavy testing** - proving business rules through slow browser or CLI runs because that path is already wired. Push each check down to the cheapest layer that can fail for the right reason ([references/layers.md](references/layers.md)).
