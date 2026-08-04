# PITCH_DATA Schema

The shape to populate in `templates/pitch.html` between the `PITCH_DATA_START` / `PITCH_DATA_END` markers.
Replace the whole object; the rendering engine below the markers is generic and reads only this shape.

```js
const PITCH_DATA = {
  title: "string - the plan's title, pitched as an outcome",
  planName: "string - the plan slug",
  generatedAt: "string - ISO date",

  demo: {
    gifDataUri: "string data:image/gif;base64,... or null - a captured walkthrough, for UI-affecting changes only",
    beforeAfterExample: "string - markdown-lite; the clearest before/after example. Always fill this in, even when a GIF exists - it's the caption under the GIF, and the whole demo when there isn't one."
  },

  why: {
    goal: "string - the outcome and why, markdown-lite",
    problem: "string - what was broken or missing before"
  },

  whatChanged: {
    before: "string - system behavior before",
    after: "string - system behavior after",
    filesTouched: ["string - repo-relative path", "..."]
  },

  howVerified: {
    e2eSummary: "string - e.g. '14/14 e2e scenarios passing', pulled from the real e2e-report.html summary, never invented",
    layersCovered: ["unit", "integration", "e2e"]   // whichever layers this plan's acceptance criteria actually exercised
  },

  deviations: [
    { what: "string - the edge case that forced a deviation", why: "string - the conservative choice made and why it still holds" }
  ],   // [] when implementation-notes.md logged none

  tryItYourself: {
    steps: ["string - one concrete step a reviewer follows to run or reach the change", "..."]
  }
};
```

## Filling it in honestly

- `demo.gifDataUri` is `null` for non-UI changes, or when nothing was captured - never fabricate a GIF or claim one exists.
- `demo.beforeAfterExample` is required regardless - it's what non-visual readers see, and what carries the section when there's no GIF.
- `howVerified.e2eSummary` and `layersCovered` are pulled from the real `{plan-name}-e2e-report.html`'s `E2E_DATA.summary` and the task-level acceptance-criteria layer tags, never invented or rounded up.
- `deviations` is `[]` when `implementation-notes.md` logged none - the template omits the whole section rather than show an empty one.
- `whatChanged.filesTouched` draws from the plan/task "Files and docs touched" sections, not a guess.
- Keep `whatChanged.before`/`after` to observable system behavior, not a restated diff - a reviewer should be able to picture the end state without reading code.
