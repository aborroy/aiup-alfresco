#!/usr/bin/env bash
# Smoke tests for the transforms deployment.
# Run after ACS + transform-router + custom engine are healthy.
#
# Usage: smoke.sh <transform-router-base-url>
# Default: http://localhost:8095

set -euo pipefail

ROUTER_BASE="${1:-http://localhost:8095}"
ENGINE_NAME="${2:-scPing}"
PASS=0
FAIL=0

printf '\n=== transforms smoke tests ===\n'

# Transform router config endpoint lists the custom engine
config_response=$(curl -s "$ROUTER_BASE/transform/config" 2>/dev/null) || config_response=""

if echo "$config_response" | grep -qi "$ENGINE_NAME"; then
    printf '  PASS  transform-router /transform/config lists engine "%s"\n' "$ENGINE_NAME"
    PASS=$((PASS+1))
else
    printf '  FAIL  engine "%s" not found in transform-router config\n' "$ENGINE_NAME"
    printf '        response: %s\n' "$(echo "$config_response" | head -c 300)"
    FAIL=$((FAIL+1))
fi

# Transform router is reachable
http_status=$(curl -s -o /dev/null -w "%{http_code}" "$ROUTER_BASE/transform/config" 2>/dev/null) || http_status="000"
if [[ "$http_status" == "200" ]]; then
    printf '  PASS  transform-router /transform/config returns HTTP 200\n'
    PASS=$((PASS+1))
else
    printf '  FAIL  transform-router returned HTTP %s\n' "$http_status"
    FAIL=$((FAIL+1))
fi

printf '\n  transforms: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
