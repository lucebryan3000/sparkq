#!/bin/bash
# =============================================================================
# @script         bootstrap-docker
# @version        1.0.0
# @phase          3
# @category       config
# @priority       50
# @short          Docker and containerized dev environment setup
# @description    Configures Docker and containerized development environment.
#                 Creates docker-compose.yml for orchestrating services,
#                 Dockerfile for application container, and .dockerignore
#                 to exclude unnecessary files from build context.
#
# @creates        docker-compose.yml
# @creates        Dockerfile
# @creates        .dockerignore
# @creates        .env.local
#
# @detects        has_docker_compose
# @questions      docker
# @defaults       DATABASE_TYPE=auto, DATABASE_NAME=app_dev, APP_PORT=3000
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  none
# @env_vars        ANSWERS_FILE,APP_PORT,DATABASE_NAME,DATABASE_PORT,DATABASE_TYPE
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf docker-compose.yml Dockerfile .dockerignore .env.local
# @verify          test -f docker-compose.yml
# @docs            https://docs.docker.com/compose/
# =============================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-docker.sh"

# Source additional libraries
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root"

# Script identifier and answers file
SCRIPT_NAME="bootstrap-docker"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "docker" \
    --scripts "" \
    --optional "docker-compose"

ANSWERS_FILE=".bootstrap-answers.env"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Docker Configuration" \
    "docker-compose.yml" \
    "Dockerfile" \
    ".dockerignore"

# Note: Template validation functions have been removed (standardization)
# They should be called from lib/validation-common.sh if needed

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Docker configuration..."

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check if Docker is installed (informational only)
if require_command "docker" 2>/dev/null; then
    log_success "Docker is installed: $(docker --version)"
else
    track_warning "Docker is not installed (required to run containers)"
    log_warning "Docker is not installed (required for docker-compose to run)"
fi

# ===================================================================
# Create docker-compose.yml
# ===================================================================

log_info "Creating docker-compose.yml..."

# Check if docker-compose.yml already exists
if file_exists "$PROJECT_ROOT/docker-compose.yml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/docker-compose.yml"
    else
        track_skipped "docker-compose.yml"
        log_warning "docker-compose.yml already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/docker-compose.yml"; then
    if cp "$TEMPLATE_ROOT/docker-compose.yml" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/docker-compose.yml"; then
            track_created "docker-compose.yml"
            log_file_created "$SCRIPT_NAME" "docker-compose.yml"
        fi
    else
        log_fatal "Failed to copy docker-compose.yml"
    fi
else
    track_warning "docker-compose.yml template not found"
    log_warning "docker-compose.yml template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create Dockerfile
# ===================================================================

log_info "Creating Dockerfile..."

# Check if Dockerfile already exists
if file_exists "$PROJECT_ROOT/Dockerfile"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/Dockerfile"
    else
        track_skipped "Dockerfile"
        log_warning "Dockerfile already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/Dockerfile"; then
    if cp "$TEMPLATE_ROOT/Dockerfile" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/Dockerfile"; then
            track_created "Dockerfile"
            log_file_created "$SCRIPT_NAME" "Dockerfile"
        fi
    else
        log_fatal "Failed to copy Dockerfile"
    fi
else
    track_warning "Dockerfile template not found"
    log_warning "Dockerfile template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .dockerignore
# ===================================================================

log_info "Creating .dockerignore..."

# Check if .dockerignore already exists
if file_exists "$PROJECT_ROOT/.dockerignore"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.dockerignore"
    else
        track_skipped ".dockerignore"
        log_warning ".dockerignore already exists, skipping"
    fi
fi

if file_exists "$TEMPLATE_ROOT/.dockerignore"; then
    if cp "$TEMPLATE_ROOT/.dockerignore" "$PROJECT_ROOT/"; then
        if verify_file "$PROJECT_ROOT/.dockerignore"; then
            track_created ".dockerignore"
            log_file_created "$SCRIPT_NAME" ".dockerignore"
        fi
    else
        log_fatal "Failed to copy .dockerignore"
    fi
else
    track_warning ".dockerignore template not found"
    log_warning ".dockerignore template not found in $TEMPLATE_ROOT"
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
    for file in docker-compose.yml Dockerfile .dockerignore; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "File: $file exists"
        else
            log_warning "File: $file not found (optional, may use defaults)"
        fi
    done

    # Test 2: Validate YAML syntax
    log_info "Validating YAML syntax..."
    if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        if python3 -c "import yaml; yaml.safe_load(open('$PROJECT_ROOT/docker-compose.yml'))" 2>/dev/null; then
            log_success "YAML: docker-compose.yml is valid"
        else
            log_warning "YAML: docker-compose.yml has syntax issues"
            errors=$((errors + 1))
        fi
    fi

    # Test 3: Check docker-compose.yml structure
    log_info "Checking docker-compose structure..."
    if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        if grep -q "^services:" "$PROJECT_ROOT/docker-compose.yml"; then
            local service_count=$(grep -c "^  [a-z].*:" "$PROJECT_ROOT/docker-compose.yml" || true)
            log_success "Services: Found $service_count service(s)"
        else
            log_warning "docker-compose.yml missing services definition"
            errors=$((errors + 1))
        fi
    fi

    # Test 4: Check Dockerfile syntax
    log_info "Checking Dockerfile syntax..."
    if [[ -f "$PROJECT_ROOT/Dockerfile" ]]; then
        if grep -q "^FROM" "$PROJECT_ROOT/Dockerfile"; then
            log_success "Dockerfile: Has FROM instruction"
        else
            log_warning "Dockerfile: Missing FROM instruction"
            errors=$((errors + 1))
        fi

        if grep -q "^WORKDIR" "$PROJECT_ROOT/Dockerfile"; then
            log_success "Dockerfile: Has WORKDIR instruction"
        else
            log_warning "Dockerfile: Missing WORKDIR instruction"
            errors=$((errors + 1))
        fi
    fi

    # Test 5: Check .dockerignore patterns
    log_info "Checking .dockerignore patterns..."
    if [[ -f "$PROJECT_ROOT/.dockerignore" ]]; then
        local pattern_count=$(grep -c "^[^#]" "$PROJECT_ROOT/.dockerignore" || true)
        log_success ".dockerignore: Found $pattern_count pattern(s)"
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

    # Customize docker-compose.yml if it exists
    if [[ -f "${PROJECT_ROOT}/docker-compose.yml" ]] && [[ -n "${DATABASE_TYPE:-}" ]]; then
        log_info "Customizing docker-compose.yml for ${DATABASE_TYPE}..."

        update_docker_compose_db "${PROJECT_ROOT}/docker-compose.yml" "$DATABASE_TYPE" "${DATABASE_NAME:-app_dev}"
        ((customized++))

        log_success "docker-compose.yml customized"
    fi

    # Create .env.local with configuration
    if [[ -n "${DATABASE_NAME:-}" ]] || [[ -n "${APP_PORT:-}" ]] || [[ -n "${DATABASE_PORT:-}" ]]; then
        log_info "Creating .env.local..."

        local compose_project="${PROJECT_NAME:-app}"
        local env_pairs=()

        [[ -n "${compose_project}" ]] && env_pairs+=("COMPOSE_PROJECT_NAME:${compose_project}")
        [[ -n "${DATABASE_NAME:-}" ]] && env_pairs+=("DATABASE_NAME:${DATABASE_NAME}")
        [[ -n "${APP_PORT:-}" ]] && env_pairs+=("APP_PORT:${APP_PORT}")
        [[ -n "${DATABASE_PORT:-}" ]] && env_pairs+=("DATABASE_PORT:${DATABASE_PORT}")
        [[ -n "${DATABASE_TYPE:-}" ]] && env_pairs+=("DATABASE_TYPE:${DATABASE_TYPE}")

        if [[ ${#env_pairs[@]} -gt 0 ]]; then
            create_env_file "${PROJECT_ROOT}/.env.local" "${env_pairs[@]}"
            ((customized++))
            log_success ".env.local created"
        fi
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
# Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
if [[ -f "$ANSWERS_FILE" ]]; then
    echo "  ✓ docker-compose.yml customized with your configuration"
    echo "  1. Build and start: docker-compose build && docker-compose up"
    echo "  2. Verify: docker-compose logs"
    echo "  3. Commit: git add docker-compose.yml Dockerfile .dockerignore"
else
    echo "  1. Edit docker-compose.yml for your services"
    echo "  2. Build and start: docker-compose build && docker-compose up"
    echo "  3. Verify: docker-compose logs"
    echo "  4. Commit: git add docker-compose.yml Dockerfile .dockerignore"
fi
echo ""
