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
{skill-dir}/scripts/init_docs.sh [--evals]
```

It copies the templates in `templates/` into the repo and never overwrites an existing file, so re-running is always safe and only fills gaps.
`engineering/evals.md` only makes sense for ML or agent-based projects: pass `--evals` when the repo has eval frameworks, datasets, or prompt/model code (or the user says the new project will be one); otherwise it is omitted entirely.
The skeleton it creates:

```
docs/
├── README.md                 # index: what lives where, read order
├── product/                  # product.md, non-goals.md, glossary.md
├── architecture/             # architecture.md, data-model.md, api.md, decisions/
├── engineering/              # tech-stack.md, conventions.md, test.md, evals.md (--evals only)
├── operations/               # deploy.md, observability.md, security.md, incidents.md
├── governance/               # policy.md, cost.md
└── agents.md                 # operating instructions for coding agents
AGENTS.md                     # root pointer to docs/agents.md (cross-tool convention)
```

If the repo has no `CLAUDE.md`, offer to create one containing `@docs/agents.md` so Claude Code loads the same instructions; never modify an existing `CLAUDE.md` without asking.

## 2. Detect the mode

Look for substantive source code.
An existing codebase gets populated now (step 3); a fresh project keeps the stubs and gets populated by the normal workflow as the project grows (step 4).

## 3. Existing codebase: populate to completion

Install is not finished while any doc is half-populated.
Populate in three passes, because code and humans know different things.

**Derive from code** (fan out one agent per area as a parallel Agent batch; each agent rewrites its own doc files, so there are no write conflicts):

- `architecture/` from the module structure, dependency direction, storage, and interfaces actually present.
- `engineering/tech-stack.md` and `conventions.md` from what the code observably does, not what anyone wishes it did.
- `engineering/test.md` from the real test layout, runners, and patterns.
- `operations/` from CI/CD configs, Dockerfiles, infra code, logging and metrics calls.

Each agent writes only what it can prove (every claim needs a file or config it actually saw) and returns its gaps to you: everything it could not determine, inferred, or would have to guess.
Gaps are reported back, never written into the docs as open questions.

**Close the gaps with the user.**
Consolidate and dedupe the gaps from all agents, add the questions code can never answer (`product/product.md`, `non-goals.md`, `glossary.md` seeds, `governance/policy.md`, `governance/cost.md`, and the judgment calls in `engineering/evals.md` when it exists), and resolve them with the AskUserQuestion tool: batches of up to four focused questions per round, offering concrete options when the code suggests plausible answers, over as many rounds as it takes.
Write every answer into the affected doc as you go.

**Track what remains.**
When the user defers a question or the answer does not exist yet (for example no SLOs have been defined), the doc still gets finished: state the current truth plainly ("No SLOs are defined yet.") and record the missing piece in `docs/backlog.md` under a `Potential improvements` header (create the file if it does not exist; append to the section if it does):

```markdown
# Backlog

## Potential improvements

Missing pieces identified during install.
Burn this list down through the normal plan loop; remove rows as they are resolved.

| Doc | Missing | Question to answer | Next step |
```

When install finishes, every standing doc is complete and its `Status: stub` line is removed; the only open items in the repo live under Potential improvements in `docs/backlog.md`.

## 4. New project: populate as you work

Leave the stubs in place and tell the user how population happens: the `to-plan` skill's Documentation impact table checks these docs on every plan, `implement` executes the doc updates a task owns, and `to-review` blocks on missed doc-impact rows.
Early plans will naturally fill `product/`, `glossary`, and the first ADRs.

## Status lifecycle

Unfinished docs carry `Status: stub` under their title: template skeleton, not yet completed for this project, safe to rewrite wholesale.
A completed doc has no status line at all; done is the default state, not a label.

There is no draft state: a doc is either a stub or done.
A completed doc documents current reality, including honest absences ("No SLOs are defined yet."); unknowns live in `docs/backlog.md` under Potential improvements, never as open questions inside a doc.
Remove the stub line only when the user has confirmed the doc's content, and from then on changes go through the plan/review loop like code; never quietly re-add it.

## Architectural decisions

Decisions live one file per decision under `docs/architecture/decisions/`, numbered `NNNN-slug.md`.
`0000-template.md` is the blank; copy it to the next free number.
During population, record only decisions that are visible in the code and clearly deliberate (for example the database choice); mark their status as `accepted (reconstructed)` so nobody mistakes archaeology for a recorded rationale.
