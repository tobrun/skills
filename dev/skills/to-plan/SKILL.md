---
name: to-plan
description: Turn a feature request, spec, or problem statement into a reviewable plan at docs/plan/{plan-name}/plan.md, including an explicit list of docs to update. Use when the user wants work planned before implementation.
disable-model-invocation: true
---

# To Plan

Turn the user's request into a written plan that a human can review before any implementation starts.
The plan is the deliverable of this skill: do not implement anything.

## Workflow

1. Understand the request.
   Read the spec or tickets and explore the relevant code.
   If the repo has standing docs, follow the read order in `docs/README.md`: at minimum the glossary, the non-goals, and the ADRs under `docs/architecture/decisions/` for the area you're touching.
2. Pick a plan name: a short kebab-case slug for the piece of work (e.g. `checkout-vat-rounding`).
   Name the outcome, not the activity: "self-serve-model-rollback" beats "rollback-work", and a title like "Ability to roll back a model in one click" beats "Create rollback".
3. Write the plan to `docs/plan/{plan-name}/plan.md` using the structure below.
4. Decide how execution splits:
   - If the work needs more than one task, recommend the user run the `to-tasks` skill to produce `task_N.md` files next to the plan.
     All skills in this plugin are human-triggered; never invoke it yourself.
   - If it fits in a single task, `to-tasks` is not needed; embed the execution detail directly in the plan's Execution section.
5. Stop and present the plan for human review: summarize the approach in a few sentences and surface the open questions.
   Do not start implementing; the follow-up is a reviewed plan handed to the `implement` skill.

## Plan structure

Use this template for `plan.md`:

```markdown
# Plan: {title}

## Goal

The outcome this work achieves and why, in the reviewer's terms.
An outcome is a measurable change in behavior of the system or its
users, not a list of activities. Where the work is a bet, state it
as a hypothesis: "We believe [change] will result in [outcome];
we will know when [measurable signal]."

## Success criteria

The 1-5 checkable statements that mean this plan is done.
Criteria measure the outcome, not the work: "p95 checkout latency
under 300ms" counts, "rollback endpoint implemented" does not.
Give baseline -> target where a number exists. The plan is complete
when these hold, not when every task file is closed.

## Scope

In: what this plan changes.
Out: what it deliberately does not; naming excluded work here
prevents sprawl better than any review.

## Current state

How the affected part of the system behaves today.
Name the concrete files, modules, and docs involved.

## Proposed approach

What changes, where, and how the system behaves afterwards.
Describe the before/after so a reviewer can picture the end state without reading code.
Call out alternatives you rejected and why, when the choice is not obvious.

## Documentation impact

| Doc | Change |
| --- | ------ |
| path/to/doc.md | What needs updating |

Every doc that needs updating, one row each.
If nothing needs updating, state "None" and why.
When the repo has a standing `docs/` tree, walk it area by area
(product, architecture, engineering, operations, governance,
agents.md): does this change alter what any of them claim?
If this plan makes an architectural decision, add a row proposing a
new ADR under docs/architecture/decisions/ (copy 0000-template.md
to the next free number).

## Risks and open questions

Known risks, assumptions, and the questions the reviewer must answer.

## Execution

Single task: the concrete steps, files touched, and acceptance criteria live here.
Multiple tasks: a task index produced by the to-tasks skill, one row per task file.
Either way, done means the Success criteria hold, not that the tasks are closed.
```

## Right-sizing

One outcome per plan.
A plan whose title could absorb unlimited work ("tech debt", "improvements", "misc fixes") is a category, not a plan; it has no outcome and never finishes.
If the work honestly spans several independent outcomes or months of effort, write several plans and say how they sequence.
And if tasks keep getting added to a plan without its goal changing, that is a discovery gap: stop and re-plan instead of letting the plan grow.

## Writing for review

The reviewer has not seen your exploration or this conversation.
The plan must stand alone: name concrete files and behaviors, not vague areas.
Prefer describing observable behavior changes over internal refactoring detail.
Keep the plan honest about uncertainty; an open question in the plan is cheaper than a wrong assumption in the code.
Never list auto-generated files (such as CHANGELOG.md) under documentation impact; they are not manually updated.
