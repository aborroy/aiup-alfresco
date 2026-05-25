#!/usr/bin/env bash
# Checker: behaviours
# Usage: behaviours.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== behaviours ===\n'

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
[[ -n "$MODULE_CTX" ]] && assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"

# ---- Content model (pre-req) ----
CONTENT_MODEL=$(find "$GEN" -name "content-model.xml" | head -1)
assert_file_exists "${CONTENT_MODEL:-/nonexistent}" "content-model.xml exists (behaviours pre-req)"
[[ -n "$CONTENT_MODEL" ]] && assert_xml_wellformed "$CONTENT_MODEL" "content-model.xml is well-formed"
[[ -n "$CONTENT_MODEL" ]] && assert_not_grep 'enforced="true"' "$CONTENT_MODEL" "content-model.xml has no enforced=true"

MODEL_JAVA=$(find "$GEN" -name "*Model.java" | head -1)
assert_file_exists "${MODEL_JAVA:-/nonexistent}" "*Model.java constants interface exists"
[[ -n "$MODEL_JAVA" ]] && assert_grep "QName.createQName(" "$MODEL_JAVA" "*Model.java uses two-arg QName.createQName()"

# ---- Behaviour class checks ----
BEHAVIOUR_JAVA=$(find "$GEN" -name "*Behaviour.java" | head -1)
assert_file_exists "${BEHAVIOUR_JAVA:-/nonexistent}" "*Behaviour.java exists"

if [[ -n "$BEHAVIOUR_JAVA" ]]; then
    assert_grep "Policy" "$BEHAVIOUR_JAVA" "behaviour class references a *Policy interface"
    assert_grep "PolicyComponent" "$BEHAVIOUR_JAVA" "behaviour class has PolicyComponent dependency"
    assert_grep "JavaBehaviour" "$BEHAVIOUR_JAVA" "behaviour class uses JavaBehaviour"
    assert_grep "bindClassBehaviour\|bindBehaviour\|bindAssociationBehaviour" "$BEHAVIOUR_JAVA" "behaviour registers with PolicyComponent"
    assert_not_grep "LANGUAGE_LUCENE" "$BEHAVIOUR_JAVA" "behaviour does not use forbidden LANGUAGE_LUCENE"
fi

# ---- service-context.xml ----
SERVICE_CTX=$(find "$GEN" -name "service-context.xml" | head -1)
assert_file_exists "${SERVICE_CTX:-/nonexistent}" "service-context.xml exists"

print_summary "behaviours"
exit_with_status
