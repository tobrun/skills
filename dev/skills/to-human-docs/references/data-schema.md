# DOCS_DATA Schema

The shape to populate in `templates/docs-map.html` between the `DOCS_DATA_START` / `DOCS_DATA_END` markers.
Replace the whole object; the rendering engine below the markers is generic and reads only this shape.

```js
const DOCS_DATA = {
  project: "string - project name (repo directory basename is a fine default)",
  goal: "string - one line from docs/product/product.md, markdown-lite",

  // One entry per area that has at least one file. Keys are fixed - the
  // template's categorical colors and cluster layout are keyed on them.
  // Use only the areas that exist; omit an area entirely if its directory
  // has no files (do not emit it with an empty docs array).
  areas: [
    {
      key: "product",        // one of: product | architecture | engineering | operations | governance
      label: "Product",      // display label for the cluster
      docs: [
        {
          id: "product/product.md",   // path relative to docs/, used as the graph node id and edge endpoint
          title: "Product",           // short display title
          status: "complete",         // "stub" if the doc still carries a Status: stub line, else "complete"
          summary: "string - one line, optional",
          content: "string - the doc's body, markdown-lite, shown in the detail panel on click"
        }
      ]
    }
  ],

  // Cross-references between docs, drawn as graph edges. Only include a
  // link if the source doc actually references the target (a markdown
  // link, an explicit "see X" style pointer) - do not invent relationships.
  edges: [
    { from: "doc id", to: "doc id" }
  ],

  // One entry per file under docs/architecture/decisions/, excluding the template.
  decisions: [
    {
      id: "string - e.g. 0001-use-postgres",
      title: "string",
      status: "accepted | proposed | superseded | accepted (reconstructed)",
      date: "YYYY-MM-DD"   // optional
    }
  ],

  // Every row from docs/backlog.md's Potential improvements table. Empty array if the file doesn't exist or has no rows.
  backlog: [
    { doc: "string - path", missing: "string", question: "string", next: "string" }
  ],

  // One entry per docs/plan/{plan-name}/ directory.
  plans: [
    {
      name: "plan-slug",
      title: "string - the plan's title (from plan.md's # Plan: heading)",
      successCriteria: [ { text: "string", met: false } ],  // from the plan's Success criteria section; `met` is a judgment call from the latest review, not a guess
      tasks: [ { n: 1, title: "string", done: false } ],    // from the plan's task index / task_N.md files; done = task implemented and committed
      verdict: "PASS" // or "CONCERNS" | "BLOCK" | null (null = no review_N.md yet)
    }
  ]
};
```

## Extracting this from a real `docs/` tree

- **status**: a doc is `"stub"` if its content still has a `Status: stub` line under the title (per the `install` skill's lifecycle), else `"complete"`. Don't infer completeness from length.
- **edges**: parse real relative markdown links between docs (`[text](../architecture/architecture.md)` style) rather than guessing at conceptual relationships. Under-connecting is better than a fabricated edge.
- **decisions**: one entry per file in `docs/architecture/decisions/` other than `0000-template.md`; read each file's own status line rather than assuming `accepted`.
- **backlog**: read the table rows directly out of `docs/backlog.md` under `## Potential improvements` - this is already structured data, don't paraphrase it.
- **plans**: for `successCriteria.met` and `verdict`, read the plan's latest `review_N.md` if one exists; without a review, leave `met: false` and `verdict: null` rather than guessing.
- **content**: keep it close to the source doc's actual text (light trimming is fine); this is what a human reads in the detail panel, so don't summarize away the substance.
