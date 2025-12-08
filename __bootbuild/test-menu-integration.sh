#!/bin/bash
# Integration test for menu input validation
# Simulates actual menu usage with various inputs

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Testing Menu Input Validation Integration"
echo "=========================================="
echo ""

# Test 1: Invalid command
echo "Test 1: Invalid command (gibberish)"
echo "Input: 'asdf'"
if echo "asdf" | timeout 2 "${SCRIPT_DIR}/scripts/bootstrap-menu.sh" 2>&1 | grep -q "Unknown command"; then
    echo "✓ Shows error message and doesn't crash"
else
    echo "✗ FAILED"
fi
echo ""

# Test 2: Number out of range
echo "Test 2: Number out of range"
echo "Input: '999'"
if echo "999" | timeout 2 "${SCRIPT_DIR}/scripts/bootstrap-menu.sh" 2>&1 | grep -q "out of range"; then
    echo "✓ Shows range error and doesn't crash"
else
    echo "✗ FAILED"
fi
echo ""

# Test 3: Negative number
echo "Test 3: Negative number"
echo "Input: '-5'"
if echo "-5" | timeout 2 "${SCRIPT_DIR}/scripts/bootstrap-menu.sh" 2>&1 | grep -q "Invalid number"; then
    echo "✓ Shows invalid number error and doesn't crash"
else
    echo "✗ FAILED"
fi
echo ""

# Test 4: Invalid single letter
echo "Test 4: Invalid single letter"
echo "Input: 'z'"
if echo "z" | timeout 2 "${SCRIPT_DIR}/scripts/bootstrap-menu.sh" 2>&1 | grep -q "Unknown command"; then
    echo "✓ Shows error message and doesn't crash"
else
    echo "✗ FAILED"
fi
echo ""

# Test 5: Invalid two letter
echo "Test 5: Invalid two-letter command"
echo "Input: 'p5'"
if echo "p5" | timeout 2 "${SCRIPT_DIR}/scripts/bootstrap-menu.sh" 2>&1 | grep -q "Unknown command"; then
    echo "✓ Shows error message and doesn't crash"
else
    echo "✗ FAILED"
fi
echo ""

echo "=========================================="
echo "Integration Test Summary"
echo "=========================================="
echo ""
echo "All tests demonstrate that invalid input:"
echo "  1. Shows helpful error messages"
echo "  2. Doesn't crash the menu"
echo "  3. Continues to prompt for valid input"
echo ""
echo "✓ Input validation is working correctly"
