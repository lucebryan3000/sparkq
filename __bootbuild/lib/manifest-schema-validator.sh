#!/bin/bash

# ===================================================================
# lib/manifest-schema-validator.sh
#
# Manifest schema validation for bootstrap system.
# Ensures bootstrap-manifest.json conforms to expected structure.
#
# USAGE:
#   source "${BOOTSTRAP_DIR}/lib/manifest-schema-validator.sh"
#   validate_manifest_schema "/path/to/bootstrap-manifest.json"
#
# DESIGN:
#   Validates manifest structure without external dependencies.
#   Provides detailed error reporting for schema violations.
#   Can be used in CI/CD pipelines to enforce manifest consistency.
#
# ===================================================================

# Prevent double-sourcing
[[ -n "${_BOOTSTRAP_MANIFEST_SCHEMA_LOADED:-}" ]] && return 0
_BOOTSTRAP_MANIFEST_SCHEMA_LOADED=1

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===================================================================
# Schema Definition
# ===================================================================

# Define required top-level sections
declare -a REQUIRED_SECTIONS=(
    "paths"
    "libraries"
    "scripts"
    "templates"
)

# Define required path keys
declare -a REQUIRED_PATHS=(
    "BOOTSTRAP_DIR"
    "MANIFEST_FILE"
    "CONFIG_FILE"
    "CONFIG_DIR"
    "LIB_DIR"
    "SCRIPTS_DIR"
    "TEMPLATES_DIR"
    "KB_ROOT"
)

# ===================================================================
# Validation Functions
# ===================================================================

# Check if jq is available
_has_jq() {
    command -v jq &>/dev/null
}

# Validate manifest has valid JSON structure
validate_json_syntax() {
    local manifest_file="$1"
    
    if ! _has_jq; then
        echo -e "${YELLOW}⚠${NC} jq not installed - skipping JSON syntax check"
        return 0
    fi
    
    if ! jq empty "$manifest_file" 2>/dev/null; then
        echo -e "${RED}✗ Invalid JSON syntax in manifest${NC}"
        jq . "$manifest_file" 2>&1 | head -10
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} JSON syntax is valid"
    return 0
}

# Validate required top-level sections
validate_required_sections() {
    local manifest_file="$1"
    local errors=0
    
    if ! _has_jq; then
        return 0
    fi
    
    echo -e "${BLUE}Validating required sections...${NC}"
    
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if jq -e ".$section" "$manifest_file" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Section present: $section"
        else
            echo -e "${RED}✗ Missing section: $section${NC}"
            ((errors++))
        fi
    done
    
    return $((errors > 0 ? 1 : 0))
}

# Validate paths section schema
validate_paths_section() {
    local manifest_file="$1"
    local errors=0
    
    if ! _has_jq; then
        return 0
    fi
    
    echo -e "${BLUE}Validating paths section...${NC}"
    
    for path_key in "${REQUIRED_PATHS[@]}"; do
        if jq -e ".paths.\"$path_key\"" "$manifest_file" > /dev/null 2>&1; then
            local path_value=$(jq -r ".paths.\"$path_key\"" "$manifest_file")
            echo -e "${GREEN}✓${NC} Path defined: $path_key"
        else
            echo -e "${YELLOW}⚠${NC} Optional path not defined: $path_key"
        fi
    done
    
    return 0
}

# Validate libraries section has expected structure
validate_libraries_section() {
    local manifest_file="$1"
    
    if ! _has_jq; then
        return 0
    fi
    
    echo -e "${BLUE}Validating libraries section...${NC}"
    
    local lib_count=$(jq '.libraries | length' "$manifest_file" 2>/dev/null || echo 0)
    
    if [[ $lib_count -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Libraries defined: $lib_count"
        
        # Check each library has required fields
        jq '.libraries | keys[]' "$manifest_file" | while read -r lib; do
            lib=${lib%\"}
            lib=${lib#\"}
            
            if jq -e ".libraries.\"$lib\".file" "$manifest_file" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}   Library: $lib"
            else
                echo -e "${YELLOW}⚠${NC}   Library missing 'file' field: $lib"
            fi
        done
    else
        echo -e "${YELLOW}⚠${NC} No libraries defined"
    fi
    
    return 0
}

# Validate scripts section has expected structure
validate_scripts_section() {
    local manifest_file="$1"
    
    if ! _has_jq; then
        return 0
    fi
    
    echo -e "${BLUE}Validating scripts section...${NC}"
    
    local script_count=$(jq '.scripts | length' "$manifest_file" 2>/dev/null || echo 0)
    
    if [[ $script_count -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Scripts defined: $script_count"
        
        # Check each script has required fields
        jq '.scripts | keys[]' "$manifest_file" | while read -r script; do
            script=${script%\"}
            script=${script#\"}
            
            if jq -e ".scripts.\"$script\".file" "$manifest_file" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}   Script: $script"
            else
                echo -e "${YELLOW}⚠${NC}   Script missing 'file' field: $script"
            fi
        done
    else
        echo -e "${YELLOW}⚠${NC} No scripts defined"
    fi
    
    return 0
}

# Validate templates section has expected structure
validate_templates_section() {
    local manifest_file="$1"
    
    if ! _has_jq; then
        return 0
    fi
    
    echo -e "${BLUE}Validating templates section...${NC}"
    
    local template_count=$(jq '.templates | length' "$manifest_file" 2>/dev/null || echo 0)
    
    if [[ $template_count -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Templates defined: $template_count"
    else
        echo -e "${YELLOW}⚠${NC} No templates defined"
    fi
    
    return 0
}

# Validate metadata (generated, version)
validate_metadata() {
    local manifest_file="$1"
    
    if ! _has_jq; then
        return 0
    fi
    
    echo -e "${BLUE}Validating metadata...${NC}"
    
    if jq -e ".version" "$manifest_file" > /dev/null 2>&1; then
        local version=$(jq -r ".version" "$manifest_file")
        echo -e "${GREEN}✓${NC} Version: $version"
    else
        echo -e "${YELLOW}⚠${NC} No version field"
    fi
    
    if jq -e ".generated" "$manifest_file" > /dev/null 2>&1; then
        local generated=$(jq -r ".generated" "$manifest_file")
        echo -e "${GREEN}✓${NC} Generated: $generated"
    else
        echo -e "${YELLOW}⚠${NC} No generated timestamp"
    fi
    
    return 0
}

# ===================================================================
# Main Validation Function
# ===================================================================

# Validate complete manifest schema
# Returns: 0 if valid, 1 if validation failed
validate_manifest_schema() {
    local manifest_file="${1:-}"
    
    if [[ -z "$manifest_file" ]]; then
        echo -e "${RED}✗ Manifest file path required${NC}"
        return 1
    fi
    
    if [[ ! -f "$manifest_file" ]]; then
        echo -e "${RED}✗ Manifest file not found: $manifest_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Bootstrap Manifest Schema Validation ===${NC}"
    echo "File: $manifest_file"
    echo ""
    
    local errors=0
    
    # Run all validations
    validate_json_syntax "$manifest_file" || ((errors++))
    echo ""
    
    validate_required_sections "$manifest_file" || ((errors++))
    echo ""
    
    validate_paths_section "$manifest_file" || ((errors++))
    echo ""
    
    validate_libraries_section "$manifest_file" || ((errors++))
    echo ""
    
    validate_scripts_section "$manifest_file" || ((errors++))
    echo ""
    
    validate_templates_section "$manifest_file" || ((errors++))
    echo ""
    
    validate_metadata "$manifest_file" || ((errors++))
    echo ""
    
    # Summary
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✓ Manifest schema is valid${NC}"
        return 0
    else
        echo -e "${RED}✗ Manifest validation failed ($errors critical errors)${NC}"
        return 1
    fi
}

# Export validation functions
export -f validate_manifest_schema
export -f validate_json_syntax
export -f validate_required_sections
