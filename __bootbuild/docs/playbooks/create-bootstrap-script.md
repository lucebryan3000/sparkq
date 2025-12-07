---
title: "Creating New Bootstrap Scripts"
aliases: ["create bootstrap script", "write new script", "bootstrap development"]
related:
  - ./standardize-bootstrap-script.md
  - ./run-bootstrap-scripts.md
  - ../references/REFERENCE_LIBRARY.md
  - ../references/REFERENCE_CONFIG.md
review_cycle: quarterly
version: 2.0
---

# Playbook: Creating New Bootstrap Scripts

When you need to add support for a new technology, tool, or component to the bootstrap system.

---

## When to Use This Playbook

- **You want to add a new technology** (e.g., Redis, MongoDB, Tailwind, Prisma, Stripe)
- **You're adding infrastructure support** (e.g., new container orchestration, observability tools)
- **You need custom project setup** (e.g., API scaffolding, client boilerplate)
- **You're creating a new bootstrap script** that follows the standardized pattern

---

## Before You Start

### Prerequisites

- [ ] Bash scripting knowledge
- [ ] Understanding of the technology/tool you're bootstrapping
- [ ] Read standardize-bootstrap-script.md (understand standardized pattern)
- [ ] Access to `lib/common.sh` to understand available functions
- [ ] Familiarity with `bootstrap.config` structure
- [ ] Test project directory available

### Architecture Understanding

All bootstrap scripts follow this pattern:

```
bootstrap-{name}.sh
├─ Setup: Source lib/common.sh, get project root
├─ Validation: Check dependencies, permissions
├─ Pre-execution: Show user what will happen
├─ Main: Create files, apply config
├─ Summary: Show results, tracking
└─ Exit: Log completion
```

---

## Step 1: Define Scope

**Before writing any code, document what your script will do:**

### Create Scope Document

```markdown
## New Bootstrap Script: bootstrap-{name}.sh

### Basic Information
- **Technology/Tool**: [name and version]
- **Purpose**: [one sentence describing what this does]
- **Phase Assignment**: [1/2/3/4 - which phase of bootstrap]
- **Dependencies**: [other bootstrap scripts that must run first]

### What Gets Created
- [ ] File 1: [description]
- [ ] File 2: [description]
- [ ] Directory structure: [description]

### Configuration
- [ ] Needs config section: [yes/no]
- [ ] Config section name: [{name}]
- [ ] Config settings: [list them]

### Templates
- [ ] Needs template files: [yes/no]
- [ ] Template locations: [path in templates/]
- [ ] Placeholders needed: [list them]

### Questions/Interactivity
- [ ] Needs questions file: [yes/no]
- [ ] Interactive inputs: [list them]

### Success Criteria
- [ ] Script completes without error
- [ ] All files created correctly
- [ ] Config values applied
- [ ] Existing files backed up
- [ ] Logs created properly
```

**Checklist:**
- [ ] Purpose is clear and single-focused
- [ ] Files to be created are documented
- [ ] Dependencies identified
- [ ] Phase assignment is logical (dependencies run in earlier phases)

---

## Step 2: Create Template Files

If your script needs to copy template files (most do):

### Create Directory Structure

```bash
# Create template directory for your technology
mkdir -p templates/root/{name}

# Example: if creating bootstrap-redis.sh
mkdir -p templates/root/redis
```

### Add Template Files

```bash
# Copy template files to templates/root/{name}/
# Example files might be:
#   templates/root/redis/redis.conf
#   templates/root/redis/.env.redis
#   templates/root/redis/docker-compose.redis.yml
```

### Template Content Patterns

Use `{{PLACEHOLDER}}` syntax for values that get replaced:

```ini
# Example: templates/root/mytech/config.ini
[mytech]
enabled=true
host={{MYTECH_HOST}}
port={{MYTECH_PORT}}
debug={{DEBUG_MODE}}
```

### Template Checklist

- [ ] Template directory created: `templates/root/{name}/`
- [ ] All template files added
- [ ] Placeholders use `{{VARIABLE_NAME}}` format
- [ ] No hardcoded environment-specific values
- [ ] Template files tested manually
- [ ] Templates are valid syntax (JSON valid, YAML indented, etc.)

---

## Step 3: Add Configuration Section

Edit `config/bootstrap.config` and add a new section:

### Config Section Format

```ini
# ===================================================================
# [{name}] - {Human Readable Name} Configuration
# ===================================================================
[{name}]
enabled=true                    # Enable/disable this bootstrap
# Add technology-specific settings below
setting_one=default_value       # Description of what this does
setting_two=default_value       # Another setting
feature_flag=false              # Optional features
```

### Real Example (bootstrap-docker)

```ini
# ===================================================================
# [docker] - Docker Development Environment
# ===================================================================
[docker]
enabled=false                   # Disabled by default (optional)
version=latest                  # Docker version
compose_version=2               # Docker Compose version
```

### Config Checklist

- [ ] Section added to `config/bootstrap.config`
- [ ] Section name matches your script: `[{name}]`
- [ ] `enabled=true` or `enabled=false`
- [ ] All default values are sensible
- [ ] Settings are documented with comments
- [ ] Variable names are descriptive

---

## Step 4: Create the Script

Create `scripts/bootstrap-{name}.sh` following the standardized pattern:

### Script Template

```bash
#!/bin/bash

# ===================================================================
# bootstrap-{name}.sh
#
# Purpose: {One-line description of what this script does}
# Creates: {List of files/directories this script creates}
# Config:  [{name}] section in bootstrap.config
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

# Initialize script
init_script "bootstrap-{name}"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-{name}"

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "{name}.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "{Name} bootstrap disabled in config"
    exit 0
fi

# Read technology-specific settings
SETTING_ONE=$(config_get "{name}.setting_one" "default_value")
SETTING_TWO=$(config_get "{name}.setting_two" "default_value")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

# List all files this script will create
FILES_TO_CREATE=(
    "{file1}"
    "{file2}"
    "{directory}/"
)

pre_execution_confirm "$SCRIPT_NAME" "{Name} Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check for required tools (if needed)
# require_command "some_tool" || log_fatal "some_tool is required but not installed"

log_success "Environment validated"

# ===================================================================
# Create Files
# ===================================================================

log_info "Creating {name} configuration..."

# Create directories (if needed)
if ! dir_exists "$PROJECT_ROOT/{directory}"; then
    ensure_dir "$PROJECT_ROOT/{directory}"
    log_dir_created "$SCRIPT_NAME" "{directory}/"
fi

# Copy template files
for file in "${FILES_TO_CREATE[@]}"; do
    # Skip directories (already handled above)
    if [[ "$file" == */ ]]; then
        continue
    fi

    if file_exists "$PROJECT_ROOT/$file"; then
        backup_file "$PROJECT_ROOT/$file"
        track_skipped "$file (backed up)"
        log_warning "$file already exists, backed up"
    else
        # Copy from templates/root/{name}/
        copy_template "root/{name}/${file##*/}" "$PROJECT_ROOT/$file"
        log_file_created "$SCRIPT_NAME" "$file"
        track_created "$file"
    fi
done

# ===================================================================
# Post-processing (Optional)
# ===================================================================

# Replace placeholders with config values (if needed)
# source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
# replace_in_file "$PROJECT_ROOT/{file}" "{{SETTING_ONE}}" "$SETTING_ONE"

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "{Name} configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Review created files"
echo "  2. Customize configuration as needed"
echo "  3. [technology-specific next step]"
echo ""

show_log_location
```

### Script Checklist

- [ ] Shebang: `#!/bin/bash`
- [ ] Error handling: `set -euo pipefail`
- [ ] Header comment with purpose, creates, config
- [ ] Setup section: SCRIPT_DIR, BOOTSTRAP_DIR, source lib/common.sh
- [ ] Initialization: init_script, get_project_root, SCRIPT_NAME
- [ ] Configuration reading: config_get calls
- [ ] Pre-execution: pre_execution_confirm with FILES_TO_CREATE
- [ ] Validation: require_dir, is_writable, require_command as needed
- [ ] File operations: copy_template, log_file_created, track_created
- [ ] Directory creation: ensure_dir, log_dir_created
- [ ] Summary: log_script_complete, show_summary, show_log_location
- [ ] Syntax validation: `bash -n scripts/bootstrap-{name}.sh` passes
- [ ] No hardcoded paths: Uses ${PROJECT_ROOT}, ${BOOTSTRAP_DIR}, etc.
- [ ] No duplicate functions: All functions come from lib/common.sh

---

## Step 5: Register Script in Menu

Update `scripts/bootstrap-menu.sh` to include your new script:

### Add to Phase Array

Find the appropriate phase array and add your script:

```bash
# In bootstrap-menu.sh, find:
declare -a PHASE1_SCRIPTS=(
    "bootstrap-claude.sh"
    "bootstrap-git.sh"
    # ... existing scripts
)

# For Phase 2, add to:
declare -a PHASE2_SCRIPTS=(
    "bootstrap-docker.sh"
    "bootstrap-{name}.sh"   # Add here in alphabetical order
    "bootstrap-linting.sh"
)
```

### Update Script Count

If needed, update the total script count in menu help text.

### Registration Checklist

- [ ] Script added to correct PHASE array (based on dependencies)
- [ ] Scripts in each array are in alphabetical order
- [ ] Script appears in menu when system runs
- [ ] Menu help text updated if needed

---

## Step 6: Add to Bootstrap Profiles (Optional)

If your script should be part of a profile, update `config/bootstrap.config`:

### Update Profiles Section

```ini
[profiles]
minimal=claude,git,packages
standard=claude,git,vscode,packages,typescript,environment,linting,editor
full=claude,git,vscode,codex,packages,typescript,environment,docker,linting,editor,testing,github,{name}
# Add {name} to appropriate profiles
```

### Profile Guidelines

- **minimal**: Essential tools only (claude, git, packages)
- **standard**: Standard development setup
- **full**: Everything available
- **api**: Backend-focused (no VS Code, no frontend tools)
- **frontend**: Frontend-focused (includes VS Code, styling)
- **library**: Library development (no docker, testing only)

### Profile Checklist

- [ ] Added to at least one profile
- [ ] Added to "full" profile
- [ ] Positioned after all dependencies in profile list
- [ ] Profile list remains comma-separated with no spaces

---

## Step 7: Create Questions File (Optional)

If your script needs interactive configuration, create `questions/bootstrap-{name}.questions.sh`:

### Questions File Template

```bash
#!/bin/bash

# ===================================================================
# bootstrap-{name}.questions.sh
#
# Interactive questions for bootstrap-{name}.sh configuration
# ===================================================================

ask_{name}_questions() {
    # Show section header
    section_header "{Name} Configuration"

    # Ask questions and save to config
    ask_with_default \
        "What is your {setting}?" \
        "{name}.setting_one" \
        "default_value" \
        SETTING_ONE

    ask_yes_no \
        "Enable {feature}?" \
        "{name}.feature_flag" \
        "Y"

    ask_choice \
        "Select {option}:" \
        "{name}.option" \
        "option1|option2|option3" \
        "option1"
}

# Export function for bootstrap-menu.sh
export -f ask_{name}_questions
```

### Questions Checklist

- [ ] Function named: `ask_{name}_questions`
- [ ] Uses bootstrap question functions: `ask_with_default`, `ask_yes_no`, `ask_choice`
- [ ] Config keys match bootstrap.config section: `{name}.key`
- [ ] Has `export -f` at end
- [ ] Works with auto-yes mode (BOOTSTRAP_YES environment variable)

---

## Step 8: Test the Script

### Syntax Validation

```bash
# Check for bash syntax errors
bash -n scripts/bootstrap-{name}.sh
```

### Manual Testing

```bash
# Create test project directory
mkdir -p /tmp/test-bootstrap

# Run script with auto-yes
BOOTSTRAP_YES=1 bash scripts/bootstrap-{name}.sh /tmp/test-bootstrap

# Verify files were created
ls -la /tmp/test-bootstrap/
cat /tmp/test-bootstrap/{expected_file}

# Check bootstrap log
cat bootstrap.log | tail -20
```

### Menu Testing

```bash
# Run via the bootstrap menu
bash scripts/bootstrap-menu.sh

# Select your script number when prompted
# Verify it runs without errors
```

### Test Checklist

- [ ] `bash -n` syntax validation passes
- [ ] Script runs with BOOTSTRAP_YES=1
- [ ] All expected files created
- [ ] File content is correct
- [ ] Existing files backed up (not overwritten)
- [ ] Log entries appear in bootstrap.log
- [ ] Works when run a second time (idempotent)
- [ ] Works via bootstrap menu selection
- [ ] Pre-execution confirmation shows correct files

---

## Step 9: Document

Add your script to the bootstrap documentation:

### Update Reference Files

Add an entry to `docs/references/REFERENCE_SCRIPT_CATALOG.md`:

```markdown
### bootstrap-{name}.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | {One sentence description} |
| **Status** | ✅ Active |
| **Dependencies** | {List required scripts} |
| **Runtime** | ~{X} minutes |
| **Creates** | {List files/directories} |
| **Config** | `[{name}]` section in bootstrap.config |
| **Location** | `scripts/bootstrap-{name}.sh` |
```

### Documentation Checklist

- [ ] Added to REFERENCE_SCRIPT_CATALOG.md
- [ ] Purpose is clear and concise
- [ ] Dependencies listed correctly
- [ ] Files created are documented
- [ ] Config section name matches script name

---

## Complete Checklist Summary

Use this to verify everything is complete:

### Scope & Planning
- [ ] Scope document created
- [ ] Purpose is clear and focused
- [ ] Dependencies identified
- [ ] Phase assignment decided

### Implementation
- [ ] Template directory created: `templates/root/{name}/`
- [ ] Template files added with {{PLACEHOLDER}} syntax
- [ ] Config section added to bootstrap.config
- [ ] Bootstrap script created in scripts/
- [ ] Script follows standardized pattern
- [ ] Pre-execution confirmation lists all files
- [ ] All file operations use lib/common.sh functions
- [ ] Summary section shows results

### Integration
- [ ] Script added to appropriate PHASE array in bootstrap-menu.sh
- [ ] Script added to bootstrap profiles
- [ ] Questions file created (if needed)
- [ ] Script registered in documentation

### Testing & Validation
- [ ] Syntax validation passes: `bash -n scripts/bootstrap-{name}.sh`
- [ ] Manual test successful with BOOTSTRAP_YES=1
- [ ] Menu test successful (can select and run from menu)
- [ ] Idempotent (safe to run multiple times)
- [ ] Existing files backed up, not overwritten
- [ ] Log entries created correctly
- [ ] Pre-execution confirmation works

### Documentation
- [ ] Added to REFERENCE_SCRIPT_CATALOG.md
- [ ] Config options documented
- [ ] Success criteria documented

---

## Troubleshooting

### Script Syntax Error
**Symptom**: `bash -n scripts/bootstrap-{name}.sh` shows errors

**Solution**:
1. Check for missing quotes in variables: `"${VAR}"`
2. Check for unmatched brackets, braces, parentheses
3. Check heredoc markers match: `<< 'EOFNAME'` ... `EOFNAME`
4. Verify `set -euo pipefail` is at top

### Files Not Created
**Symptom**: Script completes but no files appear

**Solution**:
1. Check template files exist: `ls templates/root/{name}/`
2. Check copy_template paths are correct
3. Check ensure_dir is called before copy_template
4. Run with BOOTSTRAP_VERBOSE=1 for debug output

### Config Values Not Applied
**Symptom**: Placeholders in files aren't replaced

**Solution**:
1. Check config_get calls are correct: `config_get "{name}.key" "default"`
2. Add `source "${BOOTSTRAP_DIR}/lib/template-utils.sh"`
3. Use replace_in_file after copy_template
4. Check placeholder syntax: `{{VARIABLE_NAME}}`

### Script Not in Menu
**Symptom**: Script doesn't appear when running bootstrap-menu.sh

**Solution**:
1. Check script is added to PHASE array in bootstrap-menu.sh
2. Check spelling matches: `bootstrap-{name}.sh`
3. Check array syntax is correct (commas, quotes)
4. Run menu again or source bootstrap-menu.sh

---

## Real-World Example

Here's a complete example: **bootstrap-redis.sh**

### Scope
- Purpose: Set up Redis configuration for development
- Creates: `docker-compose.redis.yml`, `.env.redis`, `redis.conf`
- Config: `[redis]` section with version, port, persistence
- Phase: 2 (Infrastructure)
- Depends on: bootstrap-docker.sh

### Template Files
```
templates/root/redis/
├─ docker-compose.redis.yml  # Redis service definition
├─ redis.conf               # Redis configuration
└─ .env.redis              # Environment variables
```

### Config Section
```ini
[redis]
enabled=false          # Off by default (optional)
version=latest         # Redis version
port=6379             # Port for local development
persistence=yes       # Enable AOF persistence
```

### Script (simplified)
```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

init_script "bootstrap-redis"
PROJECT_ROOT=$(get_project_root "${1:-.}")
SCRIPT_NAME="bootstrap-redis"

ENABLED=$(config_get "redis.enabled" "false")
[[ "$ENABLED" != "true" ]] && exit 0

pre_execution_confirm "$SCRIPT_NAME" "Redis Configuration" \
    "docker-compose.redis.yml" "redis.conf" ".env.redis"

require_dir "$PROJECT_ROOT" || log_fatal "Project not found"

copy_template "root/redis/docker-compose.redis.yml" "$PROJECT_ROOT/"
log_file_created "$SCRIPT_NAME" "docker-compose.redis.yml"
track_created "docker-compose.redis.yml"

# ... repeat for other files

log_script_complete "$SCRIPT_NAME" "3 files created"
show_summary
show_log_location
```

---

**Remember:** The bootstrap system values consistency, simplicity, and reusability. Every script should:
1. Follow the standardized pattern
2. Use lib/common.sh functions (no duplication)
3. Be idempotent (safe to run multiple times)
4. Log all operations
5. Document its purpose and requirements

---

**Last Updated**: 2025-12-07
**Maintained by**: Bootstrap System Team
**Version**: 2.0
