#!/usr/bin/env bash
# Cursor afterShellExecution — when a Maven command fails, inject debugger context
# (same intent as scripts/on-error-maven-debugger.sh + agents/alfresco-debugger-agent.md).
# stdin: JSON with .command, .output (or .stdout/.stderr), .exitCode (field names may vary).

set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s\n' "$INPUT" | jq -r '.command // empty')
EXIT_CODE=$(printf '%s\n' "$INPUT" | jq -r '.exitCode // .exit_code // .code // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

if ! echo "$COMMAND" | grep -qE '(^|[[:space:]])(\.?/?mvn(w)?[[:space:]]|mvn(w)?[[:space:]])'; then
  exit 0
fi

if [ -z "$EXIT_CODE" ] || [ "$EXIT_CODE" = "null" ] || [ "$EXIT_CODE" = "0" ]; then
  exit 0
fi

OUTPUT=$(printf '%s\n' "$INPUT" | jq -r '
  .output // .stdout // .stderr //
  (.stdout + "\n" + .stderr) //
  empty
' 2>/dev/null || true)

ERROR_TAIL=$(printf '%s\n' "$OUTPUT" | tail -80)

MSG=$(cat <<EOF
Maven build failed. Apply the alfresco-debugger-agent skill (or @agents/alfresco-debugger-agent.md).

Build command: $COMMAND

Error output (last 80 lines):
$ERROR_TAIL
EOF
)

jq -n --arg m "$MSG" '{additional_context: $m}'
exit 0
