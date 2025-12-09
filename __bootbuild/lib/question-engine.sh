#!/bin/bash

# ===================================================================
# lib/question-engine.sh
#
# Interactive Q&A engine for bootstrap scripts.
# Reads questions from bootstrap-questions.json and writes answers
# directly to bootstrap.config.
#
# USAGE:
#   source "${LIB_DIR}/question-engine.sh"
#
#   # Run questions for a script
#   question_engine_run "docker"
#
#   # Check if questions exist
#   question_engine_has_questions "docker" && echo "yes"
#
# REQUIRES:
#   - jq (for JSON parsing)
#   - config-manager.sh (for config writes)
#   - BOOTSTRAP_DIR, MANIFEST_FILE set
# ===================================================================

# Prevent double-sourcing
[[ -n "${_QUESTION_ENGINE_LOADED:-}" ]] && return 0
_QUESTION_ENGINE_LOADED=1

# ===================================================================
# Question Cache
# ===================================================================

# In-memory cache for parsed questions (Bash 4+)
if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    declare -A _QUESTIONS_JSON_CACHE
    declare -A _SCRIPT_QUESTIONS_CACHE
    _QUESTIONS_CACHE_ENABLED=true
else
    _QUESTIONS_CACHE_ENABLED=false
fi

# Cache for questions file content
_QUESTIONS_FILE_CACHE=""
_QUESTIONS_FILE_MTIME=""

# Get cached questions file content
_get_questions_json() {
    local questions_file="${QUESTIONS_FILE:-}"
    [[ -z "$questions_file" || ! -f "$questions_file" ]] && return 1

    # Check if file has changed
    local current_mtime=""
    if [[ -f "$questions_file" ]]; then
        current_mtime=$(stat -c %Y "$questions_file" 2>/dev/null || stat -f %m "$questions_file" 2>/dev/null || echo "0")
    fi

    # Return cached version if still valid
    if [[ -n "$_QUESTIONS_FILE_CACHE" && "$_QUESTIONS_FILE_MTIME" == "$current_mtime" ]]; then
        echo "$_QUESTIONS_FILE_CACHE"
        return 0
    fi

    # Cache miss or stale - read and cache
    if [[ -f "$questions_file" ]]; then
        _QUESTIONS_FILE_CACHE=$(cat "$questions_file")
        _QUESTIONS_FILE_MTIME="$current_mtime"
        echo "$_QUESTIONS_FILE_CACHE"
        return 0
    fi

    return 1
}

# Clear questions cache
_clear_questions_cache() {
    _QUESTIONS_FILE_CACHE=""
    _QUESTIONS_FILE_MTIME=""
    if [[ "$_QUESTIONS_CACHE_ENABLED" == "true" ]]; then
        _QUESTIONS_JSON_CACHE=()
        _SCRIPT_QUESTIONS_CACHE=()
    fi
}

# ===================================================================
# Configuration
# ===================================================================

# Get questions file path from manifest or default
_get_questions_file() {
    if [[ -n "${MANIFEST_FILE:-}" && -f "$MANIFEST_FILE" ]]; then
        local questions_path=$(jq -r '.paths.QUESTIONS_FILE // "config/bootstrap-questions.json"' "$MANIFEST_FILE" 2>/dev/null)
        echo "${BOOTSTRAP_DIR}/${questions_path}"
    else
        echo "${BOOTSTRAP_DIR}/config/bootstrap-questions.json"
    fi
}

# Initialize questions file path (lazy initialization)
_init_questions_file() {
    if [[ -z "${QUESTIONS_FILE:-}" ]]; then
        QUESTIONS_FILE="$(_get_questions_file)"
    fi

    # Validate questions file exists
    if [[ ! -f "$QUESTIONS_FILE" ]]; then
        log_warning "Questions file not found: $QUESTIONS_FILE"
        _QUESTION_ENGINE_DISABLED=true
        return 1
    fi
    return 0
}

# ===================================================================
# Query Functions (script_mappings aware)
# ===================================================================

# Get mapped question keys for a script from script_mappings
# Returns: list of question keys like "quick_start" or "packages.package_manager"
# Usage: keys=$(_get_script_question_keys "docker")
_get_script_question_keys() {
    local script_key="$1"
    local script_lookup="bootstrap-${script_key}"

    # Check cache first
    if [[ "$_QUESTIONS_CACHE_ENABLED" == "true" ]]; then
        if [[ -n "${_SCRIPT_QUESTIONS_CACHE[$script_lookup]:-}" ]]; then
            echo "${_SCRIPT_QUESTIONS_CACHE[$script_lookup]}"
            return 0
        fi
    fi

    # Query and cache result
    local questions_json=$(_get_questions_json) || return 1
    local result=$(echo "$questions_json" | jq -r ".script_mappings.mappings.\"$script_lookup\" // [] | .[]" 2>/dev/null)

    # Cache the result
    if [[ "$_QUESTIONS_CACHE_ENABLED" == "true" ]]; then
        _SCRIPT_QUESTIONS_CACHE[$script_lookup]="$result"
    fi

    echo "$result"
}

# Resolve a question key to actual question(s)
# Handles both section references ("quick_start") and direct keys ("packages.package_manager")
# Usage: _get_questions_for_key "quick_start"
_get_questions_for_key() {
    local key="$1"

    # Check cache first
    if [[ "$_QUESTIONS_CACHE_ENABLED" == "true" ]]; then
        if [[ -n "${_QUESTIONS_JSON_CACHE[$key]:-}" ]]; then
            echo "${_QUESTIONS_JSON_CACHE[$key]}"
            return 0
        fi
    fi

    # Get questions JSON
    local questions_json=$(_get_questions_json) || { echo "[]"; return 1; }

    # Check if it's a section (like "quick_start", "technology_choices")
    local section_questions=$(echo "$questions_json" | jq -c ".\"$key\".questions // null" 2>/dev/null)

    local result=""
    if [[ "$section_questions" != "null" && -n "$section_questions" ]]; then
        # It's a section - return all questions from it
        result="$section_questions"
    else
        # It's a direct key - find the question in any section
        local found=$(echo "$questions_json" | jq -c "
            .quick_start.questions[]? // empty | select(.key == \"$key\"),
            .technology_choices.questions[]? // empty | select(.key == \"$key\"),
            .advanced.questions[]? // empty | select(.key == \"$key\")
        " 2>/dev/null | head -1)

        if [[ -n "$found" ]]; then
            result="[$found]"
        else
            result="[]"
        fi
    fi

    # Cache the result
    if [[ "$_QUESTIONS_CACHE_ENABLED" == "true" ]]; then
        _QUESTIONS_JSON_CACHE[$key]="$result"
    fi

    echo "$result"
}

# Check if questions exist for a script
# Usage: question_engine_has_questions "docker" && echo "yes"
question_engine_has_questions() {
    _init_questions_file || return 1
    [[ "${_QUESTION_ENGINE_DISABLED:-}" == "true" ]] && return 1

    local script_key="$1"
    local keys=$(_get_script_question_keys "$script_key")

    # Check if any keys mapped
    [[ -n "$keys" ]]
}

# Get question count for a script
# Usage: count=$(question_engine_count "docker")
question_engine_count() {
    _init_questions_file || { echo 0; return; }
    [[ "${_QUESTION_ENGINE_DISABLED:-}" == "true" ]] && { echo 0; return; }

    local script_key="$1"
    local keys=$(_get_script_question_keys "$script_key")
    local count=0

    for key in $keys; do
        local q_json=$(_get_questions_for_key "$key")
        local key_count=$(echo "$q_json" | jq 'length' 2>/dev/null || echo 0)
        count=$((count + key_count))
    done

    echo "$count"
}

# Get script description from manifest (not questions file)
# Usage: desc=$(question_engine_get_description "docker")
question_engine_get_description() {
    _init_questions_file || return
    local script_key="$1"

    # Get from manifest instead
    if [[ -n "${MANIFEST_FILE:-}" && -f "$MANIFEST_FILE" ]]; then
        jq -r ".scripts.\"$script_key\".description // empty" "$MANIFEST_FILE" 2>/dev/null
    fi
}

# ===================================================================
# Variable Substitution
# ===================================================================

# Expand variables in default values
# Supports: ${section.key}, ${ENV_VAR}
_expand_default() {
    local value="$1"

    # No expansion needed
    [[ ! "$value" =~ \$\{ ]] && echo "$value" && return

    # Extract variable reference
    local var_ref=$(echo "$value" | sed -n 's/.*\${\([^}]*\)}.*/\1/p')

    if [[ -z "$var_ref" ]]; then
        echo "$value"
        return
    fi

    local resolved=""

    # Check if it's a config key (contains .)
    if [[ "$var_ref" == *.* ]]; then
        resolved=$(config_get "$var_ref" "" "$BOOTSTRAP_CONFIG" 2>/dev/null)
    else
        # Environment variable
        resolved="${!var_ref:-}"
    fi

    # Substitute and return
    echo "${value//\$\{$var_ref\}/$resolved}"
}

# ===================================================================
# Input Prompting
# ===================================================================

# Prompt for text input
# Usage: _prompt_text "Project name?" "default_value" RESULT_VAR
_prompt_text() {
    local prompt="$1"
    local default="$2"
    local result_var="$3"
    local required="${4:-false}"

    local expanded_default=$(_expand_default "$default")
    local display_default=""
    [[ -n "$expanded_default" ]] && display_default=" [$expanded_default]"

    while true; do
        echo -e -n "${BLUE}→${NC} ${prompt}${display_default}: "
        read -r response
        response="${response:-$expanded_default}"

        if [[ "$required" == "true" && -z "$response" ]]; then
            log_warning "This field is required"
            continue
        fi

        eval "$result_var=\"\$response\""
        return 0
    done
}

# Prompt for yes/no
# Usage: _prompt_yesno "Enable feature?" true RESULT_VAR
_prompt_yesno() {
    local prompt="$1"
    local default="$2"
    local result_var="$3"

    local yn_prompt="(y/N)"
    local default_char="n"
    if [[ "$default" == "true" || "$default" == "Y" || "$default" == "yes" ]]; then
        yn_prompt="(Y/n)"
        default_char="y"
    fi

    echo -e -n "${BLUE}→${NC} ${prompt} ${yn_prompt}: "
    read -r response
    response="${response:-$default_char}"

    if [[ "$response" =~ ^[Yy] ]]; then
        eval "$result_var=true"
    else
        eval "$result_var=false"
    fi
}

# Prompt for choice selection
# Usage: _prompt_choice "Select option?" "opt1 opt2 opt3" "opt1" RESULT_VAR
_prompt_choice() {
    local prompt="$1"
    local options_json="$2"
    local default="$3"
    local result_var="$4"

    # Parse JSON array to bash array
    local -a options=()
    while IFS= read -r opt; do
        options+=("$opt")
    done < <(echo "$options_json" | jq -r '.[]' 2>/dev/null)

    # Find default index
    local default_idx=1
    for i in "${!options[@]}"; do
        if [[ "${options[$i]}" == "$default" ]]; then
            default_idx=$((i + 1))
            break
        fi
    done

    echo -e "${BLUE}→${NC} ${prompt}"
    for i in "${!options[@]}"; do
        local marker=" "
        [[ "${options[$i]}" == "$default" ]] && marker="*"
        echo "  $marker$((i + 1)). ${options[$i]}"
    done

    echo -e -n "  Select [${default_idx}]: "
    read -r response
    response="${response:-$default_idx}"

    # Validate and get selection
    if [[ "$response" =~ ^[0-9]+$ ]] && (( response >= 1 && response <= ${#options[@]} )); then
        eval "$result_var=\"\${options[$((response - 1))]}\""
    else
        # Try matching by name
        for opt in "${options[@]}"; do
            if [[ "$opt" == "$response" ]]; then
                eval "$result_var=\"\$opt\""
                return 0
            fi
        done
        # Fall back to default
        eval "$result_var=\"\$default\""
    fi
}

# Prompt for number
# Usage: _prompt_number "Port?" 3000 1024 65535 RESULT_VAR
_prompt_number() {
    local prompt="$1"
    local default="$2"
    local min="${3:-0}"
    local max="${4:-999999}"
    local result_var="$5"

    while true; do
        echo -e -n "${BLUE}→${NC} ${prompt} [$default]: "
        read -r response
        response="${response:-$default}"

        if [[ "$response" =~ ^[0-9]+$ ]]; then
            if (( response >= min && response <= max )); then
                eval "$result_var=$response"
                return 0
            else
                log_warning "Must be between $min and $max"
            fi
        else
            log_warning "Must be a number"
        fi
    done
}

# ===================================================================
# Main Engine
# ===================================================================

# Process a single question JSON object
# Usage: _process_question "$q_json" session_answers
_process_question() {
    local q_json="$1"
    local -n _answers=$2

    # Parse question fields
    local q_key=$(echo "$q_json" | jq -r '.key')
    local q_prompt=$(echo "$q_json" | jq -r '.prompt')
    local q_type=$(echo "$q_json" | jq -r '.type')
    local q_default=$(echo "$q_json" | jq -r '.default // empty')
    local q_required=$(echo "$q_json" | jq -r '.required // false')
    local q_options=$(echo "$q_json" | jq -c '.options // []')
    local q_min=$(echo "$q_json" | jq -r '.min // 0')
    local q_max=$(echo "$q_json" | jq -r '.max // 999999')
    local q_depends=$(echo "$q_json" | jq -r '.depends_on // empty')
    local q_help=$(echo "$q_json" | jq -r '.help // empty')

    # Check dependency
    if [[ -n "$q_depends" ]]; then
        local dep_value=$(config_get "$q_depends" "false" "$BOOTSTRAP_CONFIG")
        if [[ "$dep_value" != "true" ]]; then
            return 0  # Skip this question
        fi
    fi

    # Get current value as default if exists
    local current=$(config_get "$q_key" "" "$BOOTSTRAP_CONFIG")
    [[ -n "$current" ]] && q_default="$current"

    # Show help if available
    [[ -n "$q_help" ]] && echo -e "  ${GREY}$q_help${NC}"

    # Prompt based on type
    local answer=""
    case "$q_type" in
        text)
            _prompt_text "$q_prompt" "$q_default" answer "$q_required"
            ;;
        yesno)
            _prompt_yesno "$q_prompt" "$q_default" answer
            ;;
        choice)
            _prompt_choice "$q_prompt" "$q_options" "$q_default" answer
            ;;
        number)
            _prompt_number "$q_prompt" "$q_default" "$q_min" "$q_max" answer
            ;;
        *)
            log_warning "Unknown question type: $q_type"
            _prompt_text "$q_prompt" "$q_default" answer "$q_required"
            ;;
    esac

    # Save answer to config (with validation)
    if [[ -n "$answer" ]]; then
        if config_set "$q_key" "$answer" "$BOOTSTRAP_CONFIG"; then
            _answers+=("$q_key=$answer")
        else
            log_warning "Failed to save answer for: $q_key"
        fi
    fi
}

# Run questions for a script
# Uses script_mappings to find relevant questions
# Usage: question_engine_run "docker"
question_engine_run() {
    local script_key="$1"

    # Validate script_key is not empty
    [[ -z "$script_key" ]] && { log_error "script_key required for question_engine_run"; return 1; }

    # Check if disabled
    if [[ "${_QUESTION_ENGINE_DISABLED:-}" == "true" ]]; then
        log_warning "Question engine disabled (questions file not found)"
        return 0
    fi

    # Check if questions exist
    if ! question_engine_has_questions "$script_key"; then
        log_debug "No questions for: $script_key"
        return 0
    fi

    local desc=$(question_engine_get_description "$script_key")
    local count=$(question_engine_count "$script_key")

    echo ""
    log_section "Configuration: $script_key"
    [[ -n "$desc" ]] && echo -e "${GREY}$desc${NC}"
    echo -e "${GREY}$count question(s)${NC}"
    echo ""

    # Track answers for session
    local -a session_answers=()

    # Get mapped question keys for this script
    local keys=$(_get_script_question_keys "$script_key")

    # Process each mapped key
    for key in $keys; do
        local questions_json=$(_get_questions_for_key "$key")

        # Skip if no questions
        [[ "$questions_json" == "[]" || -z "$questions_json" ]] && continue

        # Iterate through questions in this key
        local q_count=$(echo "$questions_json" | jq 'length' 2>/dev/null || echo 0)
        for ((i=0; i<q_count; i++)); do
            local q_json=$(echo "$questions_json" | jq -c ".[$i]" 2>/dev/null)
            [[ "$q_json" == "null" || -z "$q_json" ]] && continue

            _process_question "$q_json" session_answers
        done
    done

    echo ""
    log_success "Configuration complete for: $script_key"

    # Show summary
    if [[ ${#session_answers[@]} -gt 0 ]]; then
        echo ""
        echo -e "${GREY}Values set:${NC}"
        for ans in "${session_answers[@]}"; do
            echo "  • $ans"
        done
    fi

    echo ""
    return 0
}

# Run all questions (for full interactive setup)
# Usage: question_engine_run_all
question_engine_run_all() {
    [[ "${_QUESTION_ENGINE_DISABLED:-}" == "true" ]] && return 0

    # Get all scripts from script_mappings that have questions
    local scripts=$(jq -r '.script_mappings.mappings | to_entries[] | select(.value | length > 0) | .key | sub("bootstrap-"; "")' "$QUESTIONS_FILE" 2>/dev/null)

    for script in $scripts; do
        if question_engine_has_questions "$script"; then
            question_engine_run "$script"
        fi
    done
}

# Preview questions without running
# Usage: question_engine_preview "docker"
question_engine_preview() {
    local script_key="$1"

    [[ "${_QUESTION_ENGINE_DISABLED:-}" == "true" ]] && return 0

    if ! question_engine_has_questions "$script_key"; then
        echo "No questions for: $script_key"
        return 0
    fi

    local desc=$(question_engine_get_description "$script_key")
    local count=$(question_engine_count "$script_key")

    echo ""
    echo -e "${BLUE}Questions for: $script_key${NC}"
    [[ -n "$desc" ]] && echo -e "${GREY}$desc${NC}"
    echo ""

    # Get mapped question keys for this script
    local keys=$(_get_script_question_keys "$script_key")
    local q_num=0

    for key in $keys; do
        local questions_json=$(_get_questions_for_key "$key")
        [[ "$questions_json" == "[]" || -z "$questions_json" ]] && continue

        local q_count=$(echo "$questions_json" | jq 'length' 2>/dev/null || echo 0)
        for ((i=0; i<q_count; i++)); do
            local q_json=$(echo "$questions_json" | jq -c ".[$i]" 2>/dev/null)
            [[ "$q_json" == "null" || -z "$q_json" ]] && continue

            local q_key=$(echo "$q_json" | jq -r '.key')
            local q_prompt=$(echo "$q_json" | jq -r '.prompt')
            local q_type=$(echo "$q_json" | jq -r '.type')
            local q_default=$(echo "$q_json" | jq -r '.default // "-"')

            q_num=$((q_num + 1))
            printf "  %d. %-30s [%s] default: %s\n" "$q_num" "$q_prompt" "$q_type" "$q_default"
        done
    done

    echo ""
    echo "Total: $count question(s)"
}

# ===================================================================
# Utility
# ===================================================================

# Validate questions file structure
# Usage: question_engine_validate && echo "valid"
question_engine_validate() {
    [[ "${_QUESTION_ENGINE_DISABLED:-}" == "true" ]] && return 1

    local errors=0

    # Check JSON validity
    if ! jq empty "$QUESTIONS_FILE" 2>/dev/null; then
        log_error "Invalid JSON in questions file"
        return 1
    fi

    # Check required sections exist
    for section in quick_start technology_choices script_mappings; do
        if ! jq -e ".$section" "$QUESTIONS_FILE" &>/dev/null; then
            log_error "Missing required section: $section"
            ((errors++))
        fi
    done

    # Check questions in each section have required fields
    for section in quick_start technology_choices advanced; do
        local questions=$(jq -c ".$section.questions // []" "$QUESTIONS_FILE")
        [[ "$questions" == "[]" ]] && continue

        local q_count=$(echo "$questions" | jq 'length')
        for ((i=0; i<q_count; i++)); do
            local q=$(echo "$questions" | jq -c ".[$i]")

            for field in key prompt type; do
                if [[ "$(echo "$q" | jq -r ".$field // empty")" == "" ]]; then
                    log_error "Section '$section' question $((i+1)) missing: $field"
                    ((errors++))
                fi
            done
        done
    done

    # Validate script_mappings references
    for script in $(jq -r '.script_mappings.mappings | keys[]' "$QUESTIONS_FILE" 2>/dev/null); do
        local keys=$(jq -r ".script_mappings.mappings.\"$script\"[]" "$QUESTIONS_FILE" 2>/dev/null)
        for key in $keys; do
            # Check if key is a valid section or a valid question key
            local is_section=$(jq -e ".$key.questions" "$QUESTIONS_FILE" 2>/dev/null && echo true || echo false)
            if [[ "$is_section" != "true" ]]; then
                # Check if it's a valid question key
                local found=$(jq -r "
                    .quick_start.questions[]?.key // empty,
                    .technology_choices.questions[]?.key // empty,
                    .advanced.questions[]?.key // empty
                " "$QUESTIONS_FILE" 2>/dev/null | grep -Fx "$key" || true)

                if [[ -z "$found" ]]; then
                    log_warning "Script '$script' references unknown key: $key"
                fi
            fi
        done
    done

    if [[ $errors -eq 0 ]]; then
        log_success "Questions file is valid"
        return 0
    else
        log_error "Questions file has $errors error(s)"
        return 1
    fi
}
