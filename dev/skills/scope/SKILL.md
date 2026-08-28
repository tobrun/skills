---
name: scope
description: Spec a change by interviewing for the real problem, arguing every design decision against alternatives, and writing a self-contained spec with a change plan at .dev/{plan-name}/spec.md. Use to plan work before implementation, to turn accepted review findings into new change sets, or to audit the decisions already embedded in existing code.
disable-model-invocation: true
---

# Scope

You are making changes, and writing a spec to help with this.
The spec is a fresh-context handoff: planning happens here, and implementation happens in another session (often another model) that reads only the spec.
The spec is the deliverable: do not implement anything.

## 1. Interview

Interview the user until you understand what they want, one consequential question at a time, using the host's structured user-input tool when available. Then write down what you understood.

The request often arrives one level too low: a solution ("add rate limiting with Redis") hides the problem it solves; a symptom hides the cause that picks the fix.
Before interviewing about the change itself, climb up: ask what led to this, what they observed, and what would look different if it worked.
Then pressure-test the premise - what data shows the problem is real, and does it point where they think? A symptom usually has several candidate causes, each implying a different change; committing to a fix before the cause means speccing the wrong change well.
Once the problem holds up, brainstorm alternatives at the problem level, not just variants of the stated solution - including other layers entirely (rate limit at the ALB instead of in the app).
The user's original ask becomes one alternative among these, and the whole question lands in the research section as the first decision.
If the premise doesn't survive, that resolves as a `⊘` not-doing line with the condition that would reopen it, not as a failed interview.

Then size the change: **small** - a handful of decisions, an area the user knows, limited blast radius - or **full**, everything else.
Tell the user which you picked and why; they can override.
Small changes run the lighter variants marked in each phase below; the spec file, decision notation, scope, and change plan always happen - they're the point of the skill.

**Iterate small.**
Bias toward the smallest spec that delivers observable behavior: a slice implemented and looked at teaches more than a bigger plan, and plans rarely survive contact with the code.
A big request becomes a first slice specced now, with later slices as `⊘` lines naming what reopens them; once build and ship land, reopen the spec per "Starting from review findings" below.
The ledger carries the decisions across slices, so nothing argued is lost by going small.

For full-size changes, quiz the user on the code and domain involved: about 10 questions, medium to hard, zero jargon, each with enough context to be answerable.
Afterwards tell them what they understand well, what they don't, and their unknown unknowns - things that would affect their decisions on this task.

## 2. Catalog the decisions

Look at the code. Hunt for prior art first - existing idioms, helpers, and earlier attempts - so decisions get argued against what the codebase already does, not from scratch. Identify all the design decisions involved:

- **Big** - overall approach.
- **Medium** - things that seem simple but can cause big shifts in how much work is done (store a file on S3 or locally, retry strategy). The trickiest tier - make sure you catch all of them.
- **Small** - timeout lengths, shapes of data structures.

Pay special attention to edge cases and error handling.
How the change gets verified is a decision too: what level to test at, what needs a real dependency versus a fake, what can't be tested and why.

**Blind spot pass** (full-size only): don't grade your own catalog - you'll reread it the way you wrote it.
Spawn a subagent that gets only the user's original request and the relevant code - not the conversation, not your catalog - and independently catalogs the decisions.
Decisions it found that you didn't are blind spots; decisions you found that it didn't deserve a second look. Fold the diff into the catalog.
Then tell the user what their framing didn't account for: constraints already in the code, behavior the change would break, second-order work, and what a mature solution handles in this domain that they wouldn't know to ask about.

Talk through the big and medium decisions with the user, highest-impact first.
When a decision's criteria are taste-driven, show 2-3 concrete visual sketches of the alternatives instead of describing them in prose.

## 3. Research section

Pick a kebab-case `{plan-name}` naming the outcome, and write the spec as `.dev/{plan-name}/spec.md`, dated under its title.
Start with a research section, one entry per decision, ordered by impact.
Every decision gets a stable ID: `D-` plus a short kebab slug (`D-file-storage`); keep a slug once assigned.

Each entry: the decision phrased as a question, then one line per alternative - `✓` chosen, `✗` rejected, `?` still open - each with a short "because" clause.
A chosen alternative with a known downside states it after `⚠`: the tradeoff was seen and accepted, so a future reader doesn't re-litigate it.
A decision with no `✓` yet is marked `[open]`; the change plan can't link to it until it's decided.
A decision can also resolve to *not doing it*: every alternative gets `✗`, and a closing `⊘` line carries the rationale and the condition that would reopen it.
Evidence marks follow the Notation in [../../references/decision-ledger.md](../../references/decision-ledger.md), from phase 1 onward - the premise pressure-test data lands in the spec cited or marked.
Anywhere in the doc, `⚑` marks a line waiting on the user. Resolve and remove every `⚑` before the change plan is final.

```
D-input-validation: How should input be validated?
  ✓ custom validation - rules fit in ~20 lines, no new dependency ⚠ we maintain edge cases ourselves
  ✗ validation library - adds a dependency for one call site

D-file-storage: Where do uploaded files live? [open]
  ? S3 - survives redeploys, needs bucket + IAM work
  ⚑ ask: expected file sizes and retention?

D-response-caching: Should responses be cached?
  ✗ Redis - operational burden for an unproven need
  ⊘ not doing - no measured latency problem ? verify: p95 from prod metrics; reopen if p95 exceeds 500ms
```

When any later section references a decision, echo the resolution in parentheses - `D-file-storage (✓ S3)`, `(open)`, `(⊘ not doing)` - so the reader only jumps back for the why. If a choice changes, grep the slug to update every echo.

## 4. Scope section

Record the scope: inputs, outputs, invariants, and error handling.
An invariant that crosses a boundary - another module will rely on it without seeing the enforcing code - gets drafted in contract notation ([../../references/contracts.md](../../references/contracts.md)) so phase 8 can promote it.
A change that adds a module or dependency edge, or collides with `docs/dependencies.md`, is a decision with the alternatives named in [../../references/dependency-rules.md](../../references/dependency-rules.md); the chosen resolution edits that file inside a change set, never implicitly.
Efforts have second-order effects - capture them as nested sub-efforts, each carrying its own decisions back into the research section (rate limiting in scope means Redis setup, which carries config and deploy decisions).
Record considered non-goals as `⊘` lines with a because clause - things someone weighed and cut, not mere omissions.
End the scope with a `### Validation` block listing the repo's real typecheck/test/lint/build commands, discovered from `package.json`, a `Makefile`, CI config, or equivalent - never guess `npm test` into a `pytest` repo; ask if you cannot determine them.
Writing style for the spec: ELI12, no similes or metaphors.

## 5. Review and research in parallel

1. Spawn a subagent reviewer with the spec file only - not the conversation, not your reasoning. Give it a hunting job, not a checklist: find the decisions this spec makes without realizing it, the alternatives rejected without a stated reason, and the chosen options whose downsides the spec doesn't admit. It succeeds by finding problems; "looks complete" is a failed review. For small changes, run this hunt yourself against the spec file.
2. While it runs, research how to implement everything: exact call sites, APIs, the idioms from the phase 2 prior-art hunt. Ask the user when you hit weird stuff.
3. Also while it runs, reconcile the drafted decisions against the project's `docs/decisions.md`, if it keeps one, per the recommender contract in [../../references/decision-ledger.md](../../references/decision-ledger.md). The decisions were argued fresh, so this diff means something; a `diverged` classification is raised with the user and marked `⚑` until resolved.
4. When the reviewer returns, ask remaining questions and update the doc. Anything unanswerable stays as a `⚑` line.

## 6. Change plan

At the bottom of the spec. Short fragmented sentences. Link decisions by ID wherever one applies, echoing the choice.
Each change set ends with a `tests:` line - concrete scenarios as input -> expected outcome, each tagged with its test layer (`[unit]`, `[integration]`, `[e2e]`), covering happy path, edge cases, and failure paths.
Specific enough that whoever writes the tests invents nothing; the author tags layers here because a fresh implementation session can't recover that intent.
A change set with nothing to test says so with a reason: `tests: none - config-only`. A missing `tests:` line reads as "nobody thought about it", not "nothing to test".
Order change sets so each builds only on the ones before it; keep file lists disjoint where possible - `build` parallelizes consecutive change sets whose files don't overlap.

```
1. Change set 1
   a. file 1 - describe changes - decisions: D-input-validation (✓ custom)
   b. file 2 - describe changes
   tests: [unit] payload missing name -> 400 naming the field; [integration] valid payload -> 200 and row written; [e2e] 11MB upload -> rejected before the transfer starts

2. Change set 2
   a. file 3 - describe changes - decisions: D-file-storage (✓ S3)
   tests: none - deploy config only, verified by the deploy itself
```

## 7. Visualize

Full-size changes only. Map the settled spec onto `SPEC_DATA` per [references/data-schema.md](references/data-schema.md) and render [templates/spec.html](templates/spec.html) to `/tmp/{project-slug}/reports/{plan-name}-spec.html`, opening and publishing per [../../references/reporting.md](../../references/reporting.md).

## 8. Promote to the ledger

Copy into `docs/decisions.md` every decision that passes the promotion test in [../../references/decision-ledger.md](../../references/decision-ledger.md).
Entries go in verbatim, dated, sourced to this spec, evidence marks included; a `? verify:` never gets silently dropped, and promotion is the cheapest moment to check what's checkable now.
Promote recurring rationales to `P-` principles per the ledger's bar.
Cross-boundary invariants from phase 4 promote to `docs/contracts.md` under the same test, phrased for the relying side.
Update the familiarity line of each area the phase 1 quiz covered.

## 9. Run retrospective

Audit the run itself. Four checks, each reported as a typed line - silence reads as "never ran":

- **Contamination** - `clean | contaminated`. Did the ledger enter context before the phase 5 reconcile? If so, name the decisions drafted after exposure: their reconcile outcomes are inherited, and a `still-holds` on them proves nothing.
- **Sizing** - `held | mis-sized`. Did the small/full call survive? Name the evidence when it didn't.
- **Catalog gaps** - `none | gap`. What did the reviewer or blind-spot pass find that phase 2 should have caught? A missed *category* is a proposed edit to the phase 2 list - propose it to the user, never apply it silently.
- **Familiarity** - `matched | adjusted`. Did the decision talk match what the quiz predicted? If not, amend the phase 8 familiarity line and say so.

Then recommend the user run `build` on the spec; never launch it yourself.

## Jira sync

Read `.dev/config.json`; when `jira.enabled` is true, follow [../../references/jira.md](../../references/jira.md) from before the first `acli` call - it owns the command shapes, the Initiative/Epic/Task timing, and the failure protocol.
With an absent or disabled config, no Jira behavior or mention.

## Starting from review findings

When `.dev/{plan-name}/review_N.md` files exist, the highest-numbered review's accepted Blockers and Concerns are the interview's opening agenda: each becomes an open decision, and rejected or deferred findings land as `⊘` lines so they are visibly not dropped.
Append new change sets to the existing `spec.md` with continued numbering - never renumber - and apply the review's Decision reconciliation section to `docs/decisions.md`.
A defect change set includes the review's triggering scenario as its reproduction.

## Reverse mode

When the user points at existing code instead of a planned change ("audit the decisions in the sync layer"), follow [references/reverse-mode.md](references/reverse-mode.md): inventory the decisions already embedded in the code, reconcile them against the ledger, and write ratified entries and unexamined defaults out - no spec file is produced.
To seed a ledger from commit history instead of code, follow [references/bootstrap.md](references/bootstrap.md).
