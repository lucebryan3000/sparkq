#!/bin/bash

# ===================================================================
# python-utils.sh
#
# Python virtual environment and package management utilities
# Source this in scripts that need Python functionality:
#   source "$(dirname "$0")/../lib/python-utils.sh"
#
# Provides:
#   - Python version detection
#   - Virtual environment management (venv, virtualenv, poetry, pipenv)
#   - Package installation and requirements management
#   - Testing helpers (pytest)
#   - Cleanup utilities
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_PYTHON_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_PYTHON_UTILS_LOADED=1

# Source common utilities if not already loaded
if [[ -z "${_BOOTSTRAP_COMMON_LOADED:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/common.sh"
fi

# ===================================================================
# Python Detection
# ===================================================================

# Detect Python version
# Usage: detect_python_version [python_cmd]
# Returns: Version string (e.g., "3.11.5") or empty if not found
detect_python_version() {
    local python_cmd="${1:-python3}"

    if command -v "$python_cmd" &>/dev/null; then
        "$python_cmd" --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1
    else
        echo ""
    fi
}

# Get the best available Python command
# Usage: get_python_command
# Returns: python3, python, or empty
get_python_command() {
    if command -v python3 &>/dev/null; then
        echo "python3"
    elif command -v python &>/dev/null; then
        local version
        version=$(python --version 2>&1)
        if [[ "$version" =~ Python\ 3\. ]]; then
            echo "python"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# Check if Python meets minimum version requirement
# Usage: check_python_version <min_version> [python_cmd]
# Returns: 0 if meets requirement, 1 otherwise
check_python_version() {
    local min_version="$1"
    local python_cmd="${2:-python3}"

    local current_version
    current_version=$(detect_python_version "$python_cmd")

    if [[ -z "$current_version" ]]; then
        return 1
    fi

    # Compare versions using sort -V
    local sorted
    sorted=$(printf '%s\n%s' "$min_version" "$current_version" | sort -V | head -1)

    if [[ "$sorted" == "$min_version" ]]; then
        return 0
    else
        return 1
    fi
}

# ===================================================================
# Package Manager Detection
# ===================================================================

# Detect Python package manager in use
# Usage: detect_python_manager [project_dir]
# Returns: "poetry", "pipenv", "pip", or "unknown"
detect_python_manager() {
    local project_dir="${1:-.}"

    if [[ -f "$project_dir/pyproject.toml" ]]; then
        if grep -q "tool.poetry" "$project_dir/pyproject.toml" 2>/dev/null; then
            echo "poetry"
            return 0
        fi
    fi

    if [[ -f "$project_dir/Pipfile" ]]; then
        echo "pipenv"
        return 0
    fi

    if [[ -f "$project_dir/requirements.txt" ]] || [[ -f "$project_dir/setup.py" ]]; then
        echo "pip"
        return 0
    fi

    echo "unknown"
}

# ===================================================================
# Virtual Environment Management
# ===================================================================

# Check if virtual environment is active
# Usage: check_venv_active
# Returns: 0 if active, 1 otherwise
check_venv_active() {
    [[ -n "${VIRTUAL_ENV:-}" ]] && return 0
    [[ -n "${PIPENV_ACTIVE:-}" ]] && return 0
    return 1
}

# Get virtual environment path
# Usage: get_venv_path [venv_name]
# Returns: Path to venv directory or empty
get_venv_path() {
    local venv_name="${1:-venv}"

    # Check common locations
    local common_paths=(
        "$venv_name"
        ".venv"
        "env"
        ".env"
    )

    for path in "${common_paths[@]}"; do
        if [[ -f "$path/bin/activate" ]] || [[ -f "$path/Scripts/activate" ]]; then
            echo "$path"
            return 0
        fi
    done

    echo ""
}

# Create virtual environment
# Usage: create_venv [venv_path] [python_cmd]
# Returns: 0 on success, 1 on failure
create_venv() {
    local venv_path="${1:-venv}"
    local python_cmd="${2:-python3}"

    if [[ -d "$venv_path" ]]; then
        log_warning "Virtual environment already exists: $venv_path"
        return 0
    fi

    log_info "Creating virtual environment: $venv_path"

    # Try venv module first (built-in to Python 3.3+)
    if "$python_cmd" -m venv "$venv_path" 2>/dev/null; then
        log_success "Created venv at $venv_path"
        return 0
    fi

    # Fallback to virtualenv if available
    if command -v virtualenv &>/dev/null; then
        if virtualenv -p "$python_cmd" "$venv_path" 2>/dev/null; then
            log_success "Created virtualenv at $venv_path"
            return 0
        fi
    fi

    log_error "Failed to create virtual environment"
    return 1
}

# Get activation command for virtual environment
# Usage: get_venv_activate_cmd <venv_path>
# Returns: Activation command string
get_venv_activate_cmd() {
    local venv_path="$1"

    # Check for Unix-style activation
    if [[ -f "$venv_path/bin/activate" ]]; then
        echo "source $venv_path/bin/activate"
        return 0
    fi

    # Check for Windows-style activation
    if [[ -f "$venv_path/Scripts/activate" ]]; then
        echo "source $venv_path/Scripts/activate"
        return 0
    fi

    echo ""
    return 1
}

# Activate virtual environment (for use in subshells)
# Usage: activate_venv <venv_path>
# Returns: 0 on success, 1 on failure
# Note: This only works in subshells. For current shell, use:
#   eval "$(get_venv_activate_cmd venv)"
activate_venv() {
    local venv_path="$1"
    local activate_cmd

    activate_cmd=$(get_venv_activate_cmd "$venv_path")

    if [[ -z "$activate_cmd" ]]; then
        log_error "Cannot find activation script in $venv_path"
        return 1
    fi

    eval "$activate_cmd"
    return $?
}

# ===================================================================
# Package Installation
# ===================================================================

# Install packages from requirements.txt
# Usage: install_pip_packages [requirements_file] [pip_args...]
# Returns: 0 on success, 1 on failure
install_pip_packages() {
    local requirements_file="${1:-requirements.txt}"
    shift
    local pip_args=("$@")

    if [[ ! -f "$requirements_file" ]]; then
        log_error "Requirements file not found: $requirements_file"
        return 1
    fi

    local pip_cmd
    if check_venv_active; then
        pip_cmd="pip"
    else
        pip_cmd="pip3"
    fi

    if ! command -v "$pip_cmd" &>/dev/null; then
        log_error "pip not found"
        return 1
    fi

    log_info "Installing packages from $requirements_file"

    if "$pip_cmd" install -r "$requirements_file" "${pip_args[@]}" 2>&1; then
        log_success "Packages installed successfully"
        return 0
    else
        log_error "Failed to install packages"
        return 1
    fi
}

# Install a single package
# Usage: install_pip_package <package> [pip_args...]
# Returns: 0 on success, 1 on failure
install_pip_package() {
    local package="$1"
    shift
    local pip_args=("$@")

    local pip_cmd
    if check_venv_active; then
        pip_cmd="pip"
    else
        pip_cmd="pip3"
    fi

    if ! command -v "$pip_cmd" &>/dev/null; then
        log_error "pip not found"
        return 1
    fi

    log_info "Installing package: $package"

    if "$pip_cmd" install "$package" "${pip_args[@]}" 2>&1; then
        log_success "Package installed: $package"
        return 0
    else
        log_error "Failed to install package: $package"
        return 1
    fi
}

# Upgrade pip to latest version
# Usage: upgrade_pip
# Returns: 0 on success, 1 on failure
upgrade_pip() {
    local pip_cmd
    if check_venv_active; then
        pip_cmd="pip"
    else
        pip_cmd="pip3"
    fi

    if ! command -v "$pip_cmd" &>/dev/null; then
        log_error "pip not found"
        return 1
    fi

    log_info "Upgrading pip"

    if "$pip_cmd" install --upgrade pip 2>&1; then
        log_success "pip upgraded successfully"
        return 0
    else
        log_error "Failed to upgrade pip"
        return 1
    fi
}

# ===================================================================
# Requirements Management
# ===================================================================

# Freeze current packages to requirements.txt
# Usage: freeze_requirements [output_file]
# Returns: 0 on success, 1 on failure
freeze_requirements() {
    local output_file="${1:-requirements.txt}"

    local pip_cmd
    if check_venv_active; then
        pip_cmd="pip"
    else
        pip_cmd="pip3"
    fi

    if ! command -v "$pip_cmd" &>/dev/null; then
        log_error "pip not found"
        return 1
    fi

    log_info "Freezing requirements to $output_file"

    if "$pip_cmd" freeze > "$output_file" 2>&1; then
        log_success "Requirements saved to $output_file"
        return 0
    else
        log_error "Failed to freeze requirements"
        return 1
    fi
}

# Check if package is installed
# Usage: check_pip_package <package_name>
# Returns: 0 if installed, 1 otherwise
check_pip_package() {
    local package="$1"

    local pip_cmd
    if check_venv_active; then
        pip_cmd="pip"
    else
        pip_cmd="pip3"
    fi

    if ! command -v "$pip_cmd" &>/dev/null; then
        return 1
    fi

    "$pip_cmd" show "$package" &>/dev/null
}

# ===================================================================
# Cleanup Utilities
# ===================================================================

# Remove __pycache__ directories
# Usage: clean_pycache [directory]
# Returns: 0 on success
clean_pycache() {
    local directory="${1:-.}"

    log_info "Cleaning __pycache__ directories in $directory"

    local count=0
    while IFS= read -r -d '' cache_dir; do
        rm -rf "$cache_dir"
        ((count++))
    done < <(find "$directory" -type d -name "__pycache__" -print0 2>/dev/null)

    log_success "Removed $count __pycache__ directories"
    return 0
}

# Remove .pyc files
# Usage: clean_pyc [directory]
# Returns: 0 on success
clean_pyc() {
    local directory="${1:-.}"

    log_info "Cleaning .pyc files in $directory"

    local count=0
    while IFS= read -r -d '' pyc_file; do
        rm -f "$pyc_file"
        ((count++))
    done < <(find "$directory" -type f -name "*.pyc" -print0 2>/dev/null)

    log_success "Removed $count .pyc files"
    return 0
}

# Clean Python build artifacts
# Usage: clean_python_build [directory]
# Returns: 0 on success
clean_python_build() {
    local directory="${1:-.}"

    log_info "Cleaning Python build artifacts in $directory"

    # Remove common build directories
    local build_dirs=(
        "build"
        "dist"
        "*.egg-info"
        ".eggs"
        ".pytest_cache"
        ".mypy_cache"
        ".tox"
        "htmlcov"
        ".coverage"
    )

    local count=0
    for pattern in "${build_dirs[@]}"; do
        while IFS= read -r -d '' item; do
            rm -rf "$item"
            ((count++))
        done < <(find "$directory" -maxdepth 2 -name "$pattern" -print0 2>/dev/null)
    done

    clean_pycache "$directory"
    clean_pyc "$directory"

    log_success "Cleaned Python build artifacts ($count items)"
    return 0
}

# ===================================================================
# Testing Utilities
# ===================================================================

# Run pytest with common options
# Usage: run_pytest [pytest_args...]
# Returns: pytest exit code
run_pytest() {
    local pytest_args=("$@")

    local pytest_cmd
    if check_venv_active; then
        pytest_cmd="pytest"
    else
        pytest_cmd="pytest"
        if ! command -v pytest &>/dev/null && command -v python3 &>/dev/null; then
            pytest_cmd="python3 -m pytest"
        fi
    fi

    if ! command -v pytest &>/dev/null && ! python3 -m pytest --version &>/dev/null 2>&1; then
        log_error "pytest not found. Install with: pip install pytest"
        return 1
    fi

    log_info "Running pytest"

    if [[ ${#pytest_args[@]} -eq 0 ]]; then
        pytest_args=("-v")
    fi

    $pytest_cmd "${pytest_args[@]}"
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "All tests passed"
    else
        log_error "Tests failed (exit code: $exit_code)"
    fi

    return $exit_code
}

# Run pytest with coverage
# Usage: run_pytest_coverage [coverage_args...] [-- pytest_args...]
# Returns: pytest exit code
run_pytest_coverage() {
    local coverage_args=()
    local pytest_args=()
    local in_pytest_args=0

    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            in_pytest_args=1
            continue
        fi

        if [[ $in_pytest_args -eq 1 ]]; then
            pytest_args+=("$arg")
        else
            coverage_args+=("$arg")
        fi
    done

    if ! check_pip_package "pytest-cov"; then
        log_warning "pytest-cov not installed. Install with: pip install pytest-cov"
        return 1
    fi

    log_info "Running pytest with coverage"

    local cmd_args=("--cov" "${coverage_args[@]}" "${pytest_args[@]}")
    run_pytest "${cmd_args[@]}"
}

# ===================================================================
# Poetry Utilities
# ===================================================================

# Check if poetry is available
# Usage: check_poetry
# Returns: 0 if available, 1 otherwise
check_poetry() {
    command -v poetry &>/dev/null
}

# Install dependencies using poetry
# Usage: poetry_install [poetry_args...]
# Returns: 0 on success, 1 on failure
poetry_install() {
    local poetry_args=("$@")

    if ! check_poetry; then
        log_error "Poetry not found"
        return 1
    fi

    log_info "Installing dependencies with Poetry"

    if poetry install "${poetry_args[@]}" 2>&1; then
        log_success "Dependencies installed with Poetry"
        return 0
    else
        log_error "Failed to install dependencies with Poetry"
        return 1
    fi
}

# ===================================================================
# Pipenv Utilities
# ===================================================================

# Check if pipenv is available
# Usage: check_pipenv
# Returns: 0 if available, 1 otherwise
check_pipenv() {
    command -v pipenv &>/dev/null
}

# Install dependencies using pipenv
# Usage: pipenv_install [pipenv_args...]
# Returns: 0 on success, 1 on failure
pipenv_install() {
    local pipenv_args=("$@")

    if ! check_pipenv; then
        log_error "Pipenv not found"
        return 1
    fi

    log_info "Installing dependencies with Pipenv"

    if pipenv install "${pipenv_args[@]}" 2>&1; then
        log_success "Dependencies installed with Pipenv"
        return 0
    else
        log_error "Failed to install dependencies with Pipenv"
        return 1
    fi
}

# ===================================================================
# High-Level Setup Functions
# ===================================================================

# Setup Python environment (auto-detect manager)
# Usage: setup_python_env [project_dir]
# Returns: 0 on success, 1 on failure
setup_python_env() {
    local project_dir="${1:-.}"
    local manager

    manager=$(detect_python_manager "$project_dir")

    case "$manager" in
        poetry)
            log_info "Detected Poetry project"
            poetry_install
            ;;
        pipenv)
            log_info "Detected Pipenv project"
            pipenv_install
            ;;
        pip)
            log_info "Detected pip project"
            local venv_path
            venv_path=$(get_venv_path)

            if [[ -z "$venv_path" ]]; then
                create_venv "venv" || return 1
                venv_path="venv"
            fi

            log_info "Activating virtual environment"
            activate_venv "$venv_path" || return 1

            if [[ -f "$project_dir/requirements.txt" ]]; then
                install_pip_packages "$project_dir/requirements.txt"
            else
                log_warning "No requirements.txt found"
            fi
            ;;
        unknown)
            log_warning "No Python package manager detected"
            return 1
            ;;
    esac
}
