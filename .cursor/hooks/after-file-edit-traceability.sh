#!/usr/bin/env bash
# Cursor afterFileEdit — inject reminder to update REQUIREMENTS.md traceability
# (same intent as scripts/post-generate-traceability.sh). stdout: JSON with
# additional_context when applicable, else empty.

set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
# shellcheck source=../../scripts/traceability-artefacts.sh
[ -f "$ROOT_DIR/scripts/traceability-artefacts.sh" ] || exit 0
source "$ROOT_DIR/scripts/traceability-artefacts.sh"

INPUT=$(cat)
FILE_PATH=$(printf '%s\n' "$INPUT" | jq -r '
  .tool_input.file_path // .tool_input.path // .file_path // .path // .uri // empty
')

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
    exit 0
fi

classify_traceability_artefact "$FILE_PATH" || exit 0

PROJECT_DIR=$(pwd)
REQ_FILE=""
for candidate in "$PROJECT_DIR/REQUIREMENTS.md" "$PROJECT_DIR/docs/REQUIREMENTS.md"; do
    if [ -f "$candidate" ]; then
        REQ_FILE="$candidate"
        break
    fi
done

if [ -z "$REQ_FILE" ]; then
    exit 0
fi

MSG="Artefact of type '${ARTEFACT_TYPE}' was written to ${FILE_PATH}. Update the traceability section in ${REQ_FILE} to reflect this generated artefact."

jq -n --arg m "$MSG" '{additional_context: $m}'
exit 0
