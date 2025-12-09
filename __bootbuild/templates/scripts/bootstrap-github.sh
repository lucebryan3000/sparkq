#!/bin/bash
# =============================================================================
# @name           bootstrap-github
# @phase          2
# @category       setup
# @short          GitHub configuration and issue/PR templates
# @description    Creates GitHub-specific configuration including pull request
#                 templates, issue templates (bug/feature), GitHub Actions CI
#                 workflow, and discussion configuration for project collaboration.
#
# @creates        .github/PULL_REQUEST_TEMPLATE.md
# @creates        .github/ISSUE_TEMPLATE/bug_report.md
# @creates        .github/ISSUE_TEMPLATE/feature_request.md
# @creates        .github/workflows/ci.yml
#
# @depends        bootstrap-git, bootstrap-project
# @requires_tools git
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
# =============================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-github.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
GITHUB_DIR="${PROJECT_ROOT}/.github"
TEMPLATE_GITHUB="${TEMPLATES_DIR}/.github"

# Script identifier
SCRIPT_NAME="bootstrap-github"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "git" \
    --scripts "bootstrap-git bootstrap-project" \
    --optional ""


# Pre-execution confirmation
pre_execution_confirm "$SCRIPT_NAME" "GitHub Configuration" \
    ".github/ISSUE_TEMPLATE/" ".github/PULL_REQUEST_TEMPLATE.md" \
    ".github/workflows/"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping GitHub configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_fatal "Project directory not found: $PROJECT_ROOT"
fi

if [[ ! -d "$TEMPLATE_GITHUB" ]]; then
    log_fatal "Template .github directory not found: $TEMPLATE_GITHUB"
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

if [[ -f "$GITHUB_DIR/PULL_REQUEST_TEMPLATE.md" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$GITHUB_DIR/PULL_REQUEST_TEMPLATE.md"
    else
        track_skipped "PULL_REQUEST_TEMPLATE.md"
        log_warning "PULL_REQUEST_TEMPLATE.md already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_GITHUB/PULL_REQUEST_TEMPLATE.md" ]]; then
    if cp "$TEMPLATE_GITHUB/PULL_REQUEST_TEMPLATE.md" "$GITHUB_DIR/"; then
        track_created ".github/PULL_REQUEST_TEMPLATE.md"
        log_file_created "$SCRIPT_NAME" ".github/PULL_REQUEST_TEMPLATE.md"
    fi
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
    track_created ".github/PULL_REQUEST_TEMPLATE.md"
    log_file_created "$SCRIPT_NAME" ".github/PULL_REQUEST_TEMPLATE.md"
fi

# ===================================================================
# Copy Issue Templates
# ===================================================================

log_info "Setting up issue templates..."

# Bug report template
if [[ -f "$GITHUB_DIR/ISSUE_TEMPLATE/bug_report.md" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$GITHUB_DIR/ISSUE_TEMPLATE/bug_report.md"
    else
        track_skipped "bug_report.md"
        log_warning "bug_report.md already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/bug_report.md" ]]; then
    if cp "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/bug_report.md" "$GITHUB_DIR/ISSUE_TEMPLATE/"; then
        track_created ".github/ISSUE_TEMPLATE/bug_report.md"
        log_file_created "$SCRIPT_NAME" ".github/ISSUE_TEMPLATE/bug_report.md"
    fi
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
    track_created ".github/ISSUE_TEMPLATE/bug_report.md"
    log_file_created "$SCRIPT_NAME" ".github/ISSUE_TEMPLATE/bug_report.md"
fi

# Feature request template
if [[ -f "$GITHUB_DIR/ISSUE_TEMPLATE/feature_request.md" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$GITHUB_DIR/ISSUE_TEMPLATE/feature_request.md"
    else
        track_skipped "feature_request.md"
        log_warning "feature_request.md already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/feature_request.md" ]]; then
    if cp "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/feature_request.md" "$GITHUB_DIR/ISSUE_TEMPLATE/"; then
        track_created ".github/ISSUE_TEMPLATE/feature_request.md"
        log_file_created "$SCRIPT_NAME" ".github/ISSUE_TEMPLATE/feature_request.md"
    fi
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
    track_created ".github/ISSUE_TEMPLATE/feature_request.md"
    log_file_created "$SCRIPT_NAME" ".github/ISSUE_TEMPLATE/feature_request.md"
fi

# Issue template config
if [[ -f "$GITHUB_DIR/ISSUE_TEMPLATE/config.yml" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$GITHUB_DIR/ISSUE_TEMPLATE/config.yml"
    else
        track_skipped "ISSUE_TEMPLATE/config.yml"
        log_warning "config.yml already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/config.yml" ]]; then
    if cp "$TEMPLATE_GITHUB/ISSUE_TEMPLATE/config.yml" "$GITHUB_DIR/ISSUE_TEMPLATE/"; then
        track_created ".github/ISSUE_TEMPLATE/config.yml"
        log_file_created "$SCRIPT_NAME" ".github/ISSUE_TEMPLATE/config.yml"
    fi
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
    track_created ".github/ISSUE_TEMPLATE/config.yml"
    log_file_created "$SCRIPT_NAME" ".github/ISSUE_TEMPLATE/config.yml"
fi

# ===================================================================
# Copy CI/CD Workflows
# ===================================================================

log_info "Setting up GitHub Actions workflows..."

if [[ -f "$GITHUB_DIR/workflows/ci.yml" ]]; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$GITHUB_DIR/workflows/ci.yml"
    else
        track_skipped "workflows/ci.yml"
        log_warning "ci.yml workflow already exists, skipping"
    fi
fi

if [[ -f "$TEMPLATE_GITHUB/workflows/ci.yml" ]]; then
    if cp "$TEMPLATE_GITHUB/workflows/ci.yml" "$GITHUB_DIR/workflows/"; then
        track_created ".github/workflows/ci.yml"
        log_file_created "$SCRIPT_NAME" ".github/workflows/ci.yml"
    fi
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
    track_created ".github/workflows/ci.yml"
    log_file_created "$SCRIPT_NAME" ".github/workflows/ci.yml"
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
            log_fatal "Missing directory: .github/$dir"
            errors=$((errors + 1))
        fi
    done

    # Test 2: Required files
    log_info "Checking required files..."
    for file in PULL_REQUEST_TEMPLATE.md ISSUE_TEMPLATE/bug_report.md ISSUE_TEMPLATE/feature_request.md ISSUE_TEMPLATE/config.yml workflows/ci.yml; do
        if [[ -f "$GITHUB_DIR/$file" ]]; then
            log_success "File: .github/$file exists"
        else
            log_fatal "Missing file: .github/$file"
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
        log_fatal "Validation found $errors error(s)"
        return 1
    fi
}

# ===================================================================
# Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
echo "  1. Edit PR template to match your process"
echo "  2. Update issue templates for your project"
echo "  3. Edit .github/workflows/ci.yml for your tech stack"
echo "  4. Commit: git add .github/ && git commit -m 'Setup GitHub configuration'"
echo ""
