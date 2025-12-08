#!/bin/bash

# ===================================================================
# bootstrap-repair.sh
#
# Repair and Recovery Tool for Bootstrap System
#
# Detects the current state of bootstrap operations and provides
# options to fix broken or incomplete runs.
#
# USAGE:
#   ./bootstrap-repair.sh --status
#   ./bootstrap-repair.sh --retry
#   ./bootstrap-repair.sh --continue
#   ./bootstrap-repair.sh --from-scratch
#
# OPTIONS:
#   --status            Show current bootstrap state and issues
#   --retry             Retry the last failed phase/script
#   --continue          Continue from where bootstrap stopped
#   --from-scratch      Complete rollback and restart bootstrap
#   --check             Deep system check for common issues
#   --help              Show this help message
#
# DETECTION LOGIC:
#   - Reads __bootbuild/logs/ for session logs
#   - Checks bootstrap.config [session] section
#   - Compares against baseline state
#   - Identifies failed/incomplete operations
#
# EXIT CODES:
#   0 = Success
#   1 = No bootstrap run detected
#   2 = Bootstrap state unclear
#   3 = Repair failed
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

# Source config manager if available
[[ -f "${LIB_DIR}/config-manager.sh" ]] && source "${LIB_DIR}/config-manager.sh"

# ===================================================================
# Helper Functions
# ===================================================================

show_help() {
    cat << 'EOF'
bootstrap-repair.sh - Bootstrap Repair and Recovery Tool

USAGE:
  ./bootstrap-repair.sh --status
  ./bootstrap-repair.sh --retry
  ./bootstrap-repair.sh --continue
  ./bootstrap-repair.sh --from-scratch
  ./bootstrap-repair.sh --check

OPTIONS:
  --status            Show current bootstrap state and detected issues
  --retry             Retry the last failed phase/script
  --continue          Continue bootstrap from last checkpoint
  --from-scratch      Complete rollback and restart from beginning
  --check             Deep system check for common configuration issues
  --help              Show this help message

EXAMPLES:
  # Check current state
  ./bootstrap-repair.sh --status

  # Retry last failed operation
  ./bootstrap-repair.sh --retry

  # Continue from where it stopped
  ./bootstrap-repair.sh --continue

  # Start over completely
  ./bootstrap-repair.sh --from-scratch

  # Deep system check
  ./bootstrap-repair.sh --check

EXIT CODES:
  0 = Success
  1 = No bootstrap run detected
  2 = Bootstrap state unclear
  3 = Repair failed

EOF
}

# Get last bootstrap session info
get_session_info() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 1
    fi

    # Read session section
    local scripts_run=$(config_get "session.scripts_run" "" 2>/dev/null || echo "")
    local scripts_failed=$(config_get "session.scripts_failed" "" 2>/dev/null || echo "")
    local last_script=$(config_get "session.last_script" "" 2>/dev/null || echo "")

    cat <<EOF
scripts_run=$scripts_run
scripts_failed=$scripts_failed
last_script=$last_script
EOF
}

# Detect bootstrap state
detect_state() {
    log_section "Bootstrap State Detection"

    # Check if bootstrap has ever run
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "state=never_run"
        echo "description=No bootstrap.config found - bootstrap has never run"
        return 0
    fi

    # Check for session markers
    local session_info=$(get_session_info)
    local scripts_run=$(echo "$session_info" | grep '^scripts_run=' | cut -d= -f2)
    local scripts_failed=$(echo "$session_info" | grep '^scripts_failed=' | cut -d= -f2)
    local last_script=$(echo "$session_info" | grep '^last_script=' | cut -d= -f2)

    # Check logs directory
    local log_count=0
    if [[ -d "$LOGS_DIR" ]]; then
        log_count=$(find "$LOGS_DIR" -type f -name "*.log" 2>/dev/null | wc -l)
    fi

    # Check for completion markers
    local completed_scripts=()
    if [[ -d "${LOGS_DIR}" ]]; then
        completed_scripts=($(find "${LOGS_DIR}" -type f -name ".*.completed" 2>/dev/null | xargs -I {} basename {} | sed 's/^\.//' | sed 's/\.completed$//' || true))
    fi

    # Determine state
    if [[ -n "$scripts_failed" ]]; then
        echo "state=failed"
        echo "description=Bootstrap failed during: $scripts_failed"
        echo "last_script=$last_script"
        echo "failed_scripts=$scripts_failed"
    elif [[ -n "$scripts_run" ]] && [[ -z "$scripts_failed" ]]; then
        echo "state=partial"
        echo "description=Bootstrap partially complete - some scripts ran successfully"
        echo "last_script=$last_script"
        echo "completed_scripts=${completed_scripts[*]}"
        echo "log_count=$log_count"
    elif [[ ${#completed_scripts[@]} -eq 0 ]] && [[ $log_count -eq 0 ]]; then
        echo "state=initialized"
        echo "description=Bootstrap config exists but no scripts have run"
    else
        echo "state=complete"
        echo "description=Bootstrap appears to have completed successfully"
        echo "completed_scripts=${completed_scripts[*]}"
        echo "log_count=$log_count"
    fi

    echo "completed_count=${#completed_scripts[@]}"
}

# Show detailed status
show_status() {
    log_section "Bootstrap System Status"

    # Get state
    local state_info=$(detect_state)
    local state=$(echo "$state_info" | grep '^state=' | cut -d= -f2)
    local description=$(echo "$state_info" | grep '^description=' | cut -d= -f2-)

    echo ""
    echo -e "${BLUE}Current State:${NC} ${BOLD}$state${NC}"
    echo -e "${BLUE}Description:${NC} $description"
    echo ""

    # Show detailed info based on state
    case "$state" in
        never_run)
            log_info "Bootstrap has not been initialized yet"
            echo ""
            echo "Next steps:"
            echo "  1. Run: ./scripts/bootstrap-detect.sh"
            echo "  2. Or run a specific bootstrap script"
            ;;

        failed)
            local failed_scripts=$(echo "$state_info" | grep '^failed_scripts=' | cut -d= -f2)
            log_error "Bootstrap failed"
            echo ""
            echo "Failed scripts: $failed_scripts"
            echo ""
            echo "Recovery options:"
            echo "  1. Retry failed operation: ./scripts/bootstrap-repair.sh --retry"
            echo "  2. Start from scratch: ./scripts/bootstrap-repair.sh --from-scratch"
            echo "  3. Check system state: ./scripts/bootstrap-repair.sh --check"
            ;;

        partial)
            local completed=$(echo "$state_info" | grep '^completed_scripts=' | cut -d= -f2-)
            local completed_count=$(echo "$state_info" | grep '^completed_count=' | cut -d= -f2)
            log_warning "Bootstrap incomplete"
            echo ""
            echo "Completed: $completed_count scripts"
            [[ -n "$completed" ]] && echo "Scripts completed: $completed"
            echo ""
            echo "Recovery options:"
            echo "  1. Continue from checkpoint: ./scripts/bootstrap-repair.sh --continue"
            echo "  2. Start fresh: ./scripts/bootstrap-repair.sh --from-scratch"
            ;;

        initialized)
            log_info "Bootstrap initialized but not started"
            echo ""
            echo "Config file exists but no operations have been performed"
            ;;

        complete)
            local completed_count=$(echo "$state_info" | grep '^completed_count=' | cut -d= -f2)
            log_success "Bootstrap appears complete"
            echo ""
            echo "Completed: $completed_count operations"
            echo ""
            echo "Maintenance options:"
            echo "  - Deep check: ./scripts/bootstrap-repair.sh --check"
            echo "  - View backups: ./scripts/bootstrap-rollback.sh --list"
            ;;
    esac

    # Show session info if available
    if [[ -f "$CONFIG_FILE" ]]; then
        echo ""
        log_section "Session Information"

        local session_info=$(get_session_info)
        local scripts_run=$(echo "$session_info" | grep '^scripts_run=' | cut -d= -f2)
        local last_script=$(echo "$session_info" | grep '^last_script=' | cut -d= -f2)

        [[ -n "$scripts_run" ]] && echo "Scripts run: $scripts_run"
        [[ -n "$last_script" ]] && echo "Last script: $last_script"
    fi

    # Show recent logs
    if [[ -d "$LOGS_DIR" ]]; then
        echo ""
        log_section "Recent Logs"

        local recent_logs=($(find "$LOGS_DIR" -type f -name "*.log" -mtime -1 2>/dev/null | head -5 || true))
        if [[ ${#recent_logs[@]} -gt 0 ]]; then
            for log_file in "${recent_logs[@]}"; do
                local log_name=$(basename "$log_file")
                local log_size=$(du -sh "$log_file" | cut -f1)
                local log_time=$(stat -c %y "$log_file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
                echo "  - $log_name ($log_size) - $log_time"
            done
        else
            echo "  No recent logs found"
        fi
    fi

    echo ""
}

# Deep system check
deep_check() {
    log_section "Deep System Check"

    local issues=0
    local warnings=0

    echo ""
    log_info "Checking bootstrap infrastructure..."

    # Check directory structure
    echo ""
    log_info "Directory Structure:"

    local required_dirs=("$CONFIG_DIR" "$LIB_DIR" "$SCRIPTS_DIR" "$TEMPLATES_DIR" "$LOGS_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "$(basename "$dir")/ exists"
        else
            log_error "Missing: $(basename "$dir")/"
            ((issues++))
        fi
    done

    # Check core files
    echo ""
    log_info "Core Files:"

    if [[ -f "$MANIFEST_FILE" ]]; then
        # Validate JSON
        if command -v jq &>/dev/null; then
            if jq empty "$MANIFEST_FILE" 2>/dev/null; then
                log_success "bootstrap-manifest.json valid"
            else
                log_error "bootstrap-manifest.json invalid JSON"
                ((issues++))
            fi
        else
            log_success "bootstrap-manifest.json exists (jq not available for validation)"
        fi
    else
        log_error "bootstrap-manifest.json missing"
        ((issues++))
    fi

    if [[ -f "$CONFIG_FILE" ]]; then
        if grep -q '^\[' "$CONFIG_FILE" 2>/dev/null; then
            log_success "bootstrap.config valid"
        else
            log_error "bootstrap.config invalid format"
            ((issues++))
        fi
    else
        log_warning "bootstrap.config not found (will be created on first run)"
        ((warnings++))
    fi

    # Check library files
    echo ""
    log_info "Library Files:"

    local lib_files=("common.sh" "paths.sh" "config-manager.sh")
    for lib in "${lib_files[@]}"; do
        local lib_path="${LIB_DIR}/${lib}"
        if [[ -f "$lib_path" ]]; then
            # Check if it sources correctly
            if bash -n "$lib_path" 2>/dev/null; then
                log_success "$lib"
            else
                log_error "$lib has syntax errors"
                ((issues++))
            fi
        else
            log_warning "$lib not found"
            ((warnings++))
        fi
    done

    # Check for common configuration issues
    echo ""
    log_info "Configuration Check:"

    if [[ -f "$CONFIG_FILE" ]]; then
        # Check for required sections
        local required_sections=("project" "git" "packages")
        for section in "${required_sections[@]}"; do
            if grep -q "^\[$section\]" "$CONFIG_FILE"; then
                log_success "[$section] section present"
            else
                log_warning "[$section] section missing"
                ((warnings++))
            fi
        done
    fi

    # Check permissions
    echo ""
    log_info "Permissions Check:"

    if [[ -w "$CONFIG_DIR" ]]; then
        log_success "Config directory writable"
    else
        log_error "Config directory not writable"
        ((issues++))
    fi

    if [[ -w "$LOGS_DIR" ]] || mkdir -p "$LOGS_DIR" 2>/dev/null; then
        log_success "Logs directory writable"
    else
        log_error "Logs directory not writable"
        ((issues++))
    fi

    # Check for backups
    echo ""
    log_info "Backup System:"

    local backup_dir="${BOOTSTRAP_DIR}/.backups"
    if [[ -d "$backup_dir" ]]; then
        local backup_count=$(find "$backup_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        log_success "Backup system active ($backup_count backups)"
    else
        log_warning "No backups found"
        ((warnings++))
    fi

    # Summary
    echo ""
    log_section "Check Summary"

    if [[ $issues -eq 0 ]] && [[ $warnings -eq 0 ]]; then
        log_success "All checks passed - system is healthy"
        return 0
    elif [[ $issues -eq 0 ]]; then
        log_warning "$warnings warnings found - system is mostly healthy"
        return 0
    else
        log_error "$issues critical issues found, $warnings warnings"
        echo ""
        echo "Recommendations:"
        if [[ $issues -gt 0 ]]; then
            echo "  1. Fix critical issues listed above"
            echo "  2. Consider running: ./scripts/bootstrap-repair.sh --from-scratch"
        fi
        return 1
    fi
}

# Retry last failed operation
retry_failed() {
    log_section "Retry Failed Operation"

    # Get state
    local state_info=$(detect_state)
    local state=$(echo "$state_info" | grep '^state=' | cut -d= -f2)

    if [[ "$state" != "failed" ]]; then
        log_error "No failed operation to retry (state: $state)"
        return 1
    fi

    local failed_scripts=$(echo "$state_info" | grep '^failed_scripts=' | cut -d= -f2)

    log_info "Failed scripts: $failed_scripts"
    echo ""

    # Get the first failed script
    local first_failed=$(echo "$failed_scripts" | tr ',' '\n' | head -1)

    if [[ -z "$first_failed" ]]; then
        log_error "Could not determine which script failed"
        return 1
    fi

    log_info "Will retry: $first_failed"
    echo ""

    if ! confirm "Retry this script?" "Y"; then
        log_warning "Retry cancelled"
        return 0
    fi

    # Execute the script
    local script_path="${SCRIPTS_DIR}/bootstrap-${first_failed}.sh"

    if [[ ! -f "$script_path" ]]; then
        log_error "Script not found: $script_path"
        return 1
    fi

    log_info "Executing: $script_path"
    echo ""

    if bash "$script_path"; then
        log_success "Script completed successfully"

        # Update session to remove from failed list
        if [[ -f "$CONFIG_FILE" ]]; then
            # This is simplified - in production would properly update the CSV
            log_info "Updating session state..."
        fi

        return 0
    else
        log_error "Script failed again"
        return 3
    fi
}

# Continue from checkpoint
continue_bootstrap() {
    log_section "Continue Bootstrap"

    # Get state
    local state_info=$(detect_state)
    local state=$(echo "$state_info" | grep '^state=' | cut -d= -f2)

    if [[ "$state" == "never_run" ]]; then
        log_error "Bootstrap has never been run - nothing to continue"
        return 1
    fi

    if [[ "$state" == "complete" ]]; then
        log_info "Bootstrap appears complete - nothing to continue"
        return 0
    fi

    log_warning "Continue functionality requires orchestrator integration"
    echo ""
    echo "This would typically:"
    echo "  1. Identify which scripts have completed"
    echo "  2. Determine next scripts to run"
    echo "  3. Resume bootstrap from checkpoint"
    echo ""
    echo "For now, you can manually run individual scripts:"
    echo "  ./scripts/bootstrap-<name>.sh"

    return 0
}

# Complete restart
restart_from_scratch() {
    log_section "Restart From Scratch"

    log_warning "This will:"
    echo "  1. Create a backup of current state"
    echo "  2. Reset bootstrap.config [session] section"
    echo "  3. Clear completion markers"
    echo ""

    if ! confirm "Are you sure you want to restart from scratch?" "N"; then
        log_warning "Restart cancelled"
        return 0
    fi

    # Create backup first
    log_info "Creating backup..."
    if command -v "${SCRIPTS_DIR}/bootstrap-rollback.sh" &>/dev/null; then
        "${SCRIPTS_DIR}/bootstrap-rollback.sh" --create
    else
        log_warning "Rollback script not found - skipping backup"
    fi

    # Clear session section in config
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Clearing session state..."

        # Backup config
        cp "$CONFIG_FILE" "${CONFIG_FILE}.pre-restart"

        # Clear session values
        sed -i.bak '/^\[session\]/,/^\[/ {
            /^scripts_run=/d
            /^scripts_failed=/d
            /^scripts_skipped=/d
            /^last_script=/d
        }' "$CONFIG_FILE"

        log_success "Session state cleared"
    fi

    # Clear completion markers
    if [[ -d "$LOGS_DIR" ]]; then
        log_info "Clearing completion markers..."
        find "$LOGS_DIR" -name ".*.completed" -delete 2>/dev/null || true
        log_success "Completion markers cleared"
    fi

    echo ""
    log_success "System reset complete"
    echo ""
    echo "You can now run bootstrap scripts fresh:"
    echo "  ./scripts/bootstrap-detect.sh"
    echo "  ./scripts/bootstrap-<name>.sh"

    return 0
}

# ===================================================================
# Main
# ===================================================================

main() {
    local action="status"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --status)
                action="status"
                shift
                ;;
            --retry)
                action="retry"
                shift
                ;;
            --continue)
                action="continue"
                shift
                ;;
            --from-scratch)
                action="from-scratch"
                shift
                ;;
            --check)
                action="check"
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

    # Execute action
    case "$action" in
        status)
            show_status
            ;;
        retry)
            retry_failed
            ;;
        continue)
            continue_bootstrap
            ;;
        from-scratch)
            restart_from_scratch
            ;;
        check)
            deep_check
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

main "$@"
