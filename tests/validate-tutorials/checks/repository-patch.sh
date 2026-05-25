#!/usr/bin/env bash
# Checker: repository-patch
# Usage: repository-patch.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== repository-patch ===\n'

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

# ---- Patch class ----
PATCH_JAVA=$(find "$GEN" -name "*Patch.java" | grep -v "Test" | head -1) || true
assert_file_exists "${PATCH_JAVA:-/nonexistent}" "*Patch.java exists"
if [[ -n "$PATCH_JAVA" ]]; then
    assert_grep "AbstractPatch" "$PATCH_JAVA" \
        "patch extends AbstractPatch"
    assert_grep "applyInternal" "$PATCH_JAVA" \
        "patch overrides applyInternal()"
    assert_grep "return " "$PATCH_JAVA" \
        "applyInternal() returns a summary string"
    assert_not_grep "@Transactional" "$PATCH_JAVA" \
        "patch does not use forbidden @Transactional"
    assert_not_grep "RetryingTransactionHelper" "$PATCH_JAVA" \
        "patch does not use RetryingTransactionHelper"
    assert_not_grep "LANGUAGE_LUCENE" "$PATCH_JAVA" \
        "patch does not use forbidden LANGUAGE_LUCENE"
    assert_grep "results.close\|resultSet.close\|\.close()" "$PATCH_JAVA" \
        "patch closes ResultSet"
fi

# ---- patch-context.xml ----
PATCH_CTX=$(find "$GEN" -name "patch-context.xml" | head -1) || true
assert_file_exists "${PATCH_CTX:-/nonexistent}" "patch-context.xml exists"
if [[ -n "$PATCH_CTX" ]]; then
    assert_xml_wellformed "$PATCH_CTX" "patch-context.xml is well-formed XML"
    assert_grep "basePatch" "$PATCH_CTX" \
        "patch-context.xml uses basePatch parent"
    assert_grep "fixesFromSchema" "$PATCH_CTX" \
        "patch-context.xml sets fixesFromSchema"
    assert_grep "fixesToSchema" "$PATCH_CTX" \
        "patch-context.xml sets fixesToSchema"
    assert_grep "targetSchema" "$PATCH_CTX" \
        "patch-context.xml sets targetSchema"
    assert_grep '"id"' "$PATCH_CTX" \
        "patch-context.xml sets id property"
    assert_grep "description" "$PATCH_CTX" \
        "patch-context.xml sets description property"
fi

# ---- module-context.xml imports patch-context ----
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "patch-context" "$MODULE_CTX" \
        "module-context.xml imports patch-context.xml"
fi

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*PatchTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*PatchTest.java exists"
if [[ -n "$TEST_JAVA" ]]; then
    assert_grep "SearchService\|searchService" "$TEST_JAVA" \
        "test exercises searchService"
    assert_grep "@ExtendWith(MockitoExtension.class)\|@RunWith(MockitoJUnitRunner" "$TEST_JAVA" \
        "test uses Mockito extension"
    assert_grep "applyInternal\|apply" "$TEST_JAVA" \
        "test calls applyInternal()"
    assert_grep "ResultSet\|resultSet" "$TEST_JAVA" \
        "test mocks ResultSet"
fi

print_summary "repository-patch"
exit_with_status
