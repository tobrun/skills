---
name: to-human-plan
description: Render an implementation plan as a single self-contained interactive HTML file for human review - spatial layout, a file dependency graph sized/colored by blast radius, a walkable timeline, flaggable steps, and a copyable review-notes block - saved outside the repo. Use when the user wants to review a plan visually, walk through implementation steps interactively, or asks for an HTML or visual version of a plan.
disable-model-invocation: true
---

# To Human Plan

Turn an existing plan into an interactive HTML artifact a human reads spatially and walks through step by step, instead of scrolling markdown.

Requires a plan already produced by `/to-plan` (and `/to-tasks` if it split into multiple tasks).
If none exists, tell the user to run `/to-plan` first - this skill visualizes a plan, it doesn't write one.

Never write output inside the project repo.
These are throwaway, human-facing artifacts, not project history; the repo must never store or commit them.

Invoking this skill with an existing plan in view is the task - proceed immediately, don't wait for further instructions.

## Workflow

1. Read `docs/plan/{plan-name}/plan.md` and every `task_N.md` for that plan.
2. Map the plan onto the schema in [references/data-schema.md](references/data-schema.md): goal, context (current behavior, why, constraints/gotchas), the file list with an honest blast-radius rating per file (including consumers outside this repo, even ones you have to ask about), the dependency edges between them, the numbered steps (one-line summary, real diff, reasoning, files touched, risk, and a narration of system state after the step), and the tests.
3. Determine the output path: `~/tmp/{project-slug}/reports/{plan-name}.html`, where `project-slug` is the repo directory's basename, kebab-cased. Create the directory if it doesn't exist.
4. Copy [templates/plan.html](templates/plan.html) to that path, then replace only the object between the `PLAN_DATA_START` / `PLAN_DATA_END` markers with the real data - the rendering engine below the markers is complete and generic; don't touch it.
5. Tell the user the file path and that opening it in a browser gives the full interactive view: the graph, the walkable timeline, flaggable steps, and a "Review notes" export.
6. If the user comes back with a pasted review-notes block, treat it as new input: resolve each flagged question by updating `plan.md` / the task files first, then regenerate the HTML (steps 2-4) so the artifact reflects the resolved plan.
