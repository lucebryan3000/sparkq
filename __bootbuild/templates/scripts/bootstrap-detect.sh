#!/bin/bash

# ===================================================================
# bootstrap-detect.sh
#
# Purpose: Detect system tools, project files, and environment capabilities
# Creates: __bootbuild/logs/bootstrap-detect-*.json, updates [detected] in bootstrap.config
# Config:  [detect] section in bootstrap.config
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export SCRIPT_NAME="bootstrap-detect"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Source paths and config manager
source "${BOOTSTRAP_DIR}/lib/paths.sh" || {
    log_error "Failed to initialize paths"
    exit 1
}

if [[ -f "${BOOTSTRAP_DIR}/lib/config-manager.sh" ]]; then
    source "${BOOTSTRAP_DIR}/lib/config-manager.sh" || {
        log_error "Failed to source config-manager"
        exit 1
    }
fi

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-detect"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "python3" \
    --scripts "" \
    --optional ""


# ===================================================================
# Configuration
# ===================================================================

# Ensure logs directory exists
LOGS_DIR="${BOOTSTRAP_DIR}/logs"
mkdir -p "$LOGS_DIR"

# Output file for detection results (timestamped)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DETECT_OUTPUT="${LOGS_DIR}/bootstrap-detect-${TIMESTAMP}.json"
DETECT_LATEST="${LOGS_DIR}/bootstrap-detect-latest.json"

# Config file path
CONFIG_FILE="${BOOTSTRAP_DIR}/config/bootstrap.config"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "System Detection & Analysis" \
    "__bootbuild/logs/bootstrap-detect-*.json and [detected] section in config"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Detection Functions
# ===================================================================

# Detect if a command is available and get version
detect_tool() {
    local tool_name="$1"
    local version_flag="${2:---version}"
    local output=""

    if command -v "$tool_name" &> /dev/null; then
        output=$("$tool_name" $version_flag 2>&1 | head -1 || echo "installed")
        echo "true|$output"
    else
        echo "false|not installed"
    fi
}

# Detect if a file/directory exists in project
detect_file() {
    local file_path="$1"
    local full_path="$PROJECT_ROOT/$file_path"

    if [[ -f "$full_path" ]]; then
        echo "true|file"
    elif [[ -d "$full_path" ]]; then
        echo "true|directory"
    else
        echo "false|missing"
    fi
}

# Detect git repository
detect_git() {
    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        local branch=""
        if command -v git &> /dev/null; then
            branch=$(cd "$PROJECT_ROOT" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            echo "true|$branch"
        else
            echo "true|unknown"
        fi
    else
        echo "false|not a git repo"
    fi
}

# Detect if running in WSL
detect_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "true|WSL"
    else
        echo "false|native"
    fi
}

# Detect if Docker is running
detect_docker_running() {
    if command -v docker &> /dev/null; then
        if docker ps &> /dev/null; then
            echo "true|running"
        else
            echo "true|installed but not running"
        fi
    else
        echo "false|not installed"
    fi
}

# ===================================================================
# Detect Tools
# ===================================================================

log_info "Detecting installed tools..."

# Detect Node.js and npm ecosystem
NODE_RESULT=$(detect_tool "node" "--version")
NPM_RESULT=$(detect_tool "npm" "--version")
PNPM_RESULT=$(detect_tool "pnpm" "--version")
YARN_RESULT=$(detect_tool "yarn" "--version")

# Detect Python
PYTHON_RESULT=$(detect_tool "python3" "--version")
PIP_RESULT=$(detect_tool "pip3" "--version")

# Detect Docker
DOCKER_RESULT=$(detect_tool "docker" "--version")
DOCKER_COMPOSE_RESULT=$(detect_tool "docker-compose" "--version")
DOCKER_RUNNING=$(detect_docker_running)

# Detect Git
GIT_RESULT=$(detect_tool "git" "--version")

# Detect Database tools
PSQL_RESULT=$(detect_tool "psql" "--version")
MYSQL_RESULT=$(detect_tool "mysql" "--version")

# Detect other tools
CURL_RESULT=$(detect_tool "curl" "--version")
JQ_RESULT=$(detect_tool "jq" "--version")
MAKE_RESULT=$(detect_tool "make" "--version")

log_success "Tool detection complete"

# ===================================================================
# Detect Project Files
# ===================================================================

log_info "Detecting project files..."

PACKAGE_JSON=$(detect_file "package.json")
TSCONFIG=$(detect_file "tsconfig.json")
DOCKERFILE=$(detect_file "Dockerfile")
DOCKER_COMPOSE=$(detect_file "docker-compose.yml")
NEXT_CONFIG=$(detect_file "next.config.js")
VITE_CONFIG=$(detect_file "vite.config.ts")
PRISMA=$(detect_file "prisma")
PYTEST=$(detect_file "pytest.ini")
REQUIREMENTS=$(detect_file "requirements.txt")
PIPFILE=$(detect_file "Pipfile")
README=$(detect_file "README.md")
GITIGNORE=$(detect_file ".gitignore")

log_success "Project file detection complete"

# ===================================================================
# Detect Git Repository
# ===================================================================

log_info "Detecting git repository..."

GIT_REPO=$(detect_git)

log_success "Git detection complete"

# ===================================================================
# Detect Environment
# ===================================================================

log_info "Detecting environment..."

WSL_STATUS=$(detect_wsl)
OS_TYPE=$(uname -s)
ARCH=$(uname -m)

log_success "Environment detection complete"

# ===================================================================
# Update Bootstrap Config [detected] Section
# Project-level facts only (not host environment)
# ===================================================================

log_info "Updating bootstrap.config [detected] section..."

# Helper function to safely update config values
update_config_value() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    else
        log_warning "Key not found in config: $key"
    fi
}

# Extract boolean from detect results
get_bool() {
    echo "$1" | cut -d'|' -f1
}

# Get current branch if git repo
CURRENT_BRANCH=$(echo "$GIT_REPO" | cut -d'|' -f2)
if [[ "$CURRENT_BRANCH" == "not a git repo" ]]; then
    CURRENT_BRANCH=""
fi

# Update PROJECT-LEVEL detection status only
# (Host-level detections like git_installed, node_installed are in JSON only)
update_config_value "last_run" "$(date +'%m-%d-%Y %I:%M:%S %p %Z')"
update_config_value "has_package_json" "$(get_bool "$PACKAGE_JSON")"
update_config_value "has_git_repo" "$(get_bool "$GIT_REPO")"
update_config_value "has_tsconfig" "$(get_bool "$TSCONFIG")"
CLAUDE_DIR=$(detect_file ".claude")
update_config_value "has_claude_dir" "$(get_bool "$CLAUDE_DIR")"

log_success "Bootstrap config updated (project-level facts only)"

# ===================================================================
# Create Detection Report
# ===================================================================

log_info "Creating detection report..."

# Escape special characters for JSON
escape_json() {
    local str="$1"
    # Escape backslashes, quotes, and pipes that might break JSON
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    echo "$str"
}

# Use Python to generate valid JSON (more robust than sed)
if command -v python3 &> /dev/null; then
    python3 << EOFPYTHON > "$DETECT_OUTPUT"
import json
from datetime import datetime

data = {
    "detection_timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "system": {
        "os": "$OS_TYPE",
        "architecture": "$ARCH",
        "wsl": "$WSL_STATUS"
    },
    "tools": {
        "runtime": {
            "node": "$NODE_RESULT",
            "python": "$PYTHON_RESULT"
        },
        "package_managers": {
            "npm": "$NPM_RESULT",
            "pnpm": "$PNPM_RESULT",
            "yarn": "$YARN_RESULT",
            "pip": "$PIP_RESULT"
        },
        "containers": {
            "docker": "$DOCKER_RESULT",
            "docker_compose": "$DOCKER_COMPOSE_RESULT",
            "docker_running": "$DOCKER_RUNNING"
        },
        "databases": {
            "psql": "$PSQL_RESULT",
            "mysql": "$MYSQL_RESULT"
        },
        "vcs": {
            "git": "$GIT_RESULT"
        },
        "utilities": {
            "curl": "$CURL_RESULT",
            "jq": "$JQ_RESULT",
            "make": "$MAKE_RESULT"
        }
    },
    "project": {
        "git_repository": "$GIT_REPO",
        "files": {
            "package_json": "$PACKAGE_JSON",
            "tsconfig": "$TSCONFIG",
            "dockerfile": "$DOCKERFILE",
            "docker_compose": "$DOCKER_COMPOSE",
            "next_config": "$NEXT_CONFIG",
            "vite_config": "$VITE_CONFIG",
            "prisma": "$PRISMA",
            "pytest_ini": "$PYTEST",
            "requirements_txt": "$REQUIREMENTS",
            "pipfile": "$PIPFILE",
            "readme": "$README",
            "gitignore": "$GITIGNORE"
        }
    }
}

print(json.dumps(data, indent=2))
EOFPYTHON

    if [[ $? -eq 0 ]]; then
        log_success "JSON report generated with Python"
    else
        log_fatal "Failed to generate JSON report with Python"
    fi
else
    # Fallback to basic heredoc if Python not available
    log_warning "Python not available, using basic JSON generation"
    cat > "$DETECT_OUTPUT" << EOFJSON
{
  "detection_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "system": {
    "os": "$OS_TYPE",
    "architecture": "$ARCH",
    "wsl": "$WSL_STATUS"
  },
  "tools": {
    "runtime": {
      "node": "$(escape_json "$NODE_RESULT")",
      "python": "$(escape_json "$PYTHON_RESULT")"
    }
  },
  "note": "Limited JSON generation - Python not available for full report"
}
EOFJSON
fi

verify_file "$DETECT_OUTPUT" || log_fatal "Failed to create detection report"

# Validate JSON if possible
if command -v python3 &> /dev/null; then
    if python3 -c "import json; json.load(open('$DETECT_OUTPUT'))" 2>/dev/null; then
        log_success "JSON validation passed"
    else
        log_warning "JSON validation failed - report may be malformed"
        track_warning "Generated JSON failed validation"
    fi
fi

# Create symlink to latest
ln -sf "bootstrap-detect-${TIMESTAMP}.json" "$DETECT_LATEST"
log_success "Created symlink: bootstrap-detect-latest.json"

# Cleanup old detection files (keep last 10)
log_info "Cleaning up old detection files..."
DETECTION_FILES=$(find "$LOGS_DIR" -name "bootstrap-detect-*.json" -type f | sort -r)
FILE_COUNT=$(echo "$DETECTION_FILES" | wc -l)

if [[ $FILE_COUNT -gt 10 ]]; then
    FILES_TO_DELETE=$(echo "$DETECTION_FILES" | tail -n +11)
    echo "$FILES_TO_DELETE" | while read -r file; do
        rm -f "$file"
        log_info "Removed old detection file: $(basename "$file")"
    done
    DELETED_COUNT=$((FILE_COUNT - 10))
    log_success "Cleaned up $DELETED_COUNT old detection file(s)"
else
    log_info "No cleanup needed (only $FILE_COUNT file(s))"
fi

log_file_created "$SCRIPT_NAME" "logs/bootstrap-detect-${TIMESTAMP}.json"
track_created "logs/bootstrap-detect-${TIMESTAMP}.json"
log_success "Detection report created"

# ===================================================================
# Generate Script Recommendations
# ===================================================================

log_info "Generating script recommendations..."

# Source script registry if available
if [[ -f "${BOOTSTRAP_DIR}/lib/script-registry.sh" ]]; then
    source "${BOOTSTRAP_DIR}/lib/script-registry.sh"
    REGISTRY_AVAILABLE=true
else
    REGISTRY_AVAILABLE=false
    log_warning "Script registry not available - skipping recommendations"
fi

# Generate recommendations based on detection results
generate_recommendations() {
    local run_scripts=""
    local optional_scripts=""
    local skip_scripts=""
    local warnings=""

    # Helper to add to comma-separated list
    add_to_list() {
        local var_name="$1"
        local value="$2"
        local current="${!var_name}"
        if [[ -z "$current" ]]; then
            eval "$var_name=\"\\\"$value\\\"\""
        else
            eval "$var_name=\"$current, \\\"$value\\\"\""
        fi
    }

    add_warning() {
        local script="$1"
        local message="$2"
        local entry="{\"script\": \"$script\", \"message\": \"$message\"}"
        if [[ -z "$warnings" ]]; then
            warnings="$entry"
        else
            warnings="$warnings, $entry"
        fi
    }

    # Check each detection and map to scripts

    # Git detection
    if [[ "$(get_bool "$GIT_REPO")" == "false" ]]; then
        add_to_list run_scripts "git"
    else
        add_to_list skip_scripts "git"
    fi

    # Claude Code detection
    if [[ "$(get_bool "$CLAUDE_DIR")" == "false" ]]; then
        add_to_list run_scripts "claude"
    else
        add_to_list optional_scripts "claude"
    fi

    # Package.json detection
    if [[ "$(get_bool "$PACKAGE_JSON")" == "false" ]]; then
        add_to_list run_scripts "packages"
    else
        add_to_list optional_scripts "packages"
    fi

    # TypeScript detection
    if [[ "$(get_bool "$TSCONFIG")" == "false" ]]; then
        if [[ "$(get_bool "$PACKAGE_JSON")" == "true" ]]; then
            add_to_list run_scripts "typescript"
        else
            add_to_list optional_scripts "typescript"
        fi
    else
        add_to_list skip_scripts "typescript"
    fi

    # Docker detection
    if [[ "$(get_bool "$DOCKERFILE")" == "false" ]]; then
        if [[ "$(get_bool "$DOCKER_RUNNING")" == "true" ]]; then
            add_to_list optional_scripts "docker"
        else
            add_to_list optional_scripts "docker"
            if [[ "$(get_bool "$DOCKER_RESULT")" == "true" ]]; then
                add_warning "docker" "Docker installed but not running"
            else
                add_warning "docker" "Docker not installed"
            fi
        fi
    else
        add_to_list skip_scripts "docker"
    fi

    # Linting - always recommend if package.json exists
    if [[ "$(get_bool "$PACKAGE_JSON")" == "true" ]]; then
        local eslint_exists=$(detect_file ".eslintrc.json")
        local prettier_exists=$(detect_file ".prettierrc")
        if [[ "$(get_bool "$eslint_exists")" == "false" ]]; then
            add_to_list run_scripts "linting"
        else
            add_to_list skip_scripts "linting"
        fi
    fi

    # Testing - recommend if package.json exists
    if [[ "$(get_bool "$PACKAGE_JSON")" == "true" ]]; then
        local jest_exists=$(detect_file "jest.config.js")
        local vitest_exists=$(detect_file "vitest.config.ts")
        if [[ "$(get_bool "$jest_exists")" == "false" && "$(get_bool "$vitest_exists")" == "false" ]]; then
            add_to_list optional_scripts "testing"
        else
            add_to_list skip_scripts "testing"
        fi
    fi

    # GitHub - recommend if git repo
    if [[ "$(get_bool "$GIT_REPO")" == "true" ]]; then
        local github_dir=$(detect_file ".github")
        if [[ "$(get_bool "$github_dir")" == "false" ]]; then
            add_to_list optional_scripts "github"
        else
            add_to_list skip_scripts "github"
        fi
    fi

    # Database - optional based on docker
    if [[ "$(get_bool "$DOCKERFILE")" == "true" || "$(get_bool "$DOCKER_COMPOSE")" == "true" ]]; then
        add_to_list optional_scripts "database"
    fi

    # VSCode - always optional
    local vscode_dir=$(detect_file ".vscode")
    if [[ "$(get_bool "$vscode_dir")" == "false" ]]; then
        add_to_list optional_scripts "vscode"
    else
        add_to_list skip_scripts "vscode"
    fi

    # Husky - recommend if git and package.json
    if [[ "$(get_bool "$GIT_REPO")" == "true" && "$(get_bool "$PACKAGE_JSON")" == "true" ]]; then
        local husky_dir=$(detect_file ".husky")
        if [[ "$(get_bool "$husky_dir")" == "false" ]]; then
            add_to_list optional_scripts "husky"
        else
            add_to_list skip_scripts "husky"
        fi
    fi

    # Security - optional for Node projects
    if [[ "$(get_bool "$PACKAGE_JSON")" == "true" ]]; then
        add_to_list optional_scripts "security"
    fi

    # Output JSON
    cat << EOFJSON
{
  "generated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "recommendations": {
    "run": [${run_scripts}],
    "optional": [${optional_scripts}],
    "skip": [${skip_scripts}],
    "warnings": [${warnings}]
  },
  "detection_summary": {
    "has_git_repo": $(get_bool "$GIT_REPO"),
    "has_package_json": $(get_bool "$PACKAGE_JSON"),
    "has_tsconfig": $(get_bool "$TSCONFIG"),
    "has_dockerfile": $(get_bool "$DOCKERFILE"),
    "has_claude_dir": $(get_bool "$CLAUDE_DIR"),
    "docker_running": $(echo "$DOCKER_RUNNING" | cut -d'|' -f1),
    "node_available": $(echo "$NODE_RESULT" | cut -d'|' -f1),
    "git_available": $(echo "$GIT_RESULT" | cut -d'|' -f1)
  }
}
EOFJSON
}

# Generate and save recommendations
RECOMMENDATIONS_FILE="${LOGS_DIR}/bootstrap-recommendations.json"
if [[ "$REGISTRY_AVAILABLE" == "true" ]]; then
    generate_recommendations > "$RECOMMENDATIONS_FILE"
    log_success "Recommendations saved to: $RECOMMENDATIONS_FILE"

    # Also update cache if cache manager available
    if [[ -f "${BOOTSTRAP_DIR}/lib/cache-manager.sh" ]]; then
        source "${BOOTSTRAP_DIR}/lib/cache-manager.sh"
        cache_write "recommendations.json" "$(cat "$RECOMMENDATIONS_FILE")"
        log_info "Recommendations cached for menu"
    fi
fi

# ===================================================================
# Display Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "System detection complete"

show_summary

echo ""
log_success "System detection complete!"
echo ""
echo "Detection Summary:"
echo "  System: $OS_TYPE ($ARCH)"
echo "  Node.js: $(echo "$NODE_RESULT" | cut -d'|' -f1)"
echo "  Docker: $(echo "$DOCKER_RESULT" | cut -d'|' -f1)"
echo "  Git: $(echo "$GIT_RESULT" | cut -d'|' -f1)"
echo ""
echo "Files Updated:"
echo "  Config:      __bootbuild/config/bootstrap.config [detected] section"
echo "               (project-level facts: has_package_json, has_git_repo, etc.)"
echo "  Full Report: __bootbuild/logs/bootstrap-detect-latest.json"
echo "               (host-level detections: git_installed, node_installed, etc.)"
echo "  This Run:    __bootbuild/logs/bootstrap-detect-${TIMESTAMP}.json"
echo "  History:     Last 10 detection runs kept in logs/"
echo ""
echo "Next steps:"
echo "  1. Review host environment capabilities:"
echo "     jq '.' __bootbuild/logs/bootstrap-detect-latest.json"
echo ""
echo "  2. Check project-level detections (committed to repo):"
echo "     grep -A 5 '^\[detected\]' __bootbuild/config/bootstrap.config"
echo ""
if [[ "$(echo "$NODE_RESULT" | cut -d'|' -f1)" == "false" ]] || \
   [[ "$(echo "$DOCKER_RESULT" | cut -d'|' -f1)" == "false" ]] || \
   [[ "$(echo "$PYTHON_RESULT" | cut -d'|' -f1)" == "false" ]]; then
    echo "  3. Install missing tools:"
    if [[ "$(echo "$NODE_RESULT" | cut -d'|' -f1)" == "false" ]]; then
        echo "     - Node.js: https://nodejs.org/ or use nvm"
    fi
    if [[ "$(echo "$DOCKER_RESULT" | cut -d'|' -f1)" == "false" ]]; then
        echo "     - Docker: https://docs.docker.com/get-docker/"
    fi
    if [[ "$(echo "$PYTHON_RESULT" | cut -d'|' -f1)" == "false" ]]; then
        echo "     - Python: https://www.python.org/downloads/"
    fi
    echo ""
fi
echo "Query examples:"
echo "  - Get Node version: jq -r '.tools.runtime.node' __bootbuild/logs/bootstrap-detect-latest.json"
echo "  - Check Docker:     jq -r '.tools.containers.docker_running' __bootbuild/logs/bootstrap-detect-latest.json"
echo "  - List files:       jq '.project.files' __bootbuild/logs/bootstrap-detect-latest.json"
echo ""

# Show recommendations if generated
if [[ -f "$RECOMMENDATIONS_FILE" ]]; then
    echo "Script Recommendations:"
    echo "───────────────────────"

    # Parse and display recommendations
    if command -v jq &>/dev/null; then
        run_count=$(jq -r '.recommendations.run | length' "$RECOMMENDATIONS_FILE")
        optional_count=$(jq -r '.recommendations.optional | length' "$RECOMMENDATIONS_FILE")
        skip_count=$(jq -r '.recommendations.skip | length' "$RECOMMENDATIONS_FILE")
        warning_count=$(jq -r '.recommendations.warnings | length' "$RECOMMENDATIONS_FILE")

        if [[ "$run_count" -gt 0 ]]; then
            echo -e "  ${COLOR_GREEN}Recommended to run:${COLOR_RESET}"
            jq -r '.recommendations.run[]' "$RECOMMENDATIONS_FILE" | while read script; do
                echo "    • $script"
            done
        fi

        if [[ "$optional_count" -gt 0 ]]; then
            echo -e "  ${COLOR_YELLOW}Optional:${COLOR_RESET}"
            jq -r '.recommendations.optional[]' "$RECOMMENDATIONS_FILE" | while read script; do
                echo "    • $script"
            done
        fi

        if [[ "$warning_count" -gt 0 ]]; then
            echo -e "  ${COLOR_RED}Warnings:${COLOR_RESET}"
            jq -r '.recommendations.warnings[] | "    ⚠ \(.script): \(.message)"' "$RECOMMENDATIONS_FILE"
        fi

        echo ""
        echo "  View full recommendations:"
        echo "    jq '.' __bootbuild/logs/bootstrap-recommendations.json"
    fi
    echo ""
fi

show_log_location
