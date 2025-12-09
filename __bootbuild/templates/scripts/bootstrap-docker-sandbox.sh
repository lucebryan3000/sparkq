#!/bin/bash
# =============================================================================
# @name           bootstrap-docker-sandbox
# @phase          3
# @category       config
# @short          Tier 1 sandbox single-container for local dev
# @description    Sandbox environment with single container for local development.
#                 Combines app, PostgreSQL, and Redis with permissive settings,
#                 optional Docker socket and SSH mounts, bridge networking,
#                 and health checks. Ideal for quick local testing.
#
# @creates        docker-compose.yml
# @creates        Dockerfile
# @creates        .dockerignore
# @creates        entrypoint.sh
# @creates        .env.docker-sandbox
#
# @requires_tools docker
# @defaults       app_port=3000, postgres_port=5432, redis_port=6379
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Shared libraries
source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-docker-sandbox.sh"
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

SCRIPT_NAME="bootstrap-docker-sandbox"
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/docker/docker_tier1_sandbox"
ANSWERS_FILE="${PROJECT_ROOT}/.bootstrap-answers.env"
ENV_FILE_NAME=".env.docker-sandbox"
ENV_FILE="${PROJECT_ROOT}/${ENV_FILE_NAME}"

# -------------------------------------------------------------------
# Dependencies
# -------------------------------------------------------------------
declare_dependencies \
    --tools "docker" \
    --optional "docker-compose"

# -------------------------------------------------------------------
# Confirmation
# -------------------------------------------------------------------
pre_execution_confirm "$SCRIPT_NAME" "Docker sandbox (single container)" \
    "docker-compose.yml" \
    "Dockerfile" \
    ".dockerignore" \
    "entrypoint.sh" \
    "$ENV_FILE_NAME"

# -------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_info "Preparing single-container Docker sandbox..."

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------
resolve_placeholders() {
    local value="$1"
    local project_name="$2"
    local compose_name="$3"

    value="${value//\$\{project.name\}/$project_name}"
    value="${value//\$\{project_name\}/$project_name}"
    value="${value//\$\{COMPOSE_PROJECT_NAME\}/$compose_name}"
    echo "$value"
}

copy_template_file() {
    local name="$1"
    local src="${TEMPLATE_ROOT}/${name}"
    local dst="${PROJECT_ROOT}/${name}"

    if [[ ! -f "$src" ]]; then
        track_warning "$name (template missing)"
        log_warning "Template not found: $src"
        return
    fi

    if file_exists "$dst"; then
        if is_auto_approved "backup_existing_files"; then
            backup_file "$dst"
        else
            track_skipped "$name"
            log_warning "$name already exists, skipping"
            return
        fi
    fi

    if cp "$src" "$dst"; then
        verify_file "$dst"
        track_created "$name"
        log_file_created "$SCRIPT_NAME" "$name"
    else
        log_error "Failed to copy: $src → $dst"
    fi
}

uncomment_volume() {
    local pattern="$1"
    local file="$2"

    [[ ! -f "$file" ]] && return
    if grep -q "^\\s*#\\s*- ${pattern}" "$file"; then
        sed -i "s|^[[:space:]]*# - ${pattern}|      - ${pattern}|" "$file"
    fi
}

# -------------------------------------------------------------------
# Copy templates
# -------------------------------------------------------------------
copy_template_file "docker-compose.yml"
copy_template_file "Dockerfile"
copy_template_file ".dockerignore"
copy_template_file "entrypoint.sh"

chmod +x "${PROJECT_ROOT}/entrypoint.sh" 2>/dev/null || true

# -------------------------------------------------------------------
# Load config + answers (80% defaults, 20% prompts)
# -------------------------------------------------------------------
project_name=$(config_get "project.name" "app")
compose_project_name_raw=$(config_get "docker_sandbox.compose_project_name" "$project_name")

compose_project_name=$(resolve_placeholders "$compose_project_name_raw" "$project_name" "$project_name")
app_port=$(config_get "docker_sandbox.app_port" "3000")
postgres_port=$(config_get "docker_sandbox.postgres_port" "5432")
redis_port=$(config_get "docker_sandbox.redis_port" "6379")
postgres_user=$(config_get "docker_sandbox.postgres_user" "postgres")
postgres_password=$(config_get "docker_sandbox.postgres_password" "postgres")
postgres_db_raw=$(config_get "docker_sandbox.postgres_db" "$compose_project_name")
postgres_db=$(resolve_placeholders "$postgres_db_raw" "$project_name" "$compose_project_name")
mount_docker_socket=$(config_get "docker_sandbox.mount_docker_socket" "false")
mount_ssh_credentials=$(config_get "docker_sandbox.mount_ssh_credentials" "false")

# Override with answers file if present (questions = 20%)
if [[ -f "$ANSWERS_FILE" ]]; then
    source "$ANSWERS_FILE"
    compose_project_name="${DOCKER_SANDBOX_COMPOSE_PROJECT_NAME:-$compose_project_name}"
    app_port="${DOCKER_SANDBOX_APP_PORT:-$app_port}"
    postgres_port="${DOCKER_SANDBOX_POSTGRES_PORT:-$postgres_port}"
    redis_port="${DOCKER_SANDBOX_REDIS_PORT:-$redis_port}"
    postgres_user="${DOCKER_SANDBOX_POSTGRES_USER:-$postgres_user}"
    postgres_password="${DOCKER_SANDBOX_POSTGRES_PASSWORD:-$postgres_password}"
    postgres_db="${DOCKER_SANDBOX_POSTGRES_DB:-$postgres_db}"
    mount_docker_socket="${DOCKER_SANDBOX_MOUNT_DOCKER_SOCKET:-$mount_docker_socket}"
    mount_ssh_credentials="${DOCKER_SANDBOX_MOUNT_SSH_CREDENTIALS:-$mount_ssh_credentials}"
fi

mount_docker_socket=$(echo "$mount_docker_socket" | tr '[:upper:]' '[:lower:]')
mount_ssh_credentials=$(echo "$mount_ssh_credentials" | tr '[:upper:]' '[:lower:]')

# -------------------------------------------------------------------
# Optional mounts based on config
# -------------------------------------------------------------------
compose_file="${PROJECT_ROOT}/docker-compose.yml"
if [[ -f "$compose_file" ]]; then
    if [[ "$mount_docker_socket" == "true" ]]; then
        uncomment_volume "/var/run/docker.sock:/var/run/docker.sock" "$compose_file"
        log_info "Enabled Docker socket mount (grants container control of host Docker)."
    fi

    if [[ "$mount_ssh_credentials" == "true" ]]; then
        uncomment_volume "~/.ssh:/root/.ssh:ro" "$compose_file"
        uncomment_volume "~/.gitconfig:/root/.gitconfig:ro" "$compose_file"
        log_info "Enabled SSH key + gitconfig mounts for git access from the container."
    fi
fi

# -------------------------------------------------------------------
# Create env file for sandbox compose
# -------------------------------------------------------------------
database_url="postgresql://${postgres_user}:${postgres_password}@localhost:${postgres_port}/${postgres_db}"
redis_url="redis://localhost:${redis_port}"

if create_env_file "${ENV_FILE}" \
    "COMPOSE_PROJECT_NAME:${compose_project_name}" \
    "APP_PORT:${app_port}" \
    "PORT:${app_port}" \
    "HOST:0.0.0.0" \
    "POSTGRES_PORT:${postgres_port}" \
    "REDIS_PORT:${redis_port}" \
    "POSTGRES_USER:${postgres_user}" \
    "POSTGRES_PASSWORD:${postgres_password}" \
    "POSTGRES_DB:${postgres_db}" \
    "DATABASE_URL:${database_url}" \
    "REDIS_URL:${redis_url}" \
    "NODE_ENV:development" \
    "DEBUG:*" \
    "LOG_LEVEL:debug" \
    "DANGEROUSLY_DISABLE_HOST_CHECK:true" \
    "NEXT_TELEMETRY_DISABLED:1"; then
    track_created "$ENV_FILE_NAME"
    log_file_created "$SCRIPT_NAME" "$ENV_FILE_NAME"
fi

# -------------------------------------------------------------------
# Persist answers back into config
# -------------------------------------------------------------------
[[ -f "$ANSWERS_FILE" ]] && config_update_from_answers "$ANSWERS_FILE"

# -------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------
log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
echo "  1) docker compose --env-file ${ENV_FILE_NAME} up --build"
echo "  2) App:     http://localhost:${app_port}"
echo "  3) Postgres: localhost:${postgres_port} (user: ${postgres_user})"
echo "  4) Redis:    localhost:${redis_port}"
