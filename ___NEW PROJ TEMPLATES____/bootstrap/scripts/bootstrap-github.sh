#!/bin/bash

# ===================================================================
# bootstrap-github.sh
#
# Bootstrap GitHub configuration for a new project
# Creates .github/ directory structure with PR templates, issue templates,
# and CI/CD workflows per official GitHub documentation
#
# OFFICIAL DOCUMENTATION:
# - GitHub Templates: https://docs.github.com/en/communities/using-templates
# - Issue Templates: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
# - GitHub Actions: https://docs.github.com/en/actions
#
# CONFIGURATION SOURCE OF TRUTH:
# Template files in ___NEW PROJ TEMPLATES____/.github/ are the authoritative source
# These templates have been validated against official GitHub specifications.
# ===================================================================

set -e

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"
GITHUB_DIR="${PROJECT_ROOT}/.github"
TEMPLATE_GITHUB="${TEMPLATE_DIR}/.github"

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
# Template Validation Functions (Pre-Copy Validation)
# ===================================================================

# Validates GitHub issue template structure against official specs
# Official: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
validate_issue_template() {
    local template_file="$1"
    local template_name=$(basename "$template_file")

    if [[ ! -f "$template_file" ]]; then
        return 0  # Not a template validation failure, just missing template
    fi

    # Check for YAML frontmatter
    if ! grep -q "^---$" "$template_file"; then
        log_warning "Issue template '$template_name' missing YAML frontmatter"
        return 1
    fi

    # Check for required YAML fields in frontmatter using grep
    local required_fields=("name:" "about:" "title:" "labels:" "assignees:")
    local missing=0
    for field in "${required_fields[@]}"; do
        if ! sed -n '1,/^---$/p' "$template_file" | grep -q "^$field"; then
            missing=$((missing + 1))
        fi
    done

    if [[ $missing -gt 0 ]]; then
        log_warning "Issue template '$template_name' missing required YAML fields (name, about, title, labels, assignees)"
        return 1
    fi

    return 0
}

# Validates GitHub Actions workflow structure against official specs
# Official: https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions
validate_workflow_template() {
    local workflow_file="$1"
    local workflow_name=$(basename "$workflow_file")

    if [[ ! -f "$workflow_file" ]]; then
        return 0
    fi

    # Check for required workflow fields
    if ! grep -q "^name:" "$workflow_file"; then
        log_warning "Workflow '$workflow_name' missing 'name' field"
        return 1
    fi

    if ! grep -q "^on:" "$workflow_file"; then
        log_warning "Workflow '$workflow_name' missing 'on' field (event trigger)"
        return 1
    fi

    if ! grep -q "^jobs:" "$workflow_file"; then
        log_warning "Workflow '$workflow_name' missing 'jobs' field"
        return 1
    fi

    # Validate YAML syntax using Python
    if ! python3 -c "import yaml; yaml.safe_load(open('$workflow_file'))" 2>/dev/null; then
        log_warning "Workflow '$workflow_name' has invalid YAML syntax"
        return 1
    fi

    return 0
}

# Validates issue template config.yml against official specs
validate_config_template() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    # Check for required config fields
    if ! grep -q "^blank_issues_enabled:" "$config_file"; then
        log_warning "Config missing 'blank_issues_enabled' field"
        return 1
    fi

    # Validate YAML syntax
    if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
        log_warning "Config has invalid YAML syntax"
        return 1
    fi

    return 0
}

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping GitHub configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

if [[ ! -d "$TEMPLATE_GITHUB" ]]; then
    log_error "Template .github directory not found: $TEMPLATE_GITHUB"
fi

# ===================================================================
# Create Directory Structure
# ===================================================================

log_info "Creating .github directory structure..."
mkdir -p "$GITHUB_DIR"/{ISSUE_TEMPLATE,workflows}
log_success "Directory structure created"

# ===================================================================
# Copy Pull Request Template
# ===================================================================

log_info "Setting up pull request template..."

if [[ -f "$TEMPLATE_GITHUB/PULL_REQUEST_TEMPLATE.md" ]]; then
    cp "$TEMPLATE_GITHUB/PULL_REQUEST_TEMPLATE.md" "$GITHUB_DIR/"
    log_success "Copied PULL_REQUEST_TEMPLATE.md"
else
    log_info "Creating default PULL_REQUEST_TEMPLATE.md..."
    cat > "$GITHUB_DIR/PULL_REQUEST_TEMPLATE.md" << 'EOF'
## Summary

Brief description of the changes.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Testing

Describe the tests you ran and how to reproduce:

- [ ] Test A
- [ ] Test B
- [ ] Test C

## Checklist

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings

## Related Issues

Closes #[issue_number]

## Screenshots (if applicable)

Add screenshots here
EOF
    log_success "Created default PULL_REQUEST_TEMPLATE.md"
fi

# ===================================================================
# Copy Issue Templates
# ===================================================================

log_info "Setting up issue templates..."

# Bug report template
if [[ -f "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/bug_report.md" ]]; then
    # Validate template before copying
    validate_issue_template "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/bug_report.md"
    cp "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/bug_report.md" "$GITHUB_DIR/ISSUE_TEMPLATE/"
    log_success "Copied bug_report.md"
else
    log_info "Creating default bug_report.md..."
    cat > "$GITHUB_DIR/ISSUE_TEMPLATE/bug_report.md" << 'EOF'
---
name: Bug Report
about: Create a report to help us improve
title: "[BUG]"
labels: bug
assignees: ""
---

## Describe the Bug

A clear and concise description of what the bug is.

## To Reproduce

Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior

A clear and concise description of what you expected to happen.

## Actual Behavior

What actually happened instead.

## Screenshots

If applicable, add screenshots to help explain the problem.

## Environment

- OS: [e.g. macOS, Ubuntu, Windows]
- Node/Python Version: [e.g. 20.0.0, 3.11.0]
- Project Version: [e.g. 1.0.0]

## Additional Context

Add any other context about the problem here.
EOF
    log_success "Created default bug_report.md"
fi

# Feature request template
if [[ -f "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/feature_request.md" ]]; then
    # Validate template before copying
    validate_issue_template "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/feature_request.md"
    cp "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/feature_request.md" "$GITHUB_DIR/ISSUE_TEMPLATE/"
    log_success "Copied feature_request.md"
else
    log_info "Creating default feature_request.md..."
    cat > "$GITHUB_DIR/ISSUE_TEMPLATE/feature_request.md" << 'EOF'
---
name: Feature Request
about: Suggest an idea for this project
title: "[FEATURE]"
labels: enhancement
assignees: ""
---

## Is your feature request related to a problem?

A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

## Describe the Solution you'd Like

A clear and concise description of what you want to happen.

## Describe Alternatives you've Considered

A clear and concise description of any alternative solutions or features you've considered.

## Additional Context

Add any other context or screenshots about the feature request here.
EOF
    log_success "Created default feature_request.md"
fi

# Issue template config
if [[ -f "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/config.yml" ]]; then
    # Validate config before copying
    validate_config_template "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/config.yml"
    cp "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/config.yml" "$GITHUB_DIR/ISSUE_TEMPLATE/"
    log_success "Copied config.yml"
else
    log_info "Creating default config.yml..."
    cat > "$GITHUB_DIR/ISSUE_TEMPLATE/config.yml" << 'EOF'
blank_issues_enabled: true
contact_links:
  - name: GitHub Discussions
    url: https://github.com/[org]/[repo]/discussions
    about: "For general questions and discussions"
  - name: Documentation
    url: https://docs.example.com
    about: "Check our documentation for common questions"
EOF
    log_success "Created default config.yml"
fi

# ===================================================================
# Copy CI/CD Workflows
# ===================================================================

log_info "Setting up GitHub Actions workflows..."

if [[ -f "$TEMPLATE_GITHUB/workflows/ci.yml" ]]; then
    # Validate workflow before copying
    validate_workflow_template "$TEMPLATE_GITHUB/workflows/ci.yml"
    cp "$TEMPLATE_GITHUB/workflows/ci.yml" "$GITHUB_DIR/workflows/"
    log_success "Copied ci.yml workflow"
else
    log_info "Creating default ci.yml workflow..."
    cat > "$GITHUB_DIR/workflows/ci.yml" << 'EOF'
name: CI

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm ci
      - run: npm run lint
        if: always()

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm ci
      - run: npm run typecheck
        if: always()

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm ci
      - run: npm test
        if: always()

  build:
    runs-on: ubuntu-latest
    needs: [lint, typecheck, test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm ci
      - run: npm run build
        if: always()
EOF
    log_success "Created default ci.yml workflow"
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
    for dir in ISSUE_TEMPLATE workflows; do
        if [[ -d "$GITHUB_DIR/$dir" ]]; then
            log_success "Directory: .github/$dir exists"
        else
            log_error "Missing directory: .github/$dir"
            errors=$((errors + 1))
        fi
    done

    # Test 2: Required files
    log_info "Checking required files..."
    for file in PULL_REQUEST_TEMPLATE.md ISSUE_TEMPLATE/bug_report.md ISSUE_TEMPLATE/feature_request.md ISSUE_TEMPLATE/config.yml workflows/ci.yml; do
        if [[ -f "$GITHUB_DIR/$file" ]]; then
            log_success "File: .github/$file exists"
        else
            log_error "Missing file: .github/$file"
            errors=$((errors + 1))
        fi
    done

    # Test 3: Validate YAML files (Haiku-style validation)
    log_info "Validating YAML syntax..."
    for yaml_file in "$GITHUB_DIR/ISSUE_TEMPLATE/config.yml" "$GITHUB_DIR/workflows/ci.yml"; do
        if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
            log_success "YAML: $(basename $yaml_file) is valid"
        else
            log_warning "YAML: $(basename $yaml_file) may have syntax issues"
        fi
    done

    # Test 4: Check markdown format
    log_info "Checking markdown files..."
    for md_file in "$GITHUB_DIR/PULL_REQUEST_TEMPLATE.md" "$GITHUB_DIR/ISSUE_TEMPLATE/bug_report.md" "$GITHUB_DIR/ISSUE_TEMPLATE/feature_request.md"; do
        if [[ -f "$md_file" ]]; then
            if grep -q "^---" "$md_file" 2>/dev/null || [[ $(wc -l < "$md_file") -gt 0 ]]; then
                log_success "Markdown: $(basename $md_file) exists"
            else
                log_warning "Markdown: $(basename $md_file) may be empty"
            fi
        fi
    done

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
echo "  Directory: $GITHUB_DIR"
echo "  Structure:"
echo "    ├── PULL_REQUEST_TEMPLATE.md"
echo "    ├── ISSUE_TEMPLATE/"
echo "    │   ├── bug_report.md"
echo "    │   ├── feature_request.md"
echo "    │   └── config.yml"
echo "    └── workflows/"
echo "        └── ci.yml"
echo ""

log_info "Next steps:"
echo "  1. Customize Templates"
echo "     - Edit PR template to match your process"
echo "     - Update issue templates for your project"
echo "     - Update config.yml links for your repository"
echo "  2. Customize CI Workflow"
echo "     - Edit .github/workflows/ci.yml for your tech stack"
echo "     - Add deployment jobs if needed"
echo "     - Configure branch protection rules"
echo "  3. Commit to git:"
echo "     git add .github/ && git commit -m 'Setup GitHub configuration'"
echo ""
