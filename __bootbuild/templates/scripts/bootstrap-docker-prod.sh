#!/bin/bash

# ===================================================================
# bootstrap-docker-prod.sh
# Tier 3 prod: single-container app + Postgres + Redis, hardened
# Bridge networking for host access; secrets required; read-only app FS
# ===================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-docker-prod.sh"
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

SCRIPT_NAME="bootstrap-docker-prod"
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/docker/docker_tier3_prod"
ANSWERS_FILE="${PROJECT_ROOT}/.bootstrap-answers.env"
ENV_FILE_NAME=".env.docker-prod"
ENV_FILE="${PROJECT_ROOT}/${ENV_FILE_NAME}"
SECRETS_DIR="${PROJECT_ROOT}/secrets"

declare_dependencies \
    --tools "docker" \
    --optional "docker-compose"

pre_execution_confirm "$SCRIPT_NAME" "Docker Tier 3 Prod (single container)" \
    "docker-compose.yml" \
    "Dockerfile" \
    ".dockerignore" \
    "entrypoint.sh" \
    "healthcheck.js" \
    "$ENV_FILE_NAME" \
    "secrets/db_password.txt" \
    "secrets/redis_password.txt"

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_info "Preparing Tier 3 prod Docker template (single container, hardened)..."

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
copy_template_file "healthcheck.js"
copy_template_file "entrypoint.sh"
chmod +x "${PROJECT_ROOT}/entrypoint.sh" 2>/dev/null || true

project_name=$(config_get "project.name" "app")
compose_project_name_raw=$(config_get "docker_prod.compose_project_name" "$project_name")
compose_project_name=$(resolve_placeholders "$compose_project_name_raw" "$project_name" "$project_name")

app_port=$(config_get "docker_prod.app_port" "3000")
postgres_port=$(config_get "docker_prod.postgres_port" "5432")
redis_port=$(config_get "docker_prod.redis_port" "6379")
postgres_user=$(config_get "docker_prod.postgres_user" "${project_name}_prod")
postgres_password=$(config_get "docker_prod.postgres_password" "")
postgres_db_raw=$(config_get "docker_prod.postgres_db" "${project_name}_prod")
postgres_db=$(resolve_placeholders "$postgres_db_raw" "$project_name" "$compose_project_name")
redis_password=$(config_get "docker_prod.redis_password" "")
user_id=$(config_get "docker_prod.user_id" "1001")
group_id=$(config_get "docker_prod.group_id" "1001")
mount_docker_socket=$(config_get "docker_prod.mount_docker_socket" "false")
mount_ssh_credentials=$(config_get "docker_prod.mount_ssh_credentials" "false")

if [[ -f "$ANSWERS_FILE" ]]; then
    source "$ANSWERS_FILE"
    compose_project_name="${DOCKER_PROD_COMPOSE_PROJECT_NAME:-$compose_project_name}"
    app_port="${DOCKER_PROD_APP_PORT:-$app_port}"
    postgres_port="${DOCKER_PROD_POSTGRES_PORT:-$postgres_port}"
    redis_port="${DOCKER_PROD_REDIS_PORT:-$redis_port}"
    postgres_user="${DOCKER_PROD_POSTGRES_USER:-$postgres_user}"
    postgres_password="${DOCKER_PROD_POSTGRES_PASSWORD:-$postgres_password}"
    postgres_db="${DOCKER_PROD_POSTGRES_DB:-$postgres_db}"
    redis_password="${DOCKER_PROD_REDIS_PASSWORD:-$redis_password}"
    user_id="${DOCKER_PROD_USER_ID:-$user_id}"
    group_id="${DOCKER_PROD_GROUP_ID:-$group_id}"
    mount_docker_socket="${DOCKER_PROD_MOUNT_DOCKER_SOCKET:-$mount_docker_socket}"
    mount_ssh_credentials="${DOCKER_PROD_MOUNT_SSH_CREDENTIALS:-$mount_ssh_credentials}"
fi

if [[ -z "$postgres_password" || -z "$redis_password" ]]; then
    log_fatal "postgres_password and redis_password are required for prod."
fi

mount_docker_socket=$(echo "$mount_docker_socket" | tr '[:upper:]' '[:lower:]')
mount_ssh_credentials=$(echo "$mount_ssh_credentials" | tr '[:upper:]' '[:lower:]')

compose_file="${PROJECT_ROOT}/docker-compose.yml"
if [[ -f "$compose_file" ]]; then
    if [[ "$mount_docker_socket" == "true" ]]; then
        uncomment_volume "/var/run/docker.sock:/var/run/docker.sock" "$compose_file"
        log_warning "Docker socket mount enabled: container can control host Docker."
    fi

    if [[ "$mount_ssh_credentials" == "true" ]]; then
        uncomment_volume "~/.ssh:/home/node/.ssh:ro" "$compose_file"
        uncomment_volume "~/.gitconfig:/home/node/.gitconfig:ro" "$compose_file"
        log_warning "SSH key + gitconfig mounts enabled; avoid for production."
    fi
fi

database_url="postgresql://${postgres_user}:${postgres_password}@localhost:${postgres_port}/${postgres_db}"
redis_url="redis://:${redis_password}@localhost:${redis_port}"

if create_env_file "${ENV_FILE}" \
    "COMPOSE_PROJECT_NAME:${compose_project_name}" \
    "APP_PORT:${app_port}" \
    "POSTGRES_PORT:${postgres_port}" \
    "REDIS_PORT:${redis_port}" \
    "POSTGRES_USER:${postgres_user}" \
    "POSTGRES_PASSWORD:${postgres_password}" \
    "POSTGRES_DB:${postgres_db}" \
    "REDIS_PASSWORD:${redis_password}" \
    "DATABASE_URL:${database_url}" \
    "REDIS_URL:${redis_url}" \
    "NODE_ENV:production" \
    "LOG_LEVEL:info" \
    "NEXT_TELEMETRY_DISABLED:1"; then
    track_created "$ENV_FILE_NAME"
    log_file_created "$SCRIPT_NAME" "$ENV_FILE_NAME"
fi

ensure_dir "$SECRETS_DIR"
printf "%s" "$postgres_password" > "${SECRETS_DIR}/db_password.txt"
printf "%s" "$redis_password" > "${SECRETS_DIR}/redis_password.txt"
log_file_created "$SCRIPT_NAME" "secrets/db_password.txt"
log_file_created "$SCRIPT_NAME" "secrets/redis_password.txt"

[[ -f "$ANSWERS_FILE" ]] && config_update_from_answers "$ANSWERS_FILE"

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
echo "  1) docker compose --env-file ${ENV_FILE_NAME} up --build"
echo "  2) App:       http://localhost:${app_port}"
echo "  3) Postgres:  localhost:${postgres_port} (user: ${postgres_user})"
echo "  4) Redis:     localhost:${redis_port}"
