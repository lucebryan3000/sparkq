#!/bin/bash
# =============================================================================
# generate-manifest.sh
# Phase 3: Generate bootstrap-manifest.json from script headers
#
# This script reads all bootstrap-*.sh scripts, extracts metadata from headers,
# and generates the authoritative bootstrap-manifest.json file.
#
# Usage: ./generate-manifest.sh [--dry-run]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_SCRIPTS="${SCRIPT_DIR}/../templates/scripts"
MANIFEST_FILE="${SCRIPT_DIR}/../config/bootstrap-manifest.json"
DRY_RUN=false

# Parse arguments
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - manifest will not be written"
fi

# =============================================================================
# Helper Functions
# =============================================================================

extract_field() {
    local script="$1"
    local field="$2"
    local default="${3:-}"

    local value=$(grep -m1 "^# @$field" "$script" 2>/dev/null | sed "s/.*@$field\s*//" | xargs)

    if [[ -z "$value" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

extract_multi_field() {
    local script="$1"
    local field="$2"

    grep "^# @$field" "$script" 2>/dev/null | sed "s/.*@$field\s*//" | xargs || true
}

extract_description() {
    local script="$1"
    local in_description=false
    local description=""

    # Read file line by line to capture multi-line descriptions
    while IFS= read -r line; do
        if [[ "$line" =~ ^#[[:space:]]*@description ]]; then
            # Start of description
            in_description=true
            # Extract text after @description
            local text="${line#*@description}"
            text="${text#"${text%%[![:space:]]*}"}"  # trim leading whitespace
            description="$text"
        elif [[ "$in_description" == true ]]; then
            # Check if this is a continuation line (# followed by spaces, not a new tag)
            if [[ "$line" =~ ^#[[:space:]]{2,}[^@] ]]; then
                # Continuation line - extract text after #
                local text="${line#\#}"
                text="${text#"${text%%[![:space:]]*}"}"  # trim leading whitespace
                description="$description $text"
            elif [[ "$line" =~ ^#[[:space:]]*@ ]] || [[ "$line" == "#" ]] || [[ ! "$line" =~ ^# ]]; then
                # New tag, empty comment, or end of header - stop
                in_description=false
            fi
        fi
    done < "$script"

    # Clean up whitespace
    echo "$description" | sed 's/\s\+/ /g' | xargs
}

# Convert comma-separated string to JSON array
to_json_array() {
    local input="$1"
    if [[ -z "$input" || "$input" == "none" ]]; then
        echo "[]"
        return
    fi

    # Split by comma or newline and format as JSON array
    echo "$input" | tr ',' '\n' | while read -r item; do
        item=$(echo "$item" | xargs)  # trim whitespace
        if [[ -n "$item" ]]; then
            echo "\"$item\""
        fi
    done | paste -sd ',' | sed 's/^/[/' | sed 's/$/]/'
}

# Convert space/comma/newline-separated values to JSON array
lines_to_json_array() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "[]"
        return
    fi

    # Handle space-separated, comma-separated, or newline-separated values
    local result=""
    local first=true

    # Replace commas and newlines with spaces, then split
    for item in $(echo "$input" | tr ',' ' ' | tr '\n' ' '); do
        item=$(echo "$item" | xargs)  # trim whitespace
        if [[ -n "$item" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                result+=","
            fi
            result+="\"$item\""
        fi
    done

    if [[ -z "$result" ]]; then
        echo "[]"
    else
        echo "[$result]"
    fi
}

# =============================================================================
# Main Processing
# =============================================================================

echo "=========================================="
echo "  MANIFEST GENERATION"
echo "=========================================="
echo ""

# Start JSON structure
JSON_OUTPUT='{"$schema": "./bootstrap-manifest.schema.json","version": "2.0.0","generated": "'$(date -Iseconds)'",'
JSON_OUTPUT+='"generator": "generate-manifest.sh",'
JSON_OUTPUT+='"scripts": {'

first_script=true

for script in "$TEMPLATES_SCRIPTS"/bootstrap-*.sh; do
    # Extract script name (without bootstrap- prefix and .sh suffix)
    script_name=$(extract_field "$script" "script" "")

    if [[ -z "$script_name" ]]; then
        echo "WARNING: Skipping $script - no @script tag found"
        continue
    fi

    # Remove bootstrap- prefix if present
    script_name="${script_name#bootstrap-}"

    echo "Processing: $script_name"

    # Extract all metadata
    version=$(extract_field "$script" "version" "1.0.0")
    phase=$(extract_field "$script" "phase" "1")
    category=$(extract_field "$script" "category" "core")
    priority=$(extract_field "$script" "priority" "50")
    short=$(extract_field "$script" "short" "")
    description=$(extract_description "$script")
    safe=$(extract_field "$script" "safe" "yes")
    idempotent=$(extract_field "$script" "idempotent" "yes")
    questions=$(extract_field "$script" "questions" "none")

    # Extract multi-value fields
    creates=$(extract_multi_field "$script" "creates")
    depends=$(extract_multi_field "$script" "depends")
    requires=$(extract_multi_field "$script" "requires")
    detects=$(extract_multi_field "$script" "detects")
    tags=$(extract_multi_field "$script" "tags")
    defaults=$(extract_field "$script" "defaults" "")

    # Extract metadata fields
    author=$(extract_field "$script" "author" "")
    updated=$(extract_field "$script" "updated" "")

    # Extract Phase 2 metadata fields (8 new fields)
    config_section=$(extract_field "$script" "config_section" "none")
    env_vars=$(extract_multi_field "$script" "env_vars")
    interactive=$(extract_field "$script" "interactive" "no")
    platforms=$(extract_multi_field "$script" "platforms")
    conflicts=$(extract_multi_field "$script" "conflicts")
    rollback=$(extract_field "$script" "rollback" "")
    verify=$(extract_field "$script" "verify" "")
    docs=$(extract_field "$script" "docs" "")

    # Convert to JSON arrays
    creates_json=$(lines_to_json_array "$creates")
    depends_json=$(lines_to_json_array "$depends")
    requires_json=$(lines_to_json_array "$requires")
    detects_json=$(lines_to_json_array "$detects")
    tags_json=$(lines_to_json_array "$tags")

    # Convert Phase 2 array fields to JSON
    # Handle "none" as empty array for env_vars and conflicts
    if [[ -z "$env_vars" || "$env_vars" == "none" ]]; then
        env_vars_json='[]'
    else
        env_vars_json=$(lines_to_json_array "$env_vars")
    fi
    # Handle platforms default to ["all"] if empty
    if [[ -z "$platforms" ]]; then
        platforms_json='["all"]'
    else
        platforms_json=$(lines_to_json_array "$platforms")
    fi
    if [[ -z "$conflicts" || "$conflicts" == "none" ]]; then
        conflicts_json='[]'
    else
        conflicts_json=$(lines_to_json_array "$conflicts")
    fi

    # Convert boolean strings
    safe_bool="true"
    [[ "$safe" == "no" || "$safe" == "false" ]] && safe_bool="false"

    idempotent_bool="true"
    [[ "$idempotent" == "no" || "$idempotent" == "false" ]] && idempotent_bool="false"

    # Add comma between scripts (not before first)
    if [[ "$first_script" == "true" ]]; then
        first_script=false
    else
        JSON_OUTPUT+=','
    fi

    # Build script JSON object
    JSON_OUTPUT+='"'$script_name'": {'
    JSON_OUTPUT+='"version": "'$version'",'
    JSON_OUTPUT+='"phase": '$phase','
    JSON_OUTPUT+='"category": "'$category'",'
    JSON_OUTPUT+='"priority": '$priority','
    JSON_OUTPUT+='"short": "'$short'",'
    JSON_OUTPUT+='"description": "'$description'",'
    JSON_OUTPUT+='"safe": '$safe_bool','
    JSON_OUTPUT+='"idempotent": '$idempotent_bool','
    JSON_OUTPUT+='"questions": "'$questions'",'
    JSON_OUTPUT+='"creates": '$creates_json','
    JSON_OUTPUT+='"depends": '$depends_json','
    JSON_OUTPUT+='"requires": '$requires_json','
    JSON_OUTPUT+='"detects": '$detects_json','
    JSON_OUTPUT+='"tags": '$tags_json','
    # Phase 2 metadata fields
    JSON_OUTPUT+='"config_section": "'$config_section'",'
    JSON_OUTPUT+='"env_vars": '$env_vars_json','
    JSON_OUTPUT+='"interactive": "'$interactive'",'
    JSON_OUTPUT+='"platforms": '$platforms_json','
    JSON_OUTPUT+='"conflicts": '$conflicts_json

    # Add optional fields if present
    if [[ -n "$rollback" ]]; then
        JSON_OUTPUT+=',"rollback": "'$rollback'"'
    fi
    if [[ -n "$verify" ]]; then
        JSON_OUTPUT+=',"verify": "'$verify'"'
    fi
    if [[ -n "$docs" ]]; then
        JSON_OUTPUT+=',"docs": "'$docs'"'
    fi
    if [[ -n "$defaults" ]]; then
        JSON_OUTPUT+=',"defaults": "'$defaults'"'
    fi
    if [[ -n "$author" ]]; then
        JSON_OUTPUT+=',"author": "'$author'"'
    fi
    if [[ -n "$updated" ]]; then
        JSON_OUTPUT+=',"updated": "'$updated'"'
    fi

    JSON_OUTPUT+='}'
done

# Close JSON structure
JSON_OUTPUT+='}}'

# Validate and format JSON
echo ""
echo "Validating JSON..."

if ! echo "$JSON_OUTPUT" | jq . > /dev/null 2>&1; then
    echo "ERROR: Generated JSON is invalid"
    echo ""
    echo "Raw output (first 2000 chars):"
    echo "$JSON_OUTPUT" | head -c 2000
    exit 1
fi

# Format JSON nicely
FORMATTED_JSON=$(echo "$JSON_OUTPUT" | jq --indent 2 .)

# Write or display
if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "Generated manifest (first 100 lines):"
    echo "$FORMATTED_JSON" | head -100
    echo "..."
    echo ""
    echo "Total scripts processed: $(echo "$FORMATTED_JSON" | jq '.scripts | keys | length')"
else
    echo "$FORMATTED_JSON" > "$MANIFEST_FILE"
    echo ""
    echo "=========================================="
    echo "  MANIFEST GENERATED"
    echo "=========================================="
    echo ""
    echo "Output: $MANIFEST_FILE"
    echo "Scripts: $(echo "$FORMATTED_JSON" | jq '.scripts | keys | length')"
    echo "Size: $(wc -c < "$MANIFEST_FILE") bytes"
fi

echo ""
echo "Done!"
