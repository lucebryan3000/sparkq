#!/bin/bash

# ===================================================================
# bootstrap-codex.sh
#
# Bootstrap OpenAI Codex CLI configuration
# Sets up .codex.json for Codex AI assistance integration
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-codex"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-codex"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Codex Configuration" \
    ".codex.json" \
    ".codexignore"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Warn if jq not available (optional tool)
if ! has_jq; then
    track_warning "jq not installed - JSON validation will be skipped"
    log_warning "jq not installed - JSON validation will be skipped"
    log_info "Install with: sudo apt install jq (or brew install jq)"
fi

log_success "Environment validated"

# ===================================================================
# Create .codex.json
# ===================================================================

log_info "Creating .codex.json..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.codex.json"; then
    log_warning ".codex.json already exists, skipping"
    track_skipped ".codex.json"
else
    if cat > "$PROJECT_ROOT/.codex.json" << 'EOFCODEX'
{
  "openai": {
    "apiKey": "${OPENAI_API_KEY}",
    "organization": "${OPENAI_ORGANIZATION}",
    "model": "code-davinci-002"
  },
  "codex": {
    "enabled": false,
    "temperature": 0.5,
    "maxTokens": 100,
    "topP": 1,
    "frequencyPenalty": 0,
    "presencePenalty": 0,
    "bestOf": 1,
    "n": 1
  },
  "context": {
    "maxFiles": 10,
    "maxLinesPerFile": 100,
    "fileTypes": [
      ".ts",
      ".tsx",
      ".js",
      ".jsx",
      ".py",
      ".go",
      ".java",
      ".cpp",
      ".cs"
    ],
    "ignorePatterns": [
      "node_modules",
      "dist",
      "build",
      ".git",
      ".venv"
    ]
  },
  "cache": {
    "enabled": true,
    "ttl": 3600
  },
  "logging": {
    "level": "info",
    "file": ".codex.log"
  }
}
EOFCODEX
    then
        verify_file "$PROJECT_ROOT/.codex.json"
        track_created ".codex.json"
        log_file_created "$SCRIPT_NAME" ".codex.json"

        # Validate JSON if jq available
        if has_jq; then
            source "${LIB_DIR}/json-validator.sh"
            if validate_json_file "$PROJECT_ROOT/.codex.json" > /dev/null 2>&1; then
                log_success "JSON syntax validated"
            else
                log_warning "JSON syntax validation failed - please check file manually"
            fi
        fi
    else
        log_fatal "Failed to create .codex.json"
    fi
fi

# ===================================================================
# Create .codexignore
# ===================================================================

log_info "Creating .codexignore..."

if file_exists "$PROJECT_ROOT/.codexignore"; then
    log_warning ".codexignore already exists, skipping"
    track_skipped ".codexignore"
else
    if cat > "$PROJECT_ROOT/.codexignore" << 'EOFIGNORE'
# Dependencies
node_modules/
.venv/
venv/
env/

# Build artifacts
dist/
build/
.next/
out/

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp

# Large files
*.mp4
*.mov
*.png
*.jpg
*.zip

# Cache
.eslintcache
.cache/

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
.nyc_output/
EOFIGNORE
    then
        verify_file "$PROJECT_ROOT/.codexignore"
        track_created ".codexignore"
        log_file_created "$SCRIPT_NAME" ".codexignore"
    else
        log_fatal "Failed to create .codexignore"
    fi
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Codex configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Set OPENAI_API_KEY environment variable"
echo "  2. Update .codex.json with your OpenAI organization ID"
echo "  3. Enable Codex by setting 'enabled': true in .codex.json"
echo "  4. Test with: codex --version (if Codex CLI is installed)"
echo ""
echo "Documentation:"
echo "  - OpenAI API: https://beta.openai.com/account/api-keys"
echo "  - Codex CLI: https://github.com/openai/openai-codex-cli"
echo ""

show_log_location
