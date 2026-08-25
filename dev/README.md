# dev

Development workflow skills for Claude Code, Codex, opencode, and Pi, built around two ideas: layered tests are the enforceable spec for behavior, and every phase produces something a human actually reviews as HTML, not markdown scrolling.

The skills chain loosely rather than as a rigid pipeline: `/discover` runs whichever pre-implementation moves (blind spot pass, brainstorm/prototype, interview) a given request actually needs, or none at all; `/to-plan` produces a reviewable plan; `/to-tasks` splits it into tasks with acceptance criteria tagged by test layer; `/implement` executes those tasks test-first across unit/integration/e2e, in parallel waves where dependencies allow, keeping a running implementation-notes log; `/to-review` verifies the result with a fan-out panel that checks e2e coverage and logged deviations; `/to-pitch` and `/to-quiz` turn finished work into a buy-in doc or a comprehension check.
There is no standing knowledge base to maintain: the code, its tests, and the active plan under `.dev/{plan-name}/` are the only durable context.
Every producing skill renders its own output as self-contained HTML under `/tmp/{project-slug}/reports/`. It publishes only when the user requests a shareable link and the host provides an artifact-publishing tool.
Every skill is explicit-invocation only: Claude Code and Pi use `disable-model-invocation: true`, the generated Codex distribution uses `agents/openai.yaml` with `allow_implicit_invocation: false`, and opencode enforces it with a `permission.skill` rule set to `ask` (see opencode installation below). Skills recommend the next step rather than launching each other.

## Skills

### discover

Runs the pre-implementation moves that reduce unknowns before a plan is worth writing: a blind spot pass over unfamiliar territory, a brainstorm/prototype pass (with cheap HTML mockups) when the shape isn't decided, and a one-question-at-a-time interview for ambiguities that would change architecture.
Picks only the modes a real signal points to, in whatever order and combination the situation needs, and says so plainly when none apply.
Writes a discovery artifact plus a plain-markdown companion that `to-plan` reads back in directly.

### to-plan

Turns a feature request, spec, or problem statement into a plan for human review at `.dev/{plan-name}/plan.md`, reading a prior `/discover` pass's notes when one exists.
The plan describes the current state and the proposed approach as a before/after picture.
Every run renders `{plan-name}.html` as a walkable timeline with a blast-radius file graph.
If execution spans multiple tasks it recommends `/to-tasks`; otherwise the execution detail is embedded directly in the plan.

### to-tasks

Splits an existing plan into `.dev/{plan-name}/task_1.md`, `task_2.md`, and so on, plus a task index in the plan.
Each task is a self-contained vertical slice a junior engineer can execute in parallel with peers: acceptance criteria tagged by test layer (`[unit|integration|e2e]`), a test plan mapping each criterion to a concrete test, and a self-validation loop built from the repo's real commands to prove the task is done before handoff.
It verifies the split covers every plan scope item before finishing, and does not re-render the plan view - that stays `to-plan`'s approach-review surface.

### implement

Executes a plan's task files test-first, at the layer each acceptance criterion is tagged with - unit for business logic, integration for real cross-component seams, e2e for driving the actual running application.
Runs independent tasks in parallel as waves of subagents derived from the tasks' `Depends on` graph, committing each task and appending to a running `implementation-notes.md` that logs any deviations forced by an edge case.
Once every task is committed, drives the real app against a mocked environment, loops until every e2e scenario passes, then renders the e2e report: screenshots per scenario for frontend systems, Test Scenario and Data Model State tables for everything else.
Every run then asks whether to push and open a PR, whether or not Jira is configured (see Jira integration below).

### to-review

Reviews a branch or PR with a panel of concern-focused agents, selected per diff.
Every non-trivial finding is adversarially verified against the repo.
Checks plan conformance, including whether `[e2e]`-tagged criteria have a passing scenario in the e2e report and whether logged deviations still satisfy Success criteria.
Claude Code, Codex, and opencode use their native parallel subagent facilities. Pi preserves the same independent two-batch panel by launching isolated `pi --print` subprocesses with the current provider, model, and reasoning level.
Renders `review_N.html` alongside the `review_N.md` file for reviewer handoff.

### to-pitch

Packages a finished plan, its prototype, implementation notes, and e2e evidence into one buy-in document: demo first, then why, what changed, how it was verified, and how to try it.

### to-quiz

Renders a context/intuition/what-was-done report with a graded comprehension quiz.
Cannot enforce a merge gate, so it says so plainly and produces an honest pass/fail check instead.

## Jira integration

The spec-driven workflow can mirror its local state to Jira through the
Atlassian CLI (`acli`). Install and authenticate `acli` before enabling it.
Create `.dev/config.json` in the consuming repository:

```json
{
  "jira": {
    "enabled": true,
    "site": "acme.atlassian.net",
    "project": "PROJ"
  }
}
```

`site` is optional and `project` is required when enabled. An absent config
file or `jira.enabled: false` keeps the workflow pure-local with no Jira
calls or questions.

The hierarchy is Initiative > Epic > Task. `to-plan` asks you to choose an
existing open Initiative, creates one Epic under it, and stores the Epic key in
the plan. `to-tasks` creates one Jira Task under that Epic for each local task,
stores each key in the task file and index, and comments and closes old issues
when a task is superseded. `implement` moves the Epic to In Progress at start,
moves each task through In Progress and Done as the orchestrator dispatches and
commits it, then asks `push and open the PR?` on every run. A yes creates a
keyed branch when needed, pushes it, and opens a PR whose title starts with the
Epic key. A no stops after the e2e report.

One-time Jira administration is required. Install the GitHub for Jira
integration, then add an automation rule: "when a linked pull request is
merged, transition the Epic to Done". The Epic key in the branch name and PR
title is what lets Jira link the pull request and trigger that rule. The
skills do not poll for merges.

## Claude Code installation

```bash
/plugin marketplace add tobrun/skills
/plugin install dev@nurbot
```

Invoke skills as `/discover`, `/to-plan`, and so on.

## Codex installation

```bash
codex plugin marketplace add tobrun/skills
codex plugin add dev@nurbot
```

Invoke skills as `$dev:discover`, `$dev:to-plan`, and so on.

## opencode installation

opencode reads Claude-format `SKILL.md` files natively, so no generated distribution is needed.
Clone this repository and symlink the source skills into opencode's global skill directory:

```bash
git clone https://github.com/tobrun/skills ~/ws/skills
mkdir -p ~/.config/opencode/skills
for skill in ~/ws/skills/dev/skills/*/; do
  ln -sfn "$skill" ~/.config/opencode/skills/"$(basename "$skill")"
done
ln -sfn ~/ws/skills/dev/references ~/.config/opencode/references
```

The last symlink keeps the shared `references/jira.md` reachable through the `../../references/` links inside the skills.
Symlinks mean a `git pull` updates the skills in place; restart opencode afterwards, since skills load at startup.

opencode has no `disable-model-invocation` field (it is ignored harmlessly); skills load through a model-invoked `skill` tool.
Preserve the explicit-invocation policy with a permission rule in `~/.config/opencode/opencode.json`:

```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "discover": "ask",
      "to-plan": "ask",
      "to-tasks": "ask",
      "implement": "ask",
      "to-review": "ask",
      "to-pitch": "ask",
      "to-quiz": "ask"
    }
  }
}
```

Invoke a skill by asking for it by name, for example "run the to-plan skill on this request"; the permission rule makes opencode confirm before loading one.
Verify discovery with `opencode debug skill`.
`to-review` runs its panel through opencode's native `task` subagents.

## Pi installation

```bash
pi install git:github.com/tobrun/skills
```

Invoke skills as `/skill:discover`, `/skill:to-plan`, and so on. Pi loads the
source skills directly. A `to-review` run starts multiple model processes, one
per selected lens and then one per non-trivial finding verifier, so its model
usage scales with the panel size.
