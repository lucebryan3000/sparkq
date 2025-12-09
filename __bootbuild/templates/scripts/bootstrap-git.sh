#!/bin/bash
# =============================================================================
# @script         bootstrap-git
# @version        1.0.0
# @phase          1
# @category       vcs
# @priority       50
# @short          Git configuration for new project
# @description    Initializes Git repository and creates .gitignore with
#                 sensible defaults for Node.js, Python, IDE artifacts,
#                 environment files, and build outputs. Sets up Git attributes
#                 for consistent line endings and merge strategies.
#
# @creates        .gitignore
# @creates        .gitattributes
# @creates        .git/
#
#
# @detects        has_gitignore
# @questions      git
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  none
# @env_vars        none
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf .gitignore .gitattributes .git/
# @verify          test -f .gitignore
# @docs            https://git-scm.com/doc
# =============================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-git"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-git"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "git" \
    --scripts "" \
    --optional ""

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Git Configuration" \
    ".gitignore" ".gitattributes" ".git/"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Git configuration..."

# Verify project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Verify project directory is writable
is_writable "$PROJECT_ROOT" || log_fatal "Project directory is not writable: $PROJECT_ROOT"

# ===================================================================
# Create .gitignore
# ===================================================================

log_info "Creating .gitignore..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.gitignore"; then
    log_warning ".gitignore already exists, skipping"
    track_skipped ".gitignore"
else
    if cat > "$PROJECT_ROOT/.gitignore" << 'EOFGITIGNORE'
# Dependencies
node_modules/
pnpm-lock.yaml
yarn.lock
package-lock.json
.pnpm-store/

# Environment
.env
.env.local
.env.*.local

# Build artifacts
dist/
build/
.next/
out/
.vercel/
*.tsbuildinfo

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
.project
.classpath
.c9/

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
pnpm-debug.log*

# OS
.DS_Store
Thumbs.db

# Testing
.nyc_output/
coverage/
.jest_cache/

# Database
*.db
*.sqlite
*.sqlite3

# Cache
.eslintcache
.stylelintcache
.cache/

# Temporary
tmp/
temp/
.tmp/
EOFGITIGNORE
    then
        verify_file "$PROJECT_ROOT/.gitignore"
        track_created ".gitignore"
        log_file_created "$SCRIPT_NAME" ".gitignore"
    else
        log_fatal "Failed to create .gitignore"
    fi
fi

# ===================================================================
# Create .gitattributes
# ===================================================================

log_info "Creating .gitattributes..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.gitattributes"; then
    log_warning ".gitattributes already exists, skipping"
    track_skipped ".gitattributes"
else
    if cat > "$PROJECT_ROOT/.gitattributes" << 'EOFATTR'
# Auto detect text files and normalize line endings
* text=auto

# Shell scripts
*.sh text eol=lf
*.bash text eol=lf

# Windows batch files
*.bat text eol=crlf
*.cmd text eol=crlf

# JavaScript/TypeScript
*.js text eol=lf
*.ts text eol=lf
*.jsx text eol=lf
*.tsx text eol=lf
*.json text eol=lf

# Python
*.py text eol=lf

# YAML/Config
*.yml text eol=lf
*.yaml text eol=lf
.gitignore text eol=lf

# Documentation
*.md text eol=lf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.mov binary
*.mp4 binary
*.mp3 binary
*.gz binary
*.zip binary
*.7z binary
*.ttf binary
*.otf binary
*.db binary
*.sqlite binary
EOFATTR
    then
        verify_file "$PROJECT_ROOT/.gitattributes"
        track_created ".gitattributes"
        log_file_created "$SCRIPT_NAME" ".gitattributes"
    else
        log_fatal "Failed to create .gitattributes"
    fi
fi

# ===================================================================
# Initialize Git repository if needed
# ===================================================================

log_info "Initializing Git repository..."

# Check if git is installed
require_command "git" || log_fatal "Git is required but not installed. Please install Git first"

# Check if repository already exists
if ! dir_exists "$PROJECT_ROOT/.git"; then
    if git -C "$PROJECT_ROOT" init > /dev/null 2>&1; then
        log_success "Git repository initialized"
        track_created ".git/"
        log_dir_created "$SCRIPT_NAME" ".git/"
    else
        log_fatal "Failed to initialize Git repository"
    fi
else
    log_warning "Git repository already exists, skipping init"
    track_skipped ".git/"
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Git configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Customize .gitignore if needed"
echo "  2. Run: git add .gitignore .gitattributes"
echo "  3. Run: git commit -m 'chore: add git configuration'"
echo ""

show_log_location
