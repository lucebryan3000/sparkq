#!/bin/bash

# ===================================================================
# test-progress-bars.sh
#
# Manual test script for ui-utils.sh progress bar functionality.
# Tests all progress bar features with visual demonstrations.
#
# USAGE:
#   ./test-progress-bars.sh
# ===================================================================

set -euo pipefail

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source required libraries
source "${BOOTSTRAP_DIR}/lib/paths.sh" || exit 1
source "${LIB_DIR}/common.sh" || exit 1
source "${LIB_DIR}/ui-utils.sh" || exit 1

# ===================================================================
# Test Functions
# ===================================================================

test_basic_progress_bar() {
    log_section "Test 1: Basic Progress Bar"
    echo "Testing basic progress bar with 10 steps..."
    echo ""

    local total=10
    for ((i=0; i<=total; i++)); do
        show_progress_bar "$i" "$total" "Test Progress"
        sleep 0.2
    done

    echo ""
    log_success "Basic progress bar test complete"
    echo ""
}

test_progress_bar_labels() {
    log_section "Test 2: Progress Bar with Different Labels"
    echo "Testing progress bars with various labels..."
    echo ""

    local labels=("Installing" "Building" "Testing" "Deploying" "Complete")
    local total=5

    for ((i=0; i<=total; i++)); do
        local label="${labels[$i]}"
        show_progress_bar "$i" "$total" "$label"
        sleep 0.3
    done

    echo ""
    log_success "Label test complete"
    echo ""
}

test_duration_formatting() {
    log_section "Test 3: Duration Formatting"
    echo "Testing format_duration function..."
    echo ""

    local test_cases=(
        "30:30s"
        "90:1m 30s"
        "150:2m 30s"
        "3600:1h 0m"
        "3665:1h 1m"
        "7200:2h 0m"
    )

    for test in "${test_cases[@]}"; do
        local seconds="${test%%:*}"
        local expected="${test#*:}"
        local result=$(format_duration "$seconds")
        printf "  %5d seconds -> %-10s (expected: %s)\n" "$seconds" "$result" "$expected"
    done

    echo ""
    log_success "Duration formatting test complete"
    echo ""
}

test_eta_calculation() {
    log_section "Test 4: ETA Calculation"
    echo "Simulating work with ETA calculation..."
    echo ""

    local total=10
    local start_time=$(date +%s)

    for ((i=0; i<=total; i++)); do
        # Show progress with ETA
        local eta=$(calculate_eta "$start_time" "$i" "$total")
        show_progress_bar "$i" "$total" "Processing"

        if [[ -n "$eta" ]]; then
            printf " ETA: %s" "$eta"
        fi

        # Simulate work
        sleep 0.3
    done

    echo ""
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local formatted=$(format_duration "$duration")

    log_success "ETA calculation test complete in $formatted"
    echo ""
}

test_phase_simulation() {
    log_section "Test 5: Phase Execution Simulation"
    echo "Simulating Phase 1 with 5 scripts..."
    echo ""

    local scripts=("git" "packages" "vscode" "typescript" "environment")
    local total=${#scripts[@]}
    local start_time=$(date +%s)
    local current=0

    for script in "${scripts[@]}"; do
        show_progress_bar "$current" "$total" "Phase 1"

        log_info "Running: $script"
        sleep 0.5

        ((current++))
    done

    # Show final progress
    show_progress_bar "$total" "$total" "Phase 1"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local formatted=$(format_duration "$duration")

    log_success "Phase 1 completed in $formatted"
    echo ""
}

test_profile_simulation() {
    log_section "Test 6: Profile Execution Simulation"
    echo "Simulating 'standard' profile with 7 scripts..."
    echo ""

    local scripts=("git" "packages" "vscode" "typescript" "linting" "editor" "git-config")
    local total=${#scripts[@]}
    local start_time=$(date +%s)
    local current=0

    for script in "${scripts[@]}"; do
        show_progress_bar "$current" "$total" "Profile: standard"

        log_info "Running: $script"
        sleep 0.4

        ((current++))
    done

    # Show final progress
    show_progress_bar "$total" "$total" "Profile: standard"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local formatted=$(format_duration "$duration")

    log_success "Profile 'standard' completed in $formatted"
    echo ""
}

test_no_color_mode() {
    log_section "Test 7: NO_COLOR Mode"
    echo "Testing progress bar with NO_COLOR=1..."
    echo ""

    export NO_COLOR=1
    source "${LIB_DIR}/ui-utils.sh"  # Re-source to pick up NO_COLOR

    local total=10
    for ((i=0; i<=total; i++)); do
        show_progress_bar "$i" "$total" "No Color Test"
        sleep 0.2
    done

    unset NO_COLOR
    echo ""
    log_success "NO_COLOR mode test complete"
    echo ""
}

# ===================================================================
# Main Test Runner
# ===================================================================
main() {
    log_section "UI Utils Progress Bar Test Suite"
    echo ""
    echo "This script tests all progress bar functionality."
    echo "Watch the progress bars update in real-time."
    echo ""

    read -p "Press Enter to start tests..." -r

    # Run all tests
    test_basic_progress_bar
    sleep 1

    test_progress_bar_labels
    sleep 1

    test_duration_formatting
    sleep 1

    test_eta_calculation
    sleep 1

    test_phase_simulation
    sleep 1

    test_profile_simulation
    sleep 1

    test_no_color_mode

    # Summary
    log_section "Test Suite Complete"
    echo ""
    echo "All progress bar tests completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Try running: __bootbuild/scripts/bootstrap-menu.sh --phase=1"
    echo "  2. You should see progress bars during phase execution"
    echo "  3. Try: __bootbuild/scripts/bootstrap-menu.sh --profile=minimal"
    echo "  4. To disable: __bootbuild/scripts/bootstrap-menu.sh --phase=1 --no-progress"
    echo ""
}

# Run tests
main "$@"
