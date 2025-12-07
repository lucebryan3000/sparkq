#!/bin/bash

# ===================================================================
# bootstrap-testing.sh
#
# Bootstrap testing frameworks and coverage configuration
# Creates jest.config.js, pytest.ini, and .coveragerc files
# ===================================================================

set -e

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"
TEMPLATE_ROOT="${TEMPLATE_DIR}/root"

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
# Template Validation Functions (Pre-Copy Validation)
# ===================================================================

# Validates Jest configuration structure
# Official: https://jestjs.io/docs/configuration
validate_jest_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Basic JS/TS syntax check: should have export
    if ! grep -q "export" "$template_file"; then
        log_warning "jest.config.js should have export statement"
        return 1
    fi

    # Should have testEnvironment or testMatch defined
    if ! grep -qE "testEnvironment|testMatch" "$template_file"; then
        log_warning "jest.config.js should define testEnvironment or testMatch"
        return 1
    fi

    return 0
}

# Validates Pytest configuration structure
# Official: https://docs.pytest.org/en/stable/reference.html#ini-options
validate_pytest_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # INI format: should have [pytest] section
    if ! grep -q "^\[pytest\]" "$template_file"; then
        log_warning "pytest.ini must have [pytest] section"
        return 1
    fi

    # Should define testpaths or python_files
    if ! grep -qE "testpaths|python_files" "$template_file"; then
        log_warning "pytest.ini should define testpaths or python_files"
        return 1
    fi

    return 0
}

# Validates Coverage configuration structure
# Official: https://coverage.readthedocs.io/en/latest/config.html
validate_coverage_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # INI format: should have [run] section
    if ! grep -q "^\[run\]" "$template_file"; then
        log_warning ".coveragerc must have [run] section"
        return 1
    fi

    # Should have source or omit configured
    if ! grep -qE "source|omit" "$template_file"; then
        log_warning ".coveragerc should have source or omit configuration"
        return 1
    fi

    return 0
}

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping testing configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_error "Project directory is not writable: $PROJECT_ROOT"
fi

# ===================================================================
# Create jest.config.js
# ===================================================================

log_info "Creating jest.config.js..."

if [[ -f "$PROJECT_ROOT/jest.config.js" ]]; then
    log_warning "jest.config.js already exists"
    backup_file "$PROJECT_ROOT/jest.config.js" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/jest.config.js" ]]; then
    # Validate template before copying
    validate_jest_template "$TEMPLATE_ROOT/jest.config.js"

    if cp "$TEMPLATE_ROOT/jest.config.js" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/jest.config.js" || log_error "Failed to verify jest.config.js"
    else
        log_error "Failed to copy jest.config.js"
    fi
else
    log_warning "jest.config.js template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create pytest.ini
# ===================================================================

log_info "Creating pytest.ini..."

if [[ -f "$PROJECT_ROOT/pytest.ini" ]]; then
    log_warning "pytest.ini already exists"
    backup_file "$PROJECT_ROOT/pytest.ini" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/pytest.ini" ]]; then
    # Validate template before copying
    validate_pytest_template "$TEMPLATE_ROOT/pytest.ini"

    if cp "$TEMPLATE_ROOT/pytest.ini" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/pytest.ini" || log_error "Failed to verify pytest.ini"
    else
        log_error "Failed to copy pytest.ini"
    fi
else
    log_warning "pytest.ini template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .coveragerc
# ===================================================================

log_info "Creating .coveragerc..."

if [[ -f "$PROJECT_ROOT/.coveragerc" ]]; then
    log_warning ".coveragerc already exists"
    backup_file "$PROJECT_ROOT/.coveragerc" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/.coveragerc" ]]; then
    # Validate template before copying
    validate_coverage_template "$TEMPLATE_ROOT/.coveragerc"

    if cp "$TEMPLATE_ROOT/.coveragerc" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/.coveragerc" || log_error "Failed to verify .coveragerc"
    else
        log_error "Failed to copy .coveragerc"
    fi
else
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

echo ""
log_success "Bootstrap complete!"
echo ""

validate_bootstrap

echo ""
log_info "Bootstrap Summary:"
echo "  Files:"
echo "    ├── jest.config.js   (Node.js/Next.js testing)"
echo "    ├── pytest.ini       (Python testing)"
echo "    └── .coveragerc      (Coverage reporting)"
echo ""

log_info "Next steps:"
echo "  1. Create Test Directory"
echo "     - Run: mkdir -p src/__tests__"
echo "     - Or for Python: mkdir -p tests"
echo "  2. Create First Test File"
echo "     - JavaScript: src/__tests__/example.test.ts"
echo "     - Python: tests/test_example.py"
echo "  3. Install Test Dependencies"
echo "     - JavaScript: npm install --save-dev jest @testing-library/react"
echo "     - Python: pip install pytest pytest-cov"
echo "  4. Customize Test Configuration"
echo "     - Edit jest.config.js for project-specific settings"
echo "     - Edit pytest.ini for Python test settings"
echo "     - Adjust .coveragerc coverage thresholds as needed"
echo "  5. Run Tests"
echo "     - JavaScript: npm test"
echo "     - Python: pytest"
echo "     - Coverage: coverage run -m pytest && coverage report"
echo "  6. Commit to git:"
echo "     git add jest.config.js pytest.ini .coveragerc"
echo "     git commit -m 'Setup testing configuration'"
echo ""
