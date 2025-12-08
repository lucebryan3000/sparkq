#!/bin/bash

# ===================================================================
# run-bootstrap.sh
#
# Convenience wrapper to run bootstrap-menu.sh from project root
# ===================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="${SCRIPT_DIR}/__bootbuild"
BOOTSTRAP_MENU="${BOOTSTRAP_DIR}/scripts/bootstrap-menu.sh"

if [[ ! -f "$BOOTSTRAP_MENU" ]]; then
    echo "Error: bootstrap-menu.sh not found at $BOOTSTRAP_MENU"
    exit 1
fi

# Make executable if needed
[[ ! -x "$BOOTSTRAP_MENU" ]] && chmod +x "$BOOTSTRAP_MENU"

# Run bootstrap menu with all arguments passed through
exec bash "$BOOTSTRAP_MENU" "$@"
