#!/bin/bash

# ===================================================================
# bootstrap-git.sh
#
# Bootstrap Git configuration for a new project
# Sets up .gitignore, .gitattributes, and git hooks
# ===================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Initialize script
init_script "bootstrap-git.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "bootstrap-git" "Git Configuration" \
    ".gitignore" ".gitattributes" "Git repository init"

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

# Check if .gitignore already exists
if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.gitignore"
        log_warning ".gitignore existed, backed up"
    else
        track_skipped ".gitignore"
        log_warning ".gitignore already exists, skipping"
    fi
fi

if cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
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
EOF
then
    if verify_file "$PROJECT_ROOT/.gitignore"; then
        track_created ".gitignore"
        log_file_created "bootstrap-git" ".gitignore"
    fi
else
    log_fatal "Failed to create .gitignore"
fi

# ===================================================================
# Create .gitattributes
# ===================================================================

log_info "Creating .gitattributes..."

# Check if .gitattributes already exists
if [[ -f "$PROJECT_ROOT/.gitattributes" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.gitattributes"
        log_warning ".gitattributes existed, backed up"
    else
        track_skipped ".gitattributes"
        log_warning ".gitattributes already exists, skipping"
    fi
fi

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
    if verify_file "$PROJECT_ROOT/.gitattributes"; then
        track_created ".gitattributes"
        log_file_created "bootstrap-git" ".gitattributes"
    fi
else
    log_fatal "Failed to create .gitattributes"
fi

# ===================================================================
# Initialize Git repository if needed
# ===================================================================

if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    if is_auto_approved "git_init"; then
        log_info "Initializing Git repository..."

        # Check if git is installed
        require_command "git" || log_fatal "Git is not installed. Please install Git first"

        # Initialize the repository
        if cd "$PROJECT_ROOT" && git init; then
            log_success "Git repository initialized"
            track_created ".git/"
            log_dir_created "bootstrap-git" ".git/"
        else
            log_fatal "Failed to initialize Git repository"
        fi
    else
        log_info "Git init skipped (not auto-approved)"
        track_skipped ".git/"
    fi
else
    log_warning "Git repository already exists, skipping init"
    track_skipped ".git/ (exists)"
fi

# ===================================================================
# Summary
# ===================================================================

show_summary
log_script_complete "bootstrap-git" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_log_location

log_info "Next steps:"
echo "  1. Customize .gitignore if needed"
echo "  2. Run: git add .gitignore .gitattributes"
echo "  3. Run: git commit -m 'chore: add git configuration'"
echo ""
