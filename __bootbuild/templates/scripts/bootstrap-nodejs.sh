#!/bin/bash
# =============================================================================
# @script         bootstrap-nodejs
# @version        1.0.0
# @phase          2
# @category       nodejs
# @priority       50
# @short          Node.js runtime and package manager configuration
# @description    Configures Node.js runtime with version specification (.nvmrc),
#                 npm configuration (.npmrc), Yarn configuration (.yarnrc.yml),
#                 and PNPM configuration (.pnpmfile.cjs) for consistent package
#                 management across team and environments.
#
# @creates        .nvmrc
# @creates        .npmrc
# @creates        .yarnrc.yml
# @creates        .pnpmfile.cjs
#
# @depends        project
# @detects        has_package_json
# @questions      none
# @defaults       nodejs.enabled=true, nodejs.version=20
# @detects        has_package_json
# @questions      none
# @defaults       nodejs.package_manager=npm
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  nodejs
# @env_vars        ENABLED,NODE_VERSION
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf .nvmrc .npmrc .yarnrc.yml .pnpmfile.cjs
# @verify          test -f .nvmrc
# @docs            https://nodejs.org/docs/latest/api/
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
init_script "bootstrap-nodejs"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-nodejs"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "node" \
    --scripts "bootstrap-project" \
    --optional ""

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "nodejs.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Node.js bootstrap disabled in config"
    exit 0
fi

# Read nodejs-specific settings
NODE_VERSION=$(config_get "nodejs.version" "20")
PACKAGE_MANAGER=$(config_get "nodejs.package_manager" "npm")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Node.js Configuration" \
    ".nvmrc" \
    ".npmrc" \
    ".yarnrc.yml" \
    ".pnpmfile.cjs"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check Node.js availability
if ! has_command "node"; then
    track_warning "Node.js not installed - some validation skipped"
    log_warning "Node.js not installed"
else
    local node_version=$(node --version)
    log_success "Node.js detected: $node_version"
fi

log_success "Environment validated"

# ===================================================================
# Create .nvmrc (Node Version Manager)
# ===================================================================

log_info "Creating .nvmrc..."

if file_exists "$PROJECT_ROOT/.nvmrc"; then
    backup_file "$PROJECT_ROOT/.nvmrc"
    track_skipped ".nvmrc (backed up)"
    log_warning ".nvmrc already exists, backed up"
else
    if echo "$NODE_VERSION" > "$PROJECT_ROOT/.nvmrc"; then
        verify_file "$PROJECT_ROOT/.nvmrc"
        log_file_created "$SCRIPT_NAME" ".nvmrc"
        track_created ".nvmrc"
    else
        log_fatal "Failed to create .nvmrc"
    fi
fi

# ===================================================================
# Create .npmrc (NPM Configuration)
# ===================================================================

log_info "Creating .npmrc..."

if file_exists "$PROJECT_ROOT/.npmrc"; then
    backup_file "$PROJECT_ROOT/.npmrc"
    track_skipped ".npmrc (backed up)"
    log_warning ".npmrc already exists, backed up"
else
    if cat > "$PROJECT_ROOT/.npmrc" << 'EOFNPMRC'
# NPM Configuration
# Package Management

# Authentication & Registry
registry=https://registry.npmjs.org/

# Package Installation
save-exact=false
save-prefix=^
legacy-peer-deps=false

# Performance & Caching
prefer-offline=true
fetch-timeout=120000
fetch-retries=3

# Security
audit=true
audit-level=moderate

# Development
prefer-workspace-root=true
ignore-workspace-root-check=false

# Output
progress=true
loglevel=warn

# Engine Validation
engine-strict=false

# Lockfile Management
package-lock=true
EOFNPMRC
    then
        verify_file "$PROJECT_ROOT/.npmrc"
        log_file_created "$SCRIPT_NAME" ".npmrc"
        track_created ".npmrc"
    else
        log_fatal "Failed to create .npmrc"
    fi
fi

# ===================================================================
# Create .yarnrc.yml (Yarn Configuration)
# ===================================================================

log_info "Creating .yarnrc.yml..."

if file_exists "$PROJECT_ROOT/.yarnrc.yml"; then
    backup_file "$PROJECT_ROOT/.yarnrc.yml"
    track_skipped ".yarnrc.yml (backed up)"
    log_warning ".yarnrc.yml already exists, backed up"
else
    if cat > "$PROJECT_ROOT/.yarnrc.yml" << 'EOFYARNRC'
# Yarn Configuration (v3+)

# Node Version Manager
nodeLinker: node-modules

# Package Management
packageExtensions:
  '*': {}

# Performance
enableGlobalCache: true
enableScripts: true

# Compression
compressionLevel: mixed

# Workspaces
workspaceRoot: .

# Telemetry
enableTelemetry: false

# Lockfile
lockfileVersion: 9

# Environment
installStatePath: .yarn/install-state.gz
EOFYARNRC
    then
        verify_file "$PROJECT_ROOT/.yarnrc.yml"
        log_file_created "$SCRIPT_NAME" ".yarnrc.yml"
        track_created ".yarnrc.yml"
    else
        log_fatal "Failed to create .yarnrc.yml"
    fi
fi

# ===================================================================
# Create .pnpmfile.cjs (PNPM Configuration)
# ===================================================================

log_info "Creating .pnpmfile.cjs..."

if file_exists "$PROJECT_ROOT/.pnpmfile.cjs"; then
    backup_file "$PROJECT_ROOT/.pnpmfile.cjs"
    track_skipped ".pnpmfile.cjs (backed up)"
    log_warning ".pnpmfile.cjs already exists, backed up"
else
    if cat > "$PROJECT_ROOT/.pnpmfile.cjs" << 'EOFPNPMFILE'
// pnpm Hook Configuration
// This file allows for custom modifications before dependency installation

module.exports = {
  // Hook that runs before each dependency is installed
  hooks: {
    beforePackageInstall(stage, pkg) {
      // Example: Log installation of specific packages
      // if (pkg.name === 'some-package') {
      //   console.log(`Installing ${pkg.name}@${pkg.version}`)
      // }
    },
  },

  // Custom package mutator function
  // Use this to modify package.json before installation
  // Example: Replace package versions or add fields
  packageExtensions: {
    // Adjust peer dependencies if needed
    // 'package-name': {
    //   peerDependencies: {
    //     'other-package': '*'
    //   }
    // }
  },
}
EOFPNPMFILE
    then
        verify_file "$PROJECT_ROOT/.pnpmfile.cjs"
        log_file_created "$SCRIPT_NAME" ".pnpmfile.cjs"
        track_created ".pnpmfile.cjs"
    else
        log_fatal "Failed to create .pnpmfile.cjs"
    fi
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Node.js configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Node.js version: $NODE_VERSION (configured in .nvmrc)"
echo "  2. Install Node.js with nvm: nvm install $NODE_VERSION"
echo "  3. Activate version: nvm use"
echo ""
echo "Package manager setup:"
echo "  - npm:  Configured in .npmrc (built-in with Node.js)"
echo "  - yarn: Install with: npm install -g yarn"
echo "  - pnpm: Install with: npm install -g pnpm"
echo ""
echo "To switch package managers:"
echo "  - npm:  npm install (uses .npmrc)"
echo "  - yarn: yarn install (uses .yarnrc.yml)"
echo "  - pnpm: pnpm install (uses .pnpmfile.cjs)"
echo ""
echo "Recommendations:"
echo "  - Use npm for simplicity (included with Node.js)"
echo "  - Use pnpm for faster, stricter dependency management"
echo "  - Use yarn for legacy projects"
echo ""

show_log_location
