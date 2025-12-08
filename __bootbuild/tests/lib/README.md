# __bootbuild Test Suite

Basic unit test framework for testing `__bootbuild/lib/` shell library functions.

## Running Tests

```bash
# Run all tests
bash __bootbuild/tests/lib/test-runner.sh

# Make test runner executable (optional)
chmod +x __bootbuild/tests/lib/test-runner.sh
./__bootbuild/tests/lib/test-runner.sh
```

## Test Structure

```
__bootbuild/tests/
├── lib/
│   ├── test-runner.sh          # Main test runner
│   ├── test-common.sh          # Tests for common.sh
│   ├── test-config-manager.sh  # Tests for config-manager.sh
│   ├── test-validation.sh      # Tests for validation-common.sh
│   └── README.md               # This file
└── fixtures/
    ├── sample-config.env       # Sample config file
    ├── sample-manifest.json    # Sample manifest
    └── sample-questions.json   # Sample questions
```

## Writing Tests

### Test File Naming

Test files must:
- Be named `test-*.sh`
- Be located in `__bootbuild/tests/lib/`
- Be executable or sourceable

### Test Function Naming

Test functions must:
- Start with `test_`
- Have descriptive names: `test_function_name_behavior`

Example:
```bash
test_config_get_default() {
    # Test implementation
}

test_config_set_update_existing() {
    # Test implementation
}
```

### Available Assertions

```bash
# Equality
assert_equals "expected" "actual" "optional message"

# Success/Failure
assert_success "optional message"
assert_failure "optional message"

# File/Directory existence
assert_file_exists "/path/to/file" "optional message"
assert_dir_exists "/path/to/dir" "optional message"

# String contains
assert_contains "haystack" "needle" "optional message"
```

### Test Structure

Each test function should:
1. Setup test environment (using `$TEST_TMP`)
2. Execute the function being tested
3. Assert expected results
4. Return 0 for pass, 1 for fail

Example:
```bash
test_ensure_dir_creates() {
    # Setup
    local test_dir="${TEST_TMP}/new_dir"

    # Execute
    ensure_dir "$test_dir"

    # Assert
    assert_dir_exists "$test_dir" "ensure_dir should create directory"
}
```

### Test Environment

Each test gets:
- `$TEST_TMP` - Temporary directory (cleaned up after test)
- `$LIB_DIR` - Path to `__bootbuild/lib/`
- `$FIXTURES_DIR` - Path to `__bootbuild/tests/fixtures/`
- `$TEST_DIR` - Path to `__bootbuild/tests/lib/`

### Cleanup

The test runner automatically:
- Creates a temp directory before each test
- Exports it as `$TEST_TMP`
- Cleans it up after the test completes

No manual cleanup needed in most cases.

## Example Test

```bash
#!/bin/bash

# Source the library under test
source "${LIB_DIR}/common.sh"

# Test log_info outputs message
test_log_info() {
    local output=$(log_info "test message" 2>&1)
    assert_contains "$output" "test message" "log_info should output message"
}

# Test ensure_dir creates directory
test_ensure_dir_creates() {
    local test_dir="${TEST_TMP}/new_dir"
    ensure_dir "$test_dir"
    assert_dir_exists "$test_dir" "ensure_dir should create directory"
}

# Test require_command fails for missing command
test_require_command_missing() {
    require_command "nonexistent_command_xyz" >/dev/null 2>&1
    assert_failure "require_command should fail for missing command"
}
```

## Adding New Test Files

1. Create `test-yourlib.sh` in `__bootbuild/tests/lib/`
2. Add test functions starting with `test_`
3. Source the library you're testing
4. Run the test runner - it will auto-discover your tests

Example:
```bash
# Create new test file
cat > __bootbuild/tests/lib/test-newlib.sh << 'EOF'
#!/bin/bash

source "${LIB_DIR}/newlib.sh"

test_new_function() {
    # Test implementation
    assert_success
}
EOF

# Run tests
bash __bootbuild/tests/lib/test-runner.sh
```

## Test Output

```
╔═══════════════════════════════════════════════════════╗
║         __bootbuild Test Suite                       ║
╚═══════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Test Suite: test-common
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

→ Running: test_log_info
  ✓ PASS

→ Running: test_ensure_dir_creates
  ✓ PASS

→ Running: test_require_command_missing
  ✓ PASS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total:  15
  Passed: 15
  Failed: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Best Practices

1. **Test one thing per test** - Keep tests focused
2. **Use descriptive names** - `test_function_name_expected_behavior`
3. **Test both success and failure** - Cover edge cases
4. **Keep tests fast** - No network calls, minimal I/O
5. **Use fixtures** - Store sample data in `fixtures/`
6. **Clean up** - Use `$TEST_TMP` for temporary files
7. **Avoid external dependencies** - Stick to bash and core utils

## Test Coverage

Current coverage:
- `common.sh` - Logging, file ops, validation helpers
- `config-manager.sh` - Config get/set, auto-detection
- `validation-common.sh` - Validators, answer management

Not covered (intentionally minimal):
- Interactive prompts (hard to test in bash)
- Git operations (would require git repo setup)
- Template rendering (covered by integration tests)

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Debugging Failed Tests

If tests fail:

1. Look at the failure message showing expected vs actual
2. Run individual test files to isolate the problem
3. Add debug output to your test function
4. Check that `$TEST_TMP` is being used correctly
5. Verify library dependencies are sourced in correct order

## Future Enhancements

Potential additions:
- Coverage reporting
- Test isolation improvements
- Mock functions for external commands
- Performance benchmarking
- Integration tests
