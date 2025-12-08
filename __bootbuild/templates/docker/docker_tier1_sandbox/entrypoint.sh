#!/usr/bin/env bash
set -euo pipefail

POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
POSTGRES_DB=${POSTGRES_DB:-${COMPOSE_PROJECT_NAME:-app}}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
REDIS_PORT=${REDIS_PORT:-6379}

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

  # Listen on all interfaces so host can connect via published port
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
}

start_redis() {
  mkdir -p /var/lib/redis
  chown -R redis:redis /var/lib/redis
  su -s /bin/sh -c "redis-server --daemonize yes --protected-mode no --bind 0.0.0.0 --port ${REDIS_PORT} --dir /var/lib/redis" redis
}

configure_postgres
start_redis

exec "$@"
