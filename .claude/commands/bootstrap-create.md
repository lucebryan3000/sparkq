---
description: Create a new bootstrap script for a technology or tool
---

# Bootstrap Script Creation

Create a new bootstrap script to add support for a technology, tool, or custom project setup.

## Your Task

When the user provides a script name and scope (e.g., "Create a bootstrap script for Redis"):

1. Load the creation playbook and understand the template
2. Work through the 9-step process systematically
3. Create all necessary files (templates, script, config, etc.)
4. Test the script and validate it works
5. Provide the output and verification

## Process

### 1. Load Context

**Read in this order:**
1. `__bootbuild/docs/playbooks/create-bootstrap-script.md` (authoritative creation guide)
2. Reference examples showing complete patterns:
   - `__bootbuild/scripts/bootstrap-typescript.sh`
   - `__bootbuild/scripts/bootstrap-environment.sh`
   - `__bootbuild/scripts/bootstrap-linting.sh`

### 2. Plan Scope

Create a scope document that identifies:

```markdown
## New Bootstrap Script: bootstrap-{name}.sh

### Basic Information
- **Technology/Tool**: [what this sets up]
- **Purpose**: [one sentence]
- **Phase Assignment**: [1/2/3]
- **Dependencies**: [other scripts needed first]

### What Gets Created
- [ ] File 1: [description]
- [ ] File 2: [description]
- [ ] Directory: [structure]

### Configuration
- [ ] Config section: [{name}]
- [ ] Config settings: [list items]

### Questions/Interactivity
- [ ] Needs interactive input: [yes/no]
```

Key checks:
- Purpose is clear and single-focused?
- Files to create are documented?
- Dependencies identified?
- Phase assignment is logical?

### 3. Create Template Files

Create directory structure:
```
templates/root/{name}/
├── file1.ext        (with {{PLACEHOLDER}} syntax)
├── file2.ext
└── subdirectory/
    └── file3.ext
```

Use placeholders like `{{VARIABLE_NAME}}` for values that will be replaced by config.

### 4. Create the Script

Follow the 11-step pattern from create-bootstrap-script.md:

1. Header with purpose, creates, config section
2. Setup: source lib/common.sh, init_script, get_project_root
3. Read configuration: config_get calls
4. Pre-execution confirmation: list FILES_TO_CREATE
5. Validation: require_dir, is_writable, require_command
6. Create files: ensure_dir, copy_template, log_file_created
7. Tracking: track_created, track_skipped calls
8. Logging: all operations logged to central log
9. Summary: log_script_complete, show_summary
10. Exit: Proper exit codes
11. Syntax check: bash -n validation passes

### 5. Add Configuration

Edit `config/bootstrap.config`:

```ini
# ===================================================================
# [{name}] - {Human Readable Name} Configuration
# ===================================================================
[{name}]
enabled=true                    # Enable/disable this bootstrap
setting_one=default_value       # Description
setting_two=default_value       # Another setting
```

### 6. Register in Menu

Update `scripts/bootstrap-menu.sh` to add your script to the appropriate PHASE array:

```bash
declare -a PHASE2_SCRIPTS=(
    "bootstrap-docker.sh"
    "bootstrap-{name}.sh"    # Add here, alphabetical
    "bootstrap-linting.sh"
)
```

### 7. Add to Profiles (Optional)

Edit `config/bootstrap.config` profiles section:

```ini
[profiles]
full=claude,git,vscode,codex,packages,typescript,{name},docker
```

### 8. Test the Script

```bash
# Syntax validation
bash -n scripts/bootstrap-{name}.sh

# Manual test
mkdir -p /tmp/test-bootstrap
BOOTSTRAP_YES=1 bash scripts/bootstrap-{name}.sh /tmp/test-bootstrap

# Verify results
ls -la /tmp/test-bootstrap/
cat bootstrap.log | tail -20
```

### 9. Document

Add entry to `docs/references/REFERENCE_SCRIPT_CATALOG.md`:

```markdown
### bootstrap-{name}.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | {One sentence} |
| **Status** | ✅ Active |
| **Dependencies** | {List scripts} |
| **Creates** | {List files} |
| **Config** | `[{name}]` in bootstrap.config |
| **Location** | `scripts/bootstrap-{name}.sh` |
```

---

## Output Checklist

After creating the bootstrap script, verify:

- [ ] ✅ Template files created in `templates/root/{name}/`
- [ ] ✅ Bootstrap script created in `scripts/bootstrap-{name}.sh`
- [ ] ✅ Configuration section added to `bootstrap.config`
- [ ] ✅ Script registered in `bootstrap-menu.sh`
- [ ] ✅ Script added to at least one profile
- [ ] ✅ Syntax validation passes: `bash -n`
- [ ] ✅ Manual test successful on fresh directory
- [ ] ✅ Log entries created correctly
- [ ] ✅ Pre-execution confirmation shows correct files
- [ ] ✅ Documentation added to REFERENCE_SCRIPT_CATALOG.md
- [ ] ✅ All files are idempotent (safe to run twice)

## Key Reference

**Steps from create-bootstrap-script.md:**
- Step 1: Define scope
- Step 2: Create template files
- Step 3: Add configuration section
- Step 4: Create the script
- Step 5: Register in menu
- Step 6: Add to profiles (optional)
- Step 7: Create questions file (optional)
- Step 8: Test the script
- Step 9: Document

---

**Remember:** You are creating a new bootstrap capability. The script should be:
1. **Idempotent** - Safe to run multiple times
2. **Consistent** - Follows shared library pattern
3. **Configurable** - Uses bootstrap.config, not hardcoded values
4. **Documented** - Clear purpose, configuration, and next steps
5. **Well-tested** - Works on fresh projects without errors
