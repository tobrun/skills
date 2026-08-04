# Parallel Execution

`to-tasks` already sized tasks so peers can work them at once and recorded every ordering constraint in `Depends on`.
This file is how to cash that in: you are the orchestrator, subagents are the implementers.

## Waves

Group the tasks into waves from the `Depends on` graph:

- Wave 1 = every task with `Depends on: None`.
- Wave N+1 = every task whose dependencies are all committed.

Run all tasks in a wave concurrently, then commit them, then start the next wave.
Do not start a task whose dependency is still in flight, even if it looks unrelated - `Depends on` is also how `to-tasks` sequences tasks that touch shared files.

## Launching a wave

Launch one `Agent` per task, **all in a single message** so they run concurrently.
A wave of one task needs no subagent: implement it yourself in the main thread.

Each agent prompt contains:

1. The role: `You implement exactly one task of a plan. Other agents implement sibling tasks concurrently; stay inside your task's Files touched.`
2. Absolute paths to its `task_N.md`, the `plan.md`, and this skill's `layers.md`, `tests.md`, and `mocking.md` - the agent reads them itself rather than receiving them inlined.
3. The task loop and the loop rules from `SKILL.md`, verbatim.
4. Hard constraints:
   - Implement only this task's `[unit]` and `[integration]` criteria. `[e2e]` criteria are run once per plan by the orchestrator afterwards - do not launch the app.
   - Do not commit, stage, or touch git state. The orchestrator commits.
   - Do not edit files outside your task's `Files touched` list. If the task genuinely needs a file another task owns, stop and report it as a conflict instead of editing it.
   - Do not edit `implementation-notes.md`. Report your entry; the orchestrator appends it.
   - Run the task's `Self-validation loop` and report its real result. A red result is a fact to report, not something to hide or paper over.
5. The output contract below.

Output contract (the agent's final message must be exactly one fenced JSON block):

```json
{
  "task": 3,
  "status": "done | blocked",
  "whatWasDone": "2-4 lines",
  "seamsTested": ["..."],
  "testsAdded": ["path::test name"],
  "deviations": ["edge case found -> conservative choice made: what/why"],
  "selfValidation": { "commands": ["..."], "result": "pass | fail", "output": "the tail that matters" },
  "conflicts": ["file another task owns that this task needed"]
}
```

## After a wave

For each returned task, in task-number order:

1. Verify rather than trust the report: run the task's self-validation commands yourself, plus the wider suite once per wave.
2. Commit the task's work on the current branch, one commit per task.
3. Append the task's entry to `implementation-notes.md` from `whatWasDone`, `seamsTested`, and `deviations`.

A `status: blocked` task, a failing self-validation, or a reported conflict is yours to finish in the main thread before the next wave starts - do not carry a red task forward and do not relaunch the same agent on the same failure more than once.
If two tasks in a wave edited the same file anyway, reconcile it yourself and log it under Deviations.

## When not to parallelize

- The plan has one task, or every task depends on the one before it: run them sequentially yourself.
- The wave's tasks visibly overlap in `Files touched` despite `Depends on: None`: treat that as a `to-tasks` sizing miss, run them sequentially, and note it in `implementation-notes.md`.
