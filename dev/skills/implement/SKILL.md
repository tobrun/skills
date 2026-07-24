---
name: implement
description: Implement a piece of work based on a spec or set of tickets, test-first. Use when the user asks to implement a feature, fix a bug, or work through tickets, wants red-green TDD cycles, or mentions integration tests.
disable-model-invocation: true
---

# Implement

Implement the work in the spec or tickets, test-first.
The TDD guidance below governs every cycle - consult it before and during the loop, not after.

When exploring the codebase (if present): read `docs/product/glossary.md` for domain vocabulary, follow `docs/engineering/conventions.md` and `test.md`, and respect the ADRs under `docs/architecture/decisions/` for the area you're touching.

## Workflow

1. Read the spec or tickets and explore the relevant code.
2. Agree the seams under test with the user before writing any test.
3. Implement in vertical slices: red -> green.
4. Typecheck and run single test files regularly; run the full suite once at the end.
5. Ask the user to run `to-review` on the work - reviews are human-triggered only, never launch the panel yourself.
6. Commit to the current branch.

## What a good test is

Tests verify behavior through public interfaces, not implementation details, so they survive refactors.
A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists.
See [references/tests.md](references/tests.md) and [references/mocking.md](references/mocking.md).

## Seams - where tests go

A **seam** is the public boundary you test at, never internals.
Before writing any test, write down the seams under test and confirm them with the user; no test is written at an unconfirmed seam.
This is how testing effort lands on critical paths instead of every edge case.
Ask: "What's the public interface, and which seams should we test?"

## Anti-patterns

- **Implementation-coupled** - mocks internal collaborators, tests private methods, or verifies through a side channel. Tell: breaks on refactor even when behavior hasn't changed.
- **Tautological** - the assertion recomputes the expected value the way the code does, so it can never disagree with the code. Expected values need an independent source of truth: a literal, a worked example, the spec.
- **Horizontal slicing** - all tests first, then all implementation. Tests verify imagined shape, not real behavior, and go insensitive to change. Work in **vertical slices** instead: one test -> one implementation -> repeat, each test a tracer bullet.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to `to-review`, not the red -> green cycle.
