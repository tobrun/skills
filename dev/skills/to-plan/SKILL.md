---
name: to-plan
description: Turn a feature request, spec, or problem statement into a reviewable plan at .dev/{plan-name}/plan.md. Use when the user wants work planned before implementation.
disable-model-invocation: true
---

# To Plan

Turn the user's request into a written plan for human review before any implementation starts. The plan is the deliverable: do not implement anything. 

## Workflow

1. Read the request or spec and explore the relevant code, the tests, and the current behavior directly - the code and its test suite are the source of truth for how the system works today. Check `~/tmp/{project-slug}/reports/` for a `*-discovery-notes.md` from a prior `discover` run matching this request's topic; if one exists, read it first and treat its answers as settled inputs, not open questions to re-litigate.
2. Interview the user before writing anything - see "Interview the user" below. This is where the real unknowns get resolved; a plan written without it is a guess.
3. Pick a plan name: a kebab-case slug naming the outcome, not the activity (`self-serve-model-rollback`, not `rollback-work`). Reuse `discover`'s topic-slug when one was handed off.
4. Write the plan to `.dev/{plan-name}/plan.md` using the structure below, folding in what the interview settled.
5. Render the plan view locally and open it in the browser - see "Render and review locally" below. Do not publish it as an Artifact automatically.
6. If execution needs more than one task, recommend the user run `to-tasks`; never invoke it yourself. If it fits in one task, embed the execution detail directly in the plan's Execution section.
7. Stop and present the plan for review: point the user at the plan view now open in their browser, note the local `plan.md` path, and name any assumption you proceeded on. Offer to publish the view as a shareable Artifact if they want to hand it to someone else, but only publish when they say yes. Do not implement; the follow-up is a reviewed plan handed to `implement`.

## Jira sync

Before the interview, read `.dev/config.json`. If `jira.enabled` is true, read
`../../references/jira.md` before the first `acli` call. List open Initiatives
in the configured project and add an interview question asking the user to
choose one. If none exists, stop with a clear message; do not create one.
After writing `plan.md`, create and verify one Epic linked to the chosen
Initiative, then persist `Jira: {KEY}` under the plan title. Any Jira failure
stops the skill and asks the user how to proceed. With an absent or disabled
config, skip all Jira behavior and mentions.

## Interview the user

A plan is only as good as the unknowns it resolves before implementation starts.
After exploring, interview the user with the `AskUserQuestion` tool about anything the plan genuinely turns on that you cannot answer yourself: technical implementation choices, data model and API shape, UI and UX, edge cases, concerns, and tradeoffs.

- Ask non-obvious questions only. If you have a clear recommendation and are almost certain it is right, propose it in the plan instead of asking - do not spend a question confirming the obvious.
- One consequential unknown per question, most architecturally significant first, with concrete options where the code suggests plausible answers.
- Go in rounds and keep going: each answer can open or retire the next question. Continue interviewing until no consequential unknown remains, not just for a single round.
- Do not re-litigate anything a prior `discover` pass already settled; interview only on what is still open.

If, after exploring, there is genuinely nothing consequential left to ask, say so and proceed - a forced interview is as bad as a skipped one.

## Render and review locally

The rendered plan view is the primary review surface - the user reviews the plan in the browser, not by scrolling the chat transcript.

- Map the plan onto `PLAN_DATA` per [references/data-schema.md](references/data-schema.md): goal, success criteria, scope, constraints, current state, the risks/assumptions/open-questions, a best-effort file/blast-radius list, and `steps` as the planned sequence of changes at approach altitude - leave a step's diff empty rather than inventing one, since no code exists yet.
- Copy [templates/plan.html](templates/plan.html) to `~/tmp/{project-slug}/reports/{plan-name}.html`, replacing only the data block between the markers - never touch the rendering engine below them.
- Open that local file in the default browser (`open` on macOS, `xdg-open` on Linux) so the user reviews it there directly. Keep the local path for step 7.
- Do not publish it as an Artifact as part of this flow. Only publish (Artifact tool, stable emoji favicon, title and description from the plan's name and goal) when the user asks for a shareable link; then hand off the returned URL. `to-plan` is the sole owner of this artifact - no other skill re-renders or republishes it.

## Plan structure

Use this template for `plan.md`:

```markdown
# Plan: {title}

This plan must stand alone.
A fresh session with no conversation history should be able to execute it.

## Goal

The outcome this work achieves and why, in the reviewer's terms.
An outcome is a measurable change in behavior, not a list of activities.
For a bet, state it as a hypothesis: "We believe [change] will result in [outcome]; we will know when [measurable signal]."

## Success criteria

1-5 checkable statements that mean this plan is done, measuring the outcome (not the work: "p95 checkout latency under 300ms", not "endpoint implemented").
Give baseline -> target where a number exists.
Each criterion names its check: the command, test, or query that proves it.
Done means these hold, not that every task is closed.

## Scope

In: what this plan changes.
Out: what it deliberately does not - naming exclusions here prevents sprawl.
Out-of-scope findings discovered during execution are logged, never fixed inline.

## Constraints

Invariants the change must not break: public API stability, dependency policy, protected files, forbidden operations.
If a task appears to require violating one, execution stops and the conflict is raised.

## Current state

How the affected part of the system behaves today.
Name the concrete files, modules, and docs involved.
Include the command or steps that demonstrate today's behavior, so the change can be observed against a baseline.

## Proposed approach

What changes, where, and how the system behaves afterwards.
Describe the before/after so a reviewer can picture the end state without reading code.
Call out rejected alternatives when the choice isn't obvious.
If the change also touches a README or other user-facing doc, name that file inline here; there is no separate doc-tracking table.

## Risks, assumptions, open questions

Risks: what could go wrong and the mitigation or acceptance for each.
Assumptions: stated and proceeded on; if one proves false, execution stops.
Blocking questions: must be answered before execution starts; none may remain open when tasks begin.

## Execution

Single task: steps, files, and acceptance criteria live here.
Multiple tasks: the task index from `to-tasks`, one row per file.
Either way, done means Success criteria hold, not that tasks are closed.
```

## Writing for review

The reviewer hasn't seen your exploration or this conversation - the plan must stand alone.
Name concrete files and behaviors, not vague areas; prefer observable behavior changes over refactoring detail.
An open question in the plan is cheaper than a wrong assumption in the code.
Never list auto-generated files (e.g. CHANGELOG.md) as things this plan changes by hand.
