# Plan Directory Layout

`.dev/{plan-name}/` is the durable home of one change, named by a kebab-case slug for the outcome.
This reference owns the layout, the locating convention, and the diff scope; skills state only their own role.

## Files and owners

| File | Written by | Read by |
| ---- | ---------- | ------- |
| `spec.md` | `decision-spec` | everyone downstream |
| `implementation-notes.md` | `implement` (append-only) | `to-review`, `to-pitch`, `to-quiz` |
| `review_N.md` | `to-review` (next free index) | `decision-spec` (remediation), re-reviews |
| `.dev/config.json` | the user | any skill with Jira behavior |

Each producing skill also renders an HTML companion under `/tmp/{project-slug}/reports/` per [reporting.md](reporting.md): `{plan-name}-spec.html`, `{plan-name}-e2e-report.html`, `review_N.html`, `{plan-name}-pitch.html`, `{plan-name}-quiz.html`.
One writer per file; every other skill only reads.

## Locating the plan directory

Match the current branch name to a `.dev/{plan-name}/` slug; fall back to commit messages, then to the only directory in a plausible state for the skill (e.g. the only spec whose change sets aren't done).
Ask which one only if more than one is a plausible match; otherwise proceed without waiting.

## Diff scope

Skills that operate on "the change" (`to-review`, `to-harden`) scope to the local branch against the default branch (`git merge-base HEAD origin/{default}`), diffed with local git only (never `gh pr diff`), excluding lockfiles, build output, minified files, binaries, fonts, and snapshots:

```
':!*lock*' ':!go.sum' ':!dist/' ':!build/' ':!*.min.*' ':!*.map' ':!*.png' ':!*.jpg' ':!*.gif' ':!*.webp' ':!*.woff*' ':!*.ttf' ':!**/__snapshots__/'
```
