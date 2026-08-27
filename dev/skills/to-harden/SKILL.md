---
name: to-harden
description: Run a deterministic quality gauntlet over a change - dependency rules, coverage-weighted complexity scoring, and mutation testing - looping fresh-context fix agents until every check passes. Use after implement to harden a change beyond its own test suite, or on request to pay down accumulated quality debt.
disable-model-invocation: true
---

# To Harden

Put the code through deterministic tools that cannot be argued with, and loop until they pass.
Prompted quality rules soften into guidelines as a context grows; a checker's exit code does not.
You are the orchestrator: run the tools, dispatch fix agents with minimal prompts, verify, repeat.
Never weaken a check to make it pass.

Invoking this skill is the task - detect the scope yourself and start at step 1; do not ask what to harden.

## 1. Scope

Default scope is the current change: the branch diff against the default branch, per the diff-scope rules in [../../references/plan-layout.md](../../references/plan-layout.md).
Full-repo hardening only when the user asks for it - it is expensive, and the loop is the same.
Read `.dev/{plan-name}/spec.md` when one matches the branch, for the Validation block and the change plan's file lists; degrade gracefully without one.

## 2. Tools

Three checks, run cheapest first. Acquire each per [references/tools.md](references/tools.md): use the repo's existing tooling if present, else the ecosystem's established tool, else have an agent build a small repo-fitted one and commit it so the next run reuses it. Never weaken or skip a tool because acquiring it is work.

1. **Dependency rules** - check the in-scope files against `docs/dependencies.md` ([../../references/dependency-rules.md](../../references/dependency-rules.md), which owns the checker semantics). Skip with a clear note when the file is absent; never invent rules.
2. **Coverage-weighted complexity** - per function in scope: cyclomatic complexity combined with test coverage into a single score. High complexity with full path coverage is acceptable; high complexity with uncovered paths is the finding.
3. **Mutation testing** - mutate the in-scope source (flip comparisons, boundaries, signs, returns), run the relevant tests per mutant; every surviving mutant is a missing or toothless test.

## 3. The loop

For each tool, in order:

1. Run it; collect the violations.
2. Dispatch fixes: one fresh-context agent per independent area, launched in a single message, each given only the violation list for its area, the relevant file paths, and the fix vocabulary - kill a mutant by adding the test that catches it; cut a score by splitting the function or covering its paths; resolve a dependency violation by inverting the dependency, inserting an interface, or splitting the module. Agents never edit thresholds, rules files, or the tools themselves, and never delete a test to make a mutant moot.
3. Re-run the tool until clean, then run the spec's Validation block (or the repo's test suite) to prove the fixes broke nothing.
4. A violation that resists two fix rounds on the same root cause, or that the change seems to legitimately require, is a human call: stop and present it - it is either a real defect, a threshold worth changing, or a rule the spec should have amended.

## 4. Thresholds are decisions

Defaults: complexity-coverage score at most 6 per function; zero surviving mutants in scope; zero dependency violations.
Agent-written code tolerates a higher complexity threshold than the human default of 4 - agents hold more paths in working memory - but where the line sits is a decision, not a config value.
When the user accepts a different threshold, record it in `docs/decisions.md` as a `D-` entry (notation in [../../references/decision-ledger.md](../../references/decision-ledger.md)), dated and sourced to this run; the next run reads it from there instead of re-arguing.
Never adjust a threshold silently to make a run pass.

## 5. Report

Per tool: violations found, fixed, and surviving (with the human call each is waiting on).
Name the tools acquired or built this run and where they live, so the next run is cheaper.
State the scope honestly - "hardened the diff" is not "hardened the repo".
Recommend next steps, never invoking them: `to-review` for judgment-based verification (this gauntlet checks mechanics, not meaning) and `commit` for the accumulated fixes.
