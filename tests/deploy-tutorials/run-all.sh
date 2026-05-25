#!/usr/bin/env bash
# Run all deploy-tutorial scenarios sequentially and print a summary.
#
# Usage:
#   run-all.sh [--no-teardown]
#
# Each scenario: generate → build → deploy → smoke → teardown
# Scenarios run sequentially (not in parallel) to avoid port conflicts.
#
# Exit code: 0 if all pass, 1 if any fail.
# SKIP is reported when the generated/ directory is empty.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SCENARIOS="in-process out-of-process transforms aca-extension"
NO_TEARDOWN="${1:-}"

PASS=0
FAIL=0
SKIP=0
SUMMARY=""

for scenario in $SCENARIOS; do
    gen_dir="$SCRIPT_DIR/generated/$scenario"
    # For aca-extension: check the extension source dir; compose.yaml is static
    if [[ "$scenario" == "aca-extension" ]]; then
        file_count=$(find "$gen_dir/ext-deploy-test" -type f 2>/dev/null | wc -l | tr -d ' ') || file_count=0
    else
        file_count=$(find "$gen_dir" -not -name ".gitkeep" -not -name "REQUIREMENTS.md" \
            -type f 2>/dev/null | wc -l | tr -d ' ') || file_count=0
    fi

    if [[ "$file_count" -eq 0 ]]; then
        printf '\n[%s] SKIP — run generate.sh %s first\n' "$scenario" "$scenario"
        SKIP=$((SKIP+1))
        SUMMARY="${SUMMARY}$(printf '%-25s' "$scenario") SKIP\n"
        continue
    fi

    if bash "$SCRIPT_DIR/deploy.sh" "$scenario" $NO_TEARDOWN; then
        PASS=$((PASS+1))
        SUMMARY="${SUMMARY}$(printf '%-25s' "$scenario") PASS\n"
    else
        FAIL=$((FAIL+1))
        SUMMARY="${SUMMARY}$(printf '%-25s' "$scenario") FAIL\n"
    fi
done

printf '\n%-25s Result\n' "Scenario"
printf '%s\n' "-----------------------------------"
printf '%b' "$SUMMARY"
printf '%s\n' "-----------------------------------"
printf '%-25s PASS:%d  FAIL:%d  SKIP:%d\n' "TOTAL" "$PASS" "$FAIL" "$SKIP"

[[ $FAIL -gt 0 ]] && exit 1
exit 0
