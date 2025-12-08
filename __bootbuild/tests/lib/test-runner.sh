#!/bin/bash

# ===================================================================
# test-runner.sh
#
# Main test runner for __bootbuild/lib tests
# Runs all test_* functions and reports results
# ===================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test stats
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
declare -a FAILED_TESTS=()

# Test output control
VERBOSE=${VERBOSE:-false}

# ===================================================================
# Test Framework Functions
# ===================================================================

# Assert helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo -e "${RED}  ✗ $message${NC}"
        echo "    Expected: '$expected'"
        echo "    Got:      '$actual'"
        return 1
    fi
}

assert_true() {
    local message="${1:-Condition should be true}"
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        echo -e "${RED}  ✗ $message${NC}"
        return 1
    fi
}

assert_false() {
    local message="${1:-Condition should be false}"
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        return 0
    else
        echo -e "${RED}  ✗ $message${NC}"
        return 1
    fi
}

# Legacy compatibility (deprecated - use assert_true/assert_false)
assert_success() {
    assert_true "$@"
}

assert_failure() {
    assert_false "$@"
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo -e "${RED}  ✗ $message${NC}"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist: $dir}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        echo -e "${RED}  ✗ $message${NC}"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "${RED}  ✗ $message${NC}"
        echo "    String: '$haystack'"
        echo "    Should contain: '$needle'"
        return 1
    fi
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "${BLUE}→${NC} Running: $test_name"

    # Create temp directory for this test
    local test_tmp=$(mktemp -d)
    export TEST_TMP="$test_tmp"

    if $test_func; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}  ✓ PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        echo -e "${RED}  ✗ FAIL${NC}"
    fi

    # Cleanup
    rm -rf "$test_tmp"
    echo ""
}

# ===================================================================
# Test Discovery and Execution
# ===================================================================

# Discover and run all tests in a file
run_test_file() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Test Suite: $test_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Source the test file
    source "$test_file"

    # Find all test_* functions
    local test_functions=$(declare -F | awk '{print $3}' | grep '^test_')

    if [[ -z "$test_functions" ]]; then
        echo -e "${YELLOW}  ⚠ No tests found${NC}"
        return
    fi

    # Run each test
    for test_func in $test_functions; do
        run_test "$test_func" "$test_func"
    done
}

# ===================================================================
# Main Runner
# ===================================================================

main() {
    local test_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${test_dir}/../../lib" && pwd)"
    local fixtures_dir="$(cd "${test_dir}/../fixtures" && pwd)"

    # Export paths for tests
    export LIB_DIR="$lib_dir"
    export FIXTURES_DIR="$fixtures_dir"
    export TEST_DIR="$test_dir"

    # Header
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         __bootbuild Test Suite                       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"

    # Run all test files
    for test_file in "$test_dir"/test-*.sh; do
        [[ "$test_file" == *"test-runner.sh"* ]] && continue
        [[ -f "$test_file" ]] || continue

        run_test_file "$test_file"
    done

    # Summary
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Total:  ${BLUE}$TESTS_RUN${NC}"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Exit with proper code
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main
main "$@"
