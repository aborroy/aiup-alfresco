#!/usr/bin/env bash
# Install the AIUP Cursor pack into a consumer Alfresco project workspace root.
#
# Run from the consumer project root (e.g. project-repo/):
#   ./tools/aiup-alfresco/scripts/install-cursor-pack.sh
#
# Or with a custom submodule path:
#   ./tools/aiup-alfresco/scripts/install-cursor-pack.sh --aiup-path vendor/aiup-alfresco

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AIUP_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CONSUMER_ROOT=$(CDPATH= cd -- "$PWD" && pwd)
AIUP_REL="tools/aiup-alfresco"

usage() {
    cat <<EOF
Usage:
  $(basename "$0") [--aiup-path <relative-path>]

Installs AIUP Cursor rules, hooks, and slash-command skills into the current
project directory (consumer workspace root).

Options:
  --aiup-path <path>  Relative path from consumer root to aiup-alfresco checkout
                      (default: tools/aiup-alfresco)

Example (from consumer project root):
  ./tools/aiup-alfresco/scripts/install-cursor-pack.sh
EOF
}

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

copy_if_missing() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ]; then
        printf '  skip (exists): %s\n' "$dest"
    else
        mkdir -p "$(dirname "$dest")"
        cp -r "$src" "$dest"
        printf '  installed: %s\n' "$dest"
    fi
}

copy_executable_if_missing() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ]; then
        printf '  skip (exists): %s\n' "$dest"
    else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        chmod +x "$dest"
        printf '  installed: %s\n' "$dest"
    fi
}

copy_executable() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    chmod +x "$dest"
    printf '  installed: %s\n' "$dest"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --aiup-path)
            [ $# -ge 2 ] || fail "--aiup-path requires a value"
            AIUP_REL="${2%/}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "unknown argument: $1 (try --help)"
            ;;
    esac
done

AIUP_PATH="$CONSUMER_ROOT/$AIUP_REL"

# Resolve aiup-alfresco root: prefer consumer submodule path, fall back to script location
if [ -f "$AIUP_PATH/scripts/build-cursor-skills.sh" ]; then
    AIUP_ROOT="$AIUP_PATH"
elif [ ! -f "$AIUP_ROOT/scripts/build-cursor-skills.sh" ]; then
    fail "cannot find aiup-alfresco at $AIUP_PATH or $AIUP_ROOT"
fi

# Ensure trailing slash for prefix used in generated skill paths
AIUP_PREFIX="$AIUP_REL/"
if [ "$AIUP_ROOT" = "$CONSUMER_ROOT" ]; then
    AIUP_PREFIX=""
fi

printf 'Installing AIUP Cursor pack\n'
printf '  consumer root: %s\n' "$CONSUMER_ROOT"
printf '  aiup root:     %s\n' "$AIUP_ROOT"
printf '  aiup prefix:   %s\n' "${AIUP_PREFIX:-<repo root>}"

mkdir -p "$CONSUMER_ROOT/.cursor/rules" "$CONSUMER_ROOT/.cursor/hooks"

printf '\nRules and hooks:\n'
copy_if_missing "$AIUP_ROOT/.cursor/rules/aiup-alfresco.mdc" \
    "$CONSUMER_ROOT/.cursor/rules/aiup-alfresco.mdc"
copy_if_missing "$AIUP_ROOT/.cursor/hooks.json" \
    "$CONSUMER_ROOT/.cursor/hooks.json"

for hook in "$AIUP_ROOT/.cursor/hooks/"*.sh; do
    [ -f "$hook" ] || continue
    dest="$CONSUMER_ROOT/.cursor/hooks/$(basename "$hook")"
    copy_executable_if_missing "$hook" "$dest"
done

printf '\nTraceability hook dependency:\n'
mkdir -p "$CONSUMER_ROOT/scripts"
copy_executable "$AIUP_ROOT/scripts/traceability-artefacts.sh" \
    "$CONSUMER_ROOT/scripts/traceability-artefacts.sh"

printf '\nGenerating slash-command skills:\n'
"$AIUP_ROOT/scripts/build-cursor-skills.sh" \
    --aiup-prefix "$AIUP_PREFIX" \
    --output "$CONSUMER_ROOT/.cursor/skills" \
    --merge

skill_count=$(find "$CONSUMER_ROOT/.cursor/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
printf '\nDone. %s skill directories in %s/.cursor/skills/\n' "$skill_count" "$CONSUMER_ROOT"

cat <<EOF

Next steps:
  1. Open this project as the Cursor workspace root (not only the submodule).
  2. Confirm Rules and Hooks are enabled in Cursor settings.
  3. Add a local version override rule if your ACS/SDK versions differ from AGENTS.md.
  4. In Agent chat, type /requirements or /scaffold to start the AIUP workflow.
  5. Re-run this script after 'git submodule update' to refresh skills and
     scripts/traceability-artefacts.sh (traceability hook dependency).
  6. Existing .cursor/hooks/*.sh files are preserved on re-run; delete a hook and
     re-run to adopt an upstream version, or copy manually from the aiup-alfresco checkout.

See CURSOR-INTEGRATION-GUIDE.md in the aiup-alfresco checkout for full details.
EOF
