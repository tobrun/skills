# Docs

The standing knowledge base of this project.
These docs are requirements and context that outlive any single change; they are updated continuously through the plan/review loop, not written once.

## What lives where

| Area | Contents |
| ---- | -------- |
| [product/](product/) | What it does, who it's for, why; explicit non-goals; the glossary of domain terms |
| [architecture/](architecture/) | System shape, data model, interfaces, and one ADR per decision under `decisions/` |
| [engineering/](engineering/) | Tech stack, conventions, testing approach; ML/agent projects also keep `evals.md` here |
| [operations/](operations/) | Deploy, observability, security, incident history |
| [governance/](governance/) | Policy and cost/budget expectations |
| [agents.md](agents.md) | Operating instructions for coding agents |
| plan/ | Working memory: plans, task files, and reviews produced by the workflow skills |

## Read order for new agents and humans

1. [product/product.md](product/product.md) and [product/non-goals.md](product/non-goals.md): what we are building and deliberately not building.
2. [product/glossary.md](product/glossary.md): the vocabulary everything else uses.
3. [architecture/architecture.md](architecture/architecture.md), then the ADRs relevant to your area.
4. [engineering/conventions.md](engineering/conventions.md) and [engineering/test.md](engineering/test.md) before writing code.
5. [agents.md](agents.md) if you are a coding agent.

## Doc status

Unfinished docs carry a `Status: stub` line under their title; a completed, human-confirmed doc has no status line, and changes to it go through the plan/review loop.
Docs state current reality honestly, including absences; missing information is tracked as rows in `gaps.md` (if present) until resolved, never as open questions inside a doc.
