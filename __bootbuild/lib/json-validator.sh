#!/bin/bash

# ===================================================================
# json-validator.sh
#
# JSON syntax validation utility
# Can be used standalone or sourced by other scripts
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_JSON_VALIDATOR_LOADED:-}" ]] && return 0
_BOOTSTRAP_JSON_VALIDATOR_LOADED=1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===================================================================
# JSON Validation Functions
# ===================================================================

# Check if jq is available
has_jq() {
    command -v jq &>/dev/null
}

# Validate single JSON file
# Usage: validate_json_file "/path/to/file.json"
# Returns: 0 if valid, 1 if invalid
validate_json_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file"
        return 1
    fi

    if ! has_jq; then
        echo -e "${YELLOW}⚠${NC} jq not installed - skipping validation for $(basename "$file")"
        return 0
    fi

    # Try to parse with jq
    if jq empty "$file" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Valid JSON: $(basename "$file")"
        return 0
    else
        echo -e "${RED}✗${NC} Invalid JSON syntax: $(basename "$file")"
        echo -e "${YELLOW}→${NC} Running jq for details:"
        jq empty "$file" 2>&1 | head -5
        return 1
    fi
}

# Validate all JSON files in directory
# Usage: validate_json_in_dir "/path/to/dir"
validate_json_in_dir() {
    local dir="$1"
    local files_found=0
    local files_valid=0
    local files_invalid=0

    echo -e "${BLUE}→${NC} Validating JSON files in: $dir"
    echo ""

    while IFS= read -r -d '' file; do
        ((files_found++))
        if validate_json_file "$file"; then
            ((files_valid++))
        else
            ((files_invalid++))
        fi
    done < <(find "$dir" -name "*.json" -type f -print0)

    echo ""
    echo "Summary:"
    echo "  Found: $files_found"
    echo "  Valid: $files_valid"
    echo "  Invalid: $files_invalid"

    [[ $files_invalid -eq 0 ]]
}

# Validate multiple files
# Usage: validate_json_files "file1.json" "file2.json" ...
validate_json_files() {
    local files=("$@")
    local valid=0
    local invalid=0

    for file in "${files[@]}"; do
        if validate_json_file "$file"; then
            ((valid++))
        else
            ((invalid++))
        fi
    done

    echo ""
    echo "Summary: $valid valid, $invalid invalid"

    [[ $invalid -eq 0 ]]
}

# Check if file has valid JSON (silent, for scripting)
# Usage: is_valid_json "/path/to/file.json" && echo "valid"
is_valid_json() {
    local file="$1"
    has_jq && jq empty "$file" &>/dev/null
}

# Pretty-print JSON file
# Usage: pretty_print_json "/path/to/file.json"
pretty_print_json() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file"
        return 1
    fi

    if ! has_jq; then
        echo -e "${YELLOW}⚠${NC} jq not installed - cannot pretty-print"
        cat "$file"
        return 0
    fi

    jq '.' "$file"
}

# ===================================================================
# Standalone Usage
# ===================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly, not sourced

    show_usage() {
        cat << 'USAGE'
JSON Validator - Validate JSON syntax

Usage:
  json-validator.sh <file.json>                  Validate single file
  json-validator.sh file1.json file2.json ...    Validate multiple files
  json-validator.sh --dir <directory>            Validate all JSON in directory
  json-validator.sh --help                       Show this help

Examples:
  json-validator.sh tsconfig.json
  json-validator.sh .codex.json tsconfig.json
  json-validator.sh --dir /project/config

Requirements:
  - jq (install with: sudo apt install jq or brew install jq)
USAGE
    }

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --dir|-d)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Error: --dir requires a directory argument"
                exit 1
            fi
            validate_json_in_dir "$2"
            exit $?
            ;;
        *)
            # Validate files provided as arguments
            validate_json_files "$@"
            exit $?
            ;;
    esac
fi
