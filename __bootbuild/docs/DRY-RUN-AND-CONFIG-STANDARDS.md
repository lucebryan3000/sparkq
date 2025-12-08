# Dry-Run Support and Configuration Standardization

## Overview

This document describes the dry-run functionality and standardized configuration access added to the bootstrap system.

## Features Added

### 1. Dry-Run Wrapper (`bootstrap-dry-run-wrapper.sh`)

A universal wrapper that enables dry-run mode for any bootstrap script without modifying the script itself.

**Location:** `__bootbuild/scripts/bootstrap-dry-run-wrapper.sh`

**Usage:**
```bash
# Basic dry run
./bootstrap-dry-run-wrapper.sh <script> [args...]

# With detailed diff
./bootstrap-dry-run-wrapper.sh --show-detailed-diff <script> [args...]

# Examples
./bootstrap-dry-run-wrapper.sh ./bootstrap-menu.sh --profile=standard
./bootstrap-dry-run-wrapper.sh --show-detailed-diff ./bootstrap-kb-sync.sh
```

**Features:**
- Intercepts file operations (mkdir, cp, mv, rm, sed, touch, chmod, chown)
- Tracks all proposed changes
- Generates comprehensive summary report
- Shows before/after diffs (with --show-detailed-diff)
- Provides impact assessment
- Suggests rollback plan
- No actual changes made to filesystem

**Example Output:**
```
Total proposed changes: 15

  + Create directories: 3
  + Copy files: 8
  ~ Modify files: 2
  - Delete files: 1
  ⚙ Change permissions: 1

Impact Assessment:
  ⚠ DESTRUCTIVE: 1 file(s) will be deleted
  ⚠ MODIFYING: 2 file(s) will be changed
```

### 2. Standardized Configuration Library (`lib/config-standard.sh`)

Centralized configuration access with consistent defaults and caching.

**Location:** `__bootbuild/lib/config-standard.sh`

**Usage:**
```bash
# Source the library (after lib/paths.sh)
source "${LIB_DIR}/config-standard.sh"

# Use standard getters
node_version=$(config_get_node_version)
package_manager=$(config_get_package_manager)
database_type=$(config_get_database_type)

# Show all config values
show_config_summary
```

**Available Getters:**

**Project:**
- `config_get_project_name` - Project name (default: directory name)
- `config_get_project_phase` - Project phase (default: "POC")
- `config_get_project_owner` - Owner name (default: "Bryan Luce")
- `config_get_project_owner_email` - Owner email
- `config_get_project_root` - Project root directory
- `config_get_bootstrap_dir` - Bootstrap directory

**Node.js:**
- `config_get_node_version` - Node version (default: "20")
- `config_get_package_manager` - Package manager (default: "pnpm")
- `config_get_node_env` - Environment (default: "development")

**Database:**
- `config_get_database_type` - Database type (default: "postgres")
- `config_get_database_host` - Database host (default: "localhost")
- `config_get_database_port` - Database port (auto-detects based on type)
- `config_get_database_name` - Database name
- `config_get_database_user` - Database user

**Testing:**
- `config_get_testing_framework` - Test framework (default: "jest")
- `config_get_e2e_framework` - E2E framework (default: "playwright")
- `config_get_test_coverage_threshold` - Coverage threshold (default: "80")

**Linting:**
- `config_get_linter` - Linter (default: "eslint")
- `config_get_formatter` - Formatter (default: "prettier")

**Docker:**
- `config_get_docker_compose_version` - Compose version (default: "3.8")
- `config_get_dockerfile_node_version` - Node version (default: "20-alpine")

**Git:**
- `config_get_git_branch` - Default branch (default: "main")
- `config_get_git_user` - Git user name
- `config_get_git_email` - Git user email

**CI/CD:**
- `config_get_ci_provider` - CI provider (default: "github")
- `config_get_ci_node_version` - CI Node version (default: "20")

**Security:**
- `config_get_ssl_enabled` - SSL enabled (default: "false")
- `config_get_jwt_enabled` - JWT enabled (default: "false")

**Validation Helpers:**
- `validate_config_value` - Ensure value is not empty
- `ensure_config_key` - Get value or error if missing
- `validate_config_choice` - Validate value is in allowed list
- `validate_package_manager` - Validate package manager choice
- `validate_database_type` - Validate database type
- `validate_testing_framework` - Validate testing framework
- `validate_node_version` - Validate Node version format

**Centralized Defaults:**
All default values are defined in one place for consistency:
```bash
DEFAULT_NODE_VERSION="20"
DEFAULT_PACKAGE_MANAGER="pnpm"
DEFAULT_DATABASE="postgres"
DEFAULT_TESTING_FRAMEWORK="jest"
# ... etc
```

**Caching:**
Config values are cached after first read for performance:
```bash
# Cache is automatic, but you can:
clear_config_cache  # Clear all cached values
```

### 3. Enhanced Scripts with Native Dry-Run Support

The following scripts now have built-in `--dry-run` and `--verify-changes` support:

#### bootstrap-kb-sync.sh

**New Options:**
- `--dry-run` - Show what would be changed without modifying files
- `--verify-changes` - Show changes and ask for confirmation

**Usage:**
```bash
# Dry run
./bootstrap-kb-sync.sh --dry-run --verbose

# Verify before changes
./bootstrap-kb-sync.sh --verify-changes

# Report only (no manifest updates)
./bootstrap-kb-sync.sh --report-only
```

**Dry Run Output:**
```
[DRY RUN] Would generate scan report to: logs/kb/bootstrap-kb-scan.log
[DRY RUN] Would update: kb-bootstrap/kb-bootstrap-manifest.json
[DRY RUN] Would update: config/bootstrap.config [technologies] section

Files that would be modified:
  • logs/kb/bootstrap-kb-scan.log (scan report)
  • kb-bootstrap/kb-bootstrap-manifest.json (technology status)
  • config/bootstrap.config ([technologies] section)
```

#### bootstrap-manifest-gen.sh

**New Options:**
- `--dry-run` - Show what would be generated without writing files
- `--verify-changes` - Show changes and ask for confirmation

**Usage:**
```bash
# Dry run with preview
./bootstrap-manifest-gen.sh --dry-run --pretty

# Verify before overwriting
./bootstrap-manifest-gen.sh --verify-changes --update

# Force regenerate (dry run)
./bootstrap-manifest-gen.sh --force --dry-run
```

**Dry Run Output:**
```
[DRY RUN] Would generate bootstrap manifest...
[DRY RUN] Would write manifest to: config/bootstrap-manifest.json

Preview (first 20 lines):
{
  "paths": { ... },
  "libraries": { ... },
  ...
}
... (truncated)

Statistics:
  Scripts:   15
  Libraries: 22
  Templates: 8
  Mode:      DRY RUN (no files modified)
```

#### bootstrap-detect.sh

**New Options:**
- `--dry-run` - Show what would be detected without writing files
- `--verify-changes` - Show changes and ask for confirmation

**Usage:**
```bash
# Dry run detection
./bootstrap-detect.sh --dry-run

# Verify before updating config
./bootstrap-detect.sh --verify-changes

# Detect specific directory
./bootstrap-detect.sh --dry-run /path/to/project
```

**Dry Run Output:**
```
[DRY RUN] Would update config: last_run=12-07-2025 10:30:00 AM UTC
[DRY RUN] Would update config: has_package_json=true
[DRY RUN] Would create detection report at: logs/bootstrap-detect-20251207-103000.json
[DRY RUN] Would create symlink: bootstrap-detect-latest.json

Dry run complete - no files were modified!

Files that would be created/modified:
  • config/bootstrap.config [detected] section
  • logs/bootstrap-detect-20251207-103000.json
  • logs/bootstrap-detect-latest.json (symlink)
```

## Integration Guide

### For New Scripts

To add dry-run support to a new script:

**1. Add option parsing:**
```bash
DRY_RUN=false
VERIFY_CHANGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --verify-changes) VERIFY_CHANGES=true; shift ;;
        # ... other options
    esac
done
```

**2. Wrap file modifications:**
```bash
# Before
mkdir -p "$output_dir"
echo "content" > "$file"

# After
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would create directory: $output_dir"
    log_info "[DRY RUN] Would write file: $file"
else
    mkdir -p "$output_dir"
    echo "content" > "$file"
fi
```

**3. Add verification prompt:**
```bash
if [[ "$VERIFY_CHANGES" == "true" ]]; then
    echo "Files that will be modified:"
    echo "  • $file1"
    echo "  • $file2"
    echo ""
    read -p "Proceed with these changes? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Operation cancelled by user"
        exit 0
    fi
fi
```

### Using Config Standard Library

**1. Source the library:**
```bash
# After sourcing paths.sh
source "${LIB_DIR}/config-standard.sh"
```

**2. Replace hardcoded config reads:**
```bash
# Before
node_version=$(grep "^version=" "$CONFIG_FILE" | cut -d= -f2)

# After
node_version=$(config_get_node_version)
```

**3. Use validation:**
```bash
# Ensure required config exists
package_manager=$(ensure_config_key "nodejs.package_manager" "Package Manager")

# Validate value is in allowed list
validate_package_manager "$package_manager" || exit 1
```

## Best Practices

### When to Use Dry-Run Wrapper

Use the wrapper when:
- Testing a script for the first time
- Running on production/important directories
- Wanting to see all file operations without modifying scripts
- Need to verify changes before execution

### When to Use Native --dry-run

Use native `--dry-run` when:
- Script supports it natively (better integration)
- Need script-specific dry-run behavior
- Want to combine with other script options
- Script already has custom dry-run logic

### When to Use --verify-changes

Use `--verify-changes` when:
- Want to review changes but expect to proceed
- Need confirmation for destructive operations
- Running interactively
- Want to see what will change before committing

## Examples

### Example 1: Test New Script Safely

```bash
# First, dry run with wrapper to see all operations
./bootstrap-dry-run-wrapper.sh --show-detailed-diff ./bootstrap-new-feature.sh

# Review output, then run with native dry-run if supported
./bootstrap-new-feature.sh --dry-run

# Finally, run with verification
./bootstrap-new-feature.sh --verify-changes
```

### Example 2: Standardize Config Access

**Before:**
```bash
# Each script does this differently
if [[ -f "$CONFIG_FILE" ]]; then
    node_ver=$(sed -n '/^\[nodejs\]/,/^\[/p' "$CONFIG_FILE" | grep "^version=" | cut -d= -f2)
fi
node_ver="${node_ver:-20}"
```

**After:**
```bash
source "${LIB_DIR}/config-standard.sh"
node_ver=$(config_get_node_version)  # Handles everything, uses cache, provides defaults
```

### Example 3: Validate User Input

```bash
source "${LIB_DIR}/config-standard.sh"

# Get package manager from user
read -p "Package manager (npm/yarn/pnpm): " pm

# Validate it
if validate_package_manager "$pm"; then
    echo "Using $pm"
else
    echo "Invalid package manager"
    exit 1
fi
```

## Files Modified

### New Files Created

1. `__bootbuild/scripts/bootstrap-dry-run-wrapper.sh` - Universal dry-run wrapper
2. `__bootbuild/lib/config-standard.sh` - Standardized config access library
3. `__bootbuild/docs/DRY-RUN-AND-CONFIG-STANDARDS.md` - This documentation

### Files Enhanced

1. `__bootbuild/scripts/bootstrap-kb-sync.sh` - Added --dry-run and --verify-changes
2. `__bootbuild/scripts/bootstrap-manifest-gen.sh` - Added --dry-run and --verify-changes
3. `__bootbuild/scripts/bootstrap-detect.sh` - Added --dry-run and --verify-changes

## Testing

To test the new features:

```bash
# Test dry-run wrapper
cd __bootbuild
./scripts/bootstrap-dry-run-wrapper.sh ./scripts/bootstrap-detect.sh

# Test native dry-run on each enhanced script
./scripts/bootstrap-kb-sync.sh --dry-run --verbose
./scripts/bootstrap-manifest-gen.sh --dry-run --pretty
./scripts/bootstrap-detect.sh --dry-run

# Test config-standard library
source ./lib/paths.sh
source ./lib/config-standard.sh
show_config_summary
```

## Migration Path

For existing scripts without dry-run support:

1. **Immediate:** Use `bootstrap-dry-run-wrapper.sh` for safety
2. **Short-term:** Add native `--dry-run` support using the pattern in enhanced scripts
3. **Long-term:** Refactor config access to use `lib/config-standard.sh`

## Future Enhancements

Potential future improvements:

1. **Enhanced Wrapper:**
   - Support for more commands (git, npm, etc.)
   - Colorized diff output
   - Export changes to JSON for programmatic use
   - Rollback script generation

2. **Config Standard:**
   - Auto-detection of missing values
   - Config validation on startup
   - Config migration helpers
   - Environment variable override support

3. **Native Dry-Run:**
   - Add to remaining bootstrap scripts
   - Standardize output format
   - Create dry-run test suite
   - Add --interactive mode for selective execution

## Troubleshooting

### Dry-Run Wrapper Not Detecting Changes

**Issue:** Wrapper shows no changes even though script modifies files

**Solution:** The script might be using subshells or direct bash commands. Check:
```bash
# Won't be caught
bash -c "mkdir dir"

# Will be caught
mkdir dir
```

### Config Standard Returns Wrong Value

**Issue:** Config getter returns unexpected value

**Solution:** Check config file and cache:
```bash
# Clear cache and retry
source lib/config-standard.sh
clear_config_cache
value=$(config_get_node_version)

# Check what's in config file
grep -A 5 '^\[nodejs\]' config/bootstrap.config
```

### Verify Mode Not Prompting

**Issue:** --verify-changes doesn't ask for confirmation

**Solution:** Check for auto-approve flags:
```bash
# These bypass verification
export BOOTSTRAP_YES=true  # Remove this
export CI=true             # Running in CI

# Verify mode won't prompt in non-interactive shells
[[ -t 0 ]] && echo "Interactive" || echo "Non-interactive"
```

## Support

For issues or questions:
1. Check this documentation
2. Review example scripts (bootstrap-kb-sync.sh, bootstrap-manifest-gen.sh, bootstrap-detect.sh)
3. Test with wrapper first: `bootstrap-dry-run-wrapper.sh <your-script>`
4. Check logs in `__bootbuild/logs/`
