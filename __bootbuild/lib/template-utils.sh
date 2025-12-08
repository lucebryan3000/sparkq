#!/bin/bash

# ===================================================================
# template-utils.sh
#
# Safe file modification utilities for customizing templates
# after they've been copied to the project directory
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_TEMPLATE_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_TEMPLATE_UTILS_LOADED=1

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ===================================================================
# Safe File Replacement Functions
# ===================================================================

# Replace placeholder in file with value (atomic operation with backup)
# Usage: replace_in_file "file_path" "PLACEHOLDER" "replacement_value"
replace_in_file() {
    local file="$1"
    local placeholder="$2"
    local value="$3"

    # Validate file path is provided
    [[ -z "$file" ]] && { echo -e "${RED}✗${NC} File path required" >&2; return 1; }

    # Validate placeholder is provided
    [[ -z "$placeholder" ]] && { echo -e "${RED}✗${NC} Placeholder required" >&2; return 1; }

    # Validate file exists
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    # Validate file is writable
    if [[ ! -w "$file" ]]; then
        echo -e "${RED}✗${NC} File is not writable: $file" >&2
        return 1
    fi

    # Create backup
    local backup="${file}.backup.$(date +%s)"
    if ! cp "$file" "$backup" 2>/dev/null; then
        echo -e "${RED}✗${NC} Failed to create backup: $backup" >&2
        return 1
    fi

    # Verify backup was created successfully
    if [[ ! -f "$backup" ]]; then
        echo -e "${RED}✗${NC} Backup verification failed: $backup" >&2
        return 1
    fi

    # Use atomic operation (write to temp, then move)
    local tmp_file="${file}.tmp.$$"
    trap "rm -f '$tmp_file' 2>/dev/null" EXIT ERR

    # Escape special chars in placeholder for use as regex pattern
    local escaped_placeholder=$(printf '%s\n' "$placeholder" | sed 's/[.[\*^$]/\\&/g')
    # Escape special chars in value for use as replacement
    local escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')

    if sed "s/${escaped_placeholder}/${escaped_value}/g" "$file" > "$tmp_file" 2>/dev/null; then
        # Verify replacement occurred in tmp file
        if grep -q "$value" "$tmp_file" 2>/dev/null; then
            # Atomic move
            if mv "$tmp_file" "$file" 2>/dev/null; then
                rm -f "$backup"
                trap - EXIT ERR
                return 0
            else
                echo -e "${RED}✗${NC} Failed to write changes to $file" >&2
                mv "$backup" "$file"
                rm -f "$tmp_file"
                trap - EXIT ERR
                return 1
            fi
        else
            echo -e "${YELLOW}⚠${NC} Replacement may not have occurred in $file" >&2
            mv "$backup" "$file"
            rm -f "$tmp_file"
            trap - EXIT ERR
            return 1
        fi
    else
        echo -e "${RED}✗${NC} Failed to replace in $file" >&2
        mv "$backup" "$file"
        rm -f "$tmp_file"
        trap - EXIT ERR
        return 1
    fi
}

# Replace multiple placeholders in a file
# Usage: replace_multiple_in_file "file_path" "PLACEHOLDER1:value1" "PLACEHOLDER2:value2" ...
replace_multiple_in_file() {
    local file="$1"
    shift
    local failed=0

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    # Create single backup for all replacements
    local backup="${file}.backup.$(date +%s)"
    cp "$file" "$backup"

    for replacement in "$@"; do
        IFS=':' read -r placeholder value <<< "$replacement"

        if [[ -z "$placeholder" ]] || [[ -z "$value" ]]; then
            echo -e "${YELLOW}⚠${NC} Invalid replacement format: $replacement (use PLACEHOLDER:value)" >&2
            continue
        fi

        local escaped_placeholder=$(printf '%s\n' "$placeholder" | sed 's/[.[\*^$]/\\&/g')
        local escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')

        if ! sed -i "s/${escaped_placeholder}/${escaped_value}/g" "$file"; then
            echo -e "${RED}✗${NC} Failed to replace $placeholder in $file" >&2
            failed=1
        fi
    done

    if [[ $failed -eq 0 ]]; then
        rm -f "$backup"
        return 0
    else
        mv "$backup" "$file"
        return 1
    fi
}

# ===================================================================
# JSON Manipulation Functions
# ===================================================================

# Update field in package.json (or any JSON file) - atomic operation with validation
# Usage: update_json_field "file.json" "field.path" "new_value"
update_json_field() {
    local file="$1"
    local field_path="$2"
    local new_value="$3"

    # Validate file path is provided
    [[ -z "$file" ]] && { echo -e "${RED}✗${NC} File path required" >&2; return 1; }

    # Validate field_path is provided
    [[ -z "$field_path" ]] && { echo -e "${RED}✗${NC} Field path required" >&2; return 1; }

    # Check Python3 is installed
    command -v python3 &>/dev/null || { echo -e "${RED}✗${NC} python3 required but not installed" >&2; return 1; }

    # Validate file exists
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    # Validate file is writable
    if [[ ! -w "$file" ]]; then
        echo -e "${RED}✗${NC} File is not writable: $file" >&2
        return 1
    fi

    # Validate file is valid JSON before modification
    if ! python3 -m json.tool "$file" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} Invalid JSON in file: $file" >&2
        return 1
    fi

    # Create backup
    local backup="${file}.backup.$(date +%s)"
    if ! cp "$file" "$backup" 2>/dev/null; then
        echo -e "${RED}✗${NC} Failed to create backup: $backup" >&2
        return 1
    fi

    # Verify backup
    if [[ ! -f "$backup" ]]; then
        echo -e "${RED}✗${NC} Backup verification failed: $backup" >&2
        return 1
    fi

    # Use atomic operation with temp file
    local tmp_file="${file}.tmp.$$"
    trap "rm -f '$tmp_file' 2>/dev/null" EXIT ERR

    # Use Python for safe JSON manipulation (pass new_value as argument to prevent injection)
    if python3 -c "
import json
import sys

try:
    # Get new value from command line argument
    new_value_arg = sys.argv[1] if len(sys.argv) > 1 else ''

    with open(sys.argv[2], 'r') as f:
        data = json.load(f)

    # Handle nested field paths (e.g., 'scripts.build')
    keys = sys.argv[3].split('.')
    current = data

    # Navigate to parent of target field
    for key in keys[:-1]:
        if key not in current:
            current[key] = {}
        current = current[key]

    # Set the value (try to parse as JSON, otherwise use as string)
    try:
        current[keys[-1]] = json.loads(new_value_arg)
    except:
        current[keys[-1]] = new_value_arg

    # Write to temp file with pretty formatting
    with open(sys.argv[4], 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')

    sys.exit(0)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" "$new_value" "$file" "$field_path" "$tmp_file" 2>/dev/null; then
        # Validate the temp file is valid JSON
        if python3 -m json.tool "$tmp_file" >/dev/null 2>&1; then
            # Atomic move
            if mv "$tmp_file" "$file" 2>/dev/null; then
                rm -f "$backup"
                trap - EXIT ERR
                return 0
            else
                echo -e "${RED}✗${NC} Failed to write changes to $file" >&2
                mv "$backup" "$file"
                rm -f "$tmp_file"
                trap - EXIT ERR
                return 1
            fi
        else
            echo -e "${RED}✗${NC} Generated invalid JSON for $file" >&2
            mv "$backup" "$file"
            rm -f "$tmp_file"
            trap - EXIT ERR
            return 1
        fi
    else
        echo -e "${RED}✗${NC} Failed to update $field_path in $file" >&2
        mv "$backup" "$file"
        rm -f "$tmp_file"
        trap - EXIT ERR
        return 1
    fi
}

# Update multiple fields in JSON file
# Usage: update_json_fields "file.json" "name:my-app" "version:1.0.0" "private:true"
update_json_fields() {
    local file="$1"
    shift
    local failed=0

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    # Create single backup
    local backup="${file}.backup.$(date +%s)"
    cp "$file" "$backup"

    for field_update in "$@"; do
        IFS=':' read -r field_path new_value <<< "$field_update"

        if ! update_json_field "$file" "$field_path" "$new_value"; then
            failed=1
            break
        fi
    done

    if [[ $failed -eq 0 ]]; then
        rm -f "$backup"
        return 0
    else
        mv "$backup" "$file"
        return 1
    fi
}

# ===================================================================
# YAML Manipulation Functions
# ===================================================================

# Update value in YAML file (simple key-value, not nested)
# Usage: update_yaml_field "file.yml" "key" "new_value"
update_yaml_field() {
    local file="$1"
    local key="$2"
    local new_value="$3"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    # Create backup
    local backup="${file}.backup.$(date +%s)"
    cp "$file" "$backup"

    # Simple YAML replacement (for top-level keys only)
    local escaped_key=$(printf '%s\n' "$key" | sed 's/[.[\*^$]/\\&/g')
    local escaped_value=$(printf '%s\n' "$new_value" | sed 's/[&/\]/\\&/g')

    if sed -i "s/^\\s*${escaped_key}\\s*:.*/${escaped_key}: ${escaped_value}/" "$file"; then
        rm -f "$backup"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to update $key in $file" >&2
        mv "$backup" "$file"
        return 1
    fi
}

# Update Docker Compose database service
# Usage: update_docker_compose_db "docker-compose.yml" "mysql" "my_db_name"
update_docker_compose_db() {
    local file="$1"
    local db_type="$2"
    local db_name="${3:-app_dev}"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    # Create backup
    local backup="${file}.backup.$(date +%s)"
    cp "$file" "$backup"

    # Escape db_name for use in sed replacement
    local escaped_db_name=$(printf '%s\n' "$db_name" | sed 's/[&/\]/\\&/g')

    case "$db_type" in
        postgres|postgresql)
            sed -i 's/image: .*/image: postgres:16-alpine/' "$file"
            sed -i "s/POSTGRES_DB=.*/POSTGRES_DB=${escaped_db_name}/" "$file"
            ;;
        mysql)
            sed -i 's/image: postgres.*/image: mysql:8.0/' "$file"
            sed -i "s/POSTGRES_DB=.*/MYSQL_DATABASE=${escaped_db_name}/" "$file"
            sed -i "s/POSTGRES_USER=/MYSQL_USER=/" "$file"
            sed -i "s/POSTGRES_PASSWORD=/MYSQL_ROOT_PASSWORD=/" "$file"
            ;;
        mongodb|mongo)
            sed -i 's/image: postgres.*/image: mongo:7-alpine/' "$file"
            sed -i "s/POSTGRES_DB=.*/MONGO_INITDB_DATABASE=${escaped_db_name}/" "$file"
            sed -i "s/POSTGRES_USER=/MONGO_INITDB_ROOT_USERNAME=/" "$file"
            sed -i "s/POSTGRES_PASSWORD=/MONGO_INITDB_ROOT_PASSWORD=/" "$file"
            ;;
        *)
            echo -e "${RED}✗${NC} Unsupported database type: $db_type" >&2
            mv "$backup" "$file"
            return 1
            ;;
    esac

    rm -f "$backup"
    return 0
}

# ===================================================================
# Environment File Functions
# ===================================================================

# Create .env file from key-value pairs
# Usage: create_env_file ".env.local" "KEY1:value1" "KEY2:value2" ...
create_env_file() {
    local file="$1"
    shift

    # Validate file path is provided
    [[ -z "$file" ]] && { echo -e "${RED}✗${NC} File path required" >&2; return 1; }

    # Validate directory is writable
    local file_dir=$(dirname "$file")
    [[ ! -d "$file_dir" ]] && { echo -e "${RED}✗${NC} Directory does not exist: $file_dir" >&2; return 1; }
    [[ ! -w "$file_dir" ]] && { echo -e "${RED}✗${NC} Directory not writable: $file_dir" >&2; return 1; }

    # Backup existing file if present
    if [[ -f "$file" ]]; then
        [[ ! -w "$file" ]] && { echo -e "${RED}✗${NC} Existing file not writable: $file" >&2; return 1; }
        local backup="${file}.backup.$(date +%s)"
        cp "$file" "$backup"
    fi

    # Create header
    cat > "$file" <<EOF
# Environment Configuration
# Generated: $(date)
# DO NOT commit this file to version control

EOF

    # Verify file was created
    [[ ! -f "$file" ]] && { echo -e "${RED}✗${NC} Failed to create file: $file" >&2; return 1; }

    # Add key-value pairs
    for pair in "$@"; do
        IFS=':' read -r key value <<< "$pair"

        if [[ -n "$key" ]] && [[ -n "$value" ]]; then
            echo "${key}=${value}" >> "$file" || { echo -e "${RED}✗${NC} Failed to write to $file" >&2; return 1; }
        fi
    done

    # Final verification
    if [[ -f "$file" ]]; then
        return 0
    else
        echo -e "${RED}✗${NC} Failed to create $file" >&2
        return 1
    fi
}

# Update or add key in existing .env file
# Usage: update_env_var ".env.local" "DATABASE_URL" "postgres://..."
update_env_var() {
    local file="$1"
    local key="$2"
    local value="$3"

    # Create file if it doesn't exist
    if [[ ! -f "$file" ]]; then
        create_env_file "$file"
    fi

    # Create backup
    local backup="${file}.backup.$(date +%s)"
    cp "$file" "$backup"

    # Check if key exists
    local escaped_key=$(printf '%s\n' "$key" | sed 's/[.[\*^$]/\\&/g')
    if grep -q "^${escaped_key}=" "$file"; then
        # Update existing key
        local escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
        sed -i "s|^${escaped_key}=.*|${escaped_key}=${escaped_value}|" "$file"
    else
        # Add new key
        echo "${key}=${value}" >> "$file"
    fi

    rm -f "$backup"
    return 0
}

# ===================================================================
# Markdown Manipulation Functions
# ===================================================================

# Replace placeholder in markdown file
# Usage: update_markdown_field "README.md" "PROJECT_NAME" "my-app"
update_markdown_field() {
    replace_in_file "$@"
}

# Update frontmatter in markdown file
# Usage: update_markdown_frontmatter "CLAUDE.md" "phase" "MVP"
update_markdown_frontmatter() {
    local file="$1"
    local key="$2"
    local value="$3"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    # Create backup
    local backup="${file}.backup.$(date +%s)"
    cp "$file" "$backup"

    # Update frontmatter (between --- markers)
    # This is a simple approach - only works for top-level keys
    local escaped_key=$(printf '%s\n' "$key" | sed 's/[.[\*^$]/\\&/g')
    local escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
    if sed -i "/^---$/,/^---$/ s/^${escaped_key}:.*/${escaped_key}: ${escaped_value}/" "$file"; then
        rm -f "$backup"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to update frontmatter in $file" >&2
        mv "$backup" "$file"
        return 1
    fi
}

# ===================================================================
# Validation Functions
# ===================================================================

# Verify file was modified correctly
# Usage: verify_modification "package.json" "my-app"
verify_modification() {
    local file="$1"
    local expected_content="$2"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    if grep -q "$expected_content" "$file"; then
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Expected content not found in $file: $expected_content" >&2
        return 1
    fi
}

# Check if file is valid JSON
# Usage: validate_json "package.json"
validate_json() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    if python3 -c "import json; import sys; json.load(open(sys.argv[1]))" "$file" 2>/dev/null; then
        return 0
    else
        echo -e "${RED}✗${NC} Invalid JSON in $file" >&2
        return 1
    fi
}

# ===================================================================
# Batch Operations
# ===================================================================

# Apply template customizations from answers file
# Usage: apply_customizations ".bootstrap-answers.env" "templates_dir"
apply_customizations() {
    local answers_file="$1"
    local templates_dir="${2:-.}"

    if [[ ! -f "$answers_file" ]]; then
        echo -e "${RED}✗${NC} Answers file not found: $answers_file" >&2
        return 1
    fi

    # Source answers file to get variables
    source "$answers_file"

    echo -e "${BLUE}→${NC} Applying customizations from $answers_file..."

    # This function is meant to be extended by specific bootstrap scripts
    # Each script will define which files to modify based on the variables

    return 0
}

# Cleanup backup files
# Usage: cleanup_backups "directory"
cleanup_backups() {
    local dir="${1:-.}"
    local count=0

    # Validate directory exists
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}✗${NC} Directory not found: $dir" >&2
        return 1
    fi

    # Convert to absolute path for safety checks
    local abs_dir=$(cd "$dir" && pwd)

    # Safety checks - prevent cleaning critical system directories
    local dangerous_dirs=(
        "/"
        "/bin"
        "/boot"
        "/dev"
        "/etc"
        "/home"
        "/lib"
        "/lib64"
        "/opt"
        "/proc"
        "/root"
        "/sbin"
        "/sys"
        "/tmp"
        "/usr"
        "/var"
    )

    for dangerous in "${dangerous_dirs[@]}"; do
        if [[ "$abs_dir" == "$dangerous" ]]; then
            echo -e "${RED}✗${NC} Refusing to clean backups from critical system directory: $abs_dir" >&2
            return 1
        fi
    done

    # Additional safety: must be under /home/USER or /tmp/USER or contain 'apps' or 'projects'
    if [[ ! "$abs_dir" =~ ^/home/[^/]+/ ]] && \
       [[ ! "$abs_dir" =~ /apps/ ]] && \
       [[ ! "$abs_dir" =~ /projects/ ]] && \
       [[ ! "$abs_dir" =~ ^/tmp/[^/]+/ ]]; then
        echo -e "${RED}✗${NC} Refusing to clean backups from directory outside safe locations: $abs_dir" >&2
        echo -e "${YELLOW}⚠${NC} Safe locations: /home/USER/*, /tmp/USER/*, or paths containing 'apps' or 'projects'" >&2
        return 1
    fi

    # Proceed with cleanup
    while IFS= read -r -d '' backup; do
        rm -f "$backup"
        ((count++))
    done < <(find "$abs_dir" -type f -name "*.backup.*" -print0)

    if [[ $count -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Cleaned up $count backup files from $abs_dir"
    fi

    return 0
}

# ===================================================================
# Script Template Functions (Manifest-Driven)
# ===================================================================

# Get templates for a script from manifest
# Usage: templates=$(get_script_templates "docker")
get_script_templates() {
    local script_name="$1"

    # Requires MANIFEST_FILE to be set
    if [[ -z "${MANIFEST_FILE:-}" || ! -f "$MANIFEST_FILE" ]]; then
        echo ""
        return 1
    fi

    jq -r ".scripts.\"$script_name\".templates[]? // empty" "$MANIFEST_FILE" 2>/dev/null
}

# Copy all templates for a script
# Usage: copy_script_templates "docker" "/project/root"
copy_script_templates() {
    local script_name="$1"
    local dest_root="$2"
    local templates_root="${TEMPLATES_ROOT:-${BOOTSTRAP_DIR}/templates/root}"

    local templates=$(get_script_templates "$script_name")
    [[ -z "$templates" ]] && return 0

    local copied=0

    for template in $templates; do
        local src_path="${templates_root}/${template}"
        local dest_path="${dest_root}/${template}"

        # Handle directory templates (ending with /)
        if [[ "$template" == */ ]]; then
            local dir_name="${template%/}"
            src_path="${templates_root}/${dir_name}"
            dest_path="${dest_root}"

            if [[ -d "$src_path" ]]; then
                mkdir -p "$dest_path"
                if cp -r "$src_path"/* "$dest_path/" 2>/dev/null; then
                    log_success "Copied: $dir_name/"
                    ((copied++))
                else
                    log_warning "Failed to copy: $dir_name/"
                fi
            fi
        # Handle special directories (.claude/, .vscode/, .github/)
        elif [[ "$template" == .* && "$template" == */ ]]; then
            local special_dir="${template%/}"
            src_path="${BOOTSTRAP_DIR}/templates/${special_dir}"
            dest_path="${dest_root}/${special_dir}"

            if [[ -d "$src_path" ]]; then
                mkdir -p "$dest_path"
                if cp -r "$src_path"/* "$dest_path/" 2>/dev/null; then
                    log_success "Copied: $special_dir/"
                    ((copied++))
                fi
            fi
        # Handle individual files
        elif [[ -f "$src_path" ]]; then
            local dest_dir=$(dirname "$dest_path")
            mkdir -p "$dest_dir"

            if cp "$src_path" "$dest_path" 2>/dev/null; then
                log_success "Copied: $(basename "$template")"
                ((copied++))
            else
                log_warning "Failed to copy: $template"
            fi
        else
            log_debug "Template not found: $template"
        fi
    done

    return 0
}

# Copy a template category (e.g., "docker/", "linting/")
# Usage: copy_template_category "docker" "/project/root"
copy_template_category() {
    local category="$1"
    local dest_root="$2"
    local templates_root="${TEMPLATES_ROOT:-${BOOTSTRAP_DIR}/templates/root}"

    local src_dir="${templates_root}/${category}"

    if [[ ! -d "$src_dir" ]]; then
        log_warning "Template category not found: $category"
        return 1
    fi

    # Copy all files from the category
    for file in "$src_dir"/*; do
        [[ ! -e "$file" ]] && continue

        local filename=$(basename "$file")
        local dest_path="${dest_root}/${filename}"

        if [[ -f "$file" ]]; then
            if cp "$file" "$dest_path" 2>/dev/null; then
                log_success "Copied: $filename"
            fi
        elif [[ -d "$file" ]]; then
            mkdir -p "$dest_path"
            if cp -r "$file"/* "$dest_path/" 2>/dev/null; then
                log_success "Copied: $filename/"
            fi
        fi
    done

    return 0
}

# List available template categories
# Usage: list_template_categories
list_template_categories() {
    local templates_root="${TEMPLATES_ROOT:-${BOOTSTRAP_DIR}/templates/root}"

    if [[ -d "$templates_root" ]]; then
        find "$templates_root" -maxdepth 1 -type d -printf '%f\n' | tail -n +2 | sort
    fi
}

# ===================================================================
# Display Functions
# ===================================================================

# Show what would be modified (dry run)
# Usage: show_modifications "file" "placeholder" "new_value"
show_modifications() {
    local file="$1"
    local placeholder="$2"
    local new_value="$3"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file" >&2
        return 1
    fi

    echo -e "${BLUE}Changes that would be made to $(basename "$file"):${NC}"
    grep -n "$placeholder" "$file" | while IFS=: read -r line_num line_content; do
        local new_line="${line_content//$placeholder/$new_value}"
        echo -e "  Line $line_num:"
        echo -e "    ${RED}- $line_content${NC}"
        echo -e "    ${GREEN}+ $new_line${NC}"
    done
}
