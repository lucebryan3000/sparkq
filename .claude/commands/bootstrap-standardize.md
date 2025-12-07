---
description: Standardize a bootstrap script to use shared library structure
---

# Bootstrap Script Standardization

Migrate bootstrap scripts to follow the standardized pattern using the shared library structure.

## Your Task

1. Scan for backlog scripts that need standardization
2. Display them as a numbered list
3. Ask user which one to standardize (or accept filename argument)
4. Load migration context and apply transformations

## Process

### 1. List Backlog Scripts

When this command runs, first check `__bootbuild/templates/scripts/` for scripts that:
- Exist and contain shell code
- Don't yet use the standardized pattern (check for `source "${BOOTSTRAP_DIR}/lib/common.sh"`)

Display as:
```
Available bootstrap scripts to standardize:
1. bootstrap-git.sh
2. bootstrap-linting.sh
3. bootstrap-testing.sh
...

Specify script name (e.g., bootstrap-git.sh) or select by number:
```

### 2. Load Context

**Read in this order:**
1. `__bootbuild/docs/playbooks/standardize-bootstrap-script.md` (authoritative migration guide)
2. Three reference examples showing correct patterns:
   - `__bootbuild/scripts/bootstrap-codex.sh`
   - `__bootbuild/scripts/bootstrap-typescript.sh`
   - `__bootbuild/scripts/bootstrap-environment.sh`
3. The target script specified by the user

### 3. Analyze

Create a brief analysis checklist:

```markdown
## Standardization Analysis: bootstrap-{name}.sh

### ✅ Already Correct
- [Items already following standard]

### ❌ Needs Fixing
- [Violations with line numbers]

### 📝 Plan
1. [First change]
2. [Second change]
...
```

Key checks:
- Uses `set -euo pipefail`?
- Sources `lib/common.sh` from `${BOOTSTRAP_DIR}`?
- Calls `init_script`?
- Uses path variables (not hardcoded paths)?
- No duplicate functions from `common.sh`?
- Calls `pre_execution_confirm` before file ops?
- Uses library functions: `file_exists`, `dir_exists`, `require_dir`, `is_writable`, `require_command`?
- Has tracking calls: `track_created`, `track_skipped`, `track_warning`?
- Has logging calls: `log_file_created`, `log_dir_created`, `log_script_complete`?
- Calls `show_summary` and `show_log_location` at end?

### 4. Transform

Follow the 13-step migration guide from standardize-bootstrap-script.md:

1. Update header and setup (set -euo pipefail, source lib/common.sh, init_script)
2. Remove duplicate functions (color defs, log functions, backup_file, verify_file)
3. Replace path calculations (use ${BOOTSTRAP_DIR}, ${TEMPLATES_DIR}, ${PROJECT_ROOT})
4. Add config support (config_get for bootstrap.config values)
5. Add pre_execution_confirm (before file operations)
6. Replace validation (require_dir, is_writable, require_command, has_jq)
7. Replace file operations (file_exists, ensure_dir, copy_template)
8. Add tracking (track_created, track_skipped calls)
9. Add logging (log_file_created, log_dir_created calls)
10. Add summary section (log_script_complete, show_summary, show_log_location)
11. Validate syntax (bash -n check)
12. Verify against examples (compare with reference patterns)

**Critical requirement:** Preserve ALL original functionality and file contents.

### 5. Validate

Show verification table:

```markdown
## Standardization Verification

| Requirement | Status |
|-------------|--------|
| `set -euo pipefail` | ✅/❌ |
| Sources `lib/common.sh` | ✅/❌ |
| Uses path variables | ✅/❌ |
| No hardcoded paths | ✅/❌ |
| No duplicate functions | ✅/❌ |
| Pre-execution confirmation | ✅/❌ |
| Validation functions replaced | ✅/❌ |
| Tracking calls present | ✅/❌ |
| Logging calls present | ✅/❌ |
| Summary section complete | ✅/❌ |
| Syntax validation passes | ✅/❌ |
```

### 6. Output

Write the standardized script and run `bash -n` syntax check.

## Key Reference

**Pattern locations in standardize-bootstrap-script.md:**
- Header template: Step 2
- Duplicate removal: Step 3
- Path variables: Step 4
- Configuration: Step 5
- Pre-execution: Step 6
- Validation patterns: Step 7
- File operations: Step 8
- Tracking: Step 9
- Logging: Step 10
- Summary: Step 11
- Common replacements table: Quick Reference section
- Troubleshooting: Troubleshooting Guide section

---

**Remember:** You are standardizing, not rewriting. Preserve all functionality and file contents. Only improve the structure and function calls.
