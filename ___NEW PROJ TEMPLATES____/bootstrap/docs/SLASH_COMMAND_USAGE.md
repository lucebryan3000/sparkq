# Bootstrap Slash Commands - Usage Guide

Quick reference for using bootstrap-related slash commands in Claude Code.

---

## `/bootstrap-standardize`

**Purpose**: Standardize a bootstrap script to use shared library structure

**Location**: `.claude/commands/bootstrap-standardize.md`

**What it does**:
- Reads the standardization checklist
- Analyzes the target script
- Systematically applies all standardization requirements
- Validates the result
- Writes the fully standardized script

### Usage

**Basic usage:**
```
/bootstrap-standardize bootstrap-git.sh
```

**What happens:**
1. Loads standardization checklist
2. Reads reference examples (codex, typescript, environment)
3. Analyzes target script and shows checklist
4. Applies all transformations systematically
5. Shows verification table
6. Writes standardized script

### Example Session

**User input:**
```
/bootstrap-standardize bootstrap-git.sh
```

**Claude's process:**
1. **Analysis Phase**: Shows what needs to be fixed
   ```markdown
   ## Standardization Analysis: bootstrap-git.sh

   ### ✅ Already Correct
   - Has pre_execution_confirm
   - Uses require_dir and is_writable

   ### ❌ Needs Fixing
   - Line 16-21: Color definitions (should use common.sh)
   - Line 27-35: log_info() function (duplicate of common.sh)
   - Line 48-56: log_success() function (duplicate of common.sh)
   - Line 89: Uses [[ -f ]] instead of file_exists
   - Missing: track_created, track_skipped calls
   - Missing: log_file_created calls
   - Missing: log_script_complete call
   - Missing: show_summary call

   ### 📝 Plan
   1. Remove duplicate color definitions
   2. Remove duplicate log functions
   3. Replace [[ -f ]] with file_exists
   4. Add tracking calls
   5. Add logging calls
   6. Add summary section
   ```

2. **Transformation**: Applies changes systematically

3. **Verification**: Shows checklist
   ```markdown
   ## Standardization Verification

   | Requirement | Status |
   |-------------|--------|
   | `set -euo pipefail` | ✅ |
   | Sources `lib/common.sh` | ✅ |
   | Calls `init_script` | ✅ |
   | Uses `${TEMPLATES_DIR}`, etc | ✅ |
   | No hardcoded paths | ✅ |
   | No duplicate functions | ✅ |
   | Calls `pre_execution_confirm` | ✅ |
   | Uses `file_exists`, `dir_exists` | ✅ |
   | Calls tracking functions | ✅ |
   | Calls logging functions | ✅ |
   | Calls `log_script_complete` | ✅ |
   | Calls `show_summary`, `show_log_location` | ✅ |
   | Uses `log_fatal` | ✅ |
   | Syntax validation passes | ✅ |
   ```

4. **Result**: Writes standardized script

### Scripts to Standardize

**Ready for standardization:**
- `bootstrap-git.sh` - Partially migrated
- `bootstrap-claude.sh` - Partially migrated
- `bootstrap-docker.sh` - Partially migrated
- `bootstrap-linting.sh` - Partially migrated
- `bootstrap-packages.sh` - Not started
- `bootstrap-vscode.sh` - Not started
- `bootstrap-testing.sh` - Not started
- `bootstrap-editor.sh` - Not started
- `bootstrap-github.sh` - Not started

**Already standardized (examples):**
- `bootstrap-codex.sh` ✅
- `bootstrap-typescript.sh` ✅
- `bootstrap-environment.sh` ✅

### Tips for Best Results

1. **Run one script at a time**: Focus on quality over speed
2. **Review the analysis**: Check that Claude identified all issues
3. **Verify the result**: Run `bash -n` on the standardized script
4. **Test manually**: Run the script on a test directory
5. **Check the log**: Verify bootstrap.log entries are created

### What Gets Preserved

The command preserves:
- ✅ All functionality
- ✅ All file contents (heredocs)
- ✅ All validation logic
- ✅ All file creation operations
- ✅ All script-specific behavior

### What Gets Changed

The command updates:
- 🔄 Header structure
- 🔄 Function calls (to use lib/common.sh)
- 🔄 Path references (to use variables)
- 🔄 Validation pattern
- 🔄 File operation pattern
- 🔄 Summary section

### Common Issues

**Issue**: "Script has syntax errors after standardization"
**Fix**: Check that heredoc EOF markers are unique (e.g., EOFGITIGNORE, not just EOF)

**Issue**: "Script doesn't preserve original behavior"
**Fix**: Review the original script again and ensure all logic was transferred

**Issue**: "Hardcoded paths still present"
**Fix**: Search for absolute paths and replace with `${TEMPLATES_DIR}`, `${LIB_DIR}`, etc.

### Advanced Usage

**Standardize and test in one session:**
```
/bootstrap-standardize bootstrap-git.sh

Then test:
bash -n ___NEW\ PROJ\ TEMPLATES____/bootstrap/scripts/bootstrap-git.sh
```

**Batch standardization:**
Run the command multiple times for different scripts:
```
/bootstrap-standardize bootstrap-git.sh
/bootstrap-standardize bootstrap-claude.sh
/bootstrap-standardize bootstrap-docker.sh
```

---

## Future Slash Commands

### `/bootstrap-create` (Planned)
Create a new bootstrap script from scratch following the standard pattern.

**Usage:**
```
/bootstrap-create bootstrap-redis.sh
```

### `/bootstrap-validate` (Planned)
Validate an existing bootstrap script against the checklist.

**Usage:**
```
/bootstrap-validate bootstrap-git.sh
```

### `/bootstrap-test` (Planned)
Run automated tests on a bootstrap script.

**Usage:**
```
/bootstrap-test bootstrap-git.sh
```

---

## Reference Documentation

- **Standardization Checklist**: `docs/SCRIPT_STANDARDIZATION_CHECKLIST.md`
- **Playbook**: `docs/Bootstrap Playbooks - Script Implementation Guide.md`
- **Phase 1 Implementation**: `docs/PHASE1_IMPROVEMENTS_IMPLEMENTED.md`
- **Common Library**: `lib/common.sh`
- **Config Manager**: `lib/config-manager.sh`
- **Template Utils**: `lib/template-utils.sh`
- **JSON Validator**: `lib/json-validator.sh`

---

**Last Updated**: 2025-12-07
**Maintained By**: Bootstrap System Team
