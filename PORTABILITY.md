# Portable Agent Usage

This repository is packaged as a Claude Code plugin, but the command logic is not Claude-only.

The portable source of truth is:

- [AGENTS.md](./AGENTS.md) for repo-wide rules
- `commands/*.md` for AIUP command behavior
- `skills/*/SKILL.md` for validations or helper workflows referenced by commands
- `agents/*.md` for agent-specific guidance referenced by hooks or commands

Claude adds a slash-command UI on top of those files. Other agents can use the same command content by rendering it into a normal prompt.

## Cursor

| Topic | Details |
|-------|---------|
| Rules | [`.cursor/rules/aiup-alfresco.mdc`](./.cursor/rules/aiup-alfresco.mdc) applies AIUP context (`alwaysApply: true`); full conventions remain in [`AGENTS.md`](./AGENTS.md). |
| Skills | [`.cursor/skills/`](./.cursor/skills/) — command slash skills (one per `commands/*.md`), validators, agents, and `aiup-alfresco` orchestrator. Regenerate with `./scripts/build-cursor-skills.sh`; consumer repos use `install-cursor-pack.sh`. |
| Renderer | `./scripts/aiup-command.sh render --agent cursor <command> [args…]` — same output shape as `generic`, with a preamble tuned for Cursor (`@` file references). |
| Hooks | [`.cursor/hooks.json`](./.cursor/hooks.json) registers Cursor-native hooks (see [`CURSOR.md`](./CURSOR.md)); they are separate from Claude’s [`hooks/hooks.json`](./hooks/hooks.json). |
| Slash commands | Cursor 2.4+ — type `/requirements`, `/scaffold`, etc. in Agent chat (skills with `disable-model-invocation: true`). In consumer repos, run `./tools/aiup-alfresco/scripts/install-cursor-pack.sh` first. |

End-to-end guide: **[CURSOR.md](./CURSOR.md)**.

## Quick Start

List the available commands:

```bash
./scripts/aiup-command.sh list
```

Render a prompt for Codex:

```bash
./scripts/aiup-command.sh render --agent codex requirements \
  "We need to manage contracts with approval dates"
```

Render a prompt for OpenClaw:

```bash
./scripts/aiup-command.sh render --agent openclaw scaffold
```

Render a prompt for Cursor Agent:

```bash
./scripts/aiup-command.sh render --agent cursor requirements \
  "We need to manage contracts with approval dates"
```

Use the output as the prompt you send to the target agent.

## What The Renderer Does

- points the target agent at `AGENTS.md`
- points the target agent at the requested `commands/<name>.md`
- strips Claude-only front matter from the command file
- explains how to handle `skills/` and `agents/` references manually
- passes through any user arguments

## Typical Workflow Outside Claude

1. Run `./scripts/aiup-command.sh render --agent codex requirements "..."`
2. Send the rendered prompt to the agent.
3. After `REQUIREMENTS.md` exists, run `./scripts/aiup-command.sh render --agent codex scaffold`
4. Continue with `content-model`, `behaviours`, `web-scripts`, `events`, `docker-compose`, and `test`

## Claude-Specific Pieces

These remain Claude-specific and are not interpreted automatically by other agents:

- plugin installation via `claude plugin install`
- hook automation in `hooks/hooks.json` (Claude Code hook schema and paths)
- automatic skill dispatch in Claude Code

Outside Claude, the renderer replaces those features with an explicit prompt you can feed to another agent.

**Cursor** additionally uses `.cursor/rules/*.mdc`, `.cursor/skills/` slash commands, and `.cursor/hooks.json`; see [CURSOR.md](./CURSOR.md).
