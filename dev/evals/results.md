# Eval Results: Conciseness Refactor (2026-07-24)

Status: stale - superseded by the v1.0.0 pivot (test-as-spec, layered testing, Artifact-published HTML, discover/to-pitch/to-quiz). The scores below only cover the pre-pivot five-skill chain and no longer reflect the current `SKILL.md` text. Re-run the harness per "Re-running this harness" below, baseline commit `0.9.0` vs. the working tree, across all 8 current skills, and replace this file with that dated entry before relying on these numbers again.

Methodology, scores, and findings for the eval run that verified the conciseness refactor of all five `dev` plugin skills (commit `da466e9`) did not regress behavior versus the pre-refactor baseline (commit `b7bb3bf`).

## Method

For each skill, an "old" and a "new" subagent were given the same task and pointed at the pre-refactor and post-refactor `SKILL.md` text respectively (old text sourced via `git show b7bb3bf:dev/skills/{skill}/SKILL.md`), then graded against the assertions in this directory's `{skill}.json`.

- **Functional evals** (`to-plan`, `to-tasks`, `implement`): the subagent actually executes the skill against a realistic scratch fixture and produces a real artifact (a plan, task files, or code+tests+commit), which is graded directly.
- **Comprehension evals** (`install`, `to-review`): a full run is either interactive (`install` needs question rounds against a real codebase) or expensive (`to-review` fans out its own subagent panel), so instead the subagent answers policy questions strictly from the skill text, graded against known-correct answers.

Fixtures live under a scratch directory outside the repo (not checked in); the eval definitions and this results file are the persistent, re-runnable part of the harness.

## Scores

| Skill | Eval | Old | New |
| --- | --- | --- | --- |
| to-plan | rate-limit-api | 6/6 | 6/6 |
| to-tasks | rate-limit-api-tasks | qualitative pass* | qualitative pass* |
| implement | discount-pricing | 6/6 | 6/6 |
| install | policy questions | 4/4 | 4/4 |
| to-review | policy questions | 4/4 | 4/4 |

**Quantifiable total: 20/20 assertions pass on both old and new. No regression.**

\* `to-tasks`: old judged the fixture plan as single-task scope and declined to split it (a correct application of "if the plan honestly fits in one task, say so instead of splitting artificially"); new found a genuine vertical seam (IP-based limiting vs. API-key fallback) and split it into two well-formed, INVEST-shaped tasks with correct dependency and doc-ownership. Both are defensible applications of the same sizing rule; the divergence is judgment-call variance between agent runs, not a wording effect - the sizing heuristic's text was not touched by the conciseness edit.

## Word-count reduction (the conciseness measure itself)

| Skill | Before | After | Change |
| --- | --- | --- | --- |
| implement | 604 | 439 | -27% |
| install | 889 | 674 | -24% |
| to-plan | 763 | 592 | -22% |
| to-tasks | 687 | 555 | -19% |
| to-review | 810 | 688 | -15% |

Average reduction: ~21%.

## Findings

- No skill lost a behavioral rule during the conciseness pass: every policy comprehension question and every functional assertion that passed on the old text also passed on the new text.
- Both `implement` runs independently discovered and fixed the same unrelated bug (a broken `node --test test/` invocation in the fixture's `package.json` on Node v24.7.0), consistent with the house rule to fix engineering issues encountered along the way even when unrelated to the task at hand.
- The `to-tasks` divergence is the one place old and new produced materially different artifacts; it reflects normal variance in an agentic judgment call (single-task vs. multi-task sizing), not a defect introduced by trimming words.

## Re-running this harness

1. Pick a baseline commit (the last commit before the change under test) and the working tree as "new".
2. For functional evals, recreate the fixture described in each `{skill}.json` under a scratch directory.
3. Spawn one subagent per (skill, version) pointed at the respective `SKILL.md` text (via `git show <commit>:path` for old, the live file for new) plus the eval prompt.
4. Grade each output against that eval's `assertions`.
5. Update the scores table and word-count table above, and note any regression before merging the change under test.
