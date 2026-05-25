#!/usr/bin/env bash
# Checker: maven-sdk-baseline
# Usage: maven-sdk-baseline.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== maven-sdk-baseline ===\n'

# At least one pom.xml must contain the correct SDK parent
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

# module.properties present with required keys
MODULE_PROPS=$(find "$GEN" -name "module.properties" | head -1)
if [[ -n "$MODULE_PROPS" ]]; then
    assert_grep "module.id" "$MODULE_PROPS" "module.properties has module.id"
    assert_grep "module.version" "$MODULE_PROPS" "module.properties has module.version"
else
    _fail "module.properties exists" "not found under $GEN"
fi

# module-context.xml with at least one context import
MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1)
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

print_summary "maven-sdk-baseline"
exit_with_status
