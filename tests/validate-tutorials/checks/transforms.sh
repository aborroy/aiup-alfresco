#!/usr/bin/env bash
# Checker: transforms
# Usage: transforms.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== transforms ===\n'

# ---- Common checks (Platform JAR) ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" \
    "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_PROPS=$(find "$GEN" -name "module.properties" | head -1)
if [[ -n "$MODULE_PROPS" ]]; then
    assert_grep "module.id"      "$MODULE_PROPS" "module.properties has module.id"
    assert_grep "module.version" "$MODULE_PROPS" "module.properties has module.version"
else
    _fail "module.properties exists" "not found under $GEN"
fi

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1)
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Rendition context XML ----
RENDITION_CTX=$(find "$GEN" -name "rendition-context.xml" | head -1) || true
assert_file_exists "${RENDITION_CTX:-/nonexistent}" "rendition-context.xml exists"
if [[ -n "$RENDITION_CTX" ]]; then
    assert_xml_wellformed "$RENDITION_CTX" "rendition-context.xml is well-formed XML"
    assert_grep "RenditionDefinition2Impl" "$RENDITION_CTX" \
        "rendition-context.xml uses RenditionDefinition2Impl"
    assert_grep "renditionDefinitionRegistry2" "$RENDITION_CTX" \
        "rendition-context.xml references renditionDefinitionRegistry2"
    assert_grep "timeout" "$RENDITION_CTX" \
        "rendition definition includes timeout option"
    assert_not_grep "RenditionDefinition[^2]" "$RENDITION_CTX" \
        "rendition-context.xml does not use deprecated RenditionDefinition (v1)"
fi

# ---- module-context.xml imports rendition-context ----
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "rendition-context" "$MODULE_CTX" \
        "module-context.xml imports rendition-context.xml"
fi

# ---- MIME type registration ----
MIME_XML=$(find "$GEN" -name "mimetypes-extension-map.xml" | head -1) || true
assert_file_exists "${MIME_XML:-/nonexistent}" "mimetypes-extension-map.xml exists"
if [[ -n "$MIME_XML" ]]; then
    assert_xml_wellformed "$MIME_XML" "mimetypes-extension-map.xml is well-formed XML"
    assert_grep "mimetype-map" "$MIME_XML" \
        "mimetypes-extension-map.xml uses mimetype-map area"
    assert_grep "<mimetype " "$MIME_XML" \
        "mimetypes-extension-map.xml declares at least one mimetype"
    assert_not_grep "<bean " "$MIME_XML" \
        "mimetypes-extension-map.xml does not use Spring beans (wrong format)"
fi

# ---- Custom engine project ----
ENGINE_POM=$(find "$GEN" -name "pom.xml" | xargs grep -l "alfresco-transform-core" 2>/dev/null | head -1) || true
assert_file_exists "${ENGINE_POM:-/nonexistent}" "custom engine pom.xml with alfresco-transform-core parent exists"

ENGINE_DIR=$(dirname "${ENGINE_POM:-/nonexistent}") 2>/dev/null || ENGINE_DIR=""
if [[ -n "$ENGINE_POM" && -d "$ENGINE_DIR" ]]; then
    # TransformEngine implementation
    ENGINE_JAVA=$(find "$ENGINE_DIR" -name "*Engine.java" | head -1) || true
    assert_file_exists "${ENGINE_JAVA:-/nonexistent}" "TransformEngine implementation class exists"
    [[ -n "$ENGINE_JAVA" ]] && assert_grep "TransformEngine" "$ENGINE_JAVA" \
        "engine class implements TransformEngine"
    [[ -n "$ENGINE_JAVA" ]] && assert_grep "getTransformEngineName\|getTransformConfig\|getProbeTransform" "$ENGINE_JAVA" \
        "engine class implements required TransformEngine methods"

    # CustomTransformer implementation
    TRANSFORMER_JAVA=$(find "$ENGINE_DIR" -name "*Transformer.java" | head -1) || true
    assert_file_exists "${TRANSFORMER_JAVA:-/nonexistent}" "CustomTransformer implementation class exists"
    [[ -n "$TRANSFORMER_JAVA" ]] && assert_grep "CustomTransformer" "$TRANSFORMER_JAVA" \
        "transformer class implements CustomTransformer"
    [[ -n "$TRANSFORMER_JAVA" ]] && assert_grep "getTransformerName\|transform(" "$TRANSFORMER_JAVA" \
        "transformer class implements required CustomTransformer methods"

    # Engine config JSON
    ENGINE_CONFIG=$(find "$ENGINE_DIR" -name "*engine_config.json" | head -1) || true
    assert_file_exists "${ENGINE_CONFIG:-/nonexistent}" "*engine_config.json exists"
    if [[ -n "$ENGINE_CONFIG" ]]; then
        assert_grep "transformerName" "$ENGINE_CONFIG" \
            "engine_config.json declares transformerName"
        assert_grep "sourceMediaType" "$ENGINE_CONFIG" \
            "engine_config.json declares sourceMediaType"
        assert_grep "targetMediaType" "$ENGINE_CONFIG" \
            "engine_config.json declares targetMediaType"
    fi

    # Dockerfile
    DOCKERFILE=$(find "$ENGINE_DIR" -name "Dockerfile" | head -1) || true
    assert_file_exists "${DOCKERFILE:-/nonexistent}" "custom engine Dockerfile exists"
    [[ -n "$DOCKERFILE" ]] && assert_grep "eclipse-temurin\|openjdk\|java" "$DOCKERFILE" \
        "Dockerfile uses a JRE base image"
    [[ -n "$DOCKERFILE" ]] && assert_grep "EXPOSE\|8090\|8080" "$DOCKERFILE" \
        "Dockerfile exposes a port"
fi

print_summary "transforms"
exit_with_status
