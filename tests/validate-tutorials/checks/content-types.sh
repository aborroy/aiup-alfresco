#!/usr/bin/env bash
# Checker: content-types
# Usage: content-types.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== content-types ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_PROPS=$(find "$GEN" -name "module.properties" | head -1)
if [[ -n "$MODULE_PROPS" ]]; then
    assert_grep "module.id" "$MODULE_PROPS" "module.properties has module.id"
    assert_grep "module.version" "$MODULE_PROPS" "module.properties has module.version"
else
    _fail "module.properties exists" "not found under $GEN"
fi

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1)
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Content model XML ----
CONTENT_MODEL=$(find "$GEN" -name "content-model.xml" | head -1)
assert_file_exists "${CONTENT_MODEL:-/nonexistent}" "content-model.xml exists"

if [[ -n "$CONTENT_MODEL" ]]; then
    assert_xml_wellformed "$CONTENT_MODEL" "content-model.xml is well-formed XML"
    assert_grep '<namespace uri=' "$CONTENT_MODEL" "content-model.xml declares a namespace"
    assert_not_grep 'enforced="true"' "$CONTENT_MODEL" "content-model.xml has no enforced=true (forbidden)"
fi

# ---- Java model constants interface ----
MODEL_JAVA=$(find "$GEN" -name "*Model.java" | head -1)
assert_file_exists "${MODEL_JAVA:-/nonexistent}" "*Model.java constants interface exists"
[[ -n "$MODEL_JAVA" ]] && assert_grep "QName.createQName(" "$MODEL_JAVA" "*Model.java uses two-arg QName.createQName()"

# ---- Bootstrap context registers dictionaryModelBootstrap ----
BOOTSTRAP_CTX=$(find "$GEN" -name "bootstrap-context.xml" | head -1)
assert_file_exists "${BOOTSTRAP_CTX:-/nonexistent}" "bootstrap-context.xml exists"
[[ -n "$BOOTSTRAP_CTX" ]] && assert_grep "dictionaryModelBootstrap" "$BOOTSTRAP_CTX" "bootstrap-context.xml uses dictionaryModelBootstrap bean"

print_summary "content-types"
exit_with_status
