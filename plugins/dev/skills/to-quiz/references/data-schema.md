# QUIZ_DATA Schema

The shape to populate in `templates/quiz.html` between the `QUIZ_DATA_START` / `QUIZ_DATA_END` markers.
Replace the whole object; the grading logic below the markers is generic and reads only this shape.

```js
const QUIZ_DATA = {
  title: "string - the spec's title",
  planName: "string - the .dev/{plan-name} slug",
  generatedAt: "string - ISO date",

  context: "string - what this change is and why, markdown-lite",
  intuition: "string - the one key design insight or tradeoff a reviewer needs to get, in plain language, not a restated summary",

  whatWasDone: {
    summary: "string - concrete summary of what changed, markdown-lite",
    filesTouched: ["string - repo-relative path", "..."]
  },

  questions: [
    {
      id: "string",
      prompt: "string - the question",
      choices: ["string", "string", "string"],   // 3-4 choices, one correct
      correctIndex: 0,
      explanation: "string - why the right answer is right",
      linksToSection: "context" | "intuition" | "what-was-done"   // which section of this same document backs the right answer
    }
  ]
};
```

## Filling it in honestly

- Every question traces back to something real: an acceptance criterion, an edge case a test covers, or a logged deviation - never invented trivia a careless reader could still answer correctly.
- `linksToSection` must be one of `"context"`, `"intuition"`, `"what-was-done"` - whichever section of this document actually backs the answer; the template turns it into a jump link, so it must point somewhere real.
- 3-6 questions total - more dilutes into busywork, fewer doesn't cover the change.
- `whatWasDone.filesTouched` draws from the spec change plan's file lists, not a guess.
- This artifact never claims to gate anything - the template's banner copy says so explicitly; don't soften that language when filling in `context`/`whatWasDone.summary`.
