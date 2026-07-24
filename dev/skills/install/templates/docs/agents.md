# Agent Operating Instructions

Status: stub

Operating instructions for coding agents working in this repository.

## Before writing code

- Read [README.md](README.md) for the docs read order; at minimum know the glossary, the non-goals, and the ADRs in your area.
- Use the domain vocabulary from [product/glossary.md](product/glossary.md) in code, tests, and docs.
- Follow [engineering/conventions.md](engineering/conventions.md) and the testing approach in [engineering/test.md](engineering/test.md).

## How work flows

- Non-trivial work starts as a plan in `docs/plan/{plan-name}/plan.md` with an explicit Documentation impact table.
- Implementation is test-first at pre-agreed seams; reviews verify the plan was honored, including its doc updates.
- Architectural decisions are recorded as ADRs under [architecture/decisions/](architecture/decisions/); do not contradict an accepted ADR without recording a superseding one.

## Keeping these docs alive

- If a change makes any standing doc wrong, updating that doc is part of the change, not follow-up work.
- Do not edit completed docs (no `Status: stub` line) casually; those changes go through the plan/review loop like code.
- Auto-generated files (changelogs, lockfiles) are never edited by hand.

## Project-specific rules

(Add rules specific to this project here.)
