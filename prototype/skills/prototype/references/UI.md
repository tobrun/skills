# UI Prototype

Build when the question is about appearance, layout, or interaction --
not computation.

## Structure

A single HTML file per variant, or a single HTML file with a URL search
param that switches between variants. No framework, no build step.

## Format

A floating bottom bar with variant selector:

```
[Variant A] [Variant B] [Variant C]
```

Each variant is a radically different approach to the same content. The
point is to explore the design space, not to polish one option.

## What to vary

- Layout: single column vs grid vs sidebar
- Typography: large headings vs compact text
- Color: light vs dark vs accent
- Interaction: click vs hover vs auto-play

Do not vary content between variants -- keep the same data so the user
can compare apple to apple.

## When to stop

As soon as the user can say "I like approach B better" or "none of these
work, let me describe what I need". The prototype is a conversation
starter, not a delivery.
