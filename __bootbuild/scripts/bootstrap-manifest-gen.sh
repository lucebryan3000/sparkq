#!/bin/bash

# bootstrap-manifest-gen.sh
# Auto-generates bootstrap-manifest.json by scanning filesystem
# Usage: ./bootstrap-manifest-gen.sh [options]
# Options:
#   --update       Update existing manifest (keeps existing metadata)
#   --force        Force regenerate from scratch
#   --validate     Validate manifest after generation
#   --pretty       Pretty-print JSON output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/paths.sh" || exit 1

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
UPDATE_MODE=false
FORCE_MODE=false
VALIDATE=false
PRETTY_PRINT=false
DRY_RUN=false
VERIFY_CHANGES=false

# Show usage
usage() {
  cat << EOF
Usage: bootstrap-manifest-gen.sh [OPTIONS]

Auto-generate bootstrap-manifest.json by scanning filesystem.

OPTIONS:
  --update           Update existing manifest (keeps existing metadata)
  --force            Force regenerate from scratch
  --validate         Validate manifest after generation
  --pretty           Pretty-print JSON output
  --dry-run          Show what would be generated without writing files
  --verify-changes   Show changes and ask for confirmation before proceeding
  -h, --help         Show this help message

EXAMPLES:
  # Generate manifest from scratch
  ./bootstrap-manifest-gen.sh

  # Update existing manifest
  ./bootstrap-manifest-gen.sh --update --pretty

  # Dry run to see what would be generated
  ./bootstrap-manifest-gen.sh --dry-run

  # Verify changes before applying
  ./bootstrap-manifest-gen.sh --verify-changes

EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --update) UPDATE_MODE=true; shift ;;
    --force) FORCE_MODE=true; UPDATE_MODE=false; shift ;;
    --validate) VALIDATE=true; shift ;;
    --pretty) PRETTY_PRINT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verify-changes) VERIFY_CHANGES=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Load existing manifest if in update mode
load_existing_metadata() {
  if [[ -f "$MANIFEST_FILE" && "$UPDATE_MODE" == true ]]; then
    cat "$MANIFEST_FILE"
  else
    echo '{}'
  fi
}

# Generate scripts section by scanning scripts directory
generate_scripts_section() {
  local scripts_json='{'
  local first=true

  for script in "${SCRIPTS_DIR}"/*.sh; do
    [[ ! -f "$script" ]] && continue
    local name=$(basename "$script" .sh)

    # Skip bootstrap-manifest-gen.sh to avoid self-reference
    [[ "$name" == "bootstrap-manifest-gen" ]] && continue

    if [[ "$first" == false ]]; then
      scripts_json+=','
    fi
    first=false

    # Extract description from script header
    local description=$(grep -m 1 "^# " "$script" | sed 's/^# //' || echo "")
    local usage=$(grep -m 1 "^# Usage:" "$script" | sed 's/^# Usage: //' || echo "")

    scripts_json+="\"$name\": {
      \"file\": \"scripts/$name.sh\",
      \"description\": \"$description\",
      \"usage\": \"$usage\"
    }"
  done

  scripts_json+='}'
  echo "$scripts_json"
}

# Generate libraries section by scanning lib directory
generate_libraries_section() {
  local libs_json='{'
  local first=true

  for lib in "${LIB_DIR}"/*.sh; do
    [[ ! -f "$lib" ]] && continue
    local name=$(basename "$lib" .sh)

    if [[ "$first" == false ]]; then
      libs_json+=','
    fi
    first=false

    # Extract description from lib header
    local description=$(grep -m 1 "^# " "$lib" | sed 's/^# //' || echo "")

    libs_json+="\"$name\": {
      \"file\": \"lib/$name.sh\",
      \"description\": \"$description\"
    }"
  done

  libs_json+='}'
  echo "$libs_json"
}

# Generate templates section by scanning templates directory
generate_templates_section() {
  local templates_json='{'
  local first=true

  for template_dir in "${TEMPLATES_DIR}"/*; do
    [[ ! -d "$template_dir" ]] && continue
    local name=$(basename "$template_dir")

    if [[ "$first" == false ]]; then
      templates_json+=','
    fi
    first=false

    # Count files in template
    local file_count=$(find "$template_dir" -type f | wc -l)
    local size=$(du -sh "$template_dir" | cut -f1)

    templates_json+="\"$name\": {
      \"directory\": \"templates/$name\",
      \"files\": $file_count,
      \"size\": \"$size\"
    }"
  done

  templates_json+='}'
  echo "$templates_json"
}

# Generate paths section
generate_paths_section() {
  cat <<'EOF'
{
  "BOOTSTRAP_DIR": ".",
  "MANIFEST_FILE": "bootstrap-manifest.json",
  "CONFIG_FILE": "config/bootstrap.config",
  "CONFIG_DIR": "config",
  "LIB_DIR": "lib",
  "SCRIPTS_DIR": "scripts",
  "TEMPLATES_DIR": "templates",
  "KB_ROOT": "kb-bootstrap",
  "LOGS_DIR": "logs",
  "LOGS_KB_DIR": "logs/kb",
  "TEMPLATES_CLAUDE": "templates/.claude",
  "TEMPLATES_VSCODE": "templates/.vscode",
  "TEMPLATES_GITHUB": "templates/.github",
  "TEMPLATES_DEVCONTAINER": "templates/.devcontainer",
  "TEMPLATES_SCRIPTS": "templates/scripts",
  "KB_MANIFEST_FILE": "kb-bootstrap/kb-manifest.json",
  "KB_SCAN_REPORT": "kb-bootstrap/scan-report.json"
}
EOF
}

# Main generation function
generate_manifest() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}[DRY RUN] Would generate bootstrap manifest...${NC}"
  else
    echo -e "${BLUE}Generating bootstrap manifest...${NC}"
  fi

  local existing=$(load_existing_metadata)

  # Generate sections
  local paths_section=$(generate_paths_section)
  local libs_section=$(generate_libraries_section)
  local scripts_section=$(generate_scripts_section)
  local templates_section=$(generate_templates_section)

  # Build manifest
  local manifest="{"
  manifest+="\"paths\": $paths_section,"
  manifest+="\"libraries\": $libs_section,"
  manifest+="\"scripts\": $scripts_section,"
  manifest+="\"templates\": $templates_section,"
  manifest+="\"generated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
  manifest+="\"version\": \"1.0\""
  manifest+="}"

  # Pretty print if requested
  if [[ "$PRETTY_PRINT" == true || -t 1 ]]; then
    if command -v jq &> /dev/null; then
      manifest=$(echo "$manifest" | jq '.')
    fi
  fi

  # Handle dry run
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}[DRY RUN] Would write manifest to: $MANIFEST_FILE${NC}"
    echo -e "${GREY}Preview (first 20 lines):${NC}"
    echo "$manifest" | head -20
    echo -e "${GREY}... (truncated)${NC}"
    return 0
  fi

  # Handle verify changes
  if [[ "$VERIFY_CHANGES" == "true" ]]; then
    echo -e "${YELLOW}Files that will be modified:${NC}"
    echo "  • $MANIFEST_FILE"
    if [[ -f "$MANIFEST_FILE" ]]; then
      echo "    (existing file will be overwritten)"
    else
      echo "    (new file will be created)"
    fi
    echo ""
    read -p "Proceed with these changes? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Operation cancelled by user${NC}"
      exit 0
    fi
  fi

  # Write manifest
  if [[ -w "$(dirname "$MANIFEST_FILE")" ]]; then
    echo "$manifest" > "$MANIFEST_FILE"
    echo -e "${GREEN}✓ Manifest generated: $MANIFEST_FILE${NC}"
  else
    echo -e "${RED}✗ Cannot write to $MANIFEST_FILE${NC}"
    exit 1
  fi

  # Validate if requested
  if [[ "$VALIDATE" == true ]]; then
    validate_manifest "$MANIFEST_FILE"
  fi
}

# Validate manifest
validate_manifest() {
  local manifest_file="$1"

  if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠ jq not installed, skipping validation${NC}"
    return 0
  fi

  if jq empty "$manifest_file" 2>/dev/null; then
    echo -e "${GREEN}✓ Manifest is valid JSON${NC}"

    # Check required sections
    local sections=("paths" "libraries" "scripts" "templates")
    local missing=false

    for section in "${sections[@]}"; do
      if ! jq -e ".$section" "$manifest_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Missing section: $section${NC}"
        missing=true
      fi
    done

    if [[ "$missing" == false ]]; then
      echo -e "${GREEN}✓ All required sections present${NC}"
    fi
  else
    echo -e "${RED}✗ Invalid JSON in manifest${NC}"
    return 1
  fi
}

# Display statistics
show_stats() {
  local script_count=$(find "${SCRIPTS_DIR}" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l)
  local lib_count=$(find "${LIB_DIR}" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l)
  local template_count=$(find "${TEMPLATES_DIR}" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l)

  echo -e "${BLUE}Statistics:${NC}"
  echo "  Scripts:   $script_count"
  echo "  Libraries: $lib_count"
  echo "  Templates: $template_count"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  Mode:      DRY RUN (no files modified)"
  else
    echo "  Generated: $(date)"
  fi
}

# Main execution
main() {
  if [[ ! -d "$BOOTSTRAP_DIR" ]]; then
    echo -e "${RED}✗ Bootstrap directory not found: $BOOTSTRAP_DIR${NC}"
    exit 1
  fi

  generate_manifest
  show_stats

  if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "${GREEN}✓ Dry run complete - no files were modified${NC}"
    echo -e "${GREY}To execute changes, run without --dry-run flag${NC}"
  else
    echo -e "${GREEN}✓ Manifest generation complete${NC}"
  fi
}

main "$@"
