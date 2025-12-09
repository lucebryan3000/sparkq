#!/bin/bash

# ===================================================================
# postgres-utils.sh
#
# PostgreSQL client utilities for bootstrap scripts
# Source this in scripts that need PostgreSQL operations:
#   source "$(dirname "$0")/../lib/postgres-utils.sh"
#
# Provides:
#   - Connection testing (pg_connect)
#   - Query execution (pg_execute)
#   - Database operations (pg_create_db, pg_drop_db, pg_list_dbs)
#   - User management (pg_create_user, pg_grant)
#   - Backup/restore (pg_backup, pg_restore)
#   - Extension management (pg_install_extension)
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_POSTGRES_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_POSTGRES_UTILS_LOADED=1

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ===================================================================
# Configuration
# ===================================================================

# Default PostgreSQL connection settings (can be overridden)
: "${PGHOST:=localhost}"
: "${PGPORT:=5432}"
: "${PGUSER:=postgres}"
: "${PGDATABASE:=postgres}"
# PGPASSWORD should be set in environment or .pgpass

# ===================================================================
# Connection Management
# ===================================================================

# Test PostgreSQL connection
# Usage: pg_connect [host] [port] [user] [database]
# Returns: 0 on success, 1 on failure
pg_connect() {
    local host="${1:-$PGHOST}"
    local port="${2:-$PGPORT}"
    local user="${3:-$PGUSER}"
    local database="${4:-$PGDATABASE}"

    log_info "Testing PostgreSQL connection to $user@$host:$port/$database..."

    if PGPASSWORD="$PGPASSWORD" psql -h "$host" -p "$port" -U "$user" -d "$database" -c '\q' >/dev/null 2>&1; then
        log_success "PostgreSQL connection successful"
        return 0
    else
        log_error "PostgreSQL connection failed"
        return 1
    fi
}

# Execute SQL query
# Usage: pg_execute <query> [database] [host] [port] [user]
# Returns: Query output on success, 1 on failure
pg_execute() {
    local query="$1"
    local database="${2:-$PGDATABASE}"
    local host="${3:-$PGHOST}"
    local port="${4:-$PGPORT}"
    local user="${5:-$PGUSER}"

    if [[ -z "$query" ]]; then
        log_error "pg_execute: Query cannot be empty"
        return 1
    fi

    PGPASSWORD="$PGPASSWORD" psql -h "$host" -p "$port" -U "$user" -d "$database" \
        -t -A -c "$query" 2>&1
}

# Execute SQL query (verbose mode with error output)
# Usage: pg_execute_verbose <query> [database] [host] [port] [user]
pg_execute_verbose() {
    local query="$1"
    local database="${2:-$PGDATABASE}"
    local host="${3:-$PGHOST}"
    local port="${4:-$PGPORT}"
    local user="${5:-$PGUSER}"

    if [[ -z "$query" ]]; then
        log_error "pg_execute_verbose: Query cannot be empty"
        return 1
    fi

    PGPASSWORD="$PGPASSWORD" psql -h "$host" -p "$port" -U "$user" -d "$database" \
        -c "$query"
}

# ===================================================================
# Database Operations
# ===================================================================

# Create database
# Usage: pg_create_db <database_name> [owner] [encoding] [template]
# Returns: 0 on success, 1 on failure
pg_create_db() {
    local db_name="$1"
    local owner="${2:-$PGUSER}"
    local encoding="${3:-UTF8}"
    local template="${4:-template0}"

    if [[ -z "$db_name" ]]; then
        log_error "pg_create_db: Database name cannot be empty"
        return 1
    fi

    log_info "Creating database '$db_name' with owner '$owner'..."

    local query="CREATE DATABASE \"$db_name\" WITH OWNER = \"$owner\" ENCODING = '$encoding' TEMPLATE = $template;"

    if pg_execute "$query" "postgres" >/dev/null 2>&1; then
        log_success "Database '$db_name' created successfully"
        return 0
    else
        log_error "Failed to create database '$db_name'"
        return 1
    fi
}

# Drop database
# Usage: pg_drop_db <database_name> [force]
# Returns: 0 on success, 1 on failure
pg_drop_db() {
    local db_name="$1"
    local force="${2:-false}"

    if [[ -z "$db_name" ]]; then
        log_error "pg_drop_db: Database name cannot be empty"
        return 1
    fi

    # Safety check: don't drop system databases
    if [[ "$db_name" == "postgres" ]] || [[ "$db_name" == "template0" ]] || [[ "$db_name" == "template1" ]]; then
        log_error "Cannot drop system database '$db_name'"
        return 1
    fi

    log_warning "Dropping database '$db_name'..."

    # Terminate active connections if force is enabled
    if [[ "$force" == "true" ]]; then
        log_info "Terminating active connections to '$db_name'..."
        local terminate_query="SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db_name' AND pid <> pg_backend_pid();"
        pg_execute "$terminate_query" "postgres" >/dev/null 2>&1
    fi

    local query="DROP DATABASE IF EXISTS \"$db_name\";"

    if pg_execute "$query" "postgres" >/dev/null 2>&1; then
        log_success "Database '$db_name' dropped successfully"
        return 0
    else
        log_error "Failed to drop database '$db_name'"
        return 1
    fi
}

# List databases
# Usage: pg_list_dbs [pattern]
# Returns: List of databases
pg_list_dbs() {
    local pattern="${1:-*}"

    local query="SELECT datname FROM pg_database WHERE datistemplate = false"

    if [[ "$pattern" != "*" ]]; then
        query="$query AND datname LIKE '$pattern'"
    fi

    query="$query ORDER BY datname;"

    pg_execute "$query" "postgres"
}

# Check if database exists
# Usage: pg_db_exists <database_name>
# Returns: 0 if exists, 1 if not
pg_db_exists() {
    local db_name="$1"

    if [[ -z "$db_name" ]]; then
        log_error "pg_db_exists: Database name cannot be empty"
        return 1
    fi

    local query="SELECT 1 FROM pg_database WHERE datname = '$db_name';"
    local result
    result=$(pg_execute "$query" "postgres" 2>/dev/null)

    [[ "$result" == "1" ]]
}

# ===================================================================
# User Management
# ===================================================================

# Create user
# Usage: pg_create_user <username> <password> [superuser]
# Returns: 0 on success, 1 on failure
pg_create_user() {
    local username="$1"
    local password="$2"
    local superuser="${3:-false}"

    if [[ -z "$username" ]]; then
        log_error "pg_create_user: Username cannot be empty"
        return 1
    fi

    if [[ -z "$password" ]]; then
        log_error "pg_create_user: Password cannot be empty"
        return 1
    fi

    log_info "Creating PostgreSQL user '$username'..."

    local query="CREATE USER \"$username\" WITH PASSWORD '$password'"

    if [[ "$superuser" == "true" ]]; then
        query="$query SUPERUSER"
    fi

    query="$query;"

    if pg_execute "$query" "postgres" >/dev/null 2>&1; then
        log_success "User '$username' created successfully"
        return 0
    else
        log_error "Failed to create user '$username'"
        return 1
    fi
}

# Grant permissions
# Usage: pg_grant <privilege> <database> <user>
# Example: pg_grant "ALL PRIVILEGES" "mydb" "myuser"
# Returns: 0 on success, 1 on failure
pg_grant() {
    local privilege="$1"
    local database="$2"
    local user="$3"

    if [[ -z "$privilege" ]] || [[ -z "$database" ]] || [[ -z "$user" ]]; then
        log_error "pg_grant: privilege, database, and user are required"
        return 1
    fi

    log_info "Granting $privilege on database '$database' to user '$user'..."

    local query="GRANT $privilege ON DATABASE \"$database\" TO \"$user\";"

    if pg_execute "$query" "postgres" >/dev/null 2>&1; then
        log_success "Permissions granted successfully"
        return 0
    else
        log_error "Failed to grant permissions"
        return 1
    fi
}

# Check if user exists
# Usage: pg_user_exists <username>
# Returns: 0 if exists, 1 if not
pg_user_exists() {
    local username="$1"

    if [[ -z "$username" ]]; then
        log_error "pg_user_exists: Username cannot be empty"
        return 1
    fi

    local query="SELECT 1 FROM pg_roles WHERE rolname = '$username';"
    local result
    result=$(pg_execute "$query" "postgres" 2>/dev/null)

    [[ "$result" == "1" ]]
}

# ===================================================================
# Backup and Restore
# ===================================================================

# Backup database using pg_dump
# Usage: pg_backup <database> <output_file> [format]
# Format: plain (default), custom, directory, tar
# Returns: 0 on success, 1 on failure
pg_backup() {
    local database="$1"
    local output_file="$2"
    local format="${3:-plain}"

    if [[ -z "$database" ]] || [[ -z "$output_file" ]]; then
        log_error "pg_backup: database and output_file are required"
        return 1
    fi

    log_info "Backing up database '$database' to '$output_file'..."

    local format_flag=""
    case "$format" in
        plain)
            format_flag="-Fp"
            ;;
        custom)
            format_flag="-Fc"
            ;;
        directory)
            format_flag="-Fd"
            ;;
        tar)
            format_flag="-Ft"
            ;;
        *)
            log_error "Invalid format: $format (valid: plain, custom, directory, tar)"
            return 1
            ;;
    esac

    if PGPASSWORD="$PGPASSWORD" pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" \
        $format_flag -f "$output_file" "$database" 2>&1; then
        log_success "Database backup completed: $output_file"
        return 0
    else
        log_error "Database backup failed"
        return 1
    fi
}

# Restore database from backup
# Usage: pg_restore <database> <backup_file> [format]
# Format: plain (default), custom, directory, tar
# Returns: 0 on success, 1 on failure
pg_restore() {
    local database="$1"
    local backup_file="$2"
    local format="${3:-plain}"

    if [[ -z "$database" ]] || [[ -z "$backup_file" ]]; then
        log_error "pg_restore: database and backup_file are required"
        return 1
    fi

    if [[ ! -f "$backup_file" ]] && [[ ! -d "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    log_info "Restoring database '$database' from '$backup_file'..."

    if [[ "$format" == "plain" ]]; then
        # Plain SQL format uses psql
        if PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" \
            -d "$database" -f "$backup_file" >/dev/null 2>&1; then
            log_success "Database restored successfully"
            return 0
        else
            log_error "Database restore failed"
            return 1
        fi
    else
        # Custom/directory/tar formats use pg_restore
        local format_flag=""
        case "$format" in
            custom)
                format_flag="-Fc"
                ;;
            directory)
                format_flag="-Fd"
                ;;
            tar)
                format_flag="-Ft"
                ;;
            *)
                log_error "Invalid format: $format (valid: plain, custom, directory, tar)"
                return 1
                ;;
        esac

        if PGPASSWORD="$PGPASSWORD" pg_restore -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" \
            $format_flag -d "$database" "$backup_file" >/dev/null 2>&1; then
            log_success "Database restored successfully"
            return 0
        else
            log_error "Database restore failed"
            return 1
        fi
    fi
}

# ===================================================================
# Extension Management
# ===================================================================

# Install PostgreSQL extension
# Usage: pg_install_extension <extension_name> [database]
# Returns: 0 on success, 1 on failure
pg_install_extension() {
    local extension="$1"
    local database="${2:-$PGDATABASE}"

    if [[ -z "$extension" ]]; then
        log_error "pg_install_extension: Extension name cannot be empty"
        return 1
    fi

    log_info "Installing extension '$extension' in database '$database'..."

    local query="CREATE EXTENSION IF NOT EXISTS \"$extension\";"

    if pg_execute "$query" "$database" >/dev/null 2>&1; then
        log_success "Extension '$extension' installed successfully"
        return 0
    else
        log_error "Failed to install extension '$extension'"
        return 1
    fi
}

# List installed extensions
# Usage: pg_list_extensions [database]
# Returns: List of installed extensions
pg_list_extensions() {
    local database="${1:-$PGDATABASE}"

    local query="SELECT extname, extversion FROM pg_extension ORDER BY extname;"

    pg_execute "$query" "$database"
}

# Check if extension exists
# Usage: pg_extension_exists <extension_name> [database]
# Returns: 0 if exists, 1 if not
pg_extension_exists() {
    local extension="$1"
    local database="${2:-$PGDATABASE}"

    if [[ -z "$extension" ]]; then
        log_error "pg_extension_exists: Extension name cannot be empty"
        return 1
    fi

    local query="SELECT 1 FROM pg_extension WHERE extname = '$extension';"
    local result
    result=$(pg_execute "$query" "$database" 2>/dev/null)

    [[ "$result" == "1" ]]
}

# ===================================================================
# Utility Functions
# ===================================================================

# Get PostgreSQL version
# Usage: pg_version
# Returns: PostgreSQL version string
pg_version() {
    local query="SELECT version();"
    pg_execute "$query" "postgres"
}

# Get database size
# Usage: pg_db_size <database_name>
# Returns: Human-readable database size
pg_db_size() {
    local database="$1"

    if [[ -z "$database" ]]; then
        log_error "pg_db_size: Database name cannot be empty"
        return 1
    fi

    local query="SELECT pg_size_pretty(pg_database_size('$database'));"
    pg_execute "$query" "postgres"
}

log_info "PostgreSQL utilities loaded (postgres-utils.sh)"
