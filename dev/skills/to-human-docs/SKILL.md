---
name: to-human-docs
description: Render the project's docs/ knowledge base as a single self-contained interactive HTML map - clustered by area, cross-referenced, with a decisions timeline, plan status and verdicts, and the open backlog - saved outside the repo. Use when the user wants to see the whole project's documentation and status at a glance, review docs visually, or asks for an HTML or visual version of the docs.
disable-model-invocation: true
---

# To Human Docs

Turn the standing `docs/` tree into one explorable map: what exists, how it connects, what's still a stub, what decisions were made, and where every plan stands - instead of opening twenty files.

Requires a `docs/` tree already created by `/install`.
If none exists, tell the user to run `/install` first - this skill visualizes the docs, it doesn't create them.

Never write output inside the project repo.
These are throwaway, human-facing artifacts, not project history; the repo must never store or commit them.

Invoking this skill with a docs/ tree in view is the task - proceed immediately, don't wait for further instructions.

## Workflow

1. Read `docs/README.md` for the read order, then every file under `docs/product/`, `docs/architecture/` (including `decisions/`), `docs/engineering/`, `docs/operations/`, `docs/governance/`, `docs/backlog.md` if present, and every `docs/plan/{plan-name}/` directory (`plan.md`, its `task_N.md` files, and its latest `review_N.md` if one exists).
2. Map what you read onto the schema in [references/data-schema.md](references/data-schema.md): the areas and their docs (status from each doc's `Status: stub` line), cross-reference edges (real markdown links between docs, not inferred ones), the decisions list, the backlog rows, and the plans list (success criteria, task completion, latest review verdict).
3. Determine the output path: `~/tmp/{project-slug}/reports/docs-map.html`, where `project-slug` is the repo directory's basename, kebab-cased. Create the directory if it doesn't exist.
4. Copy [templates/docs-map.html](templates/docs-map.html) to that path, then replace only the object between the `DOCS_DATA_START` / `DOCS_DATA_END` markers with the real data - the rendering engine below the markers is complete and generic; don't touch it.
5. Tell the user the file path and that opening it in a browser gives the full explorable view: the clustered map, decisions, plan status, and backlog, with search to filter all of it at once.
6. This is a snapshot, not a live view - if the user has since changed the docs (through the plan/review loop), regenerate it (steps 1-4) rather than assuming the old file is still accurate.
