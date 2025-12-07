# Bootstrap Script Standardization Checklist

**Version**: 2.0
**Date**: 2025-12-07
**Purpose**: Comprehensive checklist for migrating bootstrap scripts to use shared library structure

---

## Core Requirements

### 1. No Hard-Coded Paths

**CRITICAL**: All paths must be derived from environment variables set by `init_script()`

**Available Path Variables** (set by `init_script()`):
- `${BOOTSTRAP_DIR}` - Root of bootstrap system
- `${TEMPLATES_DIR}` - Template files location
- `${LIB_DIR}` - Shared library location
- `${PROJECT_ROOT}` - Target project directory (from argument or current dir)

**Migration**:
```bash
# BEFORE (WRONG):
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cat "$TEMPLATE_DIR/templates/root/.gitignore"

# AFTER (CORRECT):
source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-git"
PROJECT_ROOT=$(get_project_root "${1:-.}")
cat "${TEMPLATES_DIR}/root/.gitignore"
```

**Checklist**:
- [ ] No hardcoded `/path/to/...` strings
- [ ] No manual `$(cd "$(dirname ...)" && pwd)` calculations
- [ ] All template references use `${TEMPLATES_DIR}`
- [ ] All library references use `${LIB_DIR}`
- [ ] Project target uses `${PROJECT_ROOT}`

---

### 2. Configuration in bootstrap.config

**CRITICAL**: All dynamic values must come from `bootstrap.config`, not hardcoded in scripts

**Pattern**:
```bash
# Source config manager
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Read values from config (with fallback defaults)
PROJECT_NAME=$(config_get "project.name" "my-app")
GIT_USER=$(config_get "git.user_name" "$(detect_git_user)")
DOCKER_DB=$(config_get "docker.database_type" "postgres")
```

**Checklist**:
- [ ] Script reads from `[{name}]` section in bootstrap.config
- [ ] Uses `config_get "section.key" "default"` for all dynamic values
- [ ] Config section documented in playbook
- [ ] Default values are sensible for new projects
- [ ] Detection functions used as fallback defaults

---

### 3. Shared Library Structure

**CRITICAL**: Use provided functions, don't duplicate code

**Required Sources**:
```bash
# Minimal (all scripts):
source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-{name}"

# If using templates with variable replacement:
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"

# If using interactive questions:
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"
```

**Checklist**:
- [ ] Sources `lib/common.sh`
- [ ] Calls `init_script` with script name
- [ ] Sources additional libs only if needed
- [ ] Does NOT redefine library functions

---

## Script Structure Standardization

### Header Section

**Standard Header Template**:
```bash
#!/bin/bash

# ===================================================================
# bootstrap-{name}.sh
#
# {One-line purpose description}
# Creates: {comma-separated list of files}
# Config: [{section}] section in bootstrap.config (or "None" if static)
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script (sets TEMPLATES_DIR, LIB_DIR, loads config)
init_script "bootstrap-{name}"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-{name}"
```

**Checklist**:
- [ ] Change `set -e` to `set -euo pipefail`
- [ ] Add proper header comment with purpose, files, config section
- [ ] Define `SCRIPT_DIR` and `BOOTSTRAP_DIR`
- [ ] Source `common.sh` from `${BOOTSTRAP_DIR}/lib/`
- [ ] Call `init_script` with script name
- [ ] Use `get_project_root` for `PROJECT_ROOT`
- [ ] Define `SCRIPT_NAME` variable

---

### Remove Duplicate Code

**Functions to REMOVE** (provided by `lib/common.sh`):
```bash
# DELETE THESE - they're in common.sh:
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { ... }
log_success() { ... }
log_warning() { ... }
log_error() { ... }

backup_file() { ... }
verify_file() { ... }
cleanup_on_error() { ... }
```

**Checklist**:
- [ ] Remove all color definitions (RED, GREEN, YELLOW, BLUE, NC)
- [ ] Remove `log_info()` function
- [ ] Remove `log_success()` function
- [ ] Remove `log_warning()` function
- [ ] Remove `log_error()` function
- [ ] Remove `backup_file()` function
- [ ] Remove `verify_file()` function
- [ ] Remove `cleanup_on_error()` trap handler
- [ ] Remove any other functions present in `lib/common.sh`

---

### Pre-Execution Confirmation

**Standard Pattern**:
```bash
# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Human-Readable Description" \
    "file1.ext" \
    "file2.ext" \
    "directory/" \
    "file3.ext"
```

**Output Example**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TypeScript Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This script will create:
  • tsconfig.json
  • next.config.js
  • babel.config.js
  • vite.config.ts
  • src/ (directory structure)

→ Proceed with TypeScript Configuration? (Y/n):
```

**Checklist**:
- [ ] Add `pre_execution_confirm` call BEFORE any file operations
- [ ] First param: `$SCRIPT_NAME`
- [ ] Second param: Human-readable description (title case)
- [ ] Remaining params: List of files/directories to create
- [ ] Auto-approves in CI or with `BOOTSTRAP_YES=true`

---

### Validation Section

**Standard Pattern**:
```bash
# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check required tools
require_command "git" || log_fatal "git is required"

# Warn about optional tools
if ! has_jq; then
    track_warning "jq not installed - JSON validation will be skipped"
    log_warning "jq not installed - JSON validation will be skipped"
    log_info "Install with: sudo apt install jq (or brew install jq)"
fi

log_success "Environment validated"
```

**Function Mappings**:
| Old Pattern | New Pattern |
|-------------|-------------|
| `if [[ ! -d "$dir" ]]; then log_error "..."; exit 1` | `require_dir "$dir" \|\| log_fatal "..."` |
| `if [[ ! -w "$path" ]]; then log_error "..."; exit 1` | `is_writable "$path" \|\| log_fatal "..."` |
| `if ! command -v cmd &>/dev/null; then ...` | `require_command "cmd" \|\| log_fatal "..."` |
| `log_error "..."; exit 1` | `log_fatal "..."` |

**Checklist**:
- [ ] Replace directory existence checks with `require_dir`
- [ ] Replace writable checks with `is_writable`
- [ ] Replace command checks with `require_command` (for required tools)
- [ ] Use `has_jq` (or similar) for optional tools with warnings
- [ ] All fatal errors use `log_fatal` (not `log_error; exit 1`)
- [ ] Add `track_warning` for optional tool unavailability
- [ ] Log success after validation completes

---

### File Creation Pattern

**Standard Pattern**:
```bash
# ===================================================================
# Create {filename}
# ===================================================================

log_info "Creating {filename}..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/{filename}"; then
    log_warning "{filename} already exists, skipping"
    track_skipped "{filename}"
else
    if cat > "$PROJECT_ROOT/{filename}" << 'EOFMARKER'
{file contents here}
EOFMARKER
    then
        verify_file "$PROJECT_ROOT/{filename}"
        track_created "{filename}"
        log_file_created "$SCRIPT_NAME" "{filename}"

        # Optional: Validate JSON if jq available
        if has_jq && [[ "{filename}" == *.json ]]; then
            source "${LIB_DIR}/json-validator.sh"
            if validate_json_file "$PROJECT_ROOT/{filename}" > /dev/null 2>&1; then
                log_success "JSON syntax validated"
            else
                log_warning "JSON syntax validation failed - please check file manually"
            fi
        fi
    else
        log_fatal "Failed to create {filename}"
    fi
fi
```

**Function Mappings**:
| Old Pattern | New Pattern |
|-------------|-------------|
| `[[ -f "$file" ]]` | `file_exists "$file"` |
| `[[ -d "$dir" ]]` | `dir_exists "$dir"` |
| `mkdir -p "$dir"` | `ensure_dir "$dir"` |
| Manual backup before overwrite | `backup_file "$file"` with `is_auto_approved "backup_existing_files"` |

**Checklist**:
- [ ] Use `file_exists` to check if file already exists
- [ ] Add `track_skipped` when file exists and is skipped
- [ ] Use `verify_file` after successful creation
- [ ] Add `track_created` after successful creation
- [ ] Add `log_file_created "$SCRIPT_NAME" "filename"` for central logging
- [ ] Use `log_fatal` on creation failure
- [ ] Validate JSON files if `jq` available
- [ ] Use unique EOF markers (e.g., `EOFGITIGNORE`, `EOFTSCONFIG`)

---

### Directory Creation Pattern

**Standard Pattern**:
```bash
log_info "Creating {directory} structure..."

# Create base directory
ensure_dir "$PROJECT_ROOT/{directory}"
log_dir_created "$SCRIPT_NAME" "{directory}/"

# Create subdirectories
for dir in components hooks lib types services; do
    if dir_exists "$PROJECT_ROOT/{directory}/$dir"; then
        log_debug "{directory}/$dir already exists, skipping"
    else
        ensure_dir "$PROJECT_ROOT/{directory}/$dir"
        log_dir_created "$SCRIPT_NAME" "{directory}/$dir"
    fi
done

log_success "{Directory} structure created"
```

**Checklist**:
- [ ] Use `ensure_dir` instead of `mkdir -p`
- [ ] Add `log_dir_created` for each directory created
- [ ] Check existence with `dir_exists` before creating
- [ ] Use `log_debug` for skipped directories

---

### Summary Section

**Standard Pattern**:
```bash
# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "{Description} complete!"
echo ""
echo "Next steps:"
echo "  1. {First essential step}"
echo "  2. {Second essential step}"
echo "  3. {Third essential step}"
echo ""
echo "Configuration notes:"
echo "  - {Important note 1}"
echo "  - {Important note 2}"
echo ""

show_log_location
```

**Checklist**:
- [ ] Add `log_script_complete` with file count
- [ ] Call `show_summary` (displays created/skipped/warnings)
- [ ] Add `show_log_location` at end
- [ ] Simplify "Next steps" to 3-4 essential items (not 10+)
- [ ] Remove verbose explanations (keep concise)
- [ ] Remove unnecessary echoes and formatting

---

## Progress Tracking

**All scripts MUST track their operations:**

```bash
# Track successful file creation
track_created "filename"

# Track skipped files (already exist)
track_skipped "filename"

# Track warnings (non-fatal issues)
track_warning "jq not installed - validation skipped"

# These populate arrays shown by show_summary:
# - _BOOTSTRAP_CREATED_FILES
# - _BOOTSTRAP_SKIPPED_FILES
# - _BOOTSTRAP_WARNINGS
```

**Checklist**:
- [ ] Every created file calls `track_created "filename"`
- [ ] Every skipped file calls `track_skipped "filename"`
- [ ] Every warning calls `track_warning "message"`
- [ ] `show_summary` called at end of script

---

## Centralized Logging

**All file operations MUST be logged to `bootstrap.log`:**

```bash
# Log individual file creation
log_file_created "$SCRIPT_NAME" "filename"

# Log directory creation
log_dir_created "$SCRIPT_NAME" "dirname/"

# Log script completion
log_script_complete "$SCRIPT_NAME" "summary message"

# Log script failure (automatically called by log_fatal)
log_script_failed "$SCRIPT_NAME" "error message"
```

**Log Format**:
```
[2025-12-07T10:30:15] bootstrap-git: Created: .gitignore
[2025-12-07T10:30:15] bootstrap-git: Created: .gitattributes
[2025-12-07T10:30:16] bootstrap-git: ✓ Complete: 2 files created

[2025-12-07T10:30:20] bootstrap-typescript: Created: tsconfig.json
[2025-12-07T10:30:20] bootstrap-typescript: Created: next.config.js
```

**Checklist**:
- [ ] Call `log_file_created` for EVERY file created
- [ ] Call `log_dir_created` for EVERY directory created
- [ ] Call `log_script_complete` at end with summary
- [ ] Blank line automatically added after each script

---

## Validation & Testing

**Syntax Validation**:
```bash
bash -n /path/to/bootstrap-{name}.sh
```

**Checklist**:
- [ ] Syntax validation passes (`bash -n`)
- [ ] Script runs without errors on fresh directory
- [ ] Pre-execution confirmation displays correctly
- [ ] Files are created with correct content
- [ ] Existing files are skipped (not overwritten)
- [ ] JSON validation runs if `jq` available
- [ ] Warnings displayed for missing optional tools
- [ ] Summary shows created/skipped/warnings
- [ ] `bootstrap.log` contains all operations
- [ ] Log location displayed at end
- [ ] Script exits cleanly on success (exit 0)
- [ ] Script exits with error code on failure (exit 1)

---

## Quick Reference: Function Mappings

### Path Variables
| Old Pattern | New Pattern |
|-------------|-------------|
| `TEMPLATE_DIR="$(cd ...)"` | `${TEMPLATES_DIR}` (from `init_script`) |
| `"$(dirname $0)/../templates"` | `${TEMPLATES_DIR}` |
| Manual path calculations | `${BOOTSTRAP_DIR}`, `${LIB_DIR}`, `${PROJECT_ROOT}` |

### Validation Functions
| Old Pattern | New Pattern |
|-------------|-------------|
| `[[ -f "$file" ]]` | `file_exists "$file"` |
| `[[ -d "$dir" ]]` | `dir_exists "$dir"` |
| `[[ -w "$path" ]]` | `is_writable "$path"` |
| `command -v cmd &>/dev/null` | `require_command "cmd"` or `has_jq` |
| `if [[ ! -d ... ]]; exit 1` | `require_dir "$dir" \|\| log_fatal "..."` |

### Logging Functions
| Old Pattern | New Pattern |
|-------------|-------------|
| `log_error "msg"; exit 1` | `log_fatal "msg"` |
| Manual echo to log | `log_file_created "$SCRIPT_NAME" "file"` |
| Manual directory logging | `log_dir_created "$SCRIPT_NAME" "dir"` |

### File Operations
| Old Pattern | New Pattern |
|-------------|-------------|
| `mkdir -p "$dir"` | `ensure_dir "$dir"` |
| Manual backup logic | `backup_file "$file"` |
| Manual verification | `verify_file "$file"` |
| No tracking | `track_created "file"`, `track_skipped "file"` |

### Script Structure
| Old Pattern | New Pattern |
|-------------|-------------|
| `set -e` | `set -euo pipefail` |
| No pre-execution confirm | `pre_execution_confirm "$SCRIPT_NAME" "Desc" "file1" "file2"` |
| Manual summary | `show_summary` |
| No log location | `show_log_location` |

---

## Migration Workflow

**For each script to migrate**:

1. **Backup**: `cp bootstrap-{name}.sh bootstrap-{name}.sh.backup`
2. **Read**: Review current script structure
3. **Header**: Update to standard header template
4. **Remove**: Delete duplicate functions and color definitions
5. **Confirm**: Add pre_execution_confirm
6. **Validate**: Update validation section with new functions
7. **Files**: Update file creation pattern with tracking
8. **Summary**: Update summary section with new functions
9. **Test**: Run `bash -n` syntax check
10. **Manual Test**: Run on test directory
11. **Verify**: Check bootstrap.log entries
12. **Commit**: Git commit with clear message

---

## Success Criteria

A fully migrated script MUST:

- [ ] Pass `bash -n` syntax validation
- [ ] Use `set -euo pipefail`
- [ ] Source `lib/common.sh` and call `init_script`
- [ ] Use `${BOOTSTRAP_DIR}`, `${TEMPLATES_DIR}`, `${LIB_DIR}`, `${PROJECT_ROOT}`
- [ ] Have NO hardcoded paths
- [ ] Have NO duplicate function definitions
- [ ] Call `pre_execution_confirm` before operations
- [ ] Use `require_dir`, `is_writable`, `require_command` for validation
- [ ] Use `file_exists`, `dir_exists` for existence checks
- [ ] Call `track_created`, `track_skipped`, `track_warning`
- [ ] Call `log_file_created`, `log_dir_created` for all operations
- [ ] Call `log_script_complete` at end
- [ ] Call `show_summary` and `show_log_location`
- [ ] Create entries in `bootstrap.log`
- [ ] Exit cleanly on success (exit 0)
- [ ] Exit with error on failure (via `log_fatal`)

---

**Version History**:
- v2.0 (2025-12-07): Complete standardization guide with all patterns
- v1.0: Initial checklist

**Maintainer**: Bootstrap System Team
**Last Review**: 2025-12-07
