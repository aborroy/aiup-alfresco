#!/usr/bin/env bash
# Checker: rule-conditions
# Usage: rule-conditions.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== rule-conditions ===\n'

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

# ---- Condition evaluator class ----
CONDITION_JAVA=$(find "$GEN" -name "*Condition.java" | grep -v "Test" | head -1) || true
assert_file_exists "${CONDITION_JAVA:-/nonexistent}" "*Condition.java exists"
if [[ -n "$CONDITION_JAVA" ]]; then
    assert_grep "ActionConditionEvaluatorAbstractBase" "$CONDITION_JAVA" \
        "condition extends ActionConditionEvaluatorAbstractBase"
    assert_grep "evaluateImpl" "$CONDITION_JAVA" \
        "condition overrides evaluateImpl()"
    assert_grep "ActionCondition" "$CONDITION_JAVA" \
        "condition uses ActionCondition parameter type"
    assert_not_grep "implements ActionConditionEvaluator" "$CONDITION_JAVA" \
        "condition does not implement interface directly (must extend abstract base)"
    assert_not_grep "@Autowired" "$CONDITION_JAVA" \
        "condition does not use forbidden @Autowired"
    assert_not_grep "@Transactional" "$CONDITION_JAVA" \
        "condition does not use forbidden @Transactional"
    assert_not_grep "@PostConstruct" "$CONDITION_JAVA" \
        "condition does not use forbidden @PostConstruct"
fi

# ---- NAME constant ----
if [[ -n "$CONDITION_JAVA" ]]; then
    assert_grep 'static final String NAME' "$CONDITION_JAVA" \
        "condition declares NAME constant"
fi

# ---- service-context.xml with action-condition-evaluator parent ----
SERVICE_CTX=$(find "$GEN" -name "service-context.xml" | head -1) || true
assert_file_exists "${SERVICE_CTX:-/nonexistent}" "service-context.xml exists"
if [[ -n "$SERVICE_CTX" ]]; then
    assert_xml_wellformed "$SERVICE_CTX" "service-context.xml is well-formed XML"
    assert_grep "action-condition-evaluator" "$SERVICE_CTX" \
        "service-context.xml uses action-condition-evaluator parent"
    assert_not_grep 'parent="action-executer"' "$SERVICE_CTX" \
        "condition bean does not use forbidden action-executer parent"
fi

# ---- module-context.xml imports service-context ----
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "service-context" "$MODULE_CTX" \
        "module-context.xml imports service-context.xml"
fi

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*ConditionTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*ConditionTest.java exists"
if [[ -n "$TEST_JAVA" ]]; then
    assert_grep "ActionCondition" "$TEST_JAVA" \
        "test mocks ActionCondition"
    assert_grep "@ExtendWith(MockitoExtension.class)\|@RunWith(MockitoJUnitRunner" "$TEST_JAVA" \
        "test uses Mockito extension"
    assert_grep "evaluateImpl\|evaluate" "$TEST_JAVA" \
        "test calls evaluateImpl()"
fi

print_summary "rule-conditions"
exit_with_status
