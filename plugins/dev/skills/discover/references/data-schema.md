# DISCOVERY_DATA Schema

The shape to populate in `templates/discovery.html` between the `DISCOVERY_DATA_START` / `DISCOVERY_DATA_END` markers.
Replace the whole object; the rendering engine below the markers is generic and reads only this shape.
Omit an array entirely (leave it `[]`) for any mode - or any category within a mode - you didn't actually produce; the template hides empty sections rather than rendering them blank.

```js
const DISCOVERY_DATA = {
  topic: "string - readable title for the topic",
  topicSlug: "string - the kebab-case topic-slug, e.g. 'rate-limit-public-api'",
  generatedAt: "string - ISO date",
  modesRun: ["blind-spot", "brainstorm", "interview"],   // subset, in the order they were actually run

  // Mode 1: blind spot pass. Four independent categories - fill in whichever you actually found.
  blindSpots: {
    assumptions: [
      { text: "string - an unverified assumption the request rests on", risk: "string - what breaks if it's wrong", howToVerify: "string - the concrete way to check it" }
    ],
    adjacentSystems: [
      { name: "string - a system or consumer that might be affected", note: "string - why it matters / how it's affected" }
    ],
    priorArt: [
      { pattern: "string - an existing pattern worth reusing", where: "string - file, module, or repo it lives in", note: "string - optional, one line" }
    ],
    openQuestions: [
      { question: "string - a question left open", whyItMatters: "string - what changes depending on the answer" }
    ]
  },

  // Mode 2: brainstorm + prototype.
  interventionPoints: [
    {
      option: "string - one intervention point",
      effort: "cheap" /* | "moderate" | "ambitious" */,
      whatChanges: "string - concretely what this option changes",
      tradeoff: "string - the cost or risk of taking this option"
    }
  ],
  mockups: [
    {
      title: "string - short label for this direction",
      description: "string - one line on the idea behind this direction",
      html: "string - a complete, self-contained HTML fragment (its own <style>, fake data) rendered in a sandboxed iframe"
    }
  ],

  // Mode 3: interview.
  interview: [
    {
      question: "string - the question actually asked",
      answer: "string - the user's answer",
      architecturalImpact: "high" /* | "medium" | "low" */
    }
  ],

  chosenDirection: "string - optional; the synthesized recommendation once every mode that ran is weighed together. Omit if nothing was decided yet."
};
```

## Filling it in honestly

- **modesRun drives which top-level sections render** - list only the modes actually run, in the order they ran, so the artifact matches the real conversation instead of implying more ceremony happened than did.
- **blindSpots' four categories are independent** - a real blind spot pass rarely fills all four evenly; leave a category `[]` rather than padding it to look complete.
- **mockups.html must be self-contained** - each one renders in its own sandboxed iframe with no external requests; fake data is fine, a broken or half-finished fragment is not.
- **interview.architecturalImpact is a judgment call that matters** - it's what justifies asking that question before others; don't mark everything "high" by default.
- **chosenDirection is optional** - a discovery pass that surfaced good options without settling on one is still a complete, useful artifact; don't invent a decision that wasn't actually made.
- **topicSlug must match** what you actually name `/tmp/{project-slug}/reports/{topic-slug}-discovery.html` and recommend as the next `to-plan` plan name - the artifact's own "next step" text is generated from this field, so a mismatch would point the user at the wrong file.
