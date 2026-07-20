#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
COMMANDS_DIR="$ROOT_DIR/commands"
AGENTS_FILE="$ROOT_DIR/AGENTS.md"

usage() {
    cat <<EOF
Usage:
  $(basename "$0") list
  $(basename "$0") render [--agent codex|openclaw|generic|cursor] <command> [arguments...]

Examples:
  $(basename "$0") list
  $(basename "$0") render --agent codex scaffold
  $(basename "$0") render --agent openclaw requirements "We need to classify contracts"
  $(basename "$0") render --agent cursor scaffold
EOF
}

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

strip_front_matter() {
    local file="$1"

    awk '
        NR == 1 && $0 == "---" {
            in_front_matter = 1
            next
        }
        in_front_matter && $0 == "---" {
            in_front_matter = 0
            next
        }
        !in_front_matter {
            print
        }
    ' "$file"
}

command_file_for() {
    local command_name="$1"
    printf '%s/%s.md' "$COMMANDS_DIR" "$command_name"
}

normalize_command_name() {
    local command_name="$1"
    command_name="${command_name#/}"
    printf '%s' "$command_name"
}

validate_agent() {
    case "$1" in
        codex|openclaw|generic|cursor)
            ;;
        *)
            fail "unsupported agent '$1' (expected: codex, openclaw, generic, cursor)"
            ;;
    esac
}

list_commands() {
    local file
    while IFS= read -r file; do
        local name description
        name=$(basename "$file" .md)
        description=$(awk -F'"' '/^description:/ { print $2; exit }' "$file")
        printf '/%-16s %s\n' "$name" "$description"
    done < <(find "$COMMANDS_DIR" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort)
}

render_agent_preamble() {
    local agent="$1"

    case "$agent" in
        codex)
            cat <<EOF
You are Codex working directly in this repository.
Follow the repository rules in AGENTS.md before doing anything else.
Implement the command by editing files when the command requires generated output; do not stop at a summary.
If REQUIREMENTS.md declares both Platform JAR and Event Handler projects, keep them as separate sibling modules/deployables and write files under the Section 2 Root path for each project.
EOF
            ;;
        openclaw)
            cat <<EOF
You are OpenClaw working directly in this repository.
Follow the repository rules in AGENTS.md before doing anything else.
Implement the command by editing files when the command requires generated output; do not stop at a summary.
If REQUIREMENTS.md declares both Platform JAR and Event Handler projects, keep them as separate sibling modules/deployables and write files under the Section 2 Root path for each project.
EOF
            ;;
        generic)
            cat <<EOF
You are an AI coding agent working directly in this repository.
Follow the repository rules in AGENTS.md before doing anything else.
Implement the command by editing files when the command requires generated output; do not stop at a summary.
If REQUIREMENTS.md declares both Platform JAR and Event Handler projects, keep them as separate sibling modules/deployables and write files under the Section 2 Root path for each project.
EOF
            ;;
        cursor)
            cat <<EOF
You are the Cursor AI agent working in this repository workspace.
Follow the repository rules in AGENTS.md before doing anything else.
Attach or read context using Cursor @ references (for example @AGENTS.md and @commands/<command>.md) when helpful.
Implement the command by editing files when the command requires generated output; do not stop at a summary.
If REQUIREMENTS.md declares both Platform JAR and Event Handler projects, keep them as separate sibling modules/deployables and write files under the Section 2 Root path for each project.
EOF
            ;;
    esac
}

render_prompt() {
    local agent="$1"
    local command_name="$2"
    shift 2

    local command_file arguments
    command_file=$(command_file_for "$command_name")

    [ -f "$command_file" ] || fail "unknown command '$command_name'"

    if [ "$#" -gt 0 ]; then
        arguments="$*"
    else
        arguments="none"
    fi

    render_agent_preamble "$agent"
    cat <<EOF

Repository root: $ROOT_DIR
Repository rules: $AGENTS_FILE
AIUP command spec: $command_file

Execution rules:
1. Read AGENTS.md and follow it strictly.
2. Use commands/$command_name.md as the source of truth for the AIUP command '/$command_name'.
3. Ignore Claude-only YAML front matter except as metadata hints; the Markdown body is the portable command specification.
4. If the command references a skill, open the corresponding file under $ROOT_DIR/skills/ and apply it manually.
5. If the command references an agent, use the corresponding file under $ROOT_DIR/agents/ as guidance.
6. Ask the user only for values that cannot be derived safely from repository context or prior outputs.
7. Report what you changed and any validation you ran.

User arguments:
$arguments

Begin by reading:
- $AGENTS_FILE
- $command_file

Portable command specification:

EOF
    strip_front_matter "$command_file"
}

main() {
    [ $# -gt 0 ] || {
        usage
        exit 1
    }

    local action="$1"
    shift

    case "$action" in
        list)
            [ $# -eq 0 ] || fail "'list' does not accept additional arguments"
            list_commands
            ;;
        render)
            local agent="generic"
            if [ $# -gt 0 ] && [ "$1" = "--agent" ]; then
                [ $# -ge 2 ] || fail "missing value for --agent"
                agent="$2"
                shift 2
            fi

            validate_agent "$agent"

            [ $# -ge 1 ] || fail "missing command name"

            local command_name
            command_name=$(normalize_command_name "$1")
            shift

            render_prompt "$agent" "$command_name" "$@"
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            fail "unknown action '$action'"
            ;;
    esac
}

main "$@"
