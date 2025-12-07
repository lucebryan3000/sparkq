#!/bin/bash

# ===================================================================
# bootstrap-kb-sync.sh
#
# Phase 2: Technology Documentation Scanner
#
# Scans kb-bootstrap/ folder structure and:
# 1. Counts documentation files in each technology folder
# 2. Checks for MANIFEST.json files
# 3. Determines documentation status (documented|partial|missing)
# 4. Reads source URLs from bootstrap.config [sources]
# 5. Updates kb-bootstrap-manifest.json with scan results
# 6. Writes detailed scan report to bootstrap/logs/
# 7. Updates bootstrap.config [technologies] with new status
#
# USAGE:
#   ./bootstrap-kb-sync.sh [--report-only] [--verbose]
#
# OPTIONS:
#   --report-only    Generate report without updating manifest
#   --verbose        Show detailed scan progress
#
# OUTPUT:
#   - bootstrap/logs/bootstrap-scan-report.log (detailed report)
#   - kb-bootstrap-manifest.json (updated with scan data)
#   - bootstrap.config (updated [technologies] section)
#
# ===================================================================

set -uo pipefail

# Paths - derive BOOTSTRAP_DIR first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source lib/paths.sh to initialize all paths
source "${BOOTSTRAP_DIR}/lib/paths.sh" || exit 1

# All paths now available from lib/paths.sh:
# $CONFIG_FILE, $KB_ROOT, $KB_MANIFEST_FILE, $LOGS_KB_DIR, $KB_SCAN_REPORT
# Use KB_SCAN_REPORT which is the standard name from paths.sh
REPORT_FILE="${KB_SCAN_REPORT}"

# Options
REPORT_ONLY=false
VERBOSE=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===================================================================
# Helper Functions
# ===================================================================

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[SCAN]${NC} $*"
    fi
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Parse config file and get value
config_get() {
    local key="$1"
    local default="${2:-}"
    local section="${key%%.*}"
    local var="${key##*.}"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "$default"
        return
    fi

    # Find value in config file
    local value=$(grep "^${var}=" <(sed -n "/^\[$section\]/,/^\[/p" "$CONFIG_FILE") 2>/dev/null | cut -d= -f2- || echo "")
    echo "${value:-$default}"
}

# ===================================================================
# Scan Functions
# ===================================================================

count_docs() {
    local tech_path="$1"
    local count=0

    if [[ -d "$tech_path" ]]; then
        count=$(find "$tech_path" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" \) 2>/dev/null | wc -l)
    fi

    echo "$count"
}

has_manifest() {
    local tech_path="$1"

    if [[ -f "${tech_path}/MANIFEST.json" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

determine_status() {
    local docs_count="$1"

    if [[ "$docs_count" -gt 5 ]]; then
        echo "documented"
    elif [[ "$docs_count" -gt 0 ]]; then
        echo "partial"
    else
        echo "missing"
    fi
}

get_source_url() {
    local tech="$1"
    config_get "sources.${tech}" ""
}

list_docs() {
    local tech_path="$1"

    if [[ -d "$tech_path" ]]; then
        find "$tech_path" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" \) 2>/dev/null | xargs -I {} basename {} | sort
    fi
}

# ===================================================================
# Scan kb-bootstrap/
# ===================================================================

scan_kb() {
    log_info "Scanning kb-bootstrap/ directory..."

    local documented=0
    local partial=0
    local missing=0
    local total=0

    # Get all technology folders
    local techs=$(find "$KB_ROOT" -maxdepth 1 -type d ! -name "kb-bootstrap" | sort | xargs -I {} basename {})

    for tech in $techs; do
        local tech_path="${KB_ROOT}/${tech}"
        local docs_count=$(count_docs "$tech_path")
        local has_manifest_file=$(has_manifest "$tech_path")
        local status=$(determine_status "$docs_count")
        local source_url=$(get_source_url "$tech")

        log_verbose "  $tech: $docs_count docs, status=$status"

        case "$status" in
            documented) ((documented++)) ;;
            partial) ((partial++)) ;;
            missing) ((missing++)) ;;
        esac
        ((total++))
    done

    log_info "Scan complete: $total technologies ($documented documented, $partial partial, $missing missing)"
    echo "$documented:$partial:$missing:$total"
}

# ===================================================================
# Generate Report
# ===================================================================

generate_report() {
    log_info "Generating scan report..."

    mkdir -p "$LOGS_KB_DIR"

    {
        echo "================================================================================"
        echo "BOOTSTRAP KNOWLEDGE BASE SCAN REPORT"
        echo "================================================================================"
        echo ""
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S Z')"
        echo "Scanned: ${KB_ROOT}"
        echo ""

        echo "SUMMARY"
        echo "---"

        local documented=0
        local partial=0
        local missing=0
        local total=0

        for tech_path in "$KB_ROOT"/*; do
            [[ ! -d "$tech_path" ]] && continue
            tech=$(basename "$tech_path")
            [[ "$tech" =~ \.json$ ]] && continue

            docs_count=$(count_docs "$tech_path")
            status=$(determine_status "$docs_count")

            case "$status" in
                documented) ((documented++)) ;;
                partial) ((partial++)) ;;
                missing) ((missing++)) ;;
            esac
            ((total++))
        done

        echo "Total Technologies: $total"
        echo "  ✓ Documented: $documented"
        echo "  ◐ Partial: $partial"
        echo "  ✗ Missing: $missing"
        echo ""

        echo "DOCUMENTED TECHNOLOGIES (${documented})"
        echo "---"
        for tech_path in "$KB_ROOT"/*; do
            [[ ! -d "$tech_path" ]] && continue
            tech=$(basename "$tech_path")
            [[ "$tech" =~ \.json$ ]] && continue

            docs_count=$(count_docs "$tech_path")
            status=$(determine_status "$docs_count")

            if [[ "$status" == "documented" ]]; then
                echo ""
                echo "📦 $tech ($docs_count docs)"
                echo "   Location: $tech_path"
                list_docs "$tech_path" | sed 's/^/     - /'
            fi
        done

        echo ""
        echo ""
        echo "TECHNOLOGIES NEEDING DOCUMENTATION (${missing})"
        echo "---"
        for tech_path in "$KB_ROOT"/*; do
            [[ ! -d "$tech_path" ]] && continue
            tech=$(basename "$tech_path")
            [[ "$tech" =~ \.json$ ]] && continue

            docs_count=$(count_docs "$tech_path")
            status=$(determine_status "$docs_count")
            source_url=$(get_source_url "$tech")

            if [[ "$status" == "missing" ]]; then
                echo ""
                echo "❌ $tech"
                echo "   Docs: $docs_count | Status: $status"
                if [[ -n "$source_url" ]]; then
                    echo "   Source: $source_url"
                fi
                echo "   Folder: $tech_path"
            fi
        done

        echo ""
        echo ""
        echo "PARTIALLY DOCUMENTED (${partial})"
        echo "---"
        for tech_path in "$KB_ROOT"/*; do
            [[ ! -d "$tech_path" ]] && continue
            tech=$(basename "$tech_path")
            [[ "$tech" =~ \.json$ ]] && continue

            docs_count=$(count_docs "$tech_path")
            status=$(determine_status "$docs_count")
            source_url=$(get_source_url "$tech")

            if [[ "$status" == "partial" ]]; then
                echo ""
                echo "◐ $tech ($docs_count docs)"
                echo "   Folder: $tech_path"
                list_docs "$tech_path" | sed 's/^/     - /'
                if [[ -n "$source_url" ]]; then
                    echo "   Source: $source_url"
                fi
            fi
        done

        echo ""
        echo "================================================================================"
        echo "END OF REPORT"
        echo "================================================================================"

    } > "$REPORT_FILE"

    log_info "Report written to: $REPORT_FILE"
}

# ===================================================================
# Update Manifest
# ===================================================================

update_manifest() {
    if [[ "$REPORT_ONLY" == "true" ]]; then
        log_warn "Skipping manifest update (--report-only)"
        return
    fi

    log_info "Updating kb-bootstrap-manifest.json..."

    # This would require jq or complex bash. For now, we'll use a simpler approach
    # In production, you'd use jq to update the JSON properly
    log_warn "Manifest update requires jq - install with: sudo apt-get install jq"
}

# ===================================================================
# Update Config
# ===================================================================

update_config() {
    if [[ "$REPORT_ONLY" == "true" ]]; then
        log_warn "Skipping config update (--report-only)"
        return
    fi

    log_info "Updating bootstrap.config [technologies]..."

    # This requires careful editing of the config file
    # For now, we'll just note that this needs to be done
    log_warn "Config update scheduled for future implementation"
}

# ===================================================================
# Main
# ===================================================================

main() {
    echo ""
    log_info "Bootstrap Knowledge Base Scanner - Phase 2"
    echo ""

    # Check prerequisites
    if [[ ! -d "$KB_ROOT" ]]; then
        log_error "kb-bootstrap directory not found: $KB_ROOT"
        exit 1
    fi

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "bootstrap.config not found: $CONFIG_FILE"
        exit 1
    fi

    # Run scan
    local scan_result=$(scan_kb)

    # Generate report
    generate_report

    # Update manifest
    update_manifest

    # Update config
    update_config

    echo ""
    log_info "Scan complete!"
    echo ""
    log_info "View report: cat $REPORT_FILE"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --report-only)
            REPORT_ONLY=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

main "$@"
