#!/usr/bin/env bash
# Smoke tests for the out-of-process (Spring Boot event handler) deployment.
# Run after ACS + event handler are healthy.
#
# Usage: smoke.sh <acs-base-url> <event-handler-base-url>
# Defaults: http://localhost:8080  http://localhost:9090

set -euo pipefail

ACS_BASE="${1:-http://localhost:8080}"
HANDLER_BASE="${2:-http://localhost:9090}"
PASS=0
FAIL=0

check() {
    local label="$1"
    local url="$2"
    local expected_status="${3:-200}"
    local auth_args="${4:-}"

    http_status=$(curl -s -o /dev/null -w "%{http_code}" \
        $auth_args \
        "$url" 2>/dev/null) || http_status="000"

    if [[ "$http_status" == "$expected_status" ]]; then
        printf '  PASS  %s (HTTP %s)\n' "$label" "$http_status"
        PASS=$((PASS+1))
    else
        printf '  FAIL  %s — expected HTTP %s, got %s\n' "$label" "$expected_status" "$http_status"
        FAIL=$((FAIL+1))
    fi
}

check_json() {
    local label="$1"
    local url="$2"
    local jq_filter="$3"
    local expected="$4"
    local auth_args="${5:-}"

    actual=$(curl -s $auth_args "$url" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # simple dotted key traversal
    keys = '$jq_filter'.lstrip('.').split('.')
    v = d
    for k in keys:
        v = v[k]
    print(str(v))
except Exception as e:
    print('ERROR: ' + str(e))
" 2>/dev/null) || actual="ERROR"

    if [[ "$actual" == "$expected" ]]; then
        printf '  PASS  %s (%s=%s)\n' "$label" "$jq_filter" "$expected"
        PASS=$((PASS+1))
    else
        printf '  FAIL  %s — expected %s=%s, got %s\n' "$label" "$jq_filter" "$expected" "$actual"
        FAIL=$((FAIL+1))
    fi
}

printf '\n=== out-of-process smoke tests ===\n'

# ACS readiness
check "ACS ready probe" \
    "$ACS_BASE/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" \
    "200" "-u admin:admin"

# Event handler Actuator health
check_json "event handler health status UP" \
    "$HANDLER_BASE/actuator/health" \
    ".status" \
    "UP"

# Confirm event handler is reachable (any 2xx)
check "event handler actuator endpoint reachable" \
    "$HANDLER_BASE/actuator/health"

printf '\n  out-of-process: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
