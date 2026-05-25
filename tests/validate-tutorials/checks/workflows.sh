#!/usr/bin/env bash
# Checker: workflows
# Usage: workflows.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== workflows ===\n'

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

# ---- Model XML (content model or workflow model) ----
CONTENT_MODEL=$(find "$GEN" -name "content-model.xml" | head -1)
WORKFLOW_MODEL=$(find "$GEN" -name "*workflow-model.xml" | head -1)
SOME_MODEL="${CONTENT_MODEL:-$WORKFLOW_MODEL}"
assert_file_exists "${SOME_MODEL:-/nonexistent}" "at least one model XML exists"
[[ -n "$SOME_MODEL" ]] && assert_not_grep 'enforced="true"' "$SOME_MODEL" "model XML has no enforced=true"

MODEL_JAVA=$(find "$GEN" -name "*Model.java" | head -1)
assert_file_exists "${MODEL_JAVA:-/nonexistent}" "*Model.java constants interface exists"

# ---- BPMN process file ----
BPMN=$(find "$GEN" \( -name "*.bpmn" -o -name "*.bpmn20.xml" \) | head -1)
assert_file_exists "${BPMN:-/nonexistent}" "*.bpmn process definition file exists"

if [[ -n "$BPMN" ]]; then
    assert_xml_wellformed "$BPMN" "BPMN file is well-formed XML"
    assert_grep 'xmlns:activiti="http://activiti.org/bpmn"' "$BPMN" "BPMN has activiti namespace"
    assert_grep 'isExecutable="true"' "$BPMN" "BPMN process is executable"
    assert_not_grep 'org.flowable' "$BPMN" "BPMN has no forbidden org.flowable references"
    assert_not_grep 'redeploy">true' "$BPMN" "BPMN has no redeploy=true (forbidden)"
fi

# ---- Workflow task content model ----
assert_file_exists "${WORKFLOW_MODEL:-/nonexistent}" "*-workflow-model.xml exists"

if [[ -n "$WORKFLOW_MODEL" ]]; then
    assert_xml_wellformed "$WORKFLOW_MODEL" "workflow model is well-formed XML"
    assert_grep 'http://www.alfresco.org/model/bpm/1.0' "$WORKFLOW_MODEL" "workflow model imports bpm namespace"
fi

# ---- bootstrap-context.xml uses workflowDeployer ----
BOOTSTRAP_CTX=$(find "$GEN" -name "bootstrap-context.xml" | head -1)
assert_file_exists "${BOOTSTRAP_CTX:-/nonexistent}" "bootstrap-context.xml exists"

if [[ -n "$BOOTSTRAP_CTX" ]]; then
    assert_grep 'workflowDeployer' "$BOOTSTRAP_CTX" "bootstrap-context.xml uses workflowDeployer parent for BPMN"
    assert_not_grep 'redeploy">true' "$BOOTSTRAP_CTX" "bootstrap-context.xml does not set redeploy=true"
fi

# ---- i18n message bundle ----
MESSAGES=$(find "$GEN" -name "*Workflow.properties" | head -1)
assert_file_exists "${MESSAGES:-/nonexistent}" "*Workflow.properties i18n bundle exists"

print_summary "workflows"
exit_with_status
