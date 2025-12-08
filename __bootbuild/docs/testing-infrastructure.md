# Bootstrap Testing and Error Handling Infrastructure

## Overview

Three comprehensive tools have been created for the bootstrap system:

1. **lib/error-handler.sh** - Centralized error handling library
2. **tests/integration-test.sh** - Phase execution testing suite
3. **scripts/bootstrap-validate-scripts.sh** - Script quality validation

## 1. Error Handler Library

### Location
`__bootbuild/lib/error-handler.sh`

### Purpose
Provides consistent error handling, logging, and recovery across all bootstrap scripts.

### Features

#### Standardized Error Codes
```bash
ERR_SUCCESS=0               # Success
ERR_GENERAL=1               # General error
ERR_DEPENDENCY_MISSING=2    # Missing dependency
ERR_PERMISSION_DENIED=3     # Permission denied
ERR_VALIDATION_FAILED=4     # Validation failed
ERR_ROLLBACK_NEEDED=5       # Rollback required
ERR_CONFIG_INVALID=6        # Invalid config
ERR_FILE_NOT_FOUND=7        # File not found
ERR_NETWORK_ERROR=8         # Network error
ERR_TIMEOUT=9               # Timeout
```

#### Key Functions

**error_trap_handler(exit_code, line_number)**
- Called automatically on ERR trap
- Captures stack trace and context
- Logs errors to file and console

**handle_error(code, message, script, [context], [recovery_hint])**
- Main error handler with custom messages
- Determines if rollback is needed
- Updates error state and logs

**error_summary()**
- Displays summary of all errors
- Shows error history with context
- Provides log file location

**error_reset()**
- Clears error state (for testing)

**enable_error_handling()**
- Enables automatic error trapping
- Sets up ERR trap and pipefail

### Usage Example

```bash
#!/bin/bash
set -euo pipefail

source "${LIB_DIR}/error-handler.sh"

# Enable automatic error trapping
enable_error_handling

# Handle specific errors
if ! some_command; then
    handle_error $ERR_DEPENDENCY_MISSING \
        "Required tool not found" \
        "my-script" \
        "Attempted to run 'some_command'" \
        "Install with: apt-get install tool"
    exit $ERR_DEPENDENCY_MISSING
fi

# Show summary at end
error_summary
```

### Integration

All bootstrap scripts should:
1. Source error-handler.sh early
2. Call enable_error_handling() after sourcing
3. Use handle_error() for custom error reporting
4. Call error_summary() before exit (optional)

### Error Logs

Errors are logged to: `__bootbuild/logs/errors.log`

Format includes:
- Timestamp
- Error code and name
- Message
- Script and line number
- Stack trace
- Context information

## 2. Integration Test Suite

### Location
`__bootbuild/tests/integration-test.sh`

### Purpose
Tests full phase execution workflows with real data validation.

### Features

#### Test Categories

**Prerequisites Testing**
- Verifies phase exists in manifest
- Checks script files exist
- Validates dependencies

**Script Order Testing**
- Validates dependency ordering
- Detects circular dependencies
- Ensures dependencies run first

**Execution Testing**
- Runs scripts in test mode
- Captures before/after state
- Generates execution logs

**State Validation**
- Checks expected files created
- Validates directory structure
- Compares state changes

**Error Handling Testing**
- Tests error capture
- Validates error recovery
- Checks rollback triggers

**Logging Testing**
- Verifies log creation
- Validates log content
- Checks log directory exists

#### Usage

```bash
# Test specific phase
./tests/integration-test.sh --phase=1

# Test all phases
./tests/integration-test.sh --all

# Dry run (no changes)
./tests/integration-test.sh --all --dry-run

# Generate report only
./tests/integration-test.sh --report

# Verbose output
./tests/integration-test.sh --phase=1 --verbose
```

#### Output Formats

**Console Output**
- Color-coded results
- Progress indicators
- Summary statistics

**TAP Format**
- Standard test output format
- Compatible with CI systems
- Located at: `logs/integration-tests/integration-tests.tap`

**Markdown Report**
- Detailed test results
- Failed test listing
- Log locations
- Located at: `logs/integration-tests/integration-test-report.md`

#### Test Workspace

Each test run creates an isolated workspace:
- Temporary directory in /tmp
- Minimal git repo initialized
- Cleaned up after tests
- State captured before/after

## 3. Script Validation Tool

### Location
`__bootbuild/scripts/bootstrap-validate-scripts.sh`

### Purpose
Validates all bootstrap scripts for quality, completeness, and compliance.

### Validation Checks

#### 1. Shebang
- Must start with `#!/bin/bash` or `#!/usr/bin/env bash`
- **Severity:** Critical

#### 2. Syntax
- Uses `bash -n` to check syntax
- Catches parsing errors
- **Severity:** Critical

#### 3. Shellcheck (if available)
- Runs shellcheck for advanced analysis
- Reports warnings and errors
- **Severity:** Warning

#### 4. Header Comment
- Checks for documentation header
- Looks for === borders or long comment blocks
- **Severity:** Info

#### 5. Help Text
- Must provide --help or USAGE: documentation
- **Severity:** Warning

#### 6. Error Handling
- Checks for `set -e` or `set -euo pipefail`
- Looks for trap usage
- **Severity:** Info

#### 7. Path Sourcing
- Should source lib/paths.sh
- Not required for library files
- **Severity:** Warning

#### 8. Main Function
- Encourages main() function usage
- Not required for libraries
- **Severity:** Info

#### 9. TODO/FIXME Markers
- Flags unresolved TODOs
- **Severity:** Info

#### 10. Eval Usage
- Warns against `eval` usage
- **Severity:** Warning

#### 11. Hardcoded Paths
- Detects absolute path strings
- Encourages path variables
- **Severity:** Warning

#### 12. Executable Permission
- Must have execute permission
- Can auto-fix with --fix
- **Severity:** Warning

#### 13. Registry Compliance
- Must be listed in bootstrap-manifest.json
- **Severity:** Warning

### Quality Scoring

Scripts receive a score out of 100:

- **Critical issues:** -10 points each
- **Warnings:** -5 points each
- **Info issues:** -2 points each

#### Thresholds

- **< 50:** FAILED (critical threshold)
- **< 75:** WARNINGS (warning threshold)
- **< 90:** GOOD (good threshold)
- **>= 90:** EXCELLENT

### Usage

```bash
# Validate all scripts
./scripts/bootstrap-validate-scripts.sh

# Validate specific script
./scripts/bootstrap-validate-scripts.sh bootstrap-helper.sh

# Auto-fix issues where possible
./scripts/bootstrap-validate-scripts.sh --fix

# Generate JSON report
./scripts/bootstrap-validate-scripts.sh --json

# Verbose output (show info-level issues)
./scripts/bootstrap-validate-scripts.sh --verbose
```

### Output

#### Console Report
```
╔═══════════════════════════════════════════════════════╗
║     Bootstrap Script Validation                      ║
╚═══════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Validating: bootstrap-helper.sh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Checks passed: 11 / 14
  Quality score: 88/100

Warnings:
  NO_HELP: Script should provide --help
  NOT_IN_REGISTRY: Not in bootstrap-manifest.json
✓ PASSED - Good quality score
```

#### JSON Report

Located at: `logs/script-validation.json`

Format:
```json
{
  "timestamp": "2025-12-07T...",
  "summary": {
    "total": 5,
    "passed": 3,
    "warnings": 1,
    "failed": 1
  },
  "scripts": {
    "script-name.sh": {
      "score": 88,
      "critical": 0,
      "warnings": 2,
      "info": 1
    }
  }
}
```

### Exit Codes

- **0:** All scripts passed
- **1:** Critical issues found
- **2:** Warnings only

## Integration with Existing Systems

### Config Manager
- Error handler updates session.last_error_code
- Tracks session.error_count
- Logs errors to config

### Logging
- All tools use LOGS_DIR from paths.sh
- Errors logged to logs/errors.log
- Test output to logs/integration-tests/
- Validation output to logs/script-validation.json

### Test Runner
- Integration tests use existing test-runner.sh functions
- Assert functions available
- TAP format compatible

## Best Practices

### For Script Authors

1. **Always source error-handler.sh**
   ```bash
   source "${LIB_DIR}/error-handler.sh"
   enable_error_handling
   ```

2. **Use standard error codes**
   ```bash
   handle_error $ERR_DEPENDENCY_MISSING "git not found" "$0"
   exit $ERR_DEPENDENCY_MISSING
   ```

3. **Provide help text**
   ```bash
   if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
       show_help
       exit 0
   fi
   ```

4. **Run validation before committing**
   ```bash
   ./scripts/bootstrap-validate-scripts.sh my-script.sh
   ```

### For CI/CD

1. **Run validation on all scripts**
   ```bash
   ./scripts/bootstrap-validate-scripts.sh --json
   ```

2. **Run integration tests**
   ```bash
   ./tests/integration-test.sh --all --dry-run
   ```

3. **Check exit codes**
   - Fail build on critical issues
   - Warn on quality threshold violations

### For Debugging

1. **Check error logs**
   ```bash
   cat __bootbuild/logs/errors.log
   ```

2. **Run integration tests in verbose mode**
   ```bash
   ./tests/integration-test.sh --phase=1 --verbose
   ```

3. **View test workspace state**
   - Captured in logs/integration-tests/phase*-before.state
   - Diff in logs/integration-tests/phase*-diff.log

## Files Created

```
__bootbuild/
├── lib/
│   └── error-handler.sh          # Error handling library
├── tests/
│   ├── integration-test.sh       # Integration test suite
│   └── test-error-handler.sh     # Error handler unit tests
├── scripts/
│   └── bootstrap-validate-scripts.sh  # Script validation tool
├── logs/
│   ├── errors.log                # Error log
│   ├── integration-tests/        # Integration test output
│   │   ├── *.state               # State snapshots
│   │   ├── *.log                 # Execution logs
│   │   ├── integration-tests.tap # TAP format output
│   │   └── integration-test-report.md  # Test report
│   └── script-validation.json    # Validation results
└── docs/
    └── testing-infrastructure.md # This file
```

## Future Enhancements

### Error Handler
- [ ] Remote error reporting (Sentry, etc.)
- [ ] Error categorization and grouping
- [ ] Automatic recovery suggestions
- [ ] Error rate limiting

### Integration Tests
- [ ] Performance benchmarking
- [ ] Resource usage monitoring
- [ ] Parallel test execution
- [ ] Custom test fixtures

### Script Validation
- [ ] Custom rule definitions
- [ ] Auto-fix for more issues
- [ ] IDE integration
- [ ] Git hooks integration

## References

- Error codes: `lib/error-handler.sh` lines 36-47
- Test assertions: `tests/lib/test-runner.sh` lines 33-116
- Validation rules: `scripts/bootstrap-validate-scripts.sh` lines 102-340
- Manifest structure: `config/bootstrap-manifest.json`
