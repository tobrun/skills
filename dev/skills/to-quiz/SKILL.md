---
name: to-quiz
description: Render a context/intuition/what-was-done doc with a graded comprehension quiz on finished work, published as an Artifact for a reviewer or author to read before merging. Use when the user wants a comprehension check on a change before it merges.
disable-model-invocation: true
---

# To Quiz

Turn finished work into a comprehension check: enough context to understand the change, then a quiz the reader must actually pass.
This is a comprehension aid, not an enforcement mechanism - be explicit about that distinction, below and in the artifact itself.

## What this skill can and can't do

**It cannot enforce a merge gate.** Claude Code has no hook into a PR's merge button or branch protection rules - nothing this skill produces can physically block a merge.
What it can do honestly is render a clear "do not merge until this is genuinely green" artifact, with a visible banner saying so, and suggest - never configure - real external enforcement if the user wants one: a required PR checklist item, a manually-applied label, a branch protection rule.
That wiring is out of this skill's scope; never write or imply language suggesting this skill gates anything by itself.

## Workflow

1. Locate the plan: match the current branch name to a `.dev/{plan-name}/` slug, the same convention `to-tasks` uses.
   Ask which plan only if more than one is a plausible match; otherwise proceed without waiting for clarification.
2. Read whatever exists, degrading gracefully when something doesn't, shaped for comprehension-checking rather than persuasion:
   - `.dev/{plan-name}/plan.md` and any `task_N.md` - Goal, Success criteria, acceptance criteria (including edge cases).
   - `.dev/{plan-name}/implementation-notes.md` (from `implement`) - what was done, Deviations.
   - `~/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`'s data block - concrete scenarios to quiz on.
3. Write Context (what this change is and why), Intuition (the one key design insight or tradeoff a reviewer needs to *get*, in plain language, not a restated summary), and What was done.
   Write 3-6 quiz questions, each generated from a real acceptance criterion, edge case, or logged deviation - never a generic question a reader could pass without having read anything. Each needs a correct answer, 2-3 plausible wrong answers, an explanation, and a link back to whichever section of this same document (Context, Intuition, or What was done) backs the right answer.
4. Map everything onto `QUIZ_DATA` per [references/data-schema.md](references/data-schema.md), rendered into [templates/quiz.html](templates/quiz.html): sections Context, Intuition, What was done, then the client-side quiz - graded entirely in-browser JS, no server, no network calls - with a pass/fail summary and missed-question call-outs that link back to the relevant section.
   Before first authoring or restyling the template, load the `artifact-design` skill; a plain data refresh on an existing template doesn't need it again.
5. Write the rendered file to `~/tmp/{project-slug}/reports/{plan-name}-quiz.html`, replacing only the data block between the markers - the grading logic below them is generic, don't touch it.
   Publish it with the `Artifact` tool using that `file_path`: a stable graduation-cap favicon across every quiz this skill produces, a title and one-sentence description from the plan.
   Resuming a plan in a later session and updating the same artifact needs the `url` parameter instead - find it with `Artifact({action: "list"})` if you don't already have it.
   Tell the user both the local path and the published URL, and remind them the quiz is a comprehension check they take themselves, not an automated gate.

## Writing good questions

- Ground every question in something real: an acceptance criterion, an edge case the tests cover, a deviation that was logged - never invented trivia.
- Wrong answers should be plausible misreadings of the change, not absurd distractors - a question only a careless reader would miss is testing attention, not understanding.
- The explanation for a missed question should teach, not just state the answer - that's what the link back to Context, Intuition, or What was done is for.
