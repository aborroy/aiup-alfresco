#!/usr/bin/env bash
# Regenerate .cursor/skills/ from skills/, agents/, and commands/.
# Source files under skills/ keep Claude Code frontmatter; Cursor copies use name + description only.
#
# Usage:
#   ./scripts/build-cursor-skills.sh
#   ./scripts/build-cursor-skills.sh --aiup-prefix tools/aiup-alfresco/ --output /path/to/.cursor/skills

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
COMMANDS_DIR="$ROOT_DIR/commands"

AIUP_PREFIX=""
CURSOR_SKILLS="$ROOT_DIR/.cursor/skills"
MERGE=false

usage() {
    cat <<EOF
Usage:
  $(basename "$0") [--aiup-prefix <path>] [--output <dir>] [--merge]

Options:
  --aiup-prefix <path>  Prefix for AGENTS.md and commands/ paths in command skills
                        (default: empty — paths relative to aiup-alfresco repo root)
  --output <dir>        Destination skills directory (default: .cursor/skills in repo root)
  --merge               Update only AIUP-managed skills; preserve other skill directories

Examples:
  $(basename "$0")
  $(basename "$0") --aiup-prefix tools/aiup-alfresco/ --output /path/to/project-repo/.cursor/skills --merge
EOF
}

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --aiup-prefix)
            [ $# -ge 2 ] || fail "--aiup-prefix requires a value"
            AIUP_PREFIX="$2"
            shift 2
            ;;
        --output)
            [ $# -ge 2 ] || fail "--output requires a value"
            CURSOR_SKILLS="$2"
            shift 2
            ;;
        --merge)
            MERGE=true
            shift
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

strip_claude_frontmatter() {
    awk '
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { in_fm = 0; next }
        !in_fm { print }
    ' "$1"
}

extract_yaml_field() {
    local file="$1"
    local field="$2"
    awk -v field="$field" '
        /^---$/ { if (++block == 1) next; if (block == 2) exit }
        block == 1 && $0 ~ "^" field ":" {
            sub("^" field ":[[:space:]]*", "")
            gsub(/^"/, "")
            gsub(/"$/, "")
            print
            exit
        }
    ' "$file"
}

write_cursor_skill() {
    local name="$1"
    local description="$2"
    local body_file="$3"
    local dest="$CURSOR_SKILLS/$name"

    mkdir -p "$dest"
    {
        echo "---"
        echo "name: $name"
        echo "description: $description"
        echo "---"
        echo ""
        strip_claude_frontmatter "$body_file"
    } > "$dest/SKILL.md"
}

write_command_skill() {
    local cmd="$1"
    local description="$2"
    local dest="$CURSOR_SKILLS/$cmd"

    mkdir -p "$dest"
    {
        echo "---"
        echo "name: $cmd"
        echo "description: $description"
        echo "disable-model-invocation: true"
        echo "---"
        echo ""
        echo "# AIUP command: $cmd"
        echo ""
        echo "1. Read \`${AIUP_PREFIX}AGENTS.md\`."
        echo "2. Execute the full procedure in \`${AIUP_PREFIX}commands/${cmd}.md\`."
        echo "3. Apply referenced validator skills under \`.cursor/skills/\` when the command mentions them."
        echo "4. Create or update real files unless the user asked for a plan only."
        echo ""
        echo "Treat any user text after \`/${cmd}\` as \`\$ARGUMENTS\` from the command spec."
    } > "$dest/SKILL.md"
}

collect_managed_skill_names() {
    for skill_dir in "$ROOT_DIR/skills"/*/; do
        [ -f "${skill_dir}SKILL.md" ] || continue
        basename "$skill_dir"
    done
    for agent_file in "$ROOT_DIR/agents"/*.md; do
        [ -f "$agent_file" ] || continue
        name=$(extract_yaml_field "$agent_file" "name")
        [ -n "$name" ] || name=$(basename "$agent_file" .md)
        printf '%s\n' "$name"
    done
    while IFS= read -r file; do
        basename "$file" .md
    done < <(find "$COMMANDS_DIR" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort)
    printf '%s\n' "aiup-alfresco"
}

if [ "$MERGE" = true ]; then
    mkdir -p "$CURSOR_SKILLS"
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        rm -rf "$CURSOR_SKILLS/$name"
    done < <(collect_managed_skill_names)
else
    rm -rf "$CURSOR_SKILLS"
    mkdir -p "$CURSOR_SKILLS"
fi

# --- Validator / helper skills (from skills/) ---
for skill_dir in "$ROOT_DIR/skills"/*/; do
    [ -f "${skill_dir}SKILL.md" ] || continue
    name=$(basename "$skill_dir")
    description=$(extract_yaml_field "${skill_dir}SKILL.md" "description")
    [ -n "$description" ] || description="AIUP Alfresco skill: $name"
    write_cursor_skill "$name" "$description" "${skill_dir}SKILL.md"
done

# --- Deep-guidance agents (from agents/) ---
for agent_file in "$ROOT_DIR/agents"/*.md; do
    [ -f "$agent_file" ] || continue
    name=$(extract_yaml_field "$agent_file" "name")
    [ -n "$name" ] || name=$(basename "$agent_file" .md)
    description=$(extract_yaml_field "$agent_file" "description")
    [ -n "$description" ] || description="AIUP Alfresco agent guidance: $name"
    write_cursor_skill "$name" "$description" "$agent_file"
done

# --- Command slash skills (from commands/) ---
while IFS= read -r file; do
    cmd=$(basename "$file" .md)
    desc=$(extract_yaml_field "$file" "description")
    [ -n "$desc" ] || desc="AIUP Alfresco command: $cmd"
    write_command_skill "$cmd" "$desc"
done < <(find "$COMMANDS_DIR" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort)

# --- Orchestrator skill (commands index) ---
ORCH="$CURSOR_SKILLS/aiup-alfresco/SKILL.md"
mkdir -p "$(dirname "$ORCH")"

{
    echo "---"
    echo "name: aiup-alfresco"
    echo "description: Runs AIUP Alfresco extension workflow steps (requirements, scaffold, content-model, web-scripts, docker-compose, test, and more). Use when the user asks to execute an AIUP command or develop Alfresco extensions following AGENTS.md."
    echo "---"
    echo ""
    echo "# AIUP Alfresco — command orchestrator"
    echo ""
    echo "Invoke any AIUP step with \`/<command>\` in Agent chat (Cursor 2.4+), or open \`${AIUP_PREFIX}commands/<name>.md\` directly."
    echo ""
    echo "## Before any step"
    echo ""
    echo "1. Read \`${AIUP_PREFIX}AGENTS.md\`."
    echo "2. Open \`${AIUP_PREFIX}commands/<name>.md\` for the requested step (or type \`/<name>\`)."
    echo "3. Apply referenced skills under \`.cursor/skills/\` when the command mentions them."
    echo "4. Create or update real files; do not stop at a summary unless the user asked for a plan only."
    echo ""
    echo "## Available commands"
    echo ""
    echo "| Slash command | Description |"
    echo "|---------------|-------------|"
} > "$ORCH"

while IFS= read -r file; do
    cmd=$(basename "$file" .md)
    desc=$(extract_yaml_field "$file" "description")
    printf '| `/%s` | %s |\n' "$cmd" "$desc" >> "$ORCH"
done < <(find "$COMMANDS_DIR" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort)

render_script="./scripts/aiup-command.sh"
if [ -n "$AIUP_PREFIX" ]; then
    render_script="${AIUP_PREFIX}scripts/aiup-command.sh"
fi

{
    echo ""
    echo "## Typical order"
    echo ""
    echo "1. \`/requirements\` — architecture decision + REQUIREMENTS.md"
    echo "2. \`/scaffold\` — project skeleton (requires REQUIREMENTS.md)"
    echo "3. Feature commands as needed, for example:"
    echo "   - Platform JAR: \`/content-model\`, \`/behaviours\`, \`/web-scripts\`, \`/rest-api\`, \`/actions\`, \`/workflow\`, \`/scheduled-jobs\`, \`/bootstrap-loader\`, \`/rule-conditions\`, \`/repository-patch\`, \`/permissions\`, \`/audit\`, \`/content-store\`, \`/metadata-extractor\`, \`/subsystem\`, \`/transforms\`"
    echo "   - Out-of-process: \`/events\`"
    echo "   - Share JAR: \`/share-config\`, \`/surf\`, \`/aikau\`"
    echo "   - ACA/ADW: \`/aca-extension\`"
    echo "4. \`/docker-compose\` — before integration tests"
    echo "5. \`/test\` — last"
    echo ""
    echo "## Rendered prompt (optional)"
    echo ""
    echo "\`\`\`bash"
    echo "${render_script} render --agent cursor <command> [args...]"
    echo "\`\`\`"
    echo ""
    echo "See \`CURSOR.md\` for hooks, @ references, and troubleshooting."
} >> "$ORCH"

skill_dirs=$(find "$CURSOR_SKILLS" -mindepth 1 -maxdepth 1 -type d | wc -l)
cmd_count=$(find "$COMMANDS_DIR" -maxdepth 1 -type f -name '*.md' | wc -l)
orch_count=$(grep -c '^| `/' "$ORCH" || true)
command_skill_count=$(find "$CURSOR_SKILLS" -mindepth 1 -maxdepth 1 -type d \
    -exec test -f '{}/SKILL.md' \; -print | while read -r d; do
        name=$(basename "$d")
        if [ -f "$COMMANDS_DIR/${name}.md" ]; then echo "$name"; fi
    done | wc -l)

if [ "$cmd_count" -ne "$orch_count" ]; then
    printf 'Error: orchestrator lists %s commands but commands/ has %s\n' "$orch_count" "$cmd_count" >&2
    exit 1
fi

if [ "$cmd_count" -ne "$command_skill_count" ]; then
    printf 'Error: generated %s command skills but commands/ has %s\n' "$command_skill_count" "$cmd_count" >&2
    exit 1
fi

printf 'Generated %s Cursor skills (%s command slash skills, prefix="%s") in %s\n' \
    "$skill_dirs" "$command_skill_count" "$AIUP_PREFIX" "$CURSOR_SKILLS"
