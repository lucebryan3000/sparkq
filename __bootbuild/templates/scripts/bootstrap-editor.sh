#!/bin/bash

# ===================================================================
# bootstrap-editor.sh
#
# Bootstrap editor formatting standards
# Creates .editorconfig and .stylelintrc configuration files
# ===================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-editor.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root"

# Script identifier
SCRIPT_NAME="bootstrap-editor"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "" \
    --scripts "" \
    --optional "node python3"


# Pre-execution confirmation
pre_execution_confirm "$SCRIPT_NAME" "Editor Configuration" \
    ".editorconfig" ".stylelintrc.json"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping editor configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_fatal "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_fatal "Project directory is not writable: $PROJECT_ROOT"
fi

# ===================================================================
# Create .editorconfig
# ===================================================================

log_info "Creating .editorconfig..."

if [[ -f "$PROJECT_ROOT/.editorconfig" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.editorconfig"
    else
        track_skipped ".editorconfig"
        log_warning ".editorconfig already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_ROOT/.editorconfig" ]]; then
    if cp "$TEMPLATE_ROOT/.editorconfig" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.editorconfig"; then
            track_created ".editorconfig"
            log_file_created "$SCRIPT_NAME" ".editorconfig"
        fi
    else
        log_fatal "Failed to copy .editorconfig"
    fi
else
    track_warning ".editorconfig template not found"
    log_warning ".editorconfig template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .stylelintrc
# ===================================================================

log_info "Creating .stylelintrc..."

if [[ -f "$PROJECT_ROOT/.stylelintrc" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.stylelintrc"
    else
        track_skipped ".stylelintrc"
        log_warning ".stylelintrc already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_ROOT/.stylelintrc" ]]; then
    if cp "$TEMPLATE_ROOT/.stylelintrc" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.stylelintrc"; then
            track_created ".stylelintrc"
            log_file_created "$SCRIPT_NAME" ".stylelintrc"
        fi
    else
        log_fatal "Failed to copy .stylelintrc"
    fi
else
    track_warning ".stylelintrc template not found"
    log_warning ".stylelintrc template not found in $TEMPLATE_ROOT"
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
    for file in .editorconfig .stylelintrc; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "File: $file exists"
        else
            log_warning "File: $file not found (optional, may use defaults)"
        fi
    done

    # Test 2: Validate .editorconfig structure
    log_info "Checking .editorconfig structure..."
    if [[ -f "$PROJECT_ROOT/.editorconfig" ]]; then
        if grep -q "root = true" "$PROJECT_ROOT/.editorconfig"; then
            log_success "EditorConfig: Has 'root = true' declaration"
        else
            log_warning "EditorConfig: Missing 'root = true'"
            errors=$((errors + 1))
        fi

        local section_count=$(grep -c "^\[" "$PROJECT_ROOT/.editorconfig" || true)
        log_success "EditorConfig: Found $section_count section(s)"
    fi

    # Test 3: Validate StyleLint JSON syntax
    log_info "Validating StyleLint configuration..."
    if [[ -f "$PROJECT_ROOT/.stylelintrc" ]]; then
        if python3 -c "import json; json.load(open('$PROJECT_ROOT/.stylelintrc'))" 2>/dev/null; then
            log_success "JSON: .stylelintrc is valid"
        else
            log_warning "JSON: .stylelintrc has syntax errors"
            errors=$((errors + 1))
        fi
    fi

    # Test 4: Check StyleLint configuration elements
    log_info "Checking StyleLint configuration..."
    if [[ -f "$PROJECT_ROOT/.stylelintrc" ]]; then
        if python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.stylelintrc')); assert 'extends' in data or 'rules' in data" 2>/dev/null; then
            local has_extends=$(python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.stylelintrc')); print('extends' in data)")
            local has_rules=$(python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.stylelintrc')); print('rules' in data)")
            log_success "StyleLint: Configuration is valid (extends=$has_extends, rules=$has_rules)"
        else
            log_warning "StyleLint: Missing extends or rules"
            errors=$((errors + 1))
        fi
    fi

    # Test 5: Check for ignore patterns
    log_info "Checking StyleLint ignore patterns..."
    if [[ -f "$PROJECT_ROOT/.stylelintrc" ]]; then
        if python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.stylelintrc')); assert 'ignoreFiles' in data" 2>/dev/null; then
            local ignore_count=$(python3 -c "import json; data=json.load(open('$PROJECT_ROOT/.stylelintrc')); print(len(data.get('ignoreFiles', [])))")
            log_success "StyleLint: Found $ignore_count ignore pattern(s)"
        fi
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
echo "  1. Install EditorConfig support in your editor"
echo "  2. Install: npm install --save-dev stylelint stylelint-config-standard"
echo "  3. Configure .stylelintrc for your CSS/SCSS preferences"
echo "  4. Commit: git add .editorconfig .stylelintrc"
echo ""
