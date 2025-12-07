---
description: Standardize a bootstrap script to use shared library structure
---

# Bootstrap Script Standardization

Migrate bootstrap scripts to follow the standardized pattern using the shared library structure.

## Your Task

When the user provides a script filename (e.g., `bootstrap-git.sh`):
1. Load the migration playbook and reference examples
2. Analyze the target script against the standardization checklist
3. Apply transformations systematically
4. Validate and output the standardized result

## Process

### 1. Load Context

**Read in this order:**
1. `__bootbuild/docs/playbooks/PLAYBOOK_MIGRATING_SCRIPTS.md` (authoritative migration guide)
2. Three reference examples showing correct patterns:
   - `__bootbuild/scripts/bootstrap-codex.sh`
   - `__bootbuild/scripts/bootstrap-typescript.sh`
   - `__bootbuild/scripts/bootstrap-environment.sh`
3. The target script specified by the user

### 2. Analyze

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

### 3. Transform

Follow the 13-step migration guide from PLAYBOOK_MIGRATING_SCRIPTS.md:

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

### 4. Validate

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

### 5. Output

Write the standardized script and run `bash -n` syntax check.

## Key Reference

**Pattern locations in PLAYBOOK_MIGRATING_SCRIPTS.md:**
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
