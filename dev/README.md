# dev

Development workflow skills for Claude Code, built around two ideas: layered tests are the enforceable spec for behavior, and every phase produces something a human actually reviews as HTML, not markdown scrolling.

The skills chain loosely rather than as a rigid pipeline: `/discover` runs whichever pre-implementation moves (blind spot pass, brainstorm/prototype, interview) a given request actually needs, or none at all; `/to-plan` produces a reviewable plan; `/to-tasks` splits it into tasks with acceptance criteria tagged by test layer; `/implement` executes those tasks test-first across unit/integration/e2e, in parallel waves where dependencies allow, keeping a running implementation-notes log; `/to-review` verifies the result with a fan-out panel that checks e2e coverage and logged deviations; `/to-pitch` and `/to-quiz` turn finished work into a buy-in doc or a comprehension check.
There is no standing knowledge base to maintain: the code, its tests, and the active plan under `.dev/{plan-name}/` are the only durable context.
Every producing skill renders its own output as a self-contained HTML artifact and publishes it, so plans, discovery notes, e2e reports, reviews, pitches, and quizzes are all shareable links, not local-only files.
Every skill is human-triggered (`disable-model-invocation: true`); skills recommend the next step but never launch each other, except `implement`/`to-pitch` invoking the separate, already-installed `run` skill directly to launch the app for e2e/demo capture - that utility sits outside this plugin's human-triggered family.

## Skills

### discover

Runs the pre-implementation moves that reduce unknowns before a plan is worth writing: a blind spot pass over unfamiliar territory, a brainstorm/prototype pass (with cheap HTML mockups) when the shape isn't decided, and a one-question-at-a-time interview for ambiguities that would change architecture.
Picks only the modes a real signal points to, in whatever order and combination the situation needs, and says so plainly when none apply.
Publishes a discovery artifact plus a plain-markdown companion that `/to-plan` reads back in directly.

### to-plan

Turns a feature request, spec, or problem statement into a plan for human review at `.dev/{plan-name}/plan.md`, reading a prior `/discover` pass's notes when one exists.
The plan describes the current state and the proposed approach as a before/after picture.
Every run publishes `{plan-name}.html` as an Artifact - a walkable timeline with a blast-radius file graph.
If execution spans multiple tasks it recommends `/to-tasks`; otherwise the execution detail is embedded directly in the plan.

### to-tasks

Splits an existing plan into `.dev/{plan-name}/task_1.md`, `task_2.md`, and so on, plus a task index in the plan.
Each task is a self-contained vertical slice a junior engineer can execute in parallel with peers: acceptance criteria tagged by test layer (`[unit|integration|e2e]`), a test plan mapping each criterion to a concrete test, and a self-validation loop built from the repo's real commands to prove the task is done before handoff.
It verifies the split covers every plan scope item before finishing, and does not re-render the plan view - that stays `to-plan`'s approach-review surface.

### implement

Executes a plan's task files test-first, at the layer each acceptance criterion is tagged with - unit for business logic, integration for real cross-component seams, e2e for driving the actual running application.
Runs independent tasks in parallel as waves of subagents derived from the tasks' `Depends on` graph, committing each task and appending to a running `implementation-notes.md` that logs any deviations forced by an edge case.
Once every task is committed, drives the real app (via the `run` skill) against a mocked environment, loops until every e2e scenario passes, then opens the e2e report in the browser and publishes it as an Artifact: screenshots per scenario for frontend systems, Test Scenario and Data Model State tables for everything else.

### to-review

Reviews a branch or PR with a panel of concern-focused agents, selected per diff.
Every non-trivial finding is adversarially verified against the repo.
Checks plan conformance, including whether `[e2e]`-tagged criteria have a passing scenario in the e2e report and whether logged deviations still satisfy Success criteria.
Publishes `review_N.html` as an Artifact alongside the `review_N.md` file - the artifact meant to be handed to a reviewer.

### to-pitch

Packages a finished plan, its prototype, implementation notes, and e2e evidence into one shareable buy-in doc: demo first, then why, what changed, how it was verified, and how to try it. Purely presentational, published as an Artifact.

### to-quiz

Renders a context/intuition/what-was-done report with a graded comprehension quiz, published as an Artifact.
Cannot enforce a merge gate - Claude Code has no hook into a PR's merge button - so it says so plainly and produces an honest pass/fail check instead.

## Installation

```bash
/plugin marketplace add ~/ws/skills
/plugin install dev@nurbot
```
