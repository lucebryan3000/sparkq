---
title: Playbook - Running Bootstrap Scripts
version: 1.0
created: 2025-12-07
updated: 2025-12-07
---

# Playbook: Running Bootstrap Scripts

This playbook covers how to execute bootstrap scripts, manage configurations, troubleshoot issues, and handle rollbacks. Use this guide whenever you need to initialize or bootstrap a project.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start (5 Minutes)](#quick-start-5-minutes)
3. [Running Individual Scripts](#running-individual-scripts)
4. [Running Multiple Scripts](#running-multiple-scripts)
5. [Configuration & Environment Variables](#configuration--environment-variables)
6. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
7. [Post-Execution Steps](#post-execution-steps)
8. [Advanced Usage](#advanced-usage)
9. [Rolling Back Changes](#rolling-back-changes)
10. [Verification Checklist](#verification-checklist)

---

## Prerequisites

Before running any bootstrap script, verify your environment is properly configured.

### Step 1: Verify Required Tools

Check that essential tools are installed:

```bash
# Check bash version (5.0+ recommended)
bash --version

# Check git
git --version

# Check grep/sed availability
grep --version
sed --version
```

**Requirements:**
- [ ] Bash 5.0 or higher
- [ ] Git installed and configured
- [ ] Basic Unix tools (grep, sed, awk, find)
- [ ] Write permissions in project directory

### Step 2: Verify Directory Structure

Ensure the bootstrap directory structure exists:

```bash
# Navigate to bootstrap directory
cd __bootbuild

# Verify structure
ls -la                    # Should show: config/, lib/, scripts/, docs/
ls -la lib/               # Should show: common.sh
ls -la scripts/           # Should show: bootstrap-*.sh files
```

**Directory Checklist:**
- [ ] `__bootbuild/lib/common.sh` exists
- [ ] `__bootbuild/scripts/` directory exists
- [ ] `__bootbuild/config/` directory exists
- [ ] At least one bootstrap script available

### Step 3: Verify Configuration

Check that bootstrap configuration is available:

```bash
# Check for config file
ls -la config/bootstrap.config

# Or check environment variable
echo $BOOTSTRAP_CONFIG
```

**Configuration Checklist:**
- [ ] `bootstrap.config` exists or `$BOOTSTRAP_CONFIG` is set
- [ ] Config file is readable
- [ ] Project section is defined: `[project]`
- [ ] At least one profile defined: `[profiles.dev]` or similar

### Step 4: Verify Permissions

Ensure write permissions in target directory:

```bash
# Test write permission
touch /tmp/bootstrap-test.txt 2>/dev/null && rm /tmp/bootstrap-test.txt && echo "✓ Write OK" || echo "✗ Write DENIED"

# For project directory
[ -w "$PROJECT_ROOT" ] && echo "✓ Project writable" || echo "✗ Project not writable"
```

**Permission Checklist:**
- [ ] Can write to project directory
- [ ] User owns or has write permission to target files
- [ ] No permission conflicts with existing files

---

## Quick Start (5 Minutes)

Get your project bootstrapped in 5 minutes using the default configuration.

### Step 1: Navigate to Project

```bash
cd /path/to/your/project
```

### Step 2: Run Bootstrap Menu

```bash
# Navigate to bootstrap scripts
cd __bootbuild/scripts

# Run the main menu
./bootstrap-menu.sh
```

**Expected Output:**
```
=== Bootstrap Menu ===
Select phase to bootstrap:
1) Phase 1 - Foundation (Git, Packages, Environment)
2) Phase 2 - Development (Linting, Testing, Editor)
3) Phase 3 - Advanced (Docker, CI/CD, Documentation)
4) Custom (Run individual scripts)
5) Exit

Enter choice:
```

### Step 3: Select Your Phase

- **Phase 1**: Start here for new projects (Git + package management)
- **Phase 2**: Add after Phase 1 (development tools)
- **Phase 3**: Advanced tools (Docker, CI/CD)
- **Custom**: Run individual scripts

### Step 4: Follow Confirmations

Each script will show what it will create before proceeding:

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

Answer yes to proceed or no to skip.

### Step 5: Check Results

After completion, verify:

```bash
# Check log file
tail -50 __bootbuild/bootstrap.log

# Verify created files
git status              # For git script
ls -la .env.example     # For environment script
docker -v              # For docker script (if installed)
```

---

## Running Individual Scripts

Run a single bootstrap script directly for precise control.

### Step 1: Navigate to Scripts Directory

```bash
cd /path/to/your/project/__bootbuild/scripts
```

### Step 2: Identify Your Script

List available scripts:

```bash
ls -la bootstrap-*.sh
```

Common scripts:
- `bootstrap-git.sh` - Initialize git repository
- `bootstrap-packages.sh` - Install dependencies
- `bootstrap-environment.sh` - Create .env files
- `bootstrap-docker.sh` - Configure Docker
- `bootstrap-linting.sh` - Set up linting
- `bootstrap-testing.sh` - Configure testing framework
- `bootstrap-typescript.sh` - TypeScript configuration
- `bootstrap-vscode.sh` - VS Code settings

### Step 3: Run the Script

```bash
# Run from project root
/path/to/__bootbuild/scripts/bootstrap-git.sh

# Or run with explicit project path
/path/to/__bootbuild/scripts/bootstrap-git.sh /path/to/project

# Or run from within __bootbuild/scripts directory
./bootstrap-git.sh ..
```

### Step 4: Review Pre-Execution Confirmation

The script displays what will be created:

```
=== Pre-Execution Confirmation ===
Script: bootstrap-environment
Action: Environment Configuration

Files that will be created:
  - .env.example
  - .env.local (user, not tracked)

Backup existing files: [yes/no] ?
```

Options:
- **yes** - Create backup of existing files, then proceed
- **no** - Skip backup, proceed with caution
- **skip** - Cancel execution

### Step 5: Monitor Execution

Watch the execution progress:

```bash
=== Bootstrapping Environment Configuration ===
INFO: Creating .env.example...
SUCCESS: .env.example created
INFO: Creating .env.local...
SUCCESS: .env.local created

=== Summary ===
Files created: 2
Files skipped: 0
Warnings: 0

✓ Environment configuration complete!
```

### Step 6: Verify Results

Check the specific output for your script:

```bash
# Git script
ls -la .gitignore .gitattributes .git/

# Environment script
cat .env.example

# Packages script
npm list                # For Node
pip freeze              # For Python

# Docker script
docker-compose --version
```

---

## Running Multiple Scripts

Execute multiple bootstrap scripts in sequence with proper ordering.

### Step 1: Determine Execution Order

Bootstrap scripts should run in dependency order:

**Recommended Order:**
```
1. bootstrap-git.sh          (Foundation)
2. bootstrap-packages.sh     (Dependency management)
3. bootstrap-environment.sh  (Configuration)
4. bootstrap-linting.sh      (Code quality)
5. bootstrap-testing.sh      (Test setup)
6. bootstrap-typescript.sh   (Type checking - if applicable)
7. bootstrap-docker.sh       (Containerization - if needed)
8. bootstrap-vscode.sh       (Editor config - optional)
```

**Why This Order:**
- Git first (version control foundation)
- Packages second (dependencies for other tools)
- Environment third (config for development)
- Linting/Testing (code quality)
- TypeScript (language tooling)
- Docker (infrastructure - optional)
- VSCode (editor - optional)

### Step 2: Run Scripts Sequentially

Option A: Run from the menu (recommended for beginners):

```bash
./bootstrap-menu.sh

# Select phase 1, phase 2, etc.
```

Option B: Run scripts manually in order:

```bash
cd __bootbuild/scripts

./bootstrap-git.sh ../..
./bootstrap-packages.sh ../..
./bootstrap-environment.sh ../..
./bootstrap-linting.sh ../..
./bootstrap-testing.sh ../..
```

Option C: Create a bash script to run all:

```bash
#!/bin/bash
set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/__bootbuild/scripts" && pwd)"
PROJECT_ROOT="$(cd "${BOOTSTRAP_DIR}/../.." && pwd)"

# Phase 1: Foundation
"$BOOTSTRAP_DIR/bootstrap-git.sh" "$PROJECT_ROOT"
"$BOOTSTRAP_DIR/bootstrap-packages.sh" "$PROJECT_ROOT"
"$BOOTSTRAP_DIR/bootstrap-environment.sh" "$PROJECT_ROOT"

# Phase 2: Development Tools
"$BOOTSTRAP_DIR/bootstrap-linting.sh" "$PROJECT_ROOT"
"$BOOTSTRAP_DIR/bootstrap-testing.sh" "$PROJECT_ROOT"

# Phase 3: Advanced (optional)
# "$BOOTSTRAP_DIR/bootstrap-docker.sh" "$PROJECT_ROOT"

echo "✓ Bootstrap complete!"
```

### Step 3: Review Each Confirmation

Each script shows its pre-execution confirmation. Answer yes for each:

```bash
# For each script:
=== Pre-Execution Confirmation ===
Backup existing files: [yes/no] ?
# Type 'yes' to proceed
```

### Step 4: Monitor Overall Progress

Check the bootstrap log for overall status:

```bash
# Watch log in real-time
tail -f __bootbuild/bootstrap.log

# Or review after completion
cat __bootbuild/bootstrap.log | grep -E "(SUCCESS|FATAL|WARNING)"
```

### Step 5: Verify All Results

After all scripts complete, verify comprehensive setup:

```bash
# Version checks
git --version
npm --version  (or python --version)
node --version

# File checks
ls -la .git .gitignore .gitattributes
ls -la .env* node_modules/ (or venv/)
ls -la .eslintrc* tsconfig.json jest.config.js

# Directory checks
ls -la .vscode/ .idea/ (if applicable)
docker --version (if docker script ran)
```

---

## Configuration & Environment Variables

Control bootstrap behavior through configuration and environment variables.

### Step 1: Configuration File

The configuration file is located at:

```bash
# Primary location
__bootbuild/config/bootstrap.config

# Or specified by environment variable
$BOOTSTRAP_CONFIG
```

### Step 2: Configuration Sections

Edit the configuration file to customize behavior:

```ini
[project]
# Project metadata
name = "my-awesome-project"
description = "A description"
owner = "Your Name"

[profiles.dev]
# Development profile (active when phase == dev)
auto_approve = true
skip_docker = false

[auto_approve]
# Global auto-approval (requires BOOTSTRAP_YES=true)
git = true
packages = true
environment = true

[claude]
# Claude integration settings
enabled = true
version = "4.5"

[git]
# Git configuration
init_repo = true
create_gitignore = true
create_gitattributes = true

[packages]
# Package manager settings
manager = "npm"  # or "pip", "yarn", "pnpm"
install = true

[docker]
# Docker settings
enabled = false
dockerfile = true
docker_compose = true

[linting]
# Linting configuration
eslint = true
prettier = true
stylelint = true
```

### Step 3: Environment Variables

Override configuration with environment variables:

```bash
# Enable all confirmations without prompting
export BOOTSTRAP_YES=true

# Set project root explicitly
export PROJECT_ROOT=/path/to/project

# Specify alternate config file
export BOOTSTRAP_CONFIG=/path/to/custom.config

# Enable verbose output
export BOOTSTRAP_VERBOSE=true

# Skip validation steps
export SKIP_VALIDATION=false

# Then run scripts
./bootstrap-git.sh
./bootstrap-packages.sh
```

**Precedence (highest to lowest):**
1. Environment variables
2. Configuration file values
3. Script defaults

### Step 4: Get Current Configuration

Query current configuration:

```bash
# From within a running script, use config_get:
# (This requires lib/common.sh to be sourced)
source "${BOOTSTRAP_DIR}/lib/common.sh"

value=$(config_get "section" "key")
echo "Current value: $value"
```

Example:

```bash
source __bootbuild/lib/common.sh
pkg_manager=$(config_get "packages" "manager")
echo "Using package manager: $pkg_manager"
```

### Step 5: Modify Configuration Dynamically

Update configuration for current session:

```bash
# Before running bootstrap scripts
export BOOTSTRAP_CONFIG=/tmp/custom.config
cp __bootbuild/config/bootstrap.config "$BOOTSTRAP_CONFIG"

# Modify as needed
echo "[auto_approve]" >> "$BOOTSTRAP_CONFIG"
echo "docker = true" >> "$BOOTSTRAP_CONFIG"

# Run with custom config
./bootstrap-docker.sh
```

---

## Common Issues & Troubleshooting

### Issue 1: Permission Denied When Running Script

**Symptoms:**
```bash
./bootstrap-git.sh
bash: ./bootstrap-git.sh: Permission denied
```

**Root Cause:**
Script file is not executable.

**Solution:**

```bash
# Add execute permission
chmod +x __bootbuild/scripts/bootstrap-*.sh

# Verify
ls -la __bootbuild/scripts/bootstrap-git.sh
# Should show: -rwxr-xr-x

# Run again
./bootstrap-git.sh
```

**Prevention:**
Git tracks file permissions. Ensure execute bit is set in repository:

```bash
git update-index --chmod=+x __bootbuild/scripts/bootstrap-*.sh
git commit -m "chore: set execute permissions on bootstrap scripts"
```

---

### Issue 2: lib/common.sh Not Found

**Symptoms:**
```bash
./bootstrap-git.sh
source: line 21: __bootbuild/lib/common.sh: No such file or directory
```

**Root Cause:**
Script is not run from correct directory, or lib directory is missing.

**Solution:**

```bash
# Verify directory structure
ls -la __bootbuild/lib/
# Should show: common.sh

# Run script from correct location
cd /path/to/project
__bootbuild/scripts/bootstrap-git.sh

# Or verify path in script
grep "BOOTSTRAP_DIR=" __bootbuild/scripts/bootstrap-git.sh
# Should show: SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# And: BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
```

**Prevention:**
Always run scripts from within the project directory, or provide absolute path:

```bash
/absolute/path/to/__bootbuild/scripts/bootstrap-git.sh /absolute/path/to/project
```

---

### Issue 3: Bootstrap Config File Not Found

**Symptoms:**
```bash
./bootstrap-git.sh
WARNING: bootstrap.config not found, using defaults
```

**Root Cause:**
Configuration file missing or not in expected location.

**Solution:**

```bash
# Check for config file
ls -la __bootbuild/config/bootstrap.config

# Create default config if missing
cp __bootbuild/config/bootstrap.config.example __bootbuild/config/bootstrap.config

# Or specify via environment variable
export BOOTSTRAP_CONFIG=/path/to/bootstrap.config
./bootstrap-git.sh
```

**Prevention:**
Ensure bootstrap.config is in repository:

```bash
# Check git tracking
git status __bootbuild/config/bootstrap.config

# Add if missing
git add __bootbuild/config/bootstrap.config
git commit -m "chore: add bootstrap configuration"
```

---

### Issue 4: Script Exits with "not writable" Error

**Symptoms:**
```bash
./bootstrap-git.sh
FATAL: Project directory is not writable: /path/to/project
```

**Root Cause:**
Directory permissions prevent script from creating files.

**Solution:**

```bash
# Check current permissions
ls -lad /path/to/project
# Should show: drwxr-xr-x (or similar with owner having write)

# Fix permissions
chmod u+w /path/to/project

# If owned by different user
sudo chown -R $USER:$USER /path/to/project
sudo chmod -R u+w /path/to/project

# Run script again
./bootstrap-git.sh
```

**Prevention:**
Clone/create projects with proper permissions:

```bash
git clone <repo> --
# Permissions should inherit correctly

# Or explicitly set on new directory
mkdir -p /path/to/project
chmod 755 /path/to/project
```

---

### Issue 5: Git Repository Already Exists

**Symptoms:**
```bash
./bootstrap-git.sh
WARNING: Git repository already exists, skipping init
```

**Status:**
This is **NOT an error** - it's expected behavior. The script skips initialization if .git/ exists.

**Action:**
No action needed. If you want to reinitialize:

```bash
# Backup existing git data
mv .git .git.backup

# Run script to reinitialize
./bootstrap-git.sh

# Or restore original
rm -rf .git
mv .git.backup .git
```

---

## Post-Execution Steps

After bootstrap scripts complete, verify and configure your environment.

### Step 1: Review the Summary

Each script shows a summary:

```
=== Summary ===
Files created: 5
Files skipped: 0
Warnings: 0

✓ Git configuration complete!
```

**What to check:**
- [ ] "Files created" matches expected count
- [ ] "Warnings" is 0 (or acceptable)
- [ ] No "FATAL" errors reported

### Step 2: Review the Log

Check the bootstrap log for details:

```bash
# View log file
cat __bootbuild/bootstrap.log

# Or just the latest run
tail -100 __bootbuild/bootstrap.log

# Check for any issues
grep -E "(FATAL|ERROR)" __bootbuild/bootstrap.log
```

### Step 3: Verify Created Files

For each script you ran, verify its files exist:

```bash
# After bootstrap-git.sh
ls -la .gitignore .gitattributes .git/

# After bootstrap-packages.sh
ls -la package.json  # Node
ls -la requirements.txt  # Python

# After bootstrap-environment.sh
ls -la .env.example .env.local

# After bootstrap-linting.sh
ls -la .eslintrc* prettier* stylelint*

# After bootstrap-testing.sh
ls -la jest.config.js  # Node
ls -la pytest.ini  # Python
```

### Step 4: Customize Configuration Files

Edit configuration files created by bootstrap:

```bash
# Edit .env.example → .env.local
cp .env.example .env.local
nano .env.local
# Add your API keys, secrets, etc.

# Edit .gitignore
nano .gitignore
# Add project-specific ignore patterns

# Edit .eslintrc if needed
nano .eslintrc.json
# Customize linting rules for your project

# Edit tsconfig.json if needed
nano tsconfig.json
# Configure TypeScript compiler options
```

### Step 5: Install Dependencies

If bootstrap-packages.sh was run, install dependencies:

```bash
# Node projects
npm install
# or
yarn install
# or
pnpm install

# Python projects
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Step 6: Verify Integration

Test that your tools work correctly:

```bash
# Git
git status

# Linting
npm run lint  # or your linter command
# or
eslint .

# Testing
npm test
# or
pytest

# Building (if applicable)
npm run build
```

### Step 7: Commit Bootstrap Changes

Add bootstrap-created files to git:

```bash
# Check what would be committed
git status

# Add bootstrap configuration files
git add .gitignore .gitattributes .env.example .eslintrc* tsconfig.json jest.config.js

# Commit
git commit -m "chore: add bootstrap configuration files"

# Push to repository
git push origin main
```

---

## Advanced Usage

### Selective Script Execution

Run specific scripts without running a full phase:

```bash
# Define array of scripts to run
scripts=(
  "bootstrap-git.sh"
  "bootstrap-packages.sh"
  "bootstrap-environment.sh"
)

# Execute each
for script in "${scripts[@]}"; do
  __bootbuild/scripts/"$script"
done
```

### Dry Run (Check What Would Happen)

Review what a script would do without applying changes:

```bash
# Read the script to see what it would create
less __bootbuild/scripts/bootstrap-git.sh

# Look for these sections to understand the impact:
# - Pre-Execution Confirmation (what files will be created)
# - File creation sections (what content will be written)
```

### Running with Custom Configuration

Use environment variables for one-time customization:

```bash
# Auto-approve all confirmations
BOOTSTRAP_YES=true __bootbuild/scripts/bootstrap-git.sh

# Enable verbose output
BOOTSTRAP_VERBOSE=true __bootbuild/scripts/bootstrap-packages.sh

# Skip validation
SKIP_VALIDATION=true __bootbuild/scripts/bootstrap-docker.sh

# All at once
BOOTSTRAP_YES=true BOOTSTRAP_VERBOSE=true BOOTSTRAP_CONFIG=/custom.config \
  __bootbuild/scripts/bootstrap-git.sh
```

### Batch Operations

Run bootstrap across multiple projects:

```bash
#!/bin/bash
set -euo pipefail

# Projects to bootstrap
projects=(
  /path/to/project1
  /path/to/project2
  /path/to/project3
)

# Run for each project
for project in "${projects[@]}"; do
  echo "Bootstrapping: $project"

  cd "$project"
  __bootbuild/scripts/bootstrap-git.sh
  __bootbuild/scripts/bootstrap-packages.sh
  __bootbuild/scripts/bootstrap-environment.sh

  echo "✓ $project complete"
  echo ""
done

echo "✓ All projects bootstrapped!"
```

---

## Rolling Back Changes

If something goes wrong, recover using backups created by bootstrap scripts.

### Step 1: Identify Problem

Review logs to understand what went wrong:

```bash
# Check log for errors
grep FATAL __bootbuild/bootstrap.log

# Look for recent failures
tail -50 __bootbuild/bootstrap.log

# Search for specific script
grep "bootstrap-git" __bootbuild/bootstrap.log
```

### Step 2: Locate Backup Files

Bootstrap creates backups before modifying files:

```bash
# Look for backup files
ls -la *.backup
ls -la *.bak

# Example
ls -la .gitignore.backup
ls -la .env.example.bak
```

### Step 3: Restore from Backup

Restore backed-up files:

```bash
# Simple restore
mv .gitignore.backup .gitignore

# Restore with verification
if [ -f .gitignore.backup ]; then
  cp .gitignore .gitignore.new
  mv .gitignore.backup .gitignore
  echo "Restored .gitignore from backup"
fi
```

### Step 4: Remove Unwanted Files

If needed, remove files created by bootstrap:

```bash
# Remove specific file
rm .gitattributes

# Remove directory (careful!)
rm -rf .git/

# Remove multiple files
rm .env.example .eslintrc.json jest.config.js
```

### Step 5: Revert Git Changes

If you committed bootstrap files:

```bash
# See what was committed
git log --oneline -5

# Revert the commit
git revert <commit-hash>

# Or reset to before bootstrap
git reset --hard <earlier-commit>
```

### Step 6: Re-run Script (If Needed)

After fixing the problem, re-run the bootstrap script:

```bash
# Clean up and re-run
rm -f *.backup *.bak
__bootbuild/scripts/bootstrap-git.sh

# Or re-run entire phase
./bootstrap-menu.sh
```

### Complete Rollback Procedure

If everything goes wrong and you need a complete reset:

```bash
#!/bin/bash
set -euo pipefail

echo "⚠️  COMPLETE BOOTSTRAP ROLLBACK"
echo "This will remove all bootstrap-created files."
echo "Press Ctrl+C to cancel, Enter to continue."
read -p "Continue? "

# Remove created files (customize based on what was created)
rm -f .gitignore .gitattributes
rm -rf .git/
rm -f .env.example .env.local
rm -f .eslintrc* prettier* stylelint*
rm -f jest.config.js tsconfig.json

# Remove backups
rm -f *.backup *.bak

# Clean logs
rm -f __bootbuild/bootstrap.log*

echo "✓ Rollback complete!"
echo "You can now re-run bootstrap scripts fresh."
```

---

## Verification Checklist

Use this checklist to confirm successful bootstrap execution.

### Pre-Execution Verification

- [ ] Bash version 5.0+: `bash --version`
- [ ] Git installed: `git --version`
- [ ] Bootstrap directory exists: `ls -la __bootbuild/`
- [ ] lib/common.sh present: `ls -la __bootbuild/lib/common.sh`
- [ ] scripts directory exists: `ls -la __bootbuild/scripts/`
- [ ] Config file readable: `[ -r __bootbuild/config/bootstrap.config ]`
- [ ] Project directory writable: `[ -w . ]`

### Execution Verification

- [ ] Script ran without errors: `echo $?` shows 0
- [ ] Log file updated: `tail __bootbuild/bootstrap.log`
- [ ] Expected files created: `git status` shows new files
- [ ] No FATAL errors: `grep FATAL __bootbuild/bootstrap.log` is empty
- [ ] Summary shows files created: "Files created: X" > 0
- [ ] No warnings (or acceptable): `grep WARNING __bootbuild/bootstrap.log`

### Post-Execution Verification

- [ ] Files have correct permissions: `ls -la .gitignore`
- [ ] Files have correct content: `head -20 .gitignore`
- [ ] Backups created for modified files: `ls -la *.backup`
- [ ] Bootstrap log is readable: `cat __bootbuild/bootstrap.log`
- [ ] All tools accessible: `npm --version`, `git status`, `docker --version`
- [ ] Configuration working: `git config user.name` returns value
- [ ] Environment variables set: `env | grep PROJECT_ROOT`

---

## Summary

The bootstrap system provides a streamlined way to initialize new projects with consistent configuration. By following this playbook, you can:

1. **Verify prerequisites** before running scripts
2. **Execute scripts** individually or in phases
3. **Configure behavior** through environment variables
4. **Troubleshoot issues** using common solutions
5. **Verify results** with comprehensive checklists
6. **Rollback changes** if needed

Remember:
- **Always review pre-execution confirmations** before allowing changes
- **Check the bootstrap log** after each run for detailed information
- **Verify file creation** matches expected output
- **Commit bootstrap files** to version control after successful execution
- **Keep backups** until you're certain everything works correctly

For more information:
- See [PLAYBOOK_CREATING_SCRIPTS.md](PLAYBOOK_CREATING_SCRIPTS.md) for creating new bootstrap scripts
- See [PLAYBOOK_MIGRATING_SCRIPTS.md](PLAYBOOK_MIGRATING_SCRIPTS.md) for standardizing existing scripts
- See [REFERENCE_LIBRARY.md](../references/REFERENCE_LIBRARY.md) for function documentation
- See [REFERENCE_CONFIG.md](../references/REFERENCE_CONFIG.md) for configuration options
