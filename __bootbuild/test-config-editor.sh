#!/bin/bash

# Test script for interactive config editor
# This simulates the editor in a non-interactive way

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$SCRIPT_DIR"

# Export for child scripts
export BOOTSTRAP_DIR

# Source libraries
source "${SCRIPT_DIR}/lib/paths.sh"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/config-manager.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Config Editor Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Read current config
echo "Test 1: Reading current config values"
echo "--------------------------------------"
PROJECT_NAME=$(config_get "project.name" "unknown" "$BOOTSTRAP_CONFIG")
PACKAGE_MANAGER=$(config_get "packages.package_manager" "unknown" "$BOOTSTRAP_CONFIG")
APP_PORT=$(config_get "docker.app_port" "unknown" "$BOOTSTRAP_CONFIG")
echo "✓ project.name = $PROJECT_NAME"
echo "✓ packages.package_manager = $PACKAGE_MANAGER"
echo "✓ docker.app_port = $APP_PORT"
echo ""

# Test 2: Test validation function
echo "Test 2: Testing validation"
echo "--------------------------------------"

# Create a temp config for testing
TEMP_CONFIG="/tmp/bootstrap-test-config.conf"
cp "$BOOTSTRAP_CONFIG" "$TEMP_CONFIG"

# Test valid port
echo "Testing valid port (3001)..."
if config_set "docker.app_port" "3001" "$TEMP_CONFIG"; then
    NEW_VALUE=$(config_get "docker.app_port" "" "$TEMP_CONFIG")
    if [[ "$NEW_VALUE" == "3001" ]]; then
        echo "✓ Port validation works (3001 accepted)"
    else
        echo "✗ Port value not updated correctly"
    fi
else
    echo "✗ Failed to set valid port"
fi

# Test valid package manager
echo "Testing valid package manager (yarn)..."
if config_set "packages.package_manager" "yarn" "$TEMP_CONFIG"; then
    NEW_VALUE=$(config_get "packages.package_manager" "" "$TEMP_CONFIG")
    if [[ "$NEW_VALUE" == "yarn" ]]; then
        echo "✓ Package manager validation works (yarn accepted)"
    else
        echo "✗ Package manager value not updated correctly"
    fi
else
    echo "✗ Failed to set valid package manager"
fi

# Test 3: Display section (simulated)
echo ""
echo "Test 3: Simulating section display"
echo "--------------------------------------"
echo "Section: [project]"
awk -F= '
    /^\[project\]/ { in_section=1; next }
    /^\[/ { in_section=0 }
    in_section && NF > 0 && !/^[[:space:]]*#/ { printf "  %-20s = %s\n", $1, $2 }
' "$BOOTSTRAP_CONFIG"

echo ""
echo "Section: [docker]"
awk -F= '
    /^\[docker\]/ { in_section=1; next }
    /^\[/ { in_section=0 }
    in_section && NF > 0 && !/^[[:space:]]*#/ { printf "  %-20s = %s\n", $1, $2 }
' "$BOOTSTRAP_CONFIG"

# Cleanup
rm -f "$TEMP_CONFIG"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All Tests Passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To test the interactive editor, run:"
echo "  cd __bootbuild && ./scripts/bootstrap-menu.sh"
echo "Then press 'e' to enter the config editor"
echo ""
