---
name: implement
description: Implement a piece of work based on a spec or set of tickets, test-first. Use when the user asks to implement a feature, fix a bug, or work through tickets, wants red-green TDD cycles, or mentions integration tests.
disable-model-invocation: true
---

# Implement

Implement the work described by the user in the spec or tickets.
Work test-first: the TDD guidance below governs every implementation cycle.
Consult it before and during the loop, not after.

When exploring the codebase, read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

## Workflow

1. Read the spec or tickets and explore the relevant parts of the codebase.
2. Agree the seams under test with the user before writing any test (see "Seams" below).
3. Implement in vertical slices using the red -> green loop.
4. Run typechecking regularly and single test files regularly.
   Run the full test suite once at the end.
5. Once done, use the `code-review` skill to review the work.
6. Commit your work to the current branch.

## What a good test is

Tests verify behavior through public interfaces, not implementation details.
Code can change entirely; tests shouldn't.
A good test reads like a specification - "user can checkout with valid cart" tells you exactly what capability exists - and survives refactors because it doesn't care about internal structure.

See [references/tests.md](references/tests.md) for examples and [references/mocking.md](references/mocking.md) for mocking guidelines.

## Seams - where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside.
Tests live at seams, never against internals.

**Test only at pre-agreed seams.**
Before writing any test, write down the seams under test and confirm them with the user.
No test is written at an unconfirmed seam.
You can't test everything - agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

## Anti-patterns

- **Implementation-coupled** - mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface).
  The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological** - the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code.
  Expected values must come from an independent source of truth - a known-good literal, a worked example, the spec.
- **Horizontal slicing** - writing all tests first, then all implementation.
  Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation.
  Work in **vertical slices** instead - one test -> one implementation -> repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.**
  Write the failing test first, then only enough code to pass it.
  Don't anticipate future tests or add speculative features.
- **One slice at a time.**
  One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.**
  It belongs to the review stage (see the `code-review` skill), not the red -> green implementation cycle.
