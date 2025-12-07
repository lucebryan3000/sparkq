#!/bin/bash

# ===================================================================
# bootstrap-claude.questions.sh
#
# Q&A script for Claude AI configuration
# Asks 4 key questions to customize CLAUDE.md and .claude/ settings
# ===================================================================

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/validation-common.sh"
source "${SCRIPT_DIR}/lib/config-manager.sh"

# ===================================================================
# Claude Configuration Questions
# ===================================================================

ask_claude_questions() {
    section_header "Claude AI Configuration"

    show_info "Configuring Claude AI integration for your project"
    echo ""

    # Question 1: Project Name
    ask_with_default \
        "Project name?" \
        "project.name" \
        "$(detect_project_name)" \
        PROJECT_NAME

    # Question 2: Project Phase
    ask_choice \
        "Project phase?" \
        "project.phase" \
        "POC MVP Production" \
        1 \
        PROJECT_PHASE

    # Question 3: Enable Codex
    ask_yes_no \
        "Enable Codex (AI-powered context system)?" \
        "claude.enable_codex" \
        "Y" \
        ENABLE_CODEX

    # Question 4: AI Model
    ask_choice \
        "Default AI model?" \
        "claude.ai_model" \
        "sonnet haiku opus" \
        1 \
        AI_MODEL

    echo ""
    show_success "Claude configuration collected"
}

# Run questions if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_answers
    ask_claude_questions
    show_answers_summary
fi
