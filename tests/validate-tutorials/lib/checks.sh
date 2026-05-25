#!/usr/bin/env bash
# Shared assertion helpers for scenario checker scripts.
# Source this file; call assert_* functions.
# Each function increments PASS_COUNT or FAIL_COUNT and prints a result line.
#
# NOTE: every $() that runs grep/xmllint appends || true so that set -euo pipefail
# in the caller does not abort the script when the search finds nothing.

PASS_COUNT=0
FAIL_COUNT=0

_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  PASS  %s\n' "$1"
}

_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL  %s\n' "$1"
    if [[ -n "${2:-}" ]]; then
        printf '        -> %s\n' "$2"
    fi
}

# assert_file_exists <file> [label]
assert_file_exists() {
    local file="$1"
    local label="${2:-file exists: $(basename "$file")}"
    if [[ -f "$file" ]]; then
        _pass "$label"
    else
        _fail "$label" "not found: $file"
    fi
}

# assert_dir_has_file_matching <dir> <glob> [label]
assert_dir_has_file_matching() {
    local dir="$1"
    local pattern="$2"
    local label="${3:-at least one $pattern in $dir}"
    local found
    found=$(find "$dir" -name "$pattern" 2>/dev/null | head -1) || true
    if [[ -n "$found" ]]; then
        _pass "$label"
    else
        _fail "$label" "no file matching $pattern under $dir"
    fi
}

# assert_grep <pattern> <file> [label]
assert_grep() {
    local pattern="$1"
    local file="$2"
    local label="${3:-contains '$pattern': $(basename "$file")}"
    if [[ ! -f "$file" ]]; then
        _fail "$label" "file not found: $file"
        return
    fi
    if grep -q "$pattern" "$file" 2>/dev/null; then
        _pass "$label"
    else
        _fail "$label" "pattern '$pattern' not found in $file"
    fi
}

# assert_grep_in_dir <pattern> <dir> <glob> [label]
assert_grep_in_dir() {
    local pattern="$1"
    local dir="$2"
    local glob="$3"
    local label="${4:-all $glob in $dir contain '$pattern'}"
    local files
    files=$(find "$dir" -name "$glob" 2>/dev/null) || true
    if [[ -z "$files" ]]; then
        _fail "$label" "no $glob files found under $dir"
        return
    fi
    local failed=0
    while IFS= read -r f; do
        if ! grep -q "$pattern" "$f" 2>/dev/null; then
            _fail "$label" "missing '$pattern' in $f"
            failed=1
        fi
    done <<< "$files"
    if [[ $failed -eq 0 ]]; then
        _pass "$label"
    fi
}

# assert_not_grep <pattern> <dir_or_file> [label]
# Searches recursively if dir, single file otherwise.
assert_not_grep() {
    local pattern="$1"
    local target="$2"
    local label="${3:-does not contain forbidden '$pattern'}"
    local hit
    if [[ -d "$target" ]]; then
        hit=$(grep -r "$pattern" "$target" 2>/dev/null | head -1) || true
    else
        hit=$(grep "$pattern" "$target" 2>/dev/null | head -1) || true
    fi
    if [[ -z "$hit" ]]; then
        _pass "$label"
    else
        _fail "$label" "forbidden pattern '$pattern' found: $hit"
    fi
}

# assert_xml_wellformed <file> [label]
assert_xml_wellformed() {
    local file="$1"
    local label="${2:-well-formed XML: $(basename "$file")}"
    if [[ ! -f "$file" ]]; then
        _fail "$label" "file not found: $file"
        return
    fi
    if xmllint --noout "$file" 2>/dev/null; then
        _pass "$label"
    else
        _fail "$label" "xmllint reported errors in $file"
    fi
}

# assert_xml_wellformed_dir <dir> <glob> [label]
assert_xml_wellformed_dir() {
    local dir="$1"
    local glob="$2"
    local label="${3:-all $glob under $dir are well-formed XML}"
    local files
    files=$(find "$dir" -name "$glob" 2>/dev/null) || true
    if [[ -z "$files" ]]; then
        _fail "$label" "no $glob files found under $dir"
        return
    fi
    local failed=0
    while IFS= read -r f; do
        if ! xmllint --noout "$f" 2>/dev/null; then
            _fail "$label" "xmllint errors in $f"
            failed=1
        fi
    done <<< "$files"
    if [[ $failed -eq 0 ]]; then
        _pass "$label"
    fi
}

# assert_grep_any_file <pattern> <dir> <glob> [label]
# Passes if at least ONE file matching the glob contains the pattern.
assert_grep_any_file() {
    local pattern="$1"
    local dir="$2"
    local glob="$3"
    local label="${4:-at least one $glob contains '$pattern'}"
    local hit
    hit=$(find "$dir" -name "$glob" 2>/dev/null -exec grep -l "$pattern" {} \; | head -1) || true
    if [[ -n "$hit" ]]; then
        _pass "$label"
    else
        _fail "$label" "no $glob under $dir contains '$pattern'"
    fi
}

# print_summary <scenario>
print_summary() {
    local scenario="$1"
    local total=$((PASS_COUNT + FAIL_COUNT))
    printf '\n  %s: %d/%d checks passed\n' "$scenario" "$PASS_COUNT" "$total"
    return 0
}

# exit_with_status — call at the end of every checker script.
exit_with_status() {
    if [[ $FAIL_COUNT -gt 0 ]]; then
        exit 1
    fi
    exit 0
}
