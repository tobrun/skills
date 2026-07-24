---
name: install
description: Create the standing docs/ knowledge base of a project (product, architecture, engineering, operations, governance, agents.md) and populate it from an existing codebase. Use when starting a new project, onboarding an existing codebase, or when the user asks to initialize project docs.
disable-model-invocation: true
---

# Install

Create the standing knowledge base under `docs/` and make it truthful.
Standing docs hold what outlives any change: requirements, architecture, conventions, operations, governance.
Working memory (plans, tasks, reviews) lives in `docs/plan/`, owned by the `to-plan` family; this skill does not touch it.

## 1. Create the skeleton

Run the bundled script from the repo root:

```bash
{skill-dir}/scripts/init_docs.sh [--evals]
```

It copies `templates/` into the repo and never overwrites an existing file, so re-running only fills gaps.
Pass `--evals` when the repo has eval frameworks, datasets, or prompt/model code (or the user says the new project will be one) to include `engineering/evals.md`; otherwise it's omitted.

If a `docs/` directory already exists and isn't one this skill produced, the script moves it to `docs-old/` before laying down the fresh skeleton, so nothing is lost or silently mixed with the new structure.
See "Migrating a prior docs directory" below - that knowledge must end up in the new `docs/`, not sit forgotten in `docs-old/`.

```
docs/
├── README.md                 # index: what lives where, read order
├── product/                  # product.md, non-goals.md, glossary.md
├── architecture/             # architecture.md, data-model.md, api.md, decisions/
├── engineering/              # tech-stack.md, conventions.md, test.md, evals.md (--evals only)
├── operations/               # deploy.md, observability.md, security.md, incidents.md
├── governance/                # policy.md, cost.md
└── agents.md                  # operating instructions for coding agents
AGENTS.md                     # root pointer to docs/agents.md (cross-tool convention)
```

If the repo has no `CLAUDE.md`, offer to create one containing `@docs/agents.md`; never modify an existing one without asking.

## 2. Detect the mode

Substantive source code present: populate now (step 3).
Fresh project: keep the stubs, populate as you work (step 4).

## 3. Existing codebase: populate to completion

Install is not finished while any doc is half-populated - every doc ends this step with its `Status: stub` line removed, or a tracked gap in `docs/backlog.md` (never as an open question inside the doc).

**Derive from code** (fan out one agent per area as a parallel Agent batch; each rewrites its own doc files, so there are no write conflicts): `architecture/` from module structure and interfaces present; `engineering/tech-stack.md` and `conventions.md` from what the code observably does; `engineering/test.md` from the real test layout; `operations/` from CI/CD, infra code, logging and metrics calls.
Each agent writes only what it can prove - every claim needs a file or config it actually saw - and returns its gaps instead of guessing.

**Close the gaps with the user.**
Consolidate the agents' gaps, add what code can never answer (`product/`, `non-goals.md`, `glossary.md`, `governance/`, the judgment calls in `evals.md` when present), and resolve with AskUserQuestion: up to four focused questions per round, concrete options where the code suggests plausible answers, as many rounds as it takes.
Write every answer into the doc as you go.

**Track what remains.**
When the user defers a question or no answer exists yet, finish the doc honestly ("No SLOs are defined yet.") and add a row to `docs/backlog.md` under `## Potential improvements` (create the file, or append the section, as needed):

```markdown
# Backlog

## Potential improvements

Missing pieces identified during install. Burn down through the normal plan loop; remove rows as resolved.

| Doc | Missing | Question to answer | Next step |
```

## 4. New project: populate as you work

Leave the stubs; the normal loop fills them - `to-plan`'s Documentation impact table checks these docs on every plan, `implement` executes the doc updates a task owns, `to-review` blocks on missed rows.
Still run the migration below first if `docs-old/` exists - a project can have prior documentation before it has much code.

## Migrating a prior docs directory

If `docs-old/` exists (moved aside by the script, or left over from an unfinished earlier migration), its knowledge must fully move into the new `docs/` - the goal is one source of truth, not two living in parallel.

Read every file under `docs-old/`, regardless of its original structure, and use it as a knowledge source alongside the code and the user:

- During **Derive from code**, fold matching legacy content into the area it belongs to instead of deriving from code alone - a legacy architecture doc supplements what the module structure shows, it doesn't get overwritten by it.
- During **Close the gaps with the user**, check `docs-old/` for answers before asking; present what the legacy docs already say as the starting draft to confirm or correct, rather than asking from a blank page.
- Anything in `docs-old/` that doesn't map cleanly onto the new structure, or that contradicts what you found in code, becomes a `docs/backlog.md` row under Potential improvements - it does not get silently dropped.

Track coverage as you go: every file in `docs-old/` is either merged into a new doc or explicitly logged in the backlog as not reconciled.
Once every file is accounted for, ask the user (via AskUserQuestion) whether to delete `docs-old/` now that its content lives in `docs/`; never delete it without asking, and don't ask before coverage is complete.

## Status lifecycle

`Status: stub` under the title marks an unfinished doc, safe to rewrite wholesale.
A completed doc has no status line - done is the default, not a label.
There is no draft state.
Remove the stub line only once the user has confirmed the doc's content; from then on it changes through the plan/review loop like code, and the line is never quietly re-added.

## Architectural decisions

One file per decision under `docs/architecture/decisions/`, numbered `NNNN-slug.md`; copy `0000-template.md` to the next free number.
During population, record only decisions visible in the code and clearly deliberate (e.g. the database choice), marked `accepted (reconstructed)` so nobody mistakes archaeology for recorded rationale.
