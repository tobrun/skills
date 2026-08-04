# Mode depth

Trigger signals, example prompts, and what a good versus weak output looks like for each mode.
SKILL.md covers the decision logic; this file covers how to actually run each one well.

## Blind spot pass

**Trigger signals**: the user names an area they (or you) haven't worked in before; the request touches a module you haven't read; the domain vocabulary is unfamiliar; the user explicitly says something like "I know nothing about X."

**How to run it**: explore broadly before answering narrowly. Read the surrounding code, its callers, its tests, and any existing docs for the area. Then produce, as a structured list rather than prose:

- **Unverified assumptions** - things the request quietly assumes are true that you haven't confirmed (e.g. "assumes the auth token never expires mid-request").
- **Adjacent systems/consumers** - what else reads or depends on the thing you're about to touch, including outside this repo.
- **Prior art** - existing patterns in this codebase (or a referenced one) that already solve a piece of this; check before inventing a new approach.
- **Open questions** - ones whose answer would change direction, not ones you could answer yourself by reading one more file.

Example prompt this mode is built to answer: "I'm working on adding a new auth provider but I know nothing about the auth modules in this codebase. Do a blind spot pass to help me figure out my relevant unknown unknowns."

**Good output**: specific, falsifiable claims tied to real files ("the session middleware in src/auth/session.ts assumes a single active provider - adding a second one needs to touch its provider-selection branch"). **Weak output**: generic software-engineering advice that would apply to any codebase.

## Brainstorm + prototype

**Trigger signals**: the shape of the solution isn't decided; the user asks to "see options"; the change affects what a user sees or how a workflow feels; a blind spot pass surfaced a real design choice.

**How to run it**:

- **Intervention-point table**: list options from cheap to ambitious, each with effort, what concretely changes, and the tradeoff. This should give the user a real spread, not one idea and its opposite.
- **HTML mockups** (UI-affecting work only): build 2-4 wildly different design directions as static HTML with fake data, cheap enough to throw away. The point is reacting to a real rendered page, not a description of one. Recommend an installed artifact or frontend design skill for construction quality; don't invoke it.

Example prompts: "I want a dashboard for this data but I have no visual taste and don't know what's possible - make me an HTML page with 4 wildly different design directions so I can react to them." / "Before wiring anything up, mock the new editor toolbar with fake data - I want to react to the layout before you touch the real app." / "Here's my rough problem: users churn after onboarding. Brainstorm 10 places we could intervene, cheapest to most ambitious."

**Good output**: directions that are actually different from each other (not four variations on the same idea), each one genuinely inhabitable in the mockup. **Weak output**: one plausible design duplicated with cosmetic tweaks.

## Interview

**Trigger signals**: real ambiguities remain after blind-spot and brainstorm passes (or the request was narrow enough that those weren't needed) and at least one of them would change the architecture depending on the answer.

**How to run it**: use the host's structured user-input tool when available, or ask directly in chat otherwise. Ask one question at a time, ordered so the answer that would most change the shape of the work comes first. After each answer, re-evaluate what's still open - an early answer can make a planned later question moot, or surface a new one. Stop once what's left is cosmetic (naming, copy, minor styling) rather than architectural.

Example prompt: "Interview me one question at a time about anything ambiguous - prioritize questions where my answer would change the architecture."

**Good output**: few, sharp questions, each one clearly load-bearing. **Weak output**: a long checklist of questions that could be answered by reading the code yourself, or batched questions where later ones are already implied by earlier answers.
