#!/bin/bash
# =============================================================================
# pre-commit-validate-metadata.sh
# Pre-commit hook to validate bootstrap script metadata
#
# This hook checks that any modified bootstrap scripts have valid metadata
# headers before allowing the commit.
#
# Installation:
#   ln -sf ../../__bootbuild/hooks/pre-commit-validate-metadata.sh .git/hooks/pre-commit
# =============================================================================

set -euo pipefail

TEMPLATES_SCRIPTS="$(git rev-parse --show-toplevel)/__bootbuild/templates/scripts"
REQUIRED_FIELDS=("@script" "@version" "@phase" "@category" "@priority" "@short" "@description")
ERRORS=0

# Get list of staged bootstrap scripts
STAGED_SCRIPTS=$(git diff --cached --name-only --diff-filter=ACM | grep "templates/scripts/bootstrap-.*\.sh$" || true)

if [[ -z "$STAGED_SCRIPTS" ]]; then
    # No bootstrap scripts staged, nothing to check
    exit 0
fi

echo "🔍 Validating bootstrap script metadata..."
echo ""

for script in $STAGED_SCRIPTS; do
    script_path="$script"
    name=$(basename "$script" .sh)

    echo "Checking: $name"

    # Check for old @name tag (should not exist)
    if grep -q "^# @name" "$script_path" 2>/dev/null; then
        echo "  ❌ ERROR: Uses deprecated @name tag (should be @script)"
        ((ERRORS++))
    fi

    # Check required fields
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! grep -q "^# $field" "$script_path" 2>/dev/null; then
            echo "  ❌ ERROR: Missing required field: $field"
            ((ERRORS++))
        fi
    done

    # Validate @phase value (should be 1-5)
    phase=$(grep -m1 "^# @phase" "$script_path" 2>/dev/null | sed 's/.*@phase\s*//' | xargs || true)
    if [[ -n "$phase" && ! "$phase" =~ ^[1-5]$ ]]; then
        echo "  ❌ ERROR: Invalid @phase: $phase (must be 1-5)"
        ((ERRORS++))
    fi

    # Validate @priority value (should be numeric)
    priority=$(grep -m1 "^# @priority" "$script_path" 2>/dev/null | sed 's/.*@priority\s*//' | xargs || true)
    if [[ -n "$priority" && ! "$priority" =~ ^[0-9]+$ ]]; then
        echo "  ❌ ERROR: Invalid @priority: $priority (must be numeric)"
        ((ERRORS++))
    fi

    # Validate @category value
    category=$(grep -m1 "^# @category" "$script_path" 2>/dev/null | sed 's/.*@category\s*//' | xargs || true)
    valid_categories="core|vcs|nodejs|python|database|docs|config|deploy|test|ai|build|security"
    if [[ -n "$category" && ! "$category" =~ ^($valid_categories)$ ]]; then
        echo "  ⚠️  WARNING: Non-standard @category: $category"
    fi

    # Run syntax check
    if ! bash -n "$script_path" 2>/dev/null; then
        echo "  ❌ ERROR: Syntax error in script"
        ((ERRORS++))
    fi

    echo "  ✅ Passed"
done

echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo "❌ COMMIT BLOCKED: $ERRORS metadata error(s) found"
    echo ""
    echo "Fix the errors above and try again."
    echo "To bypass (not recommended): git commit --no-verify"
    exit 1
fi

echo "✅ All metadata validation passed"
exit 0
