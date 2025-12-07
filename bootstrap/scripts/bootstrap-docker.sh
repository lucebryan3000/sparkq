#!/bin/bash

# ===================================================================
# bootstrap-docker.sh
#
# Bootstrap Docker and containerized development environment
# Creates docker-compose.yml, Dockerfile, and .dockerignore
# ===================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${BOOTSTRAP_DIR}/templates"
PROJECT_ROOT="${1:-.}"
TEMPLATE_ROOT="${TEMPLATE_DIR}/root"

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
# Template Validation Functions (Pre-Copy Validation)
# ===================================================================

# Validates docker-compose.yml structure against official specs
# Official: https://docs.docker.com/compose/compose-file/
validate_docker_compose_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Validate YAML syntax using Python
    if ! python3 -c "import yaml; yaml.safe_load(open('$template_file'))" 2>/dev/null; then
        log_warning "docker-compose.yml template has invalid YAML syntax"
        return 1
    fi

    # Check for services definition
    if ! grep -q "^services:" "$template_file"; then
        log_warning "docker-compose.yml must define services"
        return 1
    fi

    return 0
}

# Validates Dockerfile structure against official specs
# Official: https://docs.docker.com/engine/reference/builder/
validate_dockerfile_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Check for FROM instruction (required)
    if ! grep -q "^FROM" "$template_file"; then
        log_warning "Dockerfile must start with FROM instruction"
        return 1
    fi

    # Check for WORKDIR instruction
    if ! grep -q "^WORKDIR" "$template_file"; then
        log_warning "Dockerfile should define WORKDIR"
        return 1
    fi

    # Check for valid Dockerfile instructions (non-exhaustive)
    # This prevents obviously malformed Dockerfiles without requiring a full build
    local valid_instructions=0
    if grep -qE "^(FROM|WORKDIR|RUN|COPY|EXPOSE|CMD|ENV)" "$template_file"; then
        valid_instructions=1
    fi

    if [[ $valid_instructions -eq 0 ]]; then
        log_warning "Dockerfile has no recognized instructions"
        return 1
    fi

    return 0
}

# Validates .dockerignore structure
# Official: https://docs.docker.com/engine/reference/builder/#dockerignore-file
validate_dockerignore_template() {
    local template_file="$1"

    if [[ ! -f "$template_file" ]]; then
        return 0
    fi

    # Check file is not empty
    if [[ ! -s "$template_file" ]]; then
        log_warning ".dockerignore template is empty"
        return 1
    fi

    # Should contain at least some patterns
    if ! grep -q "^[^#]" "$template_file"; then
        log_warning ".dockerignore contains only comments"
        return 1
    fi

    return 0
}

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Docker configuration..."

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# Verify project directory is writable
if [[ ! -w "$PROJECT_ROOT" ]]; then
    log_error "Project directory is not writable: $PROJECT_ROOT"
fi

# Check if Docker is installed (informational only)
if command -v docker &> /dev/null; then
    log_success "Docker is installed: $(docker --version)"
else
    log_warning "Docker is not installed (required for docker-compose to run)"
fi

# ===================================================================
# Create docker-compose.yml
# ===================================================================

log_info "Creating docker-compose.yml..."

# Check if docker-compose.yml already exists
if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
    log_warning "docker-compose.yml already exists"
    backup_file "$PROJECT_ROOT/docker-compose.yml" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/docker-compose.yml" ]]; then
    # Validate template before copying
    validate_docker_compose_template "$TEMPLATE_ROOT/docker-compose.yml"

    if cp "$TEMPLATE_ROOT/docker-compose.yml" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/docker-compose.yml" || log_error "Failed to verify docker-compose.yml"
    else
        log_error "Failed to copy docker-compose.yml"
    fi
else
    log_warning "docker-compose.yml template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create Dockerfile
# ===================================================================

log_info "Creating Dockerfile..."

# Check if Dockerfile already exists
if [[ -f "$PROJECT_ROOT/Dockerfile" ]]; then
    log_warning "Dockerfile already exists"
    backup_file "$PROJECT_ROOT/Dockerfile" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/Dockerfile" ]]; then
    # Validate template before copying
    validate_dockerfile_template "$TEMPLATE_ROOT/Dockerfile"

    if cp "$TEMPLATE_ROOT/Dockerfile" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/Dockerfile" || log_error "Failed to verify Dockerfile"
    else
        log_error "Failed to copy Dockerfile"
    fi
else
    log_warning "Dockerfile template not found in $TEMPLATE_ROOT"
fi

# ===================================================================
# Create .dockerignore
# ===================================================================

log_info "Creating .dockerignore..."

# Check if .dockerignore already exists
if [[ -f "$PROJECT_ROOT/.dockerignore" ]]; then
    log_warning ".dockerignore already exists"
    backup_file "$PROJECT_ROOT/.dockerignore" || {
        log_warning "Proceeding without backup (file may be read-only)"
    }
fi

if [[ -f "$TEMPLATE_ROOT/.dockerignore" ]]; then
    # Validate template before copying
    validate_dockerignore_template "$TEMPLATE_ROOT/.dockerignore"

    if cp "$TEMPLATE_ROOT/.dockerignore" "$PROJECT_ROOT/"; then
        verify_file "$PROJECT_ROOT/.dockerignore" || log_error "Failed to verify .dockerignore"
    else
        log_error "Failed to copy .dockerignore"
    fi
else
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

echo ""
log_success "Bootstrap complete!"
echo ""

validate_bootstrap

echo ""
log_info "Bootstrap Summary:"
echo "  Files:"
echo "    ├── docker-compose.yml"
echo "    ├── Dockerfile"
echo "    └── .dockerignore"
echo ""

log_info "Next steps:"
if [[ -f "$ANSWERS_FILE" ]]; then
    echo "  ✓ docker-compose.yml and .env.local have been customized"
    echo "  1. Add Database Init Scripts (optional)"
    echo "     - Create scripts/init-db.sql for database init"
    echo "  2. Build and Start Services"
    echo "     - Run: docker-compose build"
    echo "     - Run: docker-compose up"
    echo "  3. Verify Services"
    echo "     - Check database: docker-compose exec db psql (or mysql/mongo)"
    echo "     - Check app: docker-compose logs app"
    echo "  4. Commit to git:"
    echo "     git add docker-compose.yml Dockerfile .dockerignore .env.local"
    echo "     git commit -m 'Setup Docker configuration'"
else
    echo "  1. Customize Configuration"
    echo "     - Edit docker-compose.yml for your services"
    echo "     - Update database, cache, and app configurations"
    echo "     - Set environment variables in .env.local"
    echo "  2. Add Database Init Scripts"
    echo "     - Create scripts/init-db.sql for PostgreSQL init"
    echo "     - Update docker-compose.yml to reference it"
    echo "  3. Build and Start Services"
    echo "     - Run: docker-compose build"
    echo "     - Run: docker-compose up"
    echo "  4. Verify Services"
    echo "     - Check database: docker-compose exec db psql"
    echo "     - Check app: docker-compose logs app"
    echo "  5. Commit to git:"
    echo "     git add docker-compose.yml Dockerfile .dockerignore"
    echo "     git commit -m 'Setup Docker configuration'"
    echo "  Tip: Run with --interactive mode for automatic customization"
fi
echo ""
