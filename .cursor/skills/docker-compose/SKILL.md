---
name: docker-compose
description: Generate a Docker Compose file with full ACS stack.
disable-model-invocation: true
---

# AIUP command: docker-compose

1. Read `AGENTS.md`.
2. Execute the full procedure in `commands/docker-compose.md`.
3. Apply referenced validator skills under `.cursor/skills/` when the command mentions them.
4. Create or update real files unless the user asked for a plan only.

Treat any user text after `/docker-compose` as `$ARGUMENTS` from the command spec.
