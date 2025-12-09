#!/bin/bash
# =============================================================================
# update-scripts-metadata.sh
# Adds 8 new metadata fields to all bootstrap scripts
# Reads values from discovery-results.txt
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_SCRIPTS="${SCRIPT_DIR}/../templates/scripts"
DISCOVERY_FILE="${SCRIPT_DIR}/discovery-results.txt"

if [[ ! -f "$DISCOVERY_FILE" ]]; then
    echo "ERROR: discovery-results.txt not found. Run discover-metadata.sh first."
    exit 1
fi

# Read discovery results into associative arrays
declare -A CONFIG_SECTIONS
declare -A INTERACTIVES
declare -A PLATFORMS
declare -A ENV_VARS
declare -A CONFLICTS
declare -A ROLLBACKS
declare -A VERIFIES
declare -A DOCS

# Skip header line, read data
tail -n +2 "$DISCOVERY_FILE" | while IFS='|' read -r name config_section interactive platforms env_vars conflicts rollback verify docs; do
    # Store in temp files since we can't use associative arrays across subshells
    echo "$config_section" > "/tmp/meta_${name}_config_section"
    echo "$interactive" > "/tmp/meta_${name}_interactive"
    echo "$platforms" > "/tmp/meta_${name}_platforms"
    echo "$env_vars" > "/tmp/meta_${name}_env_vars"
    echo "$conflicts" > "/tmp/meta_${name}_conflicts"
    echo "$rollback" > "/tmp/meta_${name}_rollback"
    echo "$verify" > "/tmp/meta_${name}_verify"
    echo "$docs" > "/tmp/meta_${name}_docs"
done

echo "Updating scripts with new metadata fields..."
echo ""

for script in "$TEMPLATES_SCRIPTS"/bootstrap-*.sh; do
    script_name=$(basename "$script" .sh | sed 's/bootstrap-//')

    # Check if metadata already exists
    if grep -q "^# @config_section" "$script"; then
        echo "SKIP: $script_name (already has new metadata)"
        continue
    fi

    # Read discovery values from temp files
    config_section=$(cat "/tmp/meta_${script_name}_config_section" 2>/dev/null || echo "none")
    interactive=$(cat "/tmp/meta_${script_name}_interactive" 2>/dev/null || echo "no")
    platforms=$(cat "/tmp/meta_${script_name}_platforms" 2>/dev/null || echo "all")
    env_vars=$(cat "/tmp/meta_${script_name}_env_vars" 2>/dev/null || echo "none")
    conflicts=$(cat "/tmp/meta_${script_name}_conflicts" 2>/dev/null || echo "none")
    rollback=$(cat "/tmp/meta_${script_name}_rollback" 2>/dev/null || echo "none")
    verify=$(cat "/tmp/meta_${script_name}_verify" 2>/dev/null || echo "none")
    docs=$(cat "/tmp/meta_${script_name}_docs" 2>/dev/null || echo "")

    # Find the line number of @updated (or last metadata line before the closing ===)
    insert_after=$(grep -n "^# @updated\|^# @author" "$script" | tail -1 | cut -d: -f1)

    if [[ -z "$insert_after" ]]; then
        # If no @updated, find the line before the closing === of the header
        insert_after=$(grep -n "^# ===*$" "$script" | tail -1 | cut -d: -f1)
        if [[ -n "$insert_after" ]]; then
            insert_after=$((insert_after - 1))
        else
            echo "ERROR: Cannot find header end in $script_name"
            continue
        fi
    fi

    # Build the metadata block to insert
    metadata_block="#
# @config_section  $config_section
# @env_vars        $env_vars
# @interactive     $interactive
# @platforms       $platforms
# @conflicts       $conflicts
# @rollback        $rollback
# @verify          $verify"

    # Add @docs if we have a URL
    if [[ -n "$docs" ]]; then
        metadata_block+="
# @docs            $docs"
    fi

    # Insert metadata after the target line
    # Using a temp file approach for portability
    {
        head -n "$insert_after" "$script"
        echo "$metadata_block"
        tail -n +"$((insert_after + 1))" "$script"
    } > "${script}.tmp" && mv "${script}.tmp" "$script"

    echo "UPDATED: $script_name"
done

# Clean up temp files
rm -f /tmp/meta_*_*

echo ""
echo "Done! All scripts updated."
