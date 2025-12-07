#!/bin/bash

# ===================================================================
# bootstrap-docker.questions.sh
#
# Q&A script for Docker and database configuration
# Asks 4 key questions to customize docker-compose.yml and .env
# ===================================================================

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/validation-common.sh"
source "${SCRIPT_DIR}/lib/config-manager.sh"

# ===================================================================
# Docker Configuration Questions
# ===================================================================

ask_docker_questions() {
    section_header "Docker & Database Configuration"

    show_info "Configuring containerized development environment"
    echo ""

    # Question 1: Database Type
    ask_choice \
        "Database type?" \
        "docker.database_type" \
        "postgres mysql mongodb" \
        1 \
        DATABASE_TYPE

    # Question 2: Database Name
    local default_db_name="${PROJECT_NAME:-app}_dev"
    ask_with_default \
        "Database name?" \
        "docker.database_name" \
        "$default_db_name" \
        DATABASE_NAME

    # Question 3: Application Port
    ask_validated \
        "Application port?" \
        "docker.app_port" \
        "3000" \
        validate_port \
        APP_PORT

    # Question 4: Database Port
    # Set smart default based on database type
    local default_db_port="5432"
    case "${DATABASE_TYPE:-postgres}" in
        mysql) default_db_port="3306" ;;
        mongodb|mongo) default_db_port="27017" ;;
    esac

    ask_validated \
        "Database port?" \
        "docker.database_port" \
        "$default_db_port" \
        validate_port \
        DATABASE_PORT

    echo ""
    show_success "Docker configuration collected"
}

# Run questions if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_answers
    ask_docker_questions
    show_answers_summary
fi
