# Bootstrap Playbooks - Orchestration Guide

Bash-first bootstrap system for starting new projects with velocity and accuracy.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Playbook: Running Bootstrap](#playbook-running-bootstrap)
3. [Playbook: Creating a New Bootstrap Script](#playbook-creating-a-new-bootstrap-script)
4. [Success Criteria Template](#success-criteria-template)
5. [Script Catalog](#script-catalog)
6. [Configuration Reference](#configuration-reference)
7. [Shared Library Reference](#shared-library-reference)
8. [TODO Tracking](#todo-tracking)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    bootstrap-menu.sh                         │
│                     (Entry Point)                            │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────────────────┐   │
│  │ bootstrap-helper │───►│     bootstrap.config          │   │
│  │  (Background)    │    │  - Detected values            │   │
│  └──────────────────┘    │  - Profiles                    │   │
│                          │  - Auto-approve settings       │   │
│                          └──────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    lib/common.sh                      │   │
│  │  Shared: logging, file ops, validation, config        │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Individual Scripts                       │   │
│  │  bootstrap-{name}.sh → templates/{name}/              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Bash-First** | No LLM for standard operations |
| **Config-Driven** | All settings in bootstrap.config |
| **Template-Based** | Scripts copy from templates/, customize via config |
| **Idempotent** | Safe to run multiple times |
| **Tech-Agnostic** | Same pattern for any technology |

---

## Playbook: Running Bootstrap

### Prerequisites Checklist

- [ ] Git installed (`git --version`)
- [ ] Node.js installed (`node --version`)
- [ ] Target directory exists or will be created
- [ ] Write permissions to target directory

### Execution Steps

#### Step 1: Check Environment
```bash
./bootstrap-menu.sh --status
```
**Success**: Shows detected tools, no critical errors

#### Step 2: Preview (Optional)
```bash
./bootstrap-menu.sh --profile=standard --dry-run
```
**Success**: Lists scripts that would run without errors

#### Step 3: Execute
```bash
# Option A: Interactive menu
./bootstrap-menu.sh

# Option B: Profile with auto-yes
./bootstrap-menu.sh --profile=standard -y

# Option C: Specific phase
./bootstrap-menu.sh --phase=1 -y ./my-project
```
**Success**: All scripts complete, summary shows 0 failures

#### Step 4: Verify
```bash
# Check created files
ls -la .claude/ .gitignore tsconfig.json

# Check log
cat bootstrap.log
```
**Success**: Expected files exist, log shows no errors

#### Step 5: Post-Bootstrap Actions
- [ ] Run `pnpm install` (or npm/yarn)
- [ ] Edit `.env.local` with actual values
- [ ] Customize `CLAUDE.md` for project
- [ ] Run `npx tsc --noEmit` to verify TypeScript
- [ ] Make initial commit

---

## Playbook: Creating a New Bootstrap Script

Use this playbook when adding support for a new technology (e.g., Redis, MongoDB, Tailwind, Prisma).

### Step 1: Define Scope

**Complete this checklist before writing code:**

```markdown
## New Bootstrap Script: bootstrap-{name}.sh

### Scope Definition
- [ ] Technology/Tool: _________________
- [ ] Purpose: _________________
- [ ] Files to create: _________________
- [ ] Config section needed: [yes/no]
- [ ] Template files needed: [yes/no]
- [ ] Questions file needed: [yes/no]
- [ ] Dependencies on other scripts: _________________
- [ ] Phase assignment: [1/2/3/4]
```

### Step 2: Create Template Files

```bash
# Create template directory (if needed)
mkdir -p templates/root/{name}

# Add template files
# Example: templates/root/redis.conf
```

**Checklist:**
- [ ] Template files created in `templates/root/` or `templates/{category}/`
- [ ] Placeholders use format: `{{VARIABLE_NAME}}`
- [ ] Template tested manually

### Step 3: Add Config Section

Edit `config/bootstrap.config`:

```ini
[{name}]
enabled=true
# Add technology-specific settings
setting_one=default_value
setting_two=default_value
```

**Checklist:**
- [ ] Section added to bootstrap.config
- [ ] Default values are sensible
- [ ] Settings documented in config comments

### Step 4: Create the Script

Create `scripts/bootstrap-{name}.sh`:

```bash
#!/bin/bash
set -euo pipefail

# ===================================================================
# bootstrap-{name}.sh
#
# Purpose: {One-line description}
# Creates: {List of files/directories}
# Config:  [{name}] section in bootstrap.config
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# ===================================================================
# Configuration
# ===================================================================
SCRIPT_NAME="bootstrap-{name}"
init_script "$SCRIPT_NAME"
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Read from config
ENABLED=$(config_get "{name}.enabled" "true")
SETTING_ONE=$(config_get "{name}.setting_one" "default")

# ===================================================================
# Pre-flight Checks
# ===================================================================
# Check if this bootstrap should run
if [[ "$ENABLED" != "true" ]]; then
    log_info "{name} bootstrap disabled in config"
    exit 0
fi

# Check dependencies (other scripts, tools)
# require_command "some_tool"

# ===================================================================
# Pre-execution Confirmation
# ===================================================================
FILES_TO_CREATE=(
    "{file1}"
    "{file2}"
)

pre_execution_confirm "$SCRIPT_NAME" "{Name} Configuration" "${FILES_TO_CREATE[@]}"

# ===================================================================
# Main Execution
# ===================================================================
log_section "Creating {Name} Configuration"

# Create directories (if needed)
if is_auto_approved "create_directories"; then
    ensure_dir "${PROJECT_ROOT}/{some_dir}"
    log_dir_created "$SCRIPT_NAME" "{some_dir}/"
fi

# Copy template files
for file in "${FILES_TO_CREATE[@]}"; do
    if [[ -f "${PROJECT_ROOT}/${file}" ]]; then
        backup_file "${PROJECT_ROOT}/${file}"
        track_skipped "$file (backed up)"
    fi

    copy_template "root/${file}" "${PROJECT_ROOT}/${file}"
    log_file_created "$SCRIPT_NAME" "$file"
    track_created "$file"
done

# ===================================================================
# Post-processing (customize templates)
# ===================================================================
# Replace placeholders with config values
# source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
# replace_in_file "${PROJECT_ROOT}/{file}" "{{SETTING}}" "$SETTING_ONE"

# ===================================================================
# Summary
# ===================================================================
log_script_complete "$SCRIPT_NAME" "${#FILES_TO_CREATE[@]} files created"
show_summary
show_log_location
```

**Checklist:**
- [ ] Script follows standard pattern
- [ ] Sources `lib/common.sh`
- [ ] Uses `init_script` and `get_project_root`
- [ ] Reads settings from config
- [ ] Uses `pre_execution_confirm`
- [ ] Uses `log_file_created` / `log_dir_created`
- [ ] Uses `track_created` / `track_skipped`
- [ ] Calls `show_summary` at end
- [ ] Syntax validated: `bash -n scripts/bootstrap-{name}.sh`

### Step 5: Register in Menu

Edit `scripts/bootstrap-menu.sh`:

1. Add to appropriate phase array:
```bash
declare -a PHASE2_SCRIPTS=(
    "bootstrap-docker.sh"
    "bootstrap-{name}.sh"   # Add here
    "bootstrap-linting.sh"
)
```

2. Update total count if needed

**Checklist:**
- [ ] Script added to correct phase array
- [ ] Script number updated in menu help

### Step 6: Add to Profiles (Optional)

Edit `config/bootstrap.config`:

```ini
[profiles]
full=claude,git,vscode,...,{name},...
```

**Checklist:**
- [ ] Added to appropriate profiles
- [ ] Profile order is logical (dependencies first)

### Step 7: Create Questions File (Optional)

If interactive customization is needed, create `questions/bootstrap-{name}.questions.sh`:

```bash
#!/bin/bash
# Questions for bootstrap-{name}.sh

ask_{name}_questions() {
    section_header "{Name} Configuration"

    ask_with_default "Setting description?" "{name}.setting_one" "default" SETTING_ONE
    ask_yes_no "Enable feature?" "{name}.feature" "Y" FEATURE_ENABLED
}
```

**Checklist:**
- [ ] Function named `ask_{name}_questions`
- [ ] Uses `ask_with_default`, `ask_yes_no`, `ask_choice`
- [ ] Config keys match bootstrap.config section

### Step 8: Test

```bash
# Syntax check
bash -n scripts/bootstrap-{name}.sh

# Dry run (manual)
BOOTSTRAP_YES=true bash scripts/bootstrap-{name}.sh /tmp/test-project

# Verify files created
ls -la /tmp/test-project/

# Run via menu
./bootstrap-menu.sh
# Select new script number
```

**Checklist:**
- [ ] Syntax validation passes
- [ ] Script runs without errors
- [ ] Expected files created
- [ ] Existing files backed up (not destroyed)
- [ ] Log entries created
- [ ] Works with `--yes` flag
- [ ] Works via menu selection

### Step 9: Document

Add to this playbook's Script Catalog section.

**Checklist:**
- [ ] Added to Script Catalog
- [ ] Success criteria documented
- [ ] Config options documented

---

## Success Criteria Template

Use this template to define success criteria for any bootstrap script:

```markdown
## bootstrap-{name}.sh

### Purpose
{One sentence description}

### Files Created
| File | Description |
|------|-------------|
| `{file1}` | {description} |
| `{file2}` | {description} |

### Config Section
```ini
[{name}]
{key}={default}
```

### Success Criteria
- [ ] Script completes without error (exit code 0)
- [ ] All listed files exist in project root
- [ ] Files contain expected content (not empty)
- [ ] Existing files backed up before overwrite
- [ ] Log entries created in bootstrap.log
- [ ] Config values correctly applied to templates

### Verification Commands
```bash
# Check files exist
ls -la {file1} {file2}

# Validate syntax (if applicable)
{validation_command}

# Check content
grep "{expected_string}" {file1}
```

### Dependencies
- Requires: {other scripts or tools}
- Required by: {scripts that depend on this}

### Failure Recovery
If script fails:
1. Check bootstrap.log for error details
2. Verify template files exist in templates/root/
3. Check config section exists and has valid values
4. Restore from .backup files if needed
```

---

## Script Catalog

### Phase 1: AI Development Toolkit

#### bootstrap-claude.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Configure Claude Code for AI-assisted development |
| **Creates** | `.claude/` directory, `.claudeignore` |
| **Config** | `[claude]` section |
| **Success** | `.claude/agents/` exists, `.claudeignore` exists |
| **Verify** | `ls -la .claude/` |

#### bootstrap-git.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Initialize git with sensible defaults |
| **Creates** | `.gitignore`, `.gitattributes` |
| **Config** | `[git]` section |
| **Success** | `git status` runs without error |
| **Verify** | `git status && cat .gitignore` |

#### bootstrap-vscode.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Configure VS Code workspace |
| **Creates** | `.vscode/settings.json`, `extensions.json`, `launch.json` |
| **Config** | None (static templates) |
| **Success** | `.vscode/` contains all files |
| **Verify** | `ls .vscode/` |

#### bootstrap-packages.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Set up package manager and Node version |
| **Creates** | `.npmrc`, `.nvmrc`, `.tool-versions`, `package.json` |
| **Config** | `[packages]` section |
| **Success** | `node -v` matches `.nvmrc` |
| **Verify** | `cat .nvmrc && node -v` |

#### bootstrap-typescript.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Configure TypeScript with strict mode |
| **Creates** | `tsconfig.json`, `src/` directory |
| **Config** | None (static templates) |
| **Success** | `npx tsc --noEmit` passes |
| **Verify** | `npx tsc --noEmit` |

#### bootstrap-environment.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Set up environment variables |
| **Creates** | `.env.example`, `.env.local`, `env.d.ts` |
| **Config** | None |
| **Success** | `.env.example` exists, `.env.local` gitignored |
| **Verify** | `cat .env.example` |

### Phase 2: Infrastructure

#### bootstrap-docker.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Set up Docker development environment |
| **Creates** | `docker-compose.yml`, `Dockerfile`, `.dockerignore` |
| **Config** | `[docker]` section |
| **Success** | `docker compose config` validates |
| **Verify** | `docker compose config` |

#### bootstrap-linting.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Configure ESLint and Prettier |
| **Creates** | `.eslintrc.json`, `.prettierrc.json`, ignore files |
| **Config** | `[linting]` section |
| **Success** | `npx eslint --print-config .` works |
| **Verify** | `npx eslint --print-config .eslintrc.json` |

#### bootstrap-editor.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Universal editor configuration |
| **Creates** | `.editorconfig`, `.stylelintrc` |
| **Config** | None |
| **Success** | Files exist and are valid |
| **Verify** | `cat .editorconfig` |

### Phase 3: Testing

#### bootstrap-testing.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | Configure test frameworks |
| **Creates** | `jest.config.js`, `pytest.ini`, `.coveragerc` |
| **Config** | `[testing]` section |
| **Success** | Test config files parse without error |
| **Verify** | `node -e "require('./jest.config.js')"` |

### Phase 4: CI/CD

#### bootstrap-github.sh
| Aspect | Detail |
|--------|--------|
| **Purpose** | GitHub workflows and templates |
| **Creates** | `.github/workflows/ci.yml`, PR/issue templates |
| **Config** | None |
| **Success** | `.github/` structure complete |
| **Verify** | `ls -la .github/workflows/` |

---

## Configuration Reference

### bootstrap.config Structure

```ini
# ===================================================================
# [project] - Project metadata
# ===================================================================
[project]
name=my-project          # Used in templates, package.json
phase=POC                # POC, MVP, Production
owner=Developer Name     # Used in CLAUDE.md
owner_email=dev@email    # Used in package.json, git

# ===================================================================
# [profiles] - Script combinations
# ===================================================================
[profiles]
minimal=claude,git,packages
standard=claude,git,vscode,packages,typescript,environment,linting,editor
full=claude,git,vscode,codex,packages,typescript,environment,docker,linting,editor,testing,github
api=claude,git,packages,typescript,environment,docker,testing
frontend=claude,git,vscode,packages,typescript,linting,editor
library=claude,git,packages,typescript,linting,testing
default_profile=standard

# ===================================================================
# [auto_approve] - Actions that don't need confirmation
# ===================================================================
[auto_approve]
create_directories=true
create_config_files=true
backup_existing_files=true
set_file_permissions=true
git_init=true
detect_package_manager=true

# ===================================================================
# [detected] - Populated by bootstrap-helper.sh
# ===================================================================
[detected]
last_run=
git_installed=
node_installed=
docker_installed=
has_package_json=
has_git_repo=
```

### Adding a New Config Section

1. Add section to `config/bootstrap.config`
2. Document in this reference
3. Use in script via `config_get "{section}.{key}" "default"`

---

## Shared Library Reference

### lib/common.sh Functions

#### Logging
```bash
log_info "message"      # Blue arrow: → message
log_success "message"   # Green check: ✓ message
log_warning "message"   # Yellow warning: ⚠ message
log_error "message"     # Red X: ✗ message (to stderr)
log_fatal "message"     # Red X + exit 1
log_section "Title"     # Bordered section header
log_debug "message"     # Only if BOOTSTRAP_DEBUG=true
```

#### File Logging (to bootstrap.log)
```bash
log_to_file "script-name" "message"
log_file_created "script-name" "filename"
log_dir_created "script-name" "dirname"
log_script_complete "script-name" "summary"
log_script_failed "script-name" "error"
```

#### File Operations
```bash
backup_file "/path/file"           # Returns backup path
verify_file "/path/file"           # Logs success/error
safe_copy "src" "dst"              # Backup + copy + verify
ensure_dir "/path/dir"             # mkdir -p with logging
copy_template "rel/path" "dst"     # From templates/ dir
```

#### Validation
```bash
require_command "git"              # Exit if missing
is_writable "/path"                # Returns 0/1
file_exists "/path"                # Returns 0/1
dir_exists "/path"                 # Returns 0/1
```

#### Config Access
```bash
config_get "section.key" "default" # Read from bootstrap.config
config_set "section.key" "value"   # Write to bootstrap.config
is_auto_approved "action_name"     # Check auto_approve section
```

#### Script Setup
```bash
init_script "bootstrap-name.sh"    # Set up paths, source config
get_project_root "${1:-.}"         # Resolve project path
```

#### User Interaction
```bash
confirm "Proceed?" "Y"             # Returns 0 for yes
pre_execution_confirm "script" "desc" file1 file2  # Show + confirm
```

#### Progress Tracking
```bash
track_created "filename"           # Add to created list
track_skipped "filename"           # Add to skipped list
track_warning "message"            # Add to warnings list
show_summary                       # Display all tracked items
```

---

## TODO Tracking

### Open TODOs

| ID | Script/Area | Description | Assignable To |
|----|-------------|-------------|---------------|
| TODO-001 | bootstrap-menu.sh | Implement `--rollback` flag | Haiku |
| TODO-002 | bootstrap-menu.sh | Implement `--health-check` flag | Haiku |
| TODO-003 | lib/common.sh | Implement `rollback_session()` function | Haiku |
| TODO-004 | bootstrap-devcontainer.sh | Create script (not implemented) | Sonnet |
| TODO-005 | bootstrap-documentation.sh | Create script (not implemented) | Sonnet |
| TODO-006 | bootstrap-validate.sh | Create validation script | Haiku |
| TODO-007 | All scripts | Migrate to use lib/common.sh consistently | Haiku |
| TODO-008 | bootstrap-codex.sh | Update deprecated model references | Haiku |

### TODO Template

When adding a TODO:

```markdown
| TODO-XXX | {location} | {description} | {Haiku/Sonnet/Opus/Codex} |
```

### Completion Criteria for TODOs

- **Haiku assignable**: Pattern-following, no complex decisions
- **Sonnet assignable**: Needs context, moderate complexity
- **Opus assignable**: Architecture decisions, complex debugging
- **Codex assignable**: Shell commands, package operations

---

## Quick Reference

```bash
# Check environment
./bootstrap-menu.sh --status

# Preview without executing
./bootstrap-menu.sh --profile=standard --dry-run

# Run standard profile
./bootstrap-menu.sh --profile=standard -y

# Run specific phase
./bootstrap-menu.sh --phase=1 -y

# Interactive mode
./bootstrap-menu.sh -i

# Check log after run
cat bootstrap.log
```

---

**Version**: 4.0 - Playbook Edition
**Last Updated**: December 2025
