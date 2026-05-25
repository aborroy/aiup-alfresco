#!/usr/bin/env bash
# Smoke tests for the ACA extension deployment.
# Run after the content-app container is healthy.
#
# Usage: smoke.sh <aca-base-url>
# Default: http://localhost:4200

set -euo pipefail

ACA_BASE="${1:-http://localhost:4200}"
PASS=0
FAIL=0

printf '\n=== aca-extension smoke tests ===\n'

# ACA root returns HTTP 200
http_status=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    "$ACA_BASE/" 2>/dev/null) || http_status="000"

if [[ "$http_status" == "200" ]]; then
    printf '  PASS  ACA root / returns HTTP %s\n' "$http_status"
    PASS=$((PASS+1))
else
    printf '  FAIL  ACA root / returned HTTP %s\n' "$http_status"
    FAIL=$((FAIL+1))
fi

# Plugin JSON asset is served
plugin_status=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    "$ACA_BASE/assets/plugins/ext-deploy-test.plugin.json" 2>/dev/null) || plugin_status="000"

if [[ "$plugin_status" == "200" ]]; then
    printf '  PASS  extension plugin JSON served (HTTP %s)\n' "$plugin_status"
    PASS=$((PASS+1))
else
    printf '  FAIL  extension plugin JSON not served (HTTP %s)\n' "$plugin_status"
    FAIL=$((FAIL+1))
fi

printf '\n  aca-extension: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
