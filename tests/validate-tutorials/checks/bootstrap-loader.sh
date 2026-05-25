#!/usr/bin/env bash
# Checker: bootstrap-loader
# Usage: bootstrap-loader.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== bootstrap-loader ===\n'

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

# ---- Bootstrap loader class ----
LOADER_JAVA=$(find "$GEN" -name "*BootstrapLoader.java" | grep -v "Test" | head -1) || true
assert_file_exists "${LOADER_JAVA:-/nonexistent}" "*BootstrapLoader.java exists"
if [[ -n "$LOADER_JAVA" ]]; then
    assert_grep "AbstractModuleComponent" "$LOADER_JAVA" "loader extends AbstractModuleComponent"
    assert_grep "executeInternal" "$LOADER_JAVA" "loader overrides executeInternal()"
    assert_grep "nodeLocatorService\|NodeLocatorService" "$LOADER_JAVA" "loader uses NodeLocatorService"
    assert_not_grep "@PostConstruct" "$LOADER_JAVA" "loader does not use forbidden @PostConstruct"
    assert_not_grep "@Transactional" "$LOADER_JAVA" "loader does not use forbidden @Transactional"
    assert_not_grep "RetryingTransactionHelper" "$LOADER_JAVA" "loader does not use RetryingTransactionHelper inside executeInternal"
    assert_not_grep "AbstractLifecycleBean" "$LOADER_JAVA" "loader does not extend forbidden AbstractLifecycleBean"
fi

# ---- Bootstrap context XML ----
BOOTSTRAP_CTX=$(find "$GEN" -name "bootstrap-context.xml" | head -1) || true
assert_file_exists "${BOOTSTRAP_CTX:-/nonexistent}" "bootstrap-context.xml exists"
if [[ -n "$BOOTSTRAP_CTX" ]]; then
    assert_xml_wellformed "$BOOTSTRAP_CTX" "bootstrap-context.xml is well-formed XML"
    assert_grep "module.baseComponent" "$BOOTSTRAP_CTX" "bootstrap-context.xml uses module.baseComponent parent"
    assert_grep "moduleId" "$BOOTSTRAP_CTX" "bootstrap-context.xml sets moduleId property"
    assert_grep "sinceVersion" "$BOOTSTRAP_CTX" "bootstrap-context.xml sets sinceVersion property"
    assert_grep "appliesFromVersion" "$BOOTSTRAP_CTX" "bootstrap-context.xml sets appliesFromVersion property"
    assert_grep "nodeLocatorService" "$BOOTSTRAP_CTX" "bootstrap-context.xml injects nodeLocatorService"
fi

# ---- module-context.xml imports bootstrap-context ----
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "bootstrap-context" "$MODULE_CTX" "module-context.xml imports bootstrap-context.xml"
fi

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*BootstrapLoaderTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*BootstrapLoaderTest.java exists"
if [[ -n "$TEST_JAVA" ]]; then
    assert_grep "NodeLocatorService\|nodeLocatorService" "$TEST_JAVA" "test mocks NodeLocatorService"
    assert_grep "@ExtendWith(MockitoExtension.class)\|@RunWith(MockitoJUnitRunner" "$TEST_JAVA" "test uses Mockito extension"
    assert_grep "executeInternal\|execute" "$TEST_JAVA" "test calls executeInternal()"
fi

print_summary "bootstrap-loader"
exit_with_status
