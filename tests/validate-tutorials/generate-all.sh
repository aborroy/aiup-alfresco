#!/usr/bin/env bash
# Automatically generate all scenario artefacts using claude -p (non-interactive).
#
# Usage:
#   generate-all.sh [scenario...]
#
# With no arguments, generates all 6 scenarios.
# With arguments, generates only the named scenarios:
#   generate-all.sh content-types workflows
#
# Requirements:
#   - claude CLI in PATH
#   - No interactive input needed

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AIUP_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
GENERATED_DIR="$SCRIPT_DIR/generated"
AIUP_CMD="$AIUP_ROOT/scripts/aiup-command.sh"

# Map scenario → ordered commands (space-separated)
cmds_for() {
    case "$1" in
        maven-sdk-baseline) echo "scaffold" ;;
        content-types)      echo "scaffold content-model" ;;
        actions)            echo "scaffold content-model actions" ;;
        behaviours)         echo "scaffold content-model behaviours" ;;
        web-scripts)        echo "scaffold content-model web-scripts" ;;
        workflows)          echo "scaffold content-model workflow" ;;
        scheduled-jobs)     echo "scaffold content-model scheduled-jobs" ;;
        *) return 1 ;;
    esac
}

ALL_SCENARIOS="maven-sdk-baseline content-types actions behaviours web-scripts workflows scheduled-jobs"
TARGETS="${*:-$ALL_SCENARIOS}"

PASS=0
FAIL=0
FAILED_SCENARIOS=""

run_command() {
    local cmd="$1"
    local gen_dir="$2"

    # Render the base prompt, then append explicit path context so claude -p
    # can locate REQUIREMENTS.md and knows where to write files.
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
    local gen_dir="$GENERATED_DIR/$scenario"
    local reqs="$SCENARIOS_DIR/$scenario/REQUIREMENTS.md"

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

    printf '[%s] Done.\n' "$scenario"
}

for scenario in $TARGETS; do
    if cmds_for "$scenario" >/dev/null 2>&1; then
        if run_scenario "$scenario"; then
            PASS=$((PASS + 1))
        else
            FAIL=$((FAIL + 1))
            FAILED_SCENARIOS="$FAILED_SCENARIOS $scenario"
        fi
    else
        printf 'ERROR: unknown scenario "%s" — skipping\n' "$scenario"
        FAIL=$((FAIL + 1))
    fi
done

printf '\n==============================\n'
printf 'Generation: %d/%d scenarios\n' "$PASS" "$((PASS + FAIL))"
[[ -n "$FAILED_SCENARIOS" ]] && printf 'Failed:%s\n' "$FAILED_SCENARIOS"
printf '==============================\n'
printf '\nNow run checks:\n  %s/run-all.sh\n' "$SCRIPT_DIR"

[[ $FAIL -gt 0 ]] && exit 1
exit 0
