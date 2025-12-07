#!/bin/bash

# ===================================================================
# bootstrap-packages.sh
#
# Bootstrap package management and runtime versions
# Sets up .npmrc, .nvmrc, .tool-versions, and .envrc
# ===================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-packages.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Answers file
ANSWERS_FILE=".bootstrap-answers.env"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping package management configuration..."

# Verify project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Verify project directory is writable
is_writable "$PROJECT_ROOT" || log_fatal "Project directory is not writable: $PROJECT_ROOT"

# ===================================================================
# Create .npmrc
# ===================================================================

log_info "Creating .npmrc..."

# Check if .npmrc already exists
if [[ -f "$PROJECT_ROOT/.npmrc" ]]; then
    log_warning ".npmrc already exists"
    backup_file "$PROJECT_ROOT/.npmrc" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if cat > "$PROJECT_ROOT/.npmrc" << 'EOF'
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
EOF
then
    verify_file "$PROJECT_ROOT/.npmrc" || log_fatal "Failed to verify .npmrc"
else
    log_fatal "Failed to create .npmrc"
fi

# ===================================================================
# Create .nvmrc
# ===================================================================

log_info "Creating .nvmrc..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    log_fatal "Node.js is not installed. Please install Node.js first"
fi

# Get the current Node.js version
CURRENT_NODE=$(node --version | sed 's/^v//')
if [[ -z "$CURRENT_NODE" ]]; then
    log_fatal "Failed to detect Node.js version"
fi

if cat > "$PROJECT_ROOT/.nvmrc" << EOF
$CURRENT_NODE
EOF
then
    verify_file "$PROJECT_ROOT/.nvmrc" || log_fatal "Failed to verify .nvmrc"
    log_success ".nvmrc created (Node.js $CURRENT_NODE)"
else
    log_fatal "Failed to create .nvmrc"
fi

# ===================================================================
# Create .tool-versions (asdf)
# ===================================================================

log_info "Creating .tool-versions..."

if cat > "$PROJECT_ROOT/.tool-versions" << EOF
nodejs $CURRENT_NODE
EOF
then
    verify_file "$PROJECT_ROOT/.tool-versions" || log_fatal "Failed to verify .tool-versions"
else
    log_fatal "Failed to create .tool-versions"
fi

# ===================================================================
# Create .envrc (direnv)
# ===================================================================

log_info "Creating .envrc..."

if cat > "$PROJECT_ROOT/.envrc" << 'EOF'
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
EOF
then
    verify_file "$PROJECT_ROOT/.envrc" || log_fatal "Failed to verify .envrc"
else
    log_fatal "Failed to create .envrc"
fi

# ===================================================================
# Create package.json if it doesn't exist
# ===================================================================

if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
    log_info "Creating package.json..."

    if cat > "$PROJECT_ROOT/package.json" << 'EOF'
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
EOF
    then
        verify_file "$PROJECT_ROOT/package.json" || log_fatal "Failed to verify package.json"
    else
        log_fatal "Failed to create package.json"
    fi
else
    log_warning "package.json already exists, skipping creation"
fi

# ===================================================================
# Template Customization
# ===================================================================

customize_templates() {
    log_info "Customizing templates with your configuration..."

    # Only customize if answers file exists
    if [[ ! -f "$ANSWERS_FILE" ]]; then
        log_warning "No answers file found. Skipping customization."
        return 0
    fi

    # Source answers
    source "$ANSWERS_FILE"

    local customized=0

    # Customize package.json if it exists
    if [[ -f "${PROJECT_ROOT}/package.json" ]]; then
        log_info "Customizing package.json..."

        # Update package name
        if [[ -n "${PACKAGE_NAME:-}" ]]; then
            update_json_field "${PROJECT_ROOT}/package.json" "name" "$PACKAGE_NAME"
            ((customized++))
        fi

        # Update package manager
        if [[ -n "${PACKAGE_MANAGER:-}" ]] && [[ -n "${NODE_VERSION:-}" ]]; then
            local pm_version=""
            case "$PACKAGE_MANAGER" in
                pnpm) pm_version="pnpm@9.6.0" ;;
                npm) pm_version="npm@10.0.0" ;;
                yarn) pm_version="yarn@4.0.0" ;;
            esac
            if [[ -n "$pm_version" ]]; then
                update_json_field "${PROJECT_ROOT}/package.json" "packageManager" "$pm_version"
                ((customized++))
            fi
        fi

        log_success "package.json customized"
    fi

    # Update .nvmrc if it exists
    if [[ -f "${PROJECT_ROOT}/.nvmrc" ]] && [[ -n "${NODE_VERSION:-}" ]]; then
        log_info "Updating .nvmrc with Node version ${NODE_VERSION}..."
        echo "$NODE_VERSION" > "${PROJECT_ROOT}/.nvmrc"
        ((customized++))
        log_success ".nvmrc updated"
    fi

    # Update config with answers
    config_update_from_answers "$ANSWERS_FILE"

    if [[ $customized -gt 0 ]]; then
        log_success "Applied $customized customizations"
    else
        log_info "No customizations applied"
    fi

    return 0
}

# Run customization if answers exist
if [[ -f "$ANSWERS_FILE" ]]; then
    customize_templates
    echo ""
fi

# ===================================================================
# Summary
# ===================================================================

echo ""
log_success "Package management configuration complete!"
echo ""
echo "Files created:"
echo "  - .npmrc"
echo "  - .nvmrc"
echo "  - .tool-versions"
echo "  - .envrc"
echo "  - package.json"
echo ""
echo "Next steps:"
if [[ -f "$ANSWERS_FILE" ]]; then
    echo "  ✓ package.json and .nvmrc have been customized"
    echo "  1. Install Node.js version: nvm install (or asdf install)"
    echo "  2. Allow direnv: direnv allow (if using direnv)"
    echo "  3. Install dependencies: ${PACKAGE_MANAGER:-pnpm} install"
    echo "  4. Commit files: git add .npmrc .nvmrc .tool-versions .envrc package.json"
else
    echo "  1. Edit package.json name field"
    echo "  2. Install Node.js version: nvm install (or asdf install)"
    echo "  3. Allow direnv: direnv allow (if using direnv)"
    echo "  4. Install dependencies: npm install (or pnpm install)"
    echo "  5. Commit files: git add .npmrc .nvmrc .tool-versions .envrc package.json"
    echo "  Tip: Run with --interactive mode for automatic customization"
fi
echo ""
echo "Tools:"
echo "  - nvm: https://github.com/nvm-sh/nvm"
echo "  - asdf: https://asdf-vm.com/"
echo "  - direnv: https://direnv.net/"
echo "  - pnpm: https://pnpm.io/"
echo ""
