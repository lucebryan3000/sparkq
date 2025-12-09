#!/bin/bash

# ===================================================================
# bootstrap-menu.sh
#
# Main entry point for the bootstrap system.
# Dynamic menu driven by bootstrap-manifest.json.
# Launches background scanning, supports profiles and Q&A mode.
#
# USAGE:
#   ./bootstrap-menu.sh                    # Interactive menu
#   ./bootstrap-menu.sh -i                 # With Q&A customization
#   ./bootstrap-menu.sh --profile=standard # Run profile
#   ./bootstrap-menu.sh --phase=1 -y       # Run phase 1, auto-yes
#   ./bootstrap-menu.sh --list             # List scripts
#   ./bootstrap-menu.sh --status           # Show detected status
#   ./bootstrap-menu.sh --scan             # Force rescan
#   ./bootstrap-menu.sh -h                 # Help
# ===================================================================

set -euo pipefail

# ===================================================================
# Version
# ===================================================================
MENU_VERSION="2.1.0"

# ===================================================================
# Paths and Setup
# ===================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Export for child scripts
export BOOTSTRAP_DIR

# Source lib/paths.sh first to initialize all paths
source "${BOOTSTRAP_DIR}/lib/paths.sh" || {
    echo "ERROR: Failed to source lib/paths.sh" >&2
    exit 1
}

# Source core libraries
source "${LIB_DIR}/common.sh" || exit 1
source "${LIB_DIR}/config-manager.sh" || exit 1
source "${LIB_DIR}/script-registry.sh" || exit 1

# Source optional libraries if they exist
[[ -f "${LIB_DIR}/question-engine.sh" ]] && source "${LIB_DIR}/question-engine.sh"
[[ -f "${LIB_DIR}/cache-manager.sh" ]] && source "${LIB_DIR}/cache-manager.sh"
[[ -f "${LIB_DIR}/ui-utils.sh" ]] && source "${LIB_DIR}/ui-utils.sh"
[[ -f "${LIB_DIR}/recommendation-engine.sh" ]] && source "${LIB_DIR}/recommendation-engine.sh"

[[ -f "${LIB_DIR}/preflight-checker.sh" ]] && source "${LIB_DIR}/preflight-checker.sh"
# Cache and status files
CACHE_DIR="${BOOTSTRAP_DIR}/.cache"
STATUS_FILE="${CACHE_DIR}/helper-status.json"
SCAN_CACHE="${CACHE_DIR}/menu-scan.json"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

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
FORCE_SCAN=false
SHOW_PROGRESS=true
SHOW_HELP=false
SKIP_PREFLIGHT=false
ENABLE_SUGGESTIONS=true

# ===================================================================
# Help Text
# ===================================================================
show_help() {
    cat << EOF
Bootstrap Menu v${MENU_VERSION} - Project Setup System

USAGE:
    ${SCRIPT_NAME} [OPTIONS] [PROJECT_PATH]

OPTIONS:
    -i, --interactive    Enable Q&A customization mode (asks questions before each script)
    -y, --yes            Skip all confirmations (auto-approve)
    --dry-run            Show what would run without executing
    --profile=NAME       Run predefined profile (minimal|standard|full|api|frontend|library)
    --phase=N            Run all scripts in phase N (1-4)
    --status             Show detected environment status
    --list               List all available scripts and exit
    --no-progress        Disable progress bars for multi-script operations
    --scan               Force rescan of scripts and refresh cache (updates manifest cache)
    --skip-preflight     Skip pre-flight dependency check before phase/profile execution
    --project=PATH       Target project directory (default: current)
    -h, --help           Show this help message
    -v, --version        Show version

PHASES:
    1  AI Development Toolkit
       Claude Code, Git, VS Code, packages, TypeScript, environment

    2  Infrastructure
       Docker, databases, secrets management

    3  Code Quality
       Linting, Husky hooks, testing, security scanning

    4  CI/CD & Deployment
       GitHub Actions, CI pipelines, Kubernetes, monitoring

PROFILES:
    minimal         Claude, Git, packages (bare minimum)
    standard        + VS Code, TypeScript, linting, editor integration
    full            + Docker, testing, security, GitHub Actions
    api             Backend-focused: Docker, database, testing
    frontend        Frontend-focused: VS Code, linting, editor
    library         NPM package: linting, testing, GitHub
    python-backend  Python backend: docker, database, testing, security
    python-cli      Python CLI: environment, testing, security, GitHub

MENU COMMANDS:
    1-N          Run script by number
    p1-p4        Run entire phase
    all          Run all available scripts
    v            Validation report (pre-flight check on Phase 1)
    hc           Health check (quick)
    t            Test suite
    s            Show environment status
    c            Show current config
    e            Edit config interactively
    sg           Toggle smart suggestions
    r            Refresh/rescan scripts
    h            Show help
    q            Quit

EXAMPLES:
    ${SCRIPT_NAME}                           # Interactive menu
    ${SCRIPT_NAME} -i                        # With Q&A for each script
    ${SCRIPT_NAME} --profile=standard -y     # Run standard profile, auto-yes
    ${SCRIPT_NAME} --phase=1 -y ./my-app     # Bootstrap phase 1 into ./my-app
    ${SCRIPT_NAME} --status                  # Check environment
    ${SCRIPT_NAME} --list                    # List all scripts

CONFIGURATION:
    Config file:    __bootbuild/config/bootstrap.config
    Manifest:       __bootbuild/config/bootstrap-manifest.json
    Questions:      __bootbuild/config/bootstrap-questions.json

For more information: https://github.com/your-repo/bootstrap

EOF
}

# ===================================================================
# Parse Arguments
# ===================================================================
parse_arguments() {
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
            --scan)
                FORCE_SCAN=true
                shift
                ;;
            --no-progress)
                SHOW_PROGRESS=false
                shift
                ;;
            --skip-preflight)
                SKIP_PREFLIGHT=true
                shift
                ;;
            --project=*)
                PROJECT_ROOT="${1#*=}"
                shift
                ;;
            --help|-h)
                SHOW_HELP=true
                shift
                ;;
            --version|-v)
                echo "Bootstrap Menu v${MENU_VERSION}"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [[ -d "$1" ]]; then
                    PROJECT_ROOT="$1"
                else
                    log_error "Unknown argument or invalid directory: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

normalize_project_root() {
    # Normalize PROJECT_ROOT to absolute path with validation
    if [[ -n "$PROJECT_ROOT" && -d "$PROJECT_ROOT" ]]; then
        PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)" || {
            log_fatal "Cannot access project directory: $PROJECT_ROOT"
        }
    elif [[ -n "$PROJECT_ROOT" ]]; then
        log_fatal "Project directory not found: $PROJECT_ROOT"
    else
        PROJECT_ROOT="$(pwd)"
    fi
    export PROJECT_ROOT
}

# ===================================================================
# Background Helper & Scanning
# ===================================================================
HELPER_PID=""

launch_background_scan() {
    # Run background tasks:
    # 1. Validate manifest cache
    # 2. Scan for new/missing scripts
    # 3. Quick environment detection

    (
        # Ensure cache directory
        mkdir -p "$CACHE_DIR"

        # Build script status object using jq
        local scripts_obj='{}'
        local -a VISIBLE_SCRIPTS=()
        mapfile -t VISIBLE_SCRIPTS < <(registry_get_visible_scripts)
        for script in "${VISIBLE_SCRIPTS[@]}"; do
            local status=$(registry_get_script_status "$script")
            local has_q="false"
            registry_has_questions "$script" && has_q="true"

            scripts_obj=$(jq --arg script "$script" --arg status "$status" --argjson has_q "$has_q" \
                '.[$script] = {status: $status, has_questions: $has_q}' <<< "$scripts_obj")
        done

        # Build new scripts array
        local new_scripts_array=()
        while IFS= read -r script; do
            [[ -n "$script" ]] && new_scripts_array+=("$script")
        done < <(registry_discover_new_scripts)

        # Build missing scripts array
        local missing_scripts_array=()
        while IFS= read -r script; do
            [[ -n "$script" ]] && missing_scripts_array+=("$script")
        done < <(registry_find_missing_scripts)

        # Construct final JSON using jq
        local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        local SCAN_CACHE_TMP="${SCAN_CACHE}.$$"

        # Handle empty arrays properly
        local new_scripts_json='[]'
        if [ ${#new_scripts_array[@]} -gt 0 ]; then
            new_scripts_json="$(printf '%s\n' "${new_scripts_array[@]}" | jq -Rs -s 'split("\n") | map(select(length > 0))')"
        fi

        local missing_scripts_json='[]'
        if [ ${#missing_scripts_array[@]} -gt 0 ]; then
            missing_scripts_json="$(printf '%s\n' "${missing_scripts_array[@]}" | jq -Rs -s 'split("\n") | map(select(length > 0))')"
        fi

        jq --arg timestamp "$timestamp" \
           --argjson scripts "$scripts_obj" \
           --argjson new_scripts "$new_scripts_json" \
           --argjson missing_scripts "$missing_scripts_json" \
           '{timestamp: $timestamp, scripts: $scripts, new_scripts: $new_scripts, missing_scripts: $missing_scripts}' \
           <<< 'null' > "${SCAN_CACHE}.$$" || return 1
        jq empty < "$SCAN_CACHE_TMP" || { rm "$SCAN_CACHE_TMP"; return 1; }
        mv "$SCAN_CACHE_TMP" "$SCAN_CACHE" || return 1

    ) &
    HELPER_PID=$!
}

wait_for_scan() {
    local elapsed=0
    local max_elapsed=300

    while [[ ! -f "$SCAN_CACHE" && $elapsed -lt $max_elapsed ]]; do
        sleep 0.1
        elapsed=$((elapsed + 1))
    done

    if [[ -n "${HELPER_PID:-}" ]] && kill -0 "$HELPER_PID" 2>/dev/null; then
        kill "$HELPER_PID" 2>/dev/null || true
    fi

    if [[ -f "$SCAN_CACHE" ]]; then
        return 0
    fi

    log_warning "Scan timeout after 30s" >&2
    return 124
}

read_scan_cache() {
    local attempts=0
    local max_attempts=2

    NEW_SCRIPTS_COUNT=0
    MISSING_SCRIPTS_COUNT=0

    command -v jq &>/dev/null || return

    while (( attempts < max_attempts )); do
        ((attempts++))

        if [[ -f "$SCAN_CACHE" ]]; then
            if jq empty < "$SCAN_CACHE" 2>/dev/null; then
                NEW_SCRIPTS_COUNT=$(jq -r '.new_scripts | length' "$SCAN_CACHE" 2>/dev/null || echo 0)
                MISSING_SCRIPTS_COUNT=$(jq -r '.missing_scripts | length' "$SCAN_CACHE" 2>/dev/null || echo 0)
                return
            fi

            rm -f "$SCAN_CACHE"
        fi

        launch_background_scan
        if ! wait_for_scan; then
            return
        fi
    done
}

# ===================================================================
# Script Execution
# ===================================================================
run_script() {
    local script_name="$1"
    local script_path=$(registry_get_script_path "$script_name")

    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        log_warning "Script not found: $script_name"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would run: bootstrap-${script_name}.sh"
        return 0
    fi

    # Run questions if interactive mode and script has questions
    if [[ "$INTERACTIVE_MODE" == "true" ]] && registry_has_questions "$script_name"; then
        local questions_key=$(registry_get_questions_key "$script_name")
        if type -t question_engine_run &>/dev/null; then
            log_info "Running Q&A for: $script_name"
            question_engine_run "$questions_key" || {
                log_warning "Q&A cancelled for $script_name"
                return 1
            }
        fi
    fi

    # Make executable if needed
    [[ ! -x "$script_path" ]] && chmod +x "$script_path"

    local desc=$(registry_get_script_field "$script_name" "description")
    log_info "Running: $script_name"
    [[ -n "$desc" ]] && echo -e "  ${GREY}$desc${NC}"
    echo ""

    bash "$script_path" "$PROJECT_ROOT"
    local SCRIPT_STATUS=$?

    if [[ $SCRIPT_STATUS -eq 0 ]]; then
        log_success "$script_name completed"
        ((SCRIPTS_RUN++))
        track_session_script "$script_name" "completed"

        # Suggest next scripts if enabled and function available
        if [[ "$ENABLE_SUGGESTIONS" == "true" ]] && type -t suggest_next_scripts &>/dev/null; then
            suggest_next_scripts "$script_name"
        fi

        return 0
    else
        log_error "$script_name failed (exit code: $SCRIPT_STATUS)"
        ((SCRIPTS_FAILED++))
        track_session_script "$script_name" "failed"
        return $SCRIPT_STATUS
    fi
}

run_phase() {
    local phase="$1"
    local FAILED_SCRIPTS=0

    if [[ -z "$phase" ]]; then
        log_error "Unknown phase"
        return 1
    fi

    # Pre-flight check
    if [[ "$SKIP_PREFLIGHT" != "true" ]] && type -t preflight_check_phase &>/dev/null; then
        if ! preflight_check_phase "$phase"; then
            log_error "Pre-flight check failed for phase $phase"
            return 1
        fi
        echo ""
    fi
    local phase_name=$(registry_get_phase_name "$phase")

    log_info "Running Phase $phase: $phase_name"
    echo ""

    # Count total scripts in phase
    local phase_scripts=($(registry_get_phase_scripts "$phase"))
    local total_scripts=${#phase_scripts[@]}
    local current=0
    local start_time=$(date +%s)

    for script in "${phase_scripts[@]}"; do
        if registry_script_file_exists "$script"; then
            # Show progress bar if enabled
            if [[ "$SHOW_PROGRESS" == "true" ]] && type -t show_progress_bar &>/dev/null; then
                show_progress_bar "$current" "$total_scripts" "Phase $phase"
            fi

            if run_script "$script"; then
                :
            else
                local exit_code=$?
                FAILED_SCRIPTS=$((FAILED_SCRIPTS + 1))
            fi
            ((current++))
        else
            log_warning "Skipping unavailable: $script"
            ((SCRIPTS_SKIPPED++))
            ((current++))
        fi
    done

    # Show final progress bar
    if [[ "$SHOW_PROGRESS" == "true" ]] && type -t show_progress_bar &>/dev/null; then
        show_progress_bar "$total_scripts" "$total_scripts" "Phase $phase"

        # Show completion time
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        if type -t format_duration &>/dev/null; then
            local formatted_duration=$(format_duration "$duration")
            log_success "Phase $phase completed in $formatted_duration"
        fi
    fi

    if [[ $FAILED_SCRIPTS -gt 0 ]]; then return 1; fi
}

run_profile() {
    local profile="$1"
    local FAILED_SCRIPTS=0

    if ! registry_profile_exists "$profile"; then
        log_error "Unknown profile: $profile"
        echo "Available profiles: $(registry_get_profiles | tr '\n' ' ')"
        return 1
    fi

    # Pre-flight check
    if [[ "$SKIP_PREFLIGHT" != "true" ]] && type -t preflight_check_profile &>/dev/null; then
        if ! preflight_check_profile "$profile"; then
            log_error "Pre-flight check failed for profile $profile"
            return 1
        fi
        echo ""
    fi

    local desc=$(registry_get_profile_description "$profile")
    log_info "Running profile: $profile"
    [[ -n "$desc" ]] && echo -e "  ${GREY}$desc${NC}"
    echo ""

    # Count total scripts in profile
    local profile_scripts=($(registry_get_profile_scripts "$profile"))
    local total_scripts=${#profile_scripts[@]}
    local current=0
    local start_time=$(date +%s)

    for script in "${profile_scripts[@]}"; do
        if registry_script_file_exists "$script"; then
            # Show progress bar if enabled
            if [[ "$SHOW_PROGRESS" == "true" ]] && type -t show_progress_bar &>/dev/null; then
                show_progress_bar "$current" "$total_scripts" "Profile: $profile"
            fi

            if run_script "$script"; then
                :
            else
                local exit_code=$?
                FAILED_SCRIPTS=$((FAILED_SCRIPTS + 1))
            fi
            ((current++))
        else
            log_warning "Skipping unavailable: $script"
            ((SCRIPTS_SKIPPED++))
            ((current++))
        fi
    done

    # Show final progress bar
    if [[ "$SHOW_PROGRESS" == "true" ]] && type -t show_progress_bar &>/dev/null; then
        show_progress_bar "$total_scripts" "$total_scripts" "Profile: $profile"

        # Show completion time
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        if type -t format_duration &>/dev/null; then
            local formatted_duration=$(format_duration "$duration")
            log_success "Profile '$profile' completed in $formatted_duration"
        fi
    fi

    if [[ $FAILED_SCRIPTS -gt 0 ]]; then return 1; fi
}

# ===================================================================
# Session Tracking
# ===================================================================
SCRIPTS_RUN=0
SCRIPTS_FAILED=0
SCRIPTS_SKIPPED=0

track_session_script() {
    local script="$1"
    local status="$2"

    # Update session in config if config-manager supports it
    if type -t config_append &>/dev/null; then
        config_append "session.scripts_${status}" "$script" "$BOOTSTRAP_CONFIG"
    fi
}

show_session_summary() {
    if [[ $SCRIPTS_RUN -gt 0 || $SCRIPTS_FAILED -gt 0 ]]; then
        echo ""
        log_section "Session Summary"
        echo "  Scripts run:     $SCRIPTS_RUN"
        echo "  Scripts failed:  $SCRIPTS_FAILED"
        echo "  Scripts skipped: $SCRIPTS_SKIPPED"
        echo ""

        # Prompt to save answers if interactive mode was used
        if [[ "$INTERACTIVE_MODE" == "true" && $SCRIPTS_RUN -gt 0 ]]; then
            if confirm "Save collected answers as defaults for future runs?" "Y"; then
                log_success "Answers saved to bootstrap.config"
            fi
        fi
    fi
}

# ===================================================================
# Config Preview (80% defaults shown before Q&A)
# ===================================================================
show_config_preview() {
    # Shows the 80% industry defaults from bootstrap.config
    # This helps developers understand what's pre-configured before they answer the 20% questions

    echo ""
    log_section "80% Industry Defaults (Pre-configured)"
    echo -e "${GREY}These settings use industry best practices. Press Enter to accept defaults.${NC}"
    echo ""

    # TypeScript
    echo -e "${BLUE}TypeScript${NC}"
    echo "  strict mode:     $(config_get "typescript.strict" "true" "$BOOTSTRAP_CONFIG")"
    echo "  target:          $(config_get "typescript.target" "ES2022" "$BOOTSTRAP_CONFIG")"
    echo "  module:          $(config_get "typescript.module" "ESNext" "$BOOTSTRAP_CONFIG")"
    echo ""

    # Prettier/Linting
    echo -e "${BLUE}Code Formatting (Prettier)${NC}"
    echo "  single quotes:   $(config_get "prettier.single_quote" "true" "$BOOTSTRAP_CONFIG")"
    echo "  semicolons:      $(config_get "prettier.semi" "false" "$BOOTSTRAP_CONFIG")"
    echo "  tab width:       $(config_get "prettier.tab_width" "2" "$BOOTSTRAP_CONFIG")"
    echo "  print width:     $(config_get "prettier.print_width" "100" "$BOOTSTRAP_CONFIG")"
    echo ""

    # Testing
    echo -e "${BLUE}Testing${NC}"
    echo "  coverage:        $(config_get "testing_defaults.coverage_threshold" "80" "$BOOTSTRAP_CONFIG")%"
    echo "  branch coverage: $(config_get "testing_defaults.branch_coverage" "70" "$BOOTSTRAP_CONFIG")%"
    echo ""

    # Ports (Docker)
    echo -e "${BLUE}Docker Ports${NC}"
    echo "  app port:        $(config_get "docker_defaults.app_port" "3000" "$BOOTSTRAP_CONFIG")"
    echo "  database port:   $(config_get "docker_defaults.database_port" "5432" "$BOOTSTRAP_CONFIG")"
    echo "  redis port:      $(config_get "docker_defaults.redis_port" "6379" "$BOOTSTRAP_CONFIG")"
    echo ""

    # Editor
    echo -e "${BLUE}Editor${NC}"
    echo "  indent style:    $(config_get "editor.indent_style" "space" "$BOOTSTRAP_CONFIG")"
    echo "  indent size:     $(config_get "editor.indent_size" "2" "$BOOTSTRAP_CONFIG")"
    echo "  line endings:    $(config_get "editor.end_of_line" "lf" "$BOOTSTRAP_CONFIG")"
    echo ""

    # Git
    echo -e "${BLUE}Git${NC}"
    echo "  default branch:  $(config_get "git.default_branch" "main" "$BOOTSTRAP_CONFIG")"
    echo "  node version:    $(config_get "nodejs.version" "20" "$BOOTSTRAP_CONFIG")"
    echo ""

    # Security
    echo -e "${BLUE}Security${NC}"
    echo "  npm audit:       $(config_get "security.npm_audit" "true" "$BOOTSTRAP_CONFIG")"
    echo "  audit level:     $(config_get "security.audit_level" "moderate" "$BOOTSTRAP_CONFIG")"
    echo ""

    echo -e "${GREY}These defaults are stored in __bootbuild/config/bootstrap.config${NC}"
    echo -e "${GREY}Edit the file directly to override defaults for all projects.${NC}"
    echo ""
}

show_questions_preview() {
    # Shows the 20% questions that will be asked
    echo ""
    log_section "20% Developer Decisions (You'll be asked)"
    echo -e "${GREY}These are the only questions you need to answer per project.${NC}"
    echo ""

    echo -e "${YELLOW}Quick Start:${NC}"
    echo "  • Project name         [$(config_get "project.name" "my-project" "$BOOTSTRAP_CONFIG")]"
    echo "  • Project description  [optional]"
    echo "  • Project phase        [POC/MVP/Production]"
    echo ""

    echo -e "${YELLOW}Technology Choices:${NC}"
    echo "  • Package manager      [$(config_get "packages.package_manager" "pnpm" "$BOOTSTRAP_CONFIG")]"
    echo "  • Enable Docker?       [$(config_get "docker.enabled" "true" "$BOOTSTRAP_CONFIG")]"
    echo "  • Database type        [$(config_get "docker.database_type" "postgres" "$BOOTSTRAP_CONFIG")]"
    echo "  • Testing framework    [$(config_get "testing.framework" "vitest" "$BOOTSTRAP_CONFIG")]"
    echo "  • E2E framework        [$(config_get "testing.e2e_framework" "playwright" "$BOOTSTRAP_CONFIG")]"
    echo "  • Enable Husky hooks?  [$(config_get "husky.enabled" "false" "$BOOTSTRAP_CONFIG")]"
    echo ""

    echo -e "${GREY}Press Enter to accept defaults shown in [brackets].${NC}"
    echo ""
}

# ===================================================================
# Submenu Functions
# ===================================================================
get_categories_for_phase() {
    local phase="$1"
    local -a PHASE_SCRIPTS=()
    mapfile -t PHASE_SCRIPTS < <(registry_get_phase_scripts "$phase")
    for script in "${PHASE_SCRIPTS[@]}"; do
        registry_get_script_field "$script" "category"
    done | sort | uniq
}

display_phase_menu() {
    local phase="$1"
    clear

    local phase_name=$(registry_get_phase_name "$phase")
    local phase_color=$(registry_get_phase_color "$phase")
    local color_code="$BLUE"
    case "$phase_color" in
        red) color_code="$RED" ;;
        yellow) color_code="$YELLOW" ;;
        green) color_code="$GREEN" ;;
    esac

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   Phase $phase: ${phase_name}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""

    local counter=0
    local -a categories=($(get_categories_for_phase "$phase"))

    for category in "${categories[@]}"; do
        counter=$((counter + 1))
        local scripts=""
        local script_count=0

        local -a PHASE_SCRIPTS=()
        mapfile -t PHASE_SCRIPTS < <(registry_get_phase_scripts "$phase")
        for script in "${PHASE_SCRIPTS[@]}"; do
            if [[ "$(registry_get_script_field "$script" "category")" == "$category" ]]; then
                if [[ -n "$scripts" ]]; then
                    scripts+=", "
                fi
                scripts+="$script"
                script_count=$((script_count + 1))
            fi
        done

        # Format category name (capitalize first letter of each word)
        local display_category=$(echo "$category" | sed 's/\b\(.\)/\u\1/g')
        # Show script names for this category
        echo -e "  ${GREEN}${counter}.${NC} ${display_category} (${script_count}) ${GREY}${scripts}${NC}"
    done

    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  1-${counter}   Select category"
    echo "  m         Main menu"
    echo "  q         Quit"
    echo ""
}

display_category_menu() {
    local phase="$1"
    local category="$2"
    clear

    local phase_name=$(registry_get_phase_name "$phase")
    local display_category=$(echo "$category" | sed 's/\b\(.\)/\u\1/g')

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   Phase $phase: ${display_category}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""

    local counter=0
    local -a scripts=()

    local -a PHASE_SCRIPTS=()
    mapfile -t PHASE_SCRIPTS < <(registry_get_phase_scripts "$phase")
    for script in "${PHASE_SCRIPTS[@]}"; do
        if [[ "$(registry_get_script_field "$script" "category")" == "$category" ]]; then
            counter=$((counter + 1))
            scripts+=("$script")

            local q_indicator=""
            registry_has_questions "$script" && q_indicator=" ${YELLOW}[Q]${NC}"
            local desc=$(registry_get_script_field "$script" "description")

            if registry_script_file_exists "$script"; then
                echo -e "  ${GREEN}${counter}.${NC} ${script}${q_indicator}"
                echo -e "       ${GREY}${desc:0:60}${NC}"
            else
                echo -e "  ${GREY}${counter}. ${script} (coming soon)${NC}"
                echo -e "       ${GREY}${desc:0:60}${NC}"
            fi
        fi
    done

    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  1-${counter}   Run script"
    echo "  b         Back to phase"
    echo "  m         Main menu"
    echo "  q         Quit"
    echo ""
}

run_phase_menu() {
    local phase="$1"
    local total_categories=$(get_categories_for_phase "$phase" | wc -l)

    while true; do
        display_phase_menu "$phase"
        read -p "Selection: " -r choice || continue

        [[ -z "$choice" || "$choice" == " " ]] && continue

        case "$choice" in
            m|M)
                return 0
                ;;
            q|Q|x|X)
                show_session_summary
                exit 0
                ;;
            [0-9]|[0-9][0-9])
                if [[ "$choice" -lt 1 || "$choice" -gt "$total_categories" ]]; then
                    log_error "Invalid selection: $choice (1-$total_categories)"
                    echo ""
                    sleep 1
                    continue
                fi

                local selected_category=$(get_categories_for_phase "$phase" | sed -n "${choice}p")
                run_category_menu "$phase" "$selected_category" || true
                ;;
            *)
                log_error "Unknown command: $choice"
                echo ""
                sleep 1
                ;;
        esac
    done
}

run_category_menu() {
    local phase="$1"
    local category="$2"
    local total_scripts=0

    local -a SCRIPTS=()
    mapfile -t SCRIPTS < <(registry_get_phase_scripts "$phase")
    for script in "${SCRIPTS[@]}"; do
        if [[ "$(registry_get_script_field "$script" "category")" == "$category" ]]; then
            total_scripts=$((total_scripts + 1))
        fi
    done

    while true; do
        display_category_menu "$phase" "$category"
        read -p "Selection: " -r choice || continue

        [[ -z "$choice" || "$choice" == " " ]] && continue

        case "$choice" in
            b|B)
                return 0
                ;;
            m|M)
                return 1
                ;;
            q|Q|x|X)
                show_session_summary
                exit 0
                ;;
            [0-9]|[0-9][0-9])
                if [[ "$choice" -lt 1 || "$choice" -gt "$total_scripts" ]]; then
                    log_error "Invalid selection: $choice (1-$total_scripts)"
                    echo ""
                    sleep 1
                    continue
                fi

                local selected_script=""
                local counter=0
                local -a SCRIPTS=()
                mapfile -t SCRIPTS < <(registry_get_phase_scripts "$phase")
                for script in "${SCRIPTS[@]}"; do
                    if [[ "$(registry_get_script_field "$script" "category")" == "$category" ]]; then
                        counter=$((counter + 1))
                        if [[ "$counter" -eq "$choice" ]]; then
                            selected_script="$script"
                            break
                        fi
                    fi
                done

                if [[ -n "$selected_script" ]]; then
                    if registry_script_file_exists "$selected_script"; then
                        local script_desc=$(registry_get_script_field "$selected_script" "description")
                        echo ""
                        echo -e "${BLUE}$selected_script${NC}"
                        echo "$script_desc"
                        echo ""

                        # Show additional metadata
                        local templates=$(registry_get_script_field "$selected_script" "templates")
                        local depends=$(registry_get_script_field "$selected_script" "depends")
                        local requires=$(registry_get_script_field "$selected_script" "requires")

                        if [[ -n "$templates" && "$templates" != "null" && "$templates" != "[]" ]]; then
                            echo -e "${GREY}Creates/Updates:${NC} $templates"
                        fi

                        if [[ -n "$depends" && "$depends" != "null" && "$depends" != "[]" ]]; then
                            echo -e "${GREY}Depends on:${NC} $depends"
                        fi

                        if [[ -n "$requires" && "$requires" != "null" ]]; then
                            echo -e "${GREY}Requires:${NC} $requires"
                        fi

                        local has_questions=$(registry_has_questions "$selected_script" && echo "true" || echo "false")
                        if [[ "$has_questions" == "true" ]]; then
                            echo -e "${YELLOW}[Q]${NC} This script will ask questions during execution"
                        fi

                        echo ""
                        if [[ "$AUTO_YES" == "true" ]]; then
                            run_script "$selected_script"
                        else
                            echo -e "${YELLOW}Options:${NC}"
                            echo "  [y] Run script (confirm)"
                            echo "  [d] Dry-run preview (see what will change)"
                            echo "  [n] Skip this script"
                            echo ""
                            read -p "Choice (y/d/n): " -r run_choice || run_choice="n"
                            run_choice=${run_choice,,}  # Convert to lowercase

                            case "$run_choice" in
                                y)
                                    log_section "Running: $selected_script"
                                    run_script "$selected_script"
                                    echo ""
                                    log_success "Script completed: $selected_script"
                                    echo ""
                                    read -p "Press Enter to continue..." || true
                                    ;;
                                d)
                                    log_section "Dry-Run Preview - $selected_script"
                                    if [[ ! -d "$SCRIPTS_DIR" ]]; then
                                        log_error "Scripts directory not found: $SCRIPTS_DIR"
                                    elif [[ -f "${SCRIPTS_DIR}/bootstrap-dry-run-wrapper.sh" ]]; then
                                        bash "${SCRIPTS_DIR}/bootstrap-dry-run-wrapper.sh" "${SCRIPTS_DIR}/bootstrap-${selected_script}.sh" || true
                                    else
                                        log_warning "Dry-run wrapper not found"
                                    fi
                                    echo ""
                                    read -p "Continue? (y/n): " -r continue_choice || continue_choice="n"
                                    continue_choice=${continue_choice,,}
                                    if [[ "$continue_choice" == "y" ]]; then
                                        log_section "Running: $selected_script"
                                        run_script "$selected_script"
                                        echo ""
                                        log_success "Script completed: $selected_script"
                                        echo ""
                                        read -p "Press Enter to continue..." || true
                                    else
                                        ((SCRIPTS_SKIPPED++))
                                    fi
                                    ;;
                                *)
                                    ((SCRIPTS_SKIPPED++))
                                    ;;
                            esac
                        fi
                    else
                        log_warning "Script not available: $selected_script"
                    fi
                fi
                echo ""
                sleep 0.5
                ;;
            *)
                log_error "Unknown command: $choice"
                echo ""
                sleep 1
                ;;
        esac
    done
}

# ===================================================================
# Display Functions
# ===================================================================
show_status() {
    read_scan_cache

    log_section "Environment Status"

    echo -e "${BLUE}Project:${NC}"
    echo "  Root: $PROJECT_ROOT"
    echo "  Name: $(config_get "project.name" "unknown" "$BOOTSTRAP_CONFIG")"
    echo ""

    echo -e "${BLUE}Detection:${NC}"
    echo "  Package.json: $(config_get "detected.has_package_json" "unknown" "$BOOTSTRAP_CONFIG")"
    echo "  Git repo:     $(config_get "detected.has_git_repo" "unknown" "$BOOTSTRAP_CONFIG")"
    echo "  TypeScript:   $(config_get "detected.has_tsconfig" "unknown" "$BOOTSTRAP_CONFIG")"
    echo "  Claude dir:   $(config_get "detected.has_claude_dir" "unknown" "$BOOTSTRAP_CONFIG")"
    echo ""

    echo -e "${BLUE}Scripts:${NC}"
    echo "  Total available:  $(registry_get_script_count)"
    echo "  New (unregistered): ${NEW_SCRIPTS_COUNT:-0}"
    echo "  Missing files:      ${MISSING_SCRIPTS_COUNT:-0}"
    echo ""

    echo -e "${BLUE}Last Detection:${NC}"
    echo "  $(config_get "detected.last_run" "never" "$BOOTSTRAP_CONFIG")"
    echo ""
}

show_list() {
    log_section "Available Bootstrap Scripts"

    local total=0

    local -a PHASES=()
    mapfile -t PHASES < <(registry_get_phases)
    for phase in "${PHASES[@]}"; do
        local phase_name=$(registry_get_phase_name "$phase")
        local phase_color=$(registry_get_phase_color "$phase")
        local count=$(registry_get_phase_count "$phase")

        # Set color
        local color_code="$BLUE"
        case "$phase_color" in
            red) color_code="$RED" ;;
            yellow) color_code="$YELLOW" ;;
            green) color_code="$GREEN" ;;
        esac

        echo ""
        echo -e "${color_code}Phase $phase: $phase_name ($count scripts)${NC}"
        echo -e "${color_code}$(printf '─%.0s' {1..50})${NC}"

        local -a SCRIPTS=()
        mapfile -t SCRIPTS < <(registry_get_phase_scripts "$phase")
        for script in "${SCRIPTS[@]}"; do
            total=$((total + 1))
            local status_icon="✓"
            local status_color="$GREEN"

            if ! registry_script_file_exists "$script"; then
                status_icon="○"
                status_color="$GREY"
            fi

            local desc=$(registry_get_script_field "$script" "description")
            local q_indicator=""
            registry_has_questions "$script" && q_indicator=" ${YELLOW}[Q]${NC}"

            printf "  ${status_color}%2d.${NC} %-15s ${GREY}%s${NC}%b\n" \
                "$total" "$script" "${desc:0:45}" "$q_indicator"
        done
    done

    echo ""
    echo "Legend: ✓ = available, ○ = coming soon, [Q] = has questions"
    echo "Total: $total scripts"
    echo ""
}

display_menu() {
    clear
    read_scan_cache

    local project_name=$(config_get "project.name" "Project" "$BOOTSTRAP_CONFIG")

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   Bootstrap Menu v${MENU_VERSION} - ${project_name} Setup${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

    # Show mode indicators
    local modes=""
    [[ "$INTERACTIVE_MODE" == "true" ]] && modes+="${GREEN}[Interactive]${NC} "
    [[ "$AUTO_YES" == "true" ]] && modes+="${YELLOW}[Auto-Yes]${NC} "
    [[ "$DRY_RUN" == "true" ]] && modes+="${GREY}[Dry-Run]${NC} "
    [[ -n "$modes" ]] && echo -e "   $modes"

    # Show scan warnings
    if [[ "${NEW_SCRIPTS_COUNT:-0}" -gt 0 ]]; then
        echo -e "   ${YELLOW}⚠ ${NEW_SCRIPTS_COUNT} new script(s) found - run --scan to register${NC}"
    fi
    if [[ "${MISSING_SCRIPTS_COUNT:-0}" -gt 0 ]]; then
        echo -e "   ${RED}⚠ ${MISSING_SCRIPTS_COUNT} script(s) missing files${NC}"
    fi

    echo ""
    echo -e "${YELLOW}Phases:${NC}"

    local counter=0
    local -a PHASES=()
    mapfile -t PHASES < <(registry_get_phases)
    for phase in "${PHASES[@]}"; do
        counter=$((counter + 1))
        local phase_name=$(registry_get_phase_name "$phase")
        local phase_color=$(registry_get_phase_color "$phase")
        local script_count=$(registry_get_phase_count "$phase")

        # Set color and icon
        local color_code="$BLUE"
        local icon="●"
        case "$phase_color" in
            red) color_code="$RED"; icon="🔴" ;;
            yellow) color_code="$YELLOW"; icon="🟡" ;;
            green) color_code="$GREEN"; icon="🟢" ;;
        esac

        echo -e "  ${GREEN}${counter}.${NC} ${icon} Phase $counter: ${phase_name} (${script_count} scripts)"
    done

    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    local max_phase=$(registry_get_phases | wc -l)
    echo "  1-${max_phase}      Enter phase menu to browse and run scripts"
    echo "  d        Show 80% pre-configured defaults (industry standards)"
    echo "  v        Run pre-flight validation to check environment readiness"
    echo "  hc       Quick system health check - validates tools and libraries"
    echo "  t        Run full test suite for all bootstrap components"
    echo "  qa       Display 20% of questions you'll be asked during setup"
    echo "  s        Show current environment status and bootstrap state"
    echo "  c        Display complete bootstrap configuration in detail"
    echo "  e        Interactively edit bootstrap configuration sections"
    echo "  sg       Toggle command suggestions (currently: $([ "$ENABLE_SUGGESTIONS" == "true" ] && echo "ON" || echo "OFF"))"
    echo "  r        Refresh and rescan for new or updated scripts"
    echo "  l        List all available scripts with metadata"
    echo "  h        Show this help information"
    echo "  q        Quit bootstrap menu and end session"
    echo ""
}

# ===================================================================
# Input Validation
# ===================================================================
validate_menu_command() {
    local cmd="$1"

    # Empty input is OK (skip)
    [[ -z "$cmd" || "$cmd" == " " ]] && return 0

    # Number validation FIRST (for phase selection)
    if [[ "$cmd" =~ ^-?[0-9]+$ ]]; then
        local -a PHASES=()
        mapfile -t PHASES < <(registry_get_phases)
        local max_phase=${#PHASES[@]}

        if [[ "$cmd" -lt 1 ]]; then
            log_error "Invalid number: $cmd (must be positive)"
            echo "Valid range: 1-${max_phase}"
            return 1
        elif [[ "$cmd" -gt "$max_phase" ]]; then
            log_error "Number out of range: $cmd"
            echo "Valid range: 1-${max_phase}"
            return 1
        else
            return 0
        fi
    fi

    # Single letter commands
    if [[ "${#cmd}" -eq 1 ]]; then
        case "$cmd" in
            h|H|s|S|c|C|d|D|l|L|r|R|q|Q|x|X|t|T|v|V|e|E|\?)
                return 0
                ;;
            *)
                log_error "Unknown command: $cmd"
                echo "Type 'h' for help or 'q' to quit"
                return 1
                ;;
        esac
    fi

    # Two letter commands
    if [[ "${#cmd}" -eq 2 ]]; then
        case "$cmd" in
            qa|QA|hc|HC|sg|SG)
                return 0
                ;;
            p[1-9]|P[1-9])
                # Validate phase number exists
                local phase_num="${cmd:1}"
                local -a PHASES=()
                mapfile -t PHASES < <(registry_get_phases)
                if [[ "$phase_num" -le "${#PHASES[@]}" ]]; then
                    return 0
                else
                    log_error "Unknown phase: $phase_num"
                    echo "Valid phases: 1-${#PHASES[@]}"
                    return 1
                fi
                ;;
            *)
                log_error "Unknown command: $cmd"
                echo "Type 'h' for help or 'q' to quit"
                return 1
                ;;
        esac
    fi

    # Script name validation (fallback)
    if registry_script_exists "$cmd"; then
        return 0
    fi

    # Invalid - no match found
    log_error "Unknown command: $cmd"
    echo "Type 'h' for help, 'l' to list scripts, or 'q' to quit"
    return 1
}

# ===================================================================
# Menu Loop
# ===================================================================
run_menu() {
    display_menu

    while true; do
        read -p "Selection: " -r choice || continue

        # Validate input before processing
        if ! validate_menu_command "$choice"; then
            echo ""
            continue
        fi

        case "$choice" in
            ""|" ")
                continue
                ;;

            h|H|\?)
                echo ""
                echo "Commands:"
                echo "  1-4       Enter phase menu to browse and run scripts"
                echo "  d         Show 80% pre-configured defaults (industry standards)"
                echo "  v         Run pre-flight validation to check environment readiness"
                echo "  hc        Quick system health check - validates tools and libraries"
                echo "  t         Run full test suite for all bootstrap components"
                echo "  qa        Display 20% of questions you'll be asked during setup"
                echo "  s         Show current environment status and bootstrap state"
                echo "  c         Display complete bootstrap configuration in detail"
                echo "  e         Interactively edit bootstrap configuration sections"
                echo "  sg        Toggle command suggestions"
                echo "  r         Refresh and rescan for new or updated scripts"
                echo "  l         List all available scripts with metadata"
                echo "  h         Show this help information"
                echo "  q/x       Quit bootstrap menu and end session"
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

            e|E)
                config_edit_interactive "$BOOTSTRAP_CONFIG"
                ;;

            sg|SG)
                if [[ "$ENABLE_SUGGESTIONS" == "true" ]]; then
                    ENABLE_SUGGESTIONS=false
                    log_info "Suggestions disabled"
                else
                    ENABLE_SUGGESTIONS=true
                    log_success "Suggestions enabled"
                fi
                echo ""
                sleep 0.5
                display_menu
                ;;

            d|D)
                show_config_preview
                ;;

            qa|QA)
                show_questions_preview
                ;;

            l|L)
                show_list
                ;;
            v|V)
                log_section "Validation Report"
                if type -t preflight_check_phase &>/dev/null; then
                    echo "Checking Phase 1..."
                    preflight_check_phase 1 || true
                    echo ""
                fi
                if type -t registry_validate_manifest &>/dev/null; then
                    echo "Validating manifest..."
                    registry_validate_manifest || true
                fi
                ;;

            hc|HC)
                log_info "Running health check..."
                if [[ ! -d "$SCRIPTS_DIR" ]]; then
                    log_error "Scripts directory not found: $SCRIPTS_DIR"
                elif [[ -f "${SCRIPTS_DIR}/bootstrap-healthcheck.sh" ]]; then
                    bash "${SCRIPTS_DIR}/bootstrap-healthcheck.sh" --quick
                else
                    log_error "Health check script not found"
                fi
                ;;

            t|T)
                log_section "Running Test Suite"
                if [[ ! -d "$BOOTSTRAP_DIR" ]]; then
                    log_error "Bootstrap directory not found: $BOOTSTRAP_DIR"
                elif [[ -f "${BOOTSTRAP_DIR}/tests/lib/test-runner.sh" ]]; then
                    (
                        cd "${BOOTSTRAP_DIR}" || exit 1
                        if bash tests/lib/test-runner.sh; then
                            echo ""
                            log_success "All tests passed"
                        else
                            echo ""
                            log_error "Some tests failed"
                            log_warning "Library functions may be unreliable"
                        fi
                    )
                else
                    log_error "Test runner not found"
                fi
                ;;



            r|R)
                log_info "Rescanning scripts..."
                rm -f "$SCAN_CACHE"
                launch_background_scan
                wait_for_scan
                read_scan_cache
                sleep 0.5
                display_menu
                ;;

            p[1-9]|P[1-9])
                # Dynamic phase execution (p1-p9)
                local phase_num="${choice:1}"
                run_phase "$phase_num"
                show_session_summary
                ;;

            [1-9])
                # Phase selection - route to phase menu (single digit)
                run_phase_menu "$choice"
                echo ""
                sleep 0.5
                display_menu
                ;;

            [0-9][0-9])
                # Invalid two-digit phase numbers
                local -a PHASES=()
                mapfile -t PHASES < <(registry_get_phases)
                log_error "Invalid selection: $choice (1-${#PHASES[@]})"
                echo ""
                sleep 1
                ;;

            *)
                # Try to match script name directly
                if registry_script_exists "$choice"; then
                    if registry_script_file_exists "$choice"; then
                        run_script "$choice"
                    else
                        log_warning "Script not available: $choice"
                    fi
                else
                    log_error "Unknown command: $choice"
                fi
                ;;
        esac

        echo ""
    done
}

# ===================================================================
# Main Entry Point
# ===================================================================
main() {
    # Parse command line
    parse_arguments "$@"

    # Normalize project root to absolute path
    normalize_project_root

    local manifest_file="$MANIFEST_FILE"

    # Show help if requested
    if [[ "$SHOW_HELP" == "true" ]]; then
        show_help
        exit 0
    fi

    # Validate manifest
    if ! registry_validate_manifest; then
        log_fatal "Invalid manifest file. Run bootstrap-manifest-gen.sh to regenerate."
    fi

    # Ensure config exists
    ensure_config "$BOOTSTRAP_CONFIG" >/dev/null

    # Force scan if requested or cache stale
    if [[ "$FORCE_SCAN" == "true" ]] || registry_is_cache_stale "menu-scan.json"; then
        rm -f "$SCAN_CACHE"
    fi

    # Launch background scan
    launch_background_scan

    # Handle special modes
    if [[ "$SHOW_STATUS" == "true" ]]; then
        wait_for_scan || true
        show_status
        exit 0
    fi

    if [[ "$SHOW_LIST" == "true" ]]; then
        wait_for_scan || true
        show_list
        exit 0
    fi

    # Run profile if specified
    if [[ -n "$PROFILE" ]]; then
        wait_for_scan

        local profile="$PROFILE"
        if ! grep -q "\"$profile\"" "$manifest_file"; then
            echo "Error: Unknown profile: $profile" >&2
            exit 1
        fi

        set +e
        run_profile "$profile"
        RUN_STATUS=$?
        set -e

        show_session_summary
        exit $RUN_STATUS
    fi

    # Run phase if specified
    if [[ -n "$PHASE" ]]; then
        wait_for_scan

        local phase="$PHASE"
        if ! grep -q "\"$phase\"" "$manifest_file"; then
            echo "Error: Unknown phase: $phase" >&2
            exit 1
        fi

        set +e
        run_phase "$phase"
        RUN_STATUS=$?
        set -e

        show_session_summary
        exit $RUN_STATUS
    fi

    # Wait for scan before showing menu (gracefully handle timeout)
    wait_for_scan || true

    # Interactive menu
    run_menu
}

# ===================================================================
# Cleanup
# ===================================================================
cleanup() {
    [[ -n "${HELPER_PID:-}" ]] && kill "$HELPER_PID" 2>/dev/null || true

    # Clear session history if recommendation engine is loaded
    if type -t clear_session_history &>/dev/null; then
        clear_session_history
    fi
}
trap cleanup EXIT

# Run
main "$@"
