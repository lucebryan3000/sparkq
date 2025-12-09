#!/bin/bash
# =============================================================================
# @name           bootstrap-ci-cd
# @phase          4
# @category       deploy
# @short          Multi-platform CI/CD pipeline configurations
# @description    Creates comprehensive CI/CD pipeline configurations for five
#                 platforms: GitLab CI, Jenkins, CircleCI, Azure Pipelines,
#                 Bitbucket Pipelines. Each includes linting, building, testing
#                 with Node matrix, caching, and code coverage reporting.
#
# @creates        .gitlab-ci.yml
# @creates        Jenkinsfile
# @creates        .circleci/config.yml
# @creates        azure-pipelines.yml
# @creates        bitbucket-pipelines.yml
#
# @depends        bootstrap-git, bootstrap-github
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
init_script "bootstrap-ci-cd.sh"

# Source additional libraries
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
TEMPLATE_ROOT="${TEMPLATES_DIR}/root/cicd"

# Script identifier and answers file
SCRIPT_NAME="bootstrap-ci-cd"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "git" \
    --scripts "bootstrap-git bootstrap-github" \
    --optional ""

ANSWERS_FILE=".bootstrap-answers.env"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "CI/CD Pipeline Configuration" \
    ".gitlab-ci.yml (GitLab)" \
    "Jenkinsfile (Jenkins)" \
    ".circleci/config.yml (CircleCI)" \
    "azure-pipelines.yml (Azure)" \
    "bitbucket-pipelines.yml (Bitbucket)"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping CI/CD pipeline configuration..."

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

if [[ ! -d "$TEMPLATE_ROOT" ]]; then
    log_fatal "CI/CD template directory not found: $TEMPLATE_ROOT"
fi

# ===================================================================
# Detect CI/CD Platform
# ===================================================================

detect_cicd_platform() {
    local platform=""

    # Check for existing configurations
    if [[ -f "$PROJECT_ROOT/.gitlab-ci.yml" ]]; then
        platform="gitlab"
    elif [[ -f "$PROJECT_ROOT/Jenkinsfile" ]]; then
        platform="jenkins"
    elif [[ -d "$PROJECT_ROOT/.circleci" ]]; then
        platform="circleci"
    elif [[ -f "$PROJECT_ROOT/azure-pipelines.yml" ]]; then
        platform="azure"
    elif [[ -f "$PROJECT_ROOT/bitbucket-pipelines.yml" ]]; then
        platform="bitbucket"
    fi

    echo "$platform"
}

DETECTED_PLATFORM=$(detect_cicd_platform)

if [[ -n "$DETECTED_PLATFORM" ]]; then
    log_info "Detected existing CI/CD platform: $DETECTED_PLATFORM"
fi

# ===================================================================
# Create GitLab CI Configuration
# ===================================================================

log_info "Creating GitLab CI configuration..."

if file_exists "$PROJECT_ROOT/.gitlab-ci.yml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.gitlab-ci.yml"
    else
        track_skipped ".gitlab-ci.yml"
        log_warning ".gitlab-ci.yml already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/.gitlab-ci.yml"; then
    if file_exists "$TEMPLATE_ROOT/.gitlab-ci.yml"; then
        if cp "$TEMPLATE_ROOT/.gitlab-ci.yml" "$PROJECT_ROOT/"; then
            if verify_file "$PROJECT_ROOT/.gitlab-ci.yml"; then
                track_created ".gitlab-ci.yml"
                log_file_created "$SCRIPT_NAME" ".gitlab-ci.yml"
            fi
        else
            log_fatal "Failed to copy .gitlab-ci.yml"
        fi
    else
        track_warning ".gitlab-ci.yml template not found"
        log_warning ".gitlab-ci.yml template not found in $TEMPLATE_ROOT"
    fi
fi

# ===================================================================
# Create Jenkins Pipeline
# ===================================================================

log_info "Creating Jenkinsfile..."

if file_exists "$PROJECT_ROOT/Jenkinsfile"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/Jenkinsfile"
    else
        track_skipped "Jenkinsfile"
        log_warning "Jenkinsfile already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/Jenkinsfile"; then
    if file_exists "$TEMPLATE_ROOT/Jenkinsfile"; then
        if cp "$TEMPLATE_ROOT/Jenkinsfile" "$PROJECT_ROOT/"; then
            if verify_file "$PROJECT_ROOT/Jenkinsfile"; then
                track_created "Jenkinsfile"
                log_file_created "$SCRIPT_NAME" "Jenkinsfile"
            fi
        else
            log_fatal "Failed to copy Jenkinsfile"
        fi
    else
        track_warning "Jenkinsfile template not found"
        log_warning "Jenkinsfile template not found in $TEMPLATE_ROOT"
    fi
fi

# ===================================================================
# Create CircleCI Configuration
# ===================================================================

log_info "Creating CircleCI configuration..."

mkdir -p "$PROJECT_ROOT/.circleci"

if file_exists "$PROJECT_ROOT/.circleci/config.yml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.circleci/config.yml"
    else
        track_skipped ".circleci/config.yml"
        log_warning ".circleci/config.yml already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/.circleci/config.yml"; then
    if file_exists "$TEMPLATE_ROOT/.circleci-config.yml"; then
        if cp "$TEMPLATE_ROOT/.circleci-config.yml" "$PROJECT_ROOT/.circleci/config.yml"; then
            if verify_file "$PROJECT_ROOT/.circleci/config.yml"; then
                track_created ".circleci/config.yml"
                log_file_created "$SCRIPT_NAME" ".circleci/config.yml"
            fi
        else
            log_fatal "Failed to copy .circleci/config.yml"
        fi
    else
        track_warning ".circleci/config.yml template not found"
        log_warning ".circleci/config.yml template not found in $TEMPLATE_ROOT"
    fi
fi

# ===================================================================
# Create Azure Pipelines Configuration
# ===================================================================

log_info "Creating Azure Pipelines configuration..."

if file_exists "$PROJECT_ROOT/azure-pipelines.yml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/azure-pipelines.yml"
    else
        track_skipped "azure-pipelines.yml"
        log_warning "azure-pipelines.yml already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/azure-pipelines.yml"; then
    if file_exists "$TEMPLATE_ROOT/azure-pipelines.yml"; then
        if cp "$TEMPLATE_ROOT/azure-pipelines.yml" "$PROJECT_ROOT/"; then
            if verify_file "$PROJECT_ROOT/azure-pipelines.yml"; then
                track_created "azure-pipelines.yml"
                log_file_created "$SCRIPT_NAME" "azure-pipelines.yml"
            fi
        else
            log_fatal "Failed to copy azure-pipelines.yml"
        fi
    else
        track_warning "azure-pipelines.yml template not found"
        log_warning "azure-pipelines.yml template not found in $TEMPLATE_ROOT"
    fi
fi

# ===================================================================
# Create Bitbucket Pipelines Configuration
# ===================================================================

log_info "Creating Bitbucket Pipelines configuration..."

if file_exists "$PROJECT_ROOT/bitbucket-pipelines.yml"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/bitbucket-pipelines.yml"
    else
        track_skipped "bitbucket-pipelines.yml"
        log_warning "bitbucket-pipelines.yml already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/bitbucket-pipelines.yml"; then
    if file_exists "$TEMPLATE_ROOT/bitbucket-pipelines.yml"; then
        if cp "$TEMPLATE_ROOT/bitbucket-pipelines.yml" "$PROJECT_ROOT/"; then
            if verify_file "$PROJECT_ROOT/bitbucket-pipelines.yml"; then
                track_created "bitbucket-pipelines.yml"
                log_file_created "$SCRIPT_NAME" "bitbucket-pipelines.yml"
            fi
        else
            log_fatal "Failed to copy bitbucket-pipelines.yml"
        fi
    else
        track_warning "bitbucket-pipelines.yml template not found"
        log_warning "bitbucket-pipelines.yml template not found in $TEMPLATE_ROOT"
    fi
fi

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Check created files
    log_info "Checking CI/CD configuration files..."
    local files_found=0

    if [[ -f "$PROJECT_ROOT/.gitlab-ci.yml" ]]; then
        log_success "GitLab CI: .gitlab-ci.yml exists"
        ((files_found++))
    fi

    if [[ -f "$PROJECT_ROOT/Jenkinsfile" ]]; then
        log_success "Jenkins: Jenkinsfile exists"
        ((files_found++))
    fi

    if [[ -f "$PROJECT_ROOT/.circleci/config.yml" ]]; then
        log_success "CircleCI: .circleci/config.yml exists"
        ((files_found++))
    fi

    if [[ -f "$PROJECT_ROOT/azure-pipelines.yml" ]]; then
        log_success "Azure: azure-pipelines.yml exists"
        ((files_found++))
    fi

    if [[ -f "$PROJECT_ROOT/bitbucket-pipelines.yml" ]]; then
        log_success "Bitbucket: bitbucket-pipelines.yml exists"
        ((files_found++))
    fi

    if [[ $files_found -eq 0 ]]; then
        log_warning "No CI/CD configuration files created"
        errors=$((errors + 1))
    else
        log_success "Created $files_found CI/CD configuration file(s)"
    fi

    # Test 2: Validate YAML syntax
    log_info "Validating YAML syntax..."

    for yaml_file in \
        "$PROJECT_ROOT/.gitlab-ci.yml" \
        "$PROJECT_ROOT/.circleci/config.yml" \
        "$PROJECT_ROOT/azure-pipelines.yml" \
        "$PROJECT_ROOT/bitbucket-pipelines.yml"; do

        if [[ -f "$yaml_file" ]]; then
            if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
                log_success "YAML: $(basename $yaml_file) is valid"
            else
                log_warning "YAML: $(basename $yaml_file) has syntax issues"
                errors=$((errors + 1))
            fi
        fi
    done

    # Test 3: Check pipeline stages
    log_info "Checking pipeline structure..."

    if [[ -f "$PROJECT_ROOT/.gitlab-ci.yml" ]]; then
        if grep -q "^stages:" "$PROJECT_ROOT/.gitlab-ci.yml"; then
            local stage_count=$(grep "^  - " "$PROJECT_ROOT/.gitlab-ci.yml" | head -6 | wc -l || true)
            log_success "GitLab: Found $stage_count stage(s)"
        fi
    fi

    if [[ -f "$PROJECT_ROOT/Jenkinsfile" ]]; then
        if grep -q "pipeline {" "$PROJECT_ROOT/Jenkinsfile"; then
            log_success "Jenkins: Pipeline structure found"
        fi
    fi

    if [[ -f "$PROJECT_ROOT/.circleci/config.yml" ]]; then
        if grep -q "^workflows:" "$PROJECT_ROOT/.circleci/config.yml"; then
            log_success "CircleCI: Workflow structure found"
        fi
    fi

    if [[ -f "$PROJECT_ROOT/azure-pipelines.yml" ]]; then
        if grep -q "^stages:" "$PROJECT_ROOT/azure-pipelines.yml"; then
            log_success "Azure: Pipeline stages found"
        fi
    fi

    if [[ -f "$PROJECT_ROOT/bitbucket-pipelines.yml" ]]; then
        if grep -q "^pipelines:" "$PROJECT_ROOT/bitbucket-pipelines.yml"; then
            log_success "Bitbucket: Pipeline structure found"
        fi
    fi

    # Test 4: Check for common pipeline jobs
    log_info "Checking for standard jobs..."
    local jobs_found=0

    for config_file in \
        "$PROJECT_ROOT/.gitlab-ci.yml" \
        "$PROJECT_ROOT/Jenkinsfile" \
        "$PROJECT_ROOT/.circleci/config.yml" \
        "$PROJECT_ROOT/azure-pipelines.yml" \
        "$PROJECT_ROOT/bitbucket-pipelines.yml"; do

        if [[ -f "$config_file" ]]; then
            if grep -qi "test" "$config_file" && \
               grep -qi "build" "$config_file" && \
               grep -qi "lint" "$config_file"; then
                ((jobs_found++))
            fi
        fi
    done

    if [[ $jobs_found -gt 0 ]]; then
        log_success "Standard jobs: Found in $jobs_found config(s)"
    else
        log_warning "Standard jobs: Not found in any config"
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Validation found $errors issue(s) (non-critical)"
        return 0
    fi
}

# ===================================================================
# Template Customization
# ===================================================================

customize_templates() {
    log_info "Customizing templates with your configuration..."

    # Only customize if answers file exists
    if [[ ! -f "$ANSWERS_FILE" ]]; then
        log_warning "No answers file found. Skipping customization."
        return 0
    fi

    # Source answers
    source "$ANSWERS_FILE"

    local customized=0

    # Read configuration
    local ci_platform=$(config_get "cicd.platform" "")
    local ci_node_version=$(config_get "cicd.node_version" "20")
    local ci_cache_enabled=$(config_get "cicd.cache_enabled" "true")
    local ci_test_coverage=$(config_get "cicd.test_coverage" "true")
    local ci_deploy_staging=$(config_get "cicd.deploy_staging" "true")
    local ci_deploy_production=$(config_get "cicd.deploy_production" "true")

    # Update NODE_VERSION in all config files if specified
    if [[ -n "$ci_node_version" ]]; then
        log_info "Setting Node.js version to $ci_node_version..."

        for config_file in \
            "$PROJECT_ROOT/.gitlab-ci.yml" \
            "$PROJECT_ROOT/Jenkinsfile" \
            "$PROJECT_ROOT/.circleci/config.yml" \
            "$PROJECT_ROOT/azure-pipelines.yml" \
            "$PROJECT_ROOT/bitbucket-pipelines.yml"; do

            if [[ -f "$config_file" ]]; then
                # Different files use different syntax
                case "$(basename "$config_file")" in
                    .gitlab-ci.yml)
                        sed -i "s/NODE_VERSION: \"[0-9]*\"/NODE_VERSION: \"$ci_node_version\"/" "$config_file"
                        ;;
                    Jenkinsfile)
                        sed -i "s/NODE_VERSION = '[0-9]*'/NODE_VERSION = '$ci_node_version'/" "$config_file"
                        ;;
                    config.yml)
                        sed -i "s/node:20/node:$ci_node_version/" "$config_file"
                        sed -i "s/cimg\/node:[0-9.]*/cimg\/node:$ci_node_version.0/" "$config_file"
                        ;;
                    azure-pipelines.yml)
                        sed -i "s/nodeVersion: '[0-9.]*x'/nodeVersion: '${ci_node_version}.x'/" "$config_file"
                        ;;
                    bitbucket-pipelines.yml)
                        sed -i "s/image: node:[0-9]*/image: node:$ci_node_version/" "$config_file"
                        ;;
                esac
                ((customized++))
            fi
        done

        log_success "Node.js version updated to $ci_node_version"
    fi

    # Update config with answers
    config_update_from_answers "$ANSWERS_FILE"

    if [[ $customized -gt 0 ]]; then
        log_success "Applied $customized customizations"
    else
        log_info "No customizations applied"
    fi

    return 0
}

# Run customization if answers exist
if [[ -f "$ANSWERS_FILE" ]]; then
    customize_templates
    echo ""
fi

# ===================================================================
# Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location

log_info "Next steps:"
echo ""
echo "  Multiple CI/CD configurations have been created for different platforms:"
echo ""

if [[ -f "$PROJECT_ROOT/.gitlab-ci.yml" ]]; then
    echo "  GitLab CI:"
    echo "    1. Push to GitLab repository"
    echo "    2. Pipeline will run automatically"
    echo "    3. Configure GitLab CI/CD variables in Settings > CI/CD"
    echo ""
fi

if [[ -f "$PROJECT_ROOT/Jenkinsfile" ]]; then
    echo "  Jenkins:"
    echo "    1. Create a Pipeline job in Jenkins"
    echo "    2. Point it to your repository"
    echo "    3. Configure credentials and parameters"
    echo ""
fi

if [[ -f "$PROJECT_ROOT/.circleci/config.yml" ]]; then
    echo "  CircleCI:"
    echo "    1. Connect repository to CircleCI"
    echo "    2. Pipeline will run automatically"
    echo "    3. Configure environment variables in project settings"
    echo ""
fi

if [[ -f "$PROJECT_ROOT/azure-pipelines.yml" ]]; then
    echo "  Azure Pipelines:"
    echo "    1. Create a new pipeline in Azure DevOps"
    echo "    2. Select 'Existing Azure Pipelines YAML file'"
    echo "    3. Configure pipeline variables and service connections"
    echo ""
fi

if [[ -f "$PROJECT_ROOT/bitbucket-pipelines.yml" ]]; then
    echo "  Bitbucket Pipelines:"
    echo "    1. Enable Pipelines in repository settings"
    echo "    2. Pipeline will run automatically on push"
    echo "    3. Configure deployment variables in repository settings"
    echo ""
fi

echo "  General:"
echo "    1. Choose and configure ONE platform that matches your repository host"
echo "    2. Delete unused configuration files"
echo "    3. Update deployment commands for your infrastructure"
echo "    4. Set up required environment variables and secrets"
echo "    5. Test the pipeline with a commit"
echo ""
