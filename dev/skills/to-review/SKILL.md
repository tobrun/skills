---
name: to-review
description: Concern-based fan-out review of a branch or PR where every finding is adversarially verified before it is reported, producing .dev/{plan-name}/review_N.md. Use when the user asks for a code review of their changes or before opening a PR.
disable-model-invocation: true
---

# To Review

Review the current changes with a panel of concern-focused agents, verify every finding against the repo, and write the report as a plan artifact.
You are the orchestrator: gather context, select the panel, run it, aggregate, write the report.
Do not review the code yourself.

Invoking this skill is the task - start at step 1 immediately and detect the diff yourself; do not ask what to review or wait for a task description.

## Workflow

### 1. Detect context and gather the diff

- PR number given -> review that PR; else check `gh pr view` for an open PR; else review the local branch against the default branch (`git merge-base HEAD origin/{default}`).
- Diff with local git only (never `gh pr diff`), excluding lockfiles, build output, minified files, binaries, fonts, snapshots:
  `':!*lock*' ':!go.sum' ':!dist/' ':!build/' ':!*.min.*' ':!*.map' ':!*.png' ':!*.jpg' ':!*.gif' ':!*.webp' ':!*.woff*' ':!*.ttf' ':!**/__snapshots__/'`
- Write the diff to a scratch file; agents read it from there, not inline.
- No reviewable files: say so and stop. Diff is tiny (1-2 files) or huge (>25k lines): confirm with the user before spending on the panel.

### 2. Load intent

The review checks the diff against what was planned, not just general quality.

- Find the plan directory the diff implements (branch name, commit messages, or ask if ambiguous). If found, read `plan.md` and its `task_N.md` files for acceptance criteria and agreed seams.
- Also read `.dev/{plan-name}/implementation-notes.md` if present (deviations logged during implementation) and the latest `/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`'s data block if present (which e2e scenarios exist, their pass/fail status) - both are additional evidence for the `plan-conformance` and `tests` lenses, not just the diff itself.
- No plan: derive `{plan-name}` from the branch name and fall back to the PR body and commits for intent.
- Build a short brief: what the change does, what's on the critical path, what was planned.

### 3. Check for previous reviews

`review_N.md` files present -> this is a re-review: extract unresolved findings from the highest-numbered one as verification items (fixed or not?), and the new report gets the next index.

### 4. Select the panel

Read [references/lenses.md](references/lenses.md); select only lenses with surface in this diff (a docs-only change skips performance).
Include `plan-conformance` whenever a plan was found.
At most one diff-specific custom lens (migrations, concurrency, i18n) when clearly warranted, defined in the same shape as the built-ins.
Tell the user which lenses you selected and why before launching.

### 5. Run the review panel

Use the orchestration transport selected by [references/orchestration.md](references/orchestration.md). Prefer the host's native multi-agent facility (Claude Code and Codex subagents, the opencode `task` tool), preserving its plain parallel subagents. On Pi, where no native subagent facility exists, launch isolated `pi --print` processes with the bundled runner. Both transports use the same two batches: all lens agents first, then all verifiers.
If neither native subagents nor the Pi subprocess transport is available, stop and explain that this panel-based skill cannot preserve its verification contract.
Agents hand their reports back as result files in the review scratch directory; once a batch finishes, read those files.
Never chase results over agent messaging or re-spawn a finished agent to ask for its report.
Every BLOCK or CONCERN is adversarially verified - the verifier's only job is to refute it against the actual repo.

### 6. Aggregate

- Drop REFUTED findings entirely.
- BLOCK stays BLOCK only when CONFIRMED; PLAUSIBLE demotes to CONCERN.
- Dedupe by file:line across lenses; keep the most detailed wording, tag all lenses that found it.
- Verdict: any BLOCK -> BLOCK; else any CONCERN -> CONCERNS; else PASS.
- A failed lens doesn't abort the review; note it so the verdict is honestly partial.

### 7. Write the report

Write `.dev/{plan-name}/review_N.md` (next free index, starting at 1):

```markdown
# Review {N}: {title}

Verdict: {PASS | CONCERNS | BLOCK}
Panel: {lenses run}, {failed lenses if any}
Base: {branch or PR}, {date}

{1-2 sentence summary}

## Plan conformance

Acceptance criteria met/not met, seams tested/untested. Omit if no plan.

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

Map the report onto `REVIEW_DATA` per [references/data-schema.md](references/data-schema.md), write `/tmp/{project-slug}/reports/review_N.html` from [templates/review.html](templates/review.html), replacing only the data block between its markers.
Before first authoring or restyling this template, load an installed artifact or frontend design skill; a plain data refresh on an existing template doesn't need it again.
Give the user the local path. If an artifact-publishing tool is available, publish only when the user asks for a shareable link, using a stable review favicon and a title and description naming the plan and review number. If no publisher exists, the local HTML remains the deliverable.
Re-reviewing the same plan later uses the same `file_path` convention: a new file per `review_N`.

### 9. Present and follow through

Summarize the verdict and top findings in chat, linking the `review_N.md` file, local HTML report, and published URL when one was requested and created.
If the user accepts findings needing real work, suggest `to-tasks` to turn them into `task_N.md` files; do not invoke it yourself.
This holds even when no plan exists: `to-tasks` bootstraps a minimal plan from the review's accepted findings.
Also suggest, as independent optional next steps rather than a mandatory chain: `to-pitch` when the change needs buy-in from someone who wasn't in this conversation, and `to-quiz` when a reviewer wants a comprehension check before merging.
