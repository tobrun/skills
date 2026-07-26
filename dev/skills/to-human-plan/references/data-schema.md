# PLAN_DATA Schema

The shape to populate in `templates/plan.html` between the `PLAN_DATA_START` / `PLAN_DATA_END` markers.
Replace the whole object; the rendering engine below the markers is generic and reads only this shape.

```js
const PLAN_DATA = {
  title: "string - the plan's title",
  goal: "string - the outcome and why, markdown-lite (supports **bold**, `code`, blank-line paragraphs)",

  context: {
    current: "string - how the affected part of the system behaves today",
    why: "string - why this change, now",
    constraints: ["string", "..."]   // gotchas, non-obvious constraints; omit or [] if none
  },

  // One entry per file (or external consumer) touched or affected by the change.
  files: [
    {
      id: "string - path (repo-relative) or a short name for an external consumer",
      blastRadius: 1,       // integer 1-5: how much breaks if this file's behavior is wrong. Be honest, not dramatic.
      external: false,      // true for a consumer outside this repo (a dependent service, another package)
      note: "string - one line: what this file's role is in the change"
    }
  ],

  // Dependency/touches relationships between files, drawn as edges on the graph.
  // Direction is "from depends on / touches -> to".
  edges: [
    { from: "file id", to: "file id" }
  ],

  // Numbered, in execution order. Every id in `files` that a step touches must appear in that step's `files` array.
  steps: [
    {
      n: 1,                    // 1-indexed, sequential, matches display order
      title: "string - one-line plain-language summary, not the diff restated",
      risky: false,            // true marks it on the timeline and steps list; reserve for steps that change real behavior or are hard to reverse
      files: ["file id", "..."],   // must be a subset of the `files` array's ids
      diff: "string - the real proposed diff, unified-diff style (+/- prefixed lines); never fabricate a diff for a step that has none",
      reasoning: "string - why this step is shaped this way, markdown-lite",
      after: "string - one to two sentences: what the system looks like once this step lands, for the timeline narration"
    }
  ],

  tests: [
    { name: "string - what the test verifies", file: "string - path", note: "string - optional, one line" }
  ]
};
```

## Filling it in honestly

- **blastRadius is a judgment call that matters** - it drives node size and color on the graph. A file that's imported everywhere and hard to change safely is a 4-5; a new, isolated file is a 1-2. Don't default everything to the same number.
- **external files are real** - if the change affects a consumer outside this repo (another service, a published package's public API), include it in `files` with `external: true` and wire an edge to it, even though there's no step that edits it directly.
- **diff must be real** - pull it from the plan/task files or from what you actually intend to write; an invented-looking diff erodes trust in the whole artifact.
- **after (the narration) is what makes the timeline worth walking** - it should describe observable system behavior at that point, not restate the step title.
- Every step's `files` should also appear in the top-level `files` array; the graph and the steps share the same file identifiers so click-to-highlight can match them.
