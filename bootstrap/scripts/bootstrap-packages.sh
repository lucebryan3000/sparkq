#!/bin/bash

# ===================================================================
# bootstrap-packages.sh
#
# Bootstrap package management and runtime versions
# Sets up .npmrc, .nvmrc, .tool-versions, and .envrc
# ===================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${BOOTSTRAP_DIR}/templates"
PROJECT_ROOT="${1:-.}"

# Source libraries
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Answers file
ANSWERS_FILE=".bootstrap-answers.env"

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

log_info "Bootstrapping package management configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_error "Project directory is not writable: $PROJECT_ROOT"
fi

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
    verify_file "$PROJECT_ROOT/.npmrc" || log_error "Failed to verify .npmrc"
else
    log_error "Failed to create .npmrc"
fi

# ===================================================================
# Create .nvmrc
# ===================================================================

log_info "Creating .nvmrc..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed. Please install Node.js first"
fi

# Get the current Node.js version
CURRENT_NODE=$(node --version | sed 's/^v//')
if [[ -z "$CURRENT_NODE" ]]; then
    log_error "Failed to detect Node.js version"
fi

if cat > "$PROJECT_ROOT/.nvmrc" << EOF
$CURRENT_NODE
EOF
then
    verify_file "$PROJECT_ROOT/.nvmrc" || log_error "Failed to verify .nvmrc"
    log_success ".nvmrc created (Node.js $CURRENT_NODE)"
else
    log_error "Failed to create .nvmrc"
fi

# ===================================================================
# Create .tool-versions (asdf)
# ===================================================================

log_info "Creating .tool-versions..."

if cat > "$PROJECT_ROOT/.tool-versions" << EOF
nodejs $CURRENT_NODE
EOF
then
    verify_file "$PROJECT_ROOT/.tool-versions" || log_error "Failed to verify .tool-versions"
else
    log_error "Failed to create .tool-versions"
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
    verify_file "$PROJECT_ROOT/.envrc" || log_error "Failed to verify .envrc"
else
    log_error "Failed to create .envrc"
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
        verify_file "$PROJECT_ROOT/package.json" || log_error "Failed to verify package.json"
    else
        log_error "Failed to create package.json"
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
