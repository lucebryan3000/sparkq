#!/bin/bash

# ===================================================================
# lib/script-registry.sh
#
# Script discovery and manifest queries for bootstrap system.
# Reads from bootstrap-manifest.json to provide script metadata.
#
# USAGE:
#   source "${LIB_DIR}/script-registry.sh"
#
#   # Get all scripts for a phase
#   scripts=$(registry_get_phase_scripts 1)
#
#   # Get script metadata
#   desc=$(registry_get_script_field "docker" "description")
#
#   # Check if script exists
#   registry_script_exists "docker" && echo "yes"
#
# REQUIRES:
#   - jq (for JSON parsing)
#   - MANIFEST_FILE environment variable set
# ===================================================================

# Prevent double-sourcing
[[ -n "${_SCRIPT_REGISTRY_LOADED:-}" ]] && return 0
_SCRIPT_REGISTRY_LOADED=1

# ===================================================================
# JSON Cache
# ===================================================================

# Cache for parsed manifest JSON to avoid repeated file reads
_MANIFEST_JSON_CACHE=""
_MANIFEST_MTIME_CACHE=""

# Get cached manifest JSON or read and cache it
# Returns: Full manifest JSON content
_get_manifest_json() {
    # Check if manifest file has changed
    local current_mtime=""
    if [[ -f "$MANIFEST_FILE" ]]; then
        current_mtime=$(stat -c %Y "$MANIFEST_FILE" 2>/dev/null || stat -f %m "$MANIFEST_FILE" 2>/dev/null || echo "0")
    fi

    # Return cached version if still valid
    if [[ -n "$_MANIFEST_JSON_CACHE" && "$_MANIFEST_MTIME_CACHE" == "$current_mtime" ]]; then
        echo "$_MANIFEST_JSON_CACHE"
        return 0
    fi

    # Cache miss or stale - read and cache the file
    if [[ -f "$MANIFEST_FILE" ]]; then
        _MANIFEST_JSON_CACHE=$(cat "$MANIFEST_FILE")
        _MANIFEST_MTIME_CACHE="$current_mtime"
        echo "$_MANIFEST_JSON_CACHE"
        return 0
    fi

    return 1
}

# Clear the manifest cache (useful for testing or forced reload)
_clear_manifest_cache() {
    _MANIFEST_JSON_CACHE=""
    _MANIFEST_MTIME_CACHE=""
}

# ===================================================================
# Validation
# ===================================================================

# Ensure jq is available
if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required for script-registry.sh" >&2
    echo "       Install with: sudo apt install jq" >&2
    return 1
fi

# Ensure MANIFEST_FILE is set
if [[ -z "${MANIFEST_FILE:-}" ]]; then
    echo "ERROR: MANIFEST_FILE must be set before sourcing script-registry.sh" >&2
    return 1
fi

# Ensure manifest exists
if [[ ! -f "$MANIFEST_FILE" ]]; then
    echo "ERROR: Manifest file not found: $MANIFEST_FILE" >&2
    return 1
fi

# ===================================================================
# Core Query Functions
# ===================================================================

# Get a field from a script entry
# Usage: registry_get_script_field "docker" "description"
registry_get_script_field() {
    local script_name="$1"
    local field="$2"
    _get_manifest_json | jq -r ".scripts.\"$script_name\".\"$field\" // empty"
}

# Get all script names
# Usage: scripts=$(registry_get_all_scripts)
registry_get_all_scripts() {
    _get_manifest_json | jq -r '.scripts | keys[]' | grep -v '^$'
}

# Get all visible scripts (not hidden)
# Usage: scripts=$(registry_get_visible_scripts)
registry_get_visible_scripts() {
    _get_manifest_json | jq -r '.scripts | to_entries[] | select(.value.hidden != true) | .key'
}

# Get scripts for a specific phase
# Usage: scripts=$(registry_get_phase_scripts 1)
registry_get_phase_scripts() {
    local phase="$1"
    _get_manifest_json | jq -r ".scripts | to_entries[] | select(.value.phase == $phase and .value.hidden != true) | .key"
}

# Get script count for a phase
# Usage: count=$(registry_get_phase_count 1)
registry_get_phase_count() {
    local phase="$1"
    _get_manifest_json | jq "[.scripts | to_entries[] | select(.value.phase == $phase and .value.hidden != true)] | length"
}

# Check if script exists in manifest
# Usage: registry_script_exists "docker" && echo "exists"
registry_script_exists() {
    local script_name="$1"
    _get_manifest_json | jq -e ".scripts.\"$script_name\"" &>/dev/null
}

# Check if script file exists on disk
# Usage: registry_script_file_exists "docker" && echo "file exists"
registry_script_file_exists() {
    local script_name="$1"
    local file=$(registry_get_script_field "$script_name" "file")
    local resolved_path=$(_registry_resolve_script_path "$file")
    [[ -n "$resolved_path" && -f "$resolved_path" ]]
}

# Get script filename
# Usage: file=$(registry_get_script_file "docker")
registry_get_script_file() {
    local script_name="$1"
    registry_get_script_field "$script_name" "file"
}

# Resolve a manifest file entry to an absolute script path.
# Supports file values that are absolute, repo-relative (e.g. "__bootbuild/..."),
# template-relative ("templates/scripts/..."), or just the bare filename.
_registry_resolve_script_path() {
    local file="$1"
    [[ -z "$file" ]] && return 0

    local repo_root
    repo_root=$(cd "${BOOTSTRAP_DIR}/.." && pwd)
    local basefile
    basefile=$(basename "$file")

    # Build candidate paths in order of likelihood and return the first that exists
    local -a candidates=()

    # Absolute path provided
    [[ "$file" = /* ]] && candidates+=("$file")

    # Repo-root relative (handles "__bootbuild/..." values)
    candidates+=("${repo_root}/${file}")

    # Bootstrap dir relative (handles "templates/scripts/..." values)
    candidates+=("${BOOTSTRAP_DIR}/${file}")

    # Template scripts directory (handles bare filenames)
    candidates+=("${TEMPLATES_SCRIPTS}/${file}")
    candidates+=("${TEMPLATES_SCRIPTS}/${basefile}")

    for candidate in "${candidates[@]}"; do
        [[ -z "$candidate" ]] && continue
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    # Fallback: return best-guess path even if it doesn't exist (upstream handles the check)
    echo "${TEMPLATES_SCRIPTS}/${basefile}"
}

# Get script's full path
# Usage: path=$(registry_get_script_path "docker")
registry_get_script_path() {
    local script_name="$1"
    local file=$(registry_get_script_file "$script_name")
    _registry_resolve_script_path "$file"
}

# Check if script has questions
# Usage: registry_has_questions "docker" && echo "has questions"
registry_has_questions() {
    local script_name="$1"
    local questions=$(registry_get_script_field "$script_name" "questions")
    [[ -n "$questions" && "$questions" != "null" ]]
}

# Get script's question key (for looking up in bootstrap-questions.json)
# Usage: key=$(registry_get_questions_key "docker")
registry_get_questions_key() {
    local script_name="$1"
    registry_get_script_field "$script_name" "questions"
}

# Get script's templates array
# Usage: templates=$(registry_get_script_templates "docker")
registry_get_script_templates() {
    local script_name="$1"
    _get_manifest_json | jq -r ".scripts.\"$script_name\".templates[]? // empty"
}

# Get script's dependencies
# Usage: deps=$(registry_get_script_depends "docker")
registry_get_script_depends() {
    local script_name="$1"
    _get_manifest_json | jq -r ".scripts.\"$script_name\".depends[]? // empty"
}

# Get script's detection keys
# Usage: detects=$(registry_get_script_detects "docker")
registry_get_script_detects() {
    local script_name="$1"
    _get_manifest_json | jq -r ".scripts.\"$script_name\".detects[]? // empty"
}

# ===================================================================
# Phase Information
# ===================================================================

# Get all phase numbers
# Usage: phases=$(registry_get_phases)
registry_get_phases() {
    _get_manifest_json | jq -r '.phases | keys[]' | sort -n
}

# Get phase name
# Usage: name=$(registry_get_phase_name 1)
registry_get_phase_name() {
    local phase="$1"
    case "$phase" in
        1) echo "Foundation" ;;
        2) echo "Development Environment" ;;
        3) echo "Infrastructure & Databases" ;;
        4) echo "Services & Deployment" ;;
        5) echo "Advanced Services" ;;
        *) echo "Phase $phase" ;;
    esac
}

# Get phase description
# Usage: desc=$(registry_get_phase_description 1)
registry_get_phase_description() {
    local phase="$1"
    # Phases in manifest are arrays of script names, no metadata
    return 0
}

# Get phase color
# Usage: color=$(registry_get_phase_color 1)
registry_get_phase_color() {
    local phase="$1"
    echo "blue"
}

# ===================================================================
# Profile Functions
# ===================================================================

# Get all profile names
# Usage: profiles=$(registry_get_profiles)
registry_get_profiles() {
    _get_manifest_json | jq -r '.profiles | keys[]'
}

# Get scripts for a profile
# Usage: scripts=$(registry_get_profile_scripts "standard")
registry_get_profile_scripts() {
    local profile="$1"
    _get_manifest_json | jq -r ".profiles.\"$profile\".scripts[]? // empty"
}

# Get profile description
# Usage: desc=$(registry_get_profile_description "standard")
registry_get_profile_description() {
    local profile="$1"
    _get_manifest_json | jq -r ".profiles.\"$profile\".description // empty"
}

# Check if profile exists
# Usage: registry_profile_exists "standard" && echo "exists"
registry_profile_exists() {
    local profile="$1"
    _get_manifest_json | jq -e ".profiles.\"$profile\"" &>/dev/null
}

# ===================================================================
# Discovery Functions
# ===================================================================

# Scan for new scripts not in manifest
# Returns list of script files that exist but aren't registered
# Usage: new_scripts=$(registry_discover_new_scripts)
registry_discover_new_scripts() {
    local scripts_dir="${TEMPLATES_SCRIPTS:-}"
    [[ -z "$scripts_dir" || ! -d "$scripts_dir" ]] && return 0

    # Get all bootstrap-*.sh files
    for script_file in "$scripts_dir"/bootstrap-*.sh; do
        [[ ! -f "$script_file" ]] && continue

        local basename=$(basename "$script_file")
        local script_name="${basename#bootstrap-}"
        script_name="${script_name%.sh}"

        # Check if registered in manifest
        if ! registry_script_exists "$script_name"; then
            echo "$script_name"
        fi
    done
}

# Check for missing scripts (in manifest but file doesn't exist)
# Usage: missing=$(registry_find_missing_scripts)
registry_find_missing_scripts() {
    for script_name in $(registry_get_visible_scripts); do
        if ! registry_script_file_exists "$script_name"; then
            echo "$script_name"
        fi
    done
}

# Get script availability status
# Returns: available, missing, or new
# Usage: status=$(registry_get_script_status "docker")
registry_get_script_status() {
    local script_name="$1"

    if registry_script_exists "$script_name"; then
        if registry_script_file_exists "$script_name"; then
            echo "available"
        else
            echo "missing"
        fi
    else
        echo "new"
    fi
}

# ===================================================================
# Utility Functions
# ===================================================================

# Get total script count (visible only)
# Usage: count=$(registry_get_script_count)
registry_get_script_count() {
    registry_get_visible_scripts | wc -l
}

# Get scripts by category
# Usage: scripts=$(registry_get_category_scripts "quality")
registry_get_category_scripts() {
    local category="$1"
    _get_manifest_json | jq -r ".scripts | to_entries[] | select(.value.category == \"$category\" and .value.hidden != true) | .key"
}

# Build script number map for menu display
# Returns associative array style output: number:script_name
# Usage: while read line; do ... done <<< "$(registry_build_script_map)"
registry_build_script_map() {
    local counter=1
    for phase in $(registry_get_phases); do
        for script in $(registry_get_phase_scripts "$phase"); do
            echo "${counter}:${script}"
            ((counter++))
        done
    done
}

# Get script name by menu number
# Usage: script=$(registry_get_script_by_number 5)
registry_get_script_by_number() {
    local target_num="$1"
    local counter=1

    for phase in $(registry_get_phases); do
        for script in $(registry_get_phase_scripts "$phase"); do
            if [[ $counter -eq $target_num ]]; then
                echo "$script"
                return 0
            fi
            ((counter++))
        done
    done
    return 1
}

# Get menu number for a script
# Usage: num=$(registry_get_script_number "docker")
registry_get_script_number() {
    local target_script="$1"
    local counter=1

    for phase in $(registry_get_phases); do
        for script in $(registry_get_phase_scripts "$phase"); do
            if [[ "$script" == "$target_script" ]]; then
                echo "$counter"
                return 0
            fi
            ((counter++))
        done
    done
    return 1
}

# ===================================================================
# Manifest Path Queries
# ===================================================================

# Get a path from manifest
# Usage: path=$(registry_get_path "TEMPLATES_ROOT")
registry_get_path() {
    local key="$1"
    _get_manifest_json | jq -r ".paths.\"$key\" // empty"
}

# Get questions file path
# Usage: path=$(registry_get_questions_file)
registry_get_questions_file() {
    local rel_path=$(registry_get_path "QUESTIONS_FILE")
    if [[ -n "$rel_path" ]]; then
        echo "${BOOTSTRAP_DIR}/${rel_path}"
    fi
}

# ===================================================================
# Validation Helpers
# ===================================================================

# Validate manifest structure
# Usage: registry_validate_manifest && echo "valid"
registry_validate_manifest() {
    local errors=0

    # Check required sections
    local manifest_json=$(_get_manifest_json)
    for section in scripts phases paths; do
        if ! echo "$manifest_json" | jq -e ".$section" &>/dev/null; then
            echo "ERROR: Missing section: $section" >&2
            ((errors++))
        fi
    done

    # Check each script has required fields
    for script in $(registry_get_all_scripts); do
        for field in file phase; do
            if [[ -z "$(registry_get_script_field "$script" "$field")" ]]; then
                echo "ERROR: Script '$script' missing field: $field" >&2
                ((errors++))
            fi
        done
    done

    [[ $errors -eq 0 ]]
}

# ===================================================================
# Cache Helpers
# ===================================================================

# Get cache directory path
registry_get_cache_dir() {
    local cache_dir=$(registry_get_path "CACHE_DIR")
    echo "${BOOTSTRAP_DIR}/${cache_dir:-.cache}"
}

# Check if cache is stale (manifest modified after cache)
# Usage: registry_is_cache_stale "menu-state.json" && echo "stale"
registry_is_cache_stale() {
    local cache_file="$1"
    local cache_dir=$(registry_get_cache_dir)
    local full_cache="${cache_dir}/${cache_file}"

    # No cache = stale
    [[ ! -f "$full_cache" ]] && return 0

    # Compare modification times
    if [[ "$MANIFEST_FILE" -nt "$full_cache" ]]; then
        return 0  # stale
    fi

    return 1  # fresh
}
