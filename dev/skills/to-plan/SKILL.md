---
name: to-plan
description: Turn a feature request, spec, or problem statement into a reviewable plan at docs/plan/{plan-name}/plan.md, including an explicit list of docs to update. Use when the user wants work planned before implementation.
disable-model-invocation: true
---

# To Plan

Turn the user's request into a written plan for human review before any implementation starts.
The plan is the deliverable: do not implement anything.

## Workflow

1. Read the spec or tickets and explore the relevant code.
   If the repo has standing docs, follow the read order in `docs/README.md`: at minimum the glossary, non-goals, and ADRs for the area you're touching.
2. Pick a plan name: a kebab-case slug naming the outcome, not the activity (`self-serve-model-rollback`, not `rollback-work`).
3. Write the plan to `docs/plan/{plan-name}/plan.md` using the structure below.
4. If execution needs more than one task, recommend the user run `to-tasks`; never invoke it yourself.
   If it fits in one task, embed the execution detail directly in the plan's Execution section.
5. Stop and present the plan for review: summarize the approach and surface open questions.
   Do not implement; the follow-up is a reviewed plan handed to `implement`.

## Plan structure

Use this template for `plan.md`:

```markdown
# Plan: {title}

## Goal

The outcome this work achieves and why, in the reviewer's terms.
An outcome is a measurable change in behavior, not a list of activities.
For a bet, state it as a hypothesis: "We believe [change] will result in [outcome]; we will know when [measurable signal]."

## Success criteria

1-5 checkable statements that mean this plan is done, measuring the outcome (not the work: "p95 checkout latency under 300ms", not "endpoint implemented").
Give baseline -> target where a number exists.
Done means these hold, not that every task is closed.

## Scope

In: what this plan changes.
Out: what it deliberately does not - naming exclusions here prevents sprawl.

## Current state

How the affected part of the system behaves today.
Name the concrete files, modules, and docs involved.

## Proposed approach

What changes, where, and how the system behaves afterwards.
Describe the before/after so a reviewer can picture the end state without reading code.
Call out rejected alternatives when the choice isn't obvious.

## Documentation impact

| Doc | Change |
| --- | ------ |
| path/to/doc.md | What needs updating |

One row per doc; state "None" and why if nothing needs updating.
Walk the standing `docs/` tree area by area if it exists - does this change alter what any area claims?
Making an architectural decision adds a row proposing a new ADR (copy `0000-template.md` to the next free number).

## Risks and open questions

Known risks, assumptions, and questions the reviewer must answer.

## Execution

Single task: steps, files, and acceptance criteria live here.
Multiple tasks: the task index from `to-tasks`, one row per file.
Either way, done means Success criteria hold, not that tasks are closed.
```

## Right-sizing

One outcome per plan.
A plan whose title could absorb unlimited work ("tech debt", "improvements") is a category, not a plan - it never finishes.
Work spanning several independent outcomes becomes several sequenced plans.
Tasks accreting without the goal changing is a discovery gap: stop and re-plan.

## Writing for review

The reviewer hasn't seen your exploration or this conversation - the plan must stand alone.
Name concrete files and behaviors, not vague areas; prefer observable behavior changes over refactoring detail.
An open question in the plan is cheaper than a wrong assumption in the code.
Never list auto-generated files (e.g. CHANGELOG.md) under documentation impact.
