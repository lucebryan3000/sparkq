#!/usr/bin/env bash

# ===================================================================
# TIER 1: Sandbox - Entrypoint with Bootstrap Integration
# Purpose: Setup services and run bootstrap, then start application
# Environment:
#   BOOTSTRAP_TIER: 1 (set in docker-compose)
#   SKIP_BOOTSTRAP: true to skip (optional)
# ===================================================================

set -euo pipefail

# ===================================================================
# Configuration
# ===================================================================

POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
POSTGRES_DB=${POSTGRES_DB:-${COMPOSE_PROJECT_NAME:-app}}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
REDIS_PORT=${REDIS_PORT:-6379}
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-/__bootbuild}"
BOOTSTRAP_TIER="${BOOTSTRAP_TIER:-1}"

# ===================================================================
# Logging Functions
# ===================================================================

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >&2
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# ===================================================================
# Service Configuration
# ===================================================================

configure_postgres() {
  log_info "Configuring PostgreSQL..."
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

  # Listen on all interfaces
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

  PGPORT=${POSTGRES_PORT} su - postgres -c "psql -v ON_ERROR_STOP=1 -c \"ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}'\""
  PGPORT=${POSTGRES_PORT} su - postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'\" | grep -q 1 || psql -v ON_ERROR_STOP=1 -c \"CREATE DATABASE \\\"${POSTGRES_DB}\\\"\""

  log_info "✓ PostgreSQL ready on port ${POSTGRES_PORT}"
}

start_redis() {
  log_info "Starting Redis..."
  mkdir -p /var/lib/redis
  chown -R redis:redis /var/lib/redis
  su -s /bin/sh -c "redis-server --daemonize yes --protected-mode no --bind 0.0.0.0 --port ${REDIS_PORT} --dir /var/lib/redis" redis
  log_info "✓ Redis ready on port ${REDIS_PORT}"
}

# ===================================================================
# Bootstrap Integration
# ===================================================================

run_bootstrap() {
    if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
        log_info "⏭️  Skipping bootstrap (SKIP_BOOTSTRAP=true)"
        return 0
    fi

    if [[ ! -f "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" ]]; then
        log_error "Bootstrap system not found at $BOOTSTRAP_DIR"
        return 1
    fi

    log_info "🔧 Running bootstrap system (Tier 1: Sandbox - All Phases)"

    # Tier 1 runs all phases (1-4) for maximum development capability
    export BOOTSTRAP_IN_DOCKER="true"
    export BOOTSTRAP_NO_COLOR="true"
    export BOOTSTRAP_LOG_FORMAT="text"
    export BOOTSTRAP_TIER="1"

    BOOTSTRAP_YES=1 BOOTSTRAP_IN_DOCKER=true \
        "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" \
        --phase=1-4 /app

    if [[ $? -eq 0 ]]; then
        log_info "✅ Bootstrap completed successfully"
        return 0
    else
        log_error "❌ Bootstrap failed"
        # In sandbox, warn but continue (development environment)
        return 0
    fi
}

# ===================================================================
# Main Execution
# ===================================================================

main() {
    log_info "🐳 TIER 1: Sandbox Container Starting"
    log_info "Bootstrap Tier: ${BOOTSTRAP_TIER}"

    # Setup services
    configure_postgres
    start_redis

    # Run bootstrap (optional)
    run_bootstrap

    # Start application
    log_info "🚀 Starting application..."
    exec "$@"
}

main "$@"
