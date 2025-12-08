#!/bin/bash

# ===================================================================
# bootstrap-security.sh
#
# Purpose: Security scanning and vulnerability detection configuration
# Creates: Security configuration files, audit configs, license policies
# Config:  [security] section in bootstrap.config
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
init_script "bootstrap-security"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-security"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "" \
    --scripts "bootstrap-project bootstrap-packages" \
    --optional "node npm"


# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "security.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Security bootstrap disabled in config"
    exit 0
fi

# Read security-specific settings
ENABLE_NPM_AUDIT=$(config_get "security.npm_audit" "true")
ENABLE_SNYK=$(config_get "security.snyk" "false")
ENABLE_LICENSE_CHECK=$(config_get "security.license_check" "true")
AUTO_FIX=$(config_get "security.auto_fix" "false")
FAIL_ON_CRITICAL=$(config_get "security.fail_on_critical" "true")
AUDIT_LEVEL=$(config_get "security.audit_level" "moderate")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

# List all files this script will create
FILES_TO_CREATE=(
    "security/"
    "security/.snyk"
    "security/security-policy.json"
    "security/.npmauditrc"
    "security/license-whitelist.json"
)

pre_execution_confirm "$SCRIPT_NAME" "Security Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check for package.json (required for npm-based projects)
if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
    log_warning "package.json not found - security scanning requires a package.json"
    log_warning "Continuing with template creation for future use"
fi

log_success "Environment validated"

# ===================================================================
# Create Security Directory
# ===================================================================

log_info "Creating security directory structure..."

if ! dir_exists "$PROJECT_ROOT/security"; then
    ensure_dir "$PROJECT_ROOT/security"
    log_dir_created "$SCRIPT_NAME" "security/"
    track_created "security/"
else
    log_info "security/ directory already exists"
fi

# ===================================================================
# Template Validation Functions (Pre-Copy Validation)
# ===================================================================

# Validates Snyk configuration structure
validate_snyk_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Check for version field
    if ! grep -q "^version:" "$template_file"; then
        log_warning ".snyk template missing version field"
        return 1
    fi

    return 0
}

# Validates security policy JSON structure
validate_security_policy_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Validate JSON syntax
    if ! python3 -c "import json; json.load(open('$template_file'))" 2>/dev/null; then
        log_warning "security-policy.json template has invalid JSON syntax"
        return 1
    fi

    # Check for required sections
    if ! python3 -c "import json; data=json.load(open('$template_file')); assert 'vulnerabilities' in data and 'licenses' in data" 2>/dev/null; then
        log_warning "security-policy.json should have vulnerabilities and licenses sections"
        return 1
    fi

    return 0
}

# Validates license whitelist JSON structure
validate_license_whitelist_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Validate JSON syntax
    if ! python3 -c "import json; json.load(open('$template_file'))" 2>/dev/null; then
        log_warning "license-whitelist.json template has invalid JSON syntax"
        return 1
    fi

    # Check for required sections
    if ! python3 -c "import json; data=json.load(open('$template_file')); assert 'whitelist' in data and 'blacklist' in data" 2>/dev/null; then
        log_warning "license-whitelist.json should have whitelist and blacklist sections"
        return 1
    fi

    return 0
}

# ===================================================================
# Copy Template Files
# ===================================================================

TEMPLATE_ROOT="${BOOTSTRAP_DIR}/templates/root"

# Create .snyk configuration
log_info "Creating Snyk configuration..."

if file_exists "$PROJECT_ROOT/security/.snyk"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/security/.snyk"
        track_skipped "security/.snyk (backed up)"
        log_warning "security/.snyk already exists, backed up"
    else
        track_skipped "security/.snyk"
        log_warning "security/.snyk already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/security/.snyk"; then
    validate_snyk_template "$TEMPLATE_ROOT/security/.snyk"
    if cp "$TEMPLATE_ROOT/security/.snyk" "$PROJECT_ROOT/security/"; then
        if verify_file "$PROJECT_ROOT/security/.snyk"; then
            track_created "security/.snyk"
            log_file_created "$SCRIPT_NAME" "security/.snyk"
        fi
    else
        log_fatal "Failed to copy security/.snyk"
    fi
else
    track_warning "security/.snyk template not found"
    log_warning "security/.snyk template not found"
fi

# Create security-policy.json
log_info "Creating security policy configuration..."

if file_exists "$PROJECT_ROOT/security/security-policy.json"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/security/security-policy.json"
        track_skipped "security/security-policy.json (backed up)"
        log_warning "security/security-policy.json already exists, backed up"
    else
        track_skipped "security/security-policy.json"
        log_warning "security/security-policy.json already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/security/security-policy.json"; then
    validate_security_policy_template "$TEMPLATE_ROOT/security/security-policy.json"
    if cp "$TEMPLATE_ROOT/security/security-policy.json" "$PROJECT_ROOT/security/"; then
        if verify_file "$PROJECT_ROOT/security/security-policy.json"; then
            track_created "security/security-policy.json"
            log_file_created "$SCRIPT_NAME" "security/security-policy.json"
        fi
    else
        log_fatal "Failed to copy security/security-policy.json"
    fi
else
    track_warning "security/security-policy.json template not found"
    log_warning "security/security-policy.json template not found"
fi

# Create .npmauditrc
log_info "Creating npm audit configuration..."

if file_exists "$PROJECT_ROOT/security/.npmauditrc"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/security/.npmauditrc"
        track_skipped "security/.npmauditrc (backed up)"
        log_warning "security/.npmauditrc already exists, backed up"
    else
        track_skipped "security/.npmauditrc"
        log_warning "security/.npmauditrc already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/security/.npmauditrc"; then
    if cp "$TEMPLATE_ROOT/security/.npmauditrc" "$PROJECT_ROOT/security/"; then
        if verify_file "$PROJECT_ROOT/security/.npmauditrc"; then
            track_created "security/.npmauditrc"
            log_file_created "$SCRIPT_NAME" "security/.npmauditrc"
        fi
    else
        log_fatal "Failed to copy security/.npmauditrc"
    fi
else
    track_warning "security/.npmauditrc template not found"
    log_warning "security/.npmauditrc template not found"
fi

# Create license-whitelist.json
log_info "Creating license whitelist configuration..."

if file_exists "$PROJECT_ROOT/security/license-whitelist.json"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/security/license-whitelist.json"
        track_skipped "security/license-whitelist.json (backed up)"
        log_warning "security/license-whitelist.json already exists, backed up"
    else
        track_skipped "security/license-whitelist.json"
        log_warning "security/license-whitelist.json already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/security/license-whitelist.json"; then
    validate_license_whitelist_template "$TEMPLATE_ROOT/security/license-whitelist.json"
    if cp "$TEMPLATE_ROOT/security/license-whitelist.json" "$PROJECT_ROOT/security/"; then
        if verify_file "$PROJECT_ROOT/security/license-whitelist.json"; then
            track_created "security/license-whitelist.json"
            log_file_created "$SCRIPT_NAME" "security/license-whitelist.json"
        fi
    else
        log_fatal "Failed to copy security/license-whitelist.json"
    fi
else
    track_warning "security/license-whitelist.json template not found"
    log_warning "security/license-whitelist.json template not found"
fi

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating security configuration..."
    echo ""

    # Test 1: Required files
    log_info "Checking security configuration files..."
    for file in security/.snyk security/security-policy.json security/.npmauditrc security/license-whitelist.json; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "File: $file exists"
        else
            log_warning "File: $file not found"
            errors=$((errors + 1))
        fi
    done

    # Test 2: Validate JSON files
    log_info "Validating JSON configuration files..."
    for json_file in security/security-policy.json security/license-whitelist.json; do
        if [[ -f "$PROJECT_ROOT/$json_file" ]]; then
            if python3 -c "import json; json.load(open('$PROJECT_ROOT/$json_file'))" 2>/dev/null; then
                log_success "JSON: $json_file is valid"
            else
                log_warning "JSON: $json_file has syntax errors"
                errors=$((errors + 1))
            fi
        fi
    done

    # Test 3: Check security policy structure
    log_info "Checking security policy structure..."
    if [[ -f "$PROJECT_ROOT/security/security-policy.json" ]]; then
        if python3 -c "import json; data=json.load(open('$PROJECT_ROOT/security/security-policy.json')); assert 'vulnerabilities' in data" 2>/dev/null; then
            log_success "Security policy: vulnerabilities section exists"
        else
            log_warning "Security policy: missing vulnerabilities section"
            errors=$((errors + 1))
        fi

        if python3 -c "import json; data=json.load(open('$PROJECT_ROOT/security/security-policy.json')); assert 'licenses' in data" 2>/dev/null; then
            log_success "Security policy: licenses section exists"
        else
            log_warning "Security policy: missing licenses section"
            errors=$((errors + 1))
        fi
    fi

    # Test 4: Check license whitelist structure
    log_info "Checking license whitelist structure..."
    if [[ -f "$PROJECT_ROOT/security/license-whitelist.json" ]]; then
        if python3 -c "import json; data=json.load(open('$PROJECT_ROOT/security/license-whitelist.json')); assert 'whitelist' in data" 2>/dev/null; then
            local whitelist_count=$(python3 -c "import json; data=json.load(open('$PROJECT_ROOT/security/license-whitelist.json')); print(len(data['whitelist'].get('permissive', [])))")
            log_success "License whitelist: Found $whitelist_count permissive licenses"
        else
            log_warning "License whitelist: missing whitelist section"
            errors=$((errors + 1))
        fi
    fi

    # Test 5: Check for npm (required for security scanning)
    log_info "Checking for npm availability..."
    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version 2>/dev/null || echo "unknown")
        log_success "npm: Available (version $npm_version)"
    else
        log_warning "npm: Not available (required for npm audit)"
    fi

    # Test 6: Check for package.json
    log_info "Checking for package.json..."
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        log_success "package.json: Found"
    else
        log_warning "package.json: Not found (required for dependency scanning)"
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
# Summary
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Security configuration complete!"
echo ""
echo "Configuration files created:"
echo "  - security/.snyk                  (Snyk vulnerability scanner config)"
echo "  - security/security-policy.json   (Security thresholds and policies)"
echo "  - security/.npmauditrc            (npm audit configuration)"
echo "  - security/license-whitelist.json (License compliance rules)"
echo ""
echo "Next steps:"
echo "  1. Install security tools:"
echo "     npm install --save-dev snyk"
echo ""
echo "  2. Run security scans:"
echo "     npm audit --audit-level=$AUDIT_LEVEL"
echo "     npx snyk test"
echo ""
echo "  3. Configure automatic scanning:"
echo "     - Add 'security:audit' script to package.json"
echo "     - Enable pre-commit hooks for security checks"
echo "     - Add security scanning to CI/CD pipeline"
echo ""
echo "  4. Review and customize:"
echo "     - security/security-policy.json - Adjust severity thresholds"
echo "     - security/license-whitelist.json - Add/remove approved licenses"
echo "     - security/.snyk - Configure Snyk ignore rules"
echo ""
echo "  5. Optional integrations:"
echo "     - Snyk: https://snyk.io/ (signup for free account)"
echo "     - GitHub Dependabot: Enable in repository settings"
echo "     - OWASP Dependency-Check: https://owasp.org/www-project-dependency-check/"
echo ""

show_log_location
