#!/bin/bash
# validate-metadata.sh
# Validates that all scripts have proper metadata headers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_SCRIPTS="${SCRIPT_DIR}/../templates/scripts"
ERRORS=0
WARNINGS=0

echo "=========================================="
echo "  MIGRATION SELF-TEST"
echo "=========================================="
echo ""

# Required fields that must be present in all scripts
REQUIRED_FIELDS=("@script" "@version" "@phase" "@category" "@priority" "@short" "@description")

# Check each script
for script in "$TEMPLATES_SCRIPTS"/bootstrap-*.sh; do
    name=$(basename "$script" .sh)
    script_errors=0

    # Check for old @name tag (should not exist)
    if grep -q "^# @name" "$script" 2>/dev/null; then
        echo "ERROR: $name still has @name tag (should be @script)"
        ((script_errors++))
        ((ERRORS++))
    fi

    # Check required fields
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! grep -q "^# $field" "$script" 2>/dev/null; then
            echo "ERROR: $name missing required field: $field"
            ((script_errors++))
            ((ERRORS++))
        fi
    done

    # Validate @phase value (should be 1-5)
    phase=$(grep -m1 "^# @phase" "$script" 2>/dev/null | sed 's/.*@phase\s*//' | xargs)
    if [[ -n "$phase" && ! "$phase" =~ ^[1-5]$ ]]; then
        echo "ERROR: $name has invalid @phase: $phase (should be 1-5)"
        ((ERRORS++))
    fi

    # Validate @priority value (should be numeric)
    priority=$(grep -m1 "^# @priority" "$script" 2>/dev/null | sed 's/.*@priority\s*//' | xargs)
    if [[ -n "$priority" && ! "$priority" =~ ^[0-9]+$ ]]; then
        echo "ERROR: $name has invalid @priority: $priority (should be numeric)"
        ((ERRORS++))
    fi

    # Validate @category value (should be in enum)
    category=$(grep -m1 "^# @category" "$script" 2>/dev/null | sed 's/.*@category\s*//' | xargs)
    valid_categories="core|vcs|nodejs|python|database|docs|config|deploy|test|ai|build|security"
    if [[ -n "$category" && ! "$category" =~ ^($valid_categories)$ ]]; then
        echo "WARNING: $name has non-standard @category: $category"
        ((WARNINGS++))
    fi

    # Check for @creates (should have at least one or explicit "none")
    if ! grep -q "^# @creates" "$script" 2>/dev/null; then
        echo "WARNING: $name has no @creates tag"
        ((WARNINGS++))
    fi

    # =================================================================
    # Phase 2 Metadata Field Validation
    # =================================================================

    # Validate @interactive value (should be yes/no/optional)
    interactive=$(grep -m1 "^# @interactive" "$script" 2>/dev/null | sed 's/.*@interactive\s*//' | xargs || true)
    if [[ -n "$interactive" && ! "$interactive" =~ ^(yes|no|optional)$ ]]; then
        echo "ERROR: $name has invalid @interactive: $interactive (should be yes/no/optional)"
        ((ERRORS++))
    fi

    # Validate @platforms values (should be linux/macos/windows/all)
    platforms=$(grep -m1 "^# @platforms" "$script" 2>/dev/null | sed 's/.*@platforms\s*//' | xargs || true)
    if [[ -n "$platforms" && "$platforms" != "all" && "$platforms" != "needs-review" ]]; then
        for platform in $(echo "$platforms" | tr ',' ' '); do
            platform=$(echo "$platform" | xargs)
            if [[ -n "$platform" && ! "$platform" =~ ^(linux|macos|windows|all)$ ]]; then
                echo "ERROR: $name has invalid @platforms value: $platform"
                ((ERRORS++))
            fi
        done
    fi

    # Validate @conflicts references valid script names
    conflicts=$(grep -m1 "^# @conflicts" "$script" 2>/dev/null | sed 's/.*@conflicts\s*//' | xargs || true)
    if [[ -n "$conflicts" && "$conflicts" != "none" ]]; then
        for conflict in $(echo "$conflicts" | tr ',' ' '); do
            conflict=$(echo "$conflict" | xargs)
            if [[ -n "$conflict" && ! -f "$TEMPLATES_SCRIPTS/bootstrap-${conflict}.sh" ]]; then
                echo "WARNING: $name @conflicts references non-existent script: $conflict"
                ((WARNINGS++))
            fi
        done
    fi

    # Validate @docs is a URL if present
    docs=$(grep -m1 "^# @docs" "$script" 2>/dev/null | sed 's/.*@docs\s*//' | xargs || true)
    if [[ -n "$docs" && ! "$docs" =~ ^https?:// ]]; then
        echo "WARNING: $name @docs is not a valid URL: $docs"
        ((WARNINGS++))
    fi
done

echo ""
echo "=========================================="
echo "  SUMMARY"
echo "=========================================="
echo ""

total=$(find "$TEMPLATES_SCRIPTS" -maxdepth 1 -name "bootstrap-*.sh" -type f | wc -l)
with_script=$(find "$TEMPLATES_SCRIPTS" -maxdepth 1 -name "bootstrap-*.sh" -type f -exec grep -l '^# @script' {} \; | wc -l)

echo "Total scripts:     $total"
echo "With @script tag:  $with_script"
echo ""
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    echo "✅ MIGRATION SELF-TEST PASSED"
    exit 0
else
    echo "❌ MIGRATION SELF-TEST FAILED"
    exit 1
fi
