---
description: Create or standardize a bootstrap script
---

# Bootstrap Script Management

Create a new bootstrap script or standardize an existing one to follow the shared library pattern.

**IMPORTANT:** This command requires Claude Sonnet for high-quality script generation. If you are currently using Haiku, this command will automatically use Sonnet for execution.

## Your Task

1. Check if the script exists
2. If it exists → standardize it
3. If it doesn't exist → create it (then standardize)
4. **Validate metadata header** (new requirement)
5. Output the final standardized script

## Metadata Header Format (REQUIRED)

All scripts MUST have a standardized header block. The header is the **authoritative source** for all metadata:

```bash
#!/bin/bash
# =============================================================================
# @script         bootstrap-{name}
# @version        1.0.0
# @phase          {1-5}
# @category       {core|vcs|nodejs|python|database|docs|config|deploy|test|ai|build|security}
# @priority       {0-100, default: 50}
#
# @short          {One-line description}
# @description    {Multi-line description of what the script does}
#
# @creates        {file1}
# @creates        {file2}
# @creates        {directory/}
#
# @depends        {script1}
# @depends        {script2}
#
# @requires       tool:{tool_name}
#
# @detects        {detection_function_name}
# @questions      {question_set_name|none}
#
# @safe           {yes|no}
# @idempotent     {yes|no}
#
# @author         Bootstrap System
# @updated        {YYYY-MM-DD}
#
# @config_section {config_section_name|none}
# @env_vars       {VAR1,VAR2|none}
# @interactive    {yes|no|optional}
# @platforms      {linux,macos,windows|all}
# @conflicts      {script_name|none}
# @rollback       {command to undo|none}
# @verify         {command to verify|none}
# @docs           {https://authoritative-docs-url}
# =============================================================================
```

**Required fields:** @script, @version, @phase, @category, @priority, @short, @description
**Optional fields:** @creates, @depends, @requires, @detects, @questions, @defaults, @tags
**Phase 2 fields:** @config_section, @env_vars, @interactive, @platforms, @conflicts, @rollback, @verify, @docs

## Process

### 1. Check Script Status

List available scripts and determine mode:

```
Available bootstrap scripts:
1. bootstrap-git.sh         [needs standardization]
2. bootstrap-linting.sh     [needs standardization]
3. bootstrap-testing.sh     [already standardized ✅]
...

To create new: specify name (e.g., bootstrap-redis.sh)
To standardize existing: select number or name
```

Check if target script exists at `__bootbuild/templates/scripts/bootstrap-{name}.sh`:
- If exists → **MODE=standardize**
- If not exists → **MODE=create**

### 2. Execute Appropriate Path

#### If MODE=create (Script Doesn't Exist)

1. Load creation playbook: `__bootbuild/docs/playbooks/create-bootstrap-script.md`
2. Load reference examples:
   - `__bootbuild/templates/scripts/bootstrap-typescript.sh`
   - `__bootbuild/templates/scripts/bootstrap-environment.sh`
   - `__bootbuild/templates/scripts/bootstrap-linting.sh`
3. Plan scope:
   - Technology/tool purpose
   - Phase assignment (1/2/3)
   - Dependencies on other scripts
   - Files to create and structure
4. Create template files in `__bootbuild/templates/root/{name}/`
5. Create the bootstrap script following 11-step pattern:
   - Header with source, init_script, config
   - Validation: require_dir, is_writable, require_command
   - File operations: ensure_dir, copy_template
   - Tracking: track_created, track_skipped
   - Logging: log operations to central log
   - Summary: log_script_complete, show_summary
6. Add configuration section to `__bootbuild/templates/config/bootstrap.config`
7. Register in `__bootbuild/templates/scripts/bootstrap-menu.sh` (appropriate PHASE array)
8. Syntax validation: `bash -n` passes
9. Document in `__bootbuild/templates/docs/references/REFERENCE_SCRIPT_CATALOG.md`

Script is created in standardized form (skip to validation).

#### If MODE=standardize (Script Exists)

1. Load standardization playbook: `__bootbuild/docs/playbooks/standardize-bootstrap-script.md`
2. Load reference examples:
   - `__bootbuild/templates/scripts/bootstrap-codex.sh`
   - `__bootbuild/templates/scripts/bootstrap-typescript.sh`
   - `__bootbuild/templates/scripts/bootstrap-environment.sh`
3. Analyze against standardization checklist:
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

4. Transform systematically (13-step migration):
   - Update header and setup
   - Remove duplicate functions
   - Replace path calculations with variables
   - Add config support
   - Add pre_execution_confirm
   - Replace validation with library functions
   - Replace file operations with library functions
   - Add tracking calls
   - Add logging calls
   - Add summary section
   - Validate syntax
   - Verify against examples

**Critical requirement:** Preserve ALL original functionality and file contents.

### 3. Validate Metadata Header

**Run the metadata validation check:**

```bash
__bootbuild/lib/validate-metadata.sh
```

**Manual metadata checklist:**

| Field | Status | Notes |
|-------|--------|-------|
| @script | ✅/❌ | Must match filename (without bootstrap- prefix) |
| @version | ✅/❌ | Semantic version (e.g., 1.0.0) |
| @phase | ✅/❌ | Must be 1-5 |
| @category | ✅/❌ | Must be valid enum value |
| @priority | ✅/❌ | Must be numeric (0-100) |
| @short | ✅/❌ | One-line description |
| @description | ✅/❌ | Full description present |

**Phase 2 metadata checklist:**

| Field | Status | Notes |
|-------|--------|-------|
| @config_section | ✅/❌ | Config section name or "none" |
| @env_vars | ✅/❌ | Comma-separated env vars or "none" |
| @interactive | ✅/❌ | Must be yes/no/optional |
| @platforms | ✅/❌ | Must be linux/macos/windows/all |
| @conflicts | ✅/❌ | Script name or "none" |
| @rollback | ✅/❌ | Rollback command or "none" |
| @verify | ✅/❌ | Verification command |
| @docs | ✅/❌ | Authoritative documentation URL |

### 4. Validate Script Structure

Show verification table:

```markdown
## Standardization Verification

| Requirement | Status |
|-------------|--------|
| Metadata header complete | ✅/❌ |
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

### 5. Regenerate Manifest

After creating or updating any script, regenerate the manifest:

```bash
__bootbuild/lib/generate-manifest.sh
```

This ensures the manifest stays in sync with script headers.

### 6. Output

Write the standardized script and run `bash -n` syntax check.

## Key Reference

**For creation:**
- `__bootbuild/docs/playbooks/create-bootstrap-script.md`
- Template structure in reference examples
- Menu registration in `__bootbuild/templates/scripts/bootstrap-menu.sh`

**For standardization:**
- `__bootbuild/docs/playbooks/standardize-bootstrap-script.md`
- 13-step migration pattern
- Common replacements table in playbook
- Troubleshooting guide in playbook

**For metadata validation:**
- `__bootbuild/lib/validate-metadata.sh` - validates all script headers
- `__bootbuild/lib/generate-manifest.sh` - regenerates manifest from headers
- `__bootbuild/lib/generate-detections.sh` - regenerates detection functions
- `__bootbuild/hooks/pre-commit-validate-metadata.sh` - pre-commit hook

---

**Remember:**
- Creating: Script is already created in standardized form
- Standardizing: Preserve all functionality, improve structure only
- **Always include complete metadata header** (script headers are authoritative)
- Always validate syntax before output
- Regenerate manifest after any script changes
- All scripts must be idempotent (safe to run multiple times)
