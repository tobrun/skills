# workflow

Development workflow skills for Claude Code.

## Skills

### implement

Implements a piece of work based on a spec or set of tickets, test-first.
The skill drives a strict TDD loop at pre-agreed seams:

1. Read the spec or tickets and explore the codebase.
2. Agree the seams under test with the user.
3. Implement in vertical slices with the red -> green loop.
4. Typecheck and run single test files regularly; run the full suite once at the end.
5. Review the work with the `code-review` skill.
6. Commit to the current branch.

The skill bundles reference docs on what makes a good test (`references/tests.md`) and when mocking is appropriate (`references/mocking.md`).

Invoke it explicitly with `/implement` and point it at a spec or tickets.
Model-triggered invocation is disabled; the workflow commits code, so it only runs when you ask for it.

## Installation

```bash
/plugin marketplace add ~/ws/skills
/plugin install workflow@tobrun-skills
```
