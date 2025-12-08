#!/bin/bash

# ===================================================================
# test-common.sh
#
# Tests for lib/common.sh
# ===================================================================

# Source the library under test
source "${LIB_DIR}/common.sh"

# ===================================================================
# Logging Functions Tests
# ===================================================================

test_log_info() {
    local output=$(log_info "test message" 2>&1)
    assert_contains "$output" "test message" "log_info should output message"
}

test_log_success() {
    local output=$(log_success "success message" 2>&1)
    assert_contains "$output" "success message" "log_success should output message"
}

test_log_warning() {
    local output=$(log_warning "warning message" 2>&1)
    assert_contains "$output" "warning message" "log_warning should output message"
}

test_log_error() {
    local output=$(log_error "error message" 2>&1)
    assert_contains "$output" "error message" "log_error should output message"
}

test_log_debug_disabled() {
    unset BOOTSTRAP_DEBUG
    local output=$(log_debug "debug message" 2>&1)
    # Debug should not output when BOOTSTRAP_DEBUG is not set
    [[ -z "$output" ]] || return 1
}

test_log_debug_enabled() {
    export BOOTSTRAP_DEBUG=true
    local output=$(log_debug "debug message" 2>&1)
    assert_contains "$output" "debug message" "log_debug should output when enabled"
    unset BOOTSTRAP_DEBUG
}

# ===================================================================
# File Operations Tests
# ===================================================================

test_ensure_dir_creates() {
    local test_dir="${TEST_TMP}/new_dir"
    ensure_dir "$test_dir"
    assert_dir_exists "$test_dir" "ensure_dir should create directory"
}

test_ensure_dir_existing() {
    local test_dir="${TEST_TMP}/existing_dir"
    mkdir -p "$test_dir"
    ensure_dir "$test_dir"
    assert_dir_exists "$test_dir" "ensure_dir should succeed on existing directory"
}

test_backup_file() {
    local test_file="${TEST_TMP}/test.txt"
    echo "content" > "$test_file"

    local backup=$(backup_file "$test_file")

    assert_file_exists "$backup" "backup_file should create backup"
    assert_contains "$backup" ".backup." "backup should have timestamp"
}

test_backup_file_nonexistent() {
    local backup=$(backup_file "${TEST_TMP}/nonexistent.txt")
    [[ -z "$backup" ]] || return 1
}

test_verify_file_success() {
    local test_file="${TEST_TMP}/verify.txt"
    echo "content" > "$test_file"

    verify_file "$test_file" >/dev/null 2>&1
    assert_success "verify_file should succeed for existing file"
}

test_verify_file_failure() {
    verify_file "${TEST_TMP}/nonexistent.txt" >/dev/null 2>&1 && return 1
    return 0
}

test_safe_copy() {
    local src="${TEST_TMP}/source.txt"
    local dst="${TEST_TMP}/dest.txt"

    echo "content" > "$src"
    safe_copy "$src" "$dst" >/dev/null 2>&1

    assert_file_exists "$dst" "safe_copy should create destination"

    local content=$(cat "$dst")
    assert_equals "content" "$content" "safe_copy should preserve content"
}

test_safe_copy_with_backup() {
    local src="${TEST_TMP}/source.txt"
    local dst="${TEST_TMP}/dest.txt"

    echo "old" > "$dst"
    echo "new" > "$src"

    safe_copy "$src" "$dst" >/dev/null 2>&1

    # Verify new content
    local content=$(cat "$dst")
    assert_equals "new" "$content" "safe_copy should overwrite"

    # Verify backup was created
    local backup=$(ls "${dst}.backup."* 2>/dev/null | head -1)
    assert_file_exists "$backup" "safe_copy should create backup"
}

# ===================================================================
# Validation Helpers Tests
# ===================================================================

test_require_command_exists() {
    require_command "bash" >/dev/null 2>&1
    assert_success "require_command should succeed for bash"
}

test_require_command_missing() {
    require_command "nonexistent_command_xyz" >/dev/null 2>&1 && return 1
    return 0
}

test_has_jq() {
    if command -v jq &>/dev/null; then
        has_jq
        assert_success "has_jq should succeed when jq is installed"
    else
        has_jq
        assert_failure "has_jq should fail when jq is not installed"
    fi
}

test_require_dir_exists() {
    local test_dir="${TEST_TMP}/test_dir"
    mkdir -p "$test_dir"

    require_dir "$test_dir" >/dev/null 2>&1
    assert_success "require_dir should succeed for existing directory"
}

test_require_dir_missing() {
    require_dir "${TEST_TMP}/nonexistent_dir" >/dev/null 2>&1 && return 1
    return 0
}

test_is_writable_success() {
    is_writable "$TEST_TMP" >/dev/null 2>&1
    assert_success "is_writable should succeed for writable path"
}

test_is_writable_failure() {
    local readonly_dir="/root"
    is_writable "$readonly_dir" >/dev/null 2>&1 && return 1
    return 0
}

test_file_exists() {
    local test_file="${TEST_TMP}/exists.txt"
    echo "content" > "$test_file"

    file_exists "$test_file" || return 1

    file_exists "${TEST_TMP}/nonexistent.txt" && return 1
    return 0
}

test_dir_exists() {
    local test_dir="${TEST_TMP}/exists_dir"
    mkdir -p "$test_dir"

    dir_exists "$test_dir" || return 1

    dir_exists "${TEST_TMP}/nonexistent_dir" && return 1
    return 0
}

# ===================================================================
# Utility Functions Tests
# ===================================================================

test_is_ci() {
    unset CI
    unset GITHUB_ACTIONS
    unset GITLAB_CI

    is_ci && return 1

    export CI=true
    is_ci || return 1
    unset CI
}

test_timestamp() {
    local ts=$(timestamp)
    assert_contains "$ts" "T" "timestamp should contain ISO format"
    assert_contains "$ts" ":" "timestamp should contain time"
}

test_confirm_with_yes_flag() {
    export BOOTSTRAP_YES=true
    confirm "Test?" >/dev/null 2>&1
    assert_success "confirm should succeed with BOOTSTRAP_YES"
    unset BOOTSTRAP_YES
}

# ===================================================================
# Progress Tracking Tests
# ===================================================================

test_track_created() {
    _BOOTSTRAP_CREATED_FILES=()
    track_created "file1.txt"
    track_created "file2.txt"

    assert_equals "2" "${#_BOOTSTRAP_CREATED_FILES[@]}" "should track 2 files"
    assert_equals "file1.txt" "${_BOOTSTRAP_CREATED_FILES[0]}" "should track first file"
}

test_track_skipped() {
    _BOOTSTRAP_SKIPPED_FILES=()
    track_skipped "file1.txt"

    assert_equals "1" "${#_BOOTSTRAP_SKIPPED_FILES[@]}" "should track skipped file"
}

test_track_warning() {
    _BOOTSTRAP_WARNINGS=()
    track_warning "warning message"

    assert_equals "1" "${#_BOOTSTRAP_WARNINGS[@]}" "should track warning"
}
