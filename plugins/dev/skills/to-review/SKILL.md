---
name: to-review
description: Concern-based fan-out review of a branch or PR where every finding is adversarially verified before it is reported, producing .dev/{plan-name}/review_N.md. Use when the user asks for a code review of their changes or before opening a PR.
---

# To Review

Review the current changes with a panel of concern-focused agents, verify every finding against the repo, and write the report as a plan artifact.
You are the orchestrator: gather context, select the panel, run it, aggregate, write the report.
Do not review the code yourself.

Invoking this skill is the task - start at step 1 immediately and detect the diff yourself; do not ask what to review or wait for a task description.

## Workflow

### 1. Detect context and gather the diff

- PR number given -> review that PR; else check `gh pr view` for an open PR; else review the local branch against the default branch.
- Gather the diff per the diff-scope rules in [../../references/plan-layout.md](../../references/plan-layout.md): local git only, standard exclusions.
- Write the diff to a scratch file; agents read it from there, not inline.
- No reviewable files: say so and stop. Diff is tiny (1-2 files) or huge (>25k lines): confirm with the user before spending on the panel.

### 2. Load intent

The review checks the diff against what was specced, not just general quality.

- Read the target repo's `docs/contracts.md` first, if it exists ([../../references/contracts.md](../../references/contracts.md)): its boundary guarantees are premises. Excerpt the entries whose guarantee or reliance sites the diff touches into the brief handed to every lens; a diff that breaks a cited guarantee while reliance sites still assume it is finding material.
- Find the spec directory the diff implements (branch name, commit messages, or ask if ambiguous). If found, read `.dev/{plan-name}/spec.md`: the scope section for invariants, boundaries, and error handling, the change plan for per-set files and layer-tagged `tests:` scenarios, and the research section for the decision rationale used to judge deviations.
- Also read `.dev/{plan-name}/implementation-notes.md` if present (deviations logged during implementation) and the latest `/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`'s data block if present - scenario ids and statuses only, never the base64 screenshot payloads ([../../references/reporting.md](../../references/reporting.md)). Both are additional evidence for the `spec-conformance` and `tests` lenses, not just the diff itself.
- No spec: derive `{plan-name}` from the branch name and fall back to the PR body and commits for intent.
- Build a short brief: what the change does, what's on the critical path, what was specced.

### 3. Check for previous reviews

`review_N.md` files present -> this is a re-review: extract unresolved findings from the highest-numbered one as verification items (fixed or not?), and the new report gets the next index.

### 4. Select the panel

Read [references/lenses.md](references/lenses.md); select only lenses with surface in this diff (a docs-only change skips performance).
Include `spec-conformance` whenever a spec was found.
At most one diff-specific custom lens (migrations, concurrency, i18n) when clearly warranted, defined in the same shape as the built-ins.
Tell the user which lenses you selected and why before launching.

### 5. Run the review panel

Run the two batches - all lens agents first, then all verifiers - on the transport selected by [references/orchestration.md](references/orchestration.md), which owns transport choice, result-file delivery, and the prompt contracts.
If no transport is available, stop and explain that this panel-based skill cannot preserve its verification contract.
Every BLOCK or CONCERN is adversarially verified - the verifier's only job is to refute it against the actual repo.

### 6. Aggregate

- Drop REFUTED findings entirely.
- BLOCK stays BLOCK only when CONFIRMED; PLAUSIBLE demotes to CONCERN.
- Dedupe by file:line across lenses; keep the most detailed wording, tag all lenses that found it.
- Verdict: any BLOCK -> BLOCK; else any CONCERN -> CONCERNS; else PASS.
- A failed lens doesn't abort the review; note it so the verdict is honestly partial.
- Only now, with findings verified, read the target repo's `docs/decisions.md` if it keeps one, and reconcile per the recommender contract in [../../references/decision-ledger.md](../../references/decision-ledger.md): classify each colliding finding `still-holds` (suppress it but report the check), `reopened`, or `diverged`. Read-only - this skill never edits the ledger; classifications land in the report's Decision reconciliation section, and ledger writes belong to the follow-up `decision-spec` run.

### 7. Write the report

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

### 8. Publish the report

Map the report onto `REVIEW_DATA` per [references/data-schema.md](references/data-schema.md) and render [templates/review.html](templates/review.html) to `/tmp/{project-slug}/reports/review_N.html`, opening and publishing per [../../references/reporting.md](../../references/reporting.md) (stable review favicon; title names the plan and review number).
Re-reviewing the same plan later writes a new file per `review_N`.

### 9. Present and follow through

Summarize the verdict and top findings in chat, linking the `review_N.md` file, local HTML report, and published URL when one was requested and created.
If the user accepts findings needing real work, suggest a `decision-spec` run on this plan directory to turn them into new change sets; do not invoke it yourself.
This holds even when no spec exists: `decision-spec` bootstraps one from the review's accepted findings, and it also applies the Decision reconciliation section to the ledger.
Also suggest, as independent optional next steps rather than a mandatory chain: `to-pitch` when the change needs buy-in from someone who wasn't in this conversation, and `to-quiz` when a reviewer wants a comprehension check before merging.
