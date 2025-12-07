#!/bin/bash

# ===================================================================
# bootstrap-packages.questions.sh
#
# Q&A script for package management configuration
# Asks 3 key questions to customize package.json and .nvmrc
# ===================================================================

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/validation-common.sh"
source "${SCRIPT_DIR}/lib/config-manager.sh"

# ===================================================================
# Package Configuration Questions
# ===================================================================

ask_packages_questions() {
    section_header "Package Management Configuration"

    show_info "Configuring Node.js and package manager settings"
    echo ""

    # Question 1: Project Name (for package.json)
    ask_validated \
        "Package name (for package.json)?" \
        "project.name" \
        "$(detect_project_name)" \
        validate_project_name \
        PACKAGE_NAME

    # Question 2: Package Manager
    ask_choice \
        "Package manager?" \
        "packages.package_manager" \
        "pnpm npm yarn" \
        1 \
        PACKAGE_MANAGER

    # Question 3: Node Version
    ask_with_default \
        "Node.js version?" \
        "packages.node_version" \
        "$(detect_node_version)" \
        NODE_VERSION

    echo ""
    show_success "Package configuration collected"
}

# Run questions if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_answers
    ask_packages_questions
    show_answers_summary
fi
