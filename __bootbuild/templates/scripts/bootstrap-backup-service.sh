#!/bin/bash

# ===================================================================
# bootstrap-backup-service.sh
#
# Purpose: Backup and Disaster Recovery Setup (CI/CD & Deployment - Phase 4)
# Creates: Backup configuration, restore procedures, monitoring scripts
# Config:  [backup] section in bootstrap.config
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Source docker utilities if available
if [[ -f "${BOOTSTRAP_DIR}/lib/docker-utils.sh" ]]; then
    source "${BOOTSTRAP_DIR}/lib/docker-utils.sh"
fi

# Initialize script
init_script "bootstrap-backup-service"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-backup-service"

# Track created files for display
declare -a CREATED_FILES=()
declare -a SKIPPED_FILES=()

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "backup.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Backup service bootstrap disabled in config"
    exit 0
fi

# Read backup-specific settings
BACKUP_PROVIDER=$(config_get "backup.provider" "restic")
BACKUP_STORAGE=$(config_get "backup.storage" "s3")
BACKUP_SCHEDULE=$(config_get "backup.schedule" "0 2 * * *")
BACKUP_RETENTION_DAYS=$(config_get "backup.retention_days" "30")
BACKUP_ENCRYPTION_KEY=$(config_get "backup.encryption_key" "")
BACKUP_SOURCES=$(config_get "backup.sources" "database,uploads")
BACKUP_COMPRESSION=$(config_get "backup.compression" "true")
BACKUP_VERIFY=$(config_get "backup.verify" "true")

# Storage backend settings
S3_BUCKET=$(config_get "backup.s3_bucket" "")
S3_REGION=$(config_get "backup.s3_region" "us-east-1")
S3_ENDPOINT=$(config_get "backup.s3_endpoint" "")  # For S3-compatible storage

# Get project info
PROJECT_NAME=$(config_get "project.name" "app")
PROJECT_PHASE=$(config_get "project.phase" "POC")

# Database settings (for database backups)
DB_TYPE=$(config_get "docker.database_type" "postgres")
DB_NAME=$(config_get "postgres.db_name" "app_db")
DB_USER=$(config_get "postgres.db_user" "postgres")
DB_PASSWORD=$(config_get "postgres.db_password" "postgres")
DB_HOST=$(config_get "postgres.host" "localhost")
DB_PORT=$(config_get "postgres.port" "5432")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    "config/backup/"
    "config/backup/backup.config.json"
    "config/backup/restic-backup.sh"
    "config/backup/restore-procedure.md"
    "config/backup/.backup.env"
    "scripts/backup-database.sh"
    "scripts/restore-database.sh"
    "scripts/verify-backup.sh"
)

pre_execution_confirm "$SCRIPT_NAME" "Backup & Disaster Recovery Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check backup dependencies
if [[ "$BACKUP_PROVIDER" == "restic" ]]; then
    if ! command -v restic &>/dev/null; then
        log_warning "restic not installed - install from https://restic.net/"
        log_warning "Backup scripts will be created but require restic to run"
    fi
fi

# Generate encryption key if not provided
if [[ -z "$BACKUP_ENCRYPTION_KEY" ]]; then
    BACKUP_ENCRYPTION_KEY=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p)
    log_warning "Generated random encryption key - save this securely!"
fi

# Tier-specific validation
if [[ "$PROJECT_PHASE" == "Tier 3" ]] || [[ "$PROJECT_PHASE" == "production" ]]; then
    # Tier 3 production: mandatory encryption
    if [[ -z "$BACKUP_ENCRYPTION_KEY" ]]; then
        log_fatal "Encryption key required for production deployments"
    fi

    if [[ -z "$S3_BUCKET" ]] && [[ "$BACKUP_STORAGE" == "s3" ]]; then
        log_fatal "S3 bucket required for production backups"
    fi

    log_info "Production mode: encryption and remote storage enabled"
fi

log_success "Environment validated"

# ===================================================================
# Create Directory Structure
# ===================================================================

log_info "Creating backup directory structure..."

if ! dir_exists "$PROJECT_ROOT/config/backup"; then
    ensure_dir "$PROJECT_ROOT/config/backup"
    log_dir_created "$SCRIPT_NAME" "config/backup/"
fi

if ! dir_exists "$PROJECT_ROOT/backups"; then
    ensure_dir "$PROJECT_ROOT/backups"
    log_dir_created "$SCRIPT_NAME" "backups/"
fi

if ! dir_exists "$PROJECT_ROOT/scripts"; then
    ensure_dir "$PROJECT_ROOT/scripts"
    log_dir_created "$SCRIPT_NAME" "scripts/"
fi

log_success "Directory structure created"

# ===================================================================
# Create Backup Configuration
# ===================================================================

log_info "Creating backup configuration..."

BACKUP_CONFIG_FILE="$PROJECT_ROOT/config/backup/backup.config.json"

if file_exists "$BACKUP_CONFIG_FILE"; then
    backup_file "$BACKUP_CONFIG_FILE"
    SKIPPED_FILES+=("config/backup/backup.config.json (backed up)")
    log_warning "backup.config.json already exists, backed up"
else
    cat > "$BACKUP_CONFIG_FILE" << 'EOFCONFIG'
{
  "version": "1.0",
  "provider": "{{BACKUP_PROVIDER}}",
  "schedule": {
    "full": "0 2 * * 0",
    "incremental": "0 2 * * 1-6",
    "cron": "{{BACKUP_SCHEDULE}}"
  },
  "retention": {
    "daily": 7,
    "weekly": 4,
    "monthly": 12,
    "yearly": 3,
    "days": {{BACKUP_RETENTION_DAYS}}
  },
  "storage": {
    "backend": "{{BACKUP_STORAGE}}",
    "s3": {
      "bucket": "{{S3_BUCKET}}",
      "region": "{{S3_REGION}}",
      "endpoint": "{{S3_ENDPOINT}}",
      "encryption": "AES256"
    },
    "local": {
      "path": "./backups"
    }
  },
  "sources": [
    {
      "name": "database",
      "type": "{{DB_TYPE}}",
      "enabled": true,
      "pre_backup": "scripts/backup-database.sh",
      "paths": ["./backups/database"]
    },
    {
      "name": "uploads",
      "type": "files",
      "enabled": true,
      "paths": ["./uploads", "./public/uploads"]
    },
    {
      "name": "config",
      "type": "files",
      "enabled": true,
      "paths": ["./config", "./.env.example"]
    }
  ],
  "options": {
    "compression": {{BACKUP_COMPRESSION}},
    "verify": {{BACKUP_VERIFY}},
    "encryption": true,
    "checksum": "sha256"
  },
  "notifications": {
    "on_success": false,
    "on_failure": true,
    "channels": ["log"]
  },
  "monitoring": {
    "healthcheck_url": "",
    "max_age_hours": 48
  }
}
EOFCONFIG

    # Replace placeholders
    sed -i "s/{{BACKUP_PROVIDER}}/$BACKUP_PROVIDER/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{BACKUP_STORAGE}}/$BACKUP_STORAGE/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{BACKUP_SCHEDULE}}/$BACKUP_SCHEDULE/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{BACKUP_RETENTION_DAYS}}/$BACKUP_RETENTION_DAYS/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{S3_BUCKET}}/$S3_BUCKET/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{S3_REGION}}/$S3_REGION/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{S3_ENDPOINT}}/$S3_ENDPOINT/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{DB_TYPE}}/$DB_TYPE/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{BACKUP_COMPRESSION}}/$BACKUP_COMPRESSION/g" "$BACKUP_CONFIG_FILE"
    sed -i "s/{{BACKUP_VERIFY}}/$BACKUP_VERIFY/g" "$BACKUP_CONFIG_FILE"

    verify_file "$BACKUP_CONFIG_FILE"
    log_file_created "$SCRIPT_NAME" "config/backup/backup.config.json"
    CREATED_FILES+=("config/backup/backup.config.json")
fi

# ===================================================================
# Create Restic Backup Script
# ===================================================================

log_info "Creating Restic backup script..."

RESTIC_SCRIPT="$PROJECT_ROOT/config/backup/restic-backup.sh"

if file_exists "$RESTIC_SCRIPT"; then
    backup_file "$RESTIC_SCRIPT"
    SKIPPED_FILES+=("config/backup/restic-backup.sh (backed up)")
    log_warning "restic-backup.sh already exists, backed up"
else
    cat > "$RESTIC_SCRIPT" << 'EOFRESTIC'
#!/bin/bash

# ===================================================================
# Restic Backup Script
# Auto-generated by bootstrap-backup-service.sh
# ===================================================================

set -euo pipefail

# Configuration
PROJECT_NAME="{{PROJECT_NAME}}"
BACKUP_DIR="./backups"
LOG_FILE="./logs/backup-$(date +%Y%m%d-%H%M%S).log"

# Source environment
if [[ -f "./config/backup/.backup.env" ]]; then
    source "./config/backup/.backup.env"
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# ===================================================================
# Logging Functions
# ===================================================================

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# ===================================================================
# Backup Functions
# ===================================================================

check_restic() {
    if ! command -v restic &>/dev/null; then
        log_error "restic not installed"
        exit 1
    fi
}

init_repository() {
    log "Checking repository..."

    if ! restic snapshots &>/dev/null; then
        log "Initializing new repository..."
        restic init
        log "Repository initialized"
    else
        log "Repository already initialized"
    fi
}

backup_sources() {
    log "Starting backup..."

    # Run pre-backup hooks (database dumps, etc.)
    if [[ -f "./scripts/backup-database.sh" ]]; then
        log "Running database backup..."
        bash ./scripts/backup-database.sh
    fi

    # Backup sources
    restic backup \
        --tag "${PROJECT_NAME}" \
        --tag "$(date +%Y%m%d)" \
        --verbose \
        ./backups/database \
        ./uploads \
        ./config \
        2>&1 | tee -a "$LOG_FILE"

    log "Backup completed"
}

verify_backup() {
    log "Verifying backup integrity..."

    restic check --read-data-subset=5% 2>&1 | tee -a "$LOG_FILE"

    log "Verification completed"
}

prune_old_backups() {
    log "Pruning old backups..."

    restic forget \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 12 \
        --keep-yearly 3 \
        --prune \
        2>&1 | tee -a "$LOG_FILE"

    log "Pruning completed"
}

show_stats() {
    log "Backup statistics:"

    restic stats latest 2>&1 | tee -a "$LOG_FILE"
}

# ===================================================================
# Main
# ===================================================================

log "========================================"
log "Restic Backup Starting"
log "Project: $PROJECT_NAME"
log "========================================"

check_restic
init_repository
backup_sources

if [[ "${RESTIC_VERIFY:-true}" == "true" ]]; then
    verify_backup
fi

prune_old_backups
show_stats

log "========================================"
log "Backup Completed Successfully"
log "Log: $LOG_FILE"
log "========================================"

exit 0
EOFRESTIC

    # Replace placeholders
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$RESTIC_SCRIPT"

    chmod +x "$RESTIC_SCRIPT"

    verify_file "$RESTIC_SCRIPT"
    log_file_created "$SCRIPT_NAME" "config/backup/restic-backup.sh"
    CREATED_FILES+=("config/backup/restic-backup.sh")
fi

# ===================================================================
# Create Backup Environment File
# ===================================================================

log_info "Creating backup environment configuration..."

BACKUP_ENV_FILE="$PROJECT_ROOT/config/backup/.backup.env"

if file_exists "$BACKUP_ENV_FILE"; then
    backup_file "$BACKUP_ENV_FILE"
    SKIPPED_FILES+=("config/backup/.backup.env (backed up)")
    log_warning ".backup.env already exists, backed up"
else
    cat > "$BACKUP_ENV_FILE" << 'EOFENV'
# ===================================================================
# Backup Environment Configuration
# Auto-generated by bootstrap-backup-service.sh
#
# IMPORTANT: Never commit this file to git!
# Add to .gitignore: config/backup/.backup.env
# ===================================================================

# Restic Repository
RESTIC_REPOSITORY={{RESTIC_REPOSITORY}}
RESTIC_PASSWORD={{BACKUP_ENCRYPTION_KEY}}

# AWS S3 Configuration (if using S3 backend)
AWS_ACCESS_KEY_ID={{AWS_ACCESS_KEY_ID}}
AWS_SECRET_ACCESS_KEY={{AWS_SECRET_ACCESS_KEY}}
AWS_DEFAULT_REGION={{S3_REGION}}

# S3-Compatible Storage (Backblaze B2, DigitalOcean Spaces, etc.)
# AWS_S3_ENDPOINT={{S3_ENDPOINT}}

# Backup Options
RESTIC_COMPRESSION={{RESTIC_COMPRESSION}}
RESTIC_VERIFY={{RESTIC_VERIFY}}

# Database Credentials (for backup scripts)
DB_TYPE={{DB_TYPE}}
DB_HOST={{DB_HOST}}
DB_PORT={{DB_PORT}}
DB_NAME={{DB_NAME}}
DB_USER={{DB_USER}}
DB_PASSWORD={{DB_PASSWORD}}

# Notification Settings
BACKUP_NOTIFY_EMAIL=
BACKUP_NOTIFY_SLACK_WEBHOOK=

# Healthcheck Monitoring (e.g., healthchecks.io)
HEALTHCHECK_URL=
EOFENV

    # Determine Restic repository based on storage backend
    if [[ "$BACKUP_STORAGE" == "s3" ]]; then
        RESTIC_REPO="s3:s3.${S3_REGION}.amazonaws.com/${S3_BUCKET}"
        if [[ -n "$S3_ENDPOINT" ]]; then
            RESTIC_REPO="s3:${S3_ENDPOINT}/${S3_BUCKET}"
        fi
    else
        RESTIC_REPO="./backups/restic"
    fi

    # Compression setting
    RESTIC_COMPRESSION="auto"
    if [[ "$BACKUP_COMPRESSION" == "true" ]]; then
        RESTIC_COMPRESSION="max"
    fi

    RESTIC_VERIFY_FLAG="true"
    if [[ "$BACKUP_VERIFY" == "false" ]]; then
        RESTIC_VERIFY_FLAG="false"
    fi

    # Replace placeholders
    sed -i "s|{{RESTIC_REPOSITORY}}|$RESTIC_REPO|g" "$BACKUP_ENV_FILE"
    sed -i "s/{{BACKUP_ENCRYPTION_KEY}}/$BACKUP_ENCRYPTION_KEY/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{AWS_ACCESS_KEY_ID}}//g" "$BACKUP_ENV_FILE"  # User must fill in
    sed -i "s/{{AWS_SECRET_ACCESS_KEY}}//g" "$BACKUP_ENV_FILE"
    sed -i "s/{{S3_REGION}}/$S3_REGION/g" "$BACKUP_ENV_FILE"
    sed -i "s|{{S3_ENDPOINT}}|$S3_ENDPOINT|g" "$BACKUP_ENV_FILE"
    sed -i "s/{{RESTIC_COMPRESSION}}/$RESTIC_COMPRESSION/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{RESTIC_VERIFY}}/$RESTIC_VERIFY_FLAG/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{DB_TYPE}}/$DB_TYPE/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{DB_HOST}}/$DB_HOST/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{DB_PORT}}/$DB_PORT/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{DB_USER}}/$DB_USER/g" "$BACKUP_ENV_FILE"
    sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" "$BACKUP_ENV_FILE"

    # Restrict permissions on sensitive file
    chmod 600 "$BACKUP_ENV_FILE"

    verify_file "$BACKUP_ENV_FILE"
    log_file_created "$SCRIPT_NAME" "config/backup/.backup.env"
    CREATED_FILES+=("config/backup/.backup.env")
fi

# ===================================================================
# Create Database Backup Script
# ===================================================================

log_info "Creating database backup script..."

DB_BACKUP_SCRIPT="$PROJECT_ROOT/scripts/backup-database.sh"

if file_exists "$DB_BACKUP_SCRIPT"; then
    backup_file "$DB_BACKUP_SCRIPT"
    SKIPPED_FILES+=("scripts/backup-database.sh (backed up)")
    log_warning "backup-database.sh already exists, backed up"
else
    cat > "$DB_BACKUP_SCRIPT" << 'EOFDBBACKUP'
#!/bin/bash

# ===================================================================
# Database Backup Script
# Auto-generated by bootstrap-backup-service.sh
# ===================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="./backups/database"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_TYPE="{{DB_TYPE}}"

# Source environment
if [[ -f "./config/backup/.backup.env" ]]; then
    source "./config/backup/.backup.env"
fi

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# ===================================================================
# Backup Functions
# ===================================================================

backup_postgres() {
    local backup_file="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

    echo "Backing up PostgreSQL database: $DB_NAME"

    export PGPASSWORD="$DB_PASSWORD"

    if pg_dump \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -F c \
        -b \
        -v \
        "$DB_NAME" > "$backup_file"; then

        echo "✓ Backup completed: $backup_file"

        # Compress
        if gzip "$backup_file"; then
            echo "✓ Compressed: ${backup_file}.gz"
        fi

        return 0
    else
        echo "✗ Backup failed"
        return 1
    fi
}

backup_mysql() {
    local backup_file="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

    echo "Backing up MySQL database: $DB_NAME"

    if mysqldump \
        -h "$DB_HOST" \
        -P "$DB_PORT" \
        -u "$DB_USER" \
        -p"$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        "$DB_NAME" > "$backup_file"; then

        echo "✓ Backup completed: $backup_file"

        # Compress
        if gzip "$backup_file"; then
            echo "✓ Compressed: ${backup_file}.gz"
        fi

        return 0
    else
        echo "✗ Backup failed"
        return 1
    fi
}

backup_docker_postgres() {
    local backup_file="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"
    local container_name="{{PROJECT_NAME}}-postgres"

    echo "Backing up PostgreSQL from Docker container: $container_name"

    if docker exec "$container_name" pg_dump \
        -U "$DB_USER" \
        -F c \
        -b \
        "$DB_NAME" > "$backup_file"; then

        echo "✓ Backup completed: $backup_file"

        # Compress
        if gzip "$backup_file"; then
            echo "✓ Compressed: ${backup_file}.gz"
        fi

        return 0
    else
        echo "✗ Backup failed"
        return 1
    fi
}

cleanup_old_backups() {
    local retention_days="${BACKUP_RETENTION_DAYS:-30}"

    echo "Cleaning up backups older than $retention_days days..."

    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$retention_days" -delete 2>/dev/null || true

    echo "✓ Cleanup complete"
}

# ===================================================================
# Main
# ===================================================================

echo "========================================"
echo "Database Backup Starting"
echo "Type: $DB_TYPE"
echo "Database: $DB_NAME"
echo "========================================"

# Check if running in Docker environment
if command -v docker &>/dev/null && docker ps --filter "name={{PROJECT_NAME}}-postgres" --format "{{.Names}}" | grep -q "postgres"; then
    backup_docker_postgres
elif [[ "$DB_TYPE" == "postgres" ]] && command -v pg_dump &>/dev/null; then
    backup_postgres
elif [[ "$DB_TYPE" == "mysql" ]] && command -v mysqldump &>/dev/null; then
    backup_mysql
else
    echo "✗ Database backup tool not available for: $DB_TYPE"
    exit 1
fi

cleanup_old_backups

echo "========================================"
echo "Database Backup Completed"
echo "Location: $BACKUP_DIR"
echo "========================================"

exit 0
EOFDBBACKUP

    # Replace placeholders
    sed -i "s/{{DB_TYPE}}/$DB_TYPE/g" "$DB_BACKUP_SCRIPT"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$DB_BACKUP_SCRIPT"

    chmod +x "$DB_BACKUP_SCRIPT"

    verify_file "$DB_BACKUP_SCRIPT"
    log_file_created "$SCRIPT_NAME" "scripts/backup-database.sh"
    CREATED_FILES+=("scripts/backup-database.sh")
fi

# ===================================================================
# Create Database Restore Script
# ===================================================================

log_info "Creating database restore script..."

DB_RESTORE_SCRIPT="$PROJECT_ROOT/scripts/restore-database.sh"

if file_exists "$DB_RESTORE_SCRIPT"; then
    backup_file "$DB_RESTORE_SCRIPT"
    SKIPPED_FILES+=("scripts/restore-database.sh (backed up)")
    log_warning "restore-database.sh already exists, backed up"
else
    cat > "$DB_RESTORE_SCRIPT" << 'EOFDBRESTORE'
#!/bin/bash

# ===================================================================
# Database Restore Script
# Auto-generated by bootstrap-backup-service.sh
# ===================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="./backups/database"
DB_TYPE="{{DB_TYPE}}"

# Source environment
if [[ -f "./config/backup/.backup.env" ]]; then
    source "./config/backup/.backup.env"
fi

# ===================================================================
# Restore Functions
# ===================================================================

list_backups() {
    echo "Available backups:"
    echo ""
    ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No backups found"
    echo ""
}

restore_postgres() {
    local backup_file="$1"

    echo "Restoring PostgreSQL database from: $backup_file"
    echo "⚠️  This will OVERWRITE the current database: $DB_NAME"
    echo ""
    read -p "Continue? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Restore cancelled"
        exit 0
    fi

    export PGPASSWORD="$DB_PASSWORD"

    # Decompress if needed
    local restore_file="$backup_file"
    if [[ "$backup_file" == *.gz ]]; then
        echo "Decompressing backup..."
        gunzip -c "$backup_file" > "${backup_file%.gz}"
        restore_file="${backup_file%.gz}"
    fi

    # Drop existing database (optional)
    echo "Dropping existing database..."
    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" 2>/dev/null || true

    # Create new database
    echo "Creating database..."
    createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"

    # Restore
    echo "Restoring backup..."
    if pg_restore \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -v \
        "$restore_file"; then

        echo "✓ Restore completed"

        # Cleanup decompressed file
        if [[ "$backup_file" == *.gz ]]; then
            rm -f "$restore_file"
        fi

        return 0
    else
        echo "✗ Restore failed"
        return 1
    fi
}

restore_mysql() {
    local backup_file="$1"

    echo "Restoring MySQL database from: $backup_file"
    echo "⚠️  This will OVERWRITE the current database: $DB_NAME"
    echo ""
    read -p "Continue? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Restore cancelled"
        exit 0
    fi

    # Decompress if needed
    local restore_file="$backup_file"
    if [[ "$backup_file" == *.gz ]]; then
        echo "Decompressing backup..."
        gunzip -c "$backup_file" > "${backup_file%.gz}"
        restore_file="${backup_file%.gz}"
    fi

    # Restore
    echo "Restoring backup..."
    if mysql \
        -h "$DB_HOST" \
        -P "$DB_PORT" \
        -u "$DB_USER" \
        -p"$DB_PASSWORD" \
        "$DB_NAME" < "$restore_file"; then

        echo "✓ Restore completed"

        # Cleanup decompressed file
        if [[ "$backup_file" == *.gz ]]; then
            rm -f "$restore_file"
        fi

        return 0
    else
        echo "✗ Restore failed"
        return 1
    fi
}

# ===================================================================
# Main
# ===================================================================

echo "========================================"
echo "Database Restore"
echo "Type: $DB_TYPE"
echo "Database: $DB_NAME"
echo "========================================"
echo ""

if [[ $# -eq 0 ]]; then
    list_backups
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 ./backups/database/${DB_NAME}_20250101_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "✗ Backup file not found: $BACKUP_FILE"
    exit 1
fi

if [[ "$DB_TYPE" == "postgres" ]]; then
    restore_postgres "$BACKUP_FILE"
elif [[ "$DB_TYPE" == "mysql" ]]; then
    restore_mysql "$BACKUP_FILE"
else
    echo "✗ Unsupported database type: $DB_TYPE"
    exit 1
fi

echo "========================================"
echo "Database Restore Completed"
echo "========================================"

exit 0
EOFDBRESTORE

    # Replace placeholders
    sed -i "s/{{DB_TYPE}}/$DB_TYPE/g" "$DB_RESTORE_SCRIPT"

    chmod +x "$DB_RESTORE_SCRIPT"

    verify_file "$DB_RESTORE_SCRIPT"
    log_file_created "$SCRIPT_NAME" "scripts/restore-database.sh"
    CREATED_FILES+=("scripts/restore-database.sh")
fi

# ===================================================================
# Create Backup Verification Script
# ===================================================================

log_info "Creating backup verification script..."

VERIFY_SCRIPT="$PROJECT_ROOT/scripts/verify-backup.sh"

if file_exists "$VERIFY_SCRIPT"; then
    backup_file "$VERIFY_SCRIPT"
    SKIPPED_FILES+=("scripts/verify-backup.sh (backed up)")
    log_warning "verify-backup.sh already exists, backed up"
else
    cat > "$VERIFY_SCRIPT" << 'EOFVERIFY'
#!/bin/bash

# ===================================================================
# Backup Verification Script
# Auto-generated by bootstrap-backup-service.sh
# ===================================================================

set -euo pipefail

# Source environment
if [[ -f "./config/backup/.backup.env" ]]; then
    source "./config/backup/.backup.env"
fi

# ===================================================================
# Verification Functions
# ===================================================================

verify_restic_backup() {
    echo "Verifying Restic backup integrity..."

    if ! command -v restic &>/dev/null; then
        echo "✗ restic not installed"
        return 1
    fi

    # Check repository integrity
    echo "Checking repository..."
    restic check --read-data-subset=10%

    # List recent snapshots
    echo ""
    echo "Recent snapshots:"
    restic snapshots --last 5

    # Get latest snapshot stats
    echo ""
    echo "Latest snapshot statistics:"
    restic stats latest

    echo ""
    echo "✓ Restic backup verification completed"
}

verify_database_backup() {
    local backup_dir="./backups/database"

    echo "Verifying database backups..."

    if [[ ! -d "$backup_dir" ]]; then
        echo "✗ Backup directory not found: $backup_dir"
        return 1
    fi

    # Check for recent backups
    local latest_backup=$(find "$backup_dir" -name "*.sql.gz" -type f -mtime -2 | head -1)

    if [[ -z "$latest_backup" ]]; then
        echo "⚠️  No backups found in last 48 hours"
        return 1
    fi

    echo "✓ Latest database backup: $latest_backup"
    echo "  Size: $(du -h "$latest_backup" | cut -f1)"
    echo "  Modified: $(stat -c %y "$latest_backup" 2>/dev/null || stat -f %Sm "$latest_backup")"

    # Verify archive integrity
    if gzip -t "$latest_backup" 2>/dev/null; then
        echo "✓ Backup archive integrity verified"
    else
        echo "✗ Backup archive corrupted"
        return 1
    fi

    echo ""
    echo "✓ Database backup verification completed"
}

check_backup_age() {
    local max_age_hours="${BACKUP_MAX_AGE_HOURS:-48}"
    local backup_dir="./backups/database"

    echo "Checking backup freshness (max age: ${max_age_hours}h)..."

    local latest_backup=$(find "$backup_dir" -name "*.sql.gz" -type f -mtime -2 | head -1)

    if [[ -z "$latest_backup" ]]; then
        echo "✗ ALERT: No recent backups found!"
        return 1
    fi

    local backup_age=$(( ($(date +%s) - $(stat -c %Y "$latest_backup" 2>/dev/null || stat -f %m "$latest_backup")) / 3600 ))

    if [[ $backup_age -gt $max_age_hours ]]; then
        echo "✗ ALERT: Latest backup is ${backup_age}h old (max: ${max_age_hours}h)"
        return 1
    else
        echo "✓ Latest backup is ${backup_age}h old (within threshold)"
    fi
}

# ===================================================================
# Main
# ===================================================================

echo "========================================"
echo "Backup Verification"
echo "========================================"
echo ""

EXIT_CODE=0

verify_database_backup || EXIT_CODE=1
echo ""

check_backup_age || EXIT_CODE=1
echo ""

if command -v restic &>/dev/null && [[ -n "${RESTIC_REPOSITORY:-}" ]]; then
    verify_restic_backup || EXIT_CODE=1
    echo ""
fi

echo "========================================"
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✓ All Verifications Passed"
else
    echo "✗ Some Verifications Failed"
fi
echo "========================================"

exit $EXIT_CODE
EOFVERIFY

    chmod +x "$VERIFY_SCRIPT"

    verify_file "$VERIFY_SCRIPT"
    log_file_created "$SCRIPT_NAME" "scripts/verify-backup.sh"
    CREATED_FILES+=("scripts/verify-backup.sh")
fi

# ===================================================================
# Create Restore Procedure Documentation
# ===================================================================

log_info "Creating restore procedure documentation..."

RESTORE_DOC="$PROJECT_ROOT/config/backup/restore-procedure.md"

if file_exists "$RESTORE_DOC"; then
    backup_file "$RESTORE_DOC"
    SKIPPED_FILES+=("config/backup/restore-procedure.md (backed up)")
    log_warning "restore-procedure.md already exists, backed up"
else
    cat > "$RESTORE_DOC" << 'EOFDOC'
# Disaster Recovery & Restore Procedure

**Project:** {{PROJECT_NAME}}
**Provider:** {{BACKUP_PROVIDER}}
**Storage:** {{BACKUP_STORAGE}}
**Generated:** {{GENERATED_DATE}}

---

## Table of Contents

1. [Overview](#overview)
2. [Backup Schedule](#backup-schedule)
3. [Quick Restore](#quick-restore)
4. [Full Disaster Recovery](#full-disaster-recovery)
5. [Point-in-Time Recovery](#point-in-time-recovery)
6. [Verification Procedures](#verification-procedures)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This project uses **{{BACKUP_PROVIDER}}** for automated backups with the following configuration:

- **Backup Schedule:** `{{BACKUP_SCHEDULE}}`
- **Retention:** {{BACKUP_RETENTION_DAYS}} days
- **Storage Backend:** {{BACKUP_STORAGE}}
- **Encryption:** Enabled (AES-256)
- **Compression:** {{BACKUP_COMPRESSION}}
- **Verification:** {{BACKUP_VERIFY}}

### Backup Sources

- **Database:** {{DB_TYPE}} (`{{DB_NAME}}`)
- **Application Files:** Uploads, configuration
- **Docker Volumes:** (if applicable)

---

## Backup Schedule

### Automated Backups

| Type | Schedule | Retention |
|------|----------|-----------|
| Incremental | Daily at 2 AM | 7 days |
| Full | Weekly (Sunday) | 4 weeks |
| Monthly | 1st of month | 12 months |

### Manual Backups

Run manual backup anytime:

```bash
bash config/backup/restic-backup.sh
```

---

## Quick Restore

### Database Only

1. **List available backups:**

```bash
bash scripts/restore-database.sh
```

2. **Restore specific backup:**

```bash
bash scripts/restore-database.sh ./backups/database/{{DB_NAME}}_YYYYMMDD_HHMMSS.sql.gz
```

3. **Verify restore:**

```bash
# Check database connectivity
docker-compose exec postgres psql -U {{DB_USER}} -d {{DB_NAME}} -c '\dt'
```

---

## Full Disaster Recovery

### Prerequisites

- Access to backup storage (S3 credentials, encryption key)
- Restic installed: `https://restic.net/`
- Docker and Docker Compose installed

### Step 1: Restore Environment Variables

```bash
# Copy backup environment template
cp config/backup/.backup.env.example config/backup/.backup.env

# Edit with production credentials
nano config/backup/.backup.env
```

Required variables:
- `RESTIC_REPOSITORY`
- `RESTIC_PASSWORD`
- `AWS_ACCESS_KEY_ID` (if using S3)
- `AWS_SECRET_ACCESS_KEY` (if using S3)

### Step 2: Initialize Restic Repository

```bash
# Source environment
source config/backup/.backup.env

# Check repository connectivity
restic snapshots
```

### Step 3: List Available Snapshots

```bash
# Show all snapshots
restic snapshots

# Show snapshots with specific tag
restic snapshots --tag {{PROJECT_NAME}}

# Show latest snapshot
restic snapshots --last 1
```

### Step 4: Restore Files

```bash
# Restore latest snapshot to current directory
restic restore latest --target ./restore

# Restore specific snapshot
restic restore abc123def --target ./restore

# Restore specific files only
restic restore latest --target ./restore --include ./backups/database
```

### Step 5: Restore Database

```bash
# Find latest database backup
ls -lh restore/backups/database/

# Restore database
bash scripts/restore-database.sh restore/backups/database/{{DB_NAME}}_YYYYMMDD_HHMMSS.sql.gz
```

### Step 6: Restore Application Files

```bash
# Copy uploads
cp -r restore/uploads ./

# Copy configuration
cp -r restore/config ./
```

### Step 7: Restart Services

```bash
# Restart Docker services
docker-compose down
docker-compose up -d

# Verify health
docker-compose ps
docker-compose logs -f
```

### Step 8: Verify Restoration

```bash
# Run verification script
bash scripts/verify-backup.sh

# Test application endpoints
curl http://localhost:3000/health
```

---

## Point-in-Time Recovery

Restore to a specific date/time:

### 1. Find Snapshot at Specific Time

```bash
# List snapshots near target time
restic snapshots --compact

# Example: Restore to December 1, 2025 at 10:00 AM
restic snapshots --compact | grep "2025-12-01 10:"
```

### 2. Restore Specific Snapshot

```bash
# Restore by snapshot ID
restic restore <snapshot-id> --target ./restore-pit

# Restore database from that point
bash scripts/restore-database.sh ./restore-pit/backups/database/*.sql.gz
```

---

## Verification Procedures

### Daily Verification

Run automated verification:

```bash
bash scripts/verify-backup.sh
```

This checks:
- Backup file integrity
- Backup age (alert if > 48 hours old)
- Archive compression integrity
- Restic repository health

### Manual Verification

```bash
# Check Restic repository
restic check --read-data-subset=10%

# Verify latest database backup
gunzip -t backups/database/*.sql.gz

# Test restore to temporary location
restic restore latest --target ./test-restore
```

### Monitoring

Set up external monitoring:

1. **Healthchecks.io**: Add URL to `.backup.env`:
   ```bash
   HEALTHCHECK_URL=https://hc-ping.com/your-uuid
   ```

2. **Cron job**: Add to crontab:
   ```bash
   0 2 * * * cd /path/to/project && bash config/backup/restic-backup.sh
   ```

---

## Troubleshooting

### Backup Fails: "Repository not initialized"

```bash
source config/backup/.backup.env
restic init
```

### Backup Fails: "Access Denied" (S3)

Check AWS credentials:

```bash
aws s3 ls s3://{{S3_BUCKET}}/
```

Verify credentials in `.backup.env`:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Restore Fails: "Database already exists"

```bash
# Drop existing database first
docker-compose exec postgres psql -U postgres -c "DROP DATABASE {{DB_NAME}};"

# Or use restore script which handles this automatically
bash scripts/restore-database.sh <backup-file>
```

### Backup Taking Too Long

```bash
# Check what's being backed up
restic backup --dry-run --verbose ./

# Exclude large temporary files
restic backup --exclude="node_modules" --exclude="*.log" ./
```

### Cannot Decrypt Backup

Ensure `RESTIC_PASSWORD` in `.backup.env` matches the password used during repository initialization.

If password is lost, **backups are unrecoverable**. Always store encryption key securely:

- Password manager (1Password, LastPass)
- Encrypted vault (HashiCorp Vault)
- Offline secure location

---

## Emergency Contacts

- **Project Owner:** {{PROJECT_OWNER}} ({{PROJECT_OWNER_EMAIL}})
- **Backup Storage:** {{BACKUP_STORAGE}} ({{S3_BUCKET}})
- **Documentation:** This file (`config/backup/restore-procedure.md`)

---

## Appendix: Restic Command Reference

```bash
# Initialize repository
restic init

# Create backup
restic backup ./path/to/backup

# List snapshots
restic snapshots

# Restore latest
restic restore latest --target ./restore

# Restore specific snapshot
restic restore <snapshot-id> --target ./restore

# Check repository integrity
restic check

# Prune old snapshots
restic forget --keep-daily 7 --keep-weekly 4 --prune

# Show snapshot statistics
restic stats latest

# Mount snapshots (browse as filesystem)
restic mount ./mnt
```

---

**Last Updated:** {{GENERATED_DATE}}
**Auto-generated by:** bootstrap-backup-service.sh
EOFDOC

    # Replace placeholders
    GENERATED_DATE=$(date +"%Y-%m-%d %H:%M:%S")
    PROJECT_OWNER=$(config_get "project.owner" "Project Owner")
    PROJECT_OWNER_EMAIL=$(config_get "project.owner_email" "owner@example.com")

    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$RESTORE_DOC"
    sed -i "s/{{BACKUP_PROVIDER}}/$BACKUP_PROVIDER/g" "$RESTORE_DOC"
    sed -i "s/{{BACKUP_STORAGE}}/$BACKUP_STORAGE/g" "$RESTORE_DOC"
    sed -i "s/{{BACKUP_SCHEDULE}}/$BACKUP_SCHEDULE/g" "$RESTORE_DOC"
    sed -i "s/{{BACKUP_RETENTION_DAYS}}/$BACKUP_RETENTION_DAYS/g" "$RESTORE_DOC"
    sed -i "s/{{BACKUP_COMPRESSION}}/$BACKUP_COMPRESSION/g" "$RESTORE_DOC"
    sed -i "s/{{BACKUP_VERIFY}}/$BACKUP_VERIFY/g" "$RESTORE_DOC"
    sed -i "s/{{DB_TYPE}}/$DB_TYPE/g" "$RESTORE_DOC"
    sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$RESTORE_DOC"
    sed -i "s/{{DB_USER}}/$DB_USER/g" "$RESTORE_DOC"
    sed -i "s/{{S3_BUCKET}}/$S3_BUCKET/g" "$RESTORE_DOC"
    sed -i "s/{{GENERATED_DATE}}/$GENERATED_DATE/g" "$RESTORE_DOC"
    sed -i "s/{{PROJECT_OWNER}}/$PROJECT_OWNER/g" "$RESTORE_DOC"
    sed -i "s/{{PROJECT_OWNER_EMAIL}}/$PROJECT_OWNER_EMAIL/g" "$RESTORE_DOC"

    verify_file "$RESTORE_DOC"
    log_file_created "$SCRIPT_NAME" "config/backup/restore-procedure.md"
    CREATED_FILES+=("config/backup/restore-procedure.md")
fi

# ===================================================================
# Display Created Files
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#CREATED_FILES[@]} files created"

echo ""
log_section "Backup Service Bootstrap Complete"

echo -e "${GREEN}✓ Created Files:${NC}"
for file in "${CREATED_FILES[@]}"; do
    echo "  • $file"
done

if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠ Skipped Files (already existed):${NC}"
    for file in "${SKIPPED_FILES[@]}"; do
        echo "  • $file"
    done
fi

# ===================================================================
# Summary
# ===================================================================

echo ""
echo -e "${BLUE}Backup Configuration:${NC}"
echo "  Provider: $BACKUP_PROVIDER"
echo "  Storage: $BACKUP_STORAGE"
echo "  Schedule: $BACKUP_SCHEDULE"
echo "  Retention: $BACKUP_RETENTION_DAYS days"
echo "  Encryption: Enabled"
echo ""

echo -e "${BLUE}Quick Start:${NC}"
echo "  1. Configure backup credentials:"
echo "     nano config/backup/.backup.env"
echo ""
echo "  2. Initialize Restic repository:"
echo "     source config/backup/.backup.env && restic init"
echo ""
echo "  3. Run manual backup:"
echo "     bash config/backup/restic-backup.sh"
echo ""
echo "  4. Verify backups:"
echo "     bash scripts/verify-backup.sh"
echo ""
echo "  5. Set up automated backups (cron):"
echo "     crontab -e"
echo "     $BACKUP_SCHEDULE cd $(pwd) && bash config/backup/restic-backup.sh"
echo ""

echo -e "${BLUE}Disaster Recovery:${NC}"
echo "  • Full procedure: config/backup/restore-procedure.md"
echo "  • Database restore: bash scripts/restore-database.sh"
echo "  • Backup verification: bash scripts/verify-backup.sh"
echo ""

echo -e "${YELLOW}Security Reminder:${NC}"
echo "  • SAVE encryption key securely: config/backup/.backup.env"
echo "  • Never commit .backup.env to git"
echo "  • Add AWS credentials if using S3 storage"
echo "  • Test restore procedure regularly"
if [[ "$PROJECT_PHASE" == "Tier 3" ]] || [[ "$PROJECT_PHASE" == "production" ]]; then
    echo "  • PRODUCTION MODE: Off-site backups required"
    echo "  • Set up monitoring alerts for backup failures"
fi
echo ""

echo -e "${BLUE}Files Created:${NC}"
echo "  Backup: ${#CREATED_FILES[@]} files"
echo "  Location: $PROJECT_ROOT"
echo ""

show_log_location
