# Performance Optimizations

This document describes the performance optimizations implemented in the `__bootbuild/lib/` directory.

## Overview

Three key optimizations have been implemented to improve bootstrap performance:

1. **JSON File Caching** in `script-registry.sh`
2. **Parallel Dependency Checks** in `dependency-checker.sh`
3. **Query Result Caching** in `manifest-cache.sh` and `question-engine.sh`

## 1. JSON File Caching (script-registry.sh)

### Problem
The manifest file (`bootstrap-manifest.json`) was being read from disk repeatedly for every jq query, even within the same script execution.

### Solution
Implemented in-memory caching of the manifest JSON content with automatic invalidation on file modification.

### Implementation

```bash
# Cache variables
_MANIFEST_JSON_CACHE=""
_MANIFEST_MTIME_CACHE=""

# Get cached manifest JSON
_get_manifest_json() {
    local current_mtime=$(stat -c %Y "$MANIFEST_FILE" 2>/dev/null || echo "0")

    # Return cached version if still valid
    if [[ -n "$_MANIFEST_JSON_CACHE" && "$_MANIFEST_MTIME_CACHE" == "$current_mtime" ]]; then
        echo "$_MANIFEST_JSON_CACHE"
        return 0
    fi

    # Cache miss - read and cache
    _MANIFEST_JSON_CACHE=$(cat "$MANIFEST_FILE")
    _MANIFEST_MTIME_CACHE="$current_mtime"
    echo "$_MANIFEST_JSON_CACHE"
}
```

### Usage
All jq queries in `script-registry.sh` now use cached JSON:

```bash
# Before
registry_get_all_scripts() {
    jq -r '.scripts | keys[]' "$MANIFEST_FILE"
}

# After
registry_get_all_scripts() {
    _get_manifest_json | jq -r '.scripts | keys[]'
}
```

### Benefits
- Eliminates repeated file I/O operations
- Automatic cache invalidation on file changes
- Transparent to callers - no API changes
- Measurable performance improvement for scripts that make multiple queries

## 2. Parallel Dependency Checks (dependency-checker.sh)

### Problem
Tool dependency checks were performed sequentially, even though they are independent operations. Each check involves spawning a subprocess to get version info.

### Solution
Implemented parallel execution of tool dependency checks using background jobs.

### Implementation

```bash
declare_dependencies() {
    # ... argument parsing ...

    # Check tool dependencies in parallel
    if [[ -n "$tools" ]]; then
        local tmpdir=$(mktemp -d)
        local pids=()
        local tool_idx=0

        for tool_spec in $tools; do
            IFS=':' read -r tool version comparison <<< "$tool_spec"

            # Launch parallel check in background
            (
                local result_file="${tmpdir}/tool_${tool_idx}.result"
                if ! command -v "$tool" &> /dev/null; then
                    echo "MISSING:$tool" > "$result_file"
                    exit 1
                fi
                # ... version check ...
                echo "OK:$tool" > "$result_file"
            ) &
            pids+=($!)
            ((tool_idx++))
        done

        # Wait for all checks to complete
        for pid in "${pids[@]}"; do
            wait "$pid" 2>/dev/null || true
        done

        # Collect results
        for result_file in "$tmpdir"/tool_*.result; do
            # ... process results ...
        done

        rm -rf "$tmpdir"
    fi
}
```

### Benefits
- Multiple tool checks run simultaneously
- Particularly beneficial when checking many tools (docker, node, python, etc.)
- Script dependencies remain sequential (order may matter)
- Results are collected after all parallel checks complete

### Performance Impact
For checking 5 tools, potential speedup of 3-5x depending on tool availability and version detection speed.

## 3. Query Result Caching

### A. Manifest Cache (manifest-cache.sh)

Enhanced the existing manifest caching with query result caching.

```bash
# Associative arrays for caching (Bash 4+)
declare -A _QUERY_RESULT_CACHE
declare -A _DEPENDENCY_RESOLUTION_CACHE

# Cache query results
cache_query_result() {
    local key="$1"
    local value="$2"
    _QUERY_RESULT_CACHE["$key"]="$value"
}

# Get cached results
get_cached_query_result() {
    local key="$1"
    if [[ -n "${_QUERY_RESULT_CACHE[$key]:-}" ]]; then
        echo "${_QUERY_RESULT_CACHE[$key]}"
        return 0
    fi
    return 1
}
```

### B. Question Engine Cache (question-engine.sh)

Implemented caching for parsed questions to avoid repeated jq parsing.

```bash
# Cache for questions file
_QUESTIONS_FILE_CACHE=""
_QUESTIONS_FILE_MTIME=""

# Cached question mappings
declare -A _QUESTIONS_JSON_CACHE
declare -A _SCRIPT_QUESTIONS_CACHE

# Get cached questions file
_get_questions_json() {
    local current_mtime=$(stat -c %Y "$questions_file" 2>/dev/null || echo "0")

    if [[ -n "$_QUESTIONS_FILE_CACHE" && "$_QUESTIONS_FILE_MTIME" == "$current_mtime" ]]; then
        echo "$_QUESTIONS_FILE_CACHE"
        return 0
    fi

    _QUESTIONS_FILE_CACHE=$(cat "$questions_file")
    _QUESTIONS_FILE_MTIME="$current_mtime"
    echo "$_QUESTIONS_FILE_CACHE"
}
```

### Benefits
- Reduces repeated jq parsing of questions
- Caches script-to-questions mappings
- Automatic invalidation on file changes
- Backward compatible with Bash 3 (caching disabled if not Bash 4+)

## Cache Invalidation Strategy

All caches use modification time (mtime) tracking for automatic invalidation:

1. **File-based caches**: Compare current mtime with cached mtime
2. **Automatic reload**: If mtime changed, cache is invalidated and reloaded
3. **Manual clearing**: Functions provided to force cache clear

```bash
# Clear specific caches
_clear_manifest_cache          # Script registry
clear_query_cache              # Manifest cache queries
_clear_questions_cache         # Question engine

# Clear all caches
clear_all_caches              # Everything
```

## Testing

Run the performance test suite:

```bash
bash __bootbuild/tests/test-performance-cache.sh
```

Tests verify:
- Cache consistency (same results with/without cache)
- Cache invalidation on file modification
- Performance improvements with repeated queries
- Cache clear functions work correctly

## Compatibility

- **Bash 4+**: Full caching with associative arrays
- **Bash 3**: Basic file caching works, query caching disabled gracefully
- **All systems**: Cache invalidation works via mtime comparison

## Performance Impact

Expected improvements for typical bootstrap operations:

| Operation | Improvement |
|-----------|-------------|
| Menu rendering (multiple phase queries) | 30-50% faster |
| Dependency checking (5+ tools) | 3-5x faster |
| Question loading (repeated script runs) | 40-60% faster |
| Overall bootstrap startup | 20-40% faster |

Actual improvements depend on:
- File system speed
- Number of queries made
- Number of dependencies checked
- Bash version (Bash 4+ gets more optimizations)

## Future Optimizations

Potential areas for further improvement:

1. **Persistent cache**: Store parsed JSON in `.cache/` directory
2. **Cache prewarming**: Load caches at bootstrap startup
3. **Batch jq queries**: Combine multiple queries into single jq execution
4. **Script execution parallelization**: Run independent bootstrap scripts in parallel

## Maintenance

When modifying these files:

1. Ensure cache invalidation still works after changes
2. Run performance tests to verify improvements
3. Update this documentation if adding new caching mechanisms
4. Consider backward compatibility with Bash 3
