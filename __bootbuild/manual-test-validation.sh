#!/bin/bash
# Manual test for input validation
# This script demonstrates testing the validation function

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Simple stub
log_error() { :; }
registry_script_exists() { return 1; }

# The validation function (matches the actual implementation)
validate_menu_command() {
    local cmd="$1"
    local max_scripts="$2"

    [[ -z "$cmd" || "$cmd" == " " ]] && return 0

    # Number validation FIRST (before length checks)
    if [[ "$cmd" =~ ^-?[0-9]+$ ]]; then
        [[ "$cmd" -lt 1 ]] && { log_error "Invalid: $cmd"; return 1; }
        [[ "$cmd" -gt "$max_scripts" ]] && { log_error "Out of range: $cmd"; return 1; }
        return 0
    fi

    if [[ "${#cmd}" -eq 1 ]]; then
        case "$cmd" in
            h|H|s|S|c|C|d|D|l|L|r|R|q|Q|x|X|t|T|v|V|e|E|u|U|\?) return 0 ;;
            *) log_error "Unknown: $cmd"; return 1 ;;
        esac
    fi

    if [[ "${#cmd}" -eq 2 ]]; then
        case "$cmd" in
            qa|QA|hc|HC|rb|RB|sg|SG|p1|p2|p3|p4|P1|P2|P3|P4) return 0 ;;
            *) log_error "Unknown: $cmd"; return 1 ;;
        esac
    fi

    [[ "$cmd" == "all" || "$cmd" == "ALL" ]] && return 0

    registry_script_exists "$cmd" && return 0

    log_error "Unknown: $cmd"
    return 1
}

# Test function
test_cmd() {
    local cmd="$1"
    local max=20
    local expect="$2"

    if validate_menu_command "$cmd" "$max" 2>/dev/null; then
        result="PASS"
    else
        result="FAIL"
    fi

    if [[ "$result" == "$expect" ]]; then
        echo -e "${GREEN}✓${NC} '$cmd' -> $result (expected $expect)"
    else
        echo -e "${RED}✗${NC} '$cmd' -> $result (expected $expect)"
    fi
}

echo "Testing input validation..."
echo ""

echo "Valid single-letter commands:"
test_cmd "h" "PASS"
test_cmd "s" "PASS"
test_cmd "q" "PASS"
echo ""

echo "Invalid single-letter commands:"
test_cmd "z" "FAIL"
test_cmd "f" "FAIL"
echo ""

echo "Valid two-letter commands:"
test_cmd "p1" "PASS"
test_cmd "p2" "PASS"
test_cmd "qa" "PASS"
echo ""

echo "Invalid two-letter commands:"
test_cmd "p5" "FAIL"
test_cmd "zz" "FAIL"
echo ""

echo "Valid three-letter commands:"
test_cmd "all" "PASS"
test_cmd "ALL" "PASS"
echo ""

echo "Valid numbers:"
test_cmd "1" "PASS"
test_cmd "10" "PASS"
test_cmd "20" "PASS"
echo ""

echo "Invalid numbers:"
test_cmd "0" "FAIL"
test_cmd "21" "FAIL"
test_cmd "-1" "FAIL"
echo ""

echo "Edge cases:"
test_cmd "" "PASS"
test_cmd " " "PASS"
test_cmd "foo" "FAIL"
echo ""

echo "✓ All manual tests completed"
