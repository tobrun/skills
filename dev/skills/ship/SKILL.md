---
name: ship
description: Run the quality pass that ships a change in two phases - phase 1 is a deterministic harden gauntlet (dependency rules, coverage-weighted complexity, mutation testing) that loops fresh-context fix agents until every check passes, phase 2 is a read-only adversarially verified review panel over the post-fix diff, writing .dev/{plan-name}/review_N.md. Use after build to finish a change before a PR, or on request for a single phase such as gauntlet only or review only.
disable-model-invocation: true
---

# Ship

Ship a change in two phases: a deterministic gauntlet that fixes mechanics, then a review panel that judges meaning.
Prompted quality rules soften into guidelines as a context grows; a checker's exit code does not, and judgment belongs to a verified panel, not to one context.
You are the orchestrator for both phases: run tools, dispatch agents, aggregate, report.
Do not review the code yourself, and never weaken a check to make it pass.

Invoking this skill is the task - detect the diff yourself and start immediately; do not ask what to ship.

## Phase selection

Default is phase 1 (gauntlet) then phase 2 (review): the panel reviews the diff as it stands after the gauntlet's fixes, so its findings are about meaning, not mechanics already settled.
On request, run a single phase: "gauntlet only" (or "harden only") runs phase 1 alone; "review only" runs phase 2 alone - the right mode when mutating fixes are unwanted, such as on someone else's PR.
The phases differ in contract: phase 1 mutates the repo (fix agents edit code, tools get committed, accepted thresholds land in `docs/decisions.md`); phase 2 is strictly read-only and never edits code or the ledger.

## Scope

Both phases share one scope.

- PR number given -> target that PR; else check `gh pr view` for an open PR; else the local branch against the default branch.
- Gather the diff per the diff-scope rules in [../../references/plan-layout.md](../../references/plan-layout.md): local git only, standard exclusions.
- Locate the spec directory the diff implements (branch name, commit messages, or ask if ambiguous) and read `.dev/{plan-name}/spec.md`; degrade gracefully without one.
- Full-repo runs only when the user asks - they are expensive, and the loops are the same.
- No reviewable files: say so and stop. Diff is tiny (1-2 files) or huge (>25k lines): confirm with the user before spending on agents.

## Phase 1: the gauntlet

Three checks, run cheapest first; [references/tools.md](references/tools.md) owns their definitions and the acquisition ladder.
Never weaken or skip a check because acquiring its tool is work.

1. **Dependency rules** against `docs/dependencies.md` ([../../references/dependency-rules.md](../../references/dependency-rules.md) owns the checker semantics; absent file: skip with a clear note, never invent rules).
2. **Coverage-weighted complexity** per in-scope function.
3. **Mutation testing** over the in-scope source.

Run each check to completion per the loop in [references/gauntlet.md](references/gauntlet.md).

## Phase 2: the review panel

Review the diff with a panel of concern-focused agents, verify every finding against the repo, and write the report as a plan artifact.

### 1. Load intent

The review checks the diff against what was specced, not just general quality.

- Write the diff to a scratch file; agents read it from there, not inline.
- Read the target repo's `docs/contracts.md` first, if it exists ([../../references/contracts.md](../../references/contracts.md)): its boundary guarantees are premises. Excerpt the entries whose guarantee or reliance sites the diff touches into the brief handed to every lens; a diff that breaks a cited guarantee while reliance sites still assume it is finding material.
- From the spec read in Scope: the scope section for invariants, boundaries, and error handling, the change plan for per-set files and layer-tagged `tests:` scenarios, and the research section for the decision rationale used to judge deviations.
- Also read `.dev/{plan-name}/implementation-notes.md` if present (deviations logged during implementation) and the latest `/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`'s data block, per the reading rules in [../../references/reporting.md](../../references/reporting.md). Both are additional evidence for the `spec-conformance` and `tests` lenses, not just the diff itself.
- No spec: derive `{plan-name}` from the branch name and fall back to the PR body and commits for intent.
- Build a short brief: what the change does, what's on the critical path, what was specced.

### 2. Check for previous reviews

`review_N.md` files present -> this is a re-review: extract unresolved findings from the highest-numbered one as verification items (fixed or not?), and the new report gets the next index.

### 3. Select the panel

Read [references/lenses.md](references/lenses.md); select only lenses with surface in this diff (a docs-only change skips performance).
Include `spec-conformance` whenever a spec was found.
At most one diff-specific custom lens (migrations, concurrency, i18n) when clearly warranted, defined in the same shape as the built-ins.
Tell the user which lenses you selected and why before launching.

### 4. Run the review panel

Run the two batches - all lens agents first, then all verifiers - on the transport selected by [references/orchestration.md](references/orchestration.md), which owns transport choice, result-file delivery, and the prompt contracts.
If no transport is available, stop and explain that this panel-based phase cannot preserve its verification contract.
Every BLOCK or CONCERN is adversarially verified - the verifier's only job is to refute it against the actual repo.

### 5. Aggregate

- Drop REFUTED findings entirely.
- BLOCK stays BLOCK only when CONFIRMED; PLAUSIBLE demotes to CONCERN.
- Dedupe by file:line across lenses; keep the most detailed wording, tag all lenses that found it.
- Verdict: any BLOCK -> BLOCK; else any CONCERN -> CONCERNS; else PASS.
- A failed lens doesn't abort the review; note it so the verdict is honestly partial.
- Only now, with findings verified, read the target repo's `docs/decisions.md` if it keeps one, and classify each colliding finding per the recommender contract in [../../references/decision-ledger.md](../../references/decision-ledger.md). Read-only - this phase never edits the ledger; classifications land in the report's Decision reconciliation section, and ledger writes belong to the follow-up `scope` run.

### 6. Write the report

Write `.dev/{plan-name}/review_N.md` (next free index, starting at 1):

```markdown
# Review {N}: {title}

Verdict: {PASS | CONCERNS | BLOCK}
Panel: {lenses run}, {failed lenses if any}
Base: {branch or PR}, {date}

{1-2 sentence summary}

## Spec conformance

Tests: scenarios met/not met, invariants held, seams tested/untested. Omit if no spec.

## Decision reconciliation

{only when the repo keeps docs/decisions.md} Each colliding finding: still-holds (with the checked reopen condition), reopened, or diverged.

## Previous findings

{re-review only} Each finding from review_{N-1}: fixed or still open.

## Blockers

[{lenses}] {file:line} - {title}
{The scenario that triggers it, confirmed by verification.}

## Concerns

Same shape as blockers.

## Nits

| File | Lens | Issue |

## What's good

One line per lens; omit empty ones.

## Next step

What to fix first and why.
```

### 7. Publish the report

Map the report onto `REVIEW_DATA` per [references/data-schema.md](references/data-schema.md) and render [templates/review.html](templates/review.html) to `/tmp/{project-slug}/reports/review_N.html`, opening and publishing per [../../references/reporting.md](../../references/reporting.md) (stable review favicon; title names the plan and review number).

## Wrap up

Summarize whichever phases ran in one chat message.
For the gauntlet, per tool: violations found, fixed, and surviving (with the human call each is waiting on); name the tools acquired or built this run and where they live; state the scope honestly - "hardened the diff" is not "hardened the repo".
For the review: the verdict and top findings, linking the `review_N.md` file, local HTML report, and published URL when one was requested and created.
Recommend next steps, never invoking them:

- `commit` for the gauntlet's accumulated fixes.
- `scope` on this plan directory when the user accepts findings needing real work - remediation is its job, even when no spec exists.
- As independent optional next steps rather than a mandatory chain: `to-pitch` when the change needs buy-in from someone who wasn't in this conversation, and `to-quiz` when a reviewer wants a comprehension check before merging.
