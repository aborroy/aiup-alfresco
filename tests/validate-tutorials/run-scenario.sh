#!/usr/bin/env bash
# Validate a single tutorial scenario against committed generated artefacts.
#
# Usage:
#   run-scenario.sh <scenario> [<generated-dir>]
#
# <scenario>    : maven-sdk-baseline | content-types | actions | behaviours | web-scripts | workflows
# <generated-dir>: optional override; defaults to tests/validate-tutorials/generated/<scenario>/
#
# The generated directory must be populated first by running the relevant aiup slash
# commands inside Claude Code (see tests/validate-tutorials/README.md for instructions).

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AIUP_ROOT="${AIUP_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SERIES_ROOT="${SERIES_ROOT:-$(cd "$AIUP_ROOT/../alfresco-developer-series" && pwd)}"

SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
CHECKS_DIR="$SCRIPT_DIR/checks"
GENERATED_BASE="$SCRIPT_DIR/generated"

usage() {
    printf 'Usage: %s <scenario> [<generated-dir>]\n' "$(basename "$0")"
    printf 'Scenarios: maven-sdk-baseline content-types actions behaviours web-scripts workflows scheduled-jobs bootstrap-loader rule-conditions repository-patch transforms aca-extension\n'
}

[[ $# -lt 1 ]] && { usage >&2; exit 1; }

SCENARIO="$1"
GEN_DIR="${2:-$GENERATED_BASE/$SCENARIO}"

# Map scenario to reference path (bash 3 compatible)
ref_path_for() {
    case "$1" in
        maven-sdk-baseline) echo "docs/maven-sdk/maven-sdk-tutorial" ;;
        content-types)      echo "docs/content/content-tutorial" ;;
        actions)            echo "docs/actions/actions-tutorial" ;;
        behaviours)         echo "docs/behaviors/behavior-tutorial" ;;
        web-scripts)        echo "docs/webscripts/webscripts-tutorial" ;;
        workflows)          echo "docs/workflow/workflow-tutorial" ;;
        scheduled-jobs)     echo "docs/maven-sdk/maven-sdk-tutorial" ;;
        bootstrap-loader)   echo "docs/maven-sdk/maven-sdk-tutorial" ;;
        rule-conditions)    echo "docs/actions/actions-tutorial" ;;
        repository-patch)   echo "docs/maven-sdk/maven-sdk-tutorial" ;;
        transforms)         echo "docs/maven-sdk/maven-sdk-tutorial" ;;
        aca-extension)      echo "docs/maven-sdk/maven-sdk-tutorial" ;;
        *) return 1 ;;
    esac
}

REF_SUBPATH=$(ref_path_for "$SCENARIO" 2>/dev/null) || {
    printf 'Unknown scenario: %s\n' "$SCENARIO" >&2; usage >&2; exit 1
}
REF_DIR="$SERIES_ROOT/$REF_SUBPATH"
CHECKER="$CHECKS_DIR/${SCENARIO}.sh"

[[ -f "$CHECKER" ]] || { printf 'Checker not found: %s\n' "$CHECKER" >&2; exit 1; }

# Check generated directory has content beyond the placeholder
FILE_COUNT=$(find "$GEN_DIR" -not -name ".gitkeep" -not -name "REQUIREMENTS.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$FILE_COUNT" -eq 0 ]]; then
    printf '\n[%s] SKIP — generated directory is empty.\n' "$SCENARIO"
    printf '  Populate it by running these commands in Claude Code:\n'
    case "$SCENARIO" in
        maven-sdk-baseline) printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        content-types)      printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  then  /content-model\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        actions)            printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /content-model  /actions\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        behaviours)         printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /content-model  /behaviours\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        web-scripts)        printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /content-model  /web-scripts\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        workflows)          printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /content-model  /workflow\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        scheduled-jobs)     printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /content-model  /scheduled-jobs\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        bootstrap-loader)   printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /bootstrap-loader\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        rule-conditions)    printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /content-model  /rule-conditions\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        repository-patch)   printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /content-model  /repository-patch\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        transforms)         printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /scaffold  /transforms\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
        aca-extension)      printf '    1. Copy scenarios/%s/REQUIREMENTS.md to a working dir\n' "$SCENARIO"
                            printf '    2. Run: /aca-extension\n'
                            printf '    3. Copy generated files to: %s/\n' "$GEN_DIR" ;;
    esac
    exit 0
fi

printf '\n[%s] Checking generated artefacts in: %s\n' "$SCENARIO" "$GEN_DIR"
chmod +x "$CHECKER"
if bash "$CHECKER" "$GEN_DIR" "$REF_DIR"; then
    printf '[%s] PASSED\n' "$SCENARIO"
    exit 0
else
    printf '[%s] FAILED — review artefacts at %s\n' "$SCENARIO" "$GEN_DIR"
    exit 1
fi
