#!/bin/bash

# ===================================================================
# log-utils.sh
#
# Centralized logging utilities for bootstrap scripts
# Provides color definitions and consistent logging functions
#
# Usage:
#   source "$(dirname "$0")/../lib/log-utils.sh"
#
# Provides:
#   - Color definitions (BLUE, GREEN, YELLOW, RED, GREY, BOLD, NC)
#   - log_info, log_success, log_warning, log_error, log_fatal
#   - log_debug (enabled with BOOTSTRAP_DEBUG=true)
#   - log_section (formatted section headers)
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_LOG_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_LOG_UTILS_LOADED=1

# ===================================================================
# Colors
# ===================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREY='\033[90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ===================================================================
# Logging Functions
# ===================================================================

# Log informational message with arrow prefix
# Usage: log_info "Your message here"
log_info() {
    echo -e "${BLUE}→${NC} $1"
}

# Log success message with checkmark prefix
# Usage: log_success "Operation completed"
log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Log warning message with warning symbol
# Usage: log_warning "Be careful"
log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Log error message to stderr with cross symbol
# Usage: log_error "Something went wrong"
log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Log fatal error and exit with code 1
# Usage: log_fatal "Cannot continue"
log_fatal() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

# Log debug message (only shown when BOOTSTRAP_DEBUG=true)
# Usage: log_debug "Debug information"
log_debug() {
    [[ "${BOOTSTRAP_DEBUG:-false}" == "true" ]] && echo -e "${GREY}[DEBUG] $1${NC}"
}

# Log a formatted section header
# Usage: log_section "Installation Progress"
log_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ===================================================================
# Export Functions
# ===================================================================
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_fatal
export -f log_debug
export -f log_section
