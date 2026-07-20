---
name: repository-patch
description: Generate an AbstractPatch repository patch that migrates existing data or structure between module versions, runs exactly once per repository, and is recorded in alf_applied_patch. In-Process SDK (Maven) only.
disable-model-invocation: true
---

# AIUP command: repository-patch

1. Read `AGENTS.md`.
2. Execute the full procedure in `commands/repository-patch.md`.
3. Apply referenced validator skills under `.cursor/skills/` when the command mentions them.
4. Create or update real files unless the user asked for a plan only.

Treat any user text after `/repository-patch` as `$ARGUMENTS` from the command spec.
