#!/usr/bin/env bash

# ===================================================================
# TIER 3: Production - Entrypoint with Bootstrap Integration
# Purpose: Setup services, run bootstrap (phase 1 only), then start app
# Environment:
#   BOOTSTRAP_TIER: 3 (set in docker-compose)
#   POSTGRES_PASSWORD, REDIS_PASSWORD: Required for production
#   SKIP_BOOTSTRAP: true to skip (not recommended)
# ===================================================================

set -euo pipefail

# ===================================================================
# Configuration
# ===================================================================

APP_USER=${APP_USER:-appuser}
APP_GROUP=${APP_GROUP:-appgroup}
USER_ID=${USER_ID:-1001}
GROUP_ID=${GROUP_ID:-1001}

POSTGRES_USER=${POSTGRES_USER:-${COMPOSE_PROJECT_NAME:-app}_prod}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:?POSTGRES_PASSWORD required}
POSTGRES_DB=${POSTGRES_DB:-${COMPOSE_PROJECT_NAME:-app}_prod}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:?REDIS_PASSWORD required}

BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-/__bootbuild}"
BOOTSTRAP_TIER="${BOOTSTRAP_TIER:-3}"

# ===================================================================
# Logging Functions (JSON for production log aggregation)
# ===================================================================

log_info() {
    printf '{"level":"info","timestamp":"%s","message":"%s","tier":"3"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >&2
}

log_error() {
    printf '{"level":"error","timestamp":"%s","message":"%s","tier":"3"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >&2
}

log_warning() {
    printf '{"level":"warning","timestamp":"%s","message":"%s","tier":"3"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >&2
}

# ===================================================================
# User & Permissions Setup
# ===================================================================

ensure_app_user() {
  if ! id "$APP_USER" >/dev/null 2>&1; then
    groupadd -g "$GROUP_ID" "$APP_GROUP"
    useradd -m -u "$USER_ID" -g "$GROUP_ID" "$APP_USER"
  else
    groupmod -o -g "$GROUP_ID" "$APP_GROUP" || true
    usermod -o -u "$USER_ID" -g "$GROUP_ID" "$APP_USER" || true
  fi

  mkdir -p /home/"$APP_USER" /app /home/"$APP_USER"/.local/share/pnpm/store /app/node_modules
  chown -R "$APP_USER:$APP_GROUP" /home/"$APP_USER" /app /home/"$APP_USER"/.local /app/node_modules
}

# ===================================================================
# Service Configuration
# ===================================================================

configure_postgres() {
  log_info "Configuring PostgreSQL"
  mkdir -p /var/lib/postgresql /var/run/postgresql
  chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql

  local pg_version
  pg_version=$(ls /usr/lib/postgresql | head -n1)
  if [ -z "${pg_version}" ]; then
    log_error "No PostgreSQL version found"
    exit 1
  fi

  local pg_cluster_dir="/var/lib/postgresql/${pg_version}/main"
  local pg_conf="/etc/postgresql/${pg_version}/main/postgresql.conf"
  local pg_hba="/etc/postgresql/${pg_version}/main/pg_hba.conf"

  if [ ! -s "${pg_cluster_dir}/PG_VERSION" ]; then
    pg_createcluster "${pg_version}" main --start
  fi

  if grep -Eq '^#?listen_addresses' "${pg_conf}"; then
    sed -ri "s|^#?listen_addresses\\s*=.*|listen_addresses = '*'|" "${pg_conf}"
  else
    echo "listen_addresses = '*'" >> "${pg_conf}"
  fi

  if grep -Eq '^#?port' "${pg_conf}"; then
    sed -ri "s|^#?port\\s*=.*|port = ${POSTGRES_PORT}|" "${pg_conf}"
  else
    echo "port = ${POSTGRES_PORT}" >> "${pg_conf}"
  fi

  if ! grep -q "host all all 0.0.0.0/0 scram-sha-256" "${pg_hba}"; then
    echo "host all all 0.0.0.0/0 scram-sha-256" >> "${pg_hba}"
  fi

  if pg_ctlcluster "${pg_version}" main status >/dev/null 2>&1; then
    pg_ctlcluster "${pg_version}" main restart
  else
    pg_ctlcluster "${pg_version}" main start
  fi

  PGPORT=${POSTGRES_PORT} su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'\" | grep -q 1 || psql -v ON_ERROR_STOP=1 -c \"CREATE USER \\\"${POSTGRES_USER}\\\" WITH PASSWORD '${POSTGRES_PASSWORD}'\""
  PGPORT=${POSTGRES_PORT} su - postgres -c "psql -v ON_ERROR_STOP=1 -c \"ALTER USER \\\"${POSTGRES_USER}\\\" WITH PASSWORD '${POSTGRES_PASSWORD}'\""
  PGPORT=${POSTGRES_PORT} su - postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'\" | grep -q 1 || psql -v ON_ERROR_STOP=1 -c \"CREATE DATABASE \\\"${POSTGRES_DB}\\\" OWNER \\\"${POSTGRES_USER}\\\"\""

  log_info "PostgreSQL ready"
}

start_redis() {
  log_info "Starting Redis"
  mkdir -p /var/lib/redis
  chown -R redis:redis /var/lib/redis

  local redis_cmd=(redis-server --daemonize yes --bind 0.0.0.0 --port "${REDIS_PORT}" --dir /var/lib/redis --appendonly yes --requirepass "${REDIS_PASSWORD}")

  local cmd_str
  printf -v cmd_str '%q ' "${redis_cmd[@]}"
  su -s /bin/sh -c "${cmd_str% }" redis

  log_info "Redis ready"
}

# ===================================================================
# Bootstrap Integration (Phase 1 only for production)
# ===================================================================

run_bootstrap() {
    if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
        log_warning "Bootstrap skipped (SKIP_BOOTSTRAP=true)"
        return 0
    fi

    if [[ ! -f "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" ]]; then
        log_error "Bootstrap system not found at $BOOTSTRAP_DIR"
        # Production should fail if bootstrap is missing
        exit 1
    fi

    log_info "Running bootstrap (Tier 3: Production - Phase 1 only)"

    # Tier 3 runs ONLY phase 1 (essentials, no infrastructure or CI/CD setup)
    export BOOTSTRAP_IN_DOCKER="true"
    export BOOTSTRAP_NO_COLOR="true"
    export BOOTSTRAP_LOG_FORMAT="json"
    export BOOTSTRAP_TIER="3"

    BOOTSTRAP_YES=1 BOOTSTRAP_IN_DOCKER=true \
        "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" \
        --phase=1 /app

    if [[ $? -eq 0 ]]; then
        log_info "Bootstrap completed successfully"
        return 0
    else
        log_error "Bootstrap failed - aborting production startup"
        exit 1
    fi
}

# ===================================================================
# Main Execution
# ===================================================================

main() {
    log_info "TIER 3: Production Container Starting"

    # Setup users and permissions
    ensure_app_user

    # Setup services
    configure_postgres
    start_redis

    # Run bootstrap (phase 1 only, fail hard on errors)
    run_bootstrap

    # Start application as non-root user
    log_info "Starting application"
    exec gosu "${APP_USER}:${APP_GROUP}" "$@"
}

main "$@"
