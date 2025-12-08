#!/bin/bash
# _build/start.sh
# SparkQ Bootstrap startup script
set -e

echo "=== SparkQ Bootstrap ==="
echo "Starting supervisor (manages PostgreSQL + API + Cron)..."

# Fix PostgreSQL data permissions
chown -R postgres:postgres /var/lib/postgresql/data 2>/dev/null || true
chmod 700 /var/lib/postgresql/data

# Apply schema on first boot (after PostgreSQL starts via supervisor)
(
  sleep 3  # Wait for PostgreSQL to start
  until pg_isready -q; do sleep 0.5; done
  echo "PostgreSQL ready, applying schema..."
  cd /app
  PGPASSWORD=bootstrap psql -h localhost -U bootstrap -d sparkq -f src/db/schema.sql 2>/dev/null || true
  echo "Schema applied"
) &

# Start supervisor (runs PostgreSQL, API, and cron as managed processes)
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
