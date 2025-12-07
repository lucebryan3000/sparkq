#!/bin/bash

# ===================================================================
# bootstrap-git.questions.sh
#
# Q&A script for Git configuration
# Asks 3 key questions to customize git settings
# ===================================================================

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/validation-common.sh"
source "${SCRIPT_DIR}/lib/config-manager.sh"

# ===================================================================
# Git Configuration Questions
# ===================================================================

ask_git_questions() {
    section_header "Git Configuration"

    show_info "Configuring Git settings for your project"
    echo ""

    # Question 1: Git User Name
    ask_with_default \
        "Git user name?" \
        "git.user_name" \
        "$(detect_git_user)" \
        GIT_USER_NAME

    # Question 2: Git User Email
    ask_validated \
        "Git user email?" \
        "git.user_email" \
        "$(detect_git_email)" \
        validate_email \
        GIT_USER_EMAIL

    # Question 3: Default Branch
    ask_with_default \
        "Default branch name?" \
        "git.default_branch" \
        "$(detect_git_branch)" \
        GIT_DEFAULT_BRANCH

    echo ""
    show_success "Git configuration collected"
}

# Run questions if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_answers
    ask_git_questions
    show_answers_summary
fi
