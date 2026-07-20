# prototype

A Claude Code plugin that builds throwaway prototypes to answer design
questions. The prototype skill auto-activates when you want to
sanity-check whether a state model or logic feels right, or explore
what a UI should look like.

## Install

This plugin ships as part of the
[`tobrun-skills`](../README.md) marketplace:

```
/plugin marketplace add ./skills
/plugin install prototype@tobrun-skills
```

## Use

In any Claude Code session, just ask:

```
prototype this state machine for me
```

or

```
let me see what this UI would look like
```

Claude will identify which question you're answering and build either
a logic prototype (terminal app) or a UI prototype (rendered page).

## Layout

```
prototype/
├── .claude-plugin/
│   └── plugin.json         # Plugin metadata
├── skills/
│   └── prototype/
│       ├── SKILL.md         # Skill definition with YAML frontmatter
│       └── references/
│           ├── LOGIC.md     # Logic prototype guide
│           └── UI.md        # UI prototype guide
└── README.md                # This file
```

## License

Not licensed for redistribution (`UNLICENSED`).
