---
name: to-pitch
description: Package a completed change - its plan, implementation notes, and verification evidence - into a local or shareable buy-in document. Use once implementation is done and the change needs buy-in or visibility beyond the author, not for trivial one-line fixes.
---

# To Pitch

Turn finished work into a doc that gets someone else to say yes: demo first, then the reasoning, then the evidence.
This is purely presentational - it never gates anything and never implies otherwise.

## Right-sizing

A one-line fix or an internal refactor with no visible behavior change doesn't warrant buy-in.
Say so and skip rather than manufacture ceremony.

## Workflow

1. Locate the plan: match the current branch name to a `.dev/{plan-name}/` slug, the same convention `to-tasks` uses.
   Ask which plan only if more than one is a plausible match; otherwise proceed without waiting for clarification.
2. Read whatever exists, degrading gracefully when something doesn't:
   - `.dev/{plan-name}/plan.md` and any `task_N.md` - Goal, Success criteria, before/after.
   - `/tmp/{project-slug}/reports/{topic-slug}-discovery-notes.md` (from `discover`), if this plan started there - the chosen direction and any mockups.
   - `.dev/{plan-name}/implementation-notes.md` (from `implement`) - what was done, and any Deviations.
   - `/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`'s data block - the scenario summary, as verification evidence.
3. Capture the demo. For UI-affecting changes, use an installed `run` skill when direct skill invocation is available; otherwise launch the app from its documented command. Record a short clip with available browser automation when GIF capture exists, or use a concise screenshot sequence otherwise. For non-UI changes, lead with the clearest before/after example.
4. Map everything onto `PITCH_DATA` per [references/data-schema.md](references/data-schema.md), rendered into [templates/pitch.html](templates/pitch.html) in this section order: Demo, Why, What changed, How we verified it, Deviations (omit the section entirely when none were logged), Try it yourself.
   Before first authoring or restyling the template, load an installed artifact or frontend design skill; a plain data refresh on an existing template doesn't need it again.
5. Write the rendered file to `/tmp/{project-slug}/reports/{plan-name}-pitch.html`, replacing only the data block between the markers - the rendering engine below them is generic, don't touch it.
   Give the user the local path. If an artifact-publishing tool is available, publish only when the user asks for a shareable link, using a stable pitch favicon and a title and description from the plan. If no publisher exists, the local HTML remains the deliverable.

## What good pitch content looks like

- Demo first, always - a reviewer who only looks at the top of the page should already get it.
- Why: the goal and the problem in the reviewer's terms, not implementation detail.
- What changed: a real before/after plus the concrete files touched, not a restated diff.
- How it was verified: the e2e summary and the test layers actually exercised, as evidence - "14/14 scenarios passing across unit, integration, e2e" beats "thoroughly tested".
- Deviations: only if `implementation-notes.md` logged any - what edge case forced the conservative call, and why it still holds.
- Try it yourself: concrete steps a reviewer follows to run or reach the change themselves.
