#!/usr/bin/env bash
# Checker: aca-extension
# Usage: aca-extension.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== aca-extension ===\n'

# ---- Plugin manifest ----
PLUGIN_JSON=$(find "$GEN" -name "*.plugin.json" | head -1) || true
assert_file_exists "${PLUGIN_JSON:-/nonexistent}" "*.plugin.json manifest exists"
if [[ -n "$PLUGIN_JSON" ]]; then
    assert_grep '"routes"'      "$PLUGIN_JSON" "plugin.json declares routes"
    assert_grep '"navbar"'      "$PLUGIN_JSON" "plugin.json declares navbar entry"
    assert_grep '"contextMenu"' "$PLUGIN_JSON" "plugin.json declares contextMenu entry"
    assert_grep '"toolbar"'     "$PLUGIN_JSON" "plugin.json declares toolbar entry"
    assert_grep '"sidebar"'     "$PLUGIN_JSON" "plugin.json declares sidebar tab"
    assert_grep '"actions"'     "$PLUGIN_JSON" "plugin.json declares actions"
    assert_grep '"auth"'        "$PLUGIN_JSON" "plugin.json route has auth guard"
fi

# ---- Module / providers function ----
MODULE_TS=$(find "$GEN" -name "*.module.ts" | head -1) || true
assert_file_exists "${MODULE_TS:-/nonexistent}" "*.module.ts exists"
if [[ -n "$MODULE_TS" ]]; then
    assert_grep "provideExtensionConfig"    "$MODULE_TS" "module uses provideExtensionConfig()"
    assert_grep "APP_INITIALIZER"           "$MODULE_TS" "module registers APP_INITIALIZER"
    assert_grep "ExtensionService"          "$MODULE_TS" "module depends on ExtensionService"
    assert_grep "setComponents"             "$MODULE_TS" "module registers components with setComponents()"
    assert_grep "provideEffects"            "$MODULE_TS" "module registers NgRx effects"
    assert_grep "export function provide"   "$MODULE_TS" "module exports a provideXxx() function"
    assert_grep "@NgModule"                 "$MODULE_TS" "module exports @NgModule compat shim"
fi

# ---- NgRx actions ----
ACTIONS_TS=$(find "$GEN" -name "*.actions.ts" | head -1) || true
assert_file_exists "${ACTIONS_TS:-/nonexistent}" "*.actions.ts exists"
if [[ -n "$ACTIONS_TS" ]]; then
    assert_grep "export const" "$ACTIONS_TS" "actions file exports action type constants"
fi

# ---- NgRx effects ----
EFFECTS_TS=$(find "$GEN" -name "*.effects.ts" | head -1) || true
assert_file_exists "${EFFECTS_TS:-/nonexistent}" "*.effects.ts exists"
if [[ -n "$EFFECTS_TS" ]]; then
    assert_grep "createEffect"  "$EFFECTS_TS" "effects file uses createEffect()"
    assert_grep "dispatch: false" "$EFFECTS_TS" "effects are non-dispatching"
    assert_grep "ofType"        "$EFFECTS_TS" "effects use ofType() filter"
fi

# ---- Angular service ----
SERVICE_TS=$(find "$GEN" -name "*.service.ts" | grep -v spec | head -1) || true
assert_file_exists "${SERVICE_TS:-/nonexistent}" "*.service.ts exists"
if [[ -n "$SERVICE_TS" ]]; then
    assert_grep "AppConfigService" "$SERVICE_TS" \
        "service reads config via AppConfigService (no hardcoded URLs)"
    assert_grep "Injectable"       "$SERVICE_TS" "service is @Injectable"
    assert_not_grep "http://\|https://" "$SERVICE_TS" \
        "service does not hardcode URLs"
fi

# ---- Page component ----
PAGE_TS=$(find "$GEN" -name "*.component.ts" | xargs grep -l "page\|Page" 2>/dev/null | head -1) || true
assert_file_exists "${PAGE_TS:-/nonexistent}" "page component exists"
if [[ -n "$PAGE_TS" ]]; then
    assert_grep "standalone: true" "$PAGE_TS" "page component is standalone"
    assert_not_grep "declarations\|NgModule" "$PAGE_TS" \
        "page component not declared in NgModule"
fi

# ---- Sidebar component ----
SIDEBAR_TS=$(find "$GEN" -name "*.component.ts" | xargs grep -l "sidebar\|Sidebar" 2>/dev/null | head -1) || true
assert_file_exists "${SIDEBAR_TS:-/nonexistent}" "sidebar component exists"
if [[ -n "$SIDEBAR_TS" ]]; then
    assert_grep "standalone: true" "$SIDEBAR_TS" "sidebar component is standalone"
fi

# ---- public-api.ts ----
PUBLIC_API=$(find "$GEN" -name "public-api.ts" | head -1) || true
assert_file_exists "${PUBLIC_API:-/nonexistent}" "public-api.ts exists"
if [[ -n "$PUBLIC_API" ]]; then
    assert_grep "provide" "$PUBLIC_API" "public-api exports provideXxx() function"
fi

print_summary "aca-extension"
exit_with_status
