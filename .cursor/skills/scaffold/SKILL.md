---
name: scaffold
description: Scaffolds one deployable project or a mixed multi-project repository from REQUIREMENTS.md: pom.xml(s), module.properties, module-context.xml, Share-tier base structure, and Spring Boot Application class. Supports Platform JAR (in-process), Share JAR (web-tier), Event Handler (out-of-process), and mixed architectures. Run this first, before /content-model.
disable-model-invocation: true
---

# AIUP command: scaffold

1. Read `AGENTS.md`.
2. Execute the full procedure in `commands/scaffold.md`.
3. Apply referenced validator skills under `.cursor/skills/` when the command mentions them.
4. Create or update real files unless the user asked for a plan only.

Treat any user text after `/scaffold` as `$ARGUMENTS` from the command spec.
