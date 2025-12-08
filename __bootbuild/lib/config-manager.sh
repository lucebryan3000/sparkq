#!/bin/bash

# ===================================================================
# config-manager.sh
#
# Manages bootstrap.config file - a persistent key-value store for
# bootstrap configuration that:
# 1. Auto-detects values on first run
# 2. Stores reusable information for future bootstraps
# 3. Acts as "memory" for the bootstrap system
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_CONFIG_MANAGER_LOADED:-}" ]] && return 0
_BOOTSTRAP_CONFIG_MANAGER_LOADED=1

# Config file location - MUST be set by calling script or via lib/paths.sh
# Which sets CONFIG_FILE as the standard variable name
# Support both CONFIG_FILE (new) and BOOTSTRAP_CONFIG (legacy) for compatibility
if [[ -n "${CONFIG_FILE:-}" ]]; then
    BOOTSTRAP_CONFIG="$CONFIG_FILE"
elif [[ -z "${BOOTSTRAP_CONFIG:-}" ]]; then
    echo "ERROR: [ConfigManager] CONFIG_FILE or BOOTSTRAP_CONFIG must be set before sourcing config-manager.sh" >&2
    echo "       Typically set by: source \"\${LIB_DIR}/paths.sh\"" >&2
    return 1
fi

# Validate config file location is accessible
if [[ ! -f "$BOOTSTRAP_CONFIG" ]] && [[ ! -d "$(dirname "$BOOTSTRAP_CONFIG")" ]]; then
    echo "ERROR: [ConfigManager] Config directory not found: $(dirname "$BOOTSTRAP_CONFIG")" >&2
    return 1
fi

# ===================================================================
# Auto-Detection Functions
# ===================================================================

# Detect project name from directory or git remote
detect_project_name() {
    local name=""

    # Try git remote first
    if command -v git &> /dev/null && git remote -v &> /dev/null; then
        name=$(git remote get-url origin 2>/dev/null | sed -E 's/.*\/(.+)(\.git)?$/\1/' | sed 's/\.git$//')
    fi

    # Fall back to directory name
    if [[ -z "$name" ]]; then
        name=$(basename "$(pwd)")
    fi

    echo "$name"
}

# Detect git user configuration
detect_git_user() {
    if command -v git &> /dev/null; then
        git config user.name 2>/dev/null || echo ""
    fi
}

detect_git_email() {
    if command -v git &> /dev/null; then
        git config user.email 2>/dev/null || echo ""
    fi
}

# Detect default git branch
detect_git_branch() {
    if command -v git &> /dev/null && [[ -d .git ]]; then
        git symbolic-ref --short HEAD 2>/dev/null || echo "main"
    else
        echo "main"
    fi
}

# Detect Node version from .nvmrc or nvm
detect_node_version() {
    if [[ -f .nvmrc ]]; then
        cat .nvmrc
    elif command -v node &> /dev/null; then
        node --version | sed 's/v//' | cut -d. -f1
    else
        echo "20"
    fi
}

# Detect package manager from lock files
detect_package_manager() {
    if [[ -f pnpm-lock.yaml ]]; then
        echo "pnpm"
    elif [[ -f yarn.lock ]]; then
        echo "yarn"
    elif [[ -f package-lock.json ]]; then
        echo "npm"
    else
        echo "pnpm"  # Default to pnpm
    fi
}

# Detect project phase from existing CLAUDE.md or default to POC
detect_project_phase() {
    if [[ -f CLAUDE.md ]]; then
        grep -oP 'Phase.*:\s*\K\w+' CLAUDE.md | head -1 || echo "POC"
    else
        echo "POC"
    fi
}

# ===================================================================
# Config File Management
# ===================================================================

# Initialize bootstrap.config with auto-detected values
init_config() {
    local config_file="$1"
    local config_dir=$(dirname "$config_file")

    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"

    # Detect all values
    local project_name=$(detect_project_name)
    local git_user=$(detect_git_user)
    local git_email=$(detect_git_email)
    local git_branch=$(detect_git_branch)
    local node_version=$(detect_node_version)
    local package_manager=$(detect_package_manager)
    local project_phase=$(detect_project_phase)

    # Generate config file
    cat > "$config_file" <<EOF
# ===================================================================
# Bootstrap Configuration
#
# Auto-detected and reusable values for project bootstrapping
# This file acts as "memory" for the bootstrap system
#
# Generated: $(date)
# Project: $project_name
# ===================================================================

[project]
name=$project_name
phase=$project_phase
owner=Bryan Luce
owner_email=bryan@appmelia.com

[git]
user_name=${git_user:-Bryan Luce}
user_email=${git_email:-bryan@appmelia.com}
default_branch=$git_branch

[docker]
database_type=postgres
database_name=${project_name}_dev
app_port=3000
database_port=5432
compose_project_name=$project_name

[packages]
package_manager=$package_manager
node_version=$node_version

[claude]
enable_codex=true
ai_model=sonnet

[testing]
coverage_threshold=70
e2e_framework=playwright

[paths]
# Template source paths (relative to bootstrap/)
templates_root=templates/root
templates_claude=templates/.claude
templates_vscode=templates/.vscode
templates_github=templates/.github
templates_devcontainer=templates/.devcontainer
EOF

    echo "$config_file"
}

# Read value from config file
# Usage: config_get "section.key" "default_value"
config_get() {
    local key="$1"
    local default="${2:-}"
    local config_file="${3:-$BOOTSTRAP_CONFIG}"

    # Validate key is not empty
    [[ -z "$key" ]] && { echo "ERROR: [ConfigManager] config_get: Key required" >&2; echo "$default"; return 1; }

    # Validate key format (must contain a dot)
    [[ ! "$key" =~ \. ]] && { echo "ERROR: [ConfigManager] config_get: Key must be in 'section.key' format" >&2; echo "$default"; return 1; }

    # Validate config file exists
    if [[ ! -f "$config_file" ]]; then
        echo "ERROR: [ConfigManager] config_get: Config file not found: $config_file" >&2
        echo "$default"
        return 1
    fi

    # Parse section.key format
    local section=$(echo "$key" | cut -d. -f1)
    local field=$(echo "$key" | cut -d. -f2)

    # Extract value using awk
    local value=$(awk -F= -v section="[$section]" -v key="$field" '
        $0 == section { in_section=1; next }
        /^\[/ { in_section=0 }
        in_section && $1 == key { print $2; exit }
    ' "$config_file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Set value in config file
# Usage: config_set "section.key" "value"
config_set() {
    local key="$1"
    local value="$2"
    local config_file="${3:-$BOOTSTRAP_CONFIG}"

    # Validate key is not empty
    [[ -z "$key" ]] && { echo "ERROR: [ConfigManager] config_set: Key required" >&2; return 1; }

    # Validate key format (must contain a dot)
    [[ ! "$key" =~ \. ]] && { echo "ERROR: [ConfigManager] config_set: Key must be in 'section.key' format" >&2; return 1; }

    # Validate value is provided (allow empty string but not unset)
    [[ $# -lt 2 ]] && { echo "ERROR: [ConfigManager] config_set: Value required" >&2; return 1; }

    # Validate config file path is not empty
    [[ -z "$config_file" ]] && { echo "ERROR: [ConfigManager] config_set: Config file path required" >&2; return 1; }

    # Validate directory is writable
    local config_dir=$(dirname "$config_file")
    [[ ! -d "$config_dir" ]] && { echo "ERROR: [ConfigManager] config_set: Config directory does not exist: $config_dir" >&2; return 1; }
    [[ ! -w "$config_dir" ]] && { echo "ERROR: [ConfigManager] config_set: Config directory not writable: $config_dir" >&2; return 1; }

    # Create config if doesn't exist
    if [[ ! -f "$config_file" ]]; then
        init_config "$config_file"
    fi

    # Validate config file is writable
    [[ ! -w "$config_file" ]] && { echo "ERROR: [ConfigManager] config_set: Config file not writable: $config_file" >&2; return 1; }

    # Parse section.key format
    local section=$(echo "$key" | cut -d. -f1)
    local field=$(echo "$key" | cut -d. -f2)

    # Use awk to update the value
    if awk -F= -v section="[$section]" -v key="$field" -v value="$value" '
        BEGIN { in_section=0; found=0 }
        $0 == section { in_section=1; print; next }
        /^\[/ { in_section=0 }
        in_section && $1 == key { print key "=" value; found=1; next }
        { print }
        END { if (in_section && !found) print key "=" value }
    ' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"; then
        return 0
    else
        echo "ERROR: [ConfigManager] config_set: Failed to update config file" >&2
        rm -f "$config_file.tmp"
        return 1
    fi
}

# Load all config values as environment variables
# Usage: config_load
config_load() {
    local config_file="${1:-$BOOTSTRAP_CONFIG}"

    if [[ ! -f "$config_file" ]]; then
        echo "ERROR: [ConfigManager] config_load: Config file not found: $config_file" >&2
        return 1
    fi

    # Read config file and export as environment variables
    # Format: SECTION_KEY=value (e.g., PROJECT_NAME=sparkq)
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        [[ "$key" =~ ^\[ ]] && { current_section=$(echo "$key" | tr -d '[]'); continue; }

        # Create environment variable: SECTION_KEY=value
        local env_var="${current_section}_${key}"
        env_var=$(echo "$env_var" | tr '[:lower:]' '[:upper:]' | tr -d ' ')
        export "$env_var=$value"
    done < "$config_file"
}

# Display config file contents in a formatted way
config_show() {
    local config_file="${1:-$BOOTSTRAP_CONFIG}"

    if [[ ! -f "$config_file" ]]; then
        echo "Config file not found: $config_file"
        return 1
    fi

    echo ""
    echo "Bootstrap Configuration:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local current_section=""
    while IFS= read -r line; do
        # Skip comments at start
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Section headers
        if [[ "$line" =~ ^\[(.+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
            echo ""
            echo "[$current_section]"
            continue
        fi

        # Key-value pairs
        if [[ "$line" =~ ^([^=]+)=(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            printf "  %-20s = %s\n" "$key" "$value"
        fi
    done < "$config_file"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Update config from user answers
# Usage: config_update_from_answers ".bootstrap-answers.env"
config_update_from_answers() {
    local answers_file="${1:-.bootstrap-answers.env}"
    local config_file="${2:-$BOOTSTRAP_CONFIG}"

    if [[ ! -f "$answers_file" ]]; then
        return 1
    fi

    # Source answers file
    source "$answers_file"

    # Update config with answered values
    [[ -n "$PROJECT_NAME" ]] && config_set "project.name" "$PROJECT_NAME" "$config_file"
    [[ -n "$PROJECT_PHASE" ]] && config_set "project.phase" "$PROJECT_PHASE" "$config_file"
    [[ -n "$GIT_USER_NAME" ]] && config_set "git.user_name" "$GIT_USER_NAME" "$config_file"
    [[ -n "$GIT_USER_EMAIL" ]] && config_set "git.user_email" "$GIT_USER_EMAIL" "$config_file"
    [[ -n "$GIT_DEFAULT_BRANCH" ]] && config_set "git.default_branch" "$GIT_DEFAULT_BRANCH" "$config_file"
    [[ -n "$DATABASE_TYPE" ]] && config_set "docker.database_type" "$DATABASE_TYPE" "$config_file"
    [[ -n "$DATABASE_NAME" ]] && config_set "docker.database_name" "$DATABASE_NAME" "$config_file"
    [[ -n "$APP_PORT" ]] && config_set "docker.app_port" "$APP_PORT" "$config_file"
    [[ -n "$DATABASE_PORT" ]] && config_set "docker.database_port" "$DATABASE_PORT" "$config_file"
    [[ -n "$PACKAGE_MANAGER" ]] && config_set "packages.package_manager" "$PACKAGE_MANAGER" "$config_file"
    [[ -n "$NODE_VERSION" ]] && config_set "packages.node_version" "$NODE_VERSION" "$config_file"
    [[ -n "$ENABLE_CODEX" ]] && config_set "claude.enable_codex" "$ENABLE_CODEX" "$config_file"
    [[ -n "$AI_MODEL" ]] && config_set "claude.ai_model" "$AI_MODEL" "$config_file"
    [[ -n "$COVERAGE_THRESHOLD" ]] && config_set "testing.coverage_threshold" "$COVERAGE_THRESHOLD" "$config_file"
    [[ -n "$E2E_FRAMEWORK" ]] && config_set "testing.e2e_framework" "$E2E_FRAMEWORK" "$config_file"
}

# ===================================================================
# Ensure config exists
# ===================================================================

ensure_config() {
    local config_file="${1:-$BOOTSTRAP_CONFIG}"

    if [[ ! -f "$config_file" ]]; then
        init_config "$config_file"
    fi

    echo "$config_file"
}
