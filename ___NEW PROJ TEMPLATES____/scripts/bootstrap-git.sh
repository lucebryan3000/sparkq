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

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Git configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# ===================================================================
# Create .gitignore
# ===================================================================

log_info "Creating .gitignore..."

cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
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

log_success ".gitignore created"

# ===================================================================
# Create .gitattributes
# ===================================================================

log_info "Creating .gitattributes..."

cat > "$PROJECT_ROOT/.gitattributes" << 'EOFATTR'
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

log_success ".gitattributes created"

# ===================================================================
# Initialize Git repository if needed
# ===================================================================

if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    log_info "Initializing Git repository..."
    cd "$PROJECT_ROOT"
    git init
    git config user.email "development@local" || true
    git config user.name "Development" || true
    log_success "Git repository initialized"
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
