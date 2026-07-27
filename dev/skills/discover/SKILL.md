---
name: discover
description: Run the pre-implementation moves that reduce unknowns before planning starts - a blind spot pass over unfamiliar territory, a brainstorm/prototype pass for an undecided shape, and a one-question-at-a-time interview for ambiguities that would change architecture. Use before to-plan when the request touches unfamiliar code, an undecided UX/architecture direction, or open ambiguities; skip straight to to-plan when the work is already well understood.
disable-model-invocation: true
---

# Discover

Before a plan is worth writing, find out what you don't know yet.
Work you understand well has few unknowns; work in unfamiliar territory has unknown unknowns you can't even name until you go looking for them.
This skill runs the moves that surface those unknowns, ad hoc, in whatever combination the situation needs - never a fixed pipeline.

Invoking this skill is the task - start immediately, don't wait for further instructions.

## Unknowns, named

Every request carries four kinds of unknown: known knowns (what's already in the prompt), known unknowns (gaps you're aware you haven't figured out), unknown knowns (criteria you'd recognize if you saw them but haven't articulated), and unknown unknowns (what you haven't considered at all).
Known knowns need nothing from this skill.
Each mode below targets a different one of the other three: blind spot pass surfaces unknown unknowns, brainstorm + prototype surfaces unknown knowns, interview closes known unknowns.

## Decide what this invocation needs

Read the request and judge which signals apply. Run only the modes a signal actually points to:

- Touches a codebase area, domain, or technology the user (or you) don't know well -> **blind spot pass**.
- Involves a UX or architecture shape that isn't decided yet, or the user asks to see options / mock something up -> **brainstorm + prototype**.
- Leaves ambiguities standing whose answer would change the architecture -> **interview**.

More than one signal can apply in one invocation - run the modes in sequence (a blind spot pass often surfaces the shape decision that brainstorm/prototype should then explore, which in turn surfaces the ambiguities the interview resolves).
If none apply - the area is familiar, the shape is obvious, nothing is ambiguous - say so plainly and recommend `/to-plan` directly.
Don't run a mode to look thorough; run it because a real unknown is sitting there.

## Mode 1: Blind spot pass

Explore broadly instead of narrowly answering the request as stated.
Produce: unverified assumptions the request rests on, adjacent systems or consumers that might be affected, existing prior-art patterns worth checking before inventing a new one, and open questions whose answer would change direction.
See [references/modes.md](references/modes.md) for trigger signals and example prompts.

## Mode 2: Brainstorm + prototype

Produce an intervention-point table (option, effort, what changes, tradeoff - ordered cheap to ambitious) so the user reacts to a spread of choices instead of the first idea.
When the work affects UI, also produce 2-4 cheap HTML mockups of wildly different directions embedded in the output artifact, for the user to react to before anything real is wired up.
Recommend the `artifact-design` skill for the mockups' construction quality; don't invoke it yourself.
See [references/modes.md](references/modes.md) for depth.

## Mode 3: Interview

Ask one question at a time with `AskUserQuestion`, ordered by architectural impact - the question whose answer would change the most goes first.
Ask one at a time rather than batching: each answer can change what the next question should even be, so batching would waste rounds on now-irrelevant questions.
Stop once remaining ambiguities are cosmetic or reversible, not architectural.

## Output

1. Pick a kebab-case `topic-slug` naming the outcome (same convention `to-plan` uses for `plan-name`).
2. Map what came out of the modes you ran onto `DISCOVERY_DATA` per [references/data-schema.md](references/data-schema.md). Omit sections for modes you didn't run - never render an empty section.
3. Write `~/tmp/{project-slug}/reports/{topic-slug}-discovery.html` from [templates/discovery.html](templates/discovery.html), replacing only the data block between its markers.
4. Publish it with the Artifact tool: same `file_path`, favicon `🔍` (kept stable across redeploys of this artifact type), and a title/description built from the topic. Tell the user both the local path and the returned URL.
5. Write a plain-markdown companion, `~/tmp/{project-slug}/reports/{topic-slug}-discovery-notes.md`, mirroring the same content - this is what `/to-plan` reads back in directly, without parsing HTML.
6. Recommend the user run `/to-plan` next and reuse `topic-slug` as the plan name, so `to-plan` picks up `{topic-slug}-discovery-notes.md` automatically and treats its answers as settled rather than re-litigating them.
