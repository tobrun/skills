# Orchestration Template

Run the panel with the Workflow tool using this script shape.
Invoking it from this skill is a user-sanctioned use of the Workflow tool.

Pass everything the script needs via `args`:

- `diffFile`: absolute path of the scratch file holding the diff
- `brief`: the intent brief from step 2 of the skill
- `planContext`: relevant plan/task excerpts (acceptance criteria, seams, doc-impact rows), or `""`
- `lenses`: array of `{ key, prompt }`, where `prompt` is the lens definition plus the shared rules from `lenses.md`
- `priorFindings`: unresolved findings from the previous review, or `[]`

## Script

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

## Notes for the orchestrator

- Launch with `Workflow({ script, args })`; do not pin `model` on the agent calls, so the panel inherits the session model.
- A `null` entry in `lenses` means that lens died; report it as a failed lens, never silently.
- Aggregation (drop REFUTED, demote unconfirmed BLOCKs, dedupe by file and line, verdict roll-up) is plain reasoning on the returned object; do it yourself per step 6 of the skill, not with another agent.
- If the Workflow tool is unavailable in the session, fall back to the Agent tool: launch the lens agents in one parallel batch with the same prompts and schemaless text output, then verify findings in a second batch.
