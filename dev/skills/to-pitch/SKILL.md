---
name: to-pitch
description: Package a completed change - its plan, implementation notes, and verification evidence - into a shareable buy-in doc published as an Artifact. Use once implementation is done and the change needs buy-in or visibility beyond the author, not for trivial one-line fixes.
disable-model-invocation: true
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
   - `~/tmp/{project-slug}/reports/{topic-slug}-discovery-notes.md` (from `discover`), if this plan started there - the chosen direction and any mockups.
   - `.dev/{plan-name}/implementation-notes.md` (from `implement`) - what was done, and any Deviations.
   - `~/tmp/{project-slug}/reports/{plan-name}-e2e-report.html`'s data block - the scenario summary, as verification evidence.
3. Capture the demo. For UI-affecting changes, launch the app via the separate, already-installed `run` skill - invoked directly via the Skill tool, the same justified exception `implement` uses for its own e2e pass, since `run` sits outside the human-triggered `dev` family - then record a short clip of the change working with `claude-in-chrome`'s `gif_creator`. For non-UI changes, skip the GIF and lead with the clearest before/after example instead.
4. Map everything onto `PITCH_DATA` per [references/data-schema.md](references/data-schema.md), rendered into [templates/pitch.html](templates/pitch.html) in this section order: Demo, Why, What changed, How we verified it, Deviations (omit the section entirely when none were logged), Try it yourself.
   Before first authoring or restyling the template, load the `artifact-design` skill; a plain data refresh on an existing template doesn't need it again.
5. Write the rendered file to `~/tmp/{project-slug}/reports/{plan-name}-pitch.html`, replacing only the data block between the markers - the rendering engine below them is generic, don't touch it.
   Publish it with the `Artifact` tool using that `file_path`: a stable rocket favicon across every pitch this skill produces, a title and one-sentence description from the plan.
   Resuming a plan in a later session and updating the same artifact needs the `url` parameter instead - find it with `Artifact({action: "list"})` if you don't already have it.
   Tell the user both the local path and the published URL, and that the URL is private by default until they choose to share it.

## What good pitch content looks like

- Demo first, always - a reviewer who only looks at the top of the page should already get it.
- Why: the goal and the problem in the reviewer's terms, not implementation detail.
- What changed: a real before/after plus the concrete files touched, not a restated diff.
- How it was verified: the e2e summary and the test layers actually exercised, as evidence - "14/14 scenarios passing across unit, integration, e2e" beats "thoroughly tested".
- Deviations: only if `implementation-notes.md` logged any - what edge case forced the conservative call, and why it still holds.
- Try it yourself: concrete steps a reviewer follows to run or reach the change themselves.
