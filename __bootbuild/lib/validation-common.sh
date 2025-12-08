#!/bin/bash

# ===================================================================
# validation-common.sh
#
# Shared Q&A and validation functions for bootstrap system
# Integrates with bootstrap.config for smart defaults
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_VALIDATION_COMMON_LOADED:-}" ]] && return 0
_BOOTSTRAP_VALIDATION_COMMON_LOADED=1

# Source config manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config-manager.sh"

# Answers file location
ANSWERS_FILE="${ANSWERS_FILE:-.bootstrap-answers.env}"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ===================================================================
# Answer File Management
# ===================================================================

# ===================================================================
# Function: init_answers
#
# Description: Initialize a new answers file with headers and metadata
#
# Usage: init_answers [answers_file]
#
# Arguments:
#   $1 - answers file path (optional, defaults to $ANSWERS_FILE)
#
# Returns:
#   0 - success
#   1 - failure writing file
#
# Example:
#   init_answers ".bootstrap-answers.env"
# ===================================================================
init_answers() {
    local answers_file="${1:-$ANSWERS_FILE}"

    > "$answers_file"
    echo "# Bootstrap customization answers" >> "$answers_file"
    echo "# Generated: $(date)" >> "$answers_file"
    echo "" >> "$answers_file"
}

# ===================================================================
# Function: save_answer
#
# Description: Append a variable assignment to the answers file
#
# Usage: save_answer <variable_name> <value> [answers_file]
#
# Arguments:
#   $1 - variable name to save
#   $2 - value to assign
#   $3 - answers file path (optional, defaults to $ANSWERS_FILE)
#
# Returns:
#   0 - success
#   1 - failure writing file
#
# Example:
#   save_answer "PROJECT_NAME" "my-app"
# ===================================================================
save_answer() {
    local var_name="$1"
    local value="$2"
    local answers_file="${3:-$ANSWERS_FILE}"

    echo "${var_name}=\"${value}\"" >> "$answers_file"
}

# ===================================================================
# Question Functions
# ===================================================================

# ===================================================================
# Function: ask_with_default
#
# Description: Prompt user for input with a default value from config
#
# Usage: ask_with_default <question> <config_key> <fallback_default> <var_name>
#
# Arguments:
#   $1 - question text to display
#   $2 - config key to check for default (format: section.key)
#   $3 - fallback default if config key not found
#   $4 - variable name to export result to
#
# Returns:
#   0 - success
#   1 - failure
#
# Example:
#   ask_with_default "Project name?" "project.name" "my-app" PROJECT_NAME
# ===================================================================
ask_with_default() {
    local question="$1"
    local config_key="$2"
    local fallback_default="$3"
    local var_name="$4"
    local response

    # Try to get default from config, fall back to provided default
    local default=$(config_get "$config_key" "$fallback_default")

    echo -e -n "${BLUE}→${NC} $question ${YELLOW}[$default]${NC}: "
    read -r response
    response="${response:-$default}"

    # Export and save
    export "$var_name=$response"
    save_answer "$var_name" "$response"
}

# ===================================================================
# Function: ask_yes_no
#
# Description: Prompt user for yes/no answer, converts Y/N to true/false
#
# Usage: ask_yes_no <question> <config_key> <fallback_default> <var_name>
#
# Arguments:
#   $1 - question text (should indicate Y/n format)
#   $2 - config key for default value
#   $3 - fallback default (Y or N)
#   $4 - variable name to export result to
#
# Returns:
#   0 - success (true exported if Y selected)
#   1 - failure
#
# Notes:
#   - Exports "true" or "false" to variable (not Y/N)
#   - Default case-insensitive (y/Y/n/N accepted)
#
# Example:
#   ask_yes_no "Enable Docker?" "docker.enabled" "Y" DOCKER_ENABLED
# ===================================================================
ask_yes_no() {
    local question="$1"
    local config_key="$2"
    local fallback_default="$3"
    local var_name="$4"
    local response

    # Try to get default from config
    local config_value=$(config_get "$config_key" "")
    local default="$fallback_default"

    # Convert config true/false to Y/N
    if [[ "$config_value" == "true" ]]; then
        default="Y"
    elif [[ "$config_value" == "false" ]]; then
        default="N"
    fi

    echo -e -n "${BLUE}→${NC} $question (Y/n) ${YELLOW}[$default]${NC}: "
    read -r response
    response="${response:-$default}"

    if [[ "$response" =~ ^[Yy]$ ]]; then
        export "$var_name=true"
        save_answer "$var_name" "true"
    else
        export "$var_name=false"
        save_answer "$var_name" "false"
    fi
}

# ===================================================================
# Function: ask_choice
#
# Description: Display numbered menu and prompt user to select an option
#
# Usage: ask_choice <question> <config_key> <options> <default_index> <var_name>
#
# Arguments:
#   $1 - question text to display
#   $2 - config key for default selection
#   $3 - space-separated list of options
#   $4 - default selection index (1-based)
#   $5 - variable name to export selected option to
#
# Returns:
#   0 - success
#   1 - invalid choice (uses default)
#
# Notes:
#   - Displays options numbered 1..N with * marking default
#   - Invalid numeric input automatically uses default
#   - Exports actual option value, not index
#
# Example:
#   ask_choice "Select DB" "docker.database_type" "postgres mysql mongodb" 1 DB_TYPE
# ===================================================================
ask_choice() {
    local question="$1"
    local config_key="$2"
    local options="$3"
    local fallback_default_idx="$4"
    local var_name="$5"
    local response

    # Try to get default from config
    local config_value=$(config_get "$config_key" "")

    # Convert options to array
    local -a opts=($options)
    local default_idx="$fallback_default_idx"

    # If config has a value, find its index
    if [[ -n "$config_value" ]]; then
        for i in "${!opts[@]}"; do
            if [[ "${opts[$i]}" == "$config_value" ]]; then
                default_idx=$((i+1))
                break
            fi
        done
    fi

    echo -e "${BLUE}→${NC} $question"
    for i in "${!opts[@]}"; do
        local marker=" "
        [[ $((i+1)) -eq $default_idx ]] && marker="${GREEN}*${NC}"
        echo -e "  $marker $((i+1)). ${opts[$i]}"
    done

    echo -e -n "${BLUE}→${NC} Choice ${YELLOW}[$default_idx]${NC}: "
    read -r response
    response="${response:-$default_idx}"

    # Validate numeric input
    if ! [[ "$response" =~ ^[0-9]+$ ]] || [[ $response -lt 1 ]] || [[ $response -gt ${#opts[@]} ]]; then
        echo -e "${RED}✗${NC} Invalid choice, using default: ${opts[$((default_idx-1))]}"
        response="$default_idx"
    fi

    local selected="${opts[$((response-1))]}"
    export "$var_name=$selected"
    save_answer "$var_name" "$selected"

    echo -e "${GREEN}✓${NC} Selected: $selected"
}

# ===================================================================
# Function: ask_validated
#
# Description: Prompt for input and validate using a validator function
#
# Usage: ask_validated <question> <config_key> <fallback_default> <validator_func> <var_name>
#
# Arguments:
#   $1 - question text to display
#   $2 - config key for default value
#   $3 - fallback default value
#   $4 - validator function name (e.g., validate_email)
#   $5 - variable name to export result to
#
# Returns:
#   0 - success (input validated)
#   1 - validation failed
#
# Notes:
#   - Loops until input passes validation
#   - Validator function should return 0 for valid, non-0 for invalid
#   - If validator function not found, accepts any input
#
# Example:
#   ask_validated "Email?" "contact.email" "user@example.com" validate_email EMAIL
# ===================================================================
ask_validated() {
    local question="$1"
    local config_key="$2"
    local fallback_default="$3"
    local validator_func="$4"
    local var_name="$5"
    local response
    local valid=false

    # Try to get default from config
    local default=$(config_get "$config_key" "$fallback_default")

    while [[ "$valid" == "false" ]]; do
        echo -e -n "${BLUE}→${NC} $question ${YELLOW}[$default]${NC}: "
        read -r response
        response="${response:-$default}"

        # Run validator function if provided
        if [[ -n "$validator_func" ]] && declare -f "$validator_func" > /dev/null; then
            if $validator_func "$response"; then
                valid=true
            else
                echo -e "${RED}✗${NC} Invalid input. Please try again."
            fi
        else
            valid=true
        fi
    done

    export "$var_name=$response"
    save_answer "$var_name" "$response"
}

# ===================================================================
# Common Validators
# ===================================================================

# ===================================================================
# Function: validate_email
#
# Description: Validate email address format
#
# Usage: validate_email <email>
#
# Arguments:
#   $1 - email address to validate
#
# Returns:
#   0 - valid email format
#   1 - invalid email format
#
# Example:
#   validate_email "user@example.com"
# ===================================================================
validate_email() {
    local email="$1"
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# ===================================================================
# Function: validate_port
#
# Description: Validate port number is in valid range
#
# Usage: validate_port <port>
#
# Arguments:
#   $1 - port number to validate
#
# Returns:
#   0 - valid port (1-65535)
#   1 - invalid port
#
# Example:
#   validate_port 3000
# ===================================================================
validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]
}

# ===================================================================
# Function: validate_project_name
#
# Description: Validate project name contains only alphanumeric, hyphens, underscores
#
# Usage: validate_project_name <name>
#
# Arguments:
#   $1 - project name to validate
#
# Returns:
#   0 - valid project name
#   1 - invalid project name
#
# Example:
#   validate_project_name "my-project_v1"
# ===================================================================
validate_project_name() {
    local name="$1"
    [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]
}

# ===================================================================
# Function: validate_directory
#
# Description: Check if directory exists and is accessible
#
# Usage: validate_directory <path>
#
# Arguments:
#   $1 - directory path to validate
#
# Returns:
#   0 - directory exists
#   1 - directory does not exist
#
# Example:
#   validate_directory "/home/user/project"
# ===================================================================
validate_directory() {
    local dir="$1"
    [[ -d "$dir" ]]
}

# ===================================================================
# Function: validate_file
#
# Description: Check if file exists and is readable
#
# Usage: validate_file <path>
#
# Arguments:
#   $1 - file path to validate
#
# Returns:
#   0 - file exists
#   1 - file does not exist
#
# Example:
#   validate_file "config.json"
# ===================================================================
validate_file() {
    local file="$1"
    [[ -f "$file" ]]
}

# ===================================================================
# Display Helpers
# ===================================================================

# ===================================================================
# Function: section_header
#
# Description: Display a formatted section header with border
#
# Usage: section_header <title>
#
# Arguments:
#   $1 - section title text
#
# Returns:
#   0 - always
#
# Example:
#   section_header "Configuration"
# ===================================================================
section_header() {
    local title="$1"
    local width=60

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   $title${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# ===================================================================
# Function: show_success
#
# Description: Display a success message with green checkmark
#
# Usage: show_success <message>
#
# Arguments:
#   $1 - message text to display
#
# Returns:
#   0 - always
#
# Example:
#   show_success "Configuration saved"
# ===================================================================
show_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
}

# ===================================================================
# Function: show_error
#
# Description: Display an error message with red X
#
# Usage: show_error <message>
#
# Arguments:
#   $1 - error message text to display
#
# Returns:
#   0 - always
#
# Example:
#   show_error "Failed to save configuration"
# ===================================================================
show_error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message"
}

# ===================================================================
# Function: show_warning
#
# Description: Display a warning message with yellow caution symbol
#
# Usage: show_warning <message>
#
# Arguments:
#   $1 - warning message text to display
#
# Returns:
#   0 - always
#
# Example:
#   show_warning "This action cannot be undone"
# ===================================================================
show_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} $message"
}

# ===================================================================
# Function: show_info
#
# Description: Display an info message with blue arrow prefix
#
# Usage: show_info <message>
#
# Arguments:
#   $1 - info message text to display
#
# Returns:
#   0 - always
#
# Example:
#   show_info "Processing configuration"
# ===================================================================
show_info() {
    local message="$1"
    echo -e "${BLUE}→${NC} $message"
}

# ===================================================================
# Summary Display
# ===================================================================

# ===================================================================
# Function: show_answers_summary
#
# Description: Display formatted summary of all collected answers
#
# Usage: show_answers_summary [answers_file]
#
# Arguments:
#   $1 - answers file path (optional, defaults to $ANSWERS_FILE)
#
# Returns:
#   0 - summary displayed
#   1 - answers file not found
#
# Notes:
#   - Automatically formats keys from UPPER_CASE to Title Case
#   - Removes surrounding quotes from values
#   - Displays under "Configuration Summary" header
#
# Example:
#   show_answers_summary ".bootstrap-answers.env"
# ===================================================================
show_answers_summary() {
    local answers_file="${1:-$ANSWERS_FILE}"

    if [[ ! -f "$answers_file" ]]; then
        echo -e "${RED}✗${NC} [ValidationCommon] Answers file not found: $answers_file" >&2
        return 1
    fi

    section_header "Configuration Summary"

    # Source answers and display
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Remove quotes from value
        value=$(echo "$value" | sed 's/^"//;s/"$//')

        # Format key for display
        local display_key=$(echo "$key" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

        printf "  ${BLUE}%-30s${NC} : %s\n" "$display_key" "$value"
    done < "$answers_file"

    echo ""
}

# ===================================================================
# Function: confirm_answers
#
# Description: Show summary and prompt user to confirm before proceeding
#
# Usage: confirm_answers
#
# Arguments:
#   (none)
#
# Returns:
#   0 - user confirmed (Y/yes)
#   1 - user declined (N/no)
#
# Notes:
#   - Shows full answers summary before prompt
#   - Default is Yes if user just presses enter
#   - Case-insensitive (y/Y/n/N accepted)
#
# Example:
#   confirm_answers && echo "User confirmed" || echo "User cancelled"
# ===================================================================
confirm_answers() {
    local response

    show_answers_summary

    echo -e -n "${YELLOW}→${NC} Proceed with these settings? (Y/n) ${YELLOW}[Y]${NC}: "
    read -r response
    response="${response:-Y}"

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}


# ===================================================================
# Function: validate_answer (NEW - added for robustness)
#
# Description: Validate and save an answer to the answers file with safety checks
#
# Usage: validate_answer var_name value [answers_file]
#
# Arguments:
#   $1 - variable name
#   $2 - value to save
#   $3 - answers file path (optional)
#
# Returns:
#   0 - success
#   1 - validation failure
# ===================================================================
validate_answer() {
    local var_name="$1"
    local value="$2"
    local answers_file="${3:-$ANSWERS_FILE}"

    # Validate variable name is not empty
    [[ -z "$var_name" ]] && { echo "ERROR: [ValidationCommon] validate_answer: Variable name required" >&2; return 1; }

    # Validate value is provided (allow empty string)
    [[ $# -lt 2 ]] && { echo "ERROR: [ValidationCommon] validate_answer: Value required" >&2; return 1; }

    # Validate answers file path
    [[ -z "$answers_file" ]] && { echo "ERROR: [ValidationCommon] validate_answer: Answers file path required" >&2; return 1; }

    # Validate directory is writable
    local answers_dir=$(dirname "$answers_file")
    [[ ! -d "$answers_dir" ]] && { echo "ERROR: [ValidationCommon] validate_answer: Answers directory does not exist: $answers_dir" >&2; return 1; }
    [[ ! -w "$answers_dir" ]] && { echo "ERROR: [ValidationCommon] validate_answer: Answers directory not writable: $answers_dir" >&2; return 1; }

    # If file exists, check it's writable
    if [[ -f "$answers_file" ]]; then
        [[ ! -w "$answers_file" ]] && { echo "ERROR: [ValidationCommon] validate_answer: Answers file not writable: $answers_file" >&2; return 1; }
    fi

    # Write answer
    if echo "${var_name}=\"${value}\"" >> "$answers_file"; then
        return 0
    else
        echo "ERROR: [ValidationCommon] validate_answer: Failed to write to answers file" >&2
        return 1
    fi
}
