#!/usr/bin/env bash
# Checker: actions
# Usage: actions.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== actions ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_PROPS=$(find "$GEN" -name "module.properties" -not -path "*/target/*" | head -1)
if [[ -n "$MODULE_PROPS" ]]; then
    assert_grep "module.id" "$MODULE_PROPS" "module.properties has module.id"
    assert_grep "module.version" "$MODULE_PROPS" "module.properties has module.version"
else
    _fail "module.properties exists" "not found under $GEN"
fi

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1)
[[ -n "$MODULE_CTX" ]] && assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"

# ---- Content model (pre-req) ----
CONTENT_MODEL=$(find "$GEN" -name "content-model.xml" -not -path "*/target/*" | head -1)
assert_file_exists "${CONTENT_MODEL:-/nonexistent}" "content-model.xml exists (actions pre-req)"
[[ -n "$CONTENT_MODEL" ]] && assert_xml_wellformed "$CONTENT_MODEL" "content-model.xml is well-formed"
[[ -n "$CONTENT_MODEL" ]] && assert_not_grep 'enforced="true"' "$CONTENT_MODEL" "content-model.xml has no enforced=true"

MODEL_JAVA=$(find "$GEN" -name "*Model.java" | head -1)
assert_file_exists "${MODEL_JAVA:-/nonexistent}" "*Model.java constants interface exists"
[[ -n "$MODEL_JAVA" ]] && assert_grep "QName.createQName(" "$MODEL_JAVA" "*Model.java uses two-arg QName.createQName()"

# ---- Action executor checks ----
ACTION_JAVA=$(find "$GEN" -name "*ActionExecuter.java" | head -1)
assert_file_exists "${ACTION_JAVA:-/nonexistent}" "*ActionExecuter.java exists"
[[ -n "$ACTION_JAVA" ]] && assert_grep "ActionExecuterAbstractBase" "$ACTION_JAVA" "action class extends ActionExecuterAbstractBase"
[[ -n "$ACTION_JAVA" ]] && assert_grep "executeImpl" "$ACTION_JAVA" "action class implements executeImpl()"

# ---- service-context.xml with action-executer parent bean ----
SERVICE_CTX=$(find "$GEN" -name "service-context.xml" -not -path "*/target/*" | head -1)
assert_file_exists "${SERVICE_CTX:-/nonexistent}" "service-context.xml exists"
if [[ -n "$SERVICE_CTX" ]]; then
    assert_grep 'action-executer' "$SERVICE_CTX" "service-context.xml registers action-executer bean"
    assert_grep 'id="[a-z][a-z0-9]*\.[a-zA-Z][a-zA-Z0-9]*"' "$SERVICE_CTX" \
        "action bean id follows {prefix}.{beanName} pattern"
fi

print_summary "actions"
exit_with_status
