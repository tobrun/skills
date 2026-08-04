# Orchestration

The review always uses independent agents in two batches. Select the transport
without changing the panel:

Both transports use the same scratch root, such as `/tmp/to-review-{session-id}/`,
with a `results/` directory per batch. Result files in that directory are the
only channel for agent output. Never retrieve results by messaging an agent,
waiting for relayed replies, or re-spawning an agent that already finished;
a fresh spawn has none of the original context and its output must not be used.

1. **Native transport (preferred):** when the host provides a multi-agent
   facility, launch all agents in a batch in one native parallel call. This is
   the existing Claude Code and Codex behavior; do not route those hosts
   through subprocesses.
2. **Pi transport:** when `PI_CODING_AGENT=true` and `pi` is available, write
   one prompt file per agent and run
   [scripts/run-pi-agents.sh](../scripts/run-pi-agents.sh). The runner launches
   one isolated `pi --print` process per prompt concurrently and inherits the
   current provider, model, and reasoning level.
3. **Unavailable:** if neither transport exists, stop. The orchestrator must
   not impersonate the panel or review the code itself.

No dynamic workflows are involved by default. A Workflow-tool variant exists
at the bottom for explicitly requested heavyweight runs only.

## Native transport

Use the host's plain subagent tool exactly as provided. Launch all agents of a
batch in a single parallel call. Native subagents receive the prompt contracts
below directly.

Result delivery is file-based, because on some hosts subagents run in the
background and their final message never reaches the orchestrator:

1. Before launching a batch, create `{scratch-root}/{batch}/results/`.
2. Each agent's prompt instructs it to write its JSON report to
   `{scratch-root}/{batch}/results/{safe-agent-name}.json` as its last action,
   then end with a one-line confirmation naming that path. The result file is
   the deliverable; the final message is not.
3. When the host signals that the batch's agents have finished, read the
   result files. Do not poll agents for content in the meantime.
4. A missing or unparseable file after one re-read marks only that agent as
   failed, same as a crashed agent. Do not message it or spawn a replacement.

Agents stay read-only in the repository; their only write is their own result
file under the scratch root.

## Pi transport

Use the shared scratch root. For each batch:

1. Create `prompts/` and `results/` directories dedicated to that batch.
2. Write one `{safe-agent-name}.md` prompt per agent. Include the complete
   prompt contract from the relevant batch below. Tell the process to inspect
   the repository but never modify it.
3. From the repository root, run:

   ```bash
   bash {to-review-skill-root}/scripts/run-pi-agents.sh \
     {batch-root}/prompts \
     {batch-root}/results
   ```

4. Read each `{safe-agent-name}.out` as that agent's final response. A matching
   `.err` or missing/unparseable `.out` marks only that agent as failed.
5. Keep the scratch files until aggregation is complete so malformed output is
   auditable, then remove them.

The runner disables child skills, extensions, prompt templates, and sessions
to prevent recursion and state leakage. It retains project context files and
read-oriented tools (`read`, `bash`, `grep`, `find`, `ls`) so each process can
inspect the diff, surrounding code, and tests independently. Do not add
`write` or `edit`.

## Batch 1: lens agents

Launch one agent per selected lens, all in a single message so they run concurrently.
Each lens prompt is assembled from:

1. A role line: `You are the "{key}" voice on a code-review panel; other lenses cover other concerns.`
2. The lens definition plus the shared rules from `lenses.md`.
3. The brief, and the plan context when a plan was found.
4. The diff location: `Read the full diff from {diffFile}; the repo working tree holds the post-diff state. Read repo files whenever the diff alone is not enough to judge.`
5. The output contract below.

Also state: `Do not modify repository files. This is a read-only review.`
On the native transport, add the result-file instruction from the transport
section; on Pi, the runner captures the final message instead, which must be
exactly one fenced JSON block.

Output contract (the JSON every lens agent must produce):

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

Collect every BLOCK and CONCERN from all lenses (NITs skip verification),
dedupe, and number the findings (`f1`, `f2`, ...) so verdicts map back.
Launch one verifier per finding, again all in a single message.
If that would exceed 10 verifiers, group the findings by file into at most 10
shards and give each verifier its shard; each finding is still verified
independently, one verdict object per finding.
Verifier prompt:

```
Adversarially verify each of these code-review findings, reported by the
named lens. Your job is to REFUTE them.
{findings as JSON, each with its id}
Read the diff at {diffFile} and the actual files in the repo.
Check whether each claimed problem is real: does the scenario actually
trigger, is the claim accurate against the files, does something else
already handle it?
Produce exactly one JSON array with one object per finding:
[{"id": "f1", "status": "CONFIRMED | PLAUSIBLE | REFUTED", "reason": "..."}]
CONFIRMED = you reproduced the reasoning against real files and it holds.
PLAUSIBLE = you could not refute it, but could not fully confirm it either.
REFUTED = wrong, unreachable, or already handled; say exactly why.
```

Delivery follows the transport: on native, the verifier writes the array to
its result file; on Pi, it replies with the array as one fenced JSON block.

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
