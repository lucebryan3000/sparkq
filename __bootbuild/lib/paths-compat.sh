#!/bin/bash

# ===================================================================
# lib/paths-compat.sh
#
# Legacy compatibility layer for bootstrap path initialization.
# Provides backward compatibility for scripts using old path definitions.
#
# USAGE:
#   source "${BOOTSTRAP_DIR}/lib/paths.sh"
#   source "${BOOTSTRAP_DIR}/lib/paths-compat.sh"
#   # Now old variable names still work:
#   # $BOOTSTRAP_HOME, $BOOTSTRAP_CONFIG_PATH, $BOOTSTRAP_LIBS, etc.
#
# DESIGN:
#   Maps legacy variable names to new paths.sh variables.
#   Helps scripts transition from hardcoded paths to centralized paths.
#   Should only be sourced by old scripts that need compatibility.
#
# ===================================================================

# Ensure paths.sh is already sourced
if [[ -z "${BOOTSTRAP_DIR:-}" ]]; then
    echo "ERROR: lib/paths-compat.sh requires lib/paths.sh to be sourced first" >&2
    return 1
fi

# ===================================================================
# Legacy Path Aliases (Old Name -> New Name)
# ===================================================================

# Backward compatibility for scripts using BOOTSTRAP_HOME
export BOOTSTRAP_HOME="${BOOTSTRAP_DIR}"

# Backward compatibility for config paths
export BOOTSTRAP_CONFIG_DIR="${CONFIG_DIR}"
export BOOTSTRAP_CONFIG_PATH="${CONFIG_FILE}"
export BOOTSTRAP_CONFIG="${CONFIG_FILE}"

# Backward compatibility for library paths
export BOOTSTRAP_LIBS="${LIB_DIR}"
export BOOTSTRAP_LIB_DIR="${LIB_DIR}"

# Backward compatibility for script paths
export BOOTSTRAP_SCRIPTS_DIR="${SCRIPTS_DIR}"
export BOOTSTRAP_SCRIPTS="${SCRIPTS_DIR}"

# Backward compatibility for template paths
export BOOTSTRAP_TEMPLATES="${TEMPLATES_DIR}"
export BOOTSTRAP_TEMPLATE_DIR="${TEMPLATES_DIR}"

# Backward compatibility for knowledge base paths
export KB_DIR="${KB_ROOT}"
export KB_BOOTSTRAP_DIR="${KB_ROOT}"
export BOOTSTRAP_KB_DIR="${KB_ROOT}"

# Backward compatibility for logging paths
export BOOTSTRAP_LOGS="${LOGS_DIR}"
export BOOTSTRAP_LOGS_DIR="${LOGS_DIR}"

# ===================================================================
# Legacy Path Construction Functions (Deprecated)
# ===================================================================

# DEPRECATED: Use paths.sh directly instead
# Kept for backward compatibility with old scripts
get_bootstrap_path() {
    local path_type="$1"
    case "$path_type" in
        "config") echo "$CONFIG_DIR" ;;
        "lib"|"libs") echo "$LIB_DIR" ;;
        "scripts") echo "$SCRIPTS_DIR" ;;
        "templates") echo "$TEMPLATES_DIR" ;;
        "kb") echo "$KB_ROOT" ;;
        "logs") echo "$LOGS_DIR" ;;
        *) echo "$BOOTSTRAP_DIR" ;;
    esac
}

# DEPRECATED: Use $CONFIG_FILE directly instead
get_config_file() {
    echo "$CONFIG_FILE"
}

# DEPRECATED: Use $MANIFEST_FILE directly instead
get_manifest_file() {
    echo "$MANIFEST_FILE"
}

# ===================================================================
# Deprecation Warnings (Optional - can be disabled)
# ===================================================================

# Set BOOTSTRAP_COMPAT_VERBOSE=1 to see deprecation warnings
if [[ "${BOOTSTRAP_COMPAT_VERBOSE:-0}" == "1" ]]; then
    cat >&2 <<'WARN'
WARNING: Using lib/paths-compat.sh for backward compatibility.
         Please update scripts to use lib/paths.sh directly.
         
         Old variable names still work but are deprecated:
         - BOOTSTRAP_HOME    → use BOOTSTRAP_DIR
         - BOOTSTRAP_CONFIG  → use CONFIG_FILE
         - BOOTSTRAP_LIBS    → use LIB_DIR
         - BOOTSTRAP_SCRIPTS → use SCRIPTS_DIR
         - BOOTSTRAP_KB_DIR  → use KB_ROOT
         
         Scheduled for removal in: Phase 4 (next major version)
WARN
fi

# ===================================================================
# Migration Helper Functions
# ===================================================================

# Check if script is using any legacy variables
check_legacy_usage() {
    local script_file="$1"
    
    if [[ ! -f "$script_file" ]]; then
        echo "ERROR: Script file not found: $script_file" >&2
        return 1
    fi
    
    local legacy_vars=(
        "BOOTSTRAP_HOME"
        "BOOTSTRAP_CONFIG_DIR"
        "BOOTSTRAP_CONFIG_PATH"
        "BOOTSTRAP_LIBS"
        "BOOTSTRAP_SCRIPTS_DIR"
        "BOOTSTRAP_TEMPLATES"
        "KB_DIR"
    )
    
    local found_legacy=false
    
    for var in "${legacy_vars[@]}"; do
        if grep -q "\$${var}" "$script_file" 2>/dev/null; then
            echo "Found legacy variable: $var in $script_file"
            found_legacy=true
        fi
    done
    
    if [[ "$found_legacy" == true ]]; then
        echo "This script uses legacy path variables."
        echo "Consider migrating to lib/paths.sh directly."
        return 1
    fi
    
    return 0
}

# List all legacy variables and their current values
show_legacy_mappings() {
    cat <<EOF
=== Legacy Path Mappings ===

Old Variable                New Variable           Value
---------------------------  -------------------  -------
BOOTSTRAP_HOME               BOOTSTRAP_DIR          $BOOTSTRAP_DIR
BOOTSTRAP_CONFIG_DIR         CONFIG_DIR             $CONFIG_DIR
BOOTSTRAP_CONFIG_PATH        CONFIG_FILE            $CONFIG_FILE
BOOTSTRAP_CONFIG             CONFIG_FILE            $CONFIG_FILE
BOOTSTRAP_LIBS               LIB_DIR                $LIB_DIR
BOOTSTRAP_LIB_DIR            LIB_DIR                $LIB_DIR
BOOTSTRAP_SCRIPTS_DIR        SCRIPTS_DIR            $SCRIPTS_DIR
BOOTSTRAP_SCRIPTS            SCRIPTS_DIR            $SCRIPTS_DIR
BOOTSTRAP_TEMPLATES          TEMPLATES_DIR          $TEMPLATES_DIR
BOOTSTRAP_TEMPLATE_DIR       TEMPLATES_DIR          $TEMPLATES_DIR
KB_DIR                       KB_ROOT                $KB_ROOT
KB_BOOTSTRAP_DIR             KB_ROOT                $KB_ROOT
BOOTSTRAP_KB_DIR             KB_ROOT                $KB_ROOT
BOOTSTRAP_LOGS               LOGS_DIR               $LOGS_DIR
BOOTSTRAP_LOGS_DIR           LOGS_DIR               $LOGS_DIR

NOTE: Legacy variables are exported and functional for backward compatibility,
      but should not be used in new code. Use the new variable names instead.
EOF
}

# ===================================================================
# Verification
# ===================================================================

# Verify that paths.sh was sourced first
if [[ -z "${MANIFEST_FILE:-}" ]]; then
    echo "ERROR: lib/paths-compat.sh requires lib/paths.sh to be sourced FIRST" >&2
    return 1
fi

export BOOTSTRAP_COMPAT_LOADED=1
