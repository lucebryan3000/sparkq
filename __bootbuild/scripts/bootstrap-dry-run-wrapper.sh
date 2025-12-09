#!/bin/bash

# ===================================================================
# bootstrap-dry-run-wrapper.sh
#
# Wrapper to enable dry-run mode for any bootstrap script without modifying the scripts
#
# USAGE:
#   ./bootstrap-dry-run-wrapper.sh <script> [args...]
#   ./bootstrap-dry-run-wrapper.sh ./bootstrap-menu.sh --profile=standard
#
# FEATURES:
#   - Intercepts file modification commands (mkdir, cp, mv, rm, sed, awk)
#   - Tracks proposed changes to temp file
#   - Generates comprehensive report at end
#   - Shows before/after diffs
#   - Supports --show-detailed-diff option
#
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common libraries
source "${BOOTSTRAP_DIR}/lib/common.sh" || exit 1
source "${BOOTSTRAP_DIR}/lib/paths.sh" || exit 1

# Temp file to track changes
DRY_RUN_LOG=$(mktemp /tmp/bootstrap-dry-run.XXXXXX)
trap "rm -f $DRY_RUN_LOG" EXIT

# Options
SHOW_DETAILED_DIFF=false

# ===================================================================
# Logging Functions
# ===================================================================

log_dry_run() {
    echo -e "${YELLOW}[DRY RUN]${NC} $1"
    echo "$1" >> "$DRY_RUN_LOG"
}

log_change() {
    local type="$1"
    local detail="$2"
    echo "$type|$detail" >> "$DRY_RUN_LOG"
}

# ===================================================================
# Command Interceptors
# ===================================================================

# Override mkdir to log instead of executing
dry_mkdir() {
    log_dry_run "Would create directory: $*"
    log_change "CREATE_DIR" "$*"
    return 0
}

# Override cp to log instead of executing
dry_cp() {
    local src="${@: -2:1}"
    local dst="${@: -1:1}"
    log_dry_run "Would copy: $src → $dst"
    log_change "COPY_FILE" "$src|$dst"

    if [[ "$SHOW_DETAILED_DIFF" == "true" ]] && [[ -f "$src" ]]; then
        log_dry_run "  Content preview (first 5 lines):"
        head -5 "$src" | sed 's/^/    /'
    fi
    return 0
}

# Override mv to log instead of executing
dry_mv() {
    local src="${@: -2:1}"
    local dst="${@: -1:1}"
    log_dry_run "Would move: $src → $dst"
    log_change "MOVE_FILE" "$src|$dst"
    return 0
}

# Override rm to log instead of executing
dry_rm() {
    log_dry_run "Would delete: $*"
    for file in "$@"; do
        [[ "$file" =~ ^- ]] && continue  # Skip flags
        log_change "DELETE_FILE" "$file"
    done
    return 0
}

# Override sed to log instead of executing
dry_sed() {
    local file=""
    local pattern=""

    # Parse sed arguments to extract file and pattern
    for arg in "$@"; do
        if [[ -f "$arg" ]]; then
            file="$arg"
        elif [[ ! "$arg" =~ ^- ]]; then
            pattern="$arg"
        fi
    done

    log_dry_run "Would modify file with sed: $file"
    log_change "MODIFY_FILE" "$file|sed $pattern"

    if [[ "$SHOW_DETAILED_DIFF" == "true" ]] && [[ -f "$file" ]]; then
        log_dry_run "  Current content (first 5 lines):"
        head -5 "$file" | sed 's/^/    /'
    fi
    return 0
}

# Override touch to log instead of executing
dry_touch() {
    log_dry_run "Would create/update file: $*"
    log_change "TOUCH_FILE" "$*"
    return 0
}

# Override tee to log instead of executing
dry_tee() {
    local file="$1"
    log_dry_run "Would write to file (via tee): $file"
    log_change "WRITE_FILE" "$file"
    return 0
}

# Override cat with redirect to log instead of executing
dry_cat_redirect() {
    log_dry_run "Would write to file (via cat redirect)"
    log_change "WRITE_FILE" "stdout_redirect"
    cat "$@"  # Still show output, just don't redirect
    return 0
}

# Override chmod to log instead of executing
dry_chmod() {
    local perms="$1"
    shift
    log_dry_run "Would change permissions ($perms): $*"
    for file in "$@"; do
        log_change "CHMOD_FILE" "$file|$perms"
    done
    return 0
}

# Override chown to log instead of executing
dry_chown() {
    local owner="$1"
    shift
    log_dry_run "Would change owner ($owner): $*"
    for file in "$@"; do
        log_change "CHOWN_FILE" "$file|$owner"
    done
    return 0
}

# ===================================================================
# Export Overrides
# ===================================================================

export_dry_run_functions() {
    export -f dry_mkdir
    export -f dry_cp
    export -f dry_mv
    export -f dry_rm
    export -f dry_sed
    export -f dry_touch
    export -f dry_tee
    export -f dry_cat_redirect
    export -f dry_chmod
    export -f dry_chown
    export -f log_dry_run
    export -f log_change

    # Create aliases for intercepted commands
    alias mkdir='dry_mkdir'
    alias cp='dry_cp'
    alias mv='dry_mv'
    alias rm='dry_rm'
    alias sed='dry_sed'
    alias touch='dry_touch'
    alias tee='dry_tee'
    alias chmod='dry_chmod'
    alias chown='dry_chown'

    export DRY_RUN_LOG
    export SHOW_DETAILED_DIFF
}

# ===================================================================
# Report Generation
# ===================================================================

generate_summary_report() {
    echo ""
    log_section "Dry Run Summary"
    echo ""

    # Safe counter helper to avoid empty/duplicated output under set -euo
    _count_changes() {
        local type="$1"
        if [[ ! -f "$DRY_RUN_LOG" ]]; then
            echo 0
            return
        fi
        local cnt
        cnt=$(grep -c "^${type}|" "$DRY_RUN_LOG" 2>/dev/null || true)
        echo "${cnt:-0}"
    }

    # Count changes by type
    local create_dirs=$(_count_changes "CREATE_DIR")
    local copy_files=$(_count_changes "COPY_FILE")
    local move_files=$(_count_changes "MOVE_FILE")
    local delete_files=$(_count_changes "DELETE_FILE")
    local modify_files=$(_count_changes "MODIFY_FILE")
    local touch_files=$(_count_changes "TOUCH_FILE")
    local write_files=$(_count_changes "WRITE_FILE")
    local chmod_files=$(_count_changes "CHMOD_FILE")
    local chown_files=$(_count_changes "CHOWN_FILE")

    local total=$((create_dirs + copy_files + move_files + delete_files + modify_files + touch_files + write_files + chmod_files + chown_files))

    echo -e "${BLUE}Total proposed changes: ${BOLD}${total}${NC}"
    echo ""

    [[ $create_dirs -gt 0 ]] && echo -e "  ${GREEN}+${NC} Create directories: $create_dirs"
    [[ $copy_files -gt 0 ]] && echo -e "  ${GREEN}+${NC} Copy files: $copy_files"
    [[ $move_files -gt 0 ]] && echo -e "  ${YELLOW}→${NC} Move files: $move_files"
    [[ $delete_files -gt 0 ]] && echo -e "  ${RED}-${NC} Delete files: $delete_files"
    [[ $modify_files -gt 0 ]] && echo -e "  ${YELLOW}~${NC} Modify files: $modify_files"
    [[ $touch_files -gt 0 ]] && echo -e "  ${GREEN}+${NC} Touch files: $touch_files"
    [[ $write_files -gt 0 ]] && echo -e "  ${GREEN}+${NC} Write files: $write_files"
    [[ $chmod_files -gt 0 ]] && echo -e "  ${BLUE}⚙${NC} Change permissions: $chmod_files"
    [[ $chown_files -gt 0 ]] && echo -e "  ${BLUE}⚙${NC} Change ownership: $chown_files"

    echo ""

    # Show details by category
    if [[ $create_dirs -gt 0 ]]; then
        echo -e "${GREEN}Directories to create:${NC}"
        grep "^CREATE_DIR|" "$DRY_RUN_LOG" | cut -d'|' -f2 | sed 's/^/  • /'
        echo ""
    fi

    if [[ $copy_files -gt 0 ]]; then
        echo -e "${GREEN}Files to copy:${NC}"
        grep "^COPY_FILE|" "$DRY_RUN_LOG" | cut -d'|' -f2 | sed 's/|/ → /g' | sed 's/^/  • /'
        echo ""
    fi

    if [[ $move_files -gt 0 ]]; then
        echo -e "${YELLOW}Files to move:${NC}"
        grep "^MOVE_FILE|" "$DRY_RUN_LOG" | cut -d'|' -f2 | sed 's/|/ → /g' | sed 's/^/  • /'
        echo ""
    fi

    if [[ $delete_files -gt 0 ]]; then
        echo -e "${RED}Files to delete:${NC}"
        grep "^DELETE_FILE|" "$DRY_RUN_LOG" | cut -d'|' -f2 | sed 's/^/  • /'
        echo ""
    fi

    if [[ $modify_files -gt 0 ]]; then
        echo -e "${YELLOW}Files to modify:${NC}"
        grep "^MODIFY_FILE|" "$DRY_RUN_LOG" | cut -d'|' -f2 | sed 's/|/ (via /g' | sed 's/$/)/' | sed 's/^/  • /'
        echo ""
    fi

    if [[ $write_files -gt 0 ]]; then
        echo -e "${GREEN}Files to write:${NC}"
        grep "^WRITE_FILE|" "$DRY_RUN_LOG" | cut -d'|' -f2 | sed 's/^/  • /'
        echo ""
    fi

    if [[ $chmod_files -gt 0 ]]; then
        echo -e "${BLUE}Permission changes:${NC}"
        grep "^CHMOD_FILE|" "$DRY_RUN_LOG" | cut -d'|' -f2- | sed 's/|/ → /g' | sed 's/^/  • /'
        echo ""
    fi

    if [[ $chown_files -gt 0 ]]; then
        echo -e "${BLUE}Ownership changes:${NC}"
        grep "^CHOWN_FILE|" "$DRY_RUN_LOG" | cut -d'|' -f2- | sed 's/|/ → /g' | sed 's/^/  • /'
        echo ""
    fi

    # Impact assessment
    echo -e "${BLUE}Impact Assessment:${NC}"
    if [[ $delete_files -gt 0 ]]; then
        echo -e "  ${RED}⚠${NC} DESTRUCTIVE: $delete_files file(s) will be deleted"
    fi
    if [[ $modify_files -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} MODIFYING: $modify_files file(s) will be changed"
    fi
    if [[ $total -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} No changes would be made"
    elif [[ $delete_files -eq 0 ]] && [[ $modify_files -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} All changes are non-destructive (creates only)"
    fi

    echo ""

    # Rollback plan
    if [[ $total -gt 0 ]]; then
        echo -e "${BLUE}Rollback Plan:${NC}"
        if [[ $create_dirs -gt 0 ]] || [[ $copy_files -gt 0 ]] || [[ $touch_files -gt 0 ]] || [[ $write_files -gt 0 ]]; then
            echo "  • Created files/dirs can be removed with:"
            echo "    rm -rf <created_path>"
        fi
        if [[ $modify_files -gt 0 ]]; then
            echo "  • Modified files should be backed up before actual run"
            echo "    Recommendation: Add --backup flag to script"
        fi
        if [[ $delete_files -gt 0 ]]; then
            echo "  • Deleted files cannot be recovered"
            echo "    Recommendation: Move to trash instead of delete"
        fi
        echo ""
    fi

    echo -e "${GREY}Note: This was a dry run. No actual changes were made.${NC}"
    echo -e "${GREY}To execute changes, run the script without this wrapper.${NC}"
    echo ""
}

# ===================================================================
# Main Execution
# ===================================================================

usage() {
    cat << EOF
Usage: bootstrap-dry-run-wrapper.sh [OPTIONS] <script> [script-args...]

Enable dry-run mode for any bootstrap script without modifying the script.

OPTIONS:
  --show-detailed-diff    Show content previews for file operations
  -h, --help             Show this help message

EXAMPLES:
  # Dry run bootstrap menu with standard profile
  bootstrap-dry-run-wrapper.sh ./bootstrap-menu.sh --profile=standard

  # Dry run kb sync with detailed diff
  bootstrap-dry-run-wrapper.sh --show-detailed-diff ./bootstrap-kb-sync.sh

  # Dry run manifest generation
  bootstrap-dry-run-wrapper.sh ./bootstrap-manifest-gen.sh --force

EOF
    exit 0
}

main() {
    # Parse wrapper options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --show-detailed-diff)
                SHOW_DETAILED_DIFF=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                break
                ;;
        esac
    done

    # Check if script is provided
    if [[ $# -eq 0 ]]; then
        log_error "No script provided"
        usage
    fi

    local target_script="$1"
    shift

    # Validate target script exists
    if [[ ! -f "$target_script" ]]; then
        log_error "Script not found: $target_script"
        exit 1
    fi

    if [[ ! -x "$target_script" ]]; then
        log_error "Script not executable: $target_script"
        exit 1
    fi

    # Display dry run header
    echo ""
    log_section "Dry Run Mode"
    echo ""
    log_info "Target script: $target_script"
    log_info "Script arguments: ${*:-none}"
    log_info "Detailed diff: $SHOW_DETAILED_DIFF"
    echo ""
    log_warning "This is a DRY RUN - no actual changes will be made"
    echo ""

    # Export dry run functions and aliases
    export_dry_run_functions

    # Set DRY_RUN environment variable for scripts that support it natively
    export DRY_RUN=true
    export BOOTSTRAP_DRY_RUN=true

    # Execute target script in a subshell with our interceptors
    (
        # Re-export functions in subshell
        export_dry_run_functions

        # Run the target script
        bash "$target_script" "$@" || true
    )

    # Generate and display summary report
    generate_summary_report

    # Cleanup
    rm -f "$DRY_RUN_LOG"
}

# Run main with all arguments
main "$@"
