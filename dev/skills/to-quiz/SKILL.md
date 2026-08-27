---
name: to-quiz
description: Render a context/intuition/what-was-done document with a graded comprehension quiz on finished work. Use when the user wants a local or shareable comprehension check before a change merges.
disable-model-invocation: true
---

# To Quiz

Turn finished work into a comprehension check: enough context to understand the change, then a quiz the reader must actually pass.

## What this skill can and can't do

**It cannot enforce a merge gate.** The generated document has no hook into a PR's merge button or branch protection rules - nothing this skill produces can physically block a merge.
What it can do honestly is render a clear "do not merge until this is genuinely green" artifact, with a visible banner saying so, and suggest - never configure - real external enforcement if the user wants one: a required PR checklist item, a manually-applied label, a branch protection rule.
That wiring is out of this skill's scope; never write or imply language suggesting this skill gates anything by itself.

## Workflow

1. Locate the spec directory per [../../references/plan-layout.md](../../references/plan-layout.md).
2. Read whatever exists, degrading gracefully when something doesn't, shaped for comprehension-checking rather than persuasion:
   - `.dev/{plan-name}/spec.md` - the research decisions (`✓` chosen, `✗` rejected, `⚠` accepted downsides), the scope invariants and error handling, and the change plan's layer-tagged `tests:` scenarios (including edge cases).
   - `.dev/{plan-name}/implementation-notes.md` (from `implement`) - what was done, Deviations.
   - `/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`'s data block - concrete scenarios to quiz on (scenario fields only, never the base64 screenshot payloads).
3. Write Context (what this change is and why), Intuition (the one key design insight or tradeoff a reviewer needs to *get*, in plain language - the spec's most consequential `✓`/`⚠` pair is the natural source), and What was done.
   Write 3-6 quiz questions, each generated from something real: a decision's chosen-over-rejected rationale, a scope invariant or error-handling rule, a `tests:` scenario, or a logged deviation - never a generic question a reader could pass without having read anything. Each needs a correct answer, 2-3 plausible wrong answers, an explanation, and a link back to whichever section of this same document (Context, Intuition, or What was done) backs the right answer. The spec's `✗` rejected alternatives make ideal plausible wrong answers.
4. Map everything onto `QUIZ_DATA` per [references/data-schema.md](references/data-schema.md): sections Context, Intuition, What was done, then the client-side quiz - graded entirely in-browser JS, no server, no network calls - with a pass/fail summary and missed-question call-outs that link back to the relevant section.
5. Render [templates/quiz.html](templates/quiz.html) to `/tmp/{project-slug}/reports/{plan-name}-quiz.html`, opening and publishing per [../../references/reporting.md](../../references/reporting.md) (stable quiz favicon; title and description from the spec). Remind the user that the quiz is a comprehension check they take themselves, not an automated gate.

## Writing good questions

- Wrong answers should be plausible misreadings of the change, not absurd distractors - a question only a careless reader would miss is testing attention, not understanding.
- The explanation for a missed question should teach, not just state the answer - that's what the link back to Context, Intuition, or What was done is for.
