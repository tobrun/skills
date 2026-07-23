# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Repository Overview

This is a monorepo for Tobrun's Claude Code skills packaged as plugins.
The root `.claude-plugin/marketplace.json` references individual plugins
in subdirectories, following the marketplace convention used by
`claude-plugins`.

## Repository Structure

```
.
├── .claude-plugin/
│   └── marketplace.json    # Marketplace manifest listing all plugins
├── {plugin-name}/          # Individual plugin directory
│   ├── .claude-plugin/
│   │   └── plugin.json     # Plugin metadata (name, version, author)
│   ├── README.md           # Plugin documentation
│   └── skills/
│       └── {skill-name}/
│           ├── SKILL.md    # Skill definition with YAML frontmatter
│           ├── references/ # Deep-dive docs loaded on demand
│           └── examples/   # Worked examples
```

## Key Rules

- All changes must pass `scripts/validate.sh` before committing.
- Every plugin directory name must match its `plugin.json` name and marketplace entry name.
- Every `SKILL.md` must have YAML frontmatter with `name` and `description`.
- Skill descriptions must state both what the skill does and when to use it.
- No file in the repo may contain an em dash.
- Keep `SKILL.md` body under roughly 150 lines; move detail to `references/`.

## Key Commands

- `scripts/validate.sh` - Validate the entire repository structure.
- Local testing: `/plugin marketplace add ~/ws/skills` then `/plugin install {name}@nurbot`.
- If changes aren't picked up after reinstall, bump the version with a `-devN` suffix in `plugin.json`.
