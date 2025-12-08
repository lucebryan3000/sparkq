#!/bin/bash

# ===================================================================
# lib/paths.sh
#
# Centralized path initialization for all bootstrap scripts.
# Source this file in any bootstrap script to initialize all paths.
#
# USAGE:
#   source "${BOOTSTRAP_DIR}/lib/paths.sh"
#   # Now all paths are available:
#   # $BOOTSTRAP_DIR, $MANIFEST_FILE, $CONFIG_FILE, $CONFIG_DIR,
#   # $LIB_DIR, $SCRIPTS_DIR, $TEMPLATES_DIR, $KB_ROOT,
#   # $LOGS_DIR, $LOGS_KB_DIR
#
# DESIGN:
#   This is the single source of truth for path initialization.
#   All scripts source this one file instead of deriving paths
#   independently, eliminating path hardcoding.
#
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_PATHS_LOADED:-}" ]] && return 0
_BOOTSTRAP_PATHS_LOADED=1

# Require BOOTSTRAP_DIR to be set by the calling script
if [[ -z "${BOOTSTRAP_DIR:-}" ]]; then
    echo "ERROR: [Paths] BOOTSTRAP_DIR must be set before sourcing lib/paths.sh" >&2
    echo "       Calling script should derive it:" >&2
    echo "       BOOTSTRAP_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")/../..\" && pwd)\"" >&2
    return 1
fi

# Validate bootstrap-manifest.json exists
if [[ ! -f "${BOOTSTRAP_DIR}/config/bootstrap-manifest.json" ]]; then
    echo "ERROR: [Paths] bootstrap-manifest.json not found at ${BOOTSTRAP_DIR}/config/bootstrap-manifest.json" >&2
    echo "       Bootstrap directory might be incorrect: $BOOTSTRAP_DIR" >&2
    return 1
fi

# ===================================================================
# Core Paths (derived from BOOTSTRAP_DIR)
# ===================================================================

export MANIFEST_FILE="${BOOTSTRAP_DIR}/config/bootstrap-manifest.json"
export CONFIG_DIR="${BOOTSTRAP_DIR}/config"
export CONFIG_FILE="${BOOTSTRAP_DIR}/config/bootstrap.config"
export LIB_DIR="${BOOTSTRAP_DIR}/lib"
export SCRIPTS_DIR="${BOOTSTRAP_DIR}/scripts"
export TEMPLATES_DIR="${BOOTSTRAP_DIR}/templates"
export KB_ROOT="${BOOTSTRAP_DIR}/kb-bootstrap"
export LOGS_DIR="${BOOTSTRAP_DIR}/logs"
export LOGS_KB_DIR="${BOOTSTRAP_DIR}/logs/kb"

# ===================================================================
# Template Subdirectories
# ===================================================================

export TEMPLATES_ROOT="${TEMPLATES_DIR}/root"
export TEMPLATES_CLAUDE="${TEMPLATES_DIR}/.claude"
export TEMPLATES_VSCODE="${TEMPLATES_DIR}/.vscode"
export TEMPLATES_GITHUB="${TEMPLATES_DIR}/.github"
export TEMPLATES_DEVCONTAINER="${TEMPLATES_DIR}/.devcontainer"
export TEMPLATES_SCRIPTS="${TEMPLATES_DIR}/scripts"

# ===================================================================
# Knowledge Base Directories
# ===================================================================

export KB_MANIFEST_FILE="${KB_ROOT}/kb-bootstrap-manifest.json"
export KB_SCAN_REPORT="${LOGS_KB_DIR}/bootstrap-kb-scan.log"

# ===================================================================
# Path Safety Functions
# ===================================================================

# ===================================================================
# Function: validate_safe_path
#
# Description: Check path for dangerous traversal or null byte injection
#
# Usage: validate_safe_path <path>
#
# Arguments:
#   $1 - file path to validate
#
# Returns:
#   0 - path is safe
#   1 - path contains .. traversal or null bytes
#
# Notes:
#   - Prevents path traversal attacks
#   - Detects null byte injection
#   - Used for sanitizing user-provided paths
#
# Example:
#   validate_safe_path "/home/user/project" || exit 1
# ===================================================================
validate_safe_path() {
    local path="$1"

    # Check for path traversal
    if [[ "$path" =~ \.\. ]]; then
        echo "ERROR: [Paths] Path traversal detected in: $path" >&2
        return 1
    fi

    # Check for null bytes
    if [[ "$path" =~ $'\0' ]]; then
        echo "ERROR: [Paths] Null byte detected in path: $path" >&2
        return 1
    fi

    return 0
}

# ===================================================================
# Function: normalize_to_absolute
#
# Description: Convert relative path to absolute path
#
# Usage: normalize_to_absolute <path>
#
# Arguments:
#   $1 - relative or absolute path
#
# Returns:
#   0 - always (outputs absolute path)
#
# Notes:
#   - Preserves absolute paths as-is
#   - Makes relative paths absolute from current directory
#   - Doesn't validate existence
#
# Example:
#   abs=$(normalize_to_absolute "relative/path")
# ===================================================================
normalize_to_absolute() {
    local path="$1"

    # Already absolute
    if [[ "$path" = /* ]]; then
        echo "$path"
        return 0
    fi

    # Make absolute relative to current directory
    echo "$(pwd)/$path"
}

# ===================================================================
# Function: validate_path_boundary
#
# Description: Verify path stays within allowed boundary directory
#
# Usage: validate_path_boundary <path> <boundary>
#
# Arguments:
#   $1 - path to validate
#   $2 - boundary directory (path should be within this)
#
# Returns:
#   0 - path is within boundary
#   1 - path escapes boundary
#
# Notes:
#   - Prevents directory escape attacks
#   - Normalizes both paths before comparison
#   - Useful for restricting operations to project directory
#
# Example:
#   validate_path_boundary "$config_path" "$BOOTSTRAP_DIR" || exit 1
# ===================================================================
validate_path_boundary() {
    local path="$1"
    local boundary="$2"

    # Normalize both paths
    local abs_path=$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")
    local abs_boundary=$(cd "$boundary" 2>/dev/null && pwd)

    # Check if path starts with boundary
    if [[ "$abs_path" != "$abs_boundary"* ]]; then
        echo "ERROR: [Paths] Path escapes boundary: $path (boundary: $boundary)" >&2
        return 1
    fi

    return 0
}

# Export safety functions for use in other scripts
export -f validate_safe_path
export -f normalize_to_absolute
export -f validate_path_boundary

# ===================================================================
# Validation (non-fatal during sourcing)
# ===================================================================

# Validate manifest exists (critical check)
if [[ ! -f "$MANIFEST_FILE" ]]; then
    # Non-fatal during sourcing - let calling script handle
    echo "WARNING: bootstrap-manifest.json not found at $MANIFEST_FILE" >&2
    echo "         Some functionality may be limited" >&2
fi

# Config file may not exist yet (will be created on first use)
if [[ ! -f "$CONFIG_FILE" ]]; then
    # This is normal - config is created by config-manager.sh on demand
    : # no-op
fi
