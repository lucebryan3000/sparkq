#!/bin/bash

# ===================================================================
# bootstrap-codex.sh
#
# Bootstrap OpenAI Codex CLI configuration
# Sets up .codex.json for Codex AI assistance integration
# ===================================================================

set -e

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===================================================================
# Utility Functions
# ===================================================================

log_info() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Codex configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# ===================================================================
# Create .codex.json
# ===================================================================

log_info "Creating .codex.json..."

cat > "$PROJECT_ROOT/.codex.json" << 'EOF'
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
EOF

log_success ".codex.json created"

# ===================================================================
# Create .codexignore
# ===================================================================

log_info "Creating .codexignore..."

cat > "$PROJECT_ROOT/.codexignore" << 'EOF'
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
EOF

log_success ".codexignore created"

# ===================================================================
# Summary
# ===================================================================

echo ""
log_success "Codex configuration complete!"
echo ""
echo "Files created:"
echo "  - .codex.json"
echo "  - .codexignore"
echo ""
echo "Next steps:"
echo "  1. Set OPENAI_API_KEY environment variable"
echo "  2. Update .codex.json with your preferences"
echo "  3. Enable Codex by setting 'enabled': true"
echo "  4. Commit files: git add .codex.json .codexignore"
echo ""
echo "Note: Codex requires an OpenAI API key. Get one at https://beta.openai.com/account/api-keys"
echo ""
