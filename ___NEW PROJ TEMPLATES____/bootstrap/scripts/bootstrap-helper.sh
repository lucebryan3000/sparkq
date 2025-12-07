#!/bin/bash

# ===================================================================
# bootstrap-helper.sh
#
# Background helper that runs on menu launch to:
# 1. Detect environment (tools, versions, existing files)
# 2. Populate bootstrap.config with detected values
# 3. Run quick health checks
# 4. Report status back to menu
#
# DESIGN: Runs fast (<2s) so it completes before user selects option
# ===================================================================

set -euo pipefail

# Paths - derive BOOTSTRAP_DIR first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source lib/paths.sh to initialize all paths
source "${BOOTSTRAP_DIR}/lib/paths.sh" || exit 1

# Status file uses CONFIG_DIR from paths.sh
STATUS_FILE="${CONFIG_DIR}/.helper-status"

# Source config manager (now CONFIG_FILE is set by lib/paths.sh)
source "${LIB_DIR}/config-manager.sh" || exit 1

# ===================================================================
# Quick Detection Functions (optimized for speed)
# ===================================================================

detect_tools() {
    local status=()

    # Git
    if command -v git &>/dev/null; then
        config_set "detected.git_installed" "true" "$CONFIG_FILE"
        status+=("git:ok")
    else
        config_set "detected.git_installed" "false" "$CONFIG_FILE"
        status+=("git:missing")
    fi

    # Node
    if command -v node &>/dev/null; then
        local node_ver=$(node --version 2>/dev/null | sed 's/v//')
        config_set "detected.node_installed" "true" "$CONFIG_FILE"
        config_set "packages.node_version" "${node_ver%%.*}" "$CONFIG_FILE"
        status+=("node:${node_ver}")
    else
        config_set "detected.node_installed" "false" "$CONFIG_FILE"
        status+=("node:missing")
    fi

    # pnpm
    if command -v pnpm &>/dev/null; then
        config_set "detected.pnpm_installed" "true" "$CONFIG_FILE"
        config_set "packages.package_manager" "pnpm" "$CONFIG_FILE"
        status+=("pnpm:ok")
    elif command -v yarn &>/dev/null; then
        config_set "detected.pnpm_installed" "false" "$CONFIG_FILE"
        config_set "packages.package_manager" "yarn" "$CONFIG_FILE"
        status+=("yarn:ok")
    else
        config_set "detected.pnpm_installed" "false" "$CONFIG_FILE"
        config_set "packages.package_manager" "npm" "$CONFIG_FILE"
        status+=("npm:fallback")
    fi

    # Docker
    if command -v docker &>/dev/null; then
        config_set "detected.docker_installed" "true" "$CONFIG_FILE"
        status+=("docker:ok")
    else
        config_set "detected.docker_installed" "false" "$CONFIG_FILE"
        status+=("docker:missing")
    fi

    echo "${status[*]}"
}

detect_project_state() {
    local project_root="${1:-.}"
    local status=()

    # Check for existing files in target project
    if [[ -f "${project_root}/package.json" ]]; then
        config_set "detected.has_package_json" "true" "$CONFIG_FILE"
        status+=("package.json:exists")
    else
        config_set "detected.has_package_json" "false" "$CONFIG_FILE"
        status+=("package.json:missing")
    fi

    if [[ -d "${project_root}/.git" ]]; then
        config_set "detected.has_git_repo" "true" "$CONFIG_FILE"
        status+=("git:initialized")
    else
        config_set "detected.has_git_repo" "false" "$CONFIG_FILE"
        status+=("git:not-initialized")
    fi

    if [[ -f "${project_root}/tsconfig.json" ]]; then
        config_set "detected.has_tsconfig" "true" "$CONFIG_FILE"
        status+=("typescript:configured")
    else
        config_set "detected.has_tsconfig" "false" "$CONFIG_FILE"
        status+=("typescript:not-configured")
    fi

    if [[ -d "${project_root}/.claude" ]]; then
        config_set "detected.has_claude_dir" "true" "$CONFIG_FILE"
        status+=("claude:configured")
    else
        config_set "detected.has_claude_dir" "false" "$CONFIG_FILE"
        status+=("claude:not-configured")
    fi

    echo "${status[*]}"
}

detect_git_config() {
    if command -v git &>/dev/null; then
        local user_name=$(git config --global user.name 2>/dev/null || echo "")
        local user_email=$(git config --global user.email 2>/dev/null || echo "")

        [[ -n "$user_name" ]] && config_set "git.user_name" "$user_name" "$CONFIG_FILE"
        [[ -n "$user_email" ]] && config_set "git.user_email" "$user_email" "$CONFIG_FILE"
    fi
}

detect_project_name() {
    local project_root="${1:-.}"
    local name=""

    # Try package.json first
    if [[ -f "${project_root}/package.json" ]]; then
        name=$(grep -oP '"name"\s*:\s*"\K[^"]+' "${project_root}/package.json" 2>/dev/null || echo "")
    fi

    # Try git remote
    if [[ -z "$name" ]] && command -v git &>/dev/null; then
        name=$(cd "$project_root" && git remote get-url origin 2>/dev/null | sed -E 's/.*\/(.+)(\.git)?$/\1/' | sed 's/\.git$//' || echo "")
    fi

    # Fall back to directory name
    if [[ -z "$name" ]]; then
        name=$(basename "$(cd "$project_root" && pwd)")
    fi

    [[ -n "$name" ]] && config_set "project.name" "$name" "$CONFIG_FILE"
    echo "$name"
}

# ===================================================================
# Health Check (quick validation)
# ===================================================================

run_health_check() {
    local issues=()

    # Check critical tools
    command -v git &>/dev/null || issues+=("git-not-installed")
    command -v node &>/dev/null || issues+=("node-not-installed")

    # Check config file exists
    [[ -f "$CONFIG_FILE" ]] || issues+=("config-missing")

    # Check templates exist
    [[ -d "${BOOTSTRAP_DIR}/templates/root" ]] || issues+=("templates-missing")

    # Check lib files exist
    [[ -f "${BOOTSTRAP_DIR}/lib/config-manager.sh" ]] || issues+=("lib-missing")

    if [[ ${#issues[@]} -eq 0 ]]; then
        echo "healthy"
    else
        echo "${issues[*]}"
    fi
}

# ===================================================================
# Status File (for menu to read)
# ===================================================================

write_status() {
    local tools_status="$1"
    local project_status="$2"
    local health_status="$3"
    local project_name="$4"

    cat > "$STATUS_FILE" <<EOF
# Bootstrap Helper Status
# Generated: $(date +%Y-%m-%dT%H:%M:%S)

HELPER_RUN=true
TOOLS_STATUS="${tools_status}"
PROJECT_STATUS="${project_status}"
HEALTH_STATUS="${health_status}"
PROJECT_NAME="${project_name}"
READY=true
EOF
}

# ===================================================================
# Main
# ===================================================================

main() {
    local project_root="${1:-.}"

    # Update last run timestamp
    config_set "detected.last_run" "$(date +%Y-%m-%dT%H:%M:%S)" "$CONFIG_FILE"

    # Run detections (fast, parallel-safe)
    local tools_status=$(detect_tools)
    local project_status=$(detect_project_state "$project_root")
    local project_name=$(detect_project_name "$project_root")

    # Detect git config
    detect_git_config

    # Run health check
    local health_status=$(run_health_check)

    # Write status file for menu to read
    write_status "$tools_status" "$project_status" "$health_status" "$project_name"

    # Output for debugging (only if run directly)
    if [[ "${BOOTSTRAP_HELPER_VERBOSE:-false}" == "true" ]]; then
        echo "Tools: $tools_status"
        echo "Project: $project_status"
        echo "Health: $health_status"
        echo "Name: $project_name"
    fi
}

# Run main with optional project root argument
main "${1:-.}"
