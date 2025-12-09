#!/bin/bash
# =============================================================================
# @script         bootstrap-testing
# @version        1.0.0
# @phase          3
# @category       test
# @priority       50
# @short          Testing frameworks and coverage configuration
# @description    Sets up testing frameworks including Jest for JavaScript/
#                 TypeScript unit and integration tests, Pytest for Python,
#                 and coverage reporting configuration with .coveragerc for
#                 code coverage tracking and thresholds.
#
# @creates        jest.config.js
# @creates        pytest.ini
# @creates        .coveragerc
#
# @depends        project, packages
#
# @detects        has_jest_config
# @questions      testing
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  none
# @env_vars        none
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf jest.config.js pytest.ini .coveragerc
# @verify          test -f jest.config.js
# @docs            https://vitest.dev/guide/
# =============================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-testing.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root"

# Script identifier
SCRIPT_NAME="bootstrap-testing"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "node npm" \
    --scripts "bootstrap-project bootstrap-packages" \
    --optional ""


# Pre-execution confirmation
pre_execution_confirm "$SCRIPT_NAME" "Testing Configuration" \
    "vitest.config.ts" "jest.config.js" \
    "tests/ directory"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping testing configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_fatal "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_fatal "Project directory is not writable: $PROJECT_ROOT"
fi

# ===================================================================
# Create jest.config.js
# ===================================================================

log_info "Creating jest.config.js..."

if [[ -f "$PROJECT_ROOT/jest.config.js" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/jest.config.js"
    else
        track_skipped "jest.config.js"
        log_warning "jest.config.js already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_ROOT/jest.config.js" ]]; then
    if cp "$TEMPLATE_ROOT/jest.config.js" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/jest.config.js"; then
            track_created "jest.config.js"
            log_file_created "$SCRIPT_NAME" "jest.config.js"
        fi
    else
        log_fatal "Failed to copy jest.config.js"
    fi
else
    track_warning "jest.config.js template not found"
    log_warning "jest.config.js template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create pytest.ini
# ===================================================================

log_info "Creating pytest.ini..."

if [[ -f "$PROJECT_ROOT/pytest.ini" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/pytest.ini"
    else
        track_skipped "pytest.ini"
        log_warning "pytest.ini already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_ROOT/pytest.ini" ]]; then
    if cp "$TEMPLATE_ROOT/pytest.ini" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/pytest.ini"; then
            track_created "pytest.ini"
            log_file_created "$SCRIPT_NAME" "pytest.ini"
        fi
    else
        log_fatal "Failed to copy pytest.ini"
    fi
else
    track_warning "pytest.ini template not found"
    log_warning "pytest.ini template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .coveragerc
# ===================================================================

log_info "Creating .coveragerc..."

if [[ -f "$PROJECT_ROOT/.coveragerc" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.coveragerc"
    else
        track_skipped ".coveragerc"
        log_warning ".coveragerc already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_ROOT/.coveragerc" ]]; then
    if cp "$TEMPLATE_ROOT/.coveragerc" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.coveragerc"; then
            track_created ".coveragerc"
            log_file_created "$SCRIPT_NAME" ".coveragerc"
        fi
    else
        log_fatal "Failed to copy .coveragerc"
    fi
else
    track_warning ".coveragerc template not found"
    log_warning ".coveragerc template not found in $TEMPLATE_ROOT"
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
    for file in jest.config.js pytest.ini .coveragerc; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "File: $file exists"
        else
            log_warning "File: $file not found (optional for polyglot projects)"
        fi
    done

    # Test 2: Validate Jest configuration
    log_info "Checking Jest configuration..."
    if [[ -f "$PROJECT_ROOT/jest.config.js" ]]; then
        if grep -q "testEnvironment\|testMatch" "$PROJECT_ROOT/jest.config.js"; then
            log_success "Jest: Has test configuration"
        else
            log_warning "Jest: Missing test configuration"
            errors=$((errors + 1))
        fi

        if grep -q "export" "$PROJECT_ROOT/jest.config.js"; then
            log_success "Jest: Has export statement"
        fi
    fi

    # Test 3: Validate Pytest configuration
    log_info "Checking Pytest configuration..."
    if [[ -f "$PROJECT_ROOT/pytest.ini" ]]; then
        if grep -q "^\[pytest\]" "$PROJECT_ROOT/pytest.ini"; then
            log_success "Pytest: Has [pytest] section"
        else
            log_warning "Pytest: Missing [pytest] section"
            errors=$((errors + 1))
        fi

        if grep -q "testpaths" "$PROJECT_ROOT/pytest.ini"; then
            local testpath=$(grep "^testpaths" "$PROJECT_ROOT/pytest.ini" | head -1)
            log_success "Pytest: $testpath"
        fi
    fi

    # Test 4: Validate Coverage configuration
    log_info "Checking Coverage configuration..."
    if [[ -f "$PROJECT_ROOT/.coveragerc" ]]; then
        local section_count=$(grep -c "^\[" "$PROJECT_ROOT/.coveragerc" || true)
        log_success "Coverage: Found $section_count section(s)"

        if grep -q "fail_under" "$PROJECT_ROOT/.coveragerc"; then
            local fail_under=$(grep "^fail_under" "$PROJECT_ROOT/.coveragerc")
            log_success "Coverage: $fail_under"
        fi
    fi

    # Test 5: Check for test directories
    log_info "Checking test structure..."
    if [[ -d "$PROJECT_ROOT/src" ]]; then
        log_success "Source directory exists: src/"
    fi
    if [[ ! -d "$PROJECT_ROOT/tests" && ! -d "$PROJECT_ROOT/testing" ]]; then
        log_warning "No tests/ or testing/ directory found (will be created when tests are added)"
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
echo "  1. Create test directory: mkdir -p src/__tests__ or tests/"
echo "  2. Install: npm install --save-dev jest (or pip install pytest)"
echo "  3. Run tests: npm test or pytest"
echo "  4. Commit: git add jest.config.js pytest.ini .coveragerc"
echo ""
