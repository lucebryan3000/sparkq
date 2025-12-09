#!/bin/bash
# =============================================================================
# @script         bootstrap-docker-dev
# @version        1.0.0
# @phase          3
# @category       config
# @priority       50
# @short          Tier 2 dev single-container app + Postgres + Redis
# @description    Development environment with single container combining app,
#                 PostgreSQL, and Redis. Includes hardened networking vs sandbox,
#                 optional Docker socket and SSH credential mounts, healthchecks,
#                 and bridge networking for local host access.
#
# @creates        docker-compose.yml
# @creates        Dockerfile
# @creates        .dockerignore
# @creates        entrypoint.sh
# @creates        .env.docker-dev
#
# @detects        has_docker_compose
# @questions      docker-dev
# @defaults       app_port=3000, postgres_port=5432, redis_port=6379
# @detects        has_docker_compose
# @questions      docker-dev
# @defaults       debug_port=9229, user_id=1000, group_id=1000
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  project
# @env_vars        ANSWERS_FILE,DOCKER_DEV_APP_PORT,DOCKER_DEV_COMPOSE_PROJECT_NAME,DOCKER_DEV_DEBUG_PORT,DOCKER_DEV_GROUP_ID,DOCKER_DEV_MOUNT_DOCKER_SOCKET,DOCKER_DEV_MOUNT_SSH_CREDENTIALS,DOCKER_DEV_POSTGRES_DB,DOCKER_DEV_POSTGRES_PASSWORD,DOCKER_DEV_POSTGRES_PORT,DOCKER_DEV_POSTGRES_USER,DOCKER_DEV_REDIS_PORT,DOCKER_DEV_USER_ID,ENV_FILE,ENV_FILE_NAME
# @interactive     no
# @platforms       all
# @conflicts       docker-prod
# @rollback        rm -rf docker-compose.yml Dockerfile .dockerignore entrypoint.sh .env.docker-dev
# @verify          test -f docker-compose.yml
# @docs            https://docs.docker.com/compose/
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-docker-dev.sh"
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

SCRIPT_NAME="bootstrap-docker-dev"
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/docker/docker_tier2_dev"
ANSWERS_FILE="${PROJECT_ROOT}/.bootstrap-answers.env"
ENV_FILE_NAME=".env.docker-dev"
ENV_FILE="${PROJECT_ROOT}/${ENV_FILE_NAME}"

declare_dependencies \
    --tools "docker" \
    --optional "docker-compose"

pre_execution_confirm "$SCRIPT_NAME" "Docker Tier 2 Dev (single container)" \
    "docker-compose.yml" \
    "Dockerfile" \
    ".dockerignore" \
    "entrypoint.sh" \
    "$ENV_FILE_NAME"

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_info "Preparing Tier 2 dev Docker sandbox (hardened vs sandbox)..."

copy_template_file() {
    local name="$1"
    local src="${TEMPLATE_ROOT}/${name}"
    local dst="${PROJECT_ROOT}/${name}"

    if [[ ! -f "$src" ]]; then
        track_warning "$name (template missing)"
        log_warning "Template not found: $src"
        return
    fi

    if safe_copy "$src" "$dst"; then
        track_created "$name"
        log_file_created "$SCRIPT_NAME" "$name"
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

resolve_placeholders() {
    local value="$1"
    local project="$2"
    local compose="$3"
    value="${value//\$\{project.name\}/$project}"
    value="${value//\$\{project_name\}/$project}"
    value="${value//\$\{COMPOSE_PROJECT_NAME\}/$compose}"
    echo "$value"
}

copy_template_file "docker-compose.yml"
copy_template_file "Dockerfile"
copy_template_file ".dockerignore"
copy_template_file "entrypoint.sh"
chmod +x "${PROJECT_ROOT}/entrypoint.sh" 2>/dev/null || true

project_name=$(config_get "project.name" "app")
compose_project_name_raw=$(config_get "docker_dev.compose_project_name" "$project_name")

compose_project_name=$(resolve_placeholders "$compose_project_name_raw" "$project_name" "$project_name")
app_port=$(config_get "docker_dev.app_port" "3000")
debug_port=$(config_get "docker_dev.debug_port" "9229")
postgres_port=$(config_get "docker_dev.postgres_port" "5432")
redis_port=$(config_get "docker_dev.redis_port" "6379")
postgres_user=$(config_get "docker_dev.postgres_user" "postgres")
postgres_password=$(config_get "docker_dev.postgres_password" "postgres")
postgres_db_raw=$(config_get "docker_dev.postgres_db" "$compose_project_name")
postgres_db=$(resolve_placeholders "$postgres_db_raw" "$project_name" "$compose_project_name")
user_id=$(config_get "docker_dev.user_id" "1000")
group_id=$(config_get "docker_dev.group_id" "1000")
mount_docker_socket=$(config_get "docker_dev.mount_docker_socket" "false")
mount_ssh_credentials=$(config_get "docker_dev.mount_ssh_credentials" "false")

if [[ -f "$ANSWERS_FILE" ]]; then
    source "$ANSWERS_FILE"
    compose_project_name="${DOCKER_DEV_COMPOSE_PROJECT_NAME:-$compose_project_name}"
    app_port="${DOCKER_DEV_APP_PORT:-$app_port}"
    debug_port="${DOCKER_DEV_DEBUG_PORT:-$debug_port}"
    postgres_port="${DOCKER_DEV_POSTGRES_PORT:-$postgres_port}"
    redis_port="${DOCKER_DEV_REDIS_PORT:-$redis_port}"
    postgres_user="${DOCKER_DEV_POSTGRES_USER:-$postgres_user}"
    postgres_password="${DOCKER_DEV_POSTGRES_PASSWORD:-$postgres_password}"
    postgres_db="${DOCKER_DEV_POSTGRES_DB:-$postgres_db}"
    user_id="${DOCKER_DEV_USER_ID:-$user_id}"
    group_id="${DOCKER_DEV_GROUP_ID:-$group_id}"
    mount_docker_socket="${DOCKER_DEV_MOUNT_DOCKER_SOCKET:-$mount_docker_socket}"
    mount_ssh_credentials="${DOCKER_DEV_MOUNT_SSH_CREDENTIALS:-$mount_ssh_credentials}"
fi

mount_docker_socket=$(echo "$mount_docker_socket" | tr '[:upper:]' '[:lower:]')
mount_ssh_credentials=$(echo "$mount_ssh_credentials" | tr '[:upper:]' '[:lower:]')

compose_file="${PROJECT_ROOT}/docker-compose.yml"
if [[ -f "$compose_file" ]]; then
    if [[ "$mount_docker_socket" == "true" ]]; then
        uncomment_volume "/var/run/docker.sock:/var/run/docker.sock" "$compose_file"
        log_info "Enabled Docker socket mount (grants container control of host Docker)."
    fi

    if [[ "$mount_ssh_credentials" == "true" ]]; then
        uncomment_volume "~/.ssh:/home/node/.ssh:ro" "$compose_file"
        uncomment_volume "~/.gitconfig:/home/node/.gitconfig:ro" "$compose_file"
        log_info "Enabled SSH key + gitconfig mounts for git access from the container."
    fi
fi

database_url="postgresql://${postgres_user}:${postgres_password}@localhost:${postgres_port}/${postgres_db}"
redis_url="redis://localhost:${redis_port}"

if create_env_file "${ENV_FILE}" \
    "COMPOSE_PROJECT_NAME:${compose_project_name}" \
    "USER_ID:${user_id}" \
    "GROUP_ID:${group_id}" \
    "APP_USER:node" \
    "APP_GROUP:node" \
    "APP_PORT:${app_port}" \
    "PORT:${app_port}" \
    "HOST:0.0.0.0" \
    "DEBUG_PORT:${debug_port}" \
    "POSTGRES_PORT:${postgres_port}" \
    "REDIS_PORT:${redis_port}" \
    "POSTGRES_USER:${postgres_user}" \
    "POSTGRES_PASSWORD:${postgres_password}" \
    "POSTGRES_DB:${postgres_db}" \
    "REDIS_PASSWORD:" \
    "DATABASE_URL:${database_url}" \
    "REDIS_URL:${redis_url}" \
    "NODE_ENV:development" \
    "LOG_LEVEL:debug" \
    "DEBUG:*" \
    "DANGEROUSLY_DISABLE_HOST_CHECK:false" \
    "NEXT_TELEMETRY_DISABLED:1"; then
    track_created "$ENV_FILE_NAME"
    log_file_created "$SCRIPT_NAME" "$ENV_FILE_NAME"
fi

[[ -f "$ANSWERS_FILE" ]] && config_update_from_answers "$ANSWERS_FILE"

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
echo "  1) docker compose --env-file ${ENV_FILE_NAME} up --build"
echo "  2) App:       http://localhost:${app_port}"
echo "  3) Postgres:  localhost:${postgres_port} (user: ${postgres_user})"
echo "  4) Redis:     localhost:${redis_port}"
echo "  5) Debugger:  http://localhost:${debug_port}"
