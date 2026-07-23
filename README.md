# Tobrun's Claude Code Skills Marketplace

A marketplace of Claude Code plugins packaging skills for Tobrun's
development workflows. This monorepo follows the same plugin marketplace
convention as `claude-plugins`.

## Plugins

| Plugin | Use When | Tools |
| ------ | -------- | ----- |
| [dev](dev/) | Initializing a project docs knowledge base, planning work into reviewable docs, splitting it into tasks, implementing it test-first, and reviewing it with a verified panel | `/install`, `/to-plan`, `to-tasks`, `/implement`, `to-review` |

## Installation

```bash
# Add this marketplace to your Claude Code session
/plugin marketplace add ~/ws/skills

# Install a specific plugin
/plugin install {plugin-name}@nurbot
```

## Structure

```
.
├── .claude-plugin/
│   └── marketplace.json     # Marketplace manifest listing all plugins
├── {plugin-name}/           # One directory per plugin
│   ├── .claude-plugin/
│   │   └── plugin.json      # Plugin metadata
│   ├── README.md            # Plugin documentation
│   └── skills/
│       └── {skill-name}/
│           ├── SKILL.md     # Skill definition with YAML frontmatter
│           ├── references/  # Deep-dive docs loaded on demand
│           └── examples/    # Worked examples
├── scripts/
│   └── validate.sh          # Self-validation script
├── CLAUDE.md                # Guidance for Claude Code in this repo
└── README.md                # This file
```

## Development

1. Add a new plugin by creating a directory with `.claude-plugin/plugin.json`, a `README.md`, and at least one skill.
2. Register it in `.claude-plugin/marketplace.json`.
3. Add a row to the plugin table above.
4. Run `scripts/validate.sh` to verify everything is correct.
5. Install locally to test: `/plugin marketplace add ~/ws/skills && /plugin install {name}@nurbot`.
