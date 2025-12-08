# Input Validation Improvements

**Date**: 2025-12-07
**Status**: Completed
**Scope**: Critical library functions across 5 files

## Overview

Comprehensive input validation has been added to critical functions across the bootstrap library files to prevent failures from invalid inputs, missing dependencies, and permission issues.

## Files Modified

### 1. config-manager.sh

#### `config_get()`
**Added validations:**
- Key is not empty
- Key follows 'section.key' format (contains dot)
- Config file exists before attempting to read

**Error handling:**
- Returns default value on validation failure
- Logs descriptive error messages to stderr

#### `config_set()`
**Added validations:**
- Key is not empty
- Key follows 'section.key' format
- Value parameter is provided (allows empty string)
- Config file path is not empty
- Directory exists and is writable
- Config file is writable (if it exists)
- Validates successful file write operation

**Error handling:**
- Creates config if doesn't exist (via init_config)
- Cleans up temp files on failure
- Returns explicit error codes

### 2. validation-common.sh

#### `validate_answer()` (NEW FUNCTION)
**Added comprehensive validation:**
- Variable name is not empty
- Value parameter is provided
- Answers file path is validated
- Directory exists and is writable
- File is writable (if it exists)
- Write operation succeeds

**Purpose:**
- Replaces direct writes to answers file with validated writes
- Ensures directory permissions before writing
- Provides clear error messages on failure

### 3. question-engine.sh

#### `_process_question()`
**Added validations:**
- Validates `config_set()` return value before adding to session_answers
- Logs warning if config save fails
- Continues execution rather than silently failing

**Error handling:**
- Graceful degradation on save failure
- User feedback via log_warning

#### `question_engine_run()`
**Added validations:**
- script_key parameter is not empty
- Returns error code 1 if validation fails

**Error handling:**
- Clear error message via log_error
- Early return prevents execution with invalid state

### 4. template-utils.sh

#### `replace_in_file()`
**Added validations:**
- File path parameter is provided
- Placeholder parameter is provided
- File exists
- File is writable

**Existing validations maintained:**
- Backup creation verification
- Replacement occurrence verification
- Atomic file operations

#### `update_json_field()`
**Added validations:**
- File path parameter is provided
- Field path parameter is provided
- Python3 is installed before use
- File exists
- File is writable

**Existing validations maintained:**
- JSON validity check before modification
- Backup creation and verification
- Atomic operations with temp files

#### `create_env_file()`
**Added validations:**
- File path parameter is provided
- Directory exists
- Directory is writable
- Existing file is writable (if replacing)
- File creation succeeded
- Each write operation succeeds

**Error handling:**
- Early validation before any file operations
- Verification after file creation
- Per-line write validation

### 5. nodejs-utils.sh

#### `detect_package_manager()`
**Major improvement:**
- **BREAKING FIX**: Now returns empty string if package manager not installed
- Validates command exists before returning package manager name
- Checks all lockfile-based detections
- Validates packageManager field from package.json

**Previous behavior:**
- Would return "npm" even if npm was not installed
- Could cause silent failures in downstream functions

**New behavior:**
- Returns empty string if no package manager available
- Calling functions can detect and handle missing package manager

#### `install_dependencies()`
**Added validations:**
- Project directory exists
- package.json exists
- package.json is valid JSON (when python3 available)
- Package manager was detected (not empty)
- Package manager command exists in PATH

**Error handling:**
- Graceful degradation if python3 unavailable for JSON validation
- Clear error messages for each validation failure
- Early return on validation failures

## Validation Patterns Used

### Path Validation
```bash
[[ -z "$file" ]] && { log_error "File path required"; return 1; }
[[ ! -f "$file" ]] && { log_error "File not found: $file"; return 1; }
[[ ! -w "$file" ]] && { log_error "File not writable: $file"; return 1; }
```

### Directory Validation
```bash
local dir=$(dirname "$file")
[[ ! -d "$dir" ]] && { log_error "Directory does not exist: $dir"; return 1; }
[[ ! -w "$dir" ]] && { log_error "Directory not writable: $dir"; return 1; }
```

### Command Availability
```bash
command -v python3 &>/dev/null || { log_error "python3 required"; return 1; }
```

### Operation Success Validation
```bash
if operation; then
    return 0
else
    log_error "Operation failed"
    cleanup
    return 1
fi
```

### Parameter Validation
```bash
[[ -z "$param" ]] && { log_error "Parameter required"; return 1; }
[[ $# -lt 2 ]] && { log_error "Value required"; return 1; }
```

## Benefits

### Robustness
- Functions fail fast with clear error messages
- No silent failures or undefined behavior
- Prevents cascading failures from invalid inputs

### Debugging
- Consistent error message format with function context
- All errors logged to stderr
- Return codes indicate success/failure state

### Security
- Validates file permissions before write operations
- Prevents writes to unintended locations
- Validates command existence before execution

### User Experience
- Clear error messages guide troubleshooting
- Validation happens before any destructive operations
- Graceful degradation when optional dependencies unavailable

## Testing Recommendations

### Config Manager
```bash
# Test config_get with invalid inputs
config_get "" "default"  # Should error: empty key
config_get "nokey" "default"  # Should error: no dot in key
config_get "section.key" "default" "/nonexistent/file"  # Should return default

# Test config_set with invalid inputs
config_set "" "value"  # Should error: empty key
config_set "key" ""  # Should allow empty value
config_set "section.key" "value" "/readonly/path/file"  # Should error: not writable
```

### Template Utils
```bash
# Test replace_in_file with invalid inputs
replace_in_file "" "placeholder" "value"  # Should error: empty file path
replace_in_file "/nonexistent" "placeholder" "value"  # Should error: file not found
replace_in_file "/readonly/file" "placeholder" "value"  # Should error: not writable

# Test update_json_field without python3
# Temporarily rename python3 to test error handling
```

### Node.js Utils
```bash
# Test detect_package_manager without npm installed
# Should return empty string, not "npm"

# Test install_dependencies with invalid package.json
echo "invalid json" > package.json
install_dependencies .  # Should error: invalid JSON
```

## Migration Notes

### Breaking Changes

**nodejs-utils.sh - detect_package_manager()**

**Before:**
```bash
pm=$(detect_package_manager)
npm install  # Would fail silently if npm not installed
```

**After:**
```bash
pm=$(detect_package_manager)
if [[ -z "$pm" ]]; then
    log_error "No package manager available"
    exit 1
fi
$pm install  # Safe to use
```

All calling code should check for empty return value from `detect_package_manager()`.

### Non-Breaking Changes

All other validation additions are non-breaking:
- Functions return error codes consistently
- Error messages provide actionable feedback
- Existing successful code paths unchanged

## Future Improvements

1. **Validation library**: Extract common validation patterns into shared functions
2. **Schema validation**: Add JSON schema validation for config files
3. **Dry-run mode**: Add `--dry-run` flag to validation-sensitive functions
4. **Validation tests**: Create comprehensive test suite for all validation paths
5. **Error codes**: Standardize error codes across all functions (1=validation, 2=operation, etc.)

## Related Documentation

- `/home/luce/.claude/CLAUDE.md` - Defensive deletion protocol (inspiration for validation approach)
- `lib/common.sh` - Shared logging functions used in validation
- `config/bootstrap-questions.json` - Question engine data structure

## Commit Message

```
feat(lib): add comprehensive input validation to critical functions

Add robust validation to prevent failures from invalid inputs:

- config-manager.sh: validate keys, paths, and permissions
- validation-common.sh: new validate_answer() with write checks
- question-engine.sh: validate config_set operations
- template-utils.sh: validate parameters and Python3 availability
- nodejs-utils.sh: fix detect_package_manager to check command exists

Breaking: detect_package_manager() returns empty string if not installed
```
