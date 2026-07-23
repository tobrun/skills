# Orchestration

The default mode is two batches of plain parallel subagents via the Agent tool.
No dynamic workflows are involved; this keeps the review free of the dynamic-workflow confirmation and its token profile.
A Workflow-tool variant exists at the bottom for explicitly requested heavyweight runs only.

## Batch 1: lens agents

Launch one agent per selected lens, all in a single message so they run concurrently.
Each lens prompt is assembled from:

1. A role line: `You are the "{key}" voice on a code-review panel; other lenses cover other concerns.`
2. The lens definition plus the shared rules from `lenses.md`.
3. The brief, and the plan context when a plan was found.
4. The diff location: `Read the full diff from {diffFile}; the repo working tree holds the post-diff state. Read repo files whenever the diff alone is not enough to judge.`
5. The output contract below.

Output contract (the agent's final message must be exactly one fenced JSON block):

```json
{
  "verdict": "PASS | CONCERNS | BLOCK",
  "findings": [
    {
      "severity": "BLOCK | CONCERN | NIT",
      "file": "path/relative/to/repo",
      "line": 1,
      "title": "one line",
      "detail": "2-4 lines naming the evidence",
      "scenario": "what triggers it (required for BLOCK)"
    }
  ],
  "good": ["up to 5 bullets"]
}
```

If an agent errors or returns something unparseable, record it as a failed lens and continue; the report notes it so the verdict is honestly partial.
Never retry a failed lens more than once.

## Batch 2: verifiers

Collect every BLOCK and CONCERN from all lenses (NITs skip verification) and launch one verifier per finding, again all in a single message.
Verifier prompt:

```
Adversarially verify this code-review finding from the "{lens}" lens.
Your job is to REFUTE it.
{finding as JSON}
Read the diff at {diffFile} and the actual files in the repo.
Check whether the claimed problem is real: does the scenario actually
trigger, is the claim accurate against the files, does something else
already handle it?
Reply with exactly one fenced JSON block:
{"status": "CONFIRMED | PLAUSIBLE | REFUTED", "reason": "..."}
CONFIRMED = you reproduced the reasoning against real files and it holds.
PLAUSIBLE = you could not refute it, but could not fully confirm it either.
REFUTED = wrong, unreachable, or already handled; say exactly why.
```

Aggregation of the verified results is plain reasoning per step 6 of the skill; do it yourself, not with another agent.

## Heavy mode: Workflow tool (explicit opt-in only)

Use this only when the user has explicitly asked for a workflow or an exhaustive run; it triggers the dynamic-workflow confirmation dialog.
It buys schema-validated outputs, pipelining (findings verify while other lenses still review), and `/workflows` progress.
Pass `diffFile`, `brief`, `planContext`, `lenses` (as `{key, prompt}` with the full assembled lens prompt), and `priorFindings` via `args`.

```js
export const meta = {
  name: 'to-review',
  description: 'Concern-based diff review with adversarial verification of findings',
  phases: [
    { title: 'Review', detail: 'one agent per selected lens' },
    { title: 'Verify', detail: 'refute-or-confirm each finding' },
    { title: 'Recheck', detail: 'prior findings fixed?' },
  ],
}

const FINDINGS = {
  type: 'object',
  required: ['verdict', 'findings', 'good'],
  properties: {
    verdict: { enum: ['PASS', 'CONCERNS', 'BLOCK'] },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'file', 'line', 'title', 'detail'],
        properties: {
          severity: { enum: ['BLOCK', 'CONCERN', 'NIT'] },
          file: { type: 'string' },
          line: { type: 'integer' },
          title: { type: 'string' },
          detail: { type: 'string' },
          scenario: { type: 'string' },
        },
      },
    },
    good: { type: 'array', items: { type: 'string' }, maxItems: 5 },
  },
}

const VERDICT = {
  type: 'object',
  required: ['status', 'reason'],
  properties: {
    status: { enum: ['CONFIRMED', 'PLAUSIBLE', 'REFUTED'] },
    reason: { type: 'string' },
  },
}

const RECHECK = {
  type: 'object',
  required: ['fixed', 'evidence'],
  properties: {
    fixed: { type: 'boolean' },
    evidence: { type: 'string' },
  },
}

const { diffFile, brief, planContext, lenses, priorFindings } = args

const lensPrompt = (l) => [
  `You are the "${l.key}" voice on a code-review panel; other lenses cover other concerns.`,
  l.prompt,
  `Brief: ${brief}`,
  planContext ? `Plan context:\n${planContext}` : '',
  `Read the full diff from ${diffFile}. Read surrounding source files when the diff is not enough.`,
  `Return findings for your lens only.`,
].filter(Boolean).join('\n\n')

const verifyPrompt = (f, l) => [
  `Adversarially verify this code-review finding from the "${l.key}" lens. Your job is to REFUTE it.`,
  JSON.stringify(f),
  `Read the diff at ${diffFile} and the actual files in the repo. Check whether the claimed problem is real:`,
  `does the scenario actually trigger, is the code path reachable, does something else already handle it?`,
  `CONFIRMED = you reproduced the reasoning against real code and it holds.`,
  `PLAUSIBLE = you could not refute it, but could not fully confirm the scenario either.`,
  `REFUTED = the finding is wrong, unreachable, or already handled; say exactly why.`,
].join('\n')

const rechecks = priorFindings.length
  ? parallel(priorFindings.map((f) => () =>
      agent(
        `A previous review reported:\n${JSON.stringify(f)}\nRead the current code and the diff at ${diffFile}. Is it fixed now? Cite the fixing change or what is still missing.`,
        { label: `recheck:${f.file}`, phase: 'Recheck', schema: RECHECK },
      ).then((r) => r && { ...f, recheck: r })))
  : Promise.resolve([])

const results = await pipeline(
  lenses,
  (l) => agent(lensPrompt(l), { label: `review:${l.key}`, phase: 'Review', schema: FINDINGS }),
  (review, l) => {
    if (!review) return null
    const toVerify = review.findings.filter((f) => f.severity !== 'NIT')
    return parallel(toVerify.map((f) => () =>
      agent(verifyPrompt(f, l), { label: `verify:${f.file}:${f.line}`, phase: 'Verify', schema: VERDICT })
        .then((v) => v && { ...f, lens: l.key, verification: v })))
      .then((verified) => ({
        lens: l.key,
        good: review.good,
        nits: review.findings.filter((f) => f.severity === 'NIT').map((f) => ({ ...f, lens: l.key })),
        findings: verified.filter(Boolean),
      }))
  },
)

return { lenses: results.filter(Boolean), rechecks: (await rechecks).filter(Boolean) }
```
