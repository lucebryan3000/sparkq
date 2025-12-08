#!/bin/bash

# ===================================================================
# bootstrap-python.sh
#
# Purpose: Set up Python virtual environment and dependencies
# Creates: .venv/, .env, pyproject.toml, requirements.txt
# Config:  [python] section in bootstrap.config
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-python"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-python"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "python3" \
    --scripts "bootstrap-project" \
    --optional ""

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Python Virtual Environment & Dependencies" \
    ".venv/" \
    ".env" \
    "requirements.txt" \
    "pyproject.toml"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating Python environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Validate Python is available
command -v python3 >/dev/null 2>&1 || log_fatal "python3 not found in PATH"

log_success "Environment validated"

# ===================================================================
# Configuration
# ===================================================================

# Get python configuration values (with defaults)
PY_VERSION=$(get_config "python.version" "3.11")
PY_BIN=$(get_config "python.bin" "python3")
VENV_MODE=$(get_config "python.venv_mode" "isolated")
WRITE_ENV=$(get_config "python.write_env" "true")
MANAGE_GITIGNORE=$(get_config "python.manage_gitignore" "true")
MANAGE_CLAUDEIGNORE=$(get_config "python.manage_claudeignore" "true")
INSTALL_DEPS=$(get_config "python.install_deps" "true")
EDITABLE_INSTALL=$(get_config "python.editable_install" "false")
ALLOW_EXTERNAL=$(get_config "python.allow_external_paths" "false")

# Resolve paths
VENV_DIR="${PROJECT_ROOT}/.venv"
ENV_PATH="${PROJECT_ROOT}/.env"
GITIGNORE_PATH="${PROJECT_ROOT}/.gitignore"
CLAUDEIGNORE_PATH="${PROJECT_ROOT}/.claudeignore"
HASH_FILE="${VENV_DIR}/.bootstrap.hash"

# Detect dependency files
REQ_FILES=()
[[ -f "${PROJECT_ROOT}/requirements.txt" ]] && REQ_FILES+=("${PROJECT_ROOT}/requirements.txt")
[[ -f "${PROJECT_ROOT}/requirements-dev.txt" ]] && REQ_FILES+=("${PROJECT_ROOT}/requirements-dev.txt")

PYPROJECT_TOML=""
[[ -f "${PROJECT_ROOT}/pyproject.toml" ]] && PYPROJECT_TOML="${PROJECT_ROOT}/pyproject.toml"

# ===================================================================
# Python Version Management
# ===================================================================

log_info "Checking Python version..."

detect_required_python() {
  local required=""
  if [[ -n "${PYPROJECT_TOML}" && -f "${PYPROJECT_TOML}" ]]; then
    # Extract requires-python from pyproject.toml
    required=$(grep -oP '(?<=requires-python\s*=\s*["\047])[^"\047]+' "${PYPROJECT_TOML}" 2>/dev/null || true)
  fi
  if [[ -z "${required}" && -f "${PROJECT_ROOT}/runtime.txt" ]]; then
    required=$(head -n 1 "${PROJECT_ROOT}/runtime.txt" | tr -d '[:space:]')
  fi
  echo "${required}"
}

validate_python_version() {
  local bin="$1"
  local spec="${2:-}"

  if [[ -z "$spec" ]]; then
    return 0
  fi

  # Simple version check: if spec requires 3.11+, check we have at least 3.11
  if [[ "$spec" =~ ^([0-9]+)\.([0-9]+) ]]; then
    local req_major="${BASH_REMATCH[1]}"
    local req_minor="${BASH_REMATCH[2]}"

    local ver_output
    ver_output=$("$bin" --version 2>&1 || true)

    if [[ "$ver_output" =~ ([0-9]+)\.([0-9]+) ]]; then
      local cur_major="${BASH_REMATCH[1]}"
      local cur_minor="${BASH_REMATCH[2]}"

      if (( cur_major < req_major )) || (( cur_major == req_major && cur_minor < req_minor )); then
        log_error "Python ${cur_major}.${cur_minor} found, but ${spec} required"
        return 1
      fi
    fi
  fi

  return 0
}

REQUIRED_PY_SPEC=$(detect_required_python)

if ! validate_python_version "$PY_BIN" "$REQUIRED_PY_SPEC"; then
  log_warning "Python version requirement not met: $REQUIRED_PY_SPEC"
  log_info "Using system python3 (may need pyenv integration in future)"
fi

log_success "Python version check complete"

# ===================================================================
# Virtual Environment Management
# ===================================================================

log_info "Setting up virtual environment..."

get_venv_info() {
  local venv_dir="$1"
  local py_bin="${venv_dir}/bin/python"

  # Python version
  local py_version=""
  if [[ -f "${py_bin}" ]]; then
    py_version=$("${py_bin}" --version 2>&1 | awk '{print $2}')
  fi

  # Package count
  local pkg_count=0
  if [[ -f "${venv_dir}/bin/pip" ]]; then
    pkg_count=$("${venv_dir}/bin/pip" list --quiet 2>/dev/null | wc -l || echo 0)
  fi

  # Modification time (age of venv)
  local age_days=0
  if [[ -d "${venv_dir}" ]]; then
    local mod_time
    mod_time=$(stat -c %Y "${venv_dir}" 2>/dev/null || echo 0)
    local now=$(date +%s)
    age_days=$(( (now - mod_time) / 86400 ))
  fi

  # Size in MB
  local size_mb=0
  if [[ -d "${venv_dir}" ]]; then
    size_mb=$(du -sm "${venv_dir}" 2>/dev/null | awk '{print $1}' || echo 0)
  fi

  echo "${py_version}|${pkg_count}|${age_days}|${size_mb}"
}

prompt_reuse_venv() {
  local venv_dir="$1"
  local venv_info="$2"

  IFS='|' read -r py_version pkg_count age_days size_mb <<< "${venv_info}"

  log_info "Existing virtual environment found:"
  log_info "  Python version: ${py_version:-<unknown>}"
  log_info "  Installed packages: ${pkg_count}"
  log_info "  Age: ${age_days} days"
  log_info "  Size: ${size_mb} MB"

  # In non-interactive mode or with --yes flag, reuse by default
  if [[ ! -t 0 ]] || is_auto_approved "venv_reuse"; then
    return 0
  fi

  # Interactive prompt
  read -r -p "  [R]euse, [C]lean & recreate, [A]bort? [R]: " ans
  case "${ans}" in
    [Cc]*) return 1 ;;  # Clean
    [Aa]*) log_fatal "Aborted" ;;
    *) return 0 ;;      # Reuse (default)
  esac
}

# Create or reuse venv
if [[ ! -d "${VENV_DIR}" ]]; then
  log_info "Creating virtual environment..."

  if ! $PY_BIN -m venv "${VENV_DIR}"; then
    log_fatal "Failed to create virtual environment at ${VENV_DIR}"
  fi

  if ! [[ -f "${VENV_DIR}/bin/activate" ]]; then
    log_fatal "Virtual environment invalid: missing activate script"
  fi

  log_success "Virtual environment created"
else
  # Existing venv found
  if ! [[ -f "${VENV_DIR}/bin/activate" ]]; then
    log_fatal "Existing virtual environment invalid: missing activate script"
  fi

  # Gather and display venv info
  venv_info=$(get_venv_info "${VENV_DIR}")

  # Prompt user if interactive (unless in dry-run)
  if ! prompt_reuse_venv "${VENV_DIR}" "${venv_info}"; then
    log_info "Cleaning and recreating virtual environment..."
    rm -rf "${VENV_DIR}"

    if ! $PY_BIN -m venv "${VENV_DIR}"; then
      log_fatal "Failed to create virtual environment at ${VENV_DIR}"
    fi

    if ! [[ -f "${VENV_DIR}/bin/activate" ]]; then
      log_fatal "Virtual environment invalid: missing activate script"
    fi

    log_success "Virtual environment recreated"
  else
    log_success "Reusing existing virtual environment"
  fi
fi

# Activate venv
# shellcheck source=/dev/null
if ! source "${VENV_DIR}/bin/activate"; then
  log_fatal "Failed to activate virtual environment"
fi

# ===================================================================
# Dependency Installation
# ===================================================================

log_info "Managing dependencies..."

calculate_dep_hash() {
  local payload=""
  payload+="PY_VERSION=${PY_VERSION}"$'\n'
  payload+="VENV_MODE=${VENV_MODE}"$'\n'

  # Include config file hash
  if [[ -f "${BOOTSTRAP_DIR}/../config/bootstrap.config" ]]; then
    payload+=$(<"${BOOTSTRAP_DIR}/../config/bootstrap.config")$'\n'
  fi

  # Include requirement files
  for req in "${REQ_FILES[@]}"; do
    if [[ -f "${req}" ]]; then
      payload+=$(<"${req}")$'\n'
    fi
  done

  # Include pyproject.toml
  if [[ -n "${PYPROJECT_TOML}" && -f "${PYPROJECT_TOML}" ]]; then
    payload+=$(<"${PYPROJECT_TOML}")$'\n'
  fi

  # Include Python and pip versions
  payload+="PY_BIN=${PY_BIN}"$'\n'
  payload+="PIP_VERSION=$(pip --version 2>/dev/null || true)"$'\n'

  # Calculate SHA256 hash
  echo -n "$payload" | sha256sum | awk '{print $1}'
}

install_python_deps() {
  local install_errors=()

  log_info "Upgrading pip..."
  if ! pip install --upgrade pip >/dev/null 2>&1; then
    install_errors+=("pip upgrade failed")
  fi

  # Install from requirements files
  for req in "${REQ_FILES[@]}"; do
    if [[ ! -f "${req}" ]]; then
      install_errors+=("Requirements file not found: ${req}")
      continue
    fi

    log_info "Installing from: $(basename "${req}")..."
    if ! pip install -r "${req}" >/dev/null 2>&1; then
      install_errors+=("Failed to install requirements from ${req}")
    fi
  done

  # Install from pyproject.toml
  if [[ -n "${PYPROJECT_TOML}" && -f "${PYPROJECT_TOML}" ]]; then
    local project_dir
    project_dir="$(cd "$(dirname "${PYPROJECT_TOML}")" && pwd)"

    if [[ "${EDITABLE_INSTALL}" == "true" ]]; then
      log_info "Installing project in editable mode..."
      if ! pip install -e "${project_dir}" >/dev/null 2>&1; then
        install_errors+=("Failed to install project in editable mode")
      fi
    else
      log_info "Installing project..."
      if ! pip install "${project_dir}" >/dev/null 2>&1; then
        install_errors+=("Failed to install project")
      fi
    fi
  fi

  if ((${#install_errors[@]} > 0)); then
    log_error "Installation errors:"
    for err in "${install_errors[@]}"; do
      log_error "  • $err"
    done
    log_fatal "Dependency installation failed"
  fi
}

# Check if dependencies need reinstall using hash
CURRENT_HASH=$(calculate_dep_hash)
NEED_INSTALL="true"

if [[ -f "${HASH_FILE}" ]]; then
  LAST_HASH="$(<"${HASH_FILE}")"
  if [[ "${LAST_HASH}" == "${CURRENT_HASH}" ]]; then
    NEED_INSTALL="false"
    log_success "Dependencies unchanged; skipping install"
  fi
fi

if [[ "${INSTALL_DEPS}" == "false" ]]; then
  NEED_INSTALL="false"
  log_warning "Dependency installation skipped (--no-deps)"
fi

if [[ "${NEED_INSTALL}" == "true" ]]; then
  install_python_deps
  echo "${CURRENT_HASH}" > "${HASH_FILE}"
  log_success "Dependencies installed"
fi

# ===================================================================
# File Operations
# ===================================================================

log_info "Managing project files..."

# Create logs directory
mkdir -p "${PROJECT_ROOT}/logs"

# Write environment file
write_python_env() {
  [[ "${WRITE_ENV}" == "true" ]] || return 0

  mkdir -p "$(dirname "${ENV_PATH}")"

  cat > "${ENV_PATH}" << EOFENV
# Auto-generated by bootstrap-python
PYTHON_VENV="${VENV_DIR}"
PYTHON_BIN="${VENV_DIR}/bin/python"
PROJECT_ROOT="${PROJECT_ROOT}"
VENV_MODE="${VENV_MODE}"
EOFENV

  log_success "Environment file written: ${ENV_PATH}"
}

write_python_env

# Manage .gitignore
if [[ "${MANAGE_GITIGNORE}" == "true" ]]; then
  touch "${GITIGNORE_PATH}"

  for entry in ".venv/" ".env" "__pycache__/" "*.pyc" ".pytest_cache/" "*.egg-info/" "dist/" "build/"; do
    if ! grep -qxF "${entry}" "${GITIGNORE_PATH}"; then
      echo "${entry}" >> "${GITIGNORE_PATH}"
    fi
  done

  log_success "Updated .gitignore"
fi

# Manage .claudeignore
if [[ "${MANAGE_CLAUDEIGNORE}" == "true" && -f "${CLAUDEIGNORE_PATH}" ]]; then
  for entry in ".venv/" "__pycache__/" "*.pyc" ".pytest_cache/" "*.egg-info/" "dist/" "build/"; do
    if ! grep -qxF "${entry}" "${CLAUDEIGNORE_PATH}"; then
      echo "${entry}" >> "${CLAUDEIGNORE_PATH}"
    fi
  done

  log_success "Updated .claudeignore"
fi

# ===================================================================
# Summary & Tracking
# ===================================================================

log_info "Python bootstrap complete"
log_success "Virtual environment ready at: ${VENV_DIR}"

if [[ "${WRITE_ENV}" == "true" ]]; then
  log_success "Environment variables written to: ${ENV_PATH}"
fi

log_success "To activate the virtual environment:"
log_info "  source ${VENV_DIR}/bin/activate"

exit 0
