#!/bin/bash

# ===================================================================
# bootstrap-testing.questions.sh
#
# Q&A script for testing framework configuration
# Asks 2 key questions to customize test settings
# ===================================================================

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/validation-common.sh"
source "${SCRIPT_DIR}/lib/config-manager.sh"

# ===================================================================
# Testing Configuration Questions
# ===================================================================

ask_testing_questions() {
    section_header "Testing Configuration"

    show_info "Configuring testing frameworks and quality thresholds"
    echo ""

    # Question 1: Coverage Threshold
    ask_with_default \
        "Code coverage threshold (%)?" \
        "testing.coverage_threshold" \
        "70" \
        COVERAGE_THRESHOLD

    # Question 2: E2E Framework
    ask_choice \
        "E2E testing framework?" \
        "testing.e2e_framework" \
        "playwright cypress none" \
        1 \
        E2E_FRAMEWORK

    echo ""
    show_success "Testing configuration collected"
}

# Run questions if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_answers
    ask_testing_questions
    show_answers_summary
fi
