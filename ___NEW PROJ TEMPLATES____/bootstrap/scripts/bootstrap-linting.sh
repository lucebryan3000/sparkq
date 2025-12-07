#!/bin/bash

# ===================================================================
# bootstrap-linting.sh
#
# Bootstrap code linting and quality enforcement
# Creates .eslintrc.json, .prettierrc.json, and ignore files
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

# Validates ESLint configuration structure
# Official: https://eslint.org/docs/latest/use/configure/configuration-files
validate_eslint_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Validate JSON syntax
    if ! python3 -c "import json; json.load(open('$template_file'))" 2>/dev/null; then
        log_warning ".eslintrc.json template has invalid JSON syntax"
        return 1
    fi

    # Check for required fields
    if ! python3 -c "import json; data=json.load(open('$template_file')); assert 'env' in data or 'extends' in data or 'rules' in data" 2>/dev/null; then
        log_warning ".eslintrc.json should have env, extends, or rules"
        return 1
    fi

    return 0
}

# Validates Prettier configuration structure
# Official: https://prettier.io/docs/en/configuration.html
validate_prettier_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Validate JSON syntax
    if ! python3 -c "import json; json.load(open('$template_file'))" 2>/dev/null; then
        log_warning ".prettierrc.json template has invalid JSON syntax"
        return 1
    fi

    # Check for valid format options (should have at least one)
    if ! python3 -c "import json; data=json.load(open('$template_file')); assert len(data) > 0" 2>/dev/null; then
        log_warning ".prettierrc.json is empty"
        return 1
    fi

    return 0
}

# Validates ignore file structure
validate_ignore_template() {
    local template_file="$1"
    local file_name=$(basename "$template_file")

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Check file is not empty
    if [[ ! -s "$template_file" ]]; then
        log_warning "$file_name template is empty"
        return 1
    fi

    # Should contain at least some patterns
    if ! grep -q "^[^#]" "$template_file"; then
        log_warning "$file_name contains only comments"
        return 1
    fi

    return 0
}

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping linting configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_error "Project directory is not writable: $PROJECT_ROOT"
fi

# ===================================================================
# Create .eslintrc.json
# ===================================================================

log_info "Creating .eslintrc.json..."

if [[ -f "$PROJECT_ROOT/.eslintrc.json" ]]; then
    log_warning ".eslintrc.json already exists"
    backup_file "$PROJECT_ROOT/.eslintrc.json" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/.eslintrc.json" ]]; then
    # Validate template before copying
    validate_eslint_template "$TEMPLATE_ROOT/.eslintrc.json"

    if cp "$TEMPLATE_ROOT/.eslintrc.json" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/.eslintrc.json" || log_error "Failed to verify .eslintrc.json"
    else
        log_error "Failed to copy .eslintrc.json"
    fi
else
    log_warning ".eslintrc.json template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .eslintignore
# ===================================================================

log_info "Creating .eslintignore..."

if [[ -f "$PROJECT_ROOT/.eslintignore" ]]; then
    log_warning ".eslintignore already exists"
    backup_file "$PROJECT_ROOT/.eslintignore" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/.eslintignore" ]]; then
    # Validate template before copying
    validate_ignore_template "$TEMPLATE_ROOT/.eslintignore"

    if cp "$TEMPLATE_ROOT/.eslintignore" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/.eslintignore" || log_error "Failed to verify .eslintignore"
    else
        log_error "Failed to copy .eslintignore"
    fi
else
    log_warning ".eslintignore template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .prettierrc.json
# ===================================================================

log_info "Creating .prettierrc.json..."

if [[ -f "$PROJECT_ROOT/.prettierrc.json" ]]; then
    log_warning ".prettierrc.json already exists"
    backup_file "$PROJECT_ROOT/.prettierrc.json" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/.prettierrc.json" ]]; then
    # Validate template before copying
    validate_prettier_template "$TEMPLATE_ROOT/.prettierrc.json"

    if cp "$TEMPLATE_ROOT/.prettierrc.json" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/.prettierrc.json" || log_error "Failed to verify .prettierrc.json"
    else
        log_error "Failed to copy .prettierrc.json"
    fi
else
    log_warning ".prettierrc.json template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .prettierignore
# ===================================================================

log_info "Creating .prettierignore..."

if [[ -f "$PROJECT_ROOT/.prettierignore" ]]; then
    log_warning ".prettierignore already exists"
    backup_file "$PROJECT_ROOT/.prettierignore" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/.prettierignore" ]]; then
    # Validate template before copying
    validate_ignore_template "$TEMPLATE_ROOT/.prettierignore"

    if cp "$TEMPLATE_ROOT/.prettierignore" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/.prettierignore" || log_error "Failed to verify .prettierignore"
    else
        log_error "Failed to copy .prettierignore"
    fi
else
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

echo ""
log_success "Bootstrap complete!"
echo ""

validate_bootstrap

echo ""
log_info "Bootstrap Summary:"
echo "  Files:"
echo "    ├── .eslintrc.json       (ESLint rules)"
echo "    ├── .eslintignore       (ESLint exclusions)"
echo "    ├── .prettierrc.json    (Prettier formatting)"
echo "    └── .prettierignore     (Prettier exclusions)"
echo ""

log_info "Next steps:"
echo "  1. Install Linting Tools"
echo "     - Run: npm install --save-dev eslint prettier"
echo "     - Run: npm install --save-dev @typescript-eslint/eslint-plugin"
echo "     - Run: npm install --save-dev eslint-config-prettier"
echo "  2. Customize Rules"
echo "     - Edit .eslintrc.json to adjust strictness"
echo "     - Edit .prettierrc.json for code style preferences"
echo "     - Update ignore patterns as needed"
echo "  3. Run Linters"
echo "     - Check lint: npm run lint"
echo "     - Fix lint: npm run lint -- --fix"
echo "     - Format code: npm run format"
echo "  4. Integrate with Editor"
echo "     - Install ESLint extension (VS Code)"
echo "     - Install Prettier extension (VS Code)"
echo "     - Enable 'Format on Save' in VS Code settings"
echo "  5. Commit to git:"
echo "     git add .eslintrc.json .eslintignore .prettierrc.json .prettierignore"
echo "     git commit -m 'Setup linting configuration'"
echo ""
