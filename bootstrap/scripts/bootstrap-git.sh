#!/bin/bash

# ===================================================================
# bootstrap-git.sh
#
# Bootstrap Git configuration for a new project
# Sets up .gitignore, .gitattributes, and git hooks
# ===================================================================

set -e

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"
TEMPLATE_GIT="${TEMPLATE_DIR}/.gitignore"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===================================================================
# Utility Functions
# ===================================================================

log_info() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# Backup existing file
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%s)"
        if cp "$file" "$backup"; then
            log_warning "Backed up existing file to: $(basename "$backup")"
            return 0
        else
            log_error "Failed to backup existing file: $file"
        fi
    fi
    return 1
}

# Verify file creation
verify_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "Failed to create file: $file"
    elif [[ ! -r "$file" ]]; then
        log_error "Created file but it's not readable: $file"
    else
        log_success "File created and verified: $file"
        return 0
    fi
    return 1
}

# Cleanup on exit
cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Bootstrap script failed with exit code $exit_code"
        log_info "Check the output above for details"
    fi
    return $exit_code
}

trap cleanup_on_error EXIT

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Git configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_error "Project directory is not writable: $PROJECT_ROOT"
fi

# ===================================================================
# Create .gitignore
# ===================================================================

log_info "Creating .gitignore..."

# Check if .gitignore already exists
if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
    log_warning ".gitignore already exists"
    backup_file "$PROJECT_ROOT/.gitignore" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
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
    verify_file "$PROJECT_ROOT/.gitignore" || log_error "Failed to verify .gitignore"
else
    log_error "Failed to create .gitignore"
fi

# ===================================================================
# Create .gitattributes
# ===================================================================

log_info "Creating .gitattributes..."

# Check if .gitattributes already exists
if [[ -f "$PROJECT_ROOT/.gitattributes" ]]; then
    log_warning ".gitattributes already exists"
    backup_file "$PROJECT_ROOT/.gitattributes" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
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
    verify_file "$PROJECT_ROOT/.gitattributes" || log_error "Failed to verify .gitattributes"
else
    log_error "Failed to create .gitattributes"
fi

# ===================================================================
# Initialize Git repository if needed
# ===================================================================

if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    log_info "Initializing Git repository..."

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please install Git first"
    fi

    # Initialize the repository
    if cd "$PROJECT_ROOT" && git init; then
        if git config user.email "development@local" && git config user.name "Development"; then
            log_success "Git repository initialized"
        else
            log_warning "Git repository created but configuration failed (non-critical)"
        fi
    else
        log_error "Failed to initialize Git repository"
    fi
else
    log_warning "Git repository already exists, skipping init"
fi

# ===================================================================
# Summary
# ===================================================================

echo ""
log_success "Git configuration complete!"
echo ""
echo "Files created:"
echo "  - .gitignore"
echo "  - .gitattributes"
echo ""
echo "Next steps:"
echo "  1. Customize .gitignore if needed"
echo "  2. Run: git add .gitignore .gitattributes"
echo "  3. Run: git commit -m 'chore: add git configuration'"
echo ""
