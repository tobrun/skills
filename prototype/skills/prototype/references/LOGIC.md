# Logic Prototype

Build when the question is about behavior, state transitions, or
computational logic -- not visuals.

## Structure

One file (`prototype.py` or `prototype.ts`), one entry point, one import
(the state type or interface you're prototyping). Run with the project's
convention: `pnpm prototype` or `python prototype.py`.

## Format

A REPL-like loop:

```
=== State ===
{full state dump}

What now? (action) [params]
>
```

Each action validates, mutates state, then dumps the new state. Invalid
actions print a short error and re-display the prompt.

## Example

```
=== Cart ===
items: []
total: $0.00

What now? (add|remove|checkout|quit) [params]
> add widget-1

=== Cart ===
items: ["widget-1"]
total: $9.99

What now? (add|remove|checkout|quit) [params]
>
```

## When to stop

As soon as the state-machine behavior is clear enough to answer the
question. The prototype is successful when you can say "yes, this state
model handles the edge case" or "no, this model breaks under X".
