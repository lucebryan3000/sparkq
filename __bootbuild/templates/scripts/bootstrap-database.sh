#!/bin/bash

# ===================================================================
# bootstrap-database.sh
#
# Purpose: Database initialization, migration, and management setup
# Creates: Database initialization scripts, seed data, backup scripts
# Config:  [database] section in bootstrap.config
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-database"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-database"

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "database.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Database bootstrap disabled in config"
    exit 0
fi

# Read database-specific settings
DB_TYPE=$(config_get "database.type" "postgresql")
DB_NAME=$(config_get "database.name" "app_db")
DB_USER=$(config_get "database.user" "postgres")
DB_PASSWORD=$(config_get "database.password" "postgres")
DB_HOST=$(config_get "database.host" "localhost")
DB_PORT=$(config_get "database.port" "5432")
AUTO_MIGRATE=$(config_get "database.auto_migrate" "false")
CREATE_SEED_DATA=$(config_get "database.create_seed_data" "true")
BACKUP_ENABLED=$(config_get "database.backup_enabled" "true")
POOL_SIZE=$(config_get "database.pool_size" "10")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

# List all files this script will create
FILES_TO_CREATE=(
    "database/"
    "database/db-init.sql"
    "database/seed-data.sql"
    "database/db-backup.sh"
    "database/migrations/"
    "database/README.md"
)

pre_execution_confirm "$SCRIPT_NAME" "Database Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Detect database type if not specified
if [[ "$DB_TYPE" == "detect" ]]; then
    log_info "Detecting database type..."
    if file_exists "$PROJECT_ROOT/package.json"; then
        if grep -q "pg\|postgres" "$PROJECT_ROOT/package.json" 2>/dev/null; then
            DB_TYPE="postgresql"
        elif grep -q "mysql" "$PROJECT_ROOT/package.json" 2>/dev/null; then
            DB_TYPE="mysql"
        elif grep -q "mongodb\|mongoose" "$PROJECT_ROOT/package.json" 2>/dev/null; then
            DB_TYPE="mongodb"
        else
            DB_TYPE="postgresql"
        fi
        log_info "Detected database type: $DB_TYPE"
    else
        DB_TYPE="postgresql"
        log_info "Defaulting to PostgreSQL"
    fi
fi

log_success "Environment validated"

# ===================================================================
# Database-Specific Functions
# ===================================================================

# Test PostgreSQL connection
test_postgresql_connection() {
    local host="$1"
    local port="$2"
    local user="$3"
    local db="$4"

    if command -v psql &> /dev/null; then
        if PGPASSWORD="$DB_PASSWORD" psql -h "$host" -p "$port" -U "$user" -d "$db" -c '\q' &> /dev/null; then
            return 0
        fi
    fi
    return 1
}

# Test MySQL connection
test_mysql_connection() {
    local host="$1"
    local port="$2"
    local user="$3"
    local db="$4"

    if command -v mysql &> /dev/null; then
        if mysql -h "$host" -P "$port" -u "$user" -p"$DB_PASSWORD" -e "USE $db;" &> /dev/null; then
            return 0
        fi
    fi
    return 1
}

# Test MongoDB connection
test_mongodb_connection() {
    local host="$1"
    local port="$2"

    if command -v mongosh &> /dev/null; then
        if mongosh "mongodb://$host:$port" --eval "db.version()" &> /dev/null; then
            return 0
        fi
    elif command -v mongo &> /dev/null; then
        if mongo "mongodb://$host:$port" --eval "db.version()" &> /dev/null; then
            return 0
        fi
    fi
    return 1
}

# Generate database connection string
generate_connection_string() {
    local db_type="$1"
    local user="$2"
    local password="$3"
    local host="$4"
    local port="$5"
    local db="$6"

    case "$db_type" in
        postgresql)
            echo "postgresql://${user}:${password}@${host}:${port}/${db}"
            ;;
        mysql)
            echo "mysql://${user}:${password}@${host}:${port}/${db}"
            ;;
        mongodb)
            if [[ -n "$user" ]]; then
                echo "mongodb://${user}:${password}@${host}:${port}/${db}?authSource=admin"
            else
                echo "mongodb://${host}:${port}/${db}"
            fi
            ;;
        *)
            echo "unknown://${host}:${port}/${db}"
            ;;
    esac
}

# ===================================================================
# Create Database Directory
# ===================================================================

log_info "Creating database directory structure..."

if ! dir_exists "$PROJECT_ROOT/database"; then
    ensure_dir "$PROJECT_ROOT/database"
    log_dir_created "$SCRIPT_NAME" "database/"
fi

if ! dir_exists "$PROJECT_ROOT/database/migrations"; then
    ensure_dir "$PROJECT_ROOT/database/migrations"
    log_dir_created "$SCRIPT_NAME" "database/migrations/"
fi

log_success "Directory structure created"

# ===================================================================
# Create Database Initialization Script
# ===================================================================

log_info "Creating database initialization script..."

DB_INIT_FILE="$PROJECT_ROOT/database/db-init.sql"

if file_exists "$DB_INIT_FILE"; then
    backup_file "$DB_INIT_FILE"
    track_skipped "database/db-init.sql (backed up)"
    log_warning "db-init.sql already exists, backed up"
else
    case "$DB_TYPE" in
        postgresql)
            cat > "$DB_INIT_FILE" << 'EOFPGSQL'
-- ===================================================================
-- PostgreSQL Database Initialization
-- ===================================================================

-- Create database (run as superuser)
-- CREATE DATABASE {{DB_NAME}};

-- Create user (if doesn't exist)
DO
$$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '{{DB_USER}}'
  ) THEN
    CREATE ROLE {{DB_USER}} WITH LOGIN PASSWORD '{{DB_PASSWORD}}';
  END IF;
END
$$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE {{DB_NAME}} TO {{DB_USER}};

-- Connect to the database
\c {{DB_NAME}}

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schema
CREATE SCHEMA IF NOT EXISTS app;

-- Grant schema permissions
GRANT ALL ON SCHEMA app TO {{DB_USER}};

-- Example table (customize as needed)
CREATE TABLE IF NOT EXISTS app.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES app.users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_users_email ON app.users(email);
CREATE INDEX idx_users_username ON app.users(username);
CREATE INDEX idx_sessions_token ON app.sessions(token);
CREATE INDEX idx_sessions_user_id ON app.sessions(user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION app.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to users table
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON app.users
    FOR EACH ROW EXECUTE FUNCTION app.update_updated_at_column();

EOFPGSQL
            ;;
        mysql)
            cat > "$DB_INIT_FILE" << 'EOFMYSQL'
-- ===================================================================
-- MySQL Database Initialization
-- ===================================================================

-- Create database
CREATE DATABASE IF NOT EXISTS {{DB_NAME}};
USE {{DB_NAME}};

-- Create user (if doesn't exist)
CREATE USER IF NOT EXISTS '{{DB_USER}}'@'%' IDENTIFIED BY '{{DB_PASSWORD}}';
GRANT ALL PRIVILEGES ON {{DB_NAME}}.* TO '{{DB_USER}}'@'%';
FLUSH PRIVILEGES;

-- Example tables (customize as needed)
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

CREATE TABLE IF NOT EXISTS sessions (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

EOFMYSQL
            ;;
        mongodb)
            cat > "$DB_INIT_FILE" << 'EOFMONGO'
// ===================================================================
// MongoDB Database Initialization
// ===================================================================

// Switch to database
use {{DB_NAME}};

// Create collections with validation
db.createCollection("users", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["email", "username", "passwordHash"],
            properties: {
                email: {
                    bsonType: "string",
                    pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
                },
                username: {
                    bsonType: "string",
                    minLength: 3,
                    maxLength: 50
                },
                passwordHash: {
                    bsonType: "string"
                },
                createdAt: {
                    bsonType: "date"
                },
                updatedAt: {
                    bsonType: "date"
                }
            }
        }
    }
});

db.createCollection("sessions", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["userId", "token", "expiresAt"],
            properties: {
                userId: {
                    bsonType: "objectId"
                },
                token: {
                    bsonType: "string"
                },
                expiresAt: {
                    bsonType: "date"
                },
                createdAt: {
                    bsonType: "date"
                }
            }
        }
    }
});

// Create indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ username: 1 }, { unique: true });
db.sessions.createIndex({ token: 1 }, { unique: true });
db.sessions.createIndex({ userId: 1 });
db.sessions.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

EOFMONGO
            ;;
    esac

    # Replace placeholders
    sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$DB_INIT_FILE"
    sed -i "s/{{DB_USER}}/$DB_USER/g" "$DB_INIT_FILE"
    sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" "$DB_INIT_FILE"

    verify_file "$DB_INIT_FILE"
    log_file_created "$SCRIPT_NAME" "database/db-init.sql"
    track_created "database/db-init.sql"
fi

# ===================================================================
# Create Seed Data Script
# ===================================================================

if [[ "$CREATE_SEED_DATA" == "true" ]]; then
    log_info "Creating seed data script..."

    SEED_FILE="$PROJECT_ROOT/database/seed-data.sql"

    if file_exists "$SEED_FILE"; then
        backup_file "$SEED_FILE"
        track_skipped "database/seed-data.sql (backed up)"
        log_warning "seed-data.sql already exists, backed up"
    else
        case "$DB_TYPE" in
            postgresql)
                cat > "$SEED_FILE" << 'EOFSEED'
-- ===================================================================
-- PostgreSQL Seed Data
-- Development and testing sample data
-- ===================================================================

\c {{DB_NAME}}

-- Insert sample users (passwords are hashed "password123")
INSERT INTO app.users (email, username, password_hash) VALUES
    ('admin@example.com', 'admin', '$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2'),
    ('user1@example.com', 'user1', '$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2'),
    ('user2@example.com', 'user2', '$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2')
ON CONFLICT (email) DO NOTHING;

EOFSEED
                ;;
            mysql)
                cat > "$SEED_FILE" << 'EOFSEED'
-- ===================================================================
-- MySQL Seed Data
-- Development and testing sample data
-- ===================================================================

USE {{DB_NAME}};

-- Insert sample users (passwords are hashed "password123")
INSERT IGNORE INTO users (email, username, password_hash) VALUES
    ('admin@example.com', 'admin', '$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2'),
    ('user1@example.com', 'user1', '$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2'),
    ('user2@example.com', 'user2', '$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2');

EOFSEED
                ;;
            mongodb)
                cat > "$SEED_FILE" << 'EOFSEED'
// ===================================================================
// MongoDB Seed Data
// Development and testing sample data
// ===================================================================

use {{DB_NAME}};

// Insert sample users (passwords are hashed "password123")
db.users.insertMany([
    {
        email: "admin@example.com",
        username: "admin",
        passwordHash: "$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2",
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        email: "user1@example.com",
        username: "user1",
        passwordHash: "$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2",
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        email: "user2@example.com",
        username: "user2",
        passwordHash: "$2a$10$XqBZwCPzXo8KV/WlqNYvBeSGzBJ/QRYq0gO0zLWCQhZVOWdX8rLJ2",
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);

EOFSEED
                ;;
        esac

        sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$SEED_FILE"

        verify_file "$SEED_FILE"
        log_file_created "$SCRIPT_NAME" "database/seed-data.sql"
        track_created "database/seed-data.sql"
    fi
fi

# ===================================================================
# Create Backup Script
# ===================================================================

if [[ "$BACKUP_ENABLED" == "true" ]]; then
    log_info "Creating backup script..."

    BACKUP_SCRIPT="$PROJECT_ROOT/database/db-backup.sh"

    if file_exists "$BACKUP_SCRIPT"; then
        backup_file "$BACKUP_SCRIPT"
        track_skipped "database/db-backup.sh (backed up)"
        log_warning "db-backup.sh already exists, backed up"
    else
        cat > "$BACKUP_SCRIPT" << 'EOFBACKUP'
#!/bin/bash

# ===================================================================
# Database Backup Script
# ===================================================================

set -euo pipefail

DB_TYPE="{{DB_TYPE}}"
DB_NAME="{{DB_NAME}}"
DB_USER="{{DB_USER}}"
DB_PASSWORD="{{DB_PASSWORD}}"
DB_HOST="{{DB_HOST}}"
DB_PORT="{{DB_PORT}}"

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting backup of $DB_NAME..."

case "$DB_TYPE" in
    postgresql)
        export PGPASSWORD="$DB_PASSWORD"
        pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"
        ;;
    mysql)
        mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"
        ;;
    mongodb)
        mongodump --host "$DB_HOST" --port "$DB_PORT" --db "$DB_NAME" --out "${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}"
        ;;
    *)
        echo "Unknown database type: $DB_TYPE"
        exit 1
        ;;
esac

echo "Backup completed: $BACKUP_FILE"

# Compress backup
if [[ "$DB_TYPE" != "mongodb" ]]; then
    gzip "$BACKUP_FILE"
    echo "Compressed: ${BACKUP_FILE}.gz"
fi

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -type d -name "${DB_NAME}_*" -mtime +7 -exec rm -rf {} + 2>/dev/null || true

echo "Backup complete!"

EOFBACKUP

        # Replace placeholders
        sed -i "s/{{DB_TYPE}}/$DB_TYPE/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_NAME}}/$DB_NAME/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_USER}}/$DB_USER/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_HOST}}/$DB_HOST/g" "$BACKUP_SCRIPT"
        sed -i "s/{{DB_PORT}}/$DB_PORT/g" "$BACKUP_SCRIPT"

        chmod +x "$BACKUP_SCRIPT"

        verify_file "$BACKUP_SCRIPT"
        log_file_created "$SCRIPT_NAME" "database/db-backup.sh"
        track_created "database/db-backup.sh"
    fi
fi

# ===================================================================
# Create Database README
# ===================================================================

log_info "Creating database README..."

README_FILE="$PROJECT_ROOT/database/README.md"

if file_exists "$README_FILE"; then
    backup_file "$README_FILE"
    track_skipped "database/README.md (backed up)"
    log_warning "database/README.md already exists, backed up"
else
    cat > "$README_FILE" << 'EOFREADME'
# Database Setup

## Overview

Database Type: {{DB_TYPE}}
Database Name: {{DB_NAME}}

## Quick Start

### 1. Initialize Database

```bash
# PostgreSQL
psql -h {{DB_HOST}} -p {{DB_PORT}} -U postgres -f database/db-init.sql

# MySQL
mysql -h {{DB_HOST}} -P {{DB_PORT}} -u root -p < database/db-init.sql

# MongoDB
mongosh "mongodb://{{DB_HOST}}:{{DB_PORT}}" < database/db-init.sql
```

### 2. Load Seed Data (Development)

```bash
# PostgreSQL
psql -h {{DB_HOST}} -p {{DB_PORT}} -U {{DB_USER}} -d {{DB_NAME}} -f database/seed-data.sql

# MySQL
mysql -h {{DB_HOST}} -P {{DB_PORT}} -u {{DB_USER}} -p {{DB_NAME}} < database/seed-data.sql

# MongoDB
mongosh "mongodb://{{DB_HOST}}:{{DB_PORT}}/{{DB_NAME}}" < database/seed-data.sql
```

### 3. Backup Database

```bash
./database/db-backup.sh
```

## Connection String

```
{{CONNECTION_STRING}}
```

## Environment Variables

Add to your `.env.local`:

```env
DATABASE_URL={{CONNECTION_STRING}}
DATABASE_POOL_SIZE={{POOL_SIZE}}
```

## Migrations

Place migration files in `database/migrations/` directory.

### Migration Naming Convention

```
YYYYMMDD_HHMMSS_description.sql
```

Example: `20250101_120000_add_users_table.sql`

## Backup & Restore

### Backup

```bash
./database/db-backup.sh
```

Backups are stored in `database/backups/` and automatically compressed.
Old backups (>7 days) are automatically deleted.

### Restore

```bash
# PostgreSQL
gunzip -c database/backups/{{DB_NAME}}_TIMESTAMP.sql.gz | psql -h {{DB_HOST}} -U {{DB_USER}} {{DB_NAME}}

# MySQL
gunzip -c database/backups/{{DB_NAME}}_TIMESTAMP.sql.gz | mysql -h {{DB_HOST}} -u {{DB_USER}} -p {{DB_NAME}}

# MongoDB
mongorestore --host {{DB_HOST}} --db {{DB_NAME}} database/backups/{{DB_NAME}}_TIMESTAMP/{{DB_NAME}}
```

## Connection Testing

Test database connectivity:

```bash
# PostgreSQL
psql -h {{DB_HOST}} -p {{DB_PORT}} -U {{DB_USER}} -d {{DB_NAME}} -c '\dt'

# MySQL
mysql -h {{DB_HOST}} -P {{DB_PORT}} -u {{DB_USER}} -p {{DB_NAME}} -e "SHOW TABLES;"

# MongoDB
mongosh "mongodb://{{DB_HOST}}:{{DB_PORT}}/{{DB_NAME}}" --eval "db.stats()"
```

## Security Notes

- Never commit database passwords to git
- Use environment variables for credentials
- Rotate passwords regularly in production
- Enable SSL/TLS connections in production
- Restrict database access by IP address
- Use read-only users for reporting/analytics

## Troubleshooting

### Connection Refused

Check that database service is running:

```bash
# PostgreSQL
sudo systemctl status postgresql

# MySQL
sudo systemctl status mysql

# MongoDB
sudo systemctl status mongod
```

### Permission Denied

Verify user has correct permissions:

```bash
# PostgreSQL
psql -U postgres -c "\du"

# MySQL
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"

# MongoDB
mongosh --eval "db.getUsers()"
```

EOFREADME

    # Replace placeholders
    CONNECTION_STRING=$(generate_connection_string "$DB_TYPE" "$DB_USER" "$DB_PASSWORD" "$DB_HOST" "$DB_PORT" "$DB_NAME")

    sed -i "s|{{DB_TYPE}}|$DB_TYPE|g" "$README_FILE"
    sed -i "s|{{DB_NAME}}|$DB_NAME|g" "$README_FILE"
    sed -i "s|{{DB_USER}}|$DB_USER|g" "$README_FILE"
    sed -i "s|{{DB_HOST}}|$DB_HOST|g" "$README_FILE"
    sed -i "s|{{DB_PORT}}|$DB_PORT|g" "$README_FILE"
    sed -i "s|{{CONNECTION_STRING}}|$CONNECTION_STRING|g" "$README_FILE"
    sed -i "s|{{POOL_SIZE}}|$POOL_SIZE|g" "$README_FILE"

    verify_file "$README_FILE"
    log_file_created "$SCRIPT_NAME" "database/README.md"
    track_created "database/README.md"
fi

# ===================================================================
# Test Database Connection (Optional)
# ===================================================================

log_info "Testing database connection..."

CONNECTION_AVAILABLE=false

case "$DB_TYPE" in
    postgresql)
        if test_postgresql_connection "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_NAME"; then
            log_success "PostgreSQL connection successful"
            CONNECTION_AVAILABLE=true
        else
            log_warning "Could not connect to PostgreSQL (this is normal if database not yet created)"
            track_warning "PostgreSQL connection test failed - database may need initialization"
        fi
        ;;
    mysql)
        if test_mysql_connection "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_NAME"; then
            log_success "MySQL connection successful"
            CONNECTION_AVAILABLE=true
        else
            log_warning "Could not connect to MySQL (this is normal if database not yet created)"
            track_warning "MySQL connection test failed - database may need initialization"
        fi
        ;;
    mongodb)
        if test_mongodb_connection "$DB_HOST" "$DB_PORT"; then
            log_success "MongoDB connection successful"
            CONNECTION_AVAILABLE=true
        else
            log_warning "Could not connect to MongoDB (this is normal if database not yet running)"
            track_warning "MongoDB connection test failed - database may need to be started"
        fi
        ;;
esac

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Database configuration complete!"
echo ""
echo "Database Details:"
echo "  Type: $DB_TYPE"
echo "  Name: $DB_NAME"
echo "  Host: $DB_HOST:$DB_PORT"
echo "  User: $DB_USER"
echo "  Pool Size: $POOL_SIZE"
echo ""
echo "Next steps:"
echo "  1. Review database configuration files in database/"
echo "  2. Initialize database:"
if [[ "$CONNECTION_AVAILABLE" == "true" ]]; then
    case "$DB_TYPE" in
        postgresql)
            echo "     psql -h $DB_HOST -p $DB_PORT -U postgres -f database/db-init.sql"
            ;;
        mysql)
            echo "     mysql -h $DB_HOST -P $DB_PORT -u root -p < database/db-init.sql"
            ;;
        mongodb)
            echo "     mongosh \"mongodb://$DB_HOST:$DB_PORT\" < database/db-init.sql"
            ;;
    esac
else
    echo "     First, start your database service"
    echo "     Then run the initialization script (see database/README.md)"
fi
echo "  3. Load seed data (development only):"
echo "     See database/README.md for instructions"
echo "  4. Add DATABASE_URL to your .env.local:"
CONNECTION_STRING=$(generate_connection_string "$DB_TYPE" "$DB_USER" "$DB_PASSWORD" "$DB_HOST" "$DB_PORT" "$DB_NAME")
echo "     DATABASE_URL=$CONNECTION_STRING"
echo "  5. Set up backup schedule (production):"
echo "     Add database/db-backup.sh to cron or CI/CD"
echo ""
echo "Security reminders:"
echo "  - Never commit database passwords to git"
echo "  - Change default passwords in production"
echo "  - Enable SSL/TLS for production connections"
echo "  - Restrict database access by IP"
echo "  - Test backups regularly"
echo ""

show_log_location
