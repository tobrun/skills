---
name: install
description: Create the standing docs/ knowledge base of a project (product, architecture, engineering, operations, governance, agents.md) and populate it from an existing codebase. Use when starting a new project, onboarding an existing codebase, or when the user asks to initialize project docs.
disable-model-invocation: true
---

# Install

Create the standing knowledge base of the project under `docs/` and make it truthful.
Standing docs hold what outlives any one change: requirements, architecture, conventions, operations, governance.
Working memory (plans, tasks, reviews) lives in `docs/plan/`, owned by the `to-plan` family; this skill does not touch it.

## 1. Create the skeleton

Run the bundled script from the repo root:

```bash
{skill-dir}/scripts/init_docs.sh
```

It copies the templates in `templates/` into the repo and never overwrites an existing file, so re-running is always safe and only fills gaps.
The skeleton it creates:

```
docs/
├── README.md                 # index: what lives where, read order
├── product/                  # product.md, non-goals.md, glossary.md
├── architecture/             # architecture.md, data-model.md, api.md, decisions/
├── engineering/              # tech-stack.md, conventions.md, test.md, evals.md
├── operations/               # deploy.md, observability.md, security.md, incidents.md
├── governance/               # policy.md, cost.md
└── agents.md                 # operating instructions for coding agents
AGENTS.md                     # root pointer to docs/agents.md (cross-tool convention)
```

If the repo has no `CLAUDE.md`, offer to create one containing `@docs/agents.md` so Claude Code loads the same instructions; never modify an existing `CLAUDE.md` without asking.

## 2. Detect the mode

Look for substantive source code.
An existing codebase gets populated now (step 3); a fresh project keeps the stubs and gets populated by the normal workflow as the project grows (step 4).

## 3. Existing codebase: populate

Populate in two passes, because code and humans know different things.

**Derive from code** (fan out one agent per area, via the Workflow tool or a parallel Agent batch; each agent explores the repo and rewrites its own doc files, so there are no write conflicts):

- `architecture/` from the module structure, dependency direction, storage, and interfaces actually present.
- `engineering/tech-stack.md` and `conventions.md` from what the code observably does, not what anyone wishes it did.
- `engineering/test.md` from the real test layout, runners, and patterns.
- `operations/` from CI/CD configs, Dockerfiles, infra code, logging and metrics calls.

Each agent replaces stub sections with content, sets the doc header to `Status: draft`, and records anything inferred rather than observed under an `Open questions` heading at the top of the doc.
Nothing in a draft may be invented: every claim needs a file or config the agent actually saw.

**Interview the human** for what code cannot say: `product/product.md`, `non-goals.md`, `glossary.md` seeds, `governance/policy.md`, `governance/cost.md`, and the judgment calls in `engineering/evals.md`.
Ask a handful of concrete questions at a time; write their answers into the docs and leave the rest as stubs rather than guessing.

## 4. New project: populate as you work

Leave the stubs in place and tell the user how population happens: the `to-plan` skill's Documentation impact table checks these docs on every plan, `implement` executes the doc updates a task owns, and `to-review` blocks on missed doc-impact rows.
Early plans will naturally fill `product/`, `glossary`, and the first ADRs.

## Status lifecycle

Every standing doc carries a status line under its title:

- `Status: stub` - skeleton only, safe to rewrite wholesale.
- `Status: draft` - populated but not human-confirmed; open questions listed at the top.
- `Status: maintained` - a human signed off; changes now go through the plan/review loop like code.

Promote a doc only when the user confirms its content; never demote silently.

## Architectural decisions

Decisions live one file per decision under `docs/architecture/decisions/`, numbered `NNNN-slug.md`.
`0000-template.md` is the blank; copy it to the next free number.
During population, record only decisions that are visible in the code and clearly deliberate (for example the database choice); mark their status as `accepted (reconstructed)` so nobody mistakes archaeology for a recorded rationale.
