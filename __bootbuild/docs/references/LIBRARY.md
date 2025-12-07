---
title: Bootstrap Library Function Reference
category: Reference
version: 1.0
created: 2025-12-07
updated: 2025-12-07
purpose: "Complete API reference for all functions in lib/common.sh"
audience: Script Developers, Bootstrap Contributors, Advanced Users
---

# Bootstrap Library Function Reference

Complete reference for functions available in `lib/common.sh`. These functions provide standard operations for all bootstrap scripts.

---

## Overview

The bootstrap library provides standardized functions organized into these categories:

- **Logging** - Display messages to users
- **File Operations** - Create, backup, and manage files
- **Validation** - Verify prerequisites and directory access
- **Configuration** - Read and write configuration values
- **Script Setup** - Initialize bootstrap scripts
- **User Interaction** - Prompt users for input
- **Progress Tracking** - Track files created and operations
- **Utilities** - Helper functions

---

## Logging Functions

Functions for displaying messages to users and logging to files.

### log_info

Display informational message.

**Syntax:**
```bash
log_info "Message text"
```

**Examples:**
```bash
log_info "Creating .gitignore..."
log_info "Installing dependencies..."
```

**Output:**
```
INFO: Message text
```

**Return:** 0 (always succeeds)

---

### log_success

Display success message (green text).

**Syntax:**
```bash
log_success "Success message"
```

**Examples:**
```bash
log_success "File created successfully"
log_success "Git repository initialized"
```

**Output:**
```
✓ Success message
```

**Return:** 0

---

### log_warning

Display warning message (yellow text).

**Syntax:**
```bash
log_warning "Warning message"
```

**Examples:**
```bash
log_warning "File already exists, skipping"
log_warning "Optional tool not found"
```

**Output:**
```
⚠ Warning message
```

**Return:** 0

---

### log_error

Display error message (red text) and continue.

**Syntax:**
```bash
log_error "Error message"
```

**Examples:**
```bash
log_error "Command failed but continuing"
log_error "Optional feature unavailable"
```

**Output:**
```
✗ Error message
```

**Return:** 1

---

### log_fatal

Display fatal error message and exit immediately.

**Syntax:**
```bash
log_fatal "Fatal error message"
```

**Examples:**
```bash
require_command "git" || log_fatal "Git is required but not installed"
log_fatal "Project directory not writable"
```

**Behavior:**
- Displays red error message
- Logs to bootstrap.log
- Exits script immediately with status 1
- Cannot be caught by calling script

**Output:**
```
✗ FATAL: Fatal error message
```

**Return:** Never returns (exits script)

---

### log_section

Display section header (bold text).

**Syntax:**
```bash
log_section "Section Name"
```

**Examples:**
```bash
log_section "Validation"
log_section "Create .gitignore"
```

**Output:**
```
=== Section Name ===
```

**Return:** 0

---

### log_debug

Display debug message (if BOOTSTRAP_VERBOSE=true).

**Syntax:**
```bash
log_debug "Debug message"
```

**Examples:**
```bash
log_debug "SCRIPT_DIR=$SCRIPT_DIR"
log_debug "PROJECT_ROOT=$PROJECT_ROOT"
```

**Output:** Only shows if `BOOTSTRAP_VERBOSE=true`
```
DEBUG: Debug message
```

**Return:** 0

---

## File Logging Functions

Functions for logging file operations to the bootstrap log file.

### log_file_created

Log that a file was created.

**Syntax:**
```bash
log_file_created "script_name" "filename"
```

**Examples:**
```bash
log_file_created "bootstrap-git" ".gitignore"
log_file_created "bootstrap-packages" "package.json"
```

**Output to log:**
```
[bootstrap-git] Created file: .gitignore
```

**Return:** 0

---

### log_dir_created

Log that a directory was created.

**Syntax:**
```bash
log_dir_created "script_name" "dirname"
```

**Examples:**
```bash
log_dir_created "bootstrap-git" ".git"
log_dir_created "bootstrap-packages" "node_modules"
```

**Output to log:**
```
[bootstrap-git] Created directory: .git/
```

**Return:** 0

---

### log_script_complete

Log that a script completed execution.

**Syntax:**
```bash
log_script_complete "script_name" "summary_text"
```

**Examples:**
```bash
log_script_complete "bootstrap-git" "2 files created"
log_script_complete "bootstrap-packages" "dependencies installed"
```

**Output to log:**
```
[bootstrap-git] COMPLETE: 2 files created
```

**Return:** 0

---

## File Operations

### file_exists

Check if file exists.

**Syntax:**
```bash
if file_exists "path/to/file"; then
  # File exists
else
  # File does not exist
fi
```

**Examples:**
```bash
file_exists ".gitignore" && log_warning ".gitignore already exists"
file_exists "$PROJECT_ROOT/.env" || cp .env.example .env
```

**Return:** 0 if file exists, 1 if not

---

### dir_exists

Check if directory exists.

**Syntax:**
```bash
if dir_exists "path/to/dir"; then
  # Directory exists
else
  # Directory does not exist
fi
```

**Examples:**
```bash
dir_exists ".git" && log_warning "Repository already initialized"
dir_exists "$PROJECT_ROOT/node_modules" || npm install
```

**Return:** 0 if directory exists, 1 if not

---

### ensure_dir

Create directory if it doesn't exist (with parents).

**Syntax:**
```bash
ensure_dir "path/to/dir"
```

**Examples:**
```bash
ensure_dir "$PROJECT_ROOT/.vscode"
ensure_dir "$PROJECT_ROOT/src/components"
```

**Behavior:**
- Creates directory if missing
- Creates parent directories as needed (like `mkdir -p`)
- Does nothing if directory already exists
- Logs debug message if created

**Return:** 0 if directory exists or created successfully, 1 on error

---

### backup_file

Create backup of existing file.

**Syntax:**
```bash
backup_file "path/to/file"
```

**Examples:**
```bash
backup_file ".gitignore"
backup_file "$PROJECT_ROOT/.env.local"
```

**Behavior:**
- Copies file to `file.backup`
- Only backs up if file exists
- Skips if backup already exists
- Logs the backup operation

**Output:**
```
INFO: Backing up existing file: .gitignore → .gitignore.backup
```

**Return:** 0 if backed up or not needed, 1 on error

---

### verify_file

Verify file was created with correct content.

**Syntax:**
```bash
verify_file "path/to/file"
```

**Examples:**
```bash
if cat > .gitignore << 'EOF'
# content
EOF
then
  verify_file ".gitignore"
  log_file_created "bootstrap-git" ".gitignore"
fi
```

**Behavior:**
- Checks file exists
- Checks file is readable
- Checks file is not empty
- Logs success or error

**Return:** 0 if file verified, 1 if verification fails

---

### copy_template

Copy file from templates directory to target.

**Syntax:**
```bash
copy_template "template_name" "target_path"
```

**Examples:**
```bash
copy_template "Dockerfile" "$PROJECT_ROOT/Dockerfile"
copy_template "tsconfig.json" "$PROJECT_ROOT/tsconfig.json"
```

**Behavior:**
- Reads from `__bootbuild/templates/`
- Backs up existing target file
- Copies template to target location
- Verifies copy was successful

**Return:** 0 if copied successfully, 1 on error

---

### safe_copy

Safely copy file with backup of original.

**Syntax:**
```bash
safe_copy "source" "destination"
```

**Examples:**
```bash
safe_copy ".env.example" ".env.local"
safe_copy "package.json" "package.json.template"
```

**Behavior:**
- Backs up destination if it exists
- Copies source to destination
- Verifies destination has content
- Never overwrites without backup

**Return:** 0 if copied successfully, 1 on error

---

## Validation Functions

### require_command

Check if command is available in PATH.

**Syntax:**
```bash
if require_command "command_name"; then
  # Command is available
else
  # Command not found
  log_fatal "Command not found: command_name"
fi
```

**Examples:**
```bash
require_command "git" || log_fatal "Git is required but not installed"
require_command "npm" || log_fatal "Node.js/npm is required"
require_command "jq" || log_warning "jq not found, JSON validation skipped"
```

**Return:** 0 if command available, 1 if not

---

### require_dir

Check if directory exists and is accessible.

**Syntax:**
```bash
if require_dir "path/to/dir"; then
  # Directory exists and is readable
else
  # Directory not found or not accessible
fi
```

**Examples:**
```bash
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found"
require_dir "__bootbuild/lib" || log_fatal "Bootstrap library not found"
```

**Return:** 0 if directory exists and accessible, 1 otherwise

---

### is_writable

Check if directory is writable by current user.

**Syntax:**
```bash
if is_writable "path/to/dir"; then
  # Directory is writable
else
  # Directory not writable (permission denied)
fi
```

**Examples:**
```bash
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable"
is_writable "/root" && log_warning "Running as root, not recommended"
```

**Return:** 0 if writable, 1 if not

---

### has_jq

Check if jq (JSON processor) is available.

**Syntax:**
```bash
if has_jq; then
  # jq is available, can process JSON
else
  # jq not available
fi
```

**Examples:**
```bash
if has_jq; then
  validate_json_file "config.json"
else
  log_warning "jq not installed, JSON validation skipped"
fi
```

**Return:** 0 if jq available, 1 if not

---

## Configuration Functions

### config_get

Read a value from configuration file.

**Syntax:**
```bash
value=$(config_get "section" "key")
```

**Examples:**
```bash
PACKAGE_MANAGER=$(config_get "packages" "manager")
GIT_USER=$(config_get "git" "user_name")
DOCKER_BASE=$(config_get "docker" "base_image")
```

**Behavior:**
- Reads from `__bootbuild/config/bootstrap.config`
- Returns empty string if key not found
- Can be overridden by environment variables
- Trims whitespace from values

**Return:** 0 always (returns value or empty string)

---

### config_set

Write a value to configuration file.

**Syntax:**
```bash
config_set "section" "key" "value"
```

**Examples:**
```bash
config_set "detected" "language" "typescript"
config_set "packages" "manager" "pnpm"
```

**Behavior:**
- Updates configuration file
- Creates section if it doesn't exist
- Creates key if it doesn't exist
- Overwrites existing value
- Logs the change

**Return:** 0 if set successfully, 1 on error

---

### is_auto_approved

Check if a specific action has auto-approval enabled.

**Syntax:**
```bash
if is_auto_approved "action_name"; then
  # Action is auto-approved
else
  # Requires user confirmation
fi
```

**Examples:**
```bash
if is_auto_approved "git"; then
  # Skip confirmation for git operations
  log_info "Git auto-approved by configuration"
else
  pre_execution_confirm "bootstrap-git" "Git Configuration" ".gitignore"
fi
```

**Return:** 0 if auto-approved, 1 if requires confirmation

---

## Script Setup Functions

### init_script

Initialize bootstrap script (must be called at start of every script).

**Syntax:**
```bash
init_script "script_name"
```

**Examples:**
```bash
init_script "bootstrap-git"
init_script "bootstrap-packages"
```

**Behavior:**
- Sets up logging
- Initializes tracking arrays
- Sets up signal handlers
- Creates bootstrap.log if needed
- Logs script start

**Must be called:** At the beginning of every bootstrap script

**Return:** 0

---

### get_project_root

Get project root directory from argument or current directory.

**Syntax:**
```bash
PROJECT_ROOT=$(get_project_root "${1:-.}")
```

**Examples:**
```bash
# From script argument
PROJECT_ROOT=$(get_project_root "$1")

# From current directory
PROJECT_ROOT=$(get_project_root ".")

# From argument or current if not provided
PROJECT_ROOT=$(get_project_root "${1:-.}")
```

**Behavior:**
- Accepts project path as argument
- Returns absolute path
- Validates directory exists
- Caches result for performance

**Return:** Absolute path to project root

---

## User Interaction Functions

### confirm

Prompt user for yes/no confirmation.

**Syntax:**
```bash
if confirm "Question?"; then
  # User answered yes
else
  # User answered no
fi
```

**Examples:**
```bash
if confirm "Create backup of existing files?"; then
  backup_file ".gitignore"
fi

if confirm "Initialize git repository?"; then
  git init
fi
```

**Behavior:**
- Displays question
- Waits for user input (y/Y/yes or n/N/no)
- Returns 0 for yes, 1 for no
- Can be auto-approved with `BOOTSTRAP_YES=true`

**Return:** 0 if yes, 1 if no

---

### pre_execution_confirm

Show files that will be created and ask for confirmation.

**Syntax:**
```bash
pre_execution_confirm "script_name" "action_description" "file1" "file2" ...
```

**Examples:**
```bash
pre_execution_confirm "bootstrap-git" "Git Configuration" \
  ".gitignore" ".gitattributes" ".git/"

pre_execution_confirm "bootstrap-environment" "Environment Setup" \
  ".env.example" ".env.local"
```

**Output:**
```
=== Pre-Execution Confirmation ===
Script: bootstrap-git
Action: Git Configuration

Files that will be created:
  - .gitignore
  - .gitattributes
  - .git/

Backup existing files: [yes/no] ?
```

**Return:** 0 if confirmed, exits script if denied

---

## Progress Tracking Functions

### track_created

Track that a file was created.

**Syntax:**
```bash
track_created "filename"
```

**Examples:**
```bash
track_created ".gitignore"
track_created ".gitattributes"
```

**Behavior:**
- Adds filename to internal tracking array
- Used by `show_summary` to report results
- Increments created file count

**Return:** 0

---

### track_skipped

Track that a file was skipped.

**Syntax:**
```bash
track_skipped "filename"
```

**Examples:**
```bash
track_skipped ".gitignore"  # File already exists
```

**Behavior:**
- Adds filename to skipped array
- Used by `show_summary` to report results
- Doesn't increment created count

**Return:** 0

---

### track_warning

Track a warning for the summary report.

**Syntax:**
```bash
track_warning "warning message"
```

**Examples:**
```bash
track_warning "jq not installed - JSON validation skipped"
track_warning "Optional tool not available"
```

**Return:** 0

---

### show_summary

Display summary of operations performed.

**Syntax:**
```bash
show_summary
```

**Examples:**
```bash
log_script_complete "bootstrap-git" "Git configuration complete"
show_summary
```

**Output:**
```
=== Summary ===
Files created: 2
Files skipped: 0
Warnings: 0
```

**Behavior:**
- Shows all tracked files/operations
- Called at end of script
- Resets tracking for next script

**Return:** 0

---

### show_log_location

Display location of bootstrap log file.

**Syntax:**
```bash
show_log_location
```

**Output:**
```
Log file: __bootbuild/bootstrap.log
View with: tail -50 __bootbuild/bootstrap.log
```

**Return:** 0

---

## Working Example Script

Complete example showing library function usage:

```bash
#!/bin/bash

set -euo pipefail

# ===================================================================
# bootstrap-example.sh
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library (REQUIRED)
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script (REQUIRED)
init_script "bootstrap-example"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script name for logging
SCRIPT_NAME="bootstrap-example"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Example Configuration" \
  ".example.config" ".example.log"

# ===================================================================
# Validation
# ===================================================================

log_section "Validation"

# Check prerequisites
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable"
require_command "grep" || log_fatal "grep command required"

# Optional tools
if ! has_jq; then
  track_warning "jq not installed - advanced features disabled"
  log_warning "jq not installed - advanced features disabled"
fi

log_success "Environment validated"

# ===================================================================
# Create Configuration File
# ===================================================================

log_section "Create Configuration"

CONFIG_FILE="$PROJECT_ROOT/.example.config"

# Check if file exists
if file_exists "$CONFIG_FILE"; then
  log_warning "Configuration already exists"
  track_skipped ".example.config"
else
  # Create configuration
  if cat > "$CONFIG_FILE" << 'EOF'
[example]
enabled = true
version = "1.0"
EOF
  then
    verify_file "$CONFIG_FILE"
    track_created ".example.config"
    log_file_created "$SCRIPT_NAME" ".example.config"
  else
    log_fatal "Failed to create configuration file"
  fi
fi

# Read configuration
ENABLED=$(config_get "example" "enabled")
log_debug "Configuration enabled: $ENABLED"

# ===================================================================
# Create Log File
# ===================================================================

log_section "Create Log File"

LOG_FILE="$PROJECT_ROOT/.example.log"

if cat > "$LOG_FILE" << 'EOF'
Example Log File
================
This file contains example logs.
EOF
then
  verify_file "$LOG_FILE"
  track_created ".example.log"
  log_file_created "$SCRIPT_NAME" ".example.log"
else
  log_fatal "Failed to create log file"
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "2 files created"
show_summary

echo ""
log_success "Example configuration complete!"
echo ""

show_log_location
```

---

## Function Categories

### Use for displaying status
- `log_info` - General information
- `log_success` - Operation succeeded
- `log_warning` - Warning, but continuing
- `log_error` - Error, but continuing
- `log_section` - Section header

### Use for requirements
- `require_command` - Need specific command
- `require_dir` - Need directory
- `is_writable` - Need write permission
- `log_fatal` - Cannot continue

### Use for file operations
- `file_exists` - Check existence
- `dir_exists` - Check directory
- `ensure_dir` - Create directory
- `backup_file` - Backup before modifying
- `verify_file` - Confirm file created

### Use for tracking progress
- `track_created` - File was created
- `track_skipped` - File was skipped
- `track_warning` - Warning occurred
- `show_summary` - Display summary

---

## Quick Reference

```bash
# Load library (required)
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script (required)
init_script "script_name"

# Setup
log_section "Section Name"
require_dir "$PROJECT_ROOT" || log_fatal "Error message"
is_writable "$PROJECT_ROOT" || log_fatal "Error message"

# Main operations
log_info "Creating file..."
if ! cat > file.txt << 'EOF'
content
EOF
then
  log_fatal "Failed to create file"
fi
verify_file "file.txt"
track_created "file.txt"
log_file_created "script_name" "file.txt"

# Cleanup
log_script_complete "script_name" "summary"
show_summary
```

For more information, see [PLAYBOOK_CREATING_SCRIPTS.md](../playbooks/PLAYBOOK_CREATING_SCRIPTS.md).
