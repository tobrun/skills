# Eval Results

Status: no run recorded for the current skill set.

The last recorded run (2026-07-24) covered the pre-pivot five-skill chain and was invalidated by the pivot to the decision-spec pipeline; its scores were removed rather than left to invite false confidence.
Run the harness below against the current 7 skills (`decision-spec`, `commit`, `implement`, `to-harden`, `to-review`, `to-pitch`, `to-quiz`) and replace this file with the dated results.

## Re-running this harness

1. Pick a baseline commit (the last commit before the change under test) and the working tree as "new".
2. For functional evals, recreate the fixture described in each `{skill}.json` under a scratch directory outside the repo.
3. Spawn one subagent per (skill, version) pointed at the respective `SKILL.md` text (via `git show <commit>:path` for old, the live file for new) plus the eval prompt.
4. Grade each output against that eval's `assertions`.
5. Record a scores table (skill, eval, old, new) and note any regression before merging the change under test.
