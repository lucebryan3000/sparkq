#!/bin/bash

# ===================================================================
# common.sh
#
# Shared functions for all bootstrap scripts
# Source this at the top of each script:
#   source "$(dirname "$0")/../lib/common.sh"
#
# Provides:
#   - Logging functions (log_info, log_success, log_error, log_warning)
#   - File operations (backup_file, verify_file, safe_copy)
#   - Validation helpers (require_command, require_dir, is_writable)
#   - Auto-approve checking
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_COMMON_LOADED:-}" ]] && return 0
_BOOTSTRAP_COMMON_LOADED=1

# ===================================================================
# Colors
# ===================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREY='\033[90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ===================================================================
# Logging Functions
# ===================================================================

log_info() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

log_fatal() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

log_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_debug() {
    [[ "${BOOTSTRAP_DEBUG:-false}" == "true" ]] && echo -e "${GREY}[DEBUG] $1${NC}"
}

# ===================================================================
# File Operations
# ===================================================================

# Backup a file with timestamp
# Usage: backup_file "/path/to/file"
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%s)"
        cp "$file" "$backup"
        log_debug "Backed up: $file → $backup"
        echo "$backup"
    fi
}

# Verify file was created successfully
# Usage: verify_file "/path/to/file"
verify_file() {
    local file="$1"
    if [[ -f "$file" && -r "$file" ]]; then
        log_success "Created: $(basename "$file")"
        return 0
    else
        log_error "Failed to create: $file"
        return 1
    fi
}

# Safe copy with backup
# Usage: safe_copy "source" "destination"
safe_copy() {
    local src="$1"
    local dst="$2"

    if [[ ! -f "$src" ]]; then
        log_error "Source file not found: $src"
        return 1
    fi

    # Backup existing destination
    [[ -f "$dst" ]] && backup_file "$dst"

    # Copy
    if cp "$src" "$dst"; then
        verify_file "$dst"
        return 0
    else
        log_error "Failed to copy: $src → $dst"
        return 1
    fi
}

# Create directory if it doesn't exist
# Usage: ensure_dir "/path/to/dir"
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        if mkdir -p "$dir"; then
            log_debug "Created directory: $dir"
            return 0
        else
            log_error "Failed to create directory: $dir"
            return 1
        fi
    fi
    return 0
}

# ===================================================================
# Validation Helpers
# ===================================================================

# Check if command exists
# Usage: require_command "git" || exit 1
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

# Check if jq is available
# Usage: has_jq && echo "jq is installed"
has_jq() {
    command -v jq &>/dev/null
}

# Check if directory exists
# Usage: require_dir "/path/to/dir"
require_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_error "Directory not found: $dir"
        return 1
    fi
    return 0
}

# Check if path is writable
# Usage: is_writable "/path/to/check"
is_writable() {
    local path="$1"
    if [[ -w "$path" ]]; then
        return 0
    else
        log_error "Path not writable: $path"
        return 1
    fi
}

# Check if file exists
# Usage: file_exists "/path/to/file"
file_exists() {
    [[ -f "$1" ]]
}

# Check if directory exists
# Usage: dir_exists "/path/to/dir"
dir_exists() {
    [[ -d "$1" ]]
}

# ===================================================================
# Auto-Approve Checking
# ===================================================================

# Check if an action is auto-approved
# Usage: is_auto_approved "create_directories"
is_auto_approved() {
    local action="$1"
    local config_file="${BOOTSTRAP_CONFIG:-}"

    # If no config, default to true for safe actions
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    # Source config manager if available
    local lib_dir="$(dirname "${BASH_SOURCE[0]}")"
    if [[ -f "${lib_dir}/config-manager.sh" ]]; then
        source "${lib_dir}/config-manager.sh"
        local value=$(config_get "auto_approve.${action}" "true" "$config_file")
        [[ "$value" == "true" ]]
    else
        return 0
    fi
}

# ===================================================================
# Script Setup Helpers
# ===================================================================

# Standard script initialization
# Usage: init_script "bootstrap-git.sh"
init_script() {
    local script_name="$1"

    # Derive BOOTSTRAP_DIR from calling script
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    export BOOTSTRAP_DIR="$(cd "${script_dir}/.." && pwd)"
    export SCRIPT_NAME="$script_name"
    export SCRIPT_DIR="$script_dir"

    # Source lib/paths.sh to initialize all paths
    if [[ ! -f "${BOOTSTRAP_DIR}/lib/paths.sh" ]]; then
        log_error "lib/paths.sh not found in ${BOOTSTRAP_DIR}/lib/"
        return 1
    fi

    source "${BOOTSTRAP_DIR}/lib/paths.sh" || {
        log_error "Failed to initialize paths"
        return 1
    }

    # Now source config manager with paths already set
    if [[ -f "${LIB_DIR}/config-manager.sh" ]]; then
        source "${LIB_DIR}/config-manager.sh" || {
            log_error "Failed to source config-manager"
            return 1
        }
    fi

    log_debug "Initialized: $script_name"
    log_debug "Bootstrap dir: $BOOTSTRAP_DIR"
    log_debug "Manifest: $MANIFEST_FILE"
}

# Get project root (where files will be created)
# Usage: PROJECT_ROOT=$(get_project_root "$1")
get_project_root() {
    local arg="${1:-.}"

    # Resolve to absolute path
    if [[ -d "$arg" ]]; then
        cd "$arg" && pwd
    else
        log_error "Project root not found: $arg"
        return 1
    fi
}

# ===================================================================
# Template Helpers
# ===================================================================

# Copy template file to project
# Usage: copy_template "root/.gitignore" "/project/.gitignore"
copy_template() {
    local template_path="$1"
    local dest_path="$2"

    local full_template="${TEMPLATES_DIR}/${template_path}"

    if [[ ! -f "$full_template" ]]; then
        log_error "Template not found: $template_path"
        return 1
    fi

    safe_copy "$full_template" "$dest_path"
}

# Copy template directory to project
# Usage: copy_template_dir ".vscode" "/project/.vscode"
copy_template_dir() {
    local template_dir="$1"
    local dest_dir="$2"

    local full_template="${TEMPLATES_DIR}/${template_dir}"

    if [[ ! -d "$full_template" ]]; then
        log_error "Template directory not found: $template_dir"
        return 1
    fi

    ensure_dir "$dest_dir"

    if cp -r "${full_template}/"* "$dest_dir/"; then
        log_success "Copied: $template_dir"
        return 0
    else
        log_error "Failed to copy: $template_dir"
        return 1
    fi
}

# ===================================================================
# Utility Functions
# ===================================================================

# Check if running in CI/CD environment
is_ci() {
    [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]
}

# Get current timestamp
timestamp() {
    date +%Y-%m-%dT%H:%M:%S
}

# Confirm action (unless --yes flag or auto-approved)
# Usage: confirm "Delete file?" || exit 0
confirm() {
    local prompt="$1"
    local default="${2:-N}"

    # Skip if --yes flag or CI
    [[ "${BOOTSTRAP_YES:-false}" == "true" ]] && return 0
    is_ci && return 0

    local yn_prompt="(y/N)"
    [[ "$default" == "Y" ]] && yn_prompt="(Y/n)"

    echo -e -n "${YELLOW}→${NC} ${prompt} ${yn_prompt}: "
    read -r response
    response="${response:-$default}"

    [[ "$response" =~ ^[Yy]$ ]]
}

# ===================================================================
# Progress Tracking (for post-run summary)
# ===================================================================

declare -a _BOOTSTRAP_CREATED_FILES=()
declare -a _BOOTSTRAP_SKIPPED_FILES=()
declare -a _BOOTSTRAP_WARNINGS=()

track_created() {
    _BOOTSTRAP_CREATED_FILES+=("$1")
}

track_skipped() {
    _BOOTSTRAP_SKIPPED_FILES+=("$1")
}

track_warning() {
    _BOOTSTRAP_WARNINGS+=("$1")
}

show_summary() {
    echo ""
    log_section "Summary"

    if [[ ${#_BOOTSTRAP_CREATED_FILES[@]} -gt 0 ]]; then
        echo -e "${GREEN}Created:${NC}"
        for f in "${_BOOTSTRAP_CREATED_FILES[@]}"; do
            echo "  ✓ $f"
        done
    fi

    if [[ ${#_BOOTSTRAP_SKIPPED_FILES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Skipped (already exist):${NC}"
        for f in "${_BOOTSTRAP_SKIPPED_FILES[@]}"; do
            echo "  ⚠ $f"
        done
    fi

    if [[ ${#_BOOTSTRAP_WARNINGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Warnings:${NC}"
        for w in "${_BOOTSTRAP_WARNINGS[@]}"; do
            echo "  ⚠ $w"
        done
    fi

    echo ""
}

# ===================================================================
# File Logging (Centralized Bootstrap Log)
# ===================================================================

# Get log file path
get_log_file() {
    echo "${BOOTSTRAP_LOG:-${BOOTSTRAP_DIR:-$(pwd)}/bootstrap.log}"
}

# Log to file (append-only, non-verbose)
# Usage: log_to_file "bootstrap-git" "Created .gitignore"
log_to_file() {
    local script_name="$1"
    local message="$2"
    local log_file="$(get_log_file)"

    # Create log file if it doesn't exist
    if [[ ! -f "$log_file" ]]; then
        echo "# Bootstrap Log" > "$log_file"
        echo "# Started: $(timestamp)" >> "$log_file"
        echo "" >> "$log_file"
    fi

    # Append log entry: [timestamp] script_name: message
    echo "[$(timestamp)] ${script_name}: ${message}" >> "$log_file"
}

# Log file creation to central log
# Usage: log_file_created "bootstrap-git" ".gitignore"
log_file_created() {
    local script_name="$1"
    local file_name="$2"
    log_to_file "$script_name" "Created: $file_name"
}

# Log directory creation to central log
# Usage: log_dir_created "bootstrap-typescript" "src/"
log_dir_created() {
    local script_name="$1"
    local dir_name="$2"
    log_to_file "$script_name" "Created directory: $dir_name"
}

# Log script completion and create completion marker
# Usage: log_script_complete "bootstrap-git" "3 files created"
log_script_complete() {
    local script_name="$1"
    local summary="$2"
    log_to_file "$script_name" "✓ Complete: $summary"
    echo "" >> "$(get_log_file)"  # Add blank line after script

    # Create completion marker for dependency tracking
    local marker_dir="${BOOTSTRAP_DIR}/logs"
    ensure_dir "$marker_dir"
    touch "${marker_dir}/.${script_name}.completed"
    log_debug "Created completion marker: ${script_name}"
}

# Log script failure
# Usage: log_script_failed "bootstrap-git" "Failed to create .gitignore"
log_script_failed() {
    local script_name="$1"
    local error="$2"
    log_to_file "$script_name" "✗ FAILED: $error"
    echo "" >> "$(get_log_file)"
}

# Show log file location
show_log_location() {
    local log_file="$(get_log_file)"
    if [[ -f "$log_file" ]]; then
        log_info "Full log: $log_file"
    fi
}

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

# Show what the script will do and ask for confirmation
# Usage: pre_execution_confirm "bootstrap-git" "Git configuration" ".gitignore .gitattributes"
pre_execution_confirm() {
    local script_name="$1"
    local description="$2"
    shift 2
    local files=("$@")

    echo ""
    log_section "$description"
    echo ""
    echo -e "${BLUE}This script will create:${NC}"
    for file in "${files[@]}"; do
        echo "  • $file"
    done
    echo ""

    # Show satisfied dependencies (if any were declared)
    if [[ ${#_REQUIRED_TOOLS[@]} -gt 0 ]] || [[ ${#_REQUIRED_SCRIPTS[@]} -gt 0 ]]; then
        echo -e "${GREEN}Dependencies satisfied:${NC}"

        if [[ ${#_REQUIRED_TOOLS[@]} -gt 0 ]]; then
            echo "  Tools: ${_REQUIRED_TOOLS[*]}"
        fi

        if [[ ${#_REQUIRED_SCRIPTS[@]} -gt 0 ]]; then
            echo "  Scripts: ${_REQUIRED_SCRIPTS[*]}"
        fi

        echo ""
    fi

    # Auto-approve in CI or with --yes flag
    if is_ci || [[ "${BOOTSTRAP_YES:-false}" == "true" ]]; then
        log_info "Auto-approved (CI or --yes flag)"
        return 0
    fi

    # Ask for confirmation
    if ! confirm "Proceed with $description?" "Y"; then
        log_warning "Cancelled by user"
        log_script_failed "$script_name" "User cancelled"
        exit 0
    fi

    log_to_file "$script_name" "Started (user confirmed)"
    echo ""
}

# ===================================================================
# TODO Placeholders (implement later)
# ===================================================================

# TODO: Implement rollback functionality
# rollback_session() {
#     log_warning "Rollback not yet implemented"
# }
