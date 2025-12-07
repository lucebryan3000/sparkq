---
description: Standardize a bootstrap script to use shared library structure
---

# Bootstrap Script Standardization Command

You are a bootstrap script standardization specialist. Your job is to migrate bootstrap scripts to follow the standardized pattern using the shared library structure.

## Your Task

When the user provides a script filename, you will:
1. Read the standardization checklist
2. Read the target script
3. Read reference examples
4. Systematically apply all standardization requirements
5. Write the fully standardized script

## Step 1: Load Context

**REQUIRED READING** (in this order):

1. **Standardization Checklist**:
   - Read: `__bootbuild/docs/SCRIPT_STANDARDIZATION_CHECKLIST.md`
   - This is your PRIMARY reference - follow it EXACTLY

2. **Reference Examples** (read ALL three - these show the CORRECT pattern):
   - `__bootbuild/scripts/bootstrap-codex.sh`
   - `__bootbuild/scripts/bootstrap-typescript.sh`
   - `__bootbuild/scripts/bootstrap-environment.sh`

3. **Target Script** (the file to standardize):
   - User will specify which script to standardize
   - Read the current implementation
   - Identify what needs to be changed

4. **Shared Libraries** (understand what's available):
   - `__bootbuild/lib/common.sh` (core functions)
   - `__bootbuild/lib/json-validator.sh` (JSON validation)
   - `__bootbuild/lib/template-utils.sh` (template manipulation)
   - `__bootbuild/lib/config-manager.sh` (config access)

## Step 2: Analysis Phase

Before making any changes, analyze the target script:

**Create a checklist showing current status:**

```markdown
## Standardization Analysis: bootstrap-{name}.sh

### ✅ Already Correct
- [List items that already follow the standard]

### ❌ Needs Fixing
- [List all violations with line numbers]

### ➕ Missing Features
- [List required features not present]

### 📝 Plan
1. [First change to make]
2. [Second change to make]
...
```

**CRITICAL CHECKS:**
- [ ] Does it use `set -euo pipefail`? (not just `set -e`)
- [ ] Does it source `lib/common.sh` from `${BOOTSTRAP_DIR}`?
- [ ] Does it call `init_script`?
- [ ] Does it use `${TEMPLATES_DIR}`, `${LIB_DIR}`, `${PROJECT_ROOT}`? (NO hardcoded paths)
- [ ] Does it have duplicate functions that exist in `common.sh`?
- [ ] Does it have color definitions? (should use common.sh)
- [ ] Does it call `pre_execution_confirm` before file operations?
- [ ] Does it use `file_exists`, `dir_exists` instead of `[[ -f ]]`, `[[ -d ]]`?
- [ ] Does it call `track_created`, `track_skipped`, `track_warning`?
- [ ] Does it call `log_file_created`, `log_dir_created`?
- [ ] Does it call `log_script_complete` at the end?
- [ ] Does it call `show_summary` and `show_log_location`?
- [ ] Does it use `log_fatal` instead of `log_error; exit 1`?
- [ ] Does it use `require_dir`, `is_writable`, `require_command` for validation?

## Step 3: Standardization Process

Work through the checklist SYSTEMATICALLY:

### 3.1 Header Section
```bash
#!/bin/bash

# ===================================================================
# bootstrap-{name}.sh
#
# {One-line purpose - from original script or infer from function}
# Creates: {list all files this script creates}
# Config: [{section}] section in bootstrap.config (or "None")
# ===================================================================

set -euo pipefail  # MUST be -euo pipefail, not just -e

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-{name}"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-{name}"
```

### 3.2 Remove Duplicates

**DELETE all of these if present:**
- Color definitions (RED, GREEN, YELLOW, BLUE, NC)
- `log_info()`, `log_success()`, `log_warning()`, `log_error()` functions
- `backup_file()` function
- `verify_file()` function
- Any `cleanup_on_error()` trap handlers

### 3.3 Pre-Execution Confirmation

**ADD this section** (before any file operations):
```bash
# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "{Human-Readable Description}" \
    "{file1}" \
    "{file2}" \
    "{directory}/" \
    "{file3}"
```

### 3.4 Validation Section

**CONVERT old patterns to new:**

| Old | New |
|-----|-----|
| `if [[ ! -d "$PROJECT_ROOT" ]]; then log_error "..."; exit 1; fi` | `require_dir "$PROJECT_ROOT" \|\| log_fatal "Project directory not found: $PROJECT_ROOT"` |
| `if [[ ! -w "$PROJECT_ROOT" ]]; then log_error "..."; exit 1; fi` | `is_writable "$PROJECT_ROOT" \|\| log_fatal "Project directory not writable: $PROJECT_ROOT"` |
| `if ! command -v git &>/dev/null; then log_error "..."; exit 1; fi` | `require_command "git" \|\| log_fatal "git is required"` |
| `log_error "..."; exit 1` | `log_fatal "..."` |

**For optional tools:**
```bash
if ! has_jq; then
    track_warning "jq not installed - JSON validation will be skipped"
    log_warning "jq not installed - JSON validation will be skipped"
    log_info "Install with: sudo apt install jq (or brew install jq)"
fi
```

### 3.5 File Creation Pattern

**CONVERT each file creation block:**

```bash
log_info "Creating {filename}..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/{filename}"; then
    log_warning "{filename} already exists, skipping"
    track_skipped "{filename}"
else
    if cat > "$PROJECT_ROOT/{filename}" << 'EOFMARKER'
{file contents - preserve from original}
EOFMARKER
    then
        verify_file "$PROJECT_ROOT/{filename}"
        track_created "{filename}"
        log_file_created "$SCRIPT_NAME" "{filename}"

        # For JSON files - add validation
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

**REPLACE:**
- `[[ -f "$file" ]]` → `file_exists "$file"`
- `mkdir -p "$dir"` → `ensure_dir "$dir"`
- Manual backup logic → Remove (use `track_skipped` instead)

### 3.6 Directory Creation Pattern

```bash
log_info "Creating {directory} structure..."

ensure_dir "$PROJECT_ROOT/{directory}"
log_dir_created "$SCRIPT_NAME" "{directory}/"

# For subdirectories
for dir in {subdir1} {subdir2} {subdir3}; do
    if dir_exists "$PROJECT_ROOT/{directory}/$dir"; then
        log_debug "{directory}/$dir already exists, skipping"
    else
        ensure_dir "$PROJECT_ROOT/{directory}/$dir"
        log_dir_created "$SCRIPT_NAME" "{directory}/$dir"
    fi
done

log_success "{Directory} structure created"
```

### 3.7 Summary Section

**REPLACE the entire summary section with:**

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
echo "  1. {Essential step 1 - keep concise}"
echo "  2. {Essential step 2 - keep concise}"
echo "  3. {Essential step 3 - keep concise}"
echo ""
echo "Configuration notes:"
echo "  - {Important note 1}"
echo "  - {Important note 2}"
echo ""

show_log_location
```

**Simplification rules:**
- Next steps: 3-4 items MAX (not 10+)
- Remove verbose explanations
- Keep only essential information

## Step 4: Validation

After standardization, verify:

1. **Syntax Check**: Run `bash -n` on the script
2. **Pattern Verification**: Compare against reference examples
3. **Checklist Verification**: Go through standardization checklist

**Show this table:**

```markdown
## Standardization Verification

| Requirement | Status |
|-------------|--------|
| `set -euo pipefail` | ✅/❌ |
| Sources `lib/common.sh` | ✅/❌ |
| Calls `init_script` | ✅/❌ |
| Uses `${TEMPLATES_DIR}`, `${LIB_DIR}`, `${PROJECT_ROOT}` | ✅/❌ |
| No hardcoded paths | ✅/❌ |
| No duplicate functions | ✅/❌ |
| Calls `pre_execution_confirm` | ✅/❌ |
| Uses `file_exists`, `dir_exists` | ✅/❌ |
| Calls `track_created`, `track_skipped`, `track_warning` | ✅/❌ |
| Calls `log_file_created`, `log_dir_created` | ✅/❌ |
| Calls `log_script_complete` | ✅/❌ |
| Calls `show_summary`, `show_log_location` | ✅/❌ |
| Uses `log_fatal` (not `log_error; exit 1`) | ✅/❌ |
| Uses `require_dir`, `is_writable`, `require_command` | ✅/❌ |
| Syntax validation passes | ✅/❌ |
```

## Step 5: Write Standardized Script

**Write the complete standardized script** using the Write tool.

**CRITICAL REQUIREMENTS:**
- Preserve ALL functionality from the original script
- Preserve ALL file contents (heredocs) from original
- Only change the structure and function calls
- Use unique EOF markers for each heredoc (e.g., EOFGITIGNORE, EOFTSCONFIG)
- Ensure all validation passes

## Special Cases

### If script uses template files from templates/
```bash
# Source template utilities
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"

# Use TEMPLATES_DIR variable
copy_template "root/.gitignore" "${PROJECT_ROOT}/.gitignore"
```

### If script needs interactive questions
```bash
# Source additional libraries
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Read from config with detection fallback
PROJECT_NAME=$(config_get "project.name" "$(detect_project_name)")
```

### If script has complex validation logic
- Move validation functions to a validation section
- Use existing validation functions from lib/common.sh where possible
- Keep custom validation inline if specific to this script

## Communication Style

**During standardization:**
1. Show analysis checklist first
2. Explain what you're changing and why
3. Reference specific line numbers from checklist
4. Show verification table
5. Write the standardized script

**Be systematic, thorough, and precise.**

## Example Usage

**User**: `/bootstrap-standardize bootstrap-git.sh`

**You**:
1. Read SCRIPT_STANDARDIZATION_CHECKLIST.md
2. Read the 3 reference examples
3. Read bootstrap-git.sh
4. Show analysis checklist
5. Apply all transformations
6. Show verification table
7. Write standardized bootstrap-git.sh

## Success Criteria

The standardized script MUST:
- Pass `bash -n` syntax validation
- Follow EVERY item in the standardization checklist
- Match the pattern of reference examples
- Preserve 100% of original functionality
- Have NO hardcoded paths
- Have NO duplicate code
- Log ALL operations to bootstrap.log
- Track ALL file operations
- Show pre-execution confirmation

---

**Remember**: You are NOT writing new scripts. You are STANDARDIZING existing scripts to use the shared library pattern. Preserve all functionality, just improve the structure.
