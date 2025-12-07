#!/bin/bash

# ===================================================================
# bootstrap-vscode.sh
#
# Bootstrap VS Code configuration for a new project
# Creates .vscode/ directory structure with settings, tasks, launch,
# and extensions configuration per official VS Code documentation
# ===================================================================

set -e

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"
VSCODE_DIR="${PROJECT_ROOT}/.vscode"
TEMPLATE_VSCODE="${TEMPLATE_DIR}/.vscode"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log_info "Bootstrapping VS Code configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# ===================================================================
# Create Directory Structure
# ===================================================================

log_info "Creating .vscode directory structure..."
mkdir -p "$VSCODE_DIR"
log_success "Directory structure created"

# ===================================================================
# Copy/Generate Settings
# ===================================================================

log_info "Setting up VS Code settings.json..."

if [[ -f "$TEMPLATE_VSCODE/settings.json" ]]; then
    cp "$TEMPLATE_VSCODE/settings.json" "$VSCODE_DIR/"
    log_success "Copied settings.json"
else
    log_info "Creating default settings.json..."
    cat > "$VSCODE_DIR/settings.json" << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.insertSpaces": true,
  "editor.tabSize": 2,
  "editor.trimAutoWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "files.trimTrailingWhitespace": true,
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.git": true,
    "**/.venv": true,
    "**/venv": true
  },
  "[javascript]": {
    "editor.formatOnSave": true
  },
  "[typescript]": {
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true
  },
  "[json]": {
    "editor.formatOnSave": true
  },
  "[python]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "ms-python.python"
  },
  "[markdown]": {
    "editor.wordWrap": "on",
    "editor.formatOnSave": false
  },
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "python.formatting.blackArgs": ["--line-length=100"]
}
EOF
    log_success "Created default settings.json"
fi

# ===================================================================
# Copy/Generate Extensions Recommendations
# ===================================================================

log_info "Setting up extensions.json..."

if [[ -f "$TEMPLATE_VSCODE/extensions.json" ]]; then
    cp "$TEMPLATE_VSCODE/extensions.json" "$VSCODE_DIR/"
    log_success "Copied extensions.json"
else
    log_info "Creating default extensions.json..."
    cat > "$VSCODE_DIR/extensions.json" << 'EOF'
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-python.python",
    "charliermarsh.ruff",
    "ms-vscode.makefile-tools",
    "redhat.vscode-yaml",
    "redhat.vscode-json-rpc",
    "eamodio.gitlens",
    "GitHub.copilot",
    "ms-vscode.remote-explorer"
  ]
}
EOF
    log_success "Created default extensions.json"
fi

# ===================================================================
# Copy/Generate Tasks Configuration
# ===================================================================

log_info "Setting up tasks.json..."

if [[ -f "$TEMPLATE_VSCODE/tasks.json" ]]; then
    cp "$TEMPLATE_VSCODE/tasks.json" "$VSCODE_DIR/"
    log_success "Copied tasks.json"
else
    log_info "Creating default tasks.json..."
    cat > "$VSCODE_DIR/tasks.json" << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Lint",
      "type": "shell",
      "command": "npm",
      "args": ["run", "lint"],
      "problemMatcher": ["$eslint"],
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "Type Check",
      "type": "shell",
      "command": "npm",
      "args": ["run", "typecheck"],
      "problemMatcher": ["$tsc"],
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "Test",
      "type": "shell",
      "command": "npm",
      "args": ["test"],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "group": {
        "kind": "test",
        "isDefault": true
      }
    },
    {
      "label": "Build",
      "type": "shell",
      "command": "npm",
      "args": ["run", "build"],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "Watch",
      "type": "shell",
      "command": "npm",
      "args": ["run", "dev"],
      "isBackground": true,
      "problemMatcher": {
        "pattern": {
          "regexp": "^.*$",
          "file": 1,
          "location": 2,
          "message": 3
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": "^.*watching.*",
          "endsPattern": "^.*compiled.*"
        }
      }
    }
  ]
}
EOF
    log_success "Created default tasks.json"
fi

# ===================================================================
# Copy/Generate Debug Launch Configuration
# ===================================================================

log_info "Setting up launch.json..."

if [[ -f "$TEMPLATE_VSCODE/launch.json" ]]; then
    cp "$TEMPLATE_VSCODE/launch.json" "$VSCODE_DIR/"
    log_success "Copied launch.json"
else
    log_info "Creating default launch.json..."
    cat > "$VSCODE_DIR/launch.json" << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Launch Node App",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/dist/index.js",
      "preLaunchTask": "Build",
      "outFiles": ["${workspaceFolder}/dist/**/*.js"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    },
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": true
    },
    {
      "name": "Python: Debug Tests",
      "type": "python",
      "request": "launch",
      "module": "pytest",
      "args": [
        "-v",
        "${file}"
      ],
      "console": "integratedTerminal",
      "justMyCode": false
    }
  ],
  "compounds": []
}
EOF
    log_success "Created default launch.json"
fi

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Directory structure
    log_info "Checking directory structure..."
    if [[ -d "$VSCODE_DIR" ]]; then
        log_success "Directory: .vscode exists"
    else
        log_error "Missing directory: .vscode"
        errors=$((errors + 1))
    fi

    # Test 2: Required files
    log_info "Checking required files..."
    for file in settings.json extensions.json tasks.json launch.json; do
        if [[ -f "$VSCODE_DIR/$file" ]]; then
            log_success "File: .vscode/$file exists"
        else
            log_error "Missing file: .vscode/$file"
            errors=$((errors + 1))
        fi
    done

    # Test 3: Validate JSON syntax
    log_info "Validating JSON syntax..."
    for json_file in "$VSCODE_DIR/settings.json" "$VSCODE_DIR/extensions.json" "$VSCODE_DIR/tasks.json" "$VSCODE_DIR/launch.json"; do
        if [[ -f "$json_file" ]]; then
            if python3 -c "import json; json.load(open('$json_file'))" 2>/dev/null; then
                log_success "JSON: $(basename $json_file) is valid"
            else
                log_warning "JSON: $(basename $json_file) has syntax errors"
                errors=$((errors + 1))
            fi
        fi
    done

    # Test 4: Validate settings.json structure
    log_info "Checking settings.json structure..."
    if [[ -f "$VSCODE_DIR/settings.json" ]]; then
        if python3 -c "import json; data=json.load(open('$VSCODE_DIR/settings.json')); assert isinstance(data, dict), 'Root must be object'" 2>/dev/null; then
            log_success "Settings: Root is valid JSON object"
        else
            log_warning "Settings: Invalid structure"
            errors=$((errors + 1))
        fi
    fi

    # Test 5: Validate extensions.json has recommendations array
    log_info "Checking extensions.json structure..."
    if [[ -f "$VSCODE_DIR/extensions.json" ]]; then
        if python3 -c "import json; data=json.load(open('$VSCODE_DIR/extensions.json')); assert 'recommendations' in data, 'Missing recommendations field'" 2>/dev/null; then
            local count=$(python3 -c "import json; data=json.load(open('$VSCODE_DIR/extensions.json')); print(len(data.get('recommendations', [])))")
            log_success "Extensions: Has 'recommendations' array with $count items"
        else
            log_warning "Extensions: Missing 'recommendations' array"
            errors=$((errors + 1))
        fi
    fi

    # Test 6: Validate tasks.json has tasks array
    log_info "Checking tasks.json structure..."
    if [[ -f "$VSCODE_DIR/tasks.json" ]]; then
        if python3 -c "import json; data=json.load(open('$VSCODE_DIR/tasks.json')); assert 'tasks' in data and isinstance(data['tasks'], list), 'Missing tasks array'" 2>/dev/null; then
            local count=$(python3 -c "import json; data=json.load(open('$VSCODE_DIR/tasks.json')); print(len(data.get('tasks', [])))")
            log_success "Tasks: Has 'tasks' array with $count tasks"
        else
            log_warning "Tasks: Missing or invalid 'tasks' array"
            errors=$((errors + 1))
        fi
    fi

    # Test 7: Validate launch.json has configurations array
    log_info "Checking launch.json structure..."
    if [[ -f "$VSCODE_DIR/launch.json" ]]; then
        if python3 -c "import json; data=json.load(open('$VSCODE_DIR/launch.json')); assert 'configurations' in data and isinstance(data['configurations'], list), 'Missing configurations array'" 2>/dev/null; then
            local count=$(python3 -c "import json; data=json.load(open('$VSCODE_DIR/launch.json')); print(len(data.get('configurations', [])))")
            log_success "Launch: Has 'configurations' array with $count configurations"
        else
            log_warning "Launch: Missing or invalid 'configurations' array"
            errors=$((errors + 1))
        fi
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_error "Validation found $errors error(s)"
        return 1
    fi
}

# ===================================================================
# Summary & Next Steps
# ===================================================================

echo ""
log_success "Bootstrap complete!"
echo ""

validate_bootstrap

echo ""
log_info "Bootstrap Summary:"
echo "  Directory: $VSCODE_DIR"
echo "  Structure:"
echo "    ├── settings.json"
echo "    ├── extensions.json"
echo "    ├── tasks.json"
echo "    └── launch.json"
echo ""

log_info "Next steps:"
echo "  1. Customize Settings"
echo "     - Edit .vscode/settings.json for your editor preferences"
echo "     - Add language-specific settings as needed"
echo "     - Configure formatter and linter preferences"
echo "  2. Manage Extensions"
echo "     - Update .vscode/extensions.json with team recommendations"
echo "     - Remove extensions not needed for your project"
echo "     - VS Code will prompt users to install recommended extensions"
echo "  3. Configure Build Tasks"
echo "     - Edit .vscode/tasks.json for your build/test commands"
echo "     - Customize task labels and commands to match your scripts"
echo "     - Add problem matchers for proper error detection"
echo "  4. Set Up Debug Configurations"
echo "     - Edit .vscode/launch.json for your runtime environments"
echo "     - Add Python, Node.js, or other debugger configs as needed"
echo "     - Test launch configurations with 'Run > Start Debugging'"
echo "  5. Commit to git:"
echo "     git add .vscode/ && git commit -m 'Setup VS Code configuration'"
echo ""
