#!/usr/bin/env bash
# Checker: share-config (Share form configuration)
# Usage: share-config.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== share-config ===\n'

# ---- share-config-custom.xml ----
SHARE_CFG=$(find "$GEN" -name "share-config-custom.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${SHARE_CFG:-/nonexistent}" "share-config-custom.xml exists"
if [[ -n "$SHARE_CFG" ]]; then
    assert_xml_wellformed "$SHARE_CFG" "share-config-custom.xml is well-formed XML"
    assert_grep "<alfresco-config" "$SHARE_CFG" "uses <alfresco-config> root"
    assert_grep "evaluator=" "$SHARE_CFG" "declares at least one config evaluator"
    assert_grep "<forms>\|<form" "$SHARE_CFG" "declares form configuration"
    if grep -qE '<action[^>]*label-id=' "$SHARE_CFG" 2>/dev/null; then
        _fail "DocLib <action> uses label=, not label-id" "found label-id on <action>"
    else
        _pass "DocLib <action> elements do not use label-id"
    fi
fi

# ---- share-config-custom.xml location ----
META_INF_FILE=$(find "$GEN" -path "*/META-INF/share-config-custom.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${META_INF_FILE:-/nonexistent}" \
    "share-config-custom.xml lives under META-INF/"

# ---- Share-tier boundary: nothing under alfresco/module ----
assert_not_grep "alfresco/module" "$GEN" \
    "no Share files under alfresco/module (Share tier only)"

# ---- Message bundle ----
assert_dir_has_file_matching "$GEN" "*.properties" \
    "a Share message bundle .properties exists"

print_summary "share-config"
exit_with_status
