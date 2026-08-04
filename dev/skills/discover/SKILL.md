---
name: discover
description: Run the pre-implementation moves that reduce unknowns before planning starts - a blind spot pass over unfamiliar territory, a brainstorm/prototype pass for an undecided shape, and a one-question-at-a-time interview for ambiguities that would change architecture. Use before to-plan when the request touches unfamiliar code, an undecided UX/architecture direction, or open ambiguities; skip straight to to-plan when the work is already well understood.
disable-model-invocation: true
---

# Discover

Before a plan is worth writing, find out what you don't know yet.
This skill runs the moves that surface unknowns, ad hoc, in whatever combination the situation needs - never a fixed pipeline.

Invoking this skill is the task - start immediately, don't wait for further instructions.

## Unknowns, named

Each mode targets one kind of unknown: the **blind spot pass** surfaces unknown unknowns (what you haven't considered), **brainstorm + prototype** surfaces unknown knowns (criteria you'd recognize but haven't articulated), the **interview** closes known unknowns (gaps you're aware of).
Known knowns - what's already in the prompt - need nothing from this skill.

## Decide what this invocation needs

Read the request and judge which signals apply. Run only the modes a signal actually points to:

- Touches a codebase area, domain, or technology the user (or you) don't know well -> **blind spot pass**.
- Involves a UX or architecture shape that isn't decided yet, or the user asks to see options / mock something up -> **brainstorm + prototype**.
- Leaves ambiguities standing whose answer would change the architecture -> **interview**.

More than one signal can apply - run the modes in sequence (a blind spot pass often surfaces a shape decision for brainstorm/prototype, which surfaces ambiguities for the interview).
If none apply, say so plainly and recommend `to-plan` directly.
Run a mode because a real unknown is sitting there, not to look thorough.

## Mode 1: Blind spot pass

Explore broadly instead of narrowly answering the request as stated.
Produce: unverified assumptions the request rests on, adjacent systems or consumers that might be affected, existing prior-art patterns worth checking before inventing a new one, and open questions whose answer would change direction.
See [references/modes.md](references/modes.md) for trigger signals and example prompts.

## Mode 2: Brainstorm + prototype

Produce an intervention-point table (option, effort, what changes, tradeoff - ordered cheap to ambitious) so the user reacts to a spread of choices instead of the first idea.
When the work affects UI, also produce 2-4 cheap HTML mockups of wildly different directions embedded in the output artifact, for the user to react to before anything real is wired up.
Recommend an installed artifact or frontend design skill for the mockups' construction quality; don't invoke it yourself.
See [references/modes.md](references/modes.md) for depth.

## Mode 3: Interview

Ask one question at a time with the host's structured user-input tool when available, or directly in chat otherwise. Start with the most architecturally significant question - each answer can change what the next question should be, so batching wastes rounds on now-irrelevant questions.
Stop once remaining ambiguities are cosmetic or reversible, not architectural.

## Output

1. Pick a kebab-case `topic-slug` naming the outcome (same convention `to-plan` uses for `plan-name`).
2. Map what came out of the modes you ran onto `DISCOVERY_DATA` per [references/data-schema.md](references/data-schema.md). Omit sections for modes you didn't run - never render an empty section.
3. Write `/tmp/{project-slug}/reports/{topic-slug}-discovery.html` from [templates/discovery.html](templates/discovery.html), replacing only the data block between its markers. This local file is the default deliverable - tell the user the path and stop there.
4. Only publish it with an available artifact-publishing tool (stable search favicon, title/description built from the topic) if the user asks for a shareable link. Mention the option in passing rather than doing it unprompted; if the host has no publisher, keep the local file as the deliverable.
5. Write a plain-markdown companion, `/tmp/{project-slug}/reports/{topic-slug}-discovery-notes.md`, mirroring the same content - this is what `to-plan` reads back in directly, without parsing HTML.
6. Recommend the user run `to-plan` next and reuse `topic-slug` as the plan name, so `to-plan` picks up `{topic-slug}-discovery-notes.md` automatically and treats its answers as settled rather than re-litigating them.
