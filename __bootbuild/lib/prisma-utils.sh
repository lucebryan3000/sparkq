#!/usr/bin/env bash
# shellcheck disable=SC2034

# Prisma ORM utility functions for Node.js projects
# Provides wrappers for common Prisma CLI operations

set -euo pipefail

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_PRISMA_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_PRISMA_UTILS_LOADED=1

# Color codes for output
readonly PRISMA_COLOR_RESET='\033[0m'
readonly PRISMA_COLOR_GREEN='\033[0;32m'
readonly PRISMA_COLOR_YELLOW='\033[1;33m'
readonly PRISMA_COLOR_RED='\033[0;31m'
readonly PRISMA_COLOR_BLUE='\033[0;34m'

# Prisma configuration
PRISMA_SCHEMA="${PRISMA_SCHEMA:-prisma/schema.prisma}"
PRISMA_BIN="${PRISMA_BIN:-npx prisma}"

# Internal logging functions
_prisma_log_info() {
    echo -e "${PRISMA_COLOR_BLUE}[Prisma]${PRISMA_COLOR_RESET} $*"
}

_prisma_log_success() {
    echo -e "${PRISMA_COLOR_GREEN}[Prisma]${PRISMA_COLOR_RESET} $*"
}

_prisma_log_warn() {
    echo -e "${PRISMA_COLOR_YELLOW}[Prisma]${PRISMA_COLOR_RESET} $*"
}

_prisma_log_error() {
    echo -e "${PRISMA_COLOR_RED}[Prisma]${PRISMA_COLOR_RESET} $*" >&2
}

# Check if Prisma is available
_prisma_check_available() {
    if ! command -v npx &> /dev/null; then
        _prisma_log_error "npx not found. Please install Node.js and npm."
        return 1
    fi

    if ! npx prisma --version &> /dev/null; then
        _prisma_log_error "Prisma not found. Run: npm install -D prisma"
        return 1
    fi

    return 0
}

# Check if schema file exists
_prisma_check_schema() {
    if [[ ! -f "$PRISMA_SCHEMA" ]]; then
        _prisma_log_error "Schema file not found: $PRISMA_SCHEMA"
        return 1
    fi
    return 0
}

# Generate Prisma client
# Usage: prisma_generate [--watch]
prisma_generate() {
    _prisma_log_info "Generating Prisma client..."

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")

    if $PRISMA_BIN generate "${args[@]}"; then
        _prisma_log_success "Client generated successfully"
        return 0
    else
        _prisma_log_error "Client generation failed"
        return 1
    fi
}

# Run migrations in production
# Usage: prisma_migrate [--schema PATH]
prisma_migrate() {
    _prisma_log_info "Running migrations (production)..."

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")

    if $PRISMA_BIN migrate deploy "${args[@]}"; then
        _prisma_log_success "Migrations applied successfully"
        return 0
    else
        _prisma_log_error "Migration deployment failed"
        return 1
    fi
}

# Run migrations in development
# Usage: prisma_migrate_dev [--name MIGRATION_NAME] [--create-only]
prisma_migrate_dev() {
    _prisma_log_info "Running migrations (development)..."

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")

    # If no --name flag provided, prompt for name
    local has_name=false
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--name" ]] || [[ "$arg" == "-n" ]]; then
            has_name=true
            break
        fi
    done

    if [[ "$has_name" == false ]] && [[ "${#args[@]}" -eq 0 ]]; then
        _prisma_log_warn "No migration name provided. Prisma will prompt for one."
    fi

    if $PRISMA_BIN migrate dev "${args[@]}"; then
        _prisma_log_success "Development migration completed"
        return 0
    else
        _prisma_log_error "Development migration failed"
        return 1
    fi
}

# Run seed script
# Usage: prisma_seed
prisma_seed() {
    _prisma_log_info "Running database seed..."

    if ! _prisma_check_available; then
        return 1
    fi

    # Check if seed script is configured in package.json
    if ! grep -q '"prisma".*"seed"' package.json 2>/dev/null; then
        _prisma_log_warn "No seed script configured in package.json"
        _prisma_log_info "Add to package.json: { \"prisma\": { \"seed\": \"ts-node prisma/seed.ts\" } }"
    fi

    if $PRISMA_BIN db seed; then
        _prisma_log_success "Database seeded successfully"
        return 0
    else
        _prisma_log_error "Database seeding failed"
        return 1
    fi
}

# Launch Prisma Studio
# Usage: prisma_studio [--port PORT] [--browser BROWSER]
prisma_studio() {
    _prisma_log_info "Launching Prisma Studio..."

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")

    _prisma_log_info "Prisma Studio will open in your browser"
    _prisma_log_info "Press Ctrl+C to stop"

    $PRISMA_BIN studio "${args[@]}"
}

# Reset database (destructive)
# Usage: prisma_reset [--force] [--skip-seed]
prisma_reset() {
    _prisma_log_warn "This will DELETE all data in your database!"

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")
    local force=false

    # Check if --force flag is present
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--force" ]] || [[ "$arg" == "-f" ]]; then
            force=true
            break
        fi
    done

    # Confirm unless --force is used
    if [[ "$force" == false ]]; then
        read -rp "Are you sure you want to reset the database? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            _prisma_log_info "Reset cancelled"
            return 0
        fi
    fi

    if $PRISMA_BIN migrate reset "${args[@]}"; then
        _prisma_log_success "Database reset completed"
        return 0
    else
        _prisma_log_error "Database reset failed"
        return 1
    fi
}

# Validate Prisma schema
# Usage: prisma_validate [--schema PATH]
prisma_validate() {
    _prisma_log_info "Validating Prisma schema..."

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")

    if $PRISMA_BIN validate "${args[@]}"; then
        _prisma_log_success "Schema is valid"
        return 0
    else
        _prisma_log_error "Schema validation failed"
        return 1
    fi
}

# Introspect existing database
# Usage: prisma_introspect [--force] [--print]
prisma_introspect() {
    _prisma_log_info "Introspecting database..."

    if ! _prisma_check_available; then
        return 1
    fi

    local args=("$@")

    _prisma_log_warn "This will overwrite your Prisma schema with database structure"

    if $PRISMA_BIN db pull "${args[@]}"; then
        _prisma_log_success "Database introspection completed"
        _prisma_log_info "Review changes in: $PRISMA_SCHEMA"
        return 0
    else
        _prisma_log_error "Database introspection failed"
        return 1
    fi
}

# Format Prisma schema file
# Usage: prisma_format [--schema PATH]
prisma_format() {
    _prisma_log_info "Formatting Prisma schema..."

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")

    if $PRISMA_BIN format "${args[@]}"; then
        _prisma_log_success "Schema formatted successfully"
        return 0
    else
        _prisma_log_error "Schema formatting failed"
        return 1
    fi
}

# Push schema to database without migrations (for prototyping)
# Usage: prisma_push [--force-reset] [--skip-generate]
prisma_push() {
    _prisma_log_info "Pushing schema to database..."

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    local args=("$@")

    _prisma_log_warn "db push is for prototyping. Use migrations for production."

    if $PRISMA_BIN db push "${args[@]}"; then
        _prisma_log_success "Schema pushed to database"
        return 0
    else
        _prisma_log_error "Schema push failed"
        return 1
    fi
}

# Create migration without applying it
# Usage: prisma_migrate_create NAME
prisma_migrate_create() {
    local migration_name="${1:-}"

    if [[ -z "$migration_name" ]]; then
        _prisma_log_error "Migration name required"
        _prisma_log_info "Usage: prisma_migrate_create MIGRATION_NAME"
        return 1
    fi

    _prisma_log_info "Creating migration: $migration_name"

    if ! _prisma_check_available; then
        return 1
    fi

    if ! _prisma_check_schema; then
        return 1
    fi

    if $PRISMA_BIN migrate dev --create-only --name "$migration_name"; then
        _prisma_log_success "Migration created (not applied)"
        _prisma_log_info "Review migration files in: prisma/migrations/"
        return 0
    else
        _prisma_log_error "Migration creation failed"
        return 1
    fi
}

# Export functions for use in other scripts
export -f prisma_generate
export -f prisma_migrate
export -f prisma_migrate_dev
export -f prisma_seed
export -f prisma_studio
export -f prisma_reset
export -f prisma_validate
export -f prisma_introspect
export -f prisma_format
export -f prisma_push
export -f prisma_migrate_create
