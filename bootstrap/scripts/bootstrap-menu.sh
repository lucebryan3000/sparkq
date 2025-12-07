#!/bin/bash

#############################################
# Bootstrap Menu Script (Enhanced)
#
# Lists available bootstrap scripts in
# recommended order and allows interactive
# selection and execution with improved
# error handling and validation
#############################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Source libraries
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Configuration
INTERACTIVE_MODE=false
ANSWERS_FILE=".bootstrap-answers.env"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --interactive|-i)
            INTERACTIVE_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--interactive]"
            echo ""
            echo "Options:"
            echo "  --interactive, -i    Enable interactive mode with Q&A customization"
            echo "  --help, -h           Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Ensure bootstrap.config exists
ensure_config "${BOOTSTRAP_DIR}/config/bootstrap.config" > /dev/null

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREY='\033[90m'
NC='\033[0m' # No Color

# Session tracking
SCRIPTS_RUN=0
SCRIPTS_FAILED=0
SCRIPTS_SKIPPED=0

# Error handling with context
error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Show help
show_help() {
    echo ""
    echo -e "${BLUE}SparkQ Bootstrap Menu - Commands${NC}"
    echo ""
    echo "  1-14        Run the corresponding bootstrap script"
    echo "  h, ?        Show this help message"
    echo "  q, x        Exit the menu"
    echo ""
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ $exit_code -eq 130 ]]; then
        error "Bootstrap menu interrupted by user"
    fi
    return $exit_code
}

trap cleanup EXIT
trap 'echo ""; error "Bootstrap menu interrupted"; exit 130' INT TERM

# Check if scripts directory exists
if [[ ! -d "$SCRIPT_DIR" ]]; then
    error "Scripts directory not found: $SCRIPT_DIR"
    exit 1
fi

# Verify scripts directory is readable
if [[ ! -r "$SCRIPT_DIR" ]]; then
    error "Scripts directory is not readable: $SCRIPT_DIR"
    exit 1
fi

# Get list of existing scripts, excluding bootstrap-menu.sh itself
mapfile -t EXISTING_SCRIPTS < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name "bootstrap-*.sh" ! -name "$SCRIPT_NAME" | sort) || true

# Define all bootstrap scripts in AI-first recommended order
declare -a PHASE1_SCRIPTS=(
    "bootstrap-claude.sh"
    "bootstrap-git.sh"
    "bootstrap-vscode.sh"
    "bootstrap-codex.sh"
    "bootstrap-packages.sh"
    "bootstrap-typescript.sh"
    "bootstrap-environment.sh"
)

declare -a PHASE2_SCRIPTS=(
    "bootstrap-docker.sh"
    "bootstrap-linting.sh"
    "bootstrap-editor.sh"
)

declare -a PHASE3_SCRIPTS=(
    "bootstrap-testing.sh"
)

declare -a PHASE4_SCRIPTS=(
    "bootstrap-github.sh"
    "bootstrap-devcontainer.sh"
    "bootstrap-documentation.sh"
)

# Helper function to check if script exists
script_exists() {
    [[ " ${EXISTING_SCRIPTS[@]:-} " =~ " ${SCRIPT_DIR}/$1 " ]]
}

# Run questions for a bootstrap script if in interactive mode
run_questions() {
    local script_name="$1"

    # Not in interactive mode, skip
    if [[ "$INTERACTIVE_MODE" != "true" ]]; then
        return 0
    fi

    # Determine questions file based on script name
    local base_name="${script_name%.sh}"
    local questions_file="${BOOTSTRAP_DIR}/questions/${base_name}.questions.sh"

    # Check if questions file exists
    if [[ ! -f "$questions_file" ]]; then
        info "No questions configured for $script_name (will use template defaults)"
        return 0
    fi

    echo ""
    info "Interactive customization for $script_name"
    echo ""

    # Initialize answers file
    init_answers "$ANSWERS_FILE"

    # Source and run questions
    if source "$questions_file"; then
        # Questions function should be named ask_{base}_questions
        local questions_func="ask_${base_name#bootstrap-}_questions"

        if declare -f "$questions_func" > /dev/null; then
            $questions_func
            echo ""

            # Show summary and confirm
            if confirm_answers; then
                info "Configuration saved, proceeding with bootstrap..."
                return 0
            else
                warning "Configuration rejected. Skipping customization."
                rm -f "$ANSWERS_FILE"
                return 1
            fi
        else
            warning "Questions function not found: $questions_func"
            return 0
        fi
    else
        error "Failed to source questions file: $questions_file"
        return 1
    fi
}

# Display menu
display_menu() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   SparkQ Bootstrap Menu - AI-First Development Order   ${NC}"
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        echo -e "${GREEN}   Interactive Mode: ENABLED (Q&A customization)   ${NC}"
    else
        echo -e "${GREY}   Interactive Mode: OFF (use --interactive to enable)   ${NC}"
    fi
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""

    declare -A script_map
    local script_counter=1

    # Display PHASE 1: AI Development Toolkit
    echo -e "${RED}🔴 PHASE 1: AI Development Toolkit (FIRST)${NC}"
    echo -e "${RED}────────────────────────────────────────────${NC}"
    for script in "${PHASE1_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            script_map[$script_counter]="${SCRIPT_DIR}/$script"
            echo -e "  ${GREEN}$script_counter.${NC} $script"
            ((script_counter++))
        else
            echo -e "  ${GREY}$script_counter.${NC} ${GREY}$script (coming soon)${NC}"
            ((script_counter++))
        fi
    done

    echo ""

    # Display PHASE 2: Infrastructure
    echo -e "${RED}🔴 PHASE 2: Infrastructure (Core Development)${NC}"
    echo -e "${RED}────────────────────────────────────────────${NC}"
    for script in "${PHASE2_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            script_map[$script_counter]="${SCRIPT_DIR}/$script"
            echo -e "  ${GREEN}$script_counter.${NC} $script"
            ((script_counter++))
        else
            echo -e "  ${GREY}$script_counter.${NC} ${GREY}$script (coming soon)${NC}"
            ((script_counter++))
        fi
    done

    echo ""

    # Display PHASE 3: Testing & Quality
    echo -e "${YELLOW}🟡 PHASE 3: Testing & Quality${NC}"
    echo -e "${YELLOW}────────────────────────────────${NC}"
    for script in "${PHASE3_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            script_map[$script_counter]="${SCRIPT_DIR}/$script"
            echo -e "  ${GREEN}$script_counter.${NC} $script"
            ((script_counter++))
        else
            echo -e "  ${GREY}$script_counter.${NC} ${GREY}$script (coming soon)${NC}"
            ((script_counter++))
        fi
    done

    echo ""

    # Display PHASE 4: CI/CD & Deployment
    echo -e "${GREEN}🟢 PHASE 4: CI/CD & Deployment (Optional)${NC}"
    echo -e "${GREEN}──────────────────────────────────────────${NC}"
    for script in "${PHASE4_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            script_map[$script_counter]="${SCRIPT_DIR}/$script"
            echo -e "  ${GREEN}$script_counter.${NC} $script"
            ((script_counter++))
        else
            echo -e "  ${GREY}$script_counter.${NC} ${GREY}$script (coming soon)${NC}"
            ((script_counter++))
        fi
    done

    echo ""
    echo -e "${YELLOW}Commands: (1-14) Run script | (h) Help | (q/x) Exit${NC}"
    echo ""
}

# Calculate total number of scripts
total_scripts=$((${#PHASE1_SCRIPTS[@]} + ${#PHASE2_SCRIPTS[@]} + ${#PHASE3_SCRIPTS[@]} + ${#PHASE4_SCRIPTS[@]}))

# Store script_map globally for access outside function
declare -gA SCRIPT_MAP

# Rebuild script_map
rebuild_script_map() {
    SCRIPT_MAP=()
    local script_counter=1

    for script in "${PHASE1_SCRIPTS[@]}" "${PHASE2_SCRIPTS[@]}" "${PHASE3_SCRIPTS[@]}" "${PHASE4_SCRIPTS[@]}"; do
        if script_exists "$script"; then
            SCRIPT_MAP[$script_counter]="${SCRIPT_DIR}/$script"
        fi
        ((script_counter++))
    done
}

rebuild_script_map
display_menu

# Menu loop
while true; do
    read -p "Enter selection (1-$total_scripts, h for help, q to quit): " -r choice || {
        error "Failed to read input"
        continue
    }

    # Handle empty input
    if [[ -z "$choice" ]]; then
        warning "No selection made. Enter a number (1-$total_scripts), 'h' for help, or 'q' to quit"
        continue
    fi

    # Handle help command
    if [[ "$choice" =~ ^[hH?]$ ]]; then
        show_help
        continue
    fi

    # Check for exit commands
    if [[ "$choice" =~ ^[qQxX]$ ]]; then
        info "Exiting menu"
        if [[ $SCRIPTS_RUN -gt 0 ]]; then
            echo ""
            echo -e "${BLUE}Session Summary:${NC}"
            echo "  Scripts run:      $SCRIPTS_RUN"
            echo "  Scripts skipped:  $SCRIPTS_SKIPPED"
            echo "  Scripts failed:   $SCRIPTS_FAILED"
        fi
        echo ""
        exit 0
    fi

    # Validate numeric input
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        error "Invalid input: '$choice'. Enter a number (1-$total_scripts), 'h' for help, or 'q' to quit"
        continue
    fi

    # Check if number is in valid range
    if (( choice < 1 || choice > total_scripts )); then
        error "Invalid number: $choice. Please choose between 1 and $total_scripts"
        continue
    fi

    # Check if script exists
    if [[ ! -v SCRIPT_MAP[$choice] ]]; then
        warning "Script #$choice is coming soon and not yet available"
        echo ""
        continue
    fi

    # Get selected script
    selected_script="${SCRIPT_MAP[$choice]}"
    selected_name=$(basename "$selected_script")

    # Verify script is readable and executable
    if [[ ! -r "$selected_script" ]]; then
        error "Script is not readable: $selected_name"
        continue
    fi

    # Confirm before running
    echo ""
    echo -e "${BLUE}Selected: ${GREEN}$selected_name${NC}"
    read -p "Run this script? (Y/n): " -r confirm || {
        error "Failed to read input"
        continue
    }
    confirm="${confirm:-Y}" # Default to Y if empty

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo ""

        # Run interactive Q&A if enabled
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            if ! run_questions "$selected_name"; then
                warning "Skipping $selected_name due to configuration rejection"
                ((SCRIPTS_SKIPPED++))
                echo ""
                continue
            fi
        fi

        info "Running $selected_name..."
        echo ""

        # Check if script is executable
        if [[ ! -x "$selected_script" ]]; then
            warning "Script is not executable, attempting to make it executable..."
            if ! chmod +x "$selected_script"; then
                error "Failed to make script executable: $selected_name"
                ((SCRIPTS_FAILED++))
                # Clean up answers file on error
                [[ -f "$ANSWERS_FILE" ]] && rm -f "$ANSWERS_FILE"
                echo ""
                continue
            fi
        fi

        # Run the script with error handling
        if bash "$selected_script"; then
            success "$selected_name completed successfully"
            ((SCRIPTS_RUN++))

            # Clean up answers file after successful run
            if [[ -f "$ANSWERS_FILE" ]]; then
                rm -f "$ANSWERS_FILE"
                info "Cleaned up temporary configuration"
            fi
        else
            exit_code=$?
            error "$selected_name failed with exit code $exit_code"
            warning "Review the output above for details on what went wrong"
            ((SCRIPTS_FAILED++))

            # Clean up answers file on error
            [[ -f "$ANSWERS_FILE" ]] && rm -f "$ANSWERS_FILE"
        fi

        echo ""
        read -p "Continue to menu? (Y/n): " -r menu_continue || {
            error "Failed to read input"
            continue
        }
        menu_continue="${menu_continue:-Y}"

        if [[ ! "$menu_continue" =~ ^[Yy]$ ]]; then
            info "Exiting menu"
            if [[ $SCRIPTS_RUN -gt 0 ]]; then
                echo ""
                echo -e "${BLUE}Session Summary:${NC}"
                echo "  Scripts run:      $SCRIPTS_RUN"
                echo "  Scripts skipped:  $SCRIPTS_SKIPPED"
                echo "  Scripts failed:   $SCRIPTS_FAILED"
            fi
            echo ""
            exit 0
        fi

        display_menu
    elif [[ "$confirm" =~ ^[Nn]$ ]]; then
        info "Skipped $selected_name"
        ((SCRIPTS_SKIPPED++))
        echo ""
    else
        error "Invalid input. Please enter 'Y' to run or 'N' to skip"
        echo ""
    fi
done
