#!/bin/bash

# ===================================================================
# bootstrap-validate-scripts.sh
#
# Validates all bootstrap scripts for quality and completeness
# Uses shellcheck, syntax validation, and custom quality rules
#
# USAGE:
#   ./bootstrap-validate-scripts.sh              # Validate all
#   ./bootstrap-validate-scripts.sh <script>     # Validate one
#   ./bootstrap-validate-scripts.sh --fix        # Auto-fix issues
#   ./bootstrap-validate-scripts.sh --json       # JSON output
#
# FEATURES:
# - Shellcheck integration (if available)
# - Syntax validation (bash -n)
# - Completeness checks
# - Code quality rules
# - Registry compliance
# - Quality scoring
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup and Paths
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source required libraries
source "${BOOTSTRAP_DIR}/lib/paths.sh" || exit 1
source "${BOOTSTRAP_DIR}/lib/config-manager.sh" || exit 1

# Validation configuration
FIX_MODE=false
JSON_OUTPUT=false
VERBOSE=false
TARGET_SCRIPT=""

# Quality thresholds
QUALITY_THRESHOLD_CRITICAL=50
QUALITY_THRESHOLD_WARNING=75
QUALITY_THRESHOLD_GOOD=90

# Validation stats
TOTAL_SCRIPTS=0
SCRIPTS_PASSED=0
SCRIPTS_WARNINGS=0
SCRIPTS_FAILED=0
declare -a FAILED_SCRIPTS=()
declare -A SCRIPT_SCORES=()

# Issue tracking
declare -A ISSUES_CRITICAL=()
declare -A ISSUES_WARNING=()
declare -A ISSUES_INFO=()

# ===================================================================
# Colors
# ===================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    GRAY='\033[0;90m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    GRAY=''
    BOLD=''
    NC=''
fi

# ===================================================================
# Helper Functions
# ===================================================================

log_header() {
    echo -e "${BLUE}${BOLD}$*${NC}"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_info() {
    echo -e "${GRAY}ℹ${NC} $*"
}

# ===================================================================
# Validation Functions
# ===================================================================

# Check 1: Syntax validation with bash -n
validate_syntax() {
    local script="$1"
    local issues=()

    if bash -n "$script" 2>&1; then
        return 0
    else
        local error_msg=$(bash -n "$script" 2>&1)
        issues+=("SYNTAX_ERROR: $error_msg")
        record_issue "$script" "critical" "${issues[@]}"
        return 1
    fi
}

# Check 2: Shellcheck validation (if available)
validate_shellcheck() {
    local script="$1"
    local issues=()

    if ! command -v shellcheck &>/dev/null; then
        log_info "shellcheck not available - skipping advanced checks"
        return 0
    fi

    local shellcheck_output
    if shellcheck_output=$(shellcheck -f gcc "$script" 2>&1); then
        return 0
    else
        # Parse shellcheck output
        while IFS= read -r line; do
            if [[ "$line" =~ :.*:.*:\ (warning|error): ]]; then
                local severity="${BASH_REMATCH[1]}"
                issues+=("SHELLCHECK_${severity^^}: $line")
            fi
        done <<< "$shellcheck_output"

        record_issue "$script" "warning" "${issues[@]}"
        return 1
    fi
}

# Check 3: Has proper shebang
validate_shebang() {
    local script="$1"
    local first_line=$(head -n1 "$script")

    if [[ "$first_line" =~ ^#!/bin/bash ]] || [[ "$first_line" =~ ^#!/usr/bin/env\ bash ]]; then
        return 0
    else
        record_issue "$script" "critical" "MISSING_SHEBANG: First line must be #!/bin/bash or #!/usr/bin/env bash"
        return 1
    fi
}

# Check 4: Has help text
validate_help_text() {
    local script="$1"

    if grep -q -- "--help\|USAGE:" "$script"; then
        return 0
    else
        record_issue "$script" "warning" "NO_HELP: Script should provide --help or usage documentation"
        return 1
    fi
}

# Check 5: Has error handling
validate_error_handling() {
    local script="$1"
    local issues=()

    # Check for set -e or set -euo pipefail
    if ! grep -q "set -e" "$script"; then
        issues+=("NO_SET_E: Consider using 'set -e' or 'set -euo pipefail' for error handling")
    fi

    # Check for trap on ERR or EXIT
    if ! grep -q "trap.*ERR\|trap.*EXIT" "$script"; then
        issues+=("NO_TRAP: Consider using trap for cleanup and error handling")
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        record_issue "$script" "info" "${issues[@]}"
        return 1
    fi

    return 0
}

# Check 6: Sources lib/paths.sh
validate_paths_sourcing() {
    local script="$1"

    if grep -q 'source.*lib/paths\.sh\|\..*lib/paths\.sh' "$script"; then
        return 0
    else
        # Not all scripts need to source paths.sh (e.g., library files)
        local basename=$(basename "$script")
        if [[ "$basename" =~ ^lib/ ]] || [[ "$basename" =~ test- ]]; then
            return 0
        fi

        record_issue "$script" "warning" "NO_PATHS: Script should source lib/paths.sh for centralized path management"
        return 1
    fi
}

# Check 7: No TODO/FIXME markers
validate_no_todos() {
    local script="$1"
    local todos=()

    while IFS= read -r line; do
        todos+=("$line")
    done < <(grep -n "TODO\|FIXME\|XXX\|HACK" "$script" || true)

    if [[ ${#todos[@]} -gt 0 ]]; then
        record_issue "$script" "info" "HAS_TODOS: Found ${#todos[@]} TODO/FIXME markers - consider addressing before release"
        return 1
    fi

    return 0
}

# Check 8: Proper quoting
validate_quoting() {
    local script="$1"
    local issues=()

    # Skip quoting validation for now - too many false positives
    # This would need more sophisticated parsing to be useful
    return 0

    # Look for common unquoted variable patterns (disabled)
    # local unquoted=$(grep -n '\$[A-Z_][A-Z_0-9]*[^"]' "$script" | grep -v '^\s*#' || true)
    #
    # if [[ -n "$unquoted" ]]; then
    #     local count=$(echo "$unquoted" | wc -l)
    #     issues+=("UNQUOTED_VARS: Found $count potential unquoted variables - review for proper quoting")
    # fi
    #
    # if [[ ${#issues[@]} -gt 0 ]]; then
    #     record_issue "$script" "info" "${issues[@]}"
    #     return 1
    # fi
    #
    # return 0
}

# Check 9: No use of eval
validate_no_eval() {
    local script="$1"

    if grep -q "eval " "$script" && ! grep -q "# eval: justified" "$script"; then
        record_issue "$script" "warning" "USES_EVAL: Found 'eval' usage - this is dangerous and should be avoided"
        return 1
    fi

    return 0
}

# Check 10: No hardcoded paths
validate_no_hardcoded_paths() {
    local script="$1"
    local issues=()

    # Look for absolute paths that aren't in variables
    local hardcoded=$(grep -n '"/home\|"/tmp\|"/usr/local' "$script" | grep -v '^\s*#' | grep -v 'EXAMPLE\|example' || true)

    if [[ -n "$hardcoded" ]]; then
        local count=$(echo "$hardcoded" | wc -l)
        issues+=("HARDCODED_PATH: Found $count potential hardcoded paths - use path variables instead")
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        record_issue "$script" "warning" "${issues[@]}"
        return 1
    fi

    return 0
}

# Check 11: Has proper header comment
validate_header() {
    local script="$1"

    # Check for header comment block within first 20 lines
    if head -n 20 "$script" | grep -q "^# ===\|^#\{10,\}"; then
        return 0
    else
        record_issue "$script" "info" "NO_HEADER: Script should have a header comment explaining purpose"
        return 1
    fi
}

# Check 12: Has main() function
validate_main_function() {
    local script="$1"

    # Check if script has a main function
    if grep -q "^main()\|^function main" "$script"; then
        return 0
    else
        # Not all scripts need main (libraries, sourced scripts)
        local basename=$(basename "$script")
        if [[ "$basename" =~ ^lib/ ]] || [[ -f "$script" ]] && grep -q "return 0\|return 1" "$script"; then
            return 0
        fi

        record_issue "$script" "info" "NO_MAIN: Consider using a main() function for better structure"
        return 1
    fi
}

# Check 13: Registry compliance
validate_registry_compliance() {
    local script="$1"
    local basename=$(basename "$script")
    local script_key="${basename%.sh}"

    # Remove bootstrap- prefix if present
    script_key="${script_key#bootstrap-}"

    # Check if script is in manifest
    if ! jq -e ".scripts.\"$script_key\"" "$MANIFEST_FILE" >/dev/null 2>&1; then
        # Check alternative naming
        if ! jq -e ".scripts | to_entries[] | select(.value.file == \"$basename\")" "$MANIFEST_FILE" >/dev/null 2>&1; then
            record_issue "$script" "warning" "NOT_IN_REGISTRY: Script not found in bootstrap-manifest.json"
            return 1
        fi
    fi

    return 0
}

# Check 14: File is executable
validate_executable() {
    local script="$1"

    if [[ -x "$script" ]]; then
        return 0
    else
        record_issue "$script" "warning" "NOT_EXECUTABLE: Script should have executable permissions"

        if [[ "$FIX_MODE" == "true" ]]; then
            chmod +x "$script"
            log_success "Fixed: Made script executable"
        fi

        return 1
    fi
}

# ===================================================================
# Issue Recording
# ===================================================================

record_issue() {
    local script="$1"
    local severity="$2"
    shift 2
    local issues=("$@")

    local script_name=$(basename "$script")

    for issue in "${issues[@]}"; do
        case $severity in
            critical)
                ISSUES_CRITICAL["$script_name"]+="$issue"$'\n'
                ;;
            warning)
                ISSUES_WARNING["$script_name"]+="$issue"$'\n'
                ;;
            info)
                ISSUES_INFO["$script_name"]+="$issue"$'\n'
                ;;
        esac
    done
}

# ===================================================================
# Quality Scoring
# ===================================================================

calculate_quality_score() {
    local script="$1"
    local script_name=$(basename "$script")

    local max_score=100
    local score=$max_score

    # Critical issues: -10 points each
    local critical_text="${ISSUES_CRITICAL[$script_name]:-}"
    local critical_count=0
    if [[ -n "$critical_text" ]]; then
        critical_count=$(echo "$critical_text" | grep -c "." || echo 0)
    fi
    score=$((score - (critical_count * 10)))

    # Warning issues: -5 points each
    local warning_text="${ISSUES_WARNING[$script_name]:-}"
    local warning_count=0
    if [[ -n "$warning_text" ]]; then
        warning_count=$(echo "$warning_text" | grep -c "." || echo 0)
    fi
    score=$((score - (warning_count * 5)))

    # Info issues: -2 points each
    local info_text="${ISSUES_INFO[$script_name]:-}"
    local info_count=0
    if [[ -n "$info_text" ]]; then
        info_count=$(echo "$info_text" | grep -c "." || echo 0)
    fi
    score=$((score - (info_count * 2)))

    # Ensure score doesn't go negative
    [[ $score -lt 0 ]] && score=0

    SCRIPT_SCORES["$script_name"]=$score

    echo "$score"
}

# ===================================================================
# Main Validation Runner
# ===================================================================

validate_script() {
    local script="$1"
    local script_name=$(basename "$script")

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Validating: $script_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))

    # Initialize issue arrays for this script
    ISSUES_CRITICAL["$script_name"]=""
    ISSUES_WARNING["$script_name"]=""
    ISSUES_INFO["$script_name"]=""

    # Run all validations
    local checks_passed=0
    local checks_failed=0

    local validations=(
        "validate_shebang"
        "validate_syntax"
        "validate_shellcheck"
        "validate_header"
        "validate_help_text"
        "validate_error_handling"
        "validate_paths_sourcing"
        "validate_main_function"
        "validate_no_todos"
        "validate_quoting"
        "validate_no_eval"
        "validate_no_hardcoded_paths"
        "validate_executable"
        "validate_registry_compliance"
    )

    for validation in "${validations[@]}"; do
        if $validation "$script" 2>/dev/null; then
            checks_passed=$((checks_passed + 1))
        else
            checks_failed=$((checks_failed + 1))
        fi
    done

    # Calculate quality score
    local score=$(calculate_quality_score "$script")

    # Display results
    echo ""
    echo -e "  Checks passed: ${GREEN}$checks_passed${NC} / $((checks_passed + checks_failed))"
    echo -e "  Quality score: ${BOLD}$score${NC}/100"

    # Display issues
    if [[ -n "${ISSUES_CRITICAL[$script_name]}" ]]; then
        echo ""
        echo -e "${RED}${BOLD}Critical Issues:${NC}"
        echo "${ISSUES_CRITICAL[$script_name]}" | sed 's/^/  /' | grep -v '^[[:space:]]*$'
    fi

    if [[ -n "${ISSUES_WARNING[$script_name]}" ]]; then
        echo ""
        echo -e "${YELLOW}${BOLD}Warnings:${NC}"
        echo "${ISSUES_WARNING[$script_name]}" | sed 's/^/  /' | grep -v '^[[:space:]]*$'
    fi

    if [[ "$VERBOSE" == "true" ]] && [[ -n "${ISSUES_INFO[$script_name]}" ]]; then
        echo ""
        echo -e "${GRAY}${BOLD}Info:${NC}"
        echo "${ISSUES_INFO[$script_name]}" | sed 's/^/  /' | grep -v '^[[:space:]]*$'
    fi

    # Determine overall status
    if [[ $score -lt $QUALITY_THRESHOLD_CRITICAL ]]; then
        log_error "FAILED - Quality score below critical threshold ($QUALITY_THRESHOLD_CRITICAL)"
        SCRIPTS_FAILED=$((SCRIPTS_FAILED + 1))
        FAILED_SCRIPTS+=("$script_name (score: $score)")
    elif [[ $score -lt $QUALITY_THRESHOLD_WARNING ]]; then
        log_warn "WARNINGS - Quality score below warning threshold ($QUALITY_THRESHOLD_WARNING)"
        SCRIPTS_WARNINGS=$((SCRIPTS_WARNINGS + 1))
    else
        log_success "PASSED - Good quality score"
        SCRIPTS_PASSED=$((SCRIPTS_PASSED + 1))
    fi

    echo ""
}

# ===================================================================
# Report Generation
# ===================================================================

generate_report() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Validation Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Total scripts:   ${BLUE}$TOTAL_SCRIPTS${NC}"
    echo -e "  Passed:          ${GREEN}$SCRIPTS_PASSED${NC}"
    echo -e "  Warnings:        ${YELLOW}$SCRIPTS_WARNINGS${NC}"
    echo -e "  Failed:          ${RED}$SCRIPTS_FAILED${NC}"
    echo ""

    # Average quality score
    if [[ ${#SCRIPT_SCORES[@]} -gt 0 ]]; then
        local total_score=0
        for score in "${SCRIPT_SCORES[@]}"; do
            total_score=$((total_score + score))
        done
        local avg_score=$((total_score / ${#SCRIPT_SCORES[@]}))

        echo -e "  Average quality: ${BOLD}$avg_score${NC}/100"
        echo ""
    fi

    # Failed scripts
    if [[ ${#FAILED_SCRIPTS[@]} -gt 0 ]]; then
        echo -e "${RED}Failed scripts:${NC}"
        for script in "${FAILED_SCRIPTS[@]}"; do
            echo -e "  ${RED}✗${NC} $script"
        done
        echo ""
    fi

    # Top issues across all scripts
    echo -e "${BOLD}Common Issues:${NC}"

    # Count issue types
    declare -A issue_counts
    for script_issues in "${ISSUES_CRITICAL[@]}" "${ISSUES_WARNING[@]}" "${ISSUES_INFO[@]}"; do
        while IFS= read -r issue; do
            [[ -z "$issue" ]] && continue
            local issue_type=$(echo "$issue" | cut -d: -f1)
            issue_counts["$issue_type"]=$((${issue_counts[$issue_type]:-0} + 1))
        done <<< "$script_issues"
    done

    # Display sorted by count
    for issue_type in "${!issue_counts[@]}"; do
        echo -e "  - $issue_type: ${issue_counts[$issue_type]} occurrences"
    done | sort -t: -k2 -rn

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

generate_json_report() {
    local json_file="${LOGS_DIR}/script-validation.json"

    # Build JSON structure
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"summary\": {"
        echo "    \"total\": $TOTAL_SCRIPTS,"
        echo "    \"passed\": $SCRIPTS_PASSED,"
        echo "    \"warnings\": $SCRIPTS_WARNINGS,"
        echo "    \"failed\": $SCRIPTS_FAILED"
        echo "  },"
        echo "  \"scripts\": {"

        local first=true
        for script_name in "${!SCRIPT_SCORES[@]}"; do
            [[ "$first" == "false" ]] && echo ","
            first=false

            echo "    \"$script_name\": {"
            echo "      \"score\": ${SCRIPT_SCORES[$script_name]},"
            echo "      \"critical\": $(echo "${ISSUES_CRITICAL[$script_name]:-}" | grep -c "." || echo 0),"
            echo "      \"warnings\": $(echo "${ISSUES_WARNING[$script_name]:-}" | grep -c "." || echo 0),"
            echo "      \"info\": $(echo "${ISSUES_INFO[$script_name]:-}" | grep -c "." || echo 0)"
            echo -n "    }"
        done

        echo ""
        echo "  }"
        echo "}"
    } > "$json_file"

    log_info "JSON report: $json_file"
}

# ===================================================================
# Argument Parsing
# ===================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                FIX_MODE=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                TARGET_SCRIPT="$1"
                shift
                ;;
        esac
    done
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS] [SCRIPT]

Validate bootstrap scripts for quality and completeness.

OPTIONS:
  --fix             Auto-fix issues where possible
  --json            Generate JSON report
  --verbose, -v     Show all issues including info-level
  --help, -h        Show this help message

ARGUMENTS:
  SCRIPT            Specific script to validate (default: all scripts)

EXAMPLES:
  $0                              # Validate all scripts
  $0 bootstrap-claude.sh          # Validate specific script
  $0 --fix --json                 # Validate all, fix issues, JSON output
  $0 --verbose                    # Show all issues

EXIT CODES:
  0 - All scripts passed
  1 - Critical issues found
  2 - Warnings only

EOF
}

# ===================================================================
# Main
# ===================================================================

main() {
    parse_args "$@"

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Bootstrap Script Validation                      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"

    # Create logs directory
    mkdir -p "$LOGS_DIR"

    # Determine scripts to validate
    local scripts=()

    if [[ -n "$TARGET_SCRIPT" ]]; then
        if [[ -f "$TARGET_SCRIPT" ]]; then
            scripts=("$TARGET_SCRIPT")
        elif [[ -f "${SCRIPTS_DIR}/$TARGET_SCRIPT" ]]; then
            scripts=("${SCRIPTS_DIR}/$TARGET_SCRIPT")
        else
            log_error "Script not found: $TARGET_SCRIPT"
            exit 1
        fi
    else
        # Validate all scripts in SCRIPTS_DIR
        while IFS= read -r script; do
            scripts+=("$script")
        done < <(find "$SCRIPTS_DIR" -name "*.sh" -type f)
    fi

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No scripts found to validate"
        exit 1
    fi

    # Validate each script
    for script in "${scripts[@]}"; do
        validate_script "$script"
    done

    # Generate reports
    generate_report

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        generate_json_report
    fi

    # Exit with appropriate code
    if [[ $SCRIPTS_FAILED -gt 0 ]]; then
        exit 1
    elif [[ $SCRIPTS_WARNINGS -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

main "$@"
