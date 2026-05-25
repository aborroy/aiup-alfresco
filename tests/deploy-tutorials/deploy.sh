#!/usr/bin/env bash
# Build, deploy, smoke-test, and tear down a single deploy-tutorial scenario.
#
# Usage:
#   deploy.sh <scenario> [--no-teardown]
#
# Scenarios: in-process | out-of-process | transforms | aca-extension
#
# --no-teardown: leave the stack running after smoke tests (useful for debugging)
#
# Prerequisites: docker, docker compose, maven (for in-process/transforms/out-of-process)
#
# Environment:
#   DEPLOY_TIMEOUT   seconds to wait for healthy services (default: 300)
#   MAVEN_OPTS       passed through to mvn

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GENERATED_BASE="$SCRIPT_DIR/generated"
TIMEOUT="${DEPLOY_TIMEOUT:-300}"

usage() {
    printf 'Usage: %s <scenario> [--no-teardown]\n' "$(basename "$0")"
    printf 'Scenarios: in-process out-of-process transforms aca-extension\n'
}

[[ $# -lt 1 ]] && { usage >&2; exit 1; }

SCENARIO="$1"
NO_TEARDOWN="${2:-}"
GEN_DIR="$GENERATED_BASE/$SCENARIO"
SMOKE_SCRIPT="$SCRIPT_DIR/$SCENARIO/smoke.sh"

[[ -d "$GEN_DIR" ]] || { printf 'ERROR: generated dir not found: %s\n' "$GEN_DIR"; exit 1; }
[[ -f "$SMOKE_SCRIPT" ]] || { printf 'ERROR: smoke script not found: %s\n' "$SMOKE_SCRIPT"; exit 1; }

# ACA extension uses a static compose.yaml in the scenario dir (not generated)
if [[ "$SCENARIO" == "aca-extension" ]]; then
    COMPOSE_FILE="$SCRIPT_DIR/$SCENARIO/compose.yaml"
else
    COMPOSE_FILE=$(find "$GEN_DIR" -maxdepth 2 -name "compose.yaml" | head -1) || true
    [[ -n "$COMPOSE_FILE" ]] || { printf 'ERROR: compose.yaml not found under %s\n' "$GEN_DIR"; exit 1; }
fi
COMPOSE_DIR=$(dirname "$COMPOSE_FILE")

teardown() {
    if [[ "$NO_TEARDOWN" != "--no-teardown" ]]; then
        printf '\n[%s] Tearing down...\n' "$SCENARIO"
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
    else
        printf '\n[%s] --no-teardown: stack left running at %s\n' "$SCENARIO" "$COMPOSE_DIR"
    fi
}

# ---- Build step ----
build_scenario() {
    case "$SCENARIO" in
        in-process)
            printf '[%s] Building Maven project...\n' "$SCENARIO"
            (cd "$COMPOSE_DIR" && mvn clean package -q -DskipTests)
            ;;
        out-of-process)
            printf '[%s] Building Maven project...\n' "$SCENARIO"
            # -Dlicense.skip=true: alfresco-java-sdk parent enforces Apache 2.0 headers;
            # generated files omit headers for brevity — skip in deploy tests.
            (cd "$COMPOSE_DIR" && mvn clean package -q -DskipTests -Dlicense.skip=true)
            ;;
        transforms)
            printf '[%s] Building Maven project...\n' "$SCENARIO"
            (cd "$COMPOSE_DIR" && mvn clean package -q -DskipTests)
            printf '[%s] Building custom engine Docker image...\n' "$SCENARIO"
            ENGINE_DIR=$(find "$COMPOSE_DIR" -maxdepth 2 -name "Dockerfile" | head -1 | xargs dirname)
            if [[ -n "$ENGINE_DIR" ]]; then
                ENGINE_NAME=$(basename "$ENGINE_DIR")
                docker build -t "$ENGINE_NAME:latest" "$ENGINE_DIR"
            fi
            ;;
        aca-extension)
            printf '[%s] Building ACA Docker image (clones ACA + patches + Angular build)...\n' "$SCENARIO"
            printf '[%s] This step takes ~10 minutes on first run.\n' "$SCENARIO"
            # Docker build is triggered by compose — no separate mvn step
            ;;
    esac
}

# ---- Wait for service health ----
wait_healthy() {
    local service="$1"
    local url="$2"
    local auth="${3:-}"
    local elapsed=0
    local interval=15

    printf '[%s] Waiting for %s to be healthy...\n' "$SCENARIO" "$service"
    while [[ $elapsed -lt $TIMEOUT ]]; do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            $auth --max-time 10 "$url" 2>/dev/null) || http_code="000"
        if [[ "$http_code" =~ ^2 ]]; then
            printf '[%s] %s is healthy (HTTP %s, elapsed %ds)\n' "$SCENARIO" "$service" "$http_code" "$elapsed"
            return 0
        fi
        printf '[%s] %s not ready yet (HTTP %s), retrying in %ds...\n' "$SCENARIO" "$service" "$http_code" "$interval"
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    printf '[%s] ERROR: %s did not become healthy within %ds\n' "$SCENARIO" "$service" "$TIMEOUT"
    docker compose -f "$COMPOSE_FILE" logs --tail=50 2>/dev/null || true
    return 1
}

# ---- Scenario-specific wait logic ----
wait_for_services() {
    case "$SCENARIO" in
        in-process)
            wait_healthy "ACS" \
                "http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" \
                "-u admin:admin"
            ;;
        out-of-process)
            wait_healthy "ACS" \
                "http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" \
                "-u admin:admin"
            wait_healthy "event-handler" \
                "http://localhost:9090/actuator/health"
            ;;
        transforms)
            wait_healthy "ACS" \
                "http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" \
                "-u admin:admin"
            wait_healthy "transform-router" \
                "http://localhost:8095/transform/config"
            ;;
        aca-extension)
            wait_healthy "content-app" \
                "http://localhost:4200/"
            ;;
    esac
}

# ---- Main ----
printf '\n=== DEPLOY TEST: %s ===\n' "$SCENARIO"

trap teardown EXIT

# 1. Build
build_scenario

# 2. Start stack
printf '[%s] Starting Docker Compose stack...\n' "$SCENARIO"
docker compose -f "$COMPOSE_FILE" up -d --build 2>&1 | tail -5

# 3. Wait for health
wait_for_services

# 4. Run smoke tests
printf '\n[%s] Running smoke tests...\n' "$SCENARIO"
chmod +x "$SMOKE_SCRIPT"
if bash "$SMOKE_SCRIPT"; then
    printf '\n[%s] PASSED\n' "$SCENARIO"
    exit 0
else
    printf '\n[%s] FAILED — collecting logs...\n' "$SCENARIO"
    docker compose -f "$COMPOSE_FILE" logs --tail=100 2>/dev/null | tail -50 || true
    exit 1
fi
