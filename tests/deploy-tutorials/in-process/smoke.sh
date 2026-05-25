#!/usr/bin/env bash
# Smoke tests for the in-process (Platform JAR) deployment.
# Run after ACS is healthy.
#
# Usage: smoke.sh <acs-base-url>
# Default: http://localhost:8080

set -euo pipefail

BASE="${1:-http://localhost:8080}"
PASS=0
FAIL=0

check() {
    local label="$1"
    local url="$2"
    local expected_status="${3:-200}"
    local extra_args="${4:-}"

    http_status=$(curl -s -o /dev/null -w "%{http_code}" \
        -u admin:admin \
        $extra_args \
        "$url" 2>/dev/null) || http_status="000"

    if [[ "$http_status" == "$expected_status" ]]; then
        printf '  PASS  %s (HTTP %s)\n' "$label" "$http_status"
        PASS=$((PASS+1))
    else
        printf '  FAIL  %s — expected HTTP %s, got %s\n' "$label" "$expected_status" "$http_status"
        FAIL=$((FAIL+1))
    fi
}

printf '\n=== in-process smoke tests ===\n'

# ACS readiness
check "ACS ready probe" \
    "$BASE/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-"

# Custom web script registered and reachable
check "custom web script GET /api/sc/ping" \
    "$BASE/alfresco/s/api/sc/ping"

# Content model loaded — confirm sc:doc type exists in dictionary
check "content model type sc:doc registered" \
    "$BASE/alfresco/api/-default-/public/alfresco/versions/1/types/sc:doc"

printf '\n  in-process: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
