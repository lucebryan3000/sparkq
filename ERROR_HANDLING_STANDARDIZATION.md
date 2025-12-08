# Error Handling Standardization Report

## Overview
This document summarizes the standardization of error handling patterns across all library files in `__bootbuild/lib/`. The goal was to ensure consistent error logging and reporting across the bootstrap system.

## Standard Implemented

### Rule 1: Library Functions Use log_error + return 1
**Pattern:** All library functions that encounter errors must log them before returning.

**Format:**
```bash
if [[ ! -f "$file" ]]; then
    echo "ERROR: [LibraryName] function_name: Error description" >&2
    return 1
fi
```

### Rule 2: Error Message Format
**Format:** `ERROR: [LibraryName] function_name: description`

Examples:
- `[ConfigManager] config_get: Config file not found`
- `[ManifestCache] _init_cache_dir: Failed to create cache`
- `[Paths] BOOTSTRAP_DIR must be set`

### Rule 3: Fatal Errors Use log_fatal (Only in dependency-checker.sh)
**Pattern:** Critical validation errors that should stop execution use `log_fatal` which includes `exit 1`

**Location:** `dependency-checker.sh` line 222 (already compliant)

## Files Modified

### 1. __bootbuild/lib/config-manager.sh
**Issues Fixed:**
- Lines 23, 30: Added error prefixes `[ConfigManager]` to initialization errors
- Line 193: Added logging for `config_get` when config file not found
- Line 248: Added logging for `config_load` when config file not found
- Line 272: Added logging for `config_show` when config file not found
- Line 315: Added logging for `config_update_from_answers` when answers file not found

**Changes:**
- All `return 1` statements now preceded by descriptive error messages
- Consistent error message format with `[ConfigManager]` prefix
- Errors to stderr via `>&2` redirection

### 2. __bootbuild/lib/manifest-cache.sh
**Issues Fixed:**
- Line 27: Changed generic error to `[ManifestCache]` prefix
- Line 65-68: Added proper error logging for cache directory creation failure
- Line 122-125: Added explicit error logging in `_save_cache`
- Line 143-144: Added error logging in `_load_cache`
- Line 167: Added error logging in `get_cached_manifest` when manifest file not found

**Changes:**
- All silent `return 1` statements now have error context
- Cache operations provide detailed failure messages
- Fallback mechanisms log when they're activated

### 3. __bootbuild/lib/paths.sh
**Issues Fixed:**
- Line 29: Changed generic error to `[Paths]` prefix
- Line 37: Changed generic error to `[Paths]` prefix
- Line 85: Changed generic error to `[Paths]` prefix for `validate_safe_path`
- Line 91: Changed generic error to `[Paths]` prefix for null byte detection
- Line 125: Changed generic error to `[Paths]` prefix for `validate_path_boundary`

**Changes:**
- All error messages now consistently prefixed with `[Paths]`
- Path validation functions provide clear error context

### 4. __bootbuild/lib/validation-common.sh
**Issues Fixed:**
- Line 576: Added error logging for `show_answers_summary` when answers file not found

**Changes:**
- Silent return now includes error message
- Uses color output consistent with common.sh style

## Files Already Compliant

### __bootbuild/lib/common.sh
- Already uses proper error logging (log_error, log_warning, etc.)
- All file operations log errors appropriately
- Status: ✓ FULLY COMPLIANT

### __bootbuild/lib/dependency-checker.sh
- Already uses `log_fatal` for critical errors (line 222)
- Uses proper error tracking arrays for reporting
- Status: ✓ FULLY COMPLIANT

### __bootbuild/lib/template-utils.sh
- All file operations properly log errors
- Uses color output for user feedback
- Status: ✓ FULLY COMPLIANT

### __bootbuild/lib/json-validator.sh
- Already provides detailed error messages
- Uses color output for clarity
- Status: ✓ FULLY COMPLIANT

### Other library files
- cache-manager.sh: Uses appropriate error handling for cache operations
- docker-utils.sh, nodejs-utils.sh, etc.: Already have proper error logging
- Status: ✓ FULLY COMPLIANT

## Error Handling Patterns Summary

| Pattern | Usage | Example |
|---------|-------|---------|
| `echo "ERROR: [Lib] msg" >&2; return 1` | Library function errors | Most common pattern |
| `log_error "msg"; return 1` | When log_error is sourced | Fallback if common.sh loaded |
| `log_fatal "msg"` | Critical exit errors | Only in dependency-checker.sh |
| Silent `return 1` | Status check only | Conditional tests, not errors |

## Validation

All modified files have been validated for:
1. ✓ Bash syntax correctness (`bash -n`)
2. ✓ Consistent error message format
3. ✓ Proper stderr redirection (`>&2`)
4. ✓ No `exit` in library functions (except log_fatal)
5. ✓ No hardcoded paths or absolute references

## Testing Results

```
✓ config-manager.sh: syntax OK
✓ manifest-cache.sh: syntax OK
✓ paths.sh: syntax OK
✓ validation-common.sh: syntax OK
```

## Impact

### User Experience
- Errors now provide clear context about which library and function failed
- Error messages help with debugging and issue reporting
- Consistent formatting makes logs easier to parse

### Developer Experience
- Clear patterns for error handling in new code
- Error prefixes make it easy to identify problem source
- Stderr redirection ensures errors don't interfere with stdout data

### Maintenance
- Standardized error format reduces cognitive load when reading code
- New developers can follow established patterns
- Search/grep for errors becomes more reliable

## Migration Notes

For any new library files:
1. Use `ERROR: [LibraryName]` prefix for all error messages
2. Always log before returning 1 from functions
3. Use `>&2` to redirect all errors to stderr
4. Never use `exit` in library functions
5. Reserve `log_fatal` (which exits) for critical validation only

## See Also
- `__bootbuild/lib/common.sh` - Logging functions reference
- `__bootbuild/lib/dependency-checker.sh` - Example of fatal error handling
- `__bootbuild/lib/config-manager.sh` - Example of comprehensive error handling
