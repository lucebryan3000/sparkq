---
title: "Migrating Bootstrap Scripts to Standardized Pattern"
aliases: ["standardize bootstrap script", "migrate script", "update bootstrap"]
related:
  - ../references/REFERENCE_LIBRARY.md
  - ../references/REFERENCE_CONFIG.md
review_cycle: quarterly
version: 2.0
---

# Playbook: Migrating Bootstrap Scripts to Standardized Pattern

When you need to update an existing bootstrap script to follow the standardized pattern using the shared library (`lib/common.sh`).

---

## When to Use This Playbook

- **You have an old bootstrap script** that predates the shared library system
- **You want to reduce code duplication** by using common functions
- **You need consistent logging and file tracking** across all bootstrap scripts
- **You're refactoring scripts** to use configuration-driven values
- **You want to add pre-execution confirmation** before file operations

---

## Before You Start

### Prerequisites

- [ ] Backup of the original script exists
- [ ] `lib/common.sh` exists and has been reviewed
- [ ] `config/bootstrap.config` exists
- [ ] Understanding of bash scripting
- [ ] Access to test project directory

### Time Estimate

- Simple script (5-10 functions): ~15-20 minutes
- Medium script (10-20 functions): ~30-45 minutes
- Complex script (20+ functions): ~1-2 hours

---

## Step 1: Understand What "Standardized" Means

A standardized bootstrap script:

1. **Uses shared library functions** instead of duplicating code
2. **Reads configuration** from `bootstrap.config` instead of hardcoding values
3. **Uses path variables** (`${BOOTSTRAP_DIR}`, `${TEMPLATES_DIR}`, `${PROJECT_ROOT}`) instead of hardcoded paths
4. **Tracks file operations** (created, skipped, warnings) with `track_*` functions
5. **Logs to bootstrap.log** via centralized logging functions
6. **Confirms actions** before making changes with `pre_execution_confirm`
7. **Validates requirements** with `require_*` functions
8. **Follows standard structure** (header, setup, validation, main, summary)

### Example: Before vs After

**BEFORE** (duplicated code):
```bash
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${BLUE}→${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

# Hardcoded values
GIT_EMAIL="default@example.com"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/../templates/root/.gitignore"

if [[ ! -d "$1" ]]; then
  echo "Error: Directory not found"
  exit 1
fi

# Manual operations
cp "$TEMPLATE_PATH" "$1/.gitignore"
echo "Created .gitignore"
```

**AFTER** (shared library):
```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-git"
PROJECT_ROOT=$(get_project_root "${1:-.}")

GIT_EMAIL=$(config_get "git.email" "default@example.com")
pre_execution_confirm "bootstrap-git" "Git Configuration" ".gitignore"

require_dir "$PROJECT_ROOT" || log_fatal "Directory not found: $PROJECT_ROOT"

copy_template "root/.gitignore" "$PROJECT_ROOT/.gitignore"
log_file_created "bootstrap-git" ".gitignore"
track_created ".gitignore"

log_script_complete "bootstrap-git" "1 file created"
show_summary
show_log_location
```

**Key changes:**
- Remove color definitions (use `log_*` functions)
- Remove duplicate functions (use `lib/common.sh`)
- Use `init_script` for setup
- Use `config_get` for configurable values
- Use `pre_execution_confirm` before operations
- Use `copy_template` instead of `cp`
- Use `track_created` for operation tracking
- Use `log_file_created` for centralized logging

---

## Step 2: Set Up Script Environment

### Create Header Section

Replace your script header with the standard template:

```bash
#!/bin/bash

# ===================================================================
# bootstrap-{name}.sh
#
# {One-line purpose: what does this script do?}
# Creates: {comma-separated list of files/dirs created}
# Config: [{section}] section in bootstrap.config (or "None" if static)
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library (required by all scripts)
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script (sets up paths, loads config)
init_script "bootstrap-{name}"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script name for logging
SCRIPT_NAME="bootstrap-{name}"
```

**Checklist:**
- [ ] Shebang is `#!/bin/bash`
- [ ] Header comment includes purpose, files created, config section
- [ ] `set -euo pipefail` (strict mode enabled)
- [ ] `SCRIPT_DIR` calculated correctly
- [ ] `BOOTSTRAP_DIR` points to bootstrap root
- [ ] `source "${BOOTSTRAP_DIR}/lib/common.sh"` is first source
- [ ] `init_script "bootstrap-{name}"` called with script name
- [ ] `PROJECT_ROOT=$(get_project_root "${1:-.}")` for project path
- [ ] `SCRIPT_NAME` variable defined

---

## Step 3: Remove Duplicate Functions

**DELETE these sections** - they're all provided by `lib/common.sh`:

### Color Definitions to Remove
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
```

### Functions to Remove

- `log_info()`
- `log_success()`
- `log_warning()`
- `log_error()`
- `backup_file()`
- `verify_file()`
- `cleanup_on_error()` trap handler
- Any other functions present in `lib/common.sh`

**Verification:**
```bash
# Check your script for duplicate functions
grep -n "^log_info()" bootstrap-{name}.sh  # Should return empty
grep -n "^RED=" bootstrap-{name}.sh        # Should return empty
```

**Checklist:**
- [ ] All color variables removed
- [ ] All `log_*` functions removed
- [ ] All file operation functions removed
- [ ] No duplicate trap handlers

---

## Step 4: Replace Manual Path Calculations

**Find and replace** all hardcoded or manually calculated paths:

### Path Variables Available

After `init_script` is called, these variables are available:

```bash
${BOOTSTRAP_DIR}    # Root of bootstrap system (e.g., /path/to/bootstrap)
${TEMPLATES_DIR}    # Template files location (e.g., /path/to/bootstrap/templates)
${LIB_DIR}          # Shared library location (e.g., /path/to/bootstrap/lib)
${PROJECT_ROOT}     # Target project directory (from argument)
```

### Replacement Patterns

| Old Pattern | New Pattern |
|-------------|-------------|
| `TEMPLATE_DIR="$(cd ... && pwd)"` | `${TEMPLATES_DIR}` |
| `"$(dirname $0)/../templates"` | `${TEMPLATES_DIR}` |
| Manual path calculations | `${BOOTSTRAP_DIR}`, `${TEMPLATES_DIR}`, `${PROJECT_ROOT}` |

### Examples

```bash
# BEFORE
TEMPLATE_FILE="$SCRIPT_DIR/../templates/root/.gitignore"
cat "$TEMPLATE_FILE" > "$1/.gitignore"

# AFTER
copy_template "root/.gitignore" "$PROJECT_ROOT/.gitignore"
```

**Checklist:**
- [ ] No hardcoded `/path/to/...` strings
- [ ] No manual `$(cd "$(dirname..." calculations`
- [ ] All template paths use `${TEMPLATES_DIR}`
- [ ] All library paths use `${LIB_DIR}`
- [ ] Project output paths use `${PROJECT_ROOT}`

---

## Step 5: Add Configuration Support

### Read Values from bootstrap.config

Instead of hardcoding values, read them from configuration:

```bash
# After init_script is called, use config_get:

GIT_EMAIL=$(config_get "git.email" "default@example.com")
GIT_NAME=$(config_get "git.name" "Developer")
DOCKER_VERSION=$(config_get "docker.version" "latest")

# Syntax: config_get "section.key" "default_value"
```

### Add Config Section to bootstrap.config

If your script uses configuration, add a section to `config/bootstrap.config`:

```ini
[{name}]
enabled=true
key1=value1
key2=value2
```

**Examples:**

```ini
[git]
enabled=true
email=dev@example.com
name=Developer Name
init_repo=true

[docker]
enabled=true
version=latest
compose_version=2
```

**Checklist:**
- [ ] Identified all hardcoded values
- [ ] Replaced hardcoded values with `config_get` calls
- [ ] Added config section to `bootstrap.config`
- [ ] Provided sensible default values
- [ ] Documented all config options in this playbook

---

## Step 6: Add Pre-Execution Confirmation

### Show User What Will Happen

Before making any changes, call `pre_execution_confirm`:

```bash
# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    ".gitignore"
    ".gitattributes"
    ".github/workflows/ci.yml"
)

pre_execution_confirm "$SCRIPT_NAME" "Git Configuration" "${FILES_TO_CREATE[@]}"
```

### Output Example

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Git Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This script will create:
  • .gitignore
  • .gitattributes
  • .github/workflows/ci.yml

→ Proceed with Git Configuration? (Y/n): y
```

**Checklist:**
- [ ] `pre_execution_confirm` called before ANY file operations
- [ ] First parameter: `$SCRIPT_NAME`
- [ ] Second parameter: Human-readable description
- [ ] Remaining parameters: List of files/directories to create
- [ ] User can approve or cancel before changes

---

## Step 7: Replace Validation Patterns

### Use Library Validation Functions

Replace manual validation with library functions:

```bash
# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory exists and is writable
require_dir "$PROJECT_ROOT" || log_fatal "Directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Cannot write to: $PROJECT_ROOT"

# Check required tools
require_command "git" || log_fatal "git is required"
require_command "node" || log_fatal "node is required"

# Check optional tools (warn but don't fail)
if ! has_jq; then
    track_warning "jq not installed - JSON validation will be skipped"
    log_warning "jq not installed - install with: apt install jq"
fi

log_success "Environment validated"
```

### Validation Function Reference

| Function | Purpose | Returns |
|----------|---------|---------|
| `require_dir "/path"` | Exit if directory doesn't exist | 0=exists, 1=missing |
| `require_command "cmd"` | Exit if command not in PATH | 0=found, 1=missing |
| `is_writable "/path"` | Check if path is writable | 0=writable, 1=not |
| `file_exists "/path/file"` | Check if file exists | 0=yes, 1=no |
| `dir_exists "/path"` | Check if directory exists | 0=yes, 1=no |
| `has_jq` | Check if jq is available | 0=yes, 1=no |

**Checklist:**
- [ ] Replaced `[[ -d ... ]]` with `dir_exists` or `require_dir`
- [ ] Replaced `[[ -w ... ]]` with `is_writable`
- [ ] Replaced `command -v` checks with `require_command` or `has_*`
- [ ] Using `log_fatal` instead of `log_error; exit 1`
- [ ] Added `track_warning` for optional tool unavailability

---

## Step 8: Replace File Operations

### Use Library Functions for File Creation

```bash
# ===================================================================
# Create .gitignore
# ===================================================================

log_info "Creating .gitignore..."

if file_exists "$PROJECT_ROOT/.gitignore"; then
    log_warning ".gitignore already exists, skipping"
    track_skipped ".gitignore"
else
    if cat > "$PROJECT_ROOT/.gitignore" << 'EOFGITIGNORE'
node_modules/
dist/
build/
.env.local
.DS_Store
EOFGITIGNORE
    then
        verify_file "$PROJECT_ROOT/.gitignore"
        track_created ".gitignore"
        log_file_created "$SCRIPT_NAME" ".gitignore"
    else
        log_fatal "Failed to create .gitignore"
    fi
fi
```

### Directory Creation

```bash
log_info "Creating directory structure..."

ensure_dir "$PROJECT_ROOT/src"
log_dir_created "$SCRIPT_NAME" "src/"

for subdir in components hooks lib types; do
    if ! dir_exists "$PROJECT_ROOT/src/$subdir"; then
        ensure_dir "$PROJECT_ROOT/src/$subdir"
        log_dir_created "$SCRIPT_NAME" "src/$subdir"
    fi
done
```

### Operation Function Reference

| Function | Purpose |
|----------|---------|
| `copy_template "rel/path" "dst"` | Copy template file with logging |
| `ensure_dir "/path"` | Create directory with logging |
| `backup_file "/path/file"` | Backup existing file |
| `verify_file "/path/file"` | Check file created successfully |
| `file_exists "/path/file"` | Check if file exists |
| `dir_exists "/path"` | Check if directory exists |

**Important: Unique EOF Markers**

When using heredoc (`<< 'EOF'`), use unique markers to avoid conflicts:

```bash
# GOOD - unique markers
cat > file.json << 'EOFJSON'
{ "json": "content" }
EOFJSON

cat > file.gitignore << 'EOFGITIGNORE'
*.log
EOFGITIGNORE

# BAD - reusing EOF (causes syntax errors)
cat > file1 << 'EOF'
content1
EOF
cat > file2 << 'EOF'
content2
EOF
```

**Checklist:**
- [ ] Replaced `[[ -f ... ]]` with `file_exists`
- [ ] Replaced `mkdir -p` with `ensure_dir`
- [ ] Replaced `cp` with `copy_template`
- [ ] Added `verify_file` after creation
- [ ] Added `track_created` after successful operations
- [ ] Added `track_skipped` when files exist
- [ ] Used unique EOF markers (e.g., `EOFGITIGNORE`, `EOFTSCONFIG`)
- [ ] Called `log_file_created` for each file

---

## Step 9: Add Operation Tracking

### Track All Operations

Every operation must be tracked for the summary:

```bash
# Track successful creation
track_created "filename"

# Track skipped operations (already exists)
track_skipped "filename (already exists)"

# Track warnings (non-fatal issues)
track_warning "jq not installed - JSON validation skipped"
```

### Populated Variables

These functions populate arrays used by `show_summary`:

```bash
_BOOTSTRAP_CREATED_FILES=()    # Files created
_BOOTSTRAP_SKIPPED_FILES=()    # Files skipped
_BOOTSTRAP_WARNINGS=()         # Warnings encountered
```

**Checklist:**
- [ ] Every successful file operation calls `track_created`
- [ ] Every skipped operation calls `track_skipped "reason"`
- [ ] Every warning calls `track_warning "message"`
- [ ] No operations left untracked

---

## Step 10: Add Centralized Logging

### Log All Operations

```bash
# Log file creation
log_file_created "$SCRIPT_NAME" "filename"

# Log directory creation
log_dir_created "$SCRIPT_NAME" "dirname/"

# Log warnings for missing optional tools
log_warning "jq not installed - JSON validation will be skipped"

# Log completion
log_script_complete "$SCRIPT_NAME" "summary message"
```

### Log Output Example

```
[2025-12-07T14:30:15] bootstrap-git: Created: .gitignore
[2025-12-07T14:30:15] bootstrap-git: Created: .gitattributes
[2025-12-07T14:30:16] bootstrap-git: ✓ Complete: 2 files created

[2025-12-07T14:30:20] bootstrap-typescript: Created: tsconfig.json
[2025-12-07T14:30:20] bootstrap-typescript: ✓ Complete: 1 file created
```

**Checklist:**
- [ ] Called `log_file_created "$SCRIPT_NAME" "filename"` for every file
- [ ] Called `log_dir_created "$SCRIPT_NAME" "dirname/"` for every directory
- [ ] Called `log_warning` for all non-fatal issues
- [ ] Entries appear in `bootstrap.log`

---

## Step 11: Add Summary Section

### Display Operations Summary

```bash
# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Git configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Customize .gitignore for your project"
echo "  2. Review .gitattributes settings"
echo ""

show_log_location
```

### Output Example

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Complete: 2 files created

Created:
  • .gitignore
  • .gitattributes

Next steps:
  1. Customize .gitignore for your project
  2. Review .gitattributes settings

Log written to: bootstrap.log
```

**Checklist:**
- [ ] Added `log_script_complete` with file count
- [ ] Called `show_summary` to display created/skipped/warnings
- [ ] Added 3-4 "Next steps"
- [ ] Called `show_log_location` at end
- [ ] Keep summary concise and actionable

---

## Step 12: Validate and Test

### Syntax Validation

```bash
# Check bash syntax
bash -n bootstrap-{name}.sh

# Expected output: (no output = success)
```

### Manual Testing

```bash
# Create test directory
mkdir -p /tmp/test-bootstrap

# Run script on test directory
bash scripts/bootstrap-{name}.sh /tmp/test-bootstrap

# Check what was created
ls -la /tmp/test-bootstrap/

# Review log
cat bootstrap.log | grep bootstrap-{name}

# Verify content
cat /tmp/test-bootstrap/.gitignore

# Clean up
rm -rf /tmp/test-bootstrap
```

### Success Criteria Checklist

- [ ] Syntax validation passes (`bash -n`)
- [ ] Pre-execution confirmation displays correctly
- [ ] Files are created with correct content
- [ ] Existing files are skipped (not overwritten)
- [ ] Tracking shows created/skipped/warnings
- [ ] `bootstrap.log` has entries for all operations
- [ ] Log location displayed at end
- [ ] Script exits cleanly on success (exit 0)
- [ ] Script exits with error on failure (via `log_fatal`)
- [ ] JSON validation runs (if `jq` available)
- [ ] Warnings displayed for missing optional tools

---

## Step 13: Complete Verification

### Full Function Mapping

Verify your script uses these patterns:

| Requirement | Example | Status |
|-------------|---------|--------|
| Set strict mode | `set -euo pipefail` | ✓ |
| Source common library | `source "${BOOTSTRAP_DIR}/lib/common.sh"` | ✓ |
| Initialize script | `init_script "bootstrap-git"` | ✓ |
| Use path variables | `copy_template "root/.gitignore" "$PROJECT_ROOT/.gitignore"` | ✓ |
| Read configuration | `config_get "git.email" "default@example.com"` | ✓ |
| Pre-execution confirm | `pre_execution_confirm "$SCRIPT_NAME" "Git" ".gitignore"` | ✓ |
| Validate environment | `require_dir "$PROJECT_ROOT" \|\| log_fatal "..."` | ✓ |
| Track operations | `track_created ".gitignore"` | ✓ |
| Log to central log | `log_file_created "$SCRIPT_NAME" ".gitignore"` | ✓ |
| Display summary | `show_summary` and `show_log_location` | ✓ |

### Before Committing

- [ ] Script passes `bash -n` syntax check
- [ ] All tests pass on fresh directory
- [ ] `bootstrap.log` entries are correct
- [ ] No hardcoded paths
- [ ] No duplicate functions
- [ ] Configuration section documented
- [ ] Summary output is clear and helpful
- [ ] Next steps are specific and actionable

---

## Quick Reference: Common Replacements

### Path Operations
```bash
# OLD: Manual path calculation
TEMPLATE="$(cd "$SCRIPT_DIR/.." && pwd)/templates/root/.gitignore"

# NEW: Use path variables
copy_template "root/.gitignore" "$PROJECT_ROOT/.gitignore"
```

### File Checking
```bash
# OLD: Manual checks
[[ -f "$file" ]] && echo "exists"
[[ -d "$dir" ]] && echo "is dir"
[[ -w "$path" ]] && echo "writable"

# NEW: Library functions
file_exists "$file" && echo "exists"
dir_exists "$dir" && echo "is dir"
is_writable "$path" && echo "writable"
```

### Validation
```bash
# OLD: Manual validation
if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Error: directory missing"
  exit 1
fi

# NEW: Library validation
require_dir "$PROJECT_ROOT" || log_fatal "Directory missing"
```

### Configuration
```bash
# OLD: Hardcoded values
GIT_EMAIL="dev@example.com"

# NEW: Config-driven
GIT_EMAIL=$(config_get "git.email" "dev@example.com")
```

### Logging
```bash
# OLD: Manual echo to log
echo "Created .gitignore" >> bootstrap.log

# NEW: Centralized logging
log_file_created "$SCRIPT_NAME" ".gitignore"
```

---

## Troubleshooting

### Script Syntax Errors

**Problem**: `bash -n bootstrap-{name}.sh` shows errors

**Solution**:
1. Check EOF markers are unique (EOFGITIGNORE, not EOF)
2. Verify all quotes are matched
3. Check for unescaped special characters in heredoc content

### Missing Functions

**Problem**: Script runs but says "function not found: log_info"

**Solution**:
1. Verify `source "${BOOTSTRAP_DIR}/lib/common.sh"` is before first use
2. Verify `init_script` was called
3. Check that line comes after initialization section

### Files Not Created

**Problem**: Script runs but files don't appear

**Solution**:
1. Verify `$PROJECT_ROOT` is writable
2. Check that `pre_execution_confirm` didn't exit
3. Look for errors in `cat > file <<` command
4. Verify unique EOF markers

### Configuration Not Reading

**Problem**: `config_get` returns empty values

**Solution**:
1. Verify `config/bootstrap.config` exists with correct section
2. Check syntax of config file (INI format)
3. Verify `init_script` was called

---

## Migration Workflow Summary

1. ✅ Create backup
2. ✅ Update header section
3. ✅ Remove duplicate functions
4. ✅ Replace hardcoded paths
5. ✅ Add configuration support
6. ✅ Add pre-execution confirmation
7. ✅ Replace validation patterns
8. ✅ Replace file operations
9. ✅ Add operation tracking
10. ✅ Add centralized logging
11. ✅ Add summary section
12. ✅ Validate and test
13. ✅ Final verification

---

## Additional Resources

- **[REFERENCE_LIBRARY.md](../references/REFERENCE_LIBRARY.md)** - Complete function reference
- **[REFERENCE_CONFIG.md](../references/REFERENCE_CONFIG.md)** - Configuration options
- **[REFERENCE_SCRIPT_CATALOG.md](../references/REFERENCE_SCRIPT_CATALOG.md)** - Available scripts

---

**Version**: 2.0
**Last Updated**: 2025-12-07
**Maintained By**: Bootstrap System Team
