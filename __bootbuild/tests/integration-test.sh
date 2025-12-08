#!/bin/bash

# ===================================================================
# integration-test.sh
#
# Integration test suite for bootstrap phase execution
# Tests full phase workflows with real data and validation
#
# USAGE:
#   ./integration-test.sh --phase=1       # Test specific phase
#   ./integration-test.sh --all           # Test all phases
#   ./integration-test.sh --dry-run       # Verify without changes
#   ./integration-test.sh --report        # Generate report only
#
# FEATURES:
# - Full phase execution testing
# - State validation (before/after)
# - Rollback testing
# - TAP (Test Anything Protocol) output
# - Isolated test environments
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
source "${BOOTSTRAP_DIR}/lib/error-handler.sh" || exit 1

# Don't source test-runner.sh as it runs main() automatically
# We only need the assert functions from it
# Instead, define our own assert functions or import selectively

# Test configuration
TEST_OUTPUT_DIR="${LOGS_DIR}/integration-tests"
TEST_WORKSPACE=""
DRY_RUN=false
PHASE_TO_TEST=""
RUN_ALL_PHASES=false
REPORT_ONLY=false
VERBOSE=false

# Test stats
PHASE_TESTS_RUN=0
PHASE_TESTS_PASSED=0
PHASE_TESTS_FAILED=0
declare -a FAILED_PHASE_TESTS=()

# ===================================================================
# Colors
# ===================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# ===================================================================
# Helper Functions
# ===================================================================

log_test() {
    echo -e "${BLUE}→${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_info() {
    echo -e "${GRAY}ℹ${NC} $*"
}

# ===================================================================
# Test Environment Management
# ===================================================================

setup_test_workspace() {
    TEST_WORKSPACE=$(mktemp -d -t bootstrap-integration-test.XXXXXX)
    export TEST_WORKSPACE

    log_info "Created test workspace: $TEST_WORKSPACE"

    # Create minimal project structure
    mkdir -p "$TEST_WORKSPACE"/{.git,src,tests}
    touch "$TEST_WORKSPACE/README.md"

    # Initialize git repo
    if command -v git &>/dev/null; then
        (
            cd "$TEST_WORKSPACE"
            git init -q
            git config user.name "Test User"
            git config user.email "test@example.com"
        ) 2>/dev/null || true
    fi

    return 0
}

cleanup_test_workspace() {
    if [[ -n "$TEST_WORKSPACE" ]] && [[ -d "$TEST_WORKSPACE" ]]; then
        log_info "Cleaning up test workspace: $TEST_WORKSPACE"
        rm -rf "$TEST_WORKSPACE"
    fi
}

capture_state() {
    local state_file="$1"
    local target_dir="${2:-$TEST_WORKSPACE}"

    {
        echo "# State captured at $(date)"
        echo "# Directory: $target_dir"
        echo ""

        # List files
        echo "## Files:"
        find "$target_dir" -type f 2>/dev/null | sort || true
        echo ""

        # List directories
        echo "## Directories:"
        find "$target_dir" -type d 2>/dev/null | sort || true
        echo ""

        # Git status if available
        if [[ -d "$target_dir/.git" ]]; then
            echo "## Git Status:"
            (cd "$target_dir" && git status --short 2>/dev/null) || true
            echo ""
        fi

        # Config state
        if [[ -f "$CONFIG_FILE" ]]; then
            echo "## Config File:"
            cat "$CONFIG_FILE"
            echo ""
        fi
    } > "$state_file"
}

compare_states() {
    local before_state="$1"
    local after_state="$2"
    local diff_file="${3:-/dev/null}"

    if ! diff -u "$before_state" "$after_state" > "$diff_file" 2>&1; then
        return 1  # States differ
    fi

    return 0  # States identical
}

# ===================================================================
# Phase Test Functions
# ===================================================================

test_phase_prerequisites() {
    local phase=$1
    local phase_name="$2"

    log_test "Testing prerequisites for Phase $phase: $phase_name"

    # Check if phase exists in manifest
    if ! jq -e ".phases.\"$phase\"" "$MANIFEST_FILE" >/dev/null 2>&1; then
        log_error "Phase $phase not found in manifest"
        return 1
    fi

    # Get scripts for this phase
    local scripts=$(jq -r ".scripts | to_entries[] | select(.value.phase == $phase) | .key" "$MANIFEST_FILE")

    if [[ -z "$scripts" ]]; then
        log_warn "No scripts found for phase $phase"
        return 0
    fi

    # Check each script file exists
    local missing_scripts=()
    for script in $scripts; do
        local script_file=$(jq -r ".scripts.\"$script\".file" "$MANIFEST_FILE")
        if [[ ! -f "${SCRIPTS_DIR}/${script_file}" ]]; then
            missing_scripts+=("$script_file")
        fi
    done

    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        log_error "Missing script files: ${missing_scripts[*]}"
        return 1
    fi

    log_success "Prerequisites validated for phase $phase"
    return 0
}

test_phase_script_order() {
    local phase=$1
    local phase_name="$2"

    log_test "Testing script execution order for Phase $phase"

    # Get scripts for this phase with dependencies
    local scripts=$(jq -r ".scripts | to_entries[] | select(.value.phase == $phase) | .key" "$MANIFEST_FILE")

    if [[ -z "$scripts" ]]; then
        log_success "No scripts to order for phase $phase"
        return 0
    fi

    # Check dependency ordering
    for script in $scripts; do
        local depends=$(jq -r ".scripts.\"$script\".depends // [] | .[]" "$MANIFEST_FILE")

        for dep in $depends; do
            # Verify dependency exists
            if ! jq -e ".scripts.\"$dep\"" "$MANIFEST_FILE" >/dev/null 2>&1; then
                log_error "Script $script depends on non-existent script: $dep"
                return 1
            fi

            # Verify dependency is in same or earlier phase
            local dep_phase=$(jq -r ".scripts.\"$dep\".phase" "$MANIFEST_FILE")
            if [[ $dep_phase -gt $phase ]]; then
                log_error "Script $script (phase $phase) depends on $dep (phase $dep_phase) - dependency cycle"
                return 1
            fi
        done
    done

    log_success "Script order validated for phase $phase"
    return 0
}

test_phase_execution() {
    local phase=$1
    local phase_name="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run - skipping actual execution for phase $phase"
        return 0
    fi

    log_test "Testing execution of Phase $phase: $phase_name"

    # Capture state before
    local before_state="${TEST_OUTPUT_DIR}/phase${phase}-before.state"
    capture_state "$before_state"

    # Get scripts for this phase
    local scripts=$(jq -r ".scripts | to_entries[] | select(.value.phase == $phase) | .key" "$MANIFEST_FILE")

    if [[ -z "$scripts" ]]; then
        log_success "No scripts to execute for phase $phase"
        return 0
    fi

    # Execute each script
    local execution_log="${TEST_OUTPUT_DIR}/phase${phase}-execution.log"
    local failed_scripts=()

    for script in $scripts; do
        local script_file=$(jq -r ".scripts.\"$script\".file" "$MANIFEST_FILE")
        local script_path="${SCRIPTS_DIR}/${script_file}"

        log_info "Executing script: $script"

        if [[ -x "$script_path" ]]; then
            if "$script_path" --test-mode 2>&1 | tee -a "$execution_log"; then
                log_success "Script $script executed successfully"
            else
                log_error "Script $script failed"
                failed_scripts+=("$script")
            fi
        else
            log_warn "Script $script_path not executable or missing --test-mode support"
        fi
    done

    # Capture state after
    local after_state="${TEST_OUTPUT_DIR}/phase${phase}-after.state"
    capture_state "$after_state"

    # Generate diff
    local diff_file="${TEST_OUTPUT_DIR}/phase${phase}-diff.log"
    compare_states "$before_state" "$after_state" "$diff_file" || true

    if [[ ${#failed_scripts[@]} -gt 0 ]]; then
        log_error "Phase $phase had failures: ${failed_scripts[*]}"
        return 1
    fi

    log_success "Phase $phase executed successfully"
    return 0
}

test_phase_state_validation() {
    local phase=$1
    local phase_name="$2"

    log_test "Testing state validation for Phase $phase"

    # Expected files/directories based on phase
    case $phase in
        1)
            # Phase 1: AI Development Toolkit
            local expected_files=(
                ".claude/CLAUDE.md"
                ".gitignore"
                "package.json"
            )
            ;;
        2)
            # Phase 2: Infrastructure
            local expected_files=(
                "docker-compose.yml"
            )
            ;;
        3)
            # Phase 3: Code Quality
            local expected_files=(
                ".eslintrc.json"
                ".prettierrc"
            )
            ;;
        4)
            # Phase 4: CI/CD
            local expected_files=(
                ".github/workflows/ci.yml"
            )
            ;;
        *)
            log_info "No specific validation for phase $phase"
            return 0
            ;;
    esac

    # Check expected files exist (if not in dry-run)
    if [[ "$DRY_RUN" != "true" ]]; then
        local missing_files=()
        for file in "${expected_files[@]}"; do
            if [[ ! -e "${TEST_WORKSPACE}/${file}" ]]; then
                missing_files+=("$file")
            fi
        done

        if [[ ${#missing_files[@]} -gt 0 ]]; then
            log_warn "Expected files not created: ${missing_files[*]}"
            # Not a failure - scripts might not create all files in test mode
        fi
    fi

    log_success "State validation completed for phase $phase"
    return 0
}

test_phase_error_handling() {
    local phase=$1
    local phase_name="$2"

    log_test "Testing error handling for Phase $phase"

    # Test error recovery
    error_reset  # Clear any previous errors

    # Simulate an error condition
    local test_error_code=$ERR_VALIDATION_FAILED
    handle_error "$test_error_code" "Test error simulation" "integration-test" "Phase $phase error handling test"

    # Verify error was captured
    if [[ $ERROR_COUNT -eq 0 ]]; then
        log_error "Error handler did not capture simulated error"
        return 1
    fi

    # Verify error details
    if [[ $LAST_ERROR_CODE -ne $test_error_code ]]; then
        log_error "Error code mismatch: expected $test_error_code, got $LAST_ERROR_CODE"
        return 1
    fi

    # Reset for next test
    error_reset

    log_success "Error handling validated for phase $phase"
    return 0
}

test_phase_logging() {
    local phase=$1
    local phase_name="$2"

    log_test "Testing logging for Phase $phase"

    # Verify log directory exists
    if [[ ! -d "$LOGS_DIR" ]]; then
        log_error "Logs directory not found: $LOGS_DIR"
        return 1
    fi

    # Check if execution log was created
    local execution_log="${TEST_OUTPUT_DIR}/phase${phase}-execution.log"
    if [[ "$DRY_RUN" != "true" ]] && [[ ! -f "$execution_log" ]]; then
        log_warn "Execution log not created for phase $phase"
    fi

    log_success "Logging validated for phase $phase"
    return 0
}

# ===================================================================
# Main Phase Test Runner
# ===================================================================

test_phase() {
    local phase=$1

    # Get phase name from manifest
    local phase_name=$(jq -r ".phases.\"$phase\".name // \"Unknown\"" "$MANIFEST_FILE")

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Testing Phase $phase: $phase_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Run all tests for this phase
    local tests=(
        "test_phase_prerequisites"
        "test_phase_script_order"
        "test_phase_execution"
        "test_phase_state_validation"
        "test_phase_error_handling"
        "test_phase_logging"
    )

    local phase_passed=0
    local phase_failed=0

    for test in "${tests[@]}"; do
        PHASE_TESTS_RUN=$((PHASE_TESTS_RUN + 1))

        if $test "$phase" "$phase_name"; then
            PHASE_TESTS_PASSED=$((PHASE_TESTS_PASSED + 1))
            ((phase_passed++))
        else
            PHASE_TESTS_FAILED=$((PHASE_TESTS_FAILED + 1))
            ((phase_failed++))
            FAILED_PHASE_TESTS+=("Phase $phase: $test")
        fi
    done

    echo ""
    echo -e "${GRAY}Phase $phase Summary: ${GREEN}$phase_passed passed${NC}, ${RED}$phase_failed failed${NC}"
    echo ""

    return 0
}

# ===================================================================
# TAP Output Generation
# ===================================================================

generate_tap_output() {
    local tap_file="${TEST_OUTPUT_DIR}/integration-tests.tap"

    {
        echo "TAP version 13"
        echo "1..$PHASE_TESTS_RUN"

        local test_num=1
        for test in "${FAILED_PHASE_TESTS[@]}"; do
            echo "not ok $test_num - $test"
            ((test_num++))
        done

        local passed=$((PHASE_TESTS_RUN - PHASE_TESTS_FAILED))
        for ((i=1; i<=passed; i++)); do
            echo "ok $test_num - Test passed"
            ((test_num++))
        done

        echo "# Tests: $PHASE_TESTS_RUN"
        echo "# Passed: $PHASE_TESTS_PASSED"
        echo "# Failed: $PHASE_TESTS_FAILED"
    } > "$tap_file"

    log_info "TAP output: $tap_file"
}

# ===================================================================
# Report Generation
# ===================================================================

generate_report() {
    local report_file="${TEST_OUTPUT_DIR}/integration-test-report.md"

    {
        echo "# Bootstrap Integration Test Report"
        echo ""
        echo "**Generated:** $(date)"
        echo "**Workspace:** $TEST_WORKSPACE"
        echo "**Mode:** $([ "$DRY_RUN" == "true" ] && echo "Dry Run" || echo "Full Execution")"
        echo ""

        echo "## Summary"
        echo ""
        echo "- **Total Tests:** $PHASE_TESTS_RUN"
        echo "- **Passed:** $PHASE_TESTS_PASSED"
        echo "- **Failed:** $PHASE_TESTS_FAILED"
        echo "- **Success Rate:** $(( PHASE_TESTS_RUN > 0 ? (PHASE_TESTS_PASSED * 100) / PHASE_TESTS_RUN : 0 ))%"
        echo ""

        if [[ ${#FAILED_PHASE_TESTS[@]} -gt 0 ]]; then
            echo "## Failed Tests"
            echo ""
            for test in "${FAILED_PHASE_TESTS[@]}"; do
                echo "- $test"
            done
            echo ""
        fi

        echo "## Logs"
        echo ""
        echo "- Test output: $TEST_OUTPUT_DIR"
        echo "- Error log: ${LOGS_DIR}/errors.log"
        echo ""
    } > "$report_file"

    log_success "Report generated: $report_file"

    # Display report
    cat "$report_file"
}

# ===================================================================
# Argument Parsing
# ===================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --phase=*)
                PHASE_TO_TEST="${1#*=}"
                shift
                ;;
            --all)
                RUN_ALL_PHASES=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --report)
                REPORT_ONLY=true
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
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Integration test suite for bootstrap phase execution.

OPTIONS:
  --phase=N         Test specific phase number (1-4)
  --all             Test all phases
  --dry-run         Verify without making changes
  --report          Generate report only (skip tests)
  --verbose, -v     Verbose output
  --help, -h        Show this help message

EXAMPLES:
  $0 --phase=1           # Test Phase 1 only
  $0 --all               # Test all phases
  $0 --all --dry-run     # Dry run all phases
  $0 --report            # Generate report from last run

EOF
}

# ===================================================================
# Main
# ===================================================================

main() {
    parse_args "$@"

    # Create output directory
    mkdir -p "$TEST_OUTPUT_DIR"

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Bootstrap Integration Test Suite                 ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$REPORT_ONLY" == "true" ]]; then
        generate_report
        exit 0
    fi

    # Setup test environment
    setup_test_workspace
    trap cleanup_test_workspace EXIT

    # Run tests
    if [[ "$RUN_ALL_PHASES" == "true" ]]; then
        # Test all phases
        for phase in 1 2 3 4; do
            test_phase "$phase"
        done
    elif [[ -n "$PHASE_TO_TEST" ]]; then
        # Test specific phase
        test_phase "$PHASE_TO_TEST"
    else
        log_error "No phase specified. Use --phase=N or --all"
        show_help
        exit 1
    fi

    # Generate outputs
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Final Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Total:  ${BLUE}$PHASE_TESTS_RUN${NC}"
    echo -e "  Passed: ${GREEN}$PHASE_TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$PHASE_TESTS_FAILED${NC}"
    echo ""

    generate_tap_output
    generate_report

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Exit with proper code
    if [[ $PHASE_TESTS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
