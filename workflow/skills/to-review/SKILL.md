---
name: to-review
description: Concern-based fan-out review of a branch or PR where every finding is adversarially verified before it is reported, producing docs/plan/{plan-name}/review_N.md. Use when the user asks for a code review of their changes, before opening a PR, or as the review step of the implement skill.
---

# To Review

Review the current changes with a panel of concern-focused agents, verify every finding against the repo before reporting it, and write the report as a plan artifact.
You are the orchestrator: gather context, select the panel, run the workflow, aggregate, and write the report.
Do not review the code yourself.

## Workflow

### 1. Detect context and gather the diff

- If the user passed a PR number, review that PR; otherwise check `gh pr view` for an open PR; otherwise review the local branch against the default branch (`git merge-base HEAD origin/{default}`).
- Diff with local git only (never `gh pr diff`), excluding lockfiles, build output, minified files, binaries, fonts, and snapshots:
  `':!*lock*' ':!go.sum' ':!dist/' ':!build/' ':!*.min.*' ':!*.map' ':!*.png' ':!*.jpg' ':!*.gif' ':!*.webp' ':!*.woff*' ':!*.ttf' ':!**/__snapshots__/'`
- Write the diff to a scratch file; agents read it from there instead of receiving it inline.
- Sanity checks: if no reviewable files remain, say so and stop.
  If the diff is tiny (1-2 files) or huge (>25k changed lines), tell the user and ask whether to proceed before spending on the panel.

### 2. Load intent

The review checks the diff against what was planned, not just against general code quality.

- Find the plan: a `docs/plan/{plan-name}/` directory whose plan the diff implements (from branch name, commit messages, or ask the user if ambiguous).
- If found, read `plan.md` and its `task_N.md` files.
  These supply the acceptance criteria, the agreed seams, and the Documentation impact table for the plan-conformance lens.
- If no plan exists, derive `{plan-name}` as a kebab-case slug of the branch name and fall back to the PR body and commit messages for intent.
- Build a short brief: what the change does, what is on the critical path, what was planned.

### 3. Check for previous reviews

If `docs/plan/{plan-name}/review_N.md` files exist, this is a re-review.
Extract the unresolved findings from the highest-numbered review; they become verification items in the run (was each one fixed?), and the new report gets the next index.

### 4. Select the panel

Read [references/lenses.md](references/lenses.md) and select only the lenses that have surface in this diff.
A docs-only change does not pay for a performance lens.
Include `plan-conformance` whenever a plan was found.
You may add at most one diff-specific custom lens (for example migrations, concurrency, i18n) when the change obviously calls for it; define it in the same shape as the built-in lenses.
Tell the user which lenses you selected and why before launching.

### 5. Run the review workflow

Use the Workflow tool with the script template in [references/orchestration.md](references/orchestration.md).
It pipelines: each lens reviews the diff, and every BLOCK or CONCERN finding goes straight to an adversarial verifier that tries to refute it against the actual repo.
Inherit the session model; do not pin model names.

### 6. Aggregate

- Drop REFUTED findings entirely.
- A BLOCK stays BLOCK only when CONFIRMED; PLAUSIBLE demotes it to CONCERN.
- Dedupe by file and line across lenses; keep the most detailed wording and tag with all lenses that found it.
- Verdict: any BLOCK means BLOCK; else any CONCERN means CONCERNS; else PASS.
- A failed lens does not abort the review; note it in the report so the verdict is honestly partial.

### 7. Write the report

Write `docs/plan/{plan-name}/review_N.md` (next free index, starting at 1):

```markdown
# Review {N}: {title}

Verdict: {PASS | CONCERNS | BLOCK}
Panel: {lenses run}, {failed lenses if any}
Base: {branch or PR}, {date}

{1-2 sentence summary}

## Plan conformance

Acceptance criteria met / not met, seams tested / untested,
Documentation impact rows honored / missed. Omit if no plan.

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

### 8. Present and follow through

Summarize the verdict and the top findings in chat, and link the report file.
If the user accepts findings that need real work, offer to run the `to-tasks` skill to turn them into `task_N.md` files in the same plan directory, ready for the `implement` skill.
