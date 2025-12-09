#!/bin/bash
# =============================================================================
# @script         bootstrap-mysql
# @version        1.0.0
# @phase          3
# @category       database
# @priority       50
# @short          MySQL database setup with Docker
# @description    Sets up MySQL database with Docker Compose orchestration,
#                 initialization scripts, seed data, and automated backup
#                 scripts with retention policies.
#
# @creates        database/mysql/init.sql
# @creates        database/mysql/backup.sh
# @creates        database/backups/
# @creates        .env.mysql
# @creates        docker-compose.mysql.yml
#
# @detects        has_mysql_config
# @questions      mysql
# @defaults       mysql.enabled=true, mysql.version=8.0, mysql.port=3306
# @detects        has_mysql_config
# @questions      mysql
# @defaults       mysql.backup_enabled=true
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  mysql
# @env_vars        BACKUP_DIR,BACKUP_ENABLED,BACKUP_FILE,BACKUP_SCRIPT,BLUE,CREATED_FILES,DB_HOST,DB_NAME,DB_PASSWORD,DB_PORT,DB_USER,DOCKER_COMPOSE_FILE,ENABLED,ENV_FILE,FILES_TO_CREATE,GREEN,INIT_FILE,MYSQL_ROOT_PASSWORD,MYSQL_VERSION,NC,POOL_SIZE,SKIPPED_FILES,TIMESTAMP,YELLOW
# @interactive     no
# @platforms       all
# @conflicts       postgres
# @rollback        rm -rf database/mysql/init.sql database/mysql/backup.sh database/backups/ .env.mysql docker-compose.mysql.yml
# @verify          test -f database/mysql/init.sql
# @docs            https://dev.mysql.com/doc/
# =============================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-mysql"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-mysql"

# Track created files for display
declare -a CREATED_FILES=()
declare -a SKIPPED_FILES=()

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "mysql.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "MySQL bootstrap disabled in config"
    exit 0
fi

# Read MySQL-specific settings
MYSQL_VERSION=$(config_get "mysql.version" "8.0")
DB_HOST=$(config_get "mysql.host" "localhost")
DB_PORT=$(config_get "mysql.port" "3306")
DB_NAME=$(config_get "mysql.db_name" "app_db")
DB_USER=$(config_get "mysql.db_user" "app_user")
DB_PASSWORD=$(config_get "mysql.db_password" "app_password")
MYSQL_ROOT_PASSWORD=$(config_get "mysql.root_password" "root")
POOL_SIZE=$(config_get "mysql.pool_size" "10")
BACKUP_ENABLED=$(config_get "mysql.backup_enabled" "true")
BACKUP_RETENTION=$(config_get "mysql.backup_retention_days" "7")

# Get project name for Docker
PROJECT_NAME=$(config_get "project.name" "app")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

FILES_TO_CREATE=(
    "database/mysql/"
    "database/mysql/init.sql"
    "database/mysql/backup.sh"
    ".env.mysql"
    "docker-compose.mysql.yml"
)

pre_execution_confirm "$SCRIPT_NAME" "MySQL Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Create Database Directory Structure
# ===================================================================

log_info "Creating MySQL directory structure..."

if ! dir_exists "$PROJECT_ROOT/database/mysql"; then
    ensure_dir "$PROJECT_ROOT/database/mysql"
    log_dir_created "$SCRIPT_NAME" "database/mysql/"
fi

if ! dir_exists "$PROJECT_ROOT/database/backups"; then
    ensure_dir "$PROJECT_ROOT/database/backups"
    log_dir_created "$SCRIPT_NAME" "database/backups/"
fi

log_success "Directory structure created"

# ===================================================================
# Create Initialization Script
# ===================================================================

log_info "Creating MySQL initialization script..."

INIT_FILE="$PROJECT_ROOT/database/mysql/init.sql"

if file_exists "$INIT_FILE"; then
    backup_file "$INIT_FILE"
    SKIPPED_FILES+=("database/mysql/init.sql (backed up)")
    log_warning "init.sql already exists, backed up"
else
    cat > "$INIT_FILE" << 'EOFINIT'
-- ===================================================================
-- MySQL Database Initialization
-- Auto-generated by bootstrap-mysql.sh
-- ===================================================================

-- Set character set and collation
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS {{DB_NAME}}
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Use the database
USE {{DB_NAME}};

-- ===================================================================
-- User Management
-- ===================================================================

-- Create application user if not exists
CREATE USER IF NOT EXISTS '{{DB_USER}}'@'%' IDENTIFIED BY '{{DB_PASSWORD}}';

-- Grant privileges
GRANT ALL PRIVILEGES ON {{DB_NAME}}.* TO '{{DB_USER}}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON {{DB_NAME}}.* TO '{{DB_USER}}'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- ===================================================================
-- Example Tables (customize as needed)
-- ===================================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================================
-- Verification
-- ===================================================================

-- Show created tables
SHOW TABLES;

-- Verify character set
SELECT default_character_set_name, default_collation_name
FROM information_schema.schemata
WHERE schema_name = '{{DB_NAME}}';
EOFINIT

    # Replace placeholders
    sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$INIT_FILE"
    sed -i "s/{{DB_USER}}/$DB_USER/g" "$INIT_FILE"
    sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" "$INIT_FILE"

    verify_file "$INIT_FILE"
    log_file_created "$SCRIPT_NAME" "database/mysql/init.sql"
    CREATED_FILES+=("database/mysql/init.sql")
fi

# ===================================================================
# Create Backup Script
# ===================================================================

if [[ "$BACKUP_ENABLED" == "true" ]]; then
    log_info "Creating MySQL backup script..."

    BACKUP_SCRIPT="$PROJECT_ROOT/database/mysql/backup.sh"

    if file_exists "$BACKUP_SCRIPT"; then
        backup_file "$BACKUP_SCRIPT"
        SKIPPED_FILES+=("database/mysql/backup.sh (backed up)")
        log_warning "backup.sh already exists, backed up"
    else
        cat > "$BACKUP_SCRIPT" << 'EOFBACKUP'
#!/bin/bash

# ===================================================================
# MySQL Backup Script
# Auto-generated by bootstrap-mysql.sh
# ===================================================================

set -euo pipefail

# Configuration
DB_NAME="{{DB_NAME}}"
DB_USER="{{DB_USER}}"
DB_PASSWORD="{{DB_PASSWORD}}"
DB_HOST="{{DB_HOST}}"
DB_PORT="{{DB_PORT}}"

BACKUP_DIR="./database/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

# ===================================================================
# Backup Functions
# ===================================================================

backup_database() {
    local backup_path="$1"

    echo "Starting backup of $DB_NAME..."

    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    # Run mysqldump
    if mysqldump \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --user="$DB_USER" \
        --password="$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        "$DB_NAME" > "$backup_path"; then
        echo "✓ Backup completed: $backup_path"

        # Compress
        if gzip "$backup_path"; then
            echo "✓ Compressed: ${backup_path}.gz"
            BACKUP_FILE="${backup_path}.gz"
        fi
        return 0
    else
        echo "✗ Backup failed"
        return 1
    fi
}

cleanup_old_backups() {
    echo "Cleaning up old backups (keeping last 7 days)..."
    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +7 -delete 2>/dev/null || true
    echo "✓ Cleanup complete"
}

# ===================================================================
# Main
# ===================================================================

if backup_database "$BACKUP_FILE"; then
    cleanup_old_backups
    echo ""
    echo "Database backup successful!"
    echo "Location: ${BACKUP_FILE}.gz"
    ls -lh "${BACKUP_FILE}.gz"
else
    echo "✗ Backup failed"
    exit 1
fi
EOFBACKUP

        # Replace placeholders
        sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_USER}}/$DB_USER/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_HOST}}/$DB_HOST/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_PORT}}/$DB_PORT/g" "$BACKUP_SCRIPT"

        chmod +x "$BACKUP_SCRIPT"

        verify_file "$BACKUP_SCRIPT"
        log_file_created "$SCRIPT_NAME" "database/mysql/backup.sh"
        CREATED_FILES+=("database/mysql/backup.sh")
    fi
fi

# ===================================================================
# Create Environment File
# ===================================================================

log_info "Creating MySQL environment configuration..."

ENV_FILE="$PROJECT_ROOT/.env.mysql"

if file_exists "$ENV_FILE"; then
    backup_file "$ENV_FILE"
    SKIPPED_FILES+=(".env.mysql (backed up)")
    log_warning ".env.mysql already exists, backed up"
else
    cat > "$ENV_FILE" << 'EOFENV'
# ===================================================================
# MySQL Environment Configuration
# Auto-generated by bootstrap-mysql.sh
# ===================================================================

# Database Connection
DATABASE_URL=mysql://{{DB_USER}}:{{DB_PASSWORD}}@{{DB_HOST}}:{{DB_PORT}}/{{DB_NAME}}?charset=utf8mb4
DATABASE_HOST={{DB_HOST}}
DATABASE_PORT={{DB_PORT}}
DATABASE_NAME={{DB_NAME}}
DATABASE_USER={{DB_USER}}
DATABASE_PASSWORD={{DB_PASSWORD}}

# Connection Pool
DATABASE_POOL_SIZE=10
DATABASE_IDLE_TIMEOUT=30000
DATABASE_CONNECTION_TIMEOUT=2000

# SSL Settings (enable for production)
DATABASE_SSL=false
# DATABASE_SSL_REJECT_UNAUTHORIZED=false

# Logging
DATABASE_LOG_QUERIES=false
DATABASE_DEBUG=false

# Backup
BACKUP_SCHEDULE=daily
BACKUP_RETENTION_DAYS=7

# MySQL Specific
MYSQL_ROOT_PASSWORD={{MYSQL_ROOT_PASSWORD}}
MYSQL_CHARSET=utf8mb4
MYSQL_COLLATION=utf8mb4_unicode_ci
EOFENV

    # Replace placeholders
    sed -i "s/{{DB_USER}}/$DB_USER/g" "$ENV_FILE"
    sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" "$ENV_FILE"
    sed -i "s/{{DB_HOST}}/$DB_HOST/g" "$ENV_FILE"
    sed -i "s/{{DB_PORT}}/$DB_PORT/g" "$ENV_FILE"
    sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$ENV_FILE"
    sed -i "s/{{MYSQL_ROOT_PASSWORD}}/$MYSQL_ROOT_PASSWORD/g" "$ENV_FILE"

    verify_file "$ENV_FILE"
    log_file_created "$SCRIPT_NAME" ".env.mysql"
    CREATED_FILES+=(".env.mysql")
fi

# ===================================================================
# Create Docker Compose Configuration
# ===================================================================

log_info "Creating Docker Compose configuration..."

DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.mysql.yml"

if file_exists "$DOCKER_COMPOSE_FILE"; then
    backup_file "$DOCKER_COMPOSE_FILE"
    SKIPPED_FILES+=("docker-compose.mysql.yml (backed up)")
    log_warning "docker-compose.mysql.yml already exists, backed up"
else
    cat > "$DOCKER_COMPOSE_FILE" << 'EOFDOCKER'
version: '3.8'

services:
  mysql:
    image: mysql:{{MYSQL_VERSION}}
    container_name: {{PROJECT_NAME}}-mysql
    environment:
      MYSQL_ROOT_PASSWORD: {{MYSQL_ROOT_PASSWORD}}
      MYSQL_DATABASE: {{DB_NAME}}
      MYSQL_USER: {{DB_USER}}
      MYSQL_PASSWORD: {{DB_PASSWORD}}
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --max_connections=1000
      --innodb_buffer_pool_size=256M
    ports:
      - "{{DB_PORT}}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/mysql/init.sql:/docker-entrypoint-initdb.d/01-init.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "{{DB_USER}}", "-p{{DB_PASSWORD}}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - {{PROJECT_NAME}}-net
    restart: unless-stopped

volumes:
  mysql_data:
    driver: local

networks:
  {{PROJECT_NAME}}-net:
    driver: bridge
EOFDOCKER

    # Replace placeholders
    sed -i "s/{{MYSQL_VERSION}}/$MYSQL_VERSION/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{DB_USER}}/$DB_USER/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{MYSQL_ROOT_PASSWORD}}/$MYSQL_ROOT_PASSWORD/g" "$DOCKER_COMPOSE_FILE"
    sed -i "s/{{DB_PORT}}/$DB_PORT/g" "$DOCKER_COMPOSE_FILE"

    verify_file "$DOCKER_COMPOSE_FILE"
    log_file_created "$SCRIPT_NAME" "docker-compose.mysql.yml"
    CREATED_FILES+=("docker-compose.mysql.yml")
fi

# ===================================================================
# Display Created Files
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#CREATED_FILES[@]} files created"

echo ""
log_section "MySQL Bootstrap Complete"

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
echo -e "${BLUE}MySQL Configuration:${NC}"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Pool Size: $POOL_SIZE"
echo ""

echo -e "${BLUE}Quick Start:${NC}"
echo "  1. Start MySQL container:"
echo "     docker-compose -f docker-compose.mysql.yml up -d"
echo ""
echo "  2. Verify connection:"
echo "     docker-compose -f docker-compose.mysql.yml exec mysql mysql -u $DB_USER -p$DB_PASSWORD -D $DB_NAME -e 'SHOW TABLES;'"
echo ""
echo "  3. Run backups:"
echo "     bash database/mysql/backup.sh"
echo ""

echo -e "${BLUE}Files Created:${NC}"
echo "  Database: ${#CREATED_FILES[@]} files"
echo "  Location: $PROJECT_ROOT"
echo ""

echo -e "${YELLOW}Security Reminder:${NC}"
echo "  • Change DB_PASSWORD in .env.mysql (current: $DB_PASSWORD)"
echo "  • Change MYSQL_ROOT_PASSWORD in .env.mysql (current: $MYSQL_ROOT_PASSWORD)"
echo "  • Never commit .env.mysql to git"
echo "  • Use environment variables for production"
echo ""

show_log_location
