#!/bin/bash

# ===================================================================
# bootstrap-healthcheck.sh
#
# Purpose: Post-execution verification of bootstrap system state
# Validates: Script execution logs, permissions, environment integrity
# Usage:   ./bootstrap-healthcheck.sh [options]
# Options:
#   --strict             Fail on any deviation from expected state
#   --report-only        Don't modify anything, only report
#   --compare-baseline   Compare against previous healthcheck
#   --json               Output results in JSON format
#   -h, --help           Show help
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export SCRIPT_NAME="bootstrap-healthcheck"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Source paths
source "${BOOTSTRAP_DIR}/lib/paths.sh" || {
    log_error "Failed to initialize paths"
    exit 1
}

# Source script registry for manifest validation
source "${LIB_DIR}/script-registry.sh" || {
    log_warning "Script registry not available - manifest validation disabled"
}

# Source JSON validator if available
if [[ -f "${LIB_DIR}/json-validator.sh" ]]; then
    source "${LIB_DIR}/json-validator.sh"
fi

# ===================================================================
# Configuration
# ===================================================================

# Options
STRICT_MODE=false
REPORT_ONLY=true
COMPARE_BASELINE=false
JSON_MODE=false
QUICK_MODE=false

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARNING_COUNT=0

# Results arrays for JSON output
declare -a PASSES=()
declare -a FAILURES=()
declare -a WARNINGS=()

# Baseline file
BASELINE_FILE="${LOGS_DIR}/bootstrap-healthcheck-baseline.json"
CURRENT_REPORT="${LOGS_DIR}/bootstrap-healthcheck-$(date +%Y%m%d-%H%M%S).json"
LATEST_REPORT="${LOGS_DIR}/bootstrap-healthcheck-latest.json"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# ===================================================================
# Helper Functions
# ===================================================================

# Track pass
track_pass() {
    local message="$1"
    ((PASS_COUNT++)) || true
    PASSES+=("$message")
    if [[ "$JSON_MODE" == "false" ]]; then
        log_success "$message"
    fi
}

# Track failure
track_fail() {
    local message="$1"
    ((FAIL_COUNT++)) || true
    FAILURES+=("$message")
    if [[ "$JSON_MODE" == "false" ]]; then
        log_error "$message"
    fi
}

# Track warning
track_warn() {
    local message="$1"
    ((WARNING_COUNT++)) || true
    WARNINGS+=("$message")
    if [[ "$JSON_MODE" == "false" ]]; then
        log_warning "$message"
    fi
}

# ===================================================================
# Usage
# ===================================================================

show_usage() {
    cat << 'USAGE'
Bootstrap Health Check - Post-execution verification

Usage:
  bootstrap-healthcheck.sh [options]

Options:
  --strict             Fail on any deviation (exit code 1 instead of 0)
  --report-only        Don't modify anything, only report (default)
  --compare-baseline   Compare against previous healthcheck baseline
  --json               Output results in JSON format
  --quick              Fast health check (critical libraries and tools only)
  -h, --help           Show this help

Exit Codes:
  0 - All checks passed (or warnings only in non-strict mode)
  1 - Critical failures found
  2 - Warnings found (only in --strict mode)

Examples:
  bootstrap-healthcheck.sh                    Run health check
  bootstrap-healthcheck.sh --quick            Quick health check
  bootstrap-healthcheck.sh --strict           Fail on any warning
  bootstrap-healthcheck.sh --compare-baseline Compare with baseline
  bootstrap-healthcheck.sh --json > report.json

Checks Performed:
  - Script execution logs integrity
  - Manifest and config file integrity
  - File and directory permissions
  - Orphaned processes from bootstrap scripts
  - Required tools still installed
  - Environment variables set correctly
  - Completion markers for executed phases
USAGE
}

# ===================================================================
# Parse Arguments
# ===================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --report-only)
                REPORT_ONLY=true
                shift
                ;;
            --compare-baseline)
                COMPARE_BASELINE=true
                shift
                ;;
            --json)
                JSON_MODE=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
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
# Health Check Functions
# ===================================================================

# Quick health check (critical libraries and tools only)
quick_health_check() {
    local errors=0

    [[ "$JSON_MODE" == "false" ]] && log_section "Quick Health Check"

    # Check critical library files exist
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking critical library files..."
    for lib in common.sh config-manager.sh script-registry.sh; do
        if [[ ! -f "${LIB_DIR}/${lib}" ]]; then
            log_error "Missing library: $lib"
            ((errors++))
        else
            [[ "$JSON_MODE" == "false" ]] && log_success "Library: $lib"
        fi
    done

    # Validate manifest with registry
    [[ "$JSON_MODE" == "false" ]] && echo ""
    [[ "$JSON_MODE" == "false" ]] && log_info "Validating manifest..."
    if type -t registry_validate_manifest &>/dev/null; then
        if registry_validate_manifest &>/dev/null; then
            [[ "$JSON_MODE" == "false" ]] && log_success "Manifest valid"
        else
            log_error "Invalid manifest"
            ((errors++))
        fi
    else
        log_warning "Cannot validate manifest (registry not available)"
    fi

    # Check critical tools
    [[ "$JSON_MODE" == "false" ]] && echo ""
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking critical tools..."
    for tool in bash jq; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "Missing critical tool: $tool"
            ((errors++))
        else
            [[ "$JSON_MODE" == "false" ]] && log_success "Tool: $tool"
        fi
    done

    # Report results
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "Quick health check passed"
        return 0
    else
        log_error "Quick health check failed ($errors errors)"
        return 1
    fi
}

# Check execution logs
check_execution_logs() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking execution logs..."

    # Check if any completion markers exist
    local marker_count=$(find "$LOGS_DIR" -name ".*.completed" -type f 2>/dev/null | wc -l)

    if [[ $marker_count -gt 0 ]]; then
        track_pass "Found $marker_count completion markers"

        # List completed scripts
        while IFS= read -r -d '' marker; do
            local script_name=$(basename "$marker" | sed 's/^\.//' | sed 's/\.completed$//')
            track_pass "Script completed: $script_name"
        done < <(find "$LOGS_DIR" -name ".*.completed" -type f -print0 2>/dev/null)
    else
        track_warn "No completion markers found - bootstrap may not have run yet"
    fi

    # Check for bootstrap log file
    local log_file="${BOOTSTRAP_DIR}/bootstrap.log"
    if [[ -f "$log_file" ]]; then
        local log_size=$(stat -c %s "$log_file" 2>/dev/null || stat -f %z "$log_file" 2>/dev/null || echo "0")
        track_pass "Bootstrap log exists (size: $log_size bytes)"

        # Check for errors in log
        local error_count=$(grep -c "FAILED" "$log_file" 2>/dev/null || echo "0")
        error_count=$(echo "$error_count" | head -1)
        if [[ "$error_count" =~ ^[0-9]+$ ]] && [[ $error_count -gt 0 ]]; then
            track_fail "Found $error_count errors in bootstrap log"
        else
            track_pass "No errors found in bootstrap log"
        fi
    else
        track_warn "Bootstrap log not found: $log_file"
    fi
}

# Check manifest integrity
check_manifest() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking manifest integrity..."

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        track_fail "Manifest file missing: $MANIFEST_FILE"
        return 1
    fi

    if [[ ! -r "$MANIFEST_FILE" ]]; then
        track_fail "Manifest file not readable"
        return 1
    fi

    # Validate JSON if jq available
    if command -v jq &>/dev/null; then
        if jq empty "$MANIFEST_FILE" &>/dev/null; then
            track_pass "Manifest JSON valid"
        else
            track_fail "Manifest JSON corrupted"
            return 1
        fi
    else
        track_warn "Cannot validate manifest JSON (jq not available)"
    fi
}

# Check config integrity
check_config() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking config file integrity..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        track_warn "Config file not found (may not have been created yet)"
        return 0
    fi

    if [[ ! -r "$CONFIG_FILE" ]]; then
        track_fail "Config file not readable"
        return 1
    fi

    # Check for basic config structure
    if grep -q "^\[" "$CONFIG_FILE" 2>/dev/null; then
        track_pass "Config file has valid section structure"
    else
        track_warn "Config file may be malformed"
    fi

    # Check if config is writable
    if [[ ! -w "$CONFIG_FILE" ]]; then
        track_warn "Config file not writable"
    else
        track_pass "Config file writable"
    fi
}

# Check file and directory permissions
check_permissions() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking permissions..."

    local critical_dirs=("$CONFIG_DIR" "$LOGS_DIR" "$LIB_DIR" "$SCRIPTS_DIR")

    for dir in "${critical_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            track_fail "Critical directory missing: $(basename "$dir")"
            continue
        fi

        if [[ ! -r "$dir" ]]; then
            track_fail "Directory not readable: $(basename "$dir")"
        elif [[ ! -x "$dir" ]]; then
            track_fail "Directory not executable: $(basename "$dir")"
        else
            track_pass "Directory permissions OK: $(basename "$dir")"
        fi

        # Check writable for logs and config
        case "$(basename "$dir")" in
            logs|config)
                if [[ ! -w "$dir" ]]; then
                    track_fail "Directory not writable: $(basename "$dir")"
                else
                    track_pass "Directory writable: $(basename "$dir")"
                fi
                ;;
        esac
    done

    # Check script executability
    local executable_count=0
    local non_executable_count=0

    while IFS= read -r -d '' script; do
        if [[ -x "$script" ]]; then
            ((executable_count++)) || true
        else
            ((non_executable_count++)) || true
            track_warn "Script not executable: $(basename "$script")"
        fi
    done < <(find "$SCRIPTS_DIR" -name "*.sh" -type f -print0 2>/dev/null)

    if [[ $non_executable_count -eq 0 ]]; then
        track_pass "All $executable_count scripts are executable"
    fi
}

# Check for orphaned processes
check_orphaned_processes() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking for orphaned processes..."

    # Look for any bootstrap-related processes
    local bootstrap_procs=$(ps aux | grep -i bootstrap | grep -v grep | grep -v "$SCRIPT_NAME" | wc -l)

    if [[ $bootstrap_procs -gt 0 ]]; then
        track_warn "Found $bootstrap_procs bootstrap-related processes running"

        if [[ "$JSON_MODE" == "false" ]]; then
            ps aux | grep -i bootstrap | grep -v grep | grep -v "$SCRIPT_NAME" | while read -r line; do
                log_warning "  Process: $line"
            done
        fi
    else
        track_pass "No orphaned bootstrap processes found"
    fi
}

# Check required tools
check_required_tools() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking required tools..."

    local required_tools=("bash")
    local recommended_tools=("git" "jq")

    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            track_pass "Required tool available: $tool"
        else
            track_fail "Required tool missing: $tool"
        fi
    done

    for tool in "${recommended_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            track_pass "Recommended tool available: $tool"
        else
            track_warn "Recommended tool missing: $tool"
        fi
    done
}

# Check environment variables
check_environment() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Checking environment variables..."

    # Check if key bootstrap variables are set
    local required_vars=("BOOTSTRAP_DIR")

    for var in "${required_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            track_pass "Environment variable set: $var"
        else
            track_warn "Environment variable not set: $var"
        fi
    done
}

# Compare with baseline
compare_with_baseline() {
    [[ "$JSON_MODE" == "false" ]] && log_info "Comparing with baseline..."

    if [[ ! -f "$BASELINE_FILE" ]]; then
        track_warn "No baseline file found - this may be first healthcheck"
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        track_warn "Cannot compare with baseline (jq not available)"
        return 0
    fi

    # Compare key metrics
    local baseline_errors=$(jq -r '.health.failures // 0' "$BASELINE_FILE" 2>/dev/null || echo "0")
    local baseline_warnings=$(jq -r '.health.warnings // 0' "$BASELINE_FILE" 2>/dev/null || echo "0")

    track_pass "Baseline comparison: $baseline_errors errors, $baseline_warnings warnings previously"
}

# ===================================================================
# Main Health Check
# ===================================================================

run_healthcheck() {
    [[ "$JSON_MODE" == "false" ]] && log_section "Bootstrap Health Check"

    check_execution_logs
    check_manifest
    check_config
    check_permissions
    check_orphaned_processes
    check_required_tools
    check_environment

    if [[ "$COMPARE_BASELINE" == "true" ]]; then
        compare_with_baseline
    fi
}

# ===================================================================
# Results Output
# ===================================================================

save_report() {
    # Generate JSON report
    cat > "$CURRENT_REPORT" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "health": {
    "passed": $PASS_COUNT,
    "warnings": $WARNING_COUNT,
    "failures": $FAIL_COUNT
  },
  "passes": [
EOF

    for i in "${!PASSES[@]}"; do
        local comma=","
        [[ $i -eq $((${#PASSES[@]} - 1)) ]] && comma=""
        echo "    \"${PASSES[$i]}\"$comma"
    done >> "$CURRENT_REPORT"

    cat >> "$CURRENT_REPORT" << EOF
  ],
  "warnings": [
EOF

    for i in "${!WARNINGS[@]}"; do
        local comma=","
        [[ $i -eq $((${#WARNINGS[@]} - 1)) ]] && comma=""
        echo "    \"${WARNINGS[$i]}\"$comma"
    done >> "$CURRENT_REPORT"

    cat >> "$CURRENT_REPORT" << EOF
  ],
  "failures": [
EOF

    for i in "${!FAILURES[@]}"; do
        local comma=","
        [[ $i -eq $((${#FAILURES[@]} - 1)) ]] && comma=""
        echo "    \"${FAILURES[$i]}\"$comma"
    done >> "$CURRENT_REPORT"

    cat >> "$CURRENT_REPORT" << EOF
  ],
  "status": "$(get_status)"
}
EOF

    # Create symlink to latest
    ln -sf "$(basename "$CURRENT_REPORT")" "$LATEST_REPORT"

    # If this is a successful run, update baseline
    if [[ $FAIL_COUNT -eq 0 ]]; then
        cp "$CURRENT_REPORT" "$BASELINE_FILE"
    fi
}

show_summary() {
    if [[ "$JSON_MODE" == "true" ]]; then
        cat "$CURRENT_REPORT"
    else
        # Human-readable output
        echo ""
        log_section "Health Check Summary"
        echo ""
        echo -e "  ${GREEN}Passed:${NC}   $PASS_COUNT"
        echo -e "  ${YELLOW}Warnings:${NC} $WARNING_COUNT"
        echo -e "  ${RED}Failed:${NC}   $FAIL_COUNT"
        echo ""

        if [[ $FAIL_COUNT -eq 0 && $WARNING_COUNT -eq 0 ]]; then
            log_success "All health checks passed!"
        elif [[ $FAIL_COUNT -eq 0 ]]; then
            log_warning "Health check passed with $WARNING_COUNT warnings"
        else
            log_error "Health check failed with $FAIL_COUNT failures"
        fi

        echo ""
        echo "Reports:"
        echo "  Current:  $CURRENT_REPORT"
        echo "  Latest:   $LATEST_REPORT"
        if [[ -f "$BASELINE_FILE" ]]; then
            echo "  Baseline: $BASELINE_FILE"
        fi
        echo ""

        # Show suggestions if there are failures
        if [[ $FAIL_COUNT -gt 0 ]]; then
            echo "Suggestions:"
            echo "  1. Run: bootstrap-validate.sh --fix"
            echo "  2. Check logs: $LOGS_DIR"
            echo "  3. Review manifest: $MANIFEST_FILE"
            echo ""
        fi
    fi
}

get_status() {
    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo "FAILED"
    elif [[ $WARNING_COUNT -gt 0 ]]; then
        echo "WARNINGS"
    else
        echo "HEALTHY"
    fi
}

determine_exit_code() {
    if [[ $FAIL_COUNT -gt 0 ]]; then
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

    # Run quick health check if --quick flag set
    if [[ "$QUICK_MODE" == "true" ]]; then
        quick_health_check
        exit $?
    fi

    run_healthcheck

    save_report

    show_summary

    determine_exit_code
}

main "$@"
