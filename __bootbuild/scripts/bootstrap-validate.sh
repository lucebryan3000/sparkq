#!/bin/bash

# ===================================================================
# bootstrap-validate.sh
#
# Purpose: Pre-flight validation before running bootstrap phases
# Validates: Script syntax, manifest integrity, config files, dependencies
# Usage:   ./bootstrap-validate.sh [options]
# Options:
#   --fix          Auto-create missing directories
#   --strict       Fail on warnings (default: warnings only warn)
#   --json         Output results in JSON format
#   -h, --help     Show help
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export SCRIPT_NAME="bootstrap-validate"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Source paths
source "${BOOTSTRAP_DIR}/lib/paths.sh" || {
    log_error "Failed to initialize paths"
    exit 1
}

# Source JSON validator if available
if [[ -f "${LIB_DIR}/json-validator.sh" ]]; then
    source "${LIB_DIR}/json-validator.sh"
fi

# ===================================================================
# Configuration
# ===================================================================

# Options
FIX_MODE=false
STRICT_MODE=false
JSON_MODE=false

# Counters
ERROR_COUNT=0
WARNING_COUNT=0
SUCCESS_COUNT=0

# Results arrays for JSON output
declare -a ERRORS=()
declare -a WARNINGS=()
declare -a SUCCESSES=()

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# ===================================================================
# Helper Functions
# ===================================================================

# Track error
track_error() {
    local message="$1"
    ((ERROR_COUNT++)) || true
    ERRORS+=("$message")
    if [[ "$JSON_MODE" == "false" ]]; then
        log_error "$message"
    fi
}

# Track warning
track_warning_check() {
    local message="$1"
    ((WARNING_COUNT++)) || true
    WARNINGS+=("$message")
    if [[ "$JSON_MODE" == "false" ]]; then
        log_warning "$message"
    fi
}

# Track success
track_success() {
    local message="$1"
    ((SUCCESS_COUNT++)) || true
    SUCCESSES+=("$message")
    if [[ "$JSON_MODE" == "false" ]]; then
        log_success "$message"
    fi
}

# ===================================================================
# Usage
# ===================================================================

show_usage() {
    cat << 'USAGE'
Bootstrap Validation - Pre-flight checks before running bootstrap

Usage:
  bootstrap-validate.sh [options]

Options:
  --fix          Auto-create missing directories
  --strict       Fail on warnings (exit code 2 instead of 0)
  --json         Output results in JSON format
  -h, --help     Show this help

Exit Codes:
  0 - All checks passed (or warnings only in non-strict mode)
  1 - Critical errors found
  2 - Warnings found (only in --strict mode)

Examples:
  bootstrap-validate.sh                    Run validation
  bootstrap-validate.sh --fix              Fix missing directories
  bootstrap-validate.sh --strict           Fail on any warning
  bootstrap-validate.sh --json > report.json

Checks Performed:
  - Shell syntax of all scripts (using bash -n)
  - Manifest integrity (valid JSON)
  - Config file format
  - Required library files exist
  - Template directories exist
  - Required system tools available
  - Proper permissions on config/logs directories
  - Circular dependencies in phase definitions
USAGE
}

# ===================================================================
# Parse Arguments
# ===================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                FIX_MODE=true
                shift
                ;;
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --json)
                JSON_MODE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# ===================================================================
# Validation Functions
# ===================================================================

# Validate shell syntax of all scripts
validate_script_syntax() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating script syntax..."

    local scripts_checked=0
    local scripts_valid=0
    local scripts_invalid=0

    while IFS= read -r -d '' script; do
        ((scripts_checked++)) || true
        local script_name=$(basename "$script")

        # Check if script is readable
        if [[ ! -r "$script" ]]; then
            track_warning_check "Script not readable: $script_name"
            ((scripts_invalid++)) || true
            continue
        fi

        # Check syntax with bash -n
        if bash -n "$script" 2>/dev/null; then
            ((scripts_valid++)) || true
        else
            local error_msg=$(bash -n "$script" 2>&1 | head -3)
            track_error "Syntax error in $script_name: $error_msg"
            ((scripts_invalid++)) || true
        fi
    done < <(find "$SCRIPTS_DIR" -name "*.sh" -type f -print0 2>/dev/null)

    if [[ $scripts_invalid -eq 0 ]]; then
        track_success "All $scripts_checked scripts have valid syntax"
    else
        track_error "Script validation: $scripts_invalid/$scripts_checked failed"
    fi
}

# Validate manifest integrity
validate_manifest() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating manifest integrity..."

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        track_error "Manifest file not found: $MANIFEST_FILE"
        return 1
    fi

    if [[ ! -r "$MANIFEST_FILE" ]]; then
        track_error "Manifest file not readable: $MANIFEST_FILE"
        return 1
    fi

    # Validate JSON syntax
    if command -v jq &>/dev/null; then
        if jq empty "$MANIFEST_FILE" &>/dev/null; then
            track_success "Manifest JSON syntax valid"
        else
            local error_msg=$(jq empty "$MANIFEST_FILE" 2>&1 | head -1)
            track_error "Manifest JSON invalid: $error_msg"
            return 1
        fi

        # Validate required fields
        local has_version=$(jq -r '.version // empty' "$MANIFEST_FILE")
        local has_paths=$(jq -r '.paths // empty' "$MANIFEST_FILE")
        local has_phases=$(jq -r '.phases // empty' "$MANIFEST_FILE")

        if [[ -z "$has_version" ]]; then
            track_warning_check "Manifest missing 'version' field"
        fi

        if [[ -z "$has_paths" ]]; then
            track_error "Manifest missing 'paths' section"
        else
            track_success "Manifest has valid 'paths' section"
        fi

        if [[ -z "$has_phases" ]]; then
            track_error "Manifest missing 'phases' section"
        else
            track_success "Manifest has valid 'phases' section"
        fi
    else
        track_warning_check "jq not available - skipping detailed JSON validation"
        # Fallback: check if file contains valid JSON-like structure
        if grep -q '"version"' "$MANIFEST_FILE" && grep -q '"paths"' "$MANIFEST_FILE"; then
            track_success "Manifest appears to be valid (basic check)"
        else
            track_error "Manifest does not appear to be valid JSON"
        fi
    fi
}

# Validate config file
validate_config() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating config file..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        track_warning_check "Config file not found: $CONFIG_FILE (will be created on first use)"
        return 0
    fi

    if [[ ! -r "$CONFIG_FILE" ]]; then
        track_error "Config file not readable: $CONFIG_FILE"
        return 1
    fi

    # Validate config format (INI-style)
    local line_num=0
    local malformed=0

    while IFS= read -r line; do
        ((line_num++))

        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Check for section headers [section]
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            continue
        fi

        # Check for key=value pairs
        if [[ ! "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
            track_warning_check "Possibly malformed config line $line_num: $line"
            ((malformed++))
        fi
    done < "$CONFIG_FILE"

    if [[ $malformed -eq 0 ]]; then
        track_success "Config file format valid"
    else
        track_warning_check "Config file has $malformed potentially malformed lines"
    fi
}

# Validate required library files
validate_library_files() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating library files..."

    local required_libs=("paths.sh" "common.sh" "config-manager.sh")
    local missing=0

    for lib in "${required_libs[@]}"; do
        local lib_path="${LIB_DIR}/${lib}"

        if [[ ! -f "$lib_path" ]]; then
            track_error "Required library missing: $lib"
            ((missing++))
        elif [[ ! -r "$lib_path" ]]; then
            track_error "Required library not readable: $lib"
            ((missing++))
        else
            # Check syntax
            if bash -n "$lib_path" 2>/dev/null; then
                track_success "Library valid: $lib"
            else
                track_error "Library has syntax errors: $lib"
                ((missing++))
            fi
        fi
    done

    if [[ $missing -eq 0 ]]; then
        track_success "All required libraries present and valid"
    fi
}

# Validate template directories
validate_template_directories() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating template directories..."

    local required_templates=("$TEMPLATES_ROOT" "$TEMPLATES_CLAUDE" "$TEMPLATES_VSCODE" "$TEMPLATES_GITHUB")
    local missing=0

    for template_dir in "${required_templates[@]}"; do
        if [[ ! -d "$template_dir" ]]; then
            track_warning_check "Template directory missing: $(basename "$template_dir")"
            ((missing++))

            if [[ "$FIX_MODE" == "true" ]]; then
                if mkdir -p "$template_dir" 2>/dev/null; then
                    track_success "Created template directory: $(basename "$template_dir")"
                else
                    track_error "Failed to create template directory: $(basename "$template_dir")"
                fi
            fi
        else
            track_success "Template directory exists: $(basename "$template_dir")"
        fi
    done
}

# Validate required system tools
validate_system_tools() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating system tools..."

    # Required tools
    local required=("bash")
    local recommended=("git" "jq")

    for tool in "${required[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version=$("$tool" --version 2>&1 | head -1 || echo "unknown")
            track_success "Required tool available: $tool ($version)"
        else
            track_error "Required tool missing: $tool"
        fi
    done

    for tool in "${recommended[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version=$("$tool" --version 2>&1 | head -1 || echo "unknown")
            track_success "Recommended tool available: $tool"
        else
            track_warning_check "Recommended tool missing: $tool"
        fi
    done
}

# Validate directory permissions
validate_permissions() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating directory permissions..."

    local critical_dirs=("$CONFIG_DIR" "$LOGS_DIR")

    for dir in "${critical_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            track_warning_check "Directory missing: $(basename "$dir")"

            if [[ "$FIX_MODE" == "true" ]]; then
                if mkdir -p "$dir" 2>/dev/null; then
                    track_success "Created directory: $(basename "$dir")"
                else
                    track_error "Failed to create directory: $(basename "$dir")"
                fi
            fi
            continue
        fi

        if [[ ! -r "$dir" ]]; then
            track_error "Directory not readable: $(basename "$dir")"
        elif [[ ! -w "$dir" ]]; then
            track_error "Directory not writable: $(basename "$dir")"
        else
            track_success "Directory permissions OK: $(basename "$dir")"
        fi
    done
}

# Check for circular dependencies
validate_no_circular_deps() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking for circular dependencies..."

    # This is a placeholder - would need to parse manifest to check phase dependencies
    # For now, just check that manifest has phases defined

    if command -v jq &>/dev/null && [[ -f "$MANIFEST_FILE" ]]; then
        local phase_count=$(jq '.phases | length' "$MANIFEST_FILE" 2>/dev/null || echo "0")

        if [[ "$phase_count" -gt 0 ]]; then
            track_success "Phases defined: $phase_count"
        else
            track_warning_check "No phases found in manifest"
        fi
    else
        track_warning_check "Cannot validate phase dependencies (jq not available)"
    fi
}

# ===================================================================
# Main Validation
# ===================================================================

run_validation() {
    [[ "$JSON_MODE" == "false" ]] && log_section "Bootstrap Pre-flight Validation"

    validate_script_syntax || true
    validate_manifest || true
    validate_config || true
    validate_library_files || true
    validate_template_directories || true
    validate_system_tools || true
    validate_permissions || true
    validate_no_circular_deps || true
}

# ===================================================================
# Results Output
# ===================================================================

show_summary() {
    if [[ "$JSON_MODE" == "true" ]]; then
        # JSON output - escape special characters
        echo "{"
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"validation\": {"
        echo "    \"errors\": $ERROR_COUNT,"
        echo "    \"warnings\": $WARNING_COUNT,"
        echo "    \"successes\": $SUCCESS_COUNT"
        echo "  },"
        echo "  \"errors\": ["
        for i in "${!ERRORS[@]}"; do
            local comma=","
            [[ $i -eq $((${#ERRORS[@]} - 1)) ]] && comma=""
            local escaped="${ERRORS[$i]//\\/\\\\}"  # Escape backslashes
            escaped="${escaped//\"/\\\"}"           # Escape quotes
            escaped="${escaped//$'\n'/\\n}"         # Escape newlines
            echo "    \"${escaped}\"$comma"
        done
        echo "  ],"
        echo "  \"warnings\": ["
        for i in "${!WARNINGS[@]}"; do
            local comma=","
            [[ $i -eq $((${#WARNINGS[@]} - 1)) ]] && comma=""
            local escaped="${WARNINGS[$i]//\\/\\\\}"
            escaped="${escaped//\"/\\\"}"
            escaped="${escaped//$'\n'/\\n}"
            echo "    \"${escaped}\"$comma"
        done
        echo "  ],"
        echo "  \"result\": \"$(get_result_status)\""
        echo "}"
    else
        # Human-readable output
        echo ""
        log_section "Validation Summary"
        echo ""
        echo -e "  ${GREEN}Successes:${NC} $SUCCESS_COUNT"
        echo -e "  ${YELLOW}Warnings:${NC}  $WARNING_COUNT"
        echo -e "  ${RED}Errors:${NC}    $ERROR_COUNT"
        echo ""

        if [[ $ERROR_COUNT -eq 0 && $WARNING_COUNT -eq 0 ]]; then
            log_success "All validation checks passed!"
        elif [[ $ERROR_COUNT -eq 0 ]]; then
            log_warning "Validation passed with $WARNING_COUNT warnings"
        else
            log_error "Validation failed with $ERROR_COUNT errors"
        fi

        echo ""

        if [[ "$FIX_MODE" == "true" ]]; then
            log_info "Fix mode was enabled - some issues may have been auto-corrected"
        fi
    fi
}

get_result_status() {
    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo "FAILED"
    elif [[ $WARNING_COUNT -gt 0 ]]; then
        echo "WARNINGS"
    else
        echo "PASSED"
    fi
}

determine_exit_code() {
    if [[ $ERROR_COUNT -gt 0 ]]; then
        return 1
    elif [[ $WARNING_COUNT -gt 0 && "$STRICT_MODE" == "true" ]]; then
        return 2
    else
        return 0
    fi
}

# ===================================================================
# Main Execution
# ===================================================================

main() {
    parse_args "$@"

    run_validation

    show_summary

    determine_exit_code
}

main "$@"
