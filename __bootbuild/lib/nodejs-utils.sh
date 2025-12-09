#!/bin/bash

# ===================================================================
# nodejs-utils.sh
#
# Node.js and npm ecosystem utility library
# Source this in scripts that need Node.js operations:
#   source "$(dirname "$0")/../lib/nodejs-utils.sh"
#
# Provides:
#   - Package manager detection (npm, pnpm, yarn, bun)
#   - Dependency installation and management
#   - Node.js version detection and management
#   - Lockfile validation
#   - Security auditing
#   - Module path resolution
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_NODEJS_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_NODEJS_UTILS_LOADED=1

# Source common utilities if not already loaded
if [[ -z "${_BOOTSTRAP_COMMON_LOADED:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/common.sh"
fi

# ===================================================================
# Package Manager Detection
# ===================================================================

# Detect which package manager is used in the current project
# Returns: npm|pnpm|yarn|bun or empty string if none detected/installed
# Usage: PM=$(detect_package_manager)
detect_package_manager() {
    local project_dir="${1:-.}"

    # Check for lockfiles in priority order and verify command exists
    if [[ -f "${project_dir}/bun.lockb" ]]; then
        command -v bun &>/dev/null && echo "bun" || echo ""
    elif [[ -f "${project_dir}/pnpm-lock.yaml" ]]; then
        command -v pnpm &>/dev/null && echo "pnpm" || echo ""
    elif [[ -f "${project_dir}/yarn.lock" ]]; then
        command -v yarn &>/dev/null && echo "yarn" || echo ""
    elif [[ -f "${project_dir}/package-lock.json" ]]; then
        command -v npm &>/dev/null && echo "npm" || echo ""
    else
        # No lockfile found, check package.json for packageManager field
        if [[ -f "${project_dir}/package.json" ]]; then
            local pm_field
            pm_field=$(grep -o '"packageManager"[[:space:]]*:[[:space:]]*"[^"]*"' "${project_dir}/package.json" 2>/dev/null | cut -d'"' -f4)
            if [[ -n "$pm_field" ]]; then
                # Extract package manager name before @ version
                local pm_name="${pm_field%%@*}"
                command -v "$pm_name" &>/dev/null && echo "$pm_name" || echo ""
                return 0
            fi
        fi

        # Default to npm only if npm is installed
        if command -v npm &>/dev/null; then
            echo "npm"
        else
            echo ""
        fi
    fi
}

# Get the install command for a package manager
# Usage: get_install_command <package_manager>
get_install_command() {
    local pm="$1"

    case "$pm" in
        npm)
            echo "npm install"
            ;;
        pnpm)
            echo "pnpm install"
            ;;
        yarn)
            echo "yarn install"
            ;;
        bun)
            echo "bun install"
            ;;
        *)
            echo "npm install"
            ;;
    esac
}

# Get the run command for a package manager
# Usage: get_run_command <package_manager> <script_name>
get_run_command() {
    local pm="$1"
    local script="$2"

    case "$pm" in
        npm)
            echo "npm run ${script}"
            ;;
        pnpm)
            echo "pnpm run ${script}"
            ;;
        yarn)
            echo "yarn run ${script}"
            ;;
        bun)
            echo "bun run ${script}"
            ;;
        *)
            echo "npm run ${script}"
            ;;
    esac
}

# ===================================================================
# Dependency Installation
# ===================================================================

# Install dependencies using the detected package manager
# Usage: install_dependencies [project_dir] [--frozen]
install_dependencies() {
    local project_dir="${1:-.}"
    local frozen="${2:-}"

    # Validate project_dir exists
    [[ ! -d "$project_dir" ]] && { log_error "Project directory not found: $project_dir"; return 1; }

    # Validate package.json exists
    if [[ ! -f "${project_dir}/package.json" ]]; then
        log_error "No package.json found in ${project_dir}"
        return 1
    fi

    # Validate package.json is valid JSON
    if command -v python3 &>/dev/null; then
        if ! python3 -c "import json; json.load(open('${project_dir}/package.json'))" 2>/dev/null; then
            log_error "Invalid JSON in package.json"
            return 1
        fi
    else
        log_warning "python3 not available, skipping package.json validation"
    fi

    local pm
    pm=$(detect_package_manager "$project_dir")

    # Validate package manager was detected and is available
    if [[ -z "$pm" ]]; then
        log_error "No package manager detected or available"
        return 1
    fi

    if ! command -v "$pm" &>/dev/null; then
        log_error "Package manager '${pm}' not found in PATH"
        return 1
    fi

    log_info "Installing dependencies with ${pm}..."

    local install_cmd
    case "$pm" in
        npm)
            install_cmd="npm ci"
            [[ "$frozen" == "--frozen" ]] && install_cmd="npm ci"
            [[ "$frozen" != "--frozen" ]] && install_cmd="npm install"
            ;;
        pnpm)
            install_cmd="pnpm install"
            [[ "$frozen" == "--frozen" ]] && install_cmd="pnpm install --frozen-lockfile"
            ;;
        yarn)
            install_cmd="yarn install"
            [[ "$frozen" == "--frozen" ]] && install_cmd="yarn install --frozen-lockfile"
            ;;
        bun)
            install_cmd="bun install"
            [[ "$frozen" == "--frozen" ]] && install_cmd="bun install --frozen-lockfile"
            ;;
    esac

    (cd "$project_dir" && eval "$install_cmd")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "Dependencies installed successfully"
        return 0
    else
        log_error "Failed to install dependencies (exit code: ${exit_code})"
        return 1
    fi
}

# ===================================================================
# Script Execution
# ===================================================================

# Run a package.json script
# Usage: run_npm_script <script_name> [project_dir] [args...]
run_npm_script() {
    local script_name="$1"
    local project_dir="${2:-.}"
    shift 2 || shift 1 # Remove first 1-2 args
    local args=("$@")

    if [[ ! -f "${project_dir}/package.json" ]]; then
        log_error "No package.json found in ${project_dir}"
        return 1
    fi

    # Check if script exists
    if ! grep -q "\"${script_name}\"" "${project_dir}/package.json"; then
        log_error "Script '${script_name}' not found in package.json"
        return 1
    fi

    local pm
    pm=$(detect_package_manager "$project_dir")

    if ! command -v "$pm" &>/dev/null; then
        log_error "Package manager '${pm}' not found in PATH"
        return 1
    fi

    log_info "Running script '${script_name}' with ${pm}..."

    local run_cmd
    run_cmd=$(get_run_command "$pm" "$script_name")

    (cd "$project_dir" && eval "$run_cmd ${args[*]}")
    return $?
}

# ===================================================================
# Node.js Version Detection
# ===================================================================

# Get the currently active Node.js version
# Usage: NODE_VERSION=$(detect_node_version)
detect_node_version() {
    if ! command -v node &>/dev/null; then
        echo ""
        return 1
    fi

    node --version 2>/dev/null | sed 's/^v//'
}

# Get the required Node.js version from package.json
# Usage: REQUIRED_VERSION=$(get_required_node_version [project_dir])
get_required_node_version() {
    local project_dir="${1:-.}"

    if [[ ! -f "${project_dir}/package.json" ]]; then
        echo ""
        return 1
    fi

    # Check engines.node field
    local node_version
    node_version=$(grep -A 1 '"engines"' "${project_dir}/package.json" | grep '"node"' | cut -d'"' -f4)

    if [[ -n "$node_version" ]]; then
        # Clean version specifier (remove ^, ~, >=, etc.)
        echo "$node_version" | sed 's/[^0-9.]//g'
    else
        echo ""
    fi
}

# Check if nvm (Node Version Manager) is available
# Usage: if check_nvm; then ...
check_nvm() {
    if [[ -n "${NVM_DIR:-}" ]] && [[ -s "${NVM_DIR}/nvm.sh" ]]; then
        return 0
    elif command -v nvm &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if fnm (Fast Node Manager) is available
# Usage: if check_fnm; then ...
check_fnm() {
    command -v fnm &>/dev/null
}

# Check if any Node version manager is available
# Returns: nvm|fnm|none
check_node_version_manager() {
    if check_nvm; then
        echo "nvm"
    elif check_fnm; then
        echo "fnm"
    else
        echo "none"
    fi
}

# ===================================================================
# Lockfile Validation
# ===================================================================

# Validate that lockfile is in sync with package.json
# Usage: validate_lockfile [project_dir]
validate_lockfile() {
    local project_dir="${1:-.}"

    if [[ ! -f "${project_dir}/package.json" ]]; then
        log_error "No package.json found in ${project_dir}"
        return 1
    fi

    local pm
    pm=$(detect_package_manager "$project_dir")

    log_info "Validating lockfile for ${pm}..."

    case "$pm" in
        npm)
            if [[ ! -f "${project_dir}/package-lock.json" ]]; then
                log_warning "No package-lock.json found"
                return 1
            fi
            # npm will validate on install
            (cd "$project_dir" && npm install --package-lock-only --dry-run &>/dev/null)
            ;;
        pnpm)
            if [[ ! -f "${project_dir}/pnpm-lock.yaml" ]]; then
                log_warning "No pnpm-lock.yaml found"
                return 1
            fi
            (cd "$project_dir" && pnpm install --lockfile-only --dry-run &>/dev/null)
            ;;
        yarn)
            if [[ ! -f "${project_dir}/yarn.lock" ]]; then
                log_warning "No yarn.lock found"
                return 1
            fi
            (cd "$project_dir" && yarn install --mode skip-build --dry-run &>/dev/null)
            ;;
        bun)
            if [[ ! -f "${project_dir}/bun.lockb" ]]; then
                log_warning "No bun.lockb found"
                return 1
            fi
            # bun doesn't have a dry-run validation mode
            return 0
            ;;
    esac

    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_success "Lockfile is valid"
        return 0
    else
        log_error "Lockfile validation failed"
        return 1
    fi
}

# ===================================================================
# Module Path Resolution
# ===================================================================

# Resolve the path to a node module
# Usage: MODULE_PATH=$(get_module_path <module_name> [project_dir])
get_module_path() {
    local module_name="$1"
    local project_dir="${2:-.}"

    if [[ ! -d "${project_dir}/node_modules" ]]; then
        echo ""
        return 1
    fi

    local module_path="${project_dir}/node_modules/${module_name}"

    if [[ -d "$module_path" ]]; then
        echo "$module_path"
        return 0
    else
        echo ""
        return 1
    fi
}

# Check if a module is installed
# Usage: if is_module_installed <module_name> [project_dir]; then ...
is_module_installed() {
    local module_name="$1"
    local project_dir="${2:-.}"

    [[ -n "$(get_module_path "$module_name" "$project_dir")" ]]
}

# ===================================================================
# Cleanup Operations
# ===================================================================

# Remove node_modules directory
# Usage: clean_node_modules [project_dir]
clean_node_modules() {
    local project_dir="${1:-.}"

    if [[ ! -d "${project_dir}/node_modules" ]]; then
        log_info "No node_modules directory found"
        return 0
    fi

    log_info "Removing node_modules..."
    rm -rf "${project_dir}/node_modules"

    if [[ $? -eq 0 ]]; then
        log_success "node_modules removed successfully"
        return 0
    else
        log_error "Failed to remove node_modules"
        return 1
    fi
}

# Clean package manager cache
# Usage: clean_package_manager_cache [npm|pnpm|yarn|bun]
clean_package_manager_cache() {
    local pm="${1:-}"

    if [[ -z "$pm" ]]; then
        pm=$(detect_package_manager)
    fi

    log_info "Cleaning ${pm} cache..."

    case "$pm" in
        npm)
            npm cache clean --force
            ;;
        pnpm)
            pnpm store prune
            ;;
        yarn)
            yarn cache clean
            ;;
        bun)
            # bun doesn't have a cache clean command yet
            log_warning "Bun cache cleaning not supported"
            return 0
            ;;
        *)
            log_error "Unknown package manager: ${pm}"
            return 1
            ;;
    esac

    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_success "Cache cleaned successfully"
        return 0
    else
        log_error "Failed to clean cache"
        return 1
    fi
}

# ===================================================================
# Security Auditing
# ===================================================================

# Run security audit on dependencies
# Usage: audit_dependencies [project_dir] [--fix]
audit_dependencies() {
    local project_dir="${1:-.}"
    local auto_fix="${2:-}"

    if [[ ! -f "${project_dir}/package.json" ]]; then
        log_error "No package.json found in ${project_dir}"
        return 1
    fi

    local pm
    pm=$(detect_package_manager "$project_dir")

    if ! command -v "$pm" &>/dev/null; then
        log_error "Package manager '${pm}' not found in PATH"
        return 1
    fi

    log_info "Running security audit with ${pm}..."

    local audit_cmd
    case "$pm" in
        npm)
            audit_cmd="npm audit"
            [[ "$auto_fix" == "--fix" ]] && audit_cmd="npm audit fix"
            ;;
        pnpm)
            audit_cmd="pnpm audit"
            [[ "$auto_fix" == "--fix" ]] && audit_cmd="pnpm audit --fix"
            ;;
        yarn)
            audit_cmd="yarn audit"
            [[ "$auto_fix" == "--fix" ]] && log_warning "Yarn audit --fix not supported, use 'yarn upgrade' manually"
            ;;
        bun)
            # bun doesn't have audit command yet
            log_warning "Bun audit not supported, falling back to npm audit"
            audit_cmd="npm audit"
            [[ "$auto_fix" == "--fix" ]] && audit_cmd="npm audit fix"
            ;;
    esac

    (cd "$project_dir" && eval "$audit_cmd")
    local exit_code=$?

    # Note: audit commands return non-zero if vulnerabilities found
    if [[ $exit_code -eq 0 ]]; then
        log_success "No vulnerabilities found"
        return 0
    else
        log_warning "Vulnerabilities detected (exit code: ${exit_code})"
        return $exit_code
    fi
}

# ===================================================================
# Export Functions (for documentation purposes)
# ===================================================================

# Available functions:
#   - detect_package_manager [project_dir]
#   - get_install_command <package_manager>
#   - get_run_command <package_manager> <script_name>
#   - install_dependencies [project_dir] [--frozen]
#   - run_npm_script <script_name> [project_dir] [args...]
#   - detect_node_version
#   - get_required_node_version [project_dir]
#   - check_nvm
#   - check_fnm
#   - check_node_version_manager
#   - validate_lockfile [project_dir]
#   - get_module_path <module_name> [project_dir]
#   - is_module_installed <module_name> [project_dir]
#   - clean_node_modules [project_dir]
#   - clean_package_manager_cache [npm|pnpm|yarn|bun]
#   - audit_dependencies [project_dir] [--fix]
