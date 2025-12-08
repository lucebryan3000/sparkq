#!/bin/bash

# ===================================================================
# bootstrap-rollback.sh
#
# Backup and Rollback Mechanism for Bootstrap System
#
# Manages backups created during bootstrap operations and provides
# safe restoration capabilities.
#
# USAGE:
#   ./bootstrap-rollback.sh --list
#   ./bootstrap-rollback.sh --restore=TIMESTAMP
#   ./bootstrap-rollback.sh --restore=latest
#   ./bootstrap-rollback.sh --verify
#   ./bootstrap-rollback.sh --cleanup
#
# OPTIONS:
#   --list              List all available backups with timestamps
#   --restore=TIME      Restore from specific backup (YYYYMMDD-HHMMSS or 'latest')
#   --verify            Verify integrity of all backups
#   --cleanup           Remove old backups (keep last 10)
#   --help              Show this help message
#
# BACKUP STRUCTURE:
#   __bootbuild/.backups/
#   ├── 20251207-143000/
#   │   ├── bootstrap.config
#   │   ├── bootstrap-manifest.json
#   │   ├── kb-bootstrap-manifest.json
#   │   └── timestamp.txt
#   └── 20251207-150000/
#
# EXIT CODES:
#   0 = Success
#   1 = No backups available
#   2 = Backup corrupted/invalid
#   3 = Restore failed
#
# ===================================================================

set -euo pipefail

# Paths - derive BOOTSTRAP_DIR first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source lib/paths.sh to initialize all paths
source "${BOOTSTRAP_DIR}/lib/paths.sh" || exit 1

# Source common functions
source "${BOOTSTRAP_DIR}/lib/common.sh" || exit 1

# Backup directory
BACKUP_ROOT="${BOOTSTRAP_DIR}/.backups"
MAX_BACKUPS=10

# ===================================================================
# Helper Functions
# ===================================================================

show_help() {
    cat << 'EOF'
bootstrap-rollback.sh - Backup and Restore Manager

USAGE:
  ./bootstrap-rollback.sh --list
  ./bootstrap-rollback.sh --restore=TIMESTAMP
  ./bootstrap-rollback.sh --restore=latest
  ./bootstrap-rollback.sh --verify
  ./bootstrap-rollback.sh --cleanup

OPTIONS:
  --list              List all available backups with timestamps
  --restore=TIME      Restore from specific backup (YYYYMMDD-HHMMSS or 'latest')
  --verify            Verify integrity of all backups
  --cleanup           Remove old backups (keep last 10)
  --help              Show this help message

EXAMPLES:
  # List all backups
  ./bootstrap-rollback.sh --list

  # Restore from latest backup
  ./bootstrap-rollback.sh --restore=latest

  # Restore from specific timestamp
  ./bootstrap-rollback.sh --restore=20251207-143000

  # Verify all backups
  ./bootstrap-rollback.sh --verify

  # Clean up old backups
  ./bootstrap-rollback.sh --cleanup

EXIT CODES:
  0 = Success
  1 = No backups available
  2 = Backup corrupted
  3 = Restore failed

EOF
}

# Create a new backup
create_backup() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="${BACKUP_ROOT}/${timestamp}"

    log_info "Creating backup: $timestamp"

    # Create backup directory
    mkdir -p "$backup_dir"

    # Backup config file
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "${backup_dir}/bootstrap.config"
        log_success "Backed up: bootstrap.config"
    fi

    # Backup bootstrap manifest
    if [[ -f "$MANIFEST_FILE" ]]; then
        cp "$MANIFEST_FILE" "${backup_dir}/bootstrap-manifest.json"
        log_success "Backed up: bootstrap-manifest.json"
    fi

    # Backup KB manifest
    if [[ -f "$KB_MANIFEST_FILE" ]]; then
        cp "$KB_MANIFEST_FILE" "${backup_dir}/kb-bootstrap-manifest.json"
        log_success "Backed up: kb-bootstrap-manifest.json"
    fi

    # Create timestamp file with metadata
    cat > "${backup_dir}/timestamp.txt" <<EOF
timestamp=$timestamp
created=$(date '+%Y-%m-%d %H:%M:%S')
user=$USER
host=$(hostname)
bootstrap_dir=$BOOTSTRAP_DIR
EOF

    log_success "Backup created: ${backup_dir}"
    echo "$backup_dir"
}

# List all available backups
list_backups() {
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        log_warning "No backups directory found"
        return 1
    fi

    # Use mapfile/readarray for proper array handling
    local backups=()
    while IFS= read -r line; do
        backups+=("$line")
    done < <(ls -1t "$BACKUP_ROOT" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$')

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_warning "No backups available"
        return 1
    fi

    log_section "Available Backups"

    local count=0
    for backup in "${backups[@]}"; do
        count=$((count + 1))
        local backup_dir="${BACKUP_ROOT}/${backup}"
        local timestamp_file="${backup_dir}/timestamp.txt"

        echo ""
        if [[ $count -eq 1 ]]; then
            echo -e "${GREEN}[LATEST]${NC} $backup"
        else
            echo -e "${BLUE}[$count]${NC} $backup"
        fi

        # Show metadata if available
        if [[ -f "$timestamp_file" ]]; then
            local created=$(grep '^created=' "$timestamp_file" | cut -d= -f2- || echo "Unknown")
            echo "  Created: $created"
        fi

        # Show backed up files
        local files=()
        while IFS= read -r file; do
            [[ "$file" != "timestamp.txt" ]] && files+=("$file")
        done < <(ls -1 "$backup_dir" 2>/dev/null)

        if [[ ${#files[@]} -gt 0 ]]; then
            echo "  Files: ${files[*]}"
        fi

        # Show backup size
        local size=$(du -sh "$backup_dir" 2>/dev/null | cut -f1 || echo "Unknown")
        echo "  Size: $size"
    done

    echo ""
    log_info "Total backups: ${#backups[@]}"

    return 0
}

# Get the latest backup timestamp
get_latest_backup() {
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        return 1
    fi

    local latest=$(ls -1t "$BACKUP_ROOT" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$' | head -1 || true)

    if [[ -z "$latest" ]]; then
        return 1
    fi

    echo "$latest"
}

# Verify backup integrity
verify_backup() {
    local backup_timestamp="$1"
    local backup_dir="${BACKUP_ROOT}/${backup_timestamp}"

    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_timestamp"
        return 2
    fi

    log_info "Verifying backup: $backup_timestamp"

    local errors=0

    # Check timestamp file
    if [[ ! -f "${backup_dir}/timestamp.txt" ]]; then
        log_error "Missing timestamp.txt"
        errors=$((errors + 1))
    fi

    # Check for at least one backed up file
    local file_count=$(ls -1 "$backup_dir" 2>/dev/null | grep -v '^timestamp.txt$' | wc -l)
    if [[ $file_count -eq 0 ]]; then
        log_error "No backed up files found"
        errors=$((errors + 1))
    fi

    # Verify JSON files are valid
    for json_file in "${backup_dir}"/*.json; do
        [[ ! -f "$json_file" ]] && continue

        if command -v jq &>/dev/null; then
            if ! jq empty "$json_file" 2>/dev/null; then
                log_error "Invalid JSON: $(basename "$json_file")"
                errors=$((errors + 1))
            else
                log_success "Valid JSON: $(basename "$json_file")"
            fi
        elif command -v python3 &>/dev/null; then
            if ! python3 -c "import json; json.load(open('$json_file'))" 2>/dev/null; then
                log_error "Invalid JSON: $(basename "$json_file")"
                errors=$((errors + 1))
            else
                log_success "Valid JSON: $(basename "$json_file")"
            fi
        fi
    done

    # Verify config file is readable
    if [[ -f "${backup_dir}/bootstrap.config" ]]; then
        if grep -q '^\[' "${backup_dir}/bootstrap.config" 2>/dev/null; then
            log_success "Valid config: bootstrap.config"
        else
            log_error "Invalid config: bootstrap.config"
            errors=$((errors + 1))
        fi
    fi

    if [[ $errors -gt 0 ]]; then
        log_error "Backup verification failed with $errors errors"
        return 2
    fi

    log_success "Backup verified successfully"
    return 0
}

# Verify all backups
verify_all_backups() {
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        log_warning "No backups directory found"
        return 1
    fi

    local backups=($(ls -1t "$BACKUP_ROOT" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$' || true))

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_warning "No backups available"
        return 1
    fi

    log_section "Verifying All Backups"

    local total=0
    local valid=0
    local invalid=0

    for backup in "${backups[@]}"; do
        total=$((total + 1))
        echo ""
        if verify_backup "$backup"; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
        fi
    done

    echo ""
    log_section "Verification Summary"
    echo "Total: $total"
    echo -e "${GREEN}Valid: $valid${NC}"
    [[ $invalid -gt 0 ]] && echo -e "${RED}Invalid: $invalid${NC}"

    [[ $invalid -eq 0 ]]
}

# Restore from backup
restore_backup() {
    local backup_timestamp="$1"
    local backup_dir="${BACKUP_ROOT}/${backup_timestamp}"

    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_timestamp"
        return 1
    fi

    log_section "Restoring from Backup: $backup_timestamp"

    # Verify backup first
    if ! verify_backup "$backup_timestamp"; then
        log_error "Backup verification failed - aborting restore"
        return 2
    fi

    # Create a pre-restore backup
    log_info "Creating pre-restore backup..."
    local pre_restore_backup=$(create_backup)

    # Show what will be restored
    echo ""
    log_info "Files to restore:"
    local files=($(ls -1 "$backup_dir" 2>/dev/null | grep -v '^timestamp.txt$' || true))
    for file in "${files[@]}"; do
        echo "  - $file"
    done

    # Confirm restore
    echo ""
    if ! confirm "Proceed with restore?" "N"; then
        log_warning "Restore cancelled by user"
        return 0
    fi

    # Perform restore
    local restored=0
    local failed=0

    # Restore config file
    if [[ -f "${backup_dir}/bootstrap.config" ]]; then
        if cp "${backup_dir}/bootstrap.config" "$CONFIG_FILE"; then
            log_success "Restored: bootstrap.config"
            restored=$((restored + 1))
        else
            log_error "Failed to restore: bootstrap.config"
            failed=$((failed + 1))
        fi
    fi

    # Restore bootstrap manifest
    if [[ -f "${backup_dir}/bootstrap-manifest.json" ]]; then
        if cp "${backup_dir}/bootstrap-manifest.json" "$MANIFEST_FILE"; then
            log_success "Restored: bootstrap-manifest.json"
            restored=$((restored + 1))
        else
            log_error "Failed to restore: bootstrap-manifest.json"
            failed=$((failed + 1))
        fi
    fi

    # Restore KB manifest
    if [[ -f "${backup_dir}/kb-bootstrap-manifest.json" ]]; then
        mkdir -p "$(dirname "$KB_MANIFEST_FILE")"
        if cp "${backup_dir}/kb-bootstrap-manifest.json" "$KB_MANIFEST_FILE"; then
            log_success "Restored: kb-bootstrap-manifest.json"
            restored=$((restored + 1))
        else
            log_error "Failed to restore: kb-bootstrap-manifest.json"
            failed=$((failed + 1))
        fi
    fi

    # Summary
    echo ""
    log_section "Restore Summary"
    echo "Restored: $restored files"
    [[ $failed -gt 0 ]] && echo -e "${RED}Failed: $failed files${NC}"

    if [[ $failed -gt 0 ]]; then
        log_error "Restore completed with errors"
        log_info "Pre-restore backup available at: $pre_restore_backup"
        return 3
    fi

    log_success "Restore completed successfully"
    return 0
}

# Cleanup old backups
cleanup_backups() {
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        log_warning "No backups directory found"
        return 0
    fi

    local backups=($(ls -1t "$BACKUP_ROOT" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$' || true))
    local total=${#backups[@]}

    if [[ $total -eq 0 ]]; then
        log_info "No backups to clean up"
        return 0
    fi

    log_section "Backup Cleanup"
    log_info "Total backups: $total"
    log_info "Keeping last: $MAX_BACKUPS"

    if [[ $total -le $MAX_BACKUPS ]]; then
        log_info "No cleanup needed"
        return 0
    fi

    local to_remove=$((total - MAX_BACKUPS))
    log_info "Will remove: $to_remove old backups"

    # Get backups to remove (oldest first)
    local old_backups=(${backups[@]:$MAX_BACKUPS})

    echo ""
    log_info "Backups to remove:"
    for backup in "${old_backups[@]}"; do
        echo "  - $backup"
    done

    echo ""
    if ! confirm "Proceed with cleanup?" "Y"; then
        log_warning "Cleanup cancelled"
        return 0
    fi

    # Remove old backups
    local removed=0
    for backup in "${old_backups[@]}"; do
        local backup_dir="${BACKUP_ROOT}/${backup}"
        if rm -rf "$backup_dir"; then
            log_success "Removed: $backup"
            removed=$((removed + 1))
        else
            log_error "Failed to remove: $backup"
        fi
    done

    echo ""
    log_success "Removed $removed old backups"
    log_info "Kept $MAX_BACKUPS most recent backups"
}

# ===================================================================
# Main
# ===================================================================

main() {
    local action=""
    local restore_timestamp=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                action="list"
                shift
                ;;
            --restore=*)
                action="restore"
                restore_timestamp="${1#*=}"
                shift
                ;;
            --verify)
                action="verify"
                shift
                ;;
            --cleanup)
                action="cleanup"
                shift
                ;;
            --create)
                action="create"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Default to list if no action specified
    if [[ -z "$action" ]]; then
        action="list"
    fi

    # Execute action
    case "$action" in
        list)
            list_backups
            ;;
        restore)
            if [[ -z "$restore_timestamp" ]]; then
                log_error "Restore timestamp required"
                exit 1
            fi

            # Handle 'latest' keyword
            if [[ "$restore_timestamp" == "latest" ]]; then
                restore_timestamp=$(get_latest_backup)
                if [[ -z "$restore_timestamp" ]]; then
                    log_error "No backups available"
                    exit 1
                fi
                log_info "Using latest backup: $restore_timestamp"
            fi

            restore_backup "$restore_timestamp"
            ;;
        verify)
            verify_all_backups
            ;;
        cleanup)
            cleanup_backups
            ;;
        create)
            create_backup
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

main "$@"
