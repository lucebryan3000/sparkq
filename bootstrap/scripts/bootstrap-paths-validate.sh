#!/bin/bash

# bootstrap-paths-validate.sh
# Validates all bootstrap paths exist and are accessible
# Usage: ./bootstrap-paths-validate.sh [options]
# Options:
#   --fix          Auto-create missing directories
#   --detailed     Show detailed permission information
#   --json         Output results in JSON format

set -eu

# Derive BOOTSTRAP_DIR from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${BOOTSTRAP_DIR}/lib/paths.sh" || exit 1

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
FIX_MODE=false
DETAILED=false
JSON_MODE=false
ERROR_COUNT=0
WARN_COUNT=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --fix) FIX_MODE=true; shift ;;
    --detailed) DETAILED=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Check if path exists and is readable
check_path() {
  local path="$1"
  local path_type="$2"
  local name="$3"

  if [[ ! -e "$path" ]]; then
    echo -e "${RED}✗${NC} MISSING [$path_type] $name"
    echo "  Path: $path"
    ((ERROR_COUNT++)) || true
    
    if [[ "$FIX_MODE" == true && "$path_type" == "directory" ]]; then
      mkdir -p "$path" && echo -e "${GREEN}  ✓ Created${NC}"
    fi
    return 1
  fi

  if [[ "$path_type" == "directory" && ! -d "$path" ]]; then
    echo -e "${RED}✗${NC} NOT A DIRECTORY [$path_type] $name"
    echo "  Path: $path (is a file)"
    ((ERROR_COUNT++)) || true
    return 1
  fi

  if [[ "$path_type" == "file" && ! -f "$path" ]]; then
    echo -e "${RED}✗${NC} NOT A FILE [$path_type] $name"
    echo "  Path: $path (is a directory)"
    ((ERROR_COUNT++)) || true
    return 1
  fi

  # Check readability
  if [[ ! -r "$path" ]]; then
    echo -e "${YELLOW}⚠${NC} NOT READABLE [$path_type] $name"
    echo "  Path: $path"
    ((WARN_COUNT++)) || true
    return 2
  fi

  # Check writability for config directories
  if [[ "$path_type" == "directory" && ! -w "$path" ]]; then
    case "$name" in
      config|logs|logs/kb) 
        echo -e "${YELLOW}⚠${NC} NOT WRITABLE [$path_type] $name"
        echo "  Path: $path"
        ((WARN_COUNT++)) || true
        ;;
    esac
  fi

  if [[ "$DETAILED" == true ]]; then
    local perms=$(stat -c '%A' "$path" 2>/dev/null || stat -f '%Lp' "$path" 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓${NC} EXISTS [$path_type] $name (permissions: $perms)"
  else
    echo -e "${GREEN}✓${NC} EXISTS [$path_type] $name"
  fi

  return 0
}

# Validate all core paths
validate_core_paths() {
  echo -e "${BLUE}=== Validating Core Paths ===${NC}"
  
  check_path "$BOOTSTRAP_DIR" "directory" "BOOTSTRAP_DIR" || true
  check_path "$MANIFEST_FILE" "file" "MANIFEST_FILE" || true
  check_path "$CONFIG_DIR" "directory" "CONFIG_DIR" || true
  check_path "$CONFIG_FILE" "file" "CONFIG_FILE" || true
  check_path "$LIB_DIR" "directory" "LIB_DIR" || true
  check_path "$SCRIPTS_DIR" "directory" "SCRIPTS_DIR" || true
  check_path "$TEMPLATES_DIR" "directory" "TEMPLATES_DIR" || true
  check_path "$KB_ROOT" "directory" "KB_ROOT" || true
  check_path "$LOGS_DIR" "directory" "LOGS_DIR" || true
  check_path "$LOGS_KB_DIR" "directory" "LOGS_KB_DIR" || true
}

# Validate template paths
validate_template_paths() {
  echo ""
  echo -e "${BLUE}=== Validating Template Paths ===${NC}"
  
  check_path "$TEMPLATES_CLAUDE" "directory" "TEMPLATES_CLAUDE" || true
  check_path "$TEMPLATES_VSCODE" "directory" "TEMPLATES_VSCODE" || true
  check_path "$TEMPLATES_GITHUB" "directory" "TEMPLATES_GITHUB" || true
  check_path "$TEMPLATES_DEVCONTAINER" "directory" "TEMPLATES_DEVCONTAINER" || true
  check_path "$TEMPLATES_SCRIPTS" "directory" "TEMPLATES_SCRIPTS" || true
}

# Validate library files
validate_library_files() {
  echo ""
  echo -e "${BLUE}=== Validating Library Files ===${NC}"
  
  for lib in paths.sh common.sh config-manager.sh; do
    check_path "${LIB_DIR}/$lib" "file" "lib/$lib" || true
  done
}

# Validate script files
validate_script_files() {
  echo ""
  echo -e "${BLUE}=== Validating Script Files ===${NC}"
  
  local count=0
  for script in "${SCRIPTS_DIR}"/*.sh; do
    [[ ! -f "$script" ]] && continue
    local name=$(basename "$script")
    
    if [[ ! -x "$script" ]]; then
      echo -e "${YELLOW}⚠${NC} NOT EXECUTABLE $name"
      ((WARN_COUNT++)) || true
    else
      echo -e "${GREEN}✓${NC} EXECUTABLE $name"
    fi
    ((count++)) || true
  done
  
  echo "  Total scripts: $count"
}

# Summary report
show_summary() {
  echo ""
  echo -e "${BLUE}=== Validation Summary ===${NC}"
  echo "Total errors:   ${ERROR_COUNT}"
  echo "Total warnings: ${WARN_COUNT}"
  
  if [[ $ERROR_COUNT -eq 0 ]]; then
    echo -e "${GREEN}✓ All paths validated successfully${NC}"
    return 0
  else
    echo -e "${RED}✗ Validation failed - $ERROR_COUNT errors found${NC}"
    return 1
  fi
}

# Main execution
main() {
  validate_core_paths
  validate_template_paths
  validate_library_files
  validate_script_files
  show_summary
}

main "$@"
