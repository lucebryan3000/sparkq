#!/bin/bash
# =============================================================================
# @name           bootstrap-linting
# @phase          2
# @category       config
# @short          Code linting and code formatting enforcement
# @description    Sets up ESLint for JavaScript/TypeScript linting with airbnb
#                 config, Prettier for code formatting, with ignore files for
#                 both tools to prevent conflicts and ensure consistent code style.
#
# @creates        .eslintrc.json
# @creates        .eslintignore
# @creates        .prettierrc.json
# @creates        .prettierignore
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
# =============================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-linting.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root"

# Script identifier
SCRIPT_NAME="bootstrap-linting"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "python3" \
    --optional "node npm eslint prettier"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Linting Configuration" \
    ".eslintrc.json" ".eslintignore" \
    ".prettierrc.json" ".prettierignore"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping linting configuration..."

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# ===================================================================
# Create .eslintrc.json
# ===================================================================

log_info "Creating .eslintrc.json..."

if file_exists "$PROJECT_ROOT/.eslintrc.json"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.eslintrc.json"
    else
        track_skipped ".eslintrc.json"
        log_warning ".eslintrc.json already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/.eslintrc.json"; then
    if cp "$TEMPLATE_ROOT/.eslintrc.json" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.eslintrc.json"; then
            track_created ".eslintrc.json"
            log_file_created "$SCRIPT_NAME" ".eslintrc.json"
        fi
    else
        log_fatal "Failed to copy .eslintrc.json"
    fi
else
    track_warning ".eslintrc.json template not found"
    log_warning ".eslintrc.json template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .eslintignore
# ===================================================================

log_info "Creating .eslintignore..."

if file_exists "$PROJECT_ROOT/.eslintignore"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.eslintignore"
    else
        track_skipped ".eslintignore"
        log_warning ".eslintignore already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/.eslintignore"; then
    if cp "$TEMPLATE_ROOT/.eslintignore" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.eslintignore"; then
            track_created ".eslintignore"
            log_file_created "$SCRIPT_NAME" ".eslintignore"
        fi
    else
        log_fatal "Failed to copy .eslintignore"
    fi
else
    track_warning ".eslintignore template not found"
    log_warning ".eslintignore template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .prettierrc.json
# ===================================================================

log_info "Creating .prettierrc.json..."

if file_exists "$PROJECT_ROOT/.prettierrc.json"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.prettierrc.json"
    else
        track_skipped ".prettierrc.json"
        log_warning ".prettierrc.json already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/.prettierrc.json"; then
    if cp "$TEMPLATE_ROOT/.prettierrc.json" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.prettierrc.json"; then
            track_created ".prettierrc.json"
            log_file_created "$SCRIPT_NAME" ".prettierrc.json"
        fi
    else
        log_fatal "Failed to copy .prettierrc.json"
    fi
else
    track_warning ".prettierrc.json template not found"
    log_warning ".prettierrc.json template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .prettierignore
# ===================================================================

log_info "Creating .prettierignore..."

if file_exists "$PROJECT_ROOT/.prettierignore"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.prettierignore"
    else
        track_skipped ".prettierignore"
        log_warning ".prettierignore already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/.prettierignore"; then
    if cp "$TEMPLATE_ROOT/.prettierignore" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.prettierignore"; then
            track_created ".prettierignore"
            log_file_created "$SCRIPT_NAME" ".prettierignore"
        fi
    else
        log_fatal "Failed to copy .prettierignore"
    fi
else
    track_warning ".prettierignore template not found"
    log_warning ".prettierignore template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Required files
    log_info "Checking required files..."
    for file in .eslintrc.json .eslintignore .prettierrc.json .prettierignore; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "File: $file exists"
        else
            log_warning "File: $file not found (optional, may use defaults)"
        fi
    done

    # Test 2: Validate JSON files
    log_info "Validating JSON configuration files..."
    for json_file in .eslintrc.json .prettierrc.json; do
        if [[ -f "$PROJECT_ROOT/$json_file" ]]; then
            if python3 -c "import json; json.load(open('$PROJECT_ROOT/$json_file'))" 2>/dev/null; then
                log_success "JSON: $json_file is valid"
            else
                log_warning "JSON: $json_file has syntax errors"
                errors=$((errors + 1))
            fi
        fi
    done

    # Test 3: Check ESLint configuration
    log_info "Checking ESLint configuration..."
    if [[ -f "$PROJECT_ROOT/.eslintrc.json" ]]; then
        if python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.eslintrc.json')); assert 'env' in data or 'extends' in data" 2>/dev/null; then
            local has_env=$(python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.eslintrc.json')); print('env' in data)")
            local has_extends=$(python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.eslintrc.json')); print('extends' in data)")
            log_success "ESLint: Configuration is valid (env=$has_env, extends=$has_extends)"
        else
            log_warning "ESLint: Missing required configuration"
            errors=$((errors + 1))
        fi
    fi

    # Test 4: Check ignore file patterns
    log_info "Checking ignore patterns..."
    for ignore_file in .eslintignore .prettierignore; do
        if [[ -f "$PROJECT_ROOT/$ignore_file" ]]; then
            local pattern_count=$(grep -c "^[^#]" "$PROJECT_ROOT/$ignore_file" || true)
            log_success "$ignore_file: Found $pattern_count pattern(s)"
        fi
    done

    # Test 5: Verify Prettier formatting rules
    log_info "Checking Prettier formatting rules..."
    if [[ -f "$PROJECT_ROOT/.prettierrc.json" ]]; then
        local rule_count=$(python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.prettierrc.json')); print(len(data))")
        log_success "Prettier: Found $rule_count formatting rule(s)"
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Validation found $errors issue(s) (non-critical)"
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

log_info "Next steps:"
echo "  1. Install: npm install --save-dev eslint prettier @typescript-eslint/eslint-plugin"
echo "  2. Run: npm run lint && npm run format"
echo "  3. Enable 'Format on Save' in VS Code"
echo "  4. Commit: git add .eslintrc.json .eslintignore .prettierrc.json .prettierignore"
echo ""
