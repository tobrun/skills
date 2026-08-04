## Plugins

| Plugin | Use When | Tools |
| ------ | -------- | ----- |
| [dev](dev/) | A test-focused development workflow for Claude Code, Codex, and Pi. | `discover`, `to-plan`, `to-tasks`, `implement`, `to-review`, `to-pitch`, `to-quiz` |

## Claude Code

```bash
/plugin marketplace add tobrun/skills
/plugin install dev@nurbot
```

Invoke skills as `/discover`, `/to-plan`, and so on.

## Codex

```bash
codex plugin marketplace add tobrun/skills
codex plugin add dev@nurbot
```

Invoke skills as `$dev:discover`, `$dev:to-plan`, and so on. Both
distributions are explicit-invocation only. The checked-in Codex package under
`plugins/dev/` is generated from `dev/`:

```bash
python3 scripts/build_codex_plugin.py
```

## Pi

```bash
pi install git:github.com/tobrun/skills
```

Invoke skills as `/skill:discover`, `/skill:to-plan`, and so on. Pi consumes
`dev/skills/` directly through the root `package.json`; no generated Pi copy is
needed.

`to-review` preserves its independent-agent panel on Pi by launching isolated
`pi --print` processes in parallel. Claude Code and Codex continue to use their
native subagent facilities.
