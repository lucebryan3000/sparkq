#!/bin/bash

# ===================================================================
# test-validation.sh
#
# Tests for lib/validation-common.sh
# ===================================================================

# Setup
setup_validation_test() {
    export CONFIG_FILE="${TEST_TMP}/test.config"
    export BOOTSTRAP_CONFIG="$CONFIG_FILE"
    export ANSWERS_FILE="${TEST_TMP}/.bootstrap-answers.env"
}

# ===================================================================
# Validator Function Tests
# ===================================================================

test_validate_email_valid() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_email "user@example.com"
    assert_success "should accept valid email"
}

test_validate_email_invalid() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_email "invalid-email" && return 1

    validate_email "user@" && return 1

    validate_email "@example.com" && return 1

    return 0
}

test_validate_port_valid() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_port "3000"
    assert_success "should accept valid port"

    validate_port "1"
    assert_success "should accept port 1"

    validate_port "65535"
    assert_success "should accept port 65535"
}

test_validate_port_invalid() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_port "0" && return 1

    validate_port "65536" && return 1

    validate_port "abc" && return 1

    validate_port "-1" && return 1

    return 0
}

test_validate_project_name_valid() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_project_name "my-project"
    assert_success "should accept hyphens"

    validate_project_name "my_project"
    assert_success "should accept underscores"

    validate_project_name "MyProject123"
    assert_success "should accept alphanumeric"
}

test_validate_project_name_invalid() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_project_name "my project" && return 1

    validate_project_name "my@project" && return 1

    validate_project_name "my.project" && return 1

    return 0
}

test_validate_directory_exists() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    mkdir -p "${TEST_TMP}/test_dir"

    validate_directory "${TEST_TMP}/test_dir"
    assert_success "should accept existing directory"
}

test_validate_directory_missing() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_directory "${TEST_TMP}/nonexistent" && return 1
    return 0
}

test_validate_file_exists() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    touch "${TEST_TMP}/test.txt"

    validate_file "${TEST_TMP}/test.txt"
    assert_success "should accept existing file"
}

test_validate_file_missing() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    validate_file "${TEST_TMP}/nonexistent.txt" && return 1
    return 0
}

# ===================================================================
# Answer File Management Tests
# ===================================================================

test_init_answers() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    init_answers "$ANSWERS_FILE"

    assert_file_exists "$ANSWERS_FILE" "init_answers should create file"
    assert_contains "$(cat "$ANSWERS_FILE")" "Bootstrap customization answers" "should have header"
}

test_save_answer() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    init_answers "$ANSWERS_FILE"
    save_answer "TEST_VAR" "test_value" "$ANSWERS_FILE"

    assert_contains "$(cat "$ANSWERS_FILE")" 'TEST_VAR="test_value"' "should save answer"
}

test_save_multiple_answers() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    init_answers "$ANSWERS_FILE"
    save_answer "VAR1" "value1" "$ANSWERS_FILE"
    save_answer "VAR2" "value2" "$ANSWERS_FILE"

    local content=$(cat "$ANSWERS_FILE")

    assert_contains "$content" 'VAR1="value1"' "should save first answer"
    assert_contains "$content" 'VAR2="value2"' "should save second answer"
}

# ===================================================================
# Display Helper Tests
# ===================================================================

test_show_success() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    local output=$(show_success "test message" 2>&1)

    assert_contains "$output" "test message" "should show success message"
}

test_show_error() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    local output=$(show_error "error message" 2>&1)

    assert_contains "$output" "error message" "should show error message"
}

test_show_warning() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    local output=$(show_warning "warning message" 2>&1)

    assert_contains "$output" "warning message" "should show warning message"
}

test_show_info() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    local output=$(show_info "info message" 2>&1)

    assert_contains "$output" "info message" "should show info message"
}

test_section_header() {
    setup_validation_test

    source "${LIB_DIR}/validation-common.sh"

    local output=$(section_header "Test Section" 2>&1)

    assert_contains "$output" "Test Section" "should show section header"
}
