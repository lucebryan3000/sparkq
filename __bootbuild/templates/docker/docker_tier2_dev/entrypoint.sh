#!/usr/bin/env bash
set -euo pipefail

APP_USER=${APP_USER:-node}
APP_GROUP=${APP_GROUP:-node}
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}

POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
POSTGRES_DB=${POSTGRES_DB:-${COMPOSE_PROJECT_NAME:-app}}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-}

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

configure_postgres() {
  mkdir -p /var/lib/postgresql /var/run/postgresql
  chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql

  local pg_version
  pg_version=$(ls /usr/lib/postgresql | head -n1)
  if [ -z "${pg_version}" ]; then
    echo "No PostgreSQL version found in /usr/lib/postgresql" >&2
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
}

start_redis() {
  mkdir -p /var/lib/redis
  chown -R redis:redis /var/lib/redis

  local redis_cmd=(redis-server --daemonize yes --bind 0.0.0.0 --port "${REDIS_PORT}" --dir /var/lib/redis --appendonly yes)
  if [ -n "${REDIS_PASSWORD}" ]; then
    redis_cmd+=(--requirepass "${REDIS_PASSWORD}")
  else
    redis_cmd+=(--protected-mode no)
  fi

  local cmd_str
  printf -v cmd_str '%q ' "${redis_cmd[@]}"
  su -s /bin/sh -c "${cmd_str% }" redis
}

ensure_app_user
configure_postgres
start_redis

exec gosu "${APP_USER}:${APP_GROUP}" "$@"
