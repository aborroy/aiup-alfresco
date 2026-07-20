---
name: transforms
description: Register a custom rendition definition (Platform JAR) and, when no built-in transform covers the required source/target mimetype pair, scaffold a custom Transform Engine (Spring Boot, Out-of-Process). Optionally registers a new MIME type.
disable-model-invocation: true
---

# AIUP command: transforms

1. Read `AGENTS.md`.
2. Execute the full procedure in `commands/transforms.md`.
3. Apply referenced validator skills under `.cursor/skills/` when the command mentions them.
4. Create or update real files unless the user asked for a plan only.

Treat any user text after `/transforms` as `$ARGUMENTS` from the command spec.
