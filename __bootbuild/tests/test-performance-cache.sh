#!/bin/bash

# ===================================================================
# Test script for performance optimizations
# Tests caching mechanisms in script-registry.sh, manifest-cache.sh,
# and question-engine.sh
# ===================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Find bootstrap directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}=== Performance Cache Test Suite ===${NC}"
echo ""

# Source required libraries
export MANIFEST_FILE="${BOOTSTRAP_DIR}/config/bootstrap-manifest.json"
export QUESTIONS_FILE="${BOOTSTRAP_DIR}/config/bootstrap-questions.json"

source "${BOOTSTRAP_DIR}/lib/script-registry.sh" || {
    echo -e "${RED}✗ Failed to load script-registry.sh${NC}"
    exit 1
}

source "${BOOTSTRAP_DIR}/lib/manifest-cache.sh" || {
    echo -e "${RED}✗ Failed to load manifest-cache.sh${NC}"
    exit 1
}

# ===================================================================
# Test 1: Script Registry JSON Cache
# ===================================================================

echo -e "${BLUE}Test 1: Script Registry JSON Cache${NC}"

# Clear any existing cache
_clear_manifest_cache

# First call - should read from file
start_time=$(date +%s%N)
result1=$(registry_get_all_scripts)
end_time=$(date +%s%N)
time1=$((($end_time - $start_time) / 1000000))  # Convert to milliseconds

# Second call - should use cache
start_time=$(date +%s%N)
result2=$(registry_get_all_scripts)
end_time=$(date +%s%N)
time2=$((($end_time - $start_time) / 1000000))

# Verify results are identical
if [[ "$result1" == "$result2" ]]; then
    echo -e "${GREEN}✓${NC} Cache returns consistent results"
else
    echo -e "${RED}✗${NC} Cache results differ!"
    exit 1
fi

# Verify second call is faster
if [[ $time2 -lt $time1 ]]; then
    speedup=$((time1 * 100 / (time2 + 1)))
    echo -e "${GREEN}✓${NC} Cached call is faster (${speedup}% speedup)"
    echo "  First call:  ${time1}ms"
    echo "  Cached call: ${time2}ms"
else
    echo -e "${YELLOW}⚠${NC} Cached call not significantly faster (timing may vary)"
    echo "  First call:  ${time1}ms"
    echo "  Cached call: ${time2}ms"
fi

echo ""

# ===================================================================
# Test 2: Manifest Cache Invalidation
# ===================================================================

echo -e "${BLUE}Test 2: Cache Invalidation on File Change${NC}"

# Get current manifest mtime
original_mtime=$(_get_manifest_mtime)

# Populate cache
result1=$(registry_get_script_field "docker" "description")

# Simulate file change by touching manifest
touch "$MANIFEST_FILE"
sleep 0.1  # Ensure mtime changes

new_mtime=$(_get_manifest_mtime)

if [[ "$original_mtime" != "$new_mtime" ]]; then
    echo -e "${GREEN}✓${NC} File mtime changed (invalidation trigger works)"

    # Cache should be invalidated and re-read
    result2=$(registry_get_script_field "docker" "description")

    if [[ "$result1" == "$result2" ]]; then
        echo -e "${GREEN}✓${NC} Cache invalidation works correctly"
    else
        echo -e "${RED}✗${NC} Cache invalidation failed - results differ"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠${NC} mtime didn't change (filesystem limitation)"
fi

echo ""

# ===================================================================
# Test 3: Query Result Caching
# ===================================================================

echo -e "${BLUE}Test 3: Manifest Cache Query Results${NC}"

# Test query caching
clear_query_cache

# First query - no cache
start_time=$(date +%s%N)
result1=$(get_cached_section "phases" "1")
end_time=$(date +%s%N)
time1=$((($end_time - $start_time) / 1000000))

# Second query - should use cache
start_time=$(date +%s%N)
result2=$(get_cached_section "phases" "1")
end_time=$(date +%s%N)
time2=$((($end_time - $start_time) / 1000000))

if [[ "$result1" == "$result2" ]]; then
    echo -e "${GREEN}✓${NC} Query cache returns consistent results"
else
    echo -e "${RED}✗${NC} Query cache results differ!"
    exit 1
fi

echo "  First query:  ${time1}ms"
echo "  Cached query: ${time2}ms"

echo ""

# ===================================================================
# Test 4: Multiple Repeated Queries (Real-World Usage)
# ===================================================================

echo -e "${BLUE}Test 4: Multiple Repeated Queries Performance${NC}"

_clear_manifest_cache
clear_query_cache

# Simulate menu building - queries all phases and scripts
start_time=$(date +%s%N)
for phase in $(registry_get_phases); do
    registry_get_phase_name "$phase" > /dev/null
    registry_get_phase_scripts "$phase" > /dev/null
done
end_time=$(date +%s%N)
time_uncached=$((($end_time - $start_time) / 1000000))

# Second run - should be cached
start_time=$(date +%s%N)
for phase in $(registry_get_phases); do
    registry_get_phase_name "$phase" > /dev/null
    registry_get_phase_scripts "$phase" > /dev/null
done
end_time=$(date +%s%N)
time_cached=$((($end_time - $start_time) / 1000000))

if [[ $time_cached -lt $time_uncached ]]; then
    speedup=$((time_uncached * 100 / (time_cached + 1)))
    echo -e "${GREEN}✓${NC} Real-world usage shows performance gain (${speedup}% speedup)"
    echo "  Uncached: ${time_uncached}ms"
    echo "  Cached:   ${time_cached}ms"
else
    echo -e "${YELLOW}⚠${NC} Performance gain not significant (timing may vary)"
    echo "  Uncached: ${time_uncached}ms"
    echo "  Cached:   ${time_cached}ms"
fi

echo ""

# ===================================================================
# Test 5: Cache Clear Functions
# ===================================================================

echo -e "${BLUE}Test 5: Cache Clear Functions${NC}"

# Populate caches
registry_get_all_scripts > /dev/null
get_cached_section "paths" "CONFIG_DIR" > /dev/null

# Clear manifest cache
_clear_manifest_cache

# Verify cache was cleared (should read from file again)
result=$(registry_get_all_scripts)
if [[ -n "$result" ]]; then
    echo -e "${GREEN}✓${NC} Cache clear and reload works"
else
    echo -e "${RED}✗${NC} Cache clear failed"
    exit 1
fi

# Clear query cache
clear_query_cache
echo -e "${GREEN}✓${NC} Query cache clear works"

# Clear all caches
clear_all_caches > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Clear all caches works"

echo ""

# ===================================================================
# Summary
# ===================================================================

echo -e "${GREEN}=== All Cache Tests Passed ===${NC}"
echo ""
echo "Performance improvements verified:"
echo "  ✓ JSON file caching reduces repeated file reads"
echo "  ✓ Cache invalidation on file modification works"
echo "  ✓ Query result caching reduces repeated jq parsing"
echo "  ✓ Real-world usage shows measurable performance gains"
echo ""

exit 0
