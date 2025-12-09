#!/bin/bash
# =============================================================================
# @script         bootstrap-packages
# @version        1.0.0
# @phase          2
# @category       nodejs
# @priority       50
# @short          Package management and runtime configuration
# @description    Sets up package management configuration including npm
#                 registry, Node version specification, tool-versions for
#                 asdf compatibility, direnv support, and package.json setup.
#
# @creates        .npmrc
# @creates        .nvmrc
# @creates        .tool-versions
# @creates        .envrc
# @creates        package.json
#
# @depends        project
#
# @detects        has_node_modules
# @questions      packages
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  none
# @env_vars        CURRENT_NODE
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf .npmrc .nvmrc .tool-versions .envrc package.json
# @verify          test -f .npmrc
# @docs            https://docs.npmjs.com/
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
init_script "bootstrap-packages"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-packages"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "node npm" \
    --scripts "bootstrap-project" \
    --optional ""


# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Package Management Configuration" \
    ".npmrc" \
    ".nvmrc" \
    ".tool-versions" \
    ".envrc" \
    "package.json"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Verify project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Verify project directory is writable
is_writable "$PROJECT_ROOT" || log_fatal "Project directory is not writable: $PROJECT_ROOT"

# Check if Node.js is installed
require_command "node" || log_fatal "Node.js is required but not installed"

log_success "Environment validated"

# ===================================================================
# Create .npmrc
# ===================================================================

log_info "Creating .npmrc..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.npmrc"; then
    log_warning ".npmrc already exists, skipping"
    track_skipped ".npmrc"
else
    if cat > "$PROJECT_ROOT/.npmrc" << 'EOFNPMRC'
# NPM package manager configuration
# For pnpm, use: pnpm config set [key] [value]

# Use exact versions, don't auto-update
save-exact=true

# Use lockfile-v2 for better dependency resolution
lockfile-version=3

# Authenticate with private registries
# registry=https://registry.npmjs.org/
# @org:registry=https://registry.npmjs.org/

# Reduce npm verbosity
loglevel=warn

# Disable audit advisories
audit=false

# Use legacy peer deps (optional, comment out if not needed)
# legacy-peer-deps=true
EOFNPMRC
    then
        verify_file "$PROJECT_ROOT/.npmrc"
        track_created ".npmrc"
        log_file_created "$SCRIPT_NAME" ".npmrc"
    else
        log_fatal "Failed to create .npmrc"
    fi
fi

# ===================================================================
# Create .nvmrc
# ===================================================================

log_info "Creating .nvmrc..."

# Get the current Node.js version
CURRENT_NODE=$(node --version | sed 's/^v//')
if [[ -z "$CURRENT_NODE" ]]; then
    log_fatal "Failed to detect Node.js version"
fi

# Skip if file exists
if file_exists "$PROJECT_ROOT/.nvmrc"; then
    log_warning ".nvmrc already exists, skipping"
    track_skipped ".nvmrc"
else
    if cat > "$PROJECT_ROOT/.nvmrc" << EOF
$CURRENT_NODE
EOF
    then
        verify_file "$PROJECT_ROOT/.nvmrc"
        track_created ".nvmrc"
        log_file_created "$SCRIPT_NAME" ".nvmrc"
    else
        log_fatal "Failed to create .nvmrc"
    fi
fi

# ===================================================================
# Create .tool-versions (asdf)
# ===================================================================

log_info "Creating .tool-versions..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.tool-versions"; then
    log_warning ".tool-versions already exists, skipping"
    track_skipped ".tool-versions"
else
    if cat > "$PROJECT_ROOT/.tool-versions" << EOFTOOLS
nodejs $CURRENT_NODE
EOFTOOLS
    then
        verify_file "$PROJECT_ROOT/.tool-versions"
        track_created ".tool-versions"
        log_file_created "$SCRIPT_NAME" ".tool-versions"
    else
        log_fatal "Failed to create .tool-versions"
    fi
fi

# ===================================================================
# Create .envrc (direnv)
# ===================================================================

log_info "Creating .envrc..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.envrc"; then
    log_warning ".envrc already exists, skipping"
    track_skipped ".envrc"
else
    if cat > "$PROJECT_ROOT/.envrc" << 'EOFENVRC'
# direnv configuration for automatic environment loading
# Install direnv: https://direnv.net/docs/installation.html

# Load .env.local if it exists
if [ -f .env.local ]; then
    dotenv .env.local
fi

# Load .env if it exists
if [ -f .env ]; then
    dotenv .env
fi

# Add node_modules/.bin to PATH
export PATH="./node_modules/.bin:$PATH"

# Optional: Use NVM for Node.js version management
if command -v nvm &> /dev/null; then
    nvm use 2>/dev/null || true
fi

# Optional: Use asdf for tool version management
if command -v asdf &> /dev/null; then
    eval "$(asdf env)"
fi
EOFENVRC
    then
        verify_file "$PROJECT_ROOT/.envrc"
        track_created ".envrc"
        log_file_created "$SCRIPT_NAME" ".envrc"
    else
        log_fatal "Failed to create .envrc"
    fi
fi

# ===================================================================
# Create package.json if it doesn't exist
# ===================================================================

log_info "Creating package.json..."

if file_exists "$PROJECT_ROOT/package.json"; then
    log_warning "package.json already exists, skipping"
    track_skipped "package.json"
else
    if cat > "$PROJECT_ROOT/package.json" << 'EOFPKG'
{
  "name": "project",
  "version": "0.0.1",
  "description": "A SparkQ project",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "node --watch src/index.js",
    "build": "tsc",
    "test": "node --test",
    "lint": "eslint src/",
    "format": "prettier --write ."
  },
  "keywords": [],
  "author": "",
  "license": "MIT",
  "devDependencies": {},
  "dependencies": {}
}
EOFPKG
    then
        verify_file "$PROJECT_ROOT/package.json"
        track_created "package.json"
        log_file_created "$SCRIPT_NAME" "package.json"
    else
        log_fatal "Failed to create package.json"
    fi
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Package management configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Edit package.json name field to match your project"
echo "  2. Install Node.js version: nvm install (or asdf install)"
echo "  3. Allow direnv: direnv allow (if using direnv)"
echo "  4. Install dependencies: npm install (or pnpm install)"
echo "  5. Commit files: git add .npmrc .nvmrc .tool-versions .envrc package.json"
echo ""
echo "Tools:"
echo "  - nvm: https://github.com/nvm-sh/nvm"
echo "  - asdf: https://asdf-vm.com/"
echo "  - direnv: https://direnv.net/"
echo "  - pnpm: https://pnpm.io/"
echo ""

show_log_location
