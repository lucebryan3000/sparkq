#!/bin/bash

# ===================================================================
# lib/cache-manager.sh
#
# Cache management for bootstrap menu state, scan results, and
# session tracking. Handles cache freshness and cleanup.
#
# USAGE:
#   source "${LIB_DIR}/cache-manager.sh"
#
#   # Check if cache is stale
#   cache_is_stale "menu-scan.json" && echo "needs refresh"
#
#   # Read/write cache
#   cache_write "session.json" "$json_data"
#   data=$(cache_read "session.json")
#
# REQUIRES:
#   - BOOTSTRAP_DIR set
#   - jq for JSON operations
# ===================================================================

# Prevent double-sourcing
[[ -n "${_CACHE_MANAGER_LOADED:-}" ]] && return 0
_CACHE_MANAGER_LOADED=1

# ===================================================================
# Configuration
# ===================================================================

# Cache directory (create if not exists)
CACHE_DIR="${BOOTSTRAP_DIR}/.cache"

# Validate CACHE_DIR is within BOOTSTRAP_DIR (prevent escaping)
if [[ -n "${BOOTSTRAP_DIR:-}" ]]; then
    # Normalize paths for comparison
    _cache_real=$(readlink -f "$CACHE_DIR" 2>/dev/null || echo "$CACHE_DIR")
    _bootstrap_real=$(readlink -f "$BOOTSTRAP_DIR" 2>/dev/null || echo "$BOOTSTRAP_DIR")

    if [[ "$_cache_real" != "$_bootstrap_real"* ]]; then
        echo "ERROR: [CacheManager] CACHE_DIR must be within BOOTSTRAP_DIR" >&2
        echo "       CACHE_DIR: $_cache_real" >&2
        echo "       BOOTSTRAP_DIR: $_bootstrap_real" >&2
        return 1
    fi

    unset _cache_real _bootstrap_real
fi

# Create cache directory with restricted permissions
if [[ ! -d "$CACHE_DIR" ]]; then
    if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
        echo "ERROR: [CacheManager] Failed to create cache directory: $CACHE_DIR" >&2
        return 1
    fi
    chmod 700 "$CACHE_DIR" 2>/dev/null
fi

# Default cache TTL in seconds (5 minutes)
CACHE_TTL=${CACHE_TTL:-300}

# Maximum cache size in bytes (100MB)
CACHE_MAX_SIZE=${CACHE_MAX_SIZE:-104857600}

# ===================================================================
# Core Functions
# ===================================================================

# Get full path to cache file
# Usage: path=$(cache_path "menu-scan.json")
cache_path() {
    local filename="$1"
    echo "${CACHE_DIR}/${filename}"
}

# Check if cache file exists
# Usage: cache_exists "menu-scan.json" && echo "exists"
cache_exists() {
    local filename="$1"
    [[ -f "$(cache_path "$filename")" ]]
}

# Check if cache is stale (older than TTL or source modified)
# Usage: cache_is_stale "menu-scan.json" && refresh
cache_is_stale() {
    local filename="$1"
    local source_file="${2:-$MANIFEST_FILE}"
    local cache_file=$(cache_path "$filename")

    # No cache = stale
    [[ ! -f "$cache_file" ]] && return 0

    # Check if source file is newer than cache
    if [[ -n "$source_file" && -f "$source_file" ]]; then
        if [[ "$source_file" -nt "$cache_file" ]]; then
            return 0  # stale
        fi
    fi

    # Check age against TTL
    local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    if (( cache_age > CACHE_TTL )); then
        return 0  # stale
    fi

    return 1  # fresh
}

# Read cache file contents
# Usage: data=$(cache_read "menu-scan.json")
cache_read() {
    local filename="$1"
    local cache_file=$(cache_path "$filename")

    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
    else
        echo ""
    fi
}

# Write data to cache file (with size validation)
# Usage: cache_write "menu-scan.json" "$json_data"
cache_write() {
    local filename="$1"
    local data="$2"
    local cache_file=$(cache_path "$filename")

    # Validate filename doesn't contain path traversal
    if [[ "$filename" =~ \.\. ]] || [[ "$filename" =~ / ]]; then
        echo "ERROR: [CacheManager] Invalid cache filename: $filename" >&2
        return 1
    fi

    # Check data size (prevent cache bloat)
    local data_size=${#data}
    if (( data_size > CACHE_MAX_SIZE )); then
        echo "ERROR: [CacheManager] Cache data too large: ${data_size} bytes (max: ${CACHE_MAX_SIZE})" >&2
        return 1
    fi

    # Use atomic write operation
    local tmp_file="${cache_file}.tmp.$$"
    trap "rm -f '$tmp_file' 2>/dev/null" EXIT ERR

    if echo "$data" > "$tmp_file" 2>/dev/null; then
        if mv "$tmp_file" "$cache_file" 2>/dev/null; then
            trap - EXIT ERR
            return 0
        else
            echo "ERROR: [CacheManager] Failed to write cache file: $cache_file" >&2
            rm -f "$tmp_file"
            trap - EXIT ERR
            return 1
        fi
    else
        echo "ERROR: [CacheManager] Failed to create temp cache file" >&2
        rm -f "$tmp_file"
        trap - EXIT ERR
        return 1
    fi
}

# Delete cache file
# Usage: cache_delete "menu-scan.json"
cache_delete() {
    local filename="$1"
    local cache_file=$(cache_path "$filename")

    [[ -f "$cache_file" ]] && rm -f "$cache_file"
}

# Clear all cache files
# Usage: cache_clear_all
cache_clear_all() {
    rm -f "${CACHE_DIR}"/*.json 2>/dev/null
    rm -f "${CACHE_DIR}"/*.meta 2>/dev/null
    log_info "Cache cleared"
}

# ===================================================================
# JSON Cache Helpers
# ===================================================================

# Get value from JSON cache
# Usage: value=$(cache_get_json "menu-scan.json" ".scripts.docker.status")
cache_get_json() {
    local filename="$1"
    local jq_path="$2"
    local cache_file=$(cache_path "$filename")

    if [[ -f "$cache_file" ]] && command -v jq &>/dev/null; then
        jq -r "$jq_path // empty" "$cache_file" 2>/dev/null
    else
        echo ""
    fi
}

# Set value in JSON cache (creates if not exists)
# Usage: cache_set_json "session.json" ".last_script" "docker"
cache_set_json() {
    local filename="$1"
    local jq_path="$2"
    local value="$3"
    local cache_file=$(cache_path "$filename")

    if ! command -v jq &>/dev/null; then
        log_warning "jq required for JSON cache operations"
        return 1
    fi

    local existing="{}"
    [[ -f "$cache_file" ]] && existing=$(cat "$cache_file")

    # Update or create the JSON
    echo "$existing" | jq "$jq_path = \"$value\"" > "$cache_file"
}

# ===================================================================
# Session State Management
# ===================================================================

SESSION_CACHE="session-state.json"

# Initialize session state
# Usage: session_init
session_init() {
    local session_file=$(cache_path "$SESSION_CACHE")

    if [[ ! -f "$session_file" ]]; then
        cat > "$session_file" << EOF
{
  "started": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scripts_run": [],
  "scripts_failed": [],
  "scripts_skipped": [],
  "last_script": null,
  "interactive_mode": false
}
EOF
    fi
}

# Track script execution in session
# Usage: session_track_script "docker" "completed"
session_track_script() {
    local script="$1"
    local status="$2"
    local session_file=$(cache_path "$SESSION_CACHE")

    session_init

    case "$status" in
        completed|run)
            jq ".scripts_run += [\"$script\"] | .last_script = \"$script\"" "$session_file" > "${session_file}.tmp" && \
            mv "${session_file}.tmp" "$session_file"
            ;;
        failed)
            jq ".scripts_failed += [\"$script\"] | .last_script = \"$script\"" "$session_file" > "${session_file}.tmp" && \
            mv "${session_file}.tmp" "$session_file"
            ;;
        skipped)
            jq ".scripts_skipped += [\"$script\"]" "$session_file" > "${session_file}.tmp" && \
            mv "${session_file}.tmp" "$session_file"
            ;;
    esac
}

# Get session summary
# Usage: summary=$(session_get_summary)
session_get_summary() {
    local session_file=$(cache_path "$SESSION_CACHE")

    if [[ -f "$session_file" ]]; then
        local run=$(jq -r '.scripts_run | length' "$session_file")
        local failed=$(jq -r '.scripts_failed | length' "$session_file")
        local skipped=$(jq -r '.scripts_skipped | length' "$session_file")
        echo "run:$run,failed:$failed,skipped:$skipped"
    else
        echo "run:0,failed:0,skipped:0"
    fi
}

# Check if script was run in current session
# Usage: session_was_run "docker" && echo "already run"
session_was_run() {
    local script="$1"
    local session_file=$(cache_path "$SESSION_CACHE")

    if [[ -f "$session_file" ]]; then
        jq -e ".scripts_run | index(\"$script\")" "$session_file" &>/dev/null
    else
        return 1
    fi
}

# Get last run script
# Usage: last=$(session_get_last)
session_get_last() {
    cache_get_json "$SESSION_CACHE" ".last_script"
}

# Clear session (start fresh)
# Usage: session_clear
session_clear() {
    cache_delete "$SESSION_CACHE"
    session_init
}

# ===================================================================
# Menu State Cache
# ===================================================================

MENU_STATE_CACHE="menu-state.json"

# Save menu state
# Usage: menu_state_save
menu_state_save() {
    local state_file=$(cache_path "$MENU_STATE_CACHE")

    cat > "$state_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "project_root": "${PROJECT_ROOT:-.}",
  "interactive_mode": ${INTERACTIVE_MODE:-false},
  "auto_yes": ${AUTO_YES:-false},
  "manifest_hash": "$(md5sum "$MANIFEST_FILE" 2>/dev/null | cut -d' ' -f1)"
}
EOF
}

# Check if menu state matches current settings
# Usage: menu_state_matches && echo "state is current"
menu_state_matches() {
    local state_file=$(cache_path "$MENU_STATE_CACHE")

    [[ ! -f "$state_file" ]] && return 1

    local cached_hash=$(cache_get_json "$MENU_STATE_CACHE" ".manifest_hash")
    local current_hash=$(md5sum "$MANIFEST_FILE" 2>/dev/null | cut -d' ' -f1)

    [[ "$cached_hash" == "$current_hash" ]]
}

# ===================================================================
# Scan Results Cache
# ===================================================================

SCAN_CACHE="menu-scan.json"

# Get script status from scan cache
# Usage: status=$(scan_get_script_status "docker")
scan_get_script_status() {
    local script="$1"
    cache_get_json "$SCAN_CACHE" ".scripts.\"$script\".status"
}

# Get new scripts count from scan cache
# Usage: count=$(scan_get_new_count)
scan_get_new_count() {
    local count=$(cache_get_json "$SCAN_CACHE" ".new_scripts | length")
    echo "${count:-0}"
}

# Get missing scripts count from scan cache
# Usage: count=$(scan_get_missing_count)
scan_get_missing_count() {
    local count=$(cache_get_json "$SCAN_CACHE" ".missing_scripts | length")
    echo "${count:-0}"
}

# ===================================================================
# Cache Maintenance
# ===================================================================

# Remove stale cache files (older than 24 hours)
# Usage: cache_cleanup
cache_cleanup() {
    find "$CACHE_DIR" -type f -mtime +1 -delete 2>/dev/null
}

# Get cache stats
# Usage: cache_stats
cache_stats() {
    local file_count=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l)
    local total_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)

    echo "Cache directory: $CACHE_DIR"
    echo "Files: $file_count"
    echo "Size: ${total_size:-0}"

    if [[ -f "$(cache_path "$SCAN_CACHE")" ]]; then
        local scan_age=$(( $(date +%s) - $(stat -c %Y "$(cache_path "$SCAN_CACHE")" 2>/dev/null || echo 0) ))
        echo "Scan cache age: ${scan_age}s"
    fi
}

# ===================================================================
# Initialize
# ===================================================================

# Ensure cache directory exists
mkdir -p "$CACHE_DIR" 2>/dev/null

# Run cleanup on load (non-blocking)
cache_cleanup &>/dev/null &
