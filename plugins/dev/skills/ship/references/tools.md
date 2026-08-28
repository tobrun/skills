# Acquiring the Tools

The gauntlet needs three deterministic tools.
The acquisition ladder, per tool, is: the repo's existing tooling, else the ecosystem's established tool, else a small repo-fitted script an agent writes.
Never hand-roll what the ecosystem already maintains, and never download a generic harness wholesale - fit the tool to this repo, commit it, and reuse it on every later run.

## Where tools live

Repo-fitted scripts and configs go under `tools/harden/` in the consuming repository, committed with a README line saying what each does and how to invoke it.
The first run pays the acquisition cost; every later run - and any other agent - reuses them.
Check `tools/harden/` before acquiring anything.

## 1. Dependency checker

Almost always a repo-fitted script: parse the `rules` block of `docs/dependencies.md` (format in [../../../references/dependency-rules.md](../../../references/dependency-rules.md)), glob-match the in-scope files to modules, extract static imports with the language's own tooling (a compiler API, an AST module, or a disciplined grep for import statements), and print each forbidden edge as `file -> file (module -> module)`.
Ecosystem tools exist for some stacks (dependency-cruiser for JS/TS, import-linter for Python, ArchUnit for JVM); prefer one when the repo already uses it or adoption is one config file that mirrors `docs/dependencies.md` - but `docs/dependencies.md` stays the single source of truth, so generate the tool's config from it rather than maintaining two rule sets.

## 2. Coverage-weighted complexity

The score per function combines cyclomatic complexity with test coverage so that only *uncovered* complexity fails: complexity squared, scaled down by the fraction of the function's paths the tests execute. A fully covered function scores its complexity; an uncovered one scores its complexity squared.

- Coverage comes from the repo's existing coverage runner (jest/vitest `--coverage`, `coverage.py`, `go test -cover`, JaCoCo, tarpaulin). If the repo has none, wiring the standard one up is part of this step.
- Complexity comes from the ecosystem's standard analyzer (eslint `complexity` rule, `radon`, `gocyclo`, checkstyle) or, failing that, a small AST script.
- A repo-fitted script under `tools/harden/` joins the two reports and prints each function over threshold as `file:function score (complexity N, coverage P%)`.

Scope the report to functions the diff touched; pre-existing offenders elsewhere are noted, not fixed, unless the run is full-repo.

## 3. Mutation testing

Prefer the ecosystem's mutation framework - Stryker (JS/TS), mutmut or cosmic-ray (Python), PIT (JVM), cargo-mutants (Rust), go-mutesting (Go).
These handle mutant generation, test selection, and reporting far better than a hand-rolled loop; write only the thin config that scopes them.
Hand-roll only when the ecosystem has nothing: an agent-written script that applies one mutation at a time (flip `<` to `<=`, `==` to `!=`, `+` to `-`, negate conditions, drop return values), runs the narrowest relevant test command, and records survivors.

Keeping it affordable:

- **Scope to the diff**: mutate only in-scope files, run only the tests that cover them (most frameworks do incremental or per-file runs; use that).
- Set a per-mutant test timeout so an infinite-loop mutant cannot hang the run.
- Equivalent mutants (mutations that provably cannot change behavior) are the one legitimate survivor category: mark them as such in the report with the reasoning, don't chase them forever - two fix rounds, then escalate per the loop rule.

## Fix-agent prompts

Keep them minimal - the violation list, the file paths, the fix vocabulary, nothing else.
The agents inherit no conversation and need none: a surviving mutant at `cart.ts:41 (< flipped to <=)` plus "write the test that kills it, at the layer the surrounding tests use" is a complete task.
Do not paste tool source, spec prose, or this reference into fix prompts; long prompts are how rules soften.
