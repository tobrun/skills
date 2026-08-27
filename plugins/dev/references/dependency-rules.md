# Dependency Rules

`docs/dependencies.md` in the consuming project: one repo-tracked file declaring which modules may depend on which, in a shape a checker can parse and agents cannot argue with.
It exists because prose architecture rules soften into guidelines inside a long context; a checker's exit code does not.
`decision-spec` drafts and updates the rules when a change touches module boundaries; `to-harden` enforces them with a generated checker.

## Notation

A human-readable header, then one fenced `rules` block the checker parses:

````
# Dependencies

Domain logic stays pure; the UI reaches it only through the app layer.

```rules
[modules]
domain = src/domain/**
app = src/app/**
ui = src/ui/**
infra = src/infra/**

[allowed]
app -> domain
ui -> app
infra -> domain
```
````

Semantics, kept deliberately small:

- `[modules]` names each module and binds it to one or more path globs (comma-separated). Every source file the checker scans must match exactly one module; a file matching none or several is itself a violation, so the map stays honest.
- `[allowed]` lists the permitted dependency edges as `from -> to, to`. **Anything not listed is forbidden** - an allowlist, not a denylist, so a new dependency is a deliberate edit to this file, never a drive-by import.
- Dependencies within a module are always allowed. Edges are not transitive: `ui -> app` and `app -> domain` do not grant `ui -> domain`; write the edge if it is wanted.
- A dependency is any static reference the language makes checkable: imports, includes, requires. Runtime indirection (dependency injection, events) is invisible to the checker by design - that is what makes inverting a dependency the standard fix.

## Who does what

- **decision-spec** drafts the rules. A change that adds a module, adds an edge, or is blocked by an existing edge lands in the spec as a decision (`D-` entry with the alternatives: add the edge, invert the dependency, insert an interface, split the module). The chosen resolution edits this file as part of a change set - the edit is visible in review, never implicit.
- **to-harden** enforces them. Its checker parses the `rules` block, maps changed files to modules, extracts their static dependencies, and fails on any edge not in `[allowed]`. Fix agents resolve violations by changing the code (invert, interface, split), never by editing this file - a rule change is a decision that belongs to a spec, not to a fix loop.
- **to-review**'s architecture lens treats this file as settled context: a diff that conforms needs no boundary debate; a diff that edits the rules is reviewed as the decision it is.

## What belongs here

Module-level edges only.
Function-level or file-level rules drown the signal and rot fast; the compiler and `docs/contracts.md` cover finer grain.
A project without meaningful module boundaries yet does not need this file - `to-harden` skips the check when the file is absent, and says so rather than inventing rules.
