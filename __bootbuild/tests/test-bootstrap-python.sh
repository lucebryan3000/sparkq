#!/bin/bash

# ===================================================================
# test-bootstrap-python.sh
#
# Comprehensive test suite for bootstrap-python.sh
# Tests: script exists, syntax, manifest registration, configuration
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../" && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test utilities
test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1: $2"
    ((TESTS_FAILED++))
}

echo ""
echo "╭─────────────────────────────────────────────╮"
echo "│  Bootstrap Python Test Suite                │"
echo "╰─────────────────────────────────────────────╯"
echo ""

# Test 1: Script exists
if [[ -f "${BOOTSTRAP_DIR}/templates/scripts/bootstrap-python.sh" ]]; then
    test_pass "bootstrap-python.sh script exists"
else
    test_fail "bootstrap-python.sh script exists" "File not found"
fi

# Test 2: Script is executable
if [[ -x "${BOOTSTRAP_DIR}/templates/scripts/bootstrap-python.sh" ]]; then
    test_pass "bootstrap-python.sh is executable"
else
    test_fail "bootstrap-python.sh is executable" "Not executable"
fi

# Test 3: Bash syntax is valid
if bash -n "${BOOTSTRAP_DIR}/templates/scripts/bootstrap-python.sh" >/dev/null 2>&1; then
    test_pass "bootstrap-python.sh has valid bash syntax"
else
    test_fail "bootstrap-python.sh has valid bash syntax" "Syntax errors found"
fi

# Test 4: Manifest contains python script
if grep -q '"python"' "${BOOTSTRAP_DIR}/config/bootstrap-manifest.json"; then
    test_pass "python script registered in manifest"
else
    test_fail "python script registered in manifest" "Not found in manifest"
fi

# Test 5: Python script is in Phase 1
PHASE=$(grep -A 5 '"python"' "${BOOTSTRAP_DIR}/config/bootstrap-manifest.json" | grep '"phase"' | head -1 | grep -o '[0-9]')
if [[ "$PHASE" == "1" ]]; then
    test_pass "python script is in Phase 1"
else
    test_fail "python script is in Phase 1" "Found in phase $PHASE"
fi

# Test 6: Configuration section exists
if grep -q "^\[python\]" "${BOOTSTRAP_DIR}/config/bootstrap.config"; then
    test_pass "[python] section in bootstrap.config"
else
    test_fail "[python] section in bootstrap.config" "Section not found"
fi

# Test 7: Python configuration has required keys
REQUIRED_KEYS=("version" "bin" "venv_mode" "write_env" "manage_gitignore")
for key in "${REQUIRED_KEYS[@]}"; do
    if grep -q "^${key}=" <(sed -n '/^\[python\]/,/^\[/p' "${BOOTSTRAP_DIR}/config/bootstrap.config"); then
        test_pass "Config key '$key' present"
    else
        test_fail "Config key '$key' present" "Missing from [python] section"
    fi
done

# Test 8: Template files exist
TEMPLATES=("pyproject.toml.template" "requirements.txt.template" "requirements-dev.txt.template" ".env.example.template")
for template in "${TEMPLATES[@]}"; do
    if [[ -f "${BOOTSTRAP_DIR}/templates/root/python/${template}" ]]; then
        test_pass "Template '${template}' exists"
    else
        test_fail "Template '${template}' exists" "File not found"
    fi
done

# Test 9: Bootstrap profiles created
for profile in "python-backend" "python-cli"; do
    if grep -q "^${profile}=" "${BOOTSTRAP_DIR}/config/bootstrap.config"; then
        test_pass "Profile '$profile' created"
    else
        test_fail "Profile '$profile' created" "Not found in config"
    fi
done

# Test 10: Menu updated
if grep -q "python-backend\|python-cli" "${BOOTSTRAP_DIR}/scripts/bootstrap-menu.sh"; then
    test_pass "Python profiles mentioned in menu"
else
    test_fail "Python profiles mentioned in menu" "Not referenced in bootstrap-menu.sh"
fi

# Test 11: Python depends on project
if grep -A 10 '"python"' "${BOOTSTRAP_DIR}/config/bootstrap-manifest.json" | grep -q '"project"'; then
    test_pass "Python script depends on bootstrap-project"
else
    test_fail "Python script depends on bootstrap-project" "Dependency not set"
fi

# Test 12: Python detects pyproject.toml and requirements.txt
if grep -A 10 '"python"' "${BOOTSTRAP_DIR}/config/bootstrap-manifest.json" | grep -q 'has_pyproject_toml.*has_requirements_txt'; then
    test_pass "Python script detects pyproject.toml and requirements.txt"
else
    test_fail "Python script detects pyproject.toml and requirements.txt" "Detection not configured"
fi

# Summary
echo ""
echo "─────────────────────────────────────────────"
echo "TEST SUMMARY"
echo "─────────────────────────────────────────────"
TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo "Total:  $TOTAL tests"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo -e "${GREEN}Failed: 0${NC}"
fi
echo "─────────────────────────────────────────────"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
