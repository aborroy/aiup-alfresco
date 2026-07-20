#!/usr/bin/env bash
# Cursor beforeShellExecution — block git commit when staged Alfresco model/context
# XML is present until validated (same policy as scripts/pre-commit-model-validator.sh).
# stdin: JSON with .command (Cursor shell hook shape).
# stdout: JSON with permission / user_message / agent_message when blocking.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

if ! echo "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  exit 0
fi

STAGED_MODEL_FILES=$(git diff --cached --name-only 2>/dev/null | grep -E '(-model.*\.xml|model/.*\.xml|-context\.xml|context/.*-context\.xml)' || true)

if [ -z "$STAGED_MODEL_FILES" ]; then
  exit 0
fi

jq -n \
  --arg files "$STAGED_MODEL_FILES" \
  '{
    permission: "deny",
    user_message: ("Staged files include Alfresco content-model or context XML. Run the content-model-validator skill on these paths before committing:\n" + $files),
    agent_message: "Blocked git commit: validate staged model/context XML using skills/content-model-validator/SKILL.md, then retry."
  }'

exit 0
