# The Gauntlet Loop

How phase 1 of `ship` runs its three checks to completion.
The check definitions and their acquisition ladder live in [tools.md](tools.md); this file owns the loop, the fix agents, and the thresholds.

## The loop

For each tool, in order:

1. Run it; collect the violations.
2. Dispatch fixes: one fresh-context agent per independent area, launched in a single message, each given only the violation list for its area, the relevant file paths, and the fix vocabulary below.
3. Re-run the tool until clean, then run the spec's Validation block (or the repo's test suite) to prove the fixes broke nothing; skip that run when the tool dispatched no fixes.
4. A violation that resists two fix rounds on the same root cause, or that the change seems to legitimately require, is a human call: stop and present it - it is either a real defect, a threshold worth changing, or a rule the spec should have amended.

## Fix vocabulary

- Kill a mutant by adding the test that catches it.
- Cut a complexity-coverage score by splitting the function or covering its paths.
- Resolve a dependency violation by inverting the dependency, inserting an interface, or splitting the module.

Fix agents never edit thresholds, rules files, or the tools themselves, and never delete a test to make a mutant moot.

## Thresholds are decisions

Defaults: complexity-coverage score at most 6 per function; zero surviving mutants in scope; zero dependency violations.
Agent-written code tolerates a higher complexity threshold than the human default of 4 - agents hold more paths in working memory - but where the line sits is a decision, not a config value.
When the user accepts a different threshold, record it in `docs/decisions.md` as a `D-` entry (notation in [../../../references/decision-ledger.md](../../../references/decision-ledger.md)), dated and sourced to this run; the next run reads it from there instead of re-arguing.
Never adjust a threshold silently to make a run pass.
