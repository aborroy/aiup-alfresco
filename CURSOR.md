# Using aiup-alfresco with Cursor

This repository is a [Claude Code](https://claude.com/claude-code) plugin **and** a portable prompt pack. In **Cursor 2.4+**, AIUP steps are available as **slash commands** (`/requirements`, `/scaffold`, …) via Agent Skills in `.cursor/skills/`. You can also use **project rules**, **`@` file references**, optional **hooks**, and the **`scripts/aiup-command.sh` renderer**.

## Prerequisites

- **Cursor** (a recent build) with Agent chat, project rules, and optionally **Hooks** enabled in Cursor settings.
- This folder opened as the **workspace root** (File → Open Folder).
- To generate Alfresco extensions on disk: **Java 17+**, **Maven 3.9+**, **Docker** (same as [README.md](./README.md)).
- Hook scripts that validate JSON depend on **`jq`** on your `PATH`.

## What gets loaded automatically

| Artifact | Role |
|----------|------|
| [`.cursor/rules/aiup-alfresco.mdc`](./.cursor/rules/aiup-alfresco.mdc) | Tells the agent to follow [`AGENTS.md`](./AGENTS.md) and treat `commands/` and `.cursor/skills/` as the AIUP workflow. Enabled with `alwaysApply: true`. |
| [`.cursor/skills/`](./.cursor/skills/) | Cursor-native skills: one slash skill per `commands/*.md`, validator/agent skills, and **`aiup-alfresco`** orchestrator. Regenerate after upstream merges: `./scripts/build-cursor-skills.sh`. |
| [`AGENTS.md`](./AGENTS.md) | Full Alfresco / SDK conventions (versions, layout, forbidden patterns, tests). |
| [`commands/*.md`](./commands/) | Portable specifications for each AIUP step (`requirements`, `scaffold`, `content-model`, …). |

Optional automation (team-shared if committed):

| Artifact | Role |
|----------|------|
| [`.cursor/hooks.json`](./.cursor/hooks.json) | Registers shell and file-edit hooks. |
| [`.cursor/hooks/before-shell-model-commit.sh`](./.cursor/hooks/before-shell-model-commit.sh) | Blocks `git commit` when staged files look like Alfresco model/context XML until you run validation (aligned with `content-model-validator` skill). |
| [`.cursor/hooks/after-file-edit-traceability.sh`](./.cursor/hooks/after-file-edit-traceability.sh) | After relevant file writes, reminds the agent to update traceability in `REQUIREMENTS.md` when that file exists. |
| [`.cursor/hooks/after-shell-maven-debugger.sh`](./.cursor/hooks/after-shell-maven-debugger.sh) | After a failed `mvn` / `mvnw` shell command, injects context to apply `alfresco-debugger-agent`. |

## Install in Cursor (this repo)

1. Open this folder as the **workspace root** in Cursor.
2. Confirm **Project Rules** are enabled (Settings → Rules).
3. Optional: enable **Hooks** in Cursor settings; run `chmod +x .cursor/hooks/*.sh` if scripts are not executable.
4. Regenerate skills after editing `skills/`, `agents/`, or `commands/`: `./scripts/build-cursor-skills.sh`

## Slash commands (primary workflow)

In **Agent** chat, type `/` followed by the command name (Cursor 2.4+):

```
/requirements We need to manage technical documents with categories
/scaffold
/content-model
```

Each command skill (`disable-model-invocation: true`) instructs the agent to read `AGENTS.md` and execute the matching `commands/<name>.md` spec.

List available commands:

```bash
./scripts/aiup-command.sh list
```

## Daily workflow (alternatives)

### A — `@` references (fast iteration)

In **Agent** (or Composer), ask for the step in plain language and attach the specs, for example:

- `@AGENTS.md`
- `@commands/scaffold.md`
- `@REQUIREMENTS.md` (if it already exists)

Example prompt:

> Execute the AIUP **scaffold** command per `@commands/scaffold.md`. Follow `@AGENTS.md`. If anything is ambiguous, ask before writing files.

### B — Rendered prompt (repeatable)

From the repository root:

```bash
./scripts/aiup-command.sh render --agent cursor scaffold
```

Copy the **entire** terminal output into Cursor Agent and send it. Add free-text requirements at the top or bottom as needed.

With user arguments (passed through to the prompt):

```bash
./scripts/aiup-command.sh render --agent cursor requirements \
  "We need to manage technical documents with categories and review dates"
```

### C — List commands

```bash
./scripts/aiup-command.sh list
```

Suggested order matches [README.md](./README.md): `requirements` → `scaffold` → feature commands (`content-model`, `workflow`, `scheduled-jobs`, `bootstrap-loader`, `rule-conditions`, `repository-patch`, `transforms`, `aca-extension`, …) → `docker-compose` → `test`.

After merging upstream changes, always run `./scripts/build-cursor-skills.sh` so the `aiup-alfresco` orchestrator includes new commands.

## Skills and subagents

Cursor discovers skills under [`.cursor/skills/`](./.cursor/skills/). Key entries:

| Skill | Use when |
|-------|----------|
| `aiup-alfresco` | User wants an AIUP workflow step without naming a command file |
| `content-model-validator` | Editing `*-model*.xml` or `*-context.xml` |
| `permission-model-validator` | Editing `*-permissionDefinitions.xml` |
| `audit-config-validator` | Editing `*-audit.xml` or audit Spring context |
| `rest-api-validator` | Editing v1 Public REST API resource classes |
| `alfresco-architect-agent` | Designing extension architecture from requirements |
| `alfresco-debugger-agent` | Diagnosing Maven / ACS stack traces |
| `alfresco-migrator-agent` | Migrating legacy AMPs or deprecated APIs |

Source files remain in [`skills/`](./skills/) and [`agents/`](./agents/) for Claude Code; run `./scripts/build-cursor-skills.sh` to refresh Cursor copies.

## Rules size and `globs`

The bundled rule [`.cursor/rules/aiup-alfresco.mdc`](./.cursor/rules/aiup-alfresco.mdc) is short and always applies. **`AGENTS.md` is large**; Cursor still loads it when the model reads it via `@` or when you rely on the rule’s instruction to read it before coding.

If you need a lighter rule set for unrelated work in the same repo, fork the rule: set `alwaysApply: false` and add `globs` (for example `**/alfresco/**`, `**/pom.xml`) so AIUP context attaches only when matching files are in scope.

## Hooks — install and behaviour

1. Ensure [`.cursor/hooks.json`](./.cursor/hooks.json) exists at the repo root (it does in this project).
2. Ensure hook scripts are executable: `chmod +x .cursor/hooks/*.sh`
3. Confirm **Hooks** are enabled in Cursor settings and reload the window after changing `hooks.json`.

**Commit gate:** when a shell command matches `git commit` and staged paths match Alfresco model/context patterns, the hook returns `permission: deny` until you validate (see `skills/content-model-validator/SKILL.md`).

**Traceability nudge:** after `Write` / `TabWrite` on paths that look like generated AIUP artefacts, the hook may inject `additional_context` reminding you to update `REQUIREMENTS.md` traceability.

If stdin field names change in a future Cursor release, update the `jq` paths in `.cursor/hooks/after-file-edit-traceability.sh` (see comments there).

## Reusing AIUP in another Alfresco repository

1. Add aiup-alfresco as a submodule (recommended): `git submodule add https://github.com/aborroy/aiup-alfresco.git tools/aiup-alfresco`
2. From the **consumer project root**, run: `./tools/aiup-alfresco/scripts/install-cursor-pack.sh`
3. Create a local version override rule if your ACS/SDK versions differ from `AGENTS.md` (see [CURSOR-INTEGRATION-GUIDE.md](./CURSOR-INTEGRATION-GUIDE.md)).
4. Open the consumer project as the Cursor workspace root and use `/requirements`, `/scaffold`, etc.
5. Re-run `install-cursor-pack.sh` after `git submodule update` to refresh skills.

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| `/scaffold` not in autocomplete | Cursor 2.4+ required; skills must be in **workspace root** `.cursor/skills/` (run `install-cursor-pack.sh` for consumer repos); reload window. |
| Agent ignores Alfresco conventions | Project **Rules** not disabled; `.cursor/rules/aiup-alfresco.mdc` present; model actually reads `AGENTS.md` (`@AGENTS.md` helps). |
| `unsupported agent 'cursor'` | Update `scripts/aiup-command.sh` from this repo; use `--agent generic` as a fallback. |
| Hooks never run | Paths in `hooks.json` relative to repo root; scripts executable; Hooks enabled in Cursor; restart Cursor after edits. |
| `jq: command not found` | Install `jq` or remove / disable hook entries that depend on it. |
| Windows | Prefer **Git Bash** or **WSL** for `.sh` hooks; keep paths POSIX-style in `hooks.json`. |

## See also

- [PORTABILITY.md](./PORTABILITY.md) — Codex, OpenClaw, and generic renderer workflow.
- [README.md](./README.md) — full command table and Claude Code plugin install.
