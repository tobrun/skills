# Jira mirror reference

This reference is used only when the consuming repository opts into Jira in
`.dev/config.json`. The `.dev/` files remain the source of truth; Jira mirrors
the records identified by the keys persisted in those files.

## Configuration and activation

Read `.dev/config.json` before doing any Jira work. The supported shape is:

```json
{
  "jira": {
    "enabled": true,
    "site": "acme.atlassian.net",
    "project": "PROJ"
  }
}
```

`jira.project` is required when enabled. `jira.site` is optional and should be
passed to `acli` when present. If the file is absent, malformed, Jira is
missing, or `jira.enabled` is false, the workflow is pure-local. In the
disabled case do not mention Jira, ask a Jira question, or invoke `acli`.

When enabled, check that `acli` is installed and authenticated before the first
operation. A useful check is:

```text
acli jira auth status [--site SITE]
```

If the check fails, stop and ask the user to install or authenticate `acli`, or
disable Jira sync. Do not continue with only local state.

## Command shapes

The exact flags may vary slightly with the installed `acli` release. Preserve
the intent and verify every created issue with `workitem view`. Treat a
non-zero exit, invalid JSON, missing key, or ambiguous result as a failure.

List open Initiatives for the configured project:

```text
acli jira workitem search --project PROJ --type Initiative --status open --json [--site SITE]
```

Ask the user to choose one returned Initiative. If none is returned, stop with
a clear message that an existing open Initiative is required; never create one.

Create the plan Epic linked to the chosen Initiative, then verify it:

```text
acli jira workitem create --project PROJ --type Epic --summary SUMMARY --parent INITIATIVE-1 --json [--site SITE]
acli jira workitem view EPIC-1 --json [--site SITE]
```

Create a task under the Epic, then verify it:

```text
acli jira workitem create --project PROJ --type Task --summary SUMMARY --parent EPIC-1 --json [--site SITE]
acli jira workitem view TASK-1 --json [--site SITE]
```

Before any transition, discover the project's available transitions from a
representative issue. Match the displayed names exactly and require one
unambiguous transition for the requested state:

```text
acli jira workitem transition-list --issue EPIC-1 --json [--site SITE]
acli jira workitem transition --issue EPIC-1 --transition "In Progress" --json [--site SITE]
```

Use the same discovery and transition sequence for task issues. The
implement orchestrator owns these calls. Task subagents never invoke `acli`.

When a task is superseded, transition the old issue to its available closed
state and add the required comment:

```text
acli jira workitem transition-list --issue TASK-1 --json [--site SITE]
acli jira workitem transition --issue TASK-1 --transition "Done" --json [--site SITE]
acli jira workitem comment --issue TASK-1 --body "superseded by task_3" --json [--site SITE]
```

## Persistence and timing

After the Epic is created, write `Jira: PROJ-1` directly under the plan title
in `plan.md`. After each task issue is created, write its key directly under
that task title in `task_N.md`. Add a `Jira` column to the plan task index and
put the matching key in each row.

to-plan lists Initiatives during its existing interview and creates the Epic
only after local `plan.md` has been written. to-tasks creates one Task for each
new local task after task files and the index exist. On supersede, close and
comment the old issue before creating and persisting the replacement issue.

implement transitions the persisted Epic to In Progress at the start. The
orchestrator transitions each persisted task issue to In Progress immediately
when its wave is dispatched, and to Done only after the task is verified and
its commit lands.

## Failure protocol

Jira is first-class when enabled. Any failed auth check, command, JSON parse,
verification, missing key, missing Initiative, unknown transition, or
ambiguous transition stops the skill immediately. Explain the failed
operation and ask the user how to proceed. Never silently skip Jira, continue
with divergent local-only state, invent an issue key, or mark a transition
successful without verification.

The Epic is not polled or closed by the skills. When implement asks permission
to push and open a PR, include the Epic key in the proposed branch name and at
the start of the PR title. A documented Jira automation rule closes the Epic
after the linked PR is merged.
