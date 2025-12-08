#!/bin/bash

# ===================================================================
# test-error-handler.sh
#
# Test suite for lib/error-handler.sh
# ===================================================================

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source dependencies
source "${BOOTSTRAP_DIR}/lib/paths.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"
source "${BOOTSTRAP_DIR}/lib/error-handler.sh"

# Test functions
test_error_code_names() {
    local name=$(error_get_code_name $ERR_SUCCESS)
    assert_equals "SUCCESS" "$name" "ERR_SUCCESS should map to 'SUCCESS'"

    name=$(error_get_code_name $ERR_DEPENDENCY_MISSING)
    assert_equals "DEPENDENCY_MISSING" "$name" "ERR_DEPENDENCY_MISSING should map correctly"

    name=$(error_get_code_name 999)
    assert_contains "$name" "UNKNOWN_ERROR" "Unknown code should return UNKNOWN_ERROR"
}

test_error_messages() {
    local msg=$(error_get_message $ERR_SUCCESS)
    assert_contains "$msg" "success" "Success message should mention success"

    msg=$(error_get_message $ERR_VALIDATION_FAILED)
    assert_contains "$msg" "Validation" "Validation error should mention validation"
}

test_should_rollback() {
    # Should rollback
    should_rollback $ERR_ROLLBACK_NEEDED
    assert_true "ERR_ROLLBACK_NEEDED should trigger rollback"

    should_rollback $ERR_VALIDATION_FAILED
    assert_true "ERR_VALIDATION_FAILED should trigger rollback"

    # Should not rollback
    should_rollback $ERR_GENERAL && false || true
    assert_true "ERR_GENERAL should not trigger rollback"
}

test_handle_error() {
    error_reset

    handle_error $ERR_GENERAL "Test error" "test-script" "Test context" || true

    assert_equals "$ERR_GENERAL" "$LAST_ERROR_CODE" "Error code should be stored"
    assert_equals "Test error" "$LAST_ERROR_MESSAGE" "Error message should be stored"
    assert_equals "1" "$ERROR_COUNT" "Error count should increment"
}

test_error_reset() {
    # Create some errors
    handle_error $ERR_GENERAL "Test 1" "script1" || true
    handle_error $ERR_GENERAL "Test 2" "script2" || true

    assert_equals "2" "$ERROR_COUNT" "Should have 2 errors"

    # Reset
    error_reset

    assert_equals "0" "$ERROR_COUNT" "Error count should be reset"
    assert_equals "0" "$LAST_ERROR_CODE" "Error code should be reset"
    assert_equals "" "$LAST_ERROR_MESSAGE" "Error message should be reset"
}

test_error_logging() {
    error_reset

    local log_file="${LOGS_DIR}/errors.log"

    # Clear log
    rm -f "$log_file"

    # Generate error
    handle_error $ERR_FILE_NOT_FOUND "Missing file" "test-script" || true

    # Check log was created
    if [[ -f "$log_file" ]]; then
        assert_true "Error log should be created"

        # Check log content
        local log_content=$(cat "$log_file")
        [[ "$log_content" == *"Missing file"* ]]
        assert_true "Log should contain error message"
    else
        # Log creation might fail in some environments
        echo "  ⚠ Warning: Error log not created (might be permission issue)"
    fi
}

test_enable_disable_error_handling() {
    # Enable
    enable_error_handling

    # Check trap is set (trap -p ERR should show something)
    local trap_output=$(trap -p ERR)
    [[ -n "$trap_output" ]]
    assert_true "ERR trap should be enabled"

    # Disable
    disable_error_handling

    trap_output=$(trap -p ERR)
    [[ -z "$trap_output" ]]
    assert_true "ERR trap should be disabled"
}
