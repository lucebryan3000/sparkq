#!/bin/bash
# =============================================================================
# @script         bootstrap-cicd
# @version        1.0.0
# @phase          4
# @category       deploy
# @priority       50
#
# @short          CI/CD pipeline configuration
# @description    CI/CD pipeline configuration for GitHub Actions, GitLab CI,
#                 Azure Pipelines, and CircleCI. Creates standardized workflow
#                 templates for testing, building, and deployment.
#
# @creates        .github/workflows/
# @creates        .github/workflows/ci.yml
# @creates        .gitlab-ci.yml
# @creates        azure-pipelines.yml
# @creates        .circleci/config.yml
#
# @depends        project
#
# @requires       tool:git
#
# @detects        has_github_dir
# @questions      none
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  cicd
# @env_vars        ENABLED,NODE_VERSION
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf .github/workflows/ .github/workflows/ci.yml .gitlab-ci.yml azure-pipelines.yml .circleci/config.yml
# @verify          test -f .github/workflows/
# @docs            https://docs.github.com/en/actions
# =============================================================================

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
init_script "bootstrap-cicd"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-cicd"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "git" \
    --scripts "bootstrap-project" \
    --optional ""

# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "cicd.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "CI/CD bootstrap disabled in config"
    exit 0
fi

# Read cicd-specific settings
CI_PROVIDER=$(config_get "cicd.provider" "github")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "CI/CD Configuration" \
    ".github/workflows/" \
    ".gitlab-ci.yml" \
    "azure-pipelines.yml" \
    ".circleci/"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Check if git repo exists
if ! dir_exists "$PROJECT_ROOT/.git"; then
    track_warning "Git repository not found - CI/CD setup may need adjustment"
    log_warning "Git repository not found at $PROJECT_ROOT/.git"
fi

log_success "Environment validated"

# ===================================================================
# Create .github/workflows (GitHub Actions)
# ===================================================================

log_info "Creating GitHub Actions workflow configuration..."

ensure_dir "$PROJECT_ROOT/.github/workflows"

# Create main CI workflow
if file_exists "$PROJECT_ROOT/.github/workflows/ci.yml"; then
    backup_file "$PROJECT_ROOT/.github/workflows/ci.yml"
    track_skipped ".github/workflows/ci.yml (backed up)"
    log_warning ".github/workflows/ci.yml already exists, backed up"
else
    if cat > "$PROJECT_ROOT/.github/workflows/ci.yml" << 'EOFGITHUBCI'
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
      - uses: actions/checkout@v4

      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Build
        run: npm run build

      - name: Test
        run: npm test

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
EOFGITHUBCI
    then
        verify_file "$PROJECT_ROOT/.github/workflows/ci.yml"
        log_file_created "$SCRIPT_NAME" ".github/workflows/ci.yml"
        track_created ".github/workflows/ci.yml"
    else
        log_fatal "Failed to create .github/workflows/ci.yml"
    fi
fi

# ===================================================================
# Create .gitlab-ci.yml (GitLab CI)
# ===================================================================

log_info "Creating GitLab CI configuration..."

if file_exists "$PROJECT_ROOT/.gitlab-ci.yml"; then
    backup_file "$PROJECT_ROOT/.gitlab-ci.yml"
    track_skipped ".gitlab-ci.yml (backed up)"
    log_warning ".gitlab-ci.yml already exists, backed up"
else
    if cat > "$PROJECT_ROOT/.gitlab-ci.yml" << 'EOFGITLABCI'
stages:
  - lint
  - build
  - test

variables:
  NODE_VERSION: "20"

lint:
  stage: lint
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm run lint
  cache:
    paths:
      - node_modules/

build:
  stage: build
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour
  cache:
    paths:
      - node_modules/

test:
  stage: test
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm test -- --coverage
  coverage: '/Lines\s*:\s*(\d+\.?\d*)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
  cache:
    paths:
      - node_modules/
EOFGITLABCI
    then
        verify_file "$PROJECT_ROOT/.gitlab-ci.yml"
        log_file_created "$SCRIPT_NAME" ".gitlab-ci.yml"
        track_created ".gitlab-ci.yml"
    else
        log_fatal "Failed to create .gitlab-ci.yml"
    fi
fi

# ===================================================================
# Create azure-pipelines.yml (Azure Pipelines)
# ===================================================================

log_info "Creating Azure Pipelines configuration..."

if file_exists "$PROJECT_ROOT/azure-pipelines.yml"; then
    backup_file "$PROJECT_ROOT/azure-pipelines.yml"
    track_skipped "azure-pipelines.yml (backed up)"
    log_warning "azure-pipelines.yml already exists, backed up"
else
    if cat > "$PROJECT_ROOT/azure-pipelines.yml" << 'EOFAZURE'
trigger:
  - main
  - develop

pr:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

strategy:
  matrix:
    node_18:
      nodeVersion: '18.x'
    node_20:
      nodeVersion: '20.x'

steps:
  - task: NodeTool@0
    inputs:
      versionSpec: $(nodeVersion)
    displayName: 'Install Node.js $(nodeVersion)'

  - task: Cache@2
    inputs:
      key: 'npm | "$(Agent.OS)" | package-lock.json'
      restoreKeys: |
        npm | "$(Agent.OS)"
      path: $(npm_config_cache)
    displayName: 'Cache npm packages'

  - script: npm ci
    displayName: 'Install dependencies'

  - script: npm run lint
    displayName: 'Run linter'

  - script: npm run build
    displayName: 'Build project'

  - script: npm test -- --coverage
    displayName: 'Run tests'

  - task: PublishCodeCoverageResults@1
    inputs:
      codeCoverageTool: Cobertura
      summaryFileLocation: '$(System.DefaultWorkingDirectory)/coverage/cobertura-coverage.xml'
EOFAZURE
    then
        verify_file "$PROJECT_ROOT/azure-pipelines.yml"
        log_file_created "$SCRIPT_NAME" "azure-pipelines.yml"
        track_created "azure-pipelines.yml"
    else
        log_fatal "Failed to create azure-pipelines.yml"
    fi
fi

# ===================================================================
# Create .circleci/config.yml (CircleCI)
# ===================================================================

log_info "Creating CircleCI configuration..."

ensure_dir "$PROJECT_ROOT/.circleci"

if file_exists "$PROJECT_ROOT/.circleci/config.yml"; then
    backup_file "$PROJECT_ROOT/.circleci/config.yml"
    track_skipped ".circleci/config.yml (backed up)"
    log_warning ".circleci/config.yml already exists, backed up"
else
    if cat > "$PROJECT_ROOT/.circleci/config.yml" << 'EOFCIRCLECI'
version: 2.1

jobs:
  test:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - restore_cache:
          keys:
            - npm-cache-v1-{{ checksum "package-lock.json" }}
            - npm-cache-v1-
      - run:
          name: Install dependencies
          command: npm ci
      - save_cache:
          key: npm-cache-v1-{{ checksum "package-lock.json" }}
          paths:
            - ~/.npm
      - run:
          name: Run linter
          command: npm run lint
      - run:
          name: Build project
          command: npm run build
      - run:
          name: Run tests
          command: npm test -- --coverage
      - store_artifacts:
          path: coverage
          destination: coverage

workflows:
  version: 2
  test_and_build:
    jobs:
      - test:
          filters:
            branches:
              only:
                - main
                - develop
EOFCIRCLECI
    then
        verify_file "$PROJECT_ROOT/.circleci/config.yml"
        log_file_created "$SCRIPT_NAME" ".circleci/config.yml"
        track_created ".circleci/config.yml"
    else
        log_fatal "Failed to create .circleci/config.yml"
    fi
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "CI/CD configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Review CI provider configuration based on your platform:"
echo "     - GitHub: .github/workflows/ci.yml"
echo "     - GitLab: .gitlab-ci.yml"
echo "     - Azure: azure-pipelines.yml"
echo "     - CircleCI: .circleci/config.yml"
echo ""
echo "  2. Push configuration to remote repository"
echo "  3. Enable CI/CD in your platform (GitHub Actions enabled by default)"
echo "  4. Customize pipeline stages and jobs as needed"
echo ""
echo "Platform setup guide:"
echo "  - GitHub Actions: No setup needed, runs automatically"
echo "  - GitLab CI: Enable in Settings > CI/CD > CI/CD"
echo "  - Azure Pipelines: Create pipeline in Azure DevOps"
echo "  - CircleCI: Connect repository in CircleCI dashboard"
echo ""

show_log_location
