#!/bin/bash

# ===================================================================
# bootstrap-menu.sh
#
# Main entry point for the bootstrap system.
# Launches helper in background, shows interactive menu,
# supports profiles and batch execution.
#
# USAGE:
#   ./bootstrap-menu.sh                    # Interactive menu
#   ./bootstrap-menu.sh --profile=standard # Run profile
#   ./bootstrap-menu.sh --phase=1 -y       # Run phase 1, auto-yes
#   ./bootstrap-menu.sh --list             # List scripts
#   ./bootstrap-menu.sh --status           # Show detected status
# ===================================================================

set -euo pipefail

# ===================================================================
# Paths and Setup
# ===================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Source libraries
source "${BOOTSTRAP_DIR}/lib/common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Configuration file
BOOTSTRAP_CONFIG="${BOOTSTRAP_DIR}/config/bootstrap.config"
STATUS_FILE="${BOOTSTRAP_DIR}/config/.helper-status"
ANSWERS_FILE=".bootstrap-answers.env"

# ===================================================================
# CLI Flags
# ===================================================================
INTERACTIVE_MODE=false
AUTO_YES=false
DRY_RUN=false
PROFILE=""
PHASE=""
PROJECT_ROOT="."
SHOW_STATUS=false
SHOW_LIST=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --interactive|-i)
            INTERACTIVE_MODE=true
            shift
            ;;
        --yes|-y)
            AUTO_YES=true
            export BOOTSTRAP_YES=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --profile=*)
            PROFILE="${1#*=}"
            shift
            ;;
        --profile)
            PROFILE="${2:-standard}"
            shift 2
            ;;
        --phase=*)
            PHASE="${1#*=}"
            shift
            ;;
        --phase)
            PHASE="${2:-1}"
            shift 2
            ;;
        --status)
            SHOW_STATUS=true
            shift
            ;;
        --list)
            SHOW_LIST=true
            shift
            ;;
        --project=*)
            PROJECT_ROOT="${1#*=}"
            shift
            ;;
        --help|-h)
            cat <<EOF
Bootstrap Menu - Project Setup System

USAGE:
    ${SCRIPT_NAME} [OPTIONS] [PROJECT_PATH]

OPTIONS:
    --interactive, -i    Enable Q&A customization mode
    --yes, -y            Skip all confirmations
    --dry-run            Show what would run without executing
    --profile=NAME       Run predefined profile (minimal|standard|full|api|frontend|library)
    --phase=N            Run all scripts in phase N (1-4)
    --status             Show detected environment status
    --list               List all available scripts and exit
    --project=PATH       Target project directory (default: current)
    --help, -h           Show this help message

PROFILES:
    minimal      claude, git, packages
    standard     claude, git, vscode, packages, typescript, environment, linting, editor
    full         All scripts including docker, testing, github
    api          Backend-focused: no vscode/editor
    frontend     Frontend-focused: no docker/testing
    library      Library-focused: minimal + linting + testing

EXAMPLES:
    ${SCRIPT_NAME}                           # Interactive menu
    ${SCRIPT_NAME} --profile=standard -y     # Run standard profile, auto-yes
    ${SCRIPT_NAME} --phase=1 -y ./my-app     # Bootstrap phase 1 into ./my-app
    ${SCRIPT_NAME} --status                  # Check environment

EOF
            exit 0
            ;;
        *)
            if [[ -d "$1" ]]; then
                PROJECT_ROOT="$1"
            else
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

# ===================================================================
# Launch Helper in Background
# ===================================================================
launch_helper() {
    local helper_script="${SCRIPT_DIR}/bootstrap-helper.sh"

    if [[ -f "$helper_script" ]]; then
        chmod +x "$helper_script" 2>/dev/null || true
        # Run in background, capture output to status file
        bash "$helper_script" "$PROJECT_ROOT" &
        HELPER_PID=$!
        log_debug "Launched helper (PID: $HELPER_PID)"
    fi
}

# Wait for helper to complete (with timeout)
wait_for_helper() {
    local timeout=3
    local elapsed=0

    while [[ ! -f "$STATUS_FILE" ]] && [[ $elapsed -lt $timeout ]]; do
        sleep 0.1
        elapsed=$((elapsed + 1))
    done

    # Kill helper if still running after timeout
    [[ -n "${HELPER_PID:-}" ]] && kill "$HELPER_PID" 2>/dev/null || true
}

# Read helper status
read_helper_status() {
    if [[ -f "$STATUS_FILE" ]]; then
        source "$STATUS_FILE"
    fi
}

# ===================================================================
# Script Definitions
# ===================================================================
declare -a PHASE1_SCRIPTS=(
    "bootstrap-claude.sh"
    "bootstrap-git.sh"
    "bootstrap-vscode.sh"
    "bootstrap-codex.sh"
    "bootstrap-packages.sh"
    "bootstrap-typescript.sh"
    "bootstrap-environment.sh"
)

declare -a PHASE2_SCRIPTS=(
    "bootstrap-docker.sh"
    "bootstrap-linting.sh"
    "bootstrap-editor.sh"
)

declare -a PHASE3_SCRIPTS=(
    "bootstrap-testing.sh"
)

declare -a PHASE4_SCRIPTS=(
    "bootstrap-github.sh"
    "bootstrap-devcontainer.sh"
    "bootstrap-documentation.sh"
)

# All scripts in order
declare -a ALL_SCRIPTS=(
    "${PHASE1_SCRIPTS[@]}"
    "${PHASE2_SCRIPTS[@]}"
    "${PHASE3_SCRIPTS[@]}"
    "${PHASE4_SCRIPTS[@]}"
)

# ===================================================================
# Profile Handling
# ===================================================================
get_profile_scripts() {
    local profile="$1"

    # Read from config file if available
    local profile_scripts=$(config_get "profiles.${profile}" "" "$BOOTSTRAP_CONFIG")

    if [[ -n "$profile_scripts" ]]; then
        # Convert comma-separated to array format
        echo "$profile_scripts" | tr ',' ' '
    else
        # Fallback defaults
        case "$profile" in
            minimal)
                echo "claude git packages"
                ;;
            standard)
                echo "claude git vscode packages typescript environment linting editor"
                ;;
            full)
                echo "claude git vscode codex packages typescript environment docker linting editor testing github"
                ;;
            api)
                echo "claude git packages typescript environment docker testing"
                ;;
            frontend)
                echo "claude git vscode packages typescript linting editor"
                ;;
            library)
                echo "claude git packages typescript linting testing"
                ;;
            *)
                log_error "Unknown profile: $profile"
                return 1
                ;;
        esac
    fi
}

# Convert short name to script name
to_script_name() {
    local short="$1"
    echo "bootstrap-${short}.sh"
}

# ===================================================================
# Script Execution
# ===================================================================
script_exists() {
    local script="$1"
    [[ -f "${SCRIPT_DIR}/${script}" ]]
}

run_script() {
    local script="$1"
    local script_path="${SCRIPT_DIR}/${script}"

    if [[ ! -f "$script_path" ]]; then
        log_warning "Script not found: $script"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would run: $script"
        return 0
    fi

    # Make executable if needed
    [[ ! -x "$script_path" ]] && chmod +x "$script_path"

    log_info "Running: $script"
    echo ""

    if bash "$script_path" "$PROJECT_ROOT"; then
        log_success "$script completed"
        ((SCRIPTS_RUN++))
        return 0
    else
        local exit_code=$?
        log_error "$script failed (exit code: $exit_code)"
        ((SCRIPTS_FAILED++))
        return $exit_code
    fi
}

# ===================================================================
# Session Tracking
# ===================================================================
SCRIPTS_RUN=0
SCRIPTS_FAILED=0
SCRIPTS_SKIPPED=0

show_session_summary() {
    if [[ $SCRIPTS_RUN -gt 0 || $SCRIPTS_FAILED -gt 0 ]]; then
        echo ""
        log_section "Session Summary"
        echo "  Scripts run:     $SCRIPTS_RUN"
        echo "  Scripts failed:  $SCRIPTS_FAILED"
        echo "  Scripts skipped: $SCRIPTS_SKIPPED"
        echo ""
    fi
}

# ===================================================================
# Display Functions
# ===================================================================
show_status() {
    read_helper_status

    log_section "Environment Status"

    echo -e "${BLUE}Tools:${NC}"
    echo "  ${TOOLS_STATUS:-not detected}"
    echo ""
    echo -e "${BLUE}Project:${NC}"
    echo "  ${PROJECT_STATUS:-not detected}"
    echo ""
    echo -e "${BLUE}Health:${NC}"
    if [[ "${HEALTH_STATUS:-}" == "healthy" ]]; then
        echo -e "  ${GREEN}✓ All checks passed${NC}"
    else
        echo -e "  ${YELLOW}⚠ Issues: ${HEALTH_STATUS:-unknown}${NC}"
    fi
    echo ""
    echo -e "${BLUE}Project Name:${NC} ${PROJECT_NAME:-unknown}"
    echo ""
}

show_list() {
    log_section "Available Bootstrap Scripts"

    local counter=1
    echo -e "${RED}Phase 1: AI Development Toolkit${NC}"
    for script in "${PHASE1_SCRIPTS[@]}"; do
        local status="✓"
        script_exists "$script" || status="○"
        echo "  $counter. [$status] $script"
        ((counter++))
    done

    echo ""
    echo -e "${RED}Phase 2: Infrastructure${NC}"
    for script in "${PHASE2_SCRIPTS[@]}"; do
        local status="✓"
        script_exists "$script" || status="○"
        echo "  $counter. [$status] $script"
        ((counter++))
    done

    echo ""
    echo -e "${YELLOW}Phase 3: Testing & Quality${NC}"
    for script in "${PHASE3_SCRIPTS[@]}"; do
        local status="✓"
        script_exists "$script" || status="○"
        echo "  $counter. [$status] $script"
        ((counter++))
    done

    echo ""
    echo -e "${GREEN}Phase 4: CI/CD & Deployment${NC}"
    for script in "${PHASE4_SCRIPTS[@]}"; do
        local status="✓"
        script_exists "$script" || status="○"
        echo "  $counter. [$status] $script"
        ((counter++))
    done

    echo ""
    echo "Legend: ✓ = available, ○ = coming soon"
    echo ""
}

display_menu() {
    read_helper_status

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   Bootstrap Menu - ${PROJECT_NAME:-Project} Setup${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

    # Show mode indicators
    local modes=""
    [[ "$INTERACTIVE_MODE" == "true" ]] && modes+="${GREEN}[Interactive]${NC} "
    [[ "$AUTO_YES" == "true" ]] && modes+="${YELLOW}[Auto-Yes]${NC} "
    [[ "$DRY_RUN" == "true" ]] && modes+="${GREY}[Dry-Run]${NC} "
    [[ -n "$modes" ]] && echo -e "   $modes"

    # Show health status
    if [[ "${HEALTH_STATUS:-}" == "healthy" ]]; then
        echo -e "   ${GREEN}✓ Environment ready${NC}"
    elif [[ -n "${HEALTH_STATUS:-}" ]]; then
        echo -e "   ${YELLOW}⚠ ${HEALTH_STATUS}${NC}"
    fi

    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""

    local counter=1

    # Phase 1
    echo -e "${RED}🔴 PHASE 1: AI Development Toolkit (FIRST)${NC}"
    echo -e "${RED}────────────────────────────────────────────${NC}"
    for script in "${PHASE1_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            echo -e "  ${GREEN}$counter.${NC} $script"
        else
            echo -e "  ${GREY}$counter. $script (coming soon)${NC}"
        fi
        ((counter++))
    done
    echo ""

    # Phase 2
    echo -e "${RED}🔴 PHASE 2: Infrastructure${NC}"
    echo -e "${RED}────────────────────────────────────────────${NC}"
    for script in "${PHASE2_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            echo -e "  ${GREEN}$counter.${NC} $script"
        else
            echo -e "  ${GREY}$counter. $script (coming soon)${NC}"
        fi
        ((counter++))
    done
    echo ""

    # Phase 3
    echo -e "${YELLOW}🟡 PHASE 3: Testing & Quality${NC}"
    echo -e "${YELLOW}────────────────────────────────${NC}"
    for script in "${PHASE3_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            echo -e "  ${GREEN}$counter.${NC} $script"
        else
            echo -e "  ${GREY}$counter. $script (coming soon)${NC}"
        fi
        ((counter++))
    done
    echo ""

    # Phase 4
    echo -e "${GREEN}🟢 PHASE 4: CI/CD & Deployment (Optional)${NC}"
    echo -e "${GREEN}──────────────────────────────────────────${NC}"
    for script in "${PHASE4_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            echo -e "  ${GREEN}$counter.${NC} $script"
        else
            echo -e "  ${GREY}$counter. $script (coming soon)${NC}"
        fi
        ((counter++))
    done
    echo ""

    echo -e "${YELLOW}Commands:${NC}"
    echo "  1-14     Run script by number"
    echo "  p1-p4    Run entire phase"
    echo "  h        Help"
    echo "  s        Status"
    echo "  q        Quit"
    echo ""
}

# ===================================================================
# Menu Loop
# ===================================================================
run_menu() {
    local total_scripts=${#ALL_SCRIPTS[@]}

    display_menu

    while true; do
        read -p "Selection: " -r choice || continue

        case "$choice" in
            ""|" ")
                continue
                ;;
            h|H|\?)
                echo ""
                echo "Commands:"
                echo "  1-$total_scripts  Run specific script"
                echo "  p1        Run Phase 1 (AI toolkit)"
                echo "  p2        Run Phase 2 (Infrastructure)"
                echo "  p3        Run Phase 3 (Testing)"
                echo "  p4        Run Phase 4 (CI/CD)"
                echo "  all       Run all available scripts"
                echo "  s         Show environment status"
                echo "  c         Show config"
                echo "  q/x       Exit"
                echo ""
                ;;
            q|Q|x|X)
                show_session_summary
                exit 0
                ;;
            s|S)
                show_status
                ;;
            c|C)
                config_show "$BOOTSTRAP_CONFIG"
                ;;
            p1|P1)
                log_info "Running Phase 1..."
                for script in "${PHASE1_SCRIPTS[@]}"; do
                    script_exists "$script" && run_script "$script"
                done
                show_session_summary
                ;;
            p2|P2)
                log_info "Running Phase 2..."
                for script in "${PHASE2_SCRIPTS[@]}"; do
                    script_exists "$script" && run_script "$script"
                done
                show_session_summary
                ;;
            p3|P3)
                log_info "Running Phase 3..."
                for script in "${PHASE3_SCRIPTS[@]}"; do
                    script_exists "$script" && run_script "$script"
                done
                show_session_summary
                ;;
            p4|P4)
                log_info "Running Phase 4..."
                for script in "${PHASE4_SCRIPTS[@]}"; do
                    script_exists "$script" && run_script "$script"
                done
                show_session_summary
                ;;
            all|ALL)
                log_info "Running all scripts..."
                for script in "${ALL_SCRIPTS[@]}"; do
                    script_exists "$script" && run_script "$script"
                done
                show_session_summary
                ;;
            [0-9]|[0-9][0-9])
                if (( choice >= 1 && choice <= total_scripts )); then
                    local script="${ALL_SCRIPTS[$((choice-1))]}"
                    if script_exists "$script"; then
                        if [[ "$AUTO_YES" == "true" ]] || confirm "Run $script?"; then
                            run_script "$script"
                        else
                            ((SCRIPTS_SKIPPED++))
                        fi
                    else
                        log_warning "Script not available: $script"
                    fi
                else
                    log_error "Invalid number: $choice (1-$total_scripts)"
                fi
                ;;
            *)
                log_error "Unknown command: $choice"
                ;;
        esac

        echo ""
    done
}

# ===================================================================
# Main Entry Point
# ===================================================================
main() {
    # Ensure config exists
    ensure_config "$BOOTSTRAP_CONFIG" >/dev/null

    # Launch helper in background
    launch_helper

    # Handle special modes
    if [[ "$SHOW_STATUS" == "true" ]]; then
        wait_for_helper
        show_status
        exit 0
    fi

    if [[ "$SHOW_LIST" == "true" ]]; then
        show_list
        exit 0
    fi

    # Run profile if specified
    if [[ -n "$PROFILE" ]]; then
        wait_for_helper
        log_info "Running profile: $PROFILE"
        echo ""

        local scripts=$(get_profile_scripts "$PROFILE")
        for short_name in $scripts; do
            local script=$(to_script_name "$short_name")
            if script_exists "$script"; then
                run_script "$script"
            else
                log_warning "Skipping unavailable: $script"
                ((SCRIPTS_SKIPPED++))
            fi
        done

        show_session_summary
        exit 0
    fi

    # Run phase if specified
    if [[ -n "$PHASE" ]]; then
        wait_for_helper
        log_info "Running Phase $PHASE"
        echo ""

        local phase_var="PHASE${PHASE}_SCRIPTS[@]"
        for script in "${!phase_var}"; do
            if script_exists "$script"; then
                run_script "$script"
            fi
        done

        show_session_summary
        exit 0
    fi

    # Wait for helper before showing menu
    wait_for_helper

    # Interactive menu
    run_menu
}

# Cleanup on exit
cleanup() {
    [[ -f "$STATUS_FILE" ]] && rm -f "$STATUS_FILE"
    [[ -n "${HELPER_PID:-}" ]] && kill "$HELPER_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Run
main "$@"
