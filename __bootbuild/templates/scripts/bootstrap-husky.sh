#!/bin/bash

# ===================================================================
# bootstrap-husky.sh
#
# Bootstrap Git hooks management using Husky
# Creates .husky/ directory with pre-commit, commit-msg, and other hooks
# Config: [husky] section in bootstrap.config
# ===================================================================

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
init_script "bootstrap-husky"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-husky"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "git node npm" \
    --scripts "bootstrap-git bootstrap-packages" \
    --optional ""


# Template directory
TEMPLATE_ROOT="${BOOTSTRAP_DIR}/templates/root/husky"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Git Hooks (Husky) Configuration" \
    ".husky/pre-commit" \
    ".husky/commit-msg" \
    ".husky/prepare-commit-msg" \
    ".husky/post-merge" \
    ".commitlintrc.json"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Verify this is a git repository
if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    log_fatal "Not a git repository: $PROJECT_ROOT"
fi

# Check if Node.js is available (required for Husky)
if ! command -v node &> /dev/null; then
    log_warning "Node.js not found - Husky requires Node.js"
    log_info "Install Node.js from: https://nodejs.org/"
    log_fatal "Cannot proceed without Node.js"
fi

# Detect package manager
PACKAGE_MANAGER="npm"
if [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then
    PACKAGE_MANAGER="pnpm"
elif [[ -f "$PROJECT_ROOT/yarn.lock" ]]; then
    PACKAGE_MANAGER="yarn"
fi

log_info "Detected package manager: $PACKAGE_MANAGER"

# Verify package.json exists
if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
    log_warning "package.json not found - initializing with npm init -y"
    (cd "$PROJECT_ROOT" && npm init -y)
fi

log_success "Environment validated"

# ===================================================================
# Check if Husky is Already Installed
# ===================================================================

log_info "Checking Husky installation status..."

HUSKY_INSTALLED=false

# Check if husky is in package.json dependencies
if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    if grep -q "\"husky\"" "$PROJECT_ROOT/package.json"; then
        HUSKY_INSTALLED=true
        log_info "Husky already in package.json"
    fi
fi

# Check if .husky directory exists
if [[ -d "$PROJECT_ROOT/.husky" ]]; then
    log_info ".husky directory already exists"
    HUSKY_INSTALLED=true
fi

# ===================================================================
# Install Husky (if not already installed)
# ===================================================================

if [[ "$HUSKY_INSTALLED" == "false" ]]; then
    log_info "Installing Husky..."

    case "$PACKAGE_MANAGER" in
        pnpm)
            (cd "$PROJECT_ROOT" && pnpm add -D husky)
            ;;
        yarn)
            (cd "$PROJECT_ROOT" && yarn add -D husky)
            ;;
        *)
            (cd "$PROJECT_ROOT" && npm install --save-dev husky)
            ;;
    esac

    if [[ $? -eq 0 ]]; then
        log_success "Husky installed successfully"
    else
        log_fatal "Failed to install Husky"
    fi
else
    log_info "Husky already installed, skipping installation"
fi

# ===================================================================
# Initialize Husky
# ===================================================================

log_info "Initializing Husky..."

# Run husky init if .husky directory doesn't exist
if [[ ! -d "$PROJECT_ROOT/.husky" ]]; then
    if command -v npx &> /dev/null; then
        (cd "$PROJECT_ROOT" && npx husky init)
        log_success "Husky initialized"
    else
        # Manual initialization
        mkdir -p "$PROJECT_ROOT/.husky"
        echo "#!/usr/bin/env sh" > "$PROJECT_ROOT/.husky/_/husky.sh"
        echo ". \"\$(dirname -- \"\$0\")/_/husky.sh\"" >> "$PROJECT_ROOT/.husky/_/husky.sh"
        log_success "Husky directory created manually"
    fi
else
    log_info ".husky directory already exists"
fi

# ===================================================================
# Create Hook Files
# ===================================================================

log_info "Creating hook files..."

# Array of hook files to create
declare -A HOOKS=(
    ["pre-commit"]="Pre-commit hook (linting, formatting)"
    ["commit-msg"]="Commit message validation"
    ["prepare-commit-msg"]="Commit message template"
    ["post-merge"]="Post-merge dependency check"
)

# Create each hook
for hook in "${!HOOKS[@]}"; do
    HOOK_FILE="$PROJECT_ROOT/.husky/$hook"
    TEMPLATE_FILE="$TEMPLATE_ROOT/$hook"

    if [[ -f "$HOOK_FILE" ]]; then
        if is_auto_approved "backup_existing_files"; then
            backup_file "$HOOK_FILE"
            log_warning ".husky/$hook already exists, backed up"
        else
            track_skipped ".husky/$hook"
            log_warning ".husky/$hook already exists, skipping"
            continue
        fi
    fi

    if [[ -f "$TEMPLATE_FILE" ]]; then
        if cp "$TEMPLATE_FILE" "$HOOK_FILE"; then
            # Make hook executable
            chmod +x "$HOOK_FILE"
            verify_file "$HOOK_FILE"
            track_created ".husky/$hook"
            log_file_created "$SCRIPT_NAME" ".husky/$hook"
            log_debug "Hook: $hook - ${HOOKS[$hook]}"
        else
            log_warning "Failed to copy .husky/$hook"
        fi
    else
        log_warning "Template not found: $TEMPLATE_FILE"
    fi
done

# ===================================================================
# Create commitlint Configuration
# ===================================================================

log_info "Creating commitlint configuration..."

if file_exists "$PROJECT_ROOT/.commitlintrc.json"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.commitlintrc.json"
    else
        track_skipped ".commitlintrc.json"
        log_warning ".commitlintrc.json already exists, skipping"
    fi
fi

if [[ ! -f "$PROJECT_ROOT/.commitlintrc.json" ]] && [[ -f "$TEMPLATE_ROOT/.commitlintrc.json" ]]; then
    if cp "$TEMPLATE_ROOT/.commitlintrc.json" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/.commitlintrc.json"
        track_created ".commitlintrc.json"
        log_file_created "$SCRIPT_NAME" ".commitlintrc.json"
    else
        log_warning "Failed to copy .commitlintrc.json"
    fi
fi

# ===================================================================
# Add Prepare Script to package.json
# ===================================================================

log_info "Checking package.json scripts..."

# Check if prepare script exists
if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    if ! grep -q "\"prepare\"" "$PROJECT_ROOT/package.json"; then
        log_info "Adding 'prepare' script to package.json..."

        # Add prepare script using temporary file (safer than inline editing)
        if command -v jq &> /dev/null; then
            # Use jq if available (preferred method)
            jq '.scripts.prepare = "husky"' "$PROJECT_ROOT/package.json" > "$PROJECT_ROOT/package.json.tmp"
            mv "$PROJECT_ROOT/package.json.tmp" "$PROJECT_ROOT/package.json"
            log_success "Added 'prepare' script"
        else
            # Fallback: manual instruction
            log_warning "jq not found - cannot automatically add prepare script"
            log_info "Please manually add to package.json scripts:"
            echo "  \"prepare\": \"husky\""
        fi
    else
        log_info "prepare script already exists in package.json"
    fi
fi

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating Husky configuration..."
    echo ""

    # Test 1: Check .husky directory exists
    log_info "Checking .husky directory..."
    if [[ -d "$PROJECT_ROOT/.husky" ]]; then
        log_success "Directory: .husky/ exists"
    else
        log_error "Directory: .husky/ not found"
        errors=$((errors + 1))
    fi

    # Test 2: Check hook files exist and are executable
    log_info "Checking hook files..."
    for hook in "${!HOOKS[@]}"; do
        HOOK_FILE="$PROJECT_ROOT/.husky/$hook"
        if [[ -f "$HOOK_FILE" ]]; then
            if [[ -x "$HOOK_FILE" ]]; then
                log_success "Hook: $hook is executable"
            else
                log_warning "Hook: $hook exists but is not executable"
                chmod +x "$HOOK_FILE" 2>/dev/null || true
            fi
        else
            log_warning "Hook: $hook not found (optional)"
        fi
    done

    # Test 3: Verify Husky is in package.json
    log_info "Checking package.json..."
    if grep -q "\"husky\"" "$PROJECT_ROOT/package.json" 2>/dev/null; then
        log_success "package.json: Husky listed in dependencies"
    else
        log_warning "package.json: Husky not found in dependencies"
        errors=$((errors + 1))
    fi

    # Test 4: Check prepare script
    if grep -q "\"prepare\"" "$PROJECT_ROOT/package.json" 2>/dev/null; then
        log_success "package.json: prepare script configured"
    else
        log_warning "package.json: prepare script missing"
    fi

    # Test 5: Validate commitlint config
    log_info "Checking commitlint configuration..."
    if [[ -f "$PROJECT_ROOT/.commitlintrc.json" ]]; then
        if command -v python3 &> /dev/null; then
            if python3 -c "import json; json.load(open('$PROJECT_ROOT/.commitlintrc.json'))" 2>/dev/null; then
                log_success "commitlint: Configuration is valid JSON"
            else
                log_warning "commitlint: Invalid JSON syntax"
                errors=$((errors + 1))
            fi
        else
            log_success "commitlint: Configuration file exists"
        fi
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Validation found $errors issue(s)"
        return 0
    fi
}

# ===================================================================
# Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

echo ""
log_success "Git hooks (Husky) configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Install commitlint (optional): $PACKAGE_MANAGER install --save-dev @commitlint/cli @commitlint/config-conventional"
echo "  2. Test hooks: git add . && git commit -m \"test: verify hooks\""
echo "  3. Review hook scripts in .husky/ directory"
echo "  4. Customize hooks for your project needs"
echo ""
echo "Hook bypass (use sparingly):"
echo "  git commit --no-verify -m \"message\""
echo ""
echo "Configured hooks:"
echo "  • pre-commit:         Runs linting and formatting checks"
echo "  • commit-msg:         Validates conventional commit format"
echo "  • prepare-commit-msg: Adds branch/ticket info to commits"
echo "  • post-merge:         Checks for dependency updates"
echo ""
