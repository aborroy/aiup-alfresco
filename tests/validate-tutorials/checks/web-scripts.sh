#!/usr/bin/env bash
# Checker: web-scripts
# Usage: web-scripts.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== web-scripts ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_PROPS=$(find "$GEN" -name "module.properties" | head -1)
if [[ -n "$MODULE_PROPS" ]]; then
    assert_grep "module.id" "$MODULE_PROPS" "module.properties has module.id"
    assert_grep "module.version" "$MODULE_PROPS" "module.properties has module.version"
else
    _fail "module.properties exists" "not found under $GEN"
fi

MODULE_CTX=$(find "$GEN" -name "module-context.xml" | head -1)
[[ -n "$MODULE_CTX" ]] && assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"

# ---- Content model (pre-req) ----
CONTENT_MODEL=$(find "$GEN" -name "content-model.xml" | head -1)
assert_file_exists "${CONTENT_MODEL:-/nonexistent}" "content-model.xml exists (web-scripts pre-req)"
[[ -n "$CONTENT_MODEL" ]] && assert_xml_wellformed "$CONTENT_MODEL" "content-model.xml is well-formed"
[[ -n "$CONTENT_MODEL" ]] && assert_not_grep 'enforced="true"' "$CONTENT_MODEL" "content-model.xml has no enforced=true"

MODEL_JAVA=$(find "$GEN" -name "*Model.java" | head -1)
assert_file_exists "${MODEL_JAVA:-/nonexistent}" "*Model.java constants interface exists"

# ---- Web script descriptors ----
FIRST_DESC=$(find "$GEN" -name "*.desc.xml" | head -1)
assert_file_exists "${FIRST_DESC:-/nonexistent}" "at least one *.desc.xml descriptor exists"

if [[ -n "$FIRST_DESC" ]]; then
    assert_xml_wellformed_dir "$GEN" "*.desc.xml" "all descriptors are well-formed XML"
    assert_grep_in_dir '<authentication>' "$GEN" "*.desc.xml" "all descriptors have <authentication>"
    assert_grep_in_dir '<format' "$GEN" "*.desc.xml" "all descriptors have <format>"
    assert_grep_in_dir '<transaction>' "$GEN" "*.desc.xml" "all descriptors have <transaction>"
    assert_grep_in_dir '<cache>' "$GEN" "*.desc.xml" "all descriptors have <cache>"
    # Generated URLs must follow AGENTS.md /api/ convention
    assert_grep_in_dir '/api/' "$GEN" "*.desc.xml" "all descriptors use /api/ URL prefix"
fi

# ---- At least one JSON FTL response template ----
FIRST_FTL=$(find "$GEN" -name "*.json.ftl" | head -1)
assert_file_exists "${FIRST_FTL:-/nonexistent}" "at least one *.json.ftl response template exists"

# ---- webscript-context.xml ----
WEBSCRIPT_CTX=$(find "$GEN" -name "webscript-context.xml" | head -1)
assert_file_exists "${WEBSCRIPT_CTX:-/nonexistent}" "webscript-context.xml exists"

print_summary "web-scripts"
exit_with_status
