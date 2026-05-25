#!/usr/bin/env bash
# Generate all deploy-test projects using claude -p (non-interactive).
#
# Usage:
#   generate.sh [scenario...]
#
# Scenarios: in-process out-of-process transforms aca-extension
# With no arguments, generates all 4 scenarios.
#
# Each scenario:
#   1. Copies its REQUIREMENTS.md into a fresh generated/ directory
#   2. Runs the appropriate aiup slash commands via scripts/aiup-command.sh
#   3. The generated directory is ready for deploy.sh to build and run

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AIUP_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
GENERATED_BASE="$SCRIPT_DIR/generated"
AIUP_CMD="$AIUP_ROOT/scripts/aiup-command.sh"

cmds_for() {
    case "$1" in
        in-process)      echo "scaffold content-model web-scripts docker-compose" ;;
        out-of-process)  echo "scaffold events docker-compose" ;;
        transforms)      echo "scaffold content-model transforms docker-compose" ;;
        aca-extension)   echo "aca-extension" ;;
        *) return 1 ;;
    esac
}

ALL_SCENARIOS="in-process out-of-process transforms aca-extension"
TARGETS="${*:-$ALL_SCENARIOS}"

run_command() {
    local cmd="$1"
    local gen_dir="$2"

    local base_prompt
    base_prompt=$("$AIUP_CMD" render --agent generic "$cmd")

    local full_prompt
    full_prompt="$base_prompt

IMPORTANT — path context for this non-interactive run:
- REQUIREMENTS.md is at: $gen_dir/REQUIREMENTS.md
- Read it from that absolute path.
- Write ALL generated files under: $gen_dir/
- Use absolute paths when creating files."

    printf '  -> /%s\n' "$cmd"
    echo "$full_prompt" | \
        claude -p --dangerously-skip-permissions \
               --add-dir "$gen_dir" \
               --add-dir "$AIUP_ROOT" \
               2>&1 \
        | grep -v "^$" \
        | tail -3
}

run_scenario() {
    local scenario="$1"
    local gen_dir="$GENERATED_BASE/$scenario"
    local reqs="$SCRIPT_DIR/$scenario/REQUIREMENTS.md"

    printf '\n[%s] Generating...\n' "$scenario"

    [[ -f "$reqs" ]] || { printf '[%s] ERROR: %s not found\n' "$scenario" "$reqs"; return 1; }

    rm -rf "$gen_dir"
    mkdir -p "$gen_dir"
    cp "$reqs" "$gen_dir/REQUIREMENTS.md"

    local cmds
    cmds=$(cmds_for "$scenario") || { printf '[%s] ERROR: unknown scenario\n' "$scenario"; return 1; }

    for cmd in $cmds; do
        run_command "$cmd" "$gen_dir"
    done

    printf '[%s] Generation done.\n' "$scenario"
}

PASS=0
FAIL=0
FAILED=""

for scenario in $TARGETS; do
    if cmds_for "$scenario" >/dev/null 2>&1; then
        if run_scenario "$scenario"; then
            PASS=$((PASS+1))
        else
            FAIL=$((FAIL+1))
            FAILED="$FAILED $scenario"
        fi
    else
        printf 'ERROR: unknown scenario "%s"\n' "$scenario"
        FAIL=$((FAIL+1))
    fi
done

printf '\n==============================\n'
printf 'Generation: %d/%d scenarios\n' "$PASS" "$((PASS+FAIL))"
[[ -n "$FAILED" ]] && printf 'Failed:%s\n' "$FAILED"
printf '==============================\n'
[[ $FAIL -gt 0 ]] && exit 1
exit 0
