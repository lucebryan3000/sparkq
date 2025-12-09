#!/bin/bash
# =============================================================================
# @script         bootstrap-test-suite
# @version        1.0.0
# @phase          4
# @category       test
# @priority       50
# @short          Complete test suite setup for projects
# @description    Sets up comprehensive testing infrastructure with Jest for
#                 unit/integration testing, Pytest for Python, Vitest for
#                 modern TypeScript, Playwright for e2e browser testing, and
#                 test contract documentation with patterns and best practices.
#
# @creates        tests/conftest.py
# @creates        tests/jest.config.js
# @creates        tests/TEST_CONTRACT.md
# @creates        tests/patterns.md
# @creates        tests/unit/
# @creates        tests/integration/
# @creates        tests/e2e/
# @creates        pytest.ini
# @creates        vitest.config.ts
# @creates        playwright.config.ts
#
# @modifies       .gitignore
#
# @detects        has_test_suite
# @questions      none
# @defaults       INSTALL_MODE=full
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  none
# @env_vars        API_BASE_URL,API_PORT,DRY_RUN,FORCE,FRAMEWORK_LIST,FRAMEWORKS,GITIGNORE,GITIGNORE_ENTRIES,INSTALL_MODE,SRC_DIR,TESTS_DIR,TZ
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf tests/conftest.py tests/jest.config.js tests/TEST_CONTRACT.md tests/patterns.md tests/unit/ tests/integration/ tests/e2e/ pytest.ini vitest.config.ts playwright.config.ts
# @verify          test -f tests/conftest.py
# @docs            https://jestjs.io/docs/getting-started
# =============================================================================
#
# USAGE:
#   ./bootstrap-test-suite.sh [PROJECT_PATH]
#   ./bootstrap-test-suite.sh --minimal
#   ./bootstrap-test-suite.sh --frameworks=pytest,vitest
#   ./bootstrap-test-suite.sh --dry-run

set -euo pipefail

# ===================================================================
# Version
# ===================================================================
SCRIPT_VERSION="1.0.0"

# ===================================================================
# Paths and Setup
# ===================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script is in templates/scripts/, so go up two levels to __bootbuild/
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Export for child scripts
export BOOTSTRAP_DIR

# Source lib/paths.sh first to initialize all paths
if [[ -f "${BOOTSTRAP_DIR}/lib/paths.sh" ]]; then
    source "${BOOTSTRAP_DIR}/lib/paths.sh"
fi

# Source core libraries
source "${BOOTSTRAP_DIR}/lib/common.sh" || {
    echo "ERROR: Failed to source lib/common.sh" >&2
    exit 1
}

# Source template utilities
if [[ -f "${BOOTSTRAP_DIR}/lib/template-utils.sh" ]]; then
    source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
fi

# Initialize script
init_script "bootstrap-test-suite.sh"

# Script identifier
SCRIPT_NAME="bootstrap-test-suite"

# Template source directory
TEMPLATE_SOURCE="${BOOTSTRAP_DIR}/templates/test"

# ===================================================================
# CLI Flags
# ===================================================================
DRY_RUN=false
INSTALL_MODE="full"
PROJECT_ROOT="."
FRAMEWORKS=""
SHOW_HELP=false
AUTO_YES=false
FORCE=false

# ===================================================================
# Help Text
# ===================================================================
show_help() {
    cat << EOF
Bootstrap Test Suite v${SCRIPT_VERSION}

USAGE:
    ${SCRIPT_NAME} [OPTIONS] [PROJECT_PATH]

DESCRIPTION:
    Copies test suite templates to your project and configures them
    with project-specific values.

OPTIONS:
    --minimal           Install minimal test suite (no storage dependencies)
    --full              Install full test suite (default)
    --frameworks=LIST   Comma-separated list of frameworks to install
                        Options: pytest, jest, vitest, playwright, puppeteer
                        Default: auto-detect from package.json/pyproject.toml
    --dry-run           Show what would be done without making changes
    --force             Overwrite existing test files
    -y, --yes           Skip all confirmations
    -h, --help          Show this help message
    -v, --version       Show version

EXAMPLES:
    # Install full test suite in current directory
    ${SCRIPT_NAME}

    # Install minimal suite (starter tests only)
    ${SCRIPT_NAME} --minimal

    # Install specific frameworks
    ${SCRIPT_NAME} --frameworks=pytest,vitest

    # Preview what would be installed
    ${SCRIPT_NAME} --dry-run

    # Install in a specific project
    ${SCRIPT_NAME} /path/to/project

EOF
}

# ===================================================================
# Parse Arguments
# ===================================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --minimal)
            INSTALL_MODE="minimal"
            shift
            ;;
        --full)
            INSTALL_MODE="full"
            shift
            ;;
        --frameworks=*)
            FRAMEWORKS="${1#*=}"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "v${SCRIPT_VERSION}"
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            PROJECT_ROOT="$1"
            shift
            ;;
    esac
done

# ===================================================================
# Project Detection
# ===================================================================

# Get absolute project root
PROJECT_ROOT=$(cd "$PROJECT_ROOT" && pwd)

log_info "Project root: $PROJECT_ROOT"

# Detect project name
detect_project_name() {
    local name=""

    # Try package.json
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        name=$(python3 -c "import json; print(json.load(open('$PROJECT_ROOT/package.json')).get('name', ''))" 2>/dev/null || true)
    fi

    # Try pyproject.toml
    if [[ -z "$name" && -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        name=$(grep -E "^name\s*=" "$PROJECT_ROOT/pyproject.toml" | head -1 | sed 's/.*=\s*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/' || true)
    fi

    # Fall back to directory name
    if [[ -z "$name" ]]; then
        name=$(basename "$PROJECT_ROOT")
    fi

    echo "$name"
}

# Convert project name to different cases
to_pascal_case() {
    echo "$1" | sed -E 's/(^|[-_])([a-z])/\U\2/g'
}

to_snake_case() {
    echo "$1" | sed 's/-/_/g'
}

to_upper_case() {
    echo "$1" | tr '[:lower:]-' '[:upper:]_'
}

# Detect frameworks from project files
detect_frameworks() {
    local detected=""

    # Python: always include pytest if Python files exist
    if [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || [[ -f "$PROJECT_ROOT/requirements.txt" ]] || \
       find "$PROJECT_ROOT" -maxdepth 2 -name "*.py" -type f | head -1 | grep -q .; then
        detected="pytest"
    fi

    # JavaScript/TypeScript
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        local pkg_content
        pkg_content=$(cat "$PROJECT_ROOT/package.json")

        # Check for vitest
        if echo "$pkg_content" | grep -q '"vitest"'; then
            detected="${detected:+$detected,}vitest"
        # Check for jest
        elif echo "$pkg_content" | grep -q '"jest"'; then
            detected="${detected:+$detected,}jest"
        # Default to jest if TypeScript/JavaScript project
        elif echo "$pkg_content" | grep -qE '"typescript"|"@types/'; then
            detected="${detected:+$detected,}jest"
        fi

        # Check for playwright
        if echo "$pkg_content" | grep -q '"@playwright/test"'; then
            detected="${detected:+$detected,}playwright"
        # Check for puppeteer
        elif echo "$pkg_content" | grep -q '"puppeteer"'; then
            detected="${detected:+$detected,}puppeteer"
        fi
    fi

    echo "$detected"
}

# ===================================================================
# Variable Substitution
# ===================================================================

# Project variables
PROJECT_NAME=$(detect_project_name)
PROJECT_NAME_PASCAL=$(to_pascal_case "$PROJECT_NAME")
PROJECT_NAME_SNAKE=$(to_snake_case "$PROJECT_NAME")
PROJECT_NAME_UPPER=$(to_upper_case "$PROJECT_NAME")

# Directory variables
SRC_DIR="src"
TESTS_DIR="tests"

# API variables
API_PORT="5000"
API_BASE_URL="http://localhost:${API_PORT}"

# Timezone
TZ="${TZ:-America/Chicago}"

# Auto-detect frameworks if not specified
if [[ -z "$FRAMEWORKS" ]]; then
    FRAMEWORKS=$(detect_frameworks)
fi

log_info "Detected configuration:"
echo "  Project name:     $PROJECT_NAME"
echo "  PascalCase:       $PROJECT_NAME_PASCAL"
echo "  snake_case:       $PROJECT_NAME_SNAKE"
echo "  UPPER_CASE:       $PROJECT_NAME_UPPER"
echo "  Source dir:       $SRC_DIR"
echo "  Tests dir:        $TESTS_DIR"
echo "  API port:         $API_PORT"
echo "  Frameworks:       ${FRAMEWORKS:-none detected}"
echo "  Install mode:     $INSTALL_MODE"
echo ""

# ===================================================================
# Variable Substitution Function
# ===================================================================

substitute_variables() {
    local file="$1"

    # Perform all substitutions
    sed -i \
        -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
        -e "s|{{PROJECT_NAME_PASCAL}}|${PROJECT_NAME_PASCAL}|g" \
        -e "s|{{PROJECT_NAME_SNAKE}}|${PROJECT_NAME_SNAKE}|g" \
        -e "s|{{PROJECT_NAME_UPPER}}|${PROJECT_NAME_UPPER}|g" \
        -e "s|{{SRC_DIR}}|${SRC_DIR}|g" \
        -e "s|{{TESTS_DIR}}|${TESTS_DIR}|g" \
        -e "s|{{API_PORT}}|${API_PORT}|g" \
        -e "s|{{API_BASE_URL}}|${API_BASE_URL}|g" \
        -e "s|{{TZ}}|${TZ}|g" \
        "$file"
}

# ===================================================================
# File Copy Function
# ===================================================================

copy_template() {
    local src="$1"
    local dst="$2"
    local relative_path="${src#$TEMPLATE_SOURCE/}"

    # Skip if destination exists and not forcing
    if [[ -f "$dst" && "$FORCE" != "true" ]]; then
        log_warning "Skipping (exists): $relative_path"
        track_skipped "$relative_path"
        return 0
    fi

    # Ensure destination directory exists
    mkdir -p "$(dirname "$dst")"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would copy: $relative_path"
        return 0
    fi

    # Copy file
    cp "$src" "$dst"

    # Perform variable substitution
    substitute_variables "$dst"

    log_success "Created: $relative_path"
    track_created "$relative_path"
}

copy_directory() {
    local src_dir="$1"
    local dst_dir="$2"

    if [[ ! -d "$src_dir" ]]; then
        return 0
    fi

    find "$src_dir" -type f | while read -r file; do
        local relative="${file#$src_dir/}"
        copy_template "$file" "$dst_dir/$relative"
    done
}

# ===================================================================
# Main Installation
# ===================================================================

log_section "Installing Test Suite"

# Create tests directory
if [[ "$DRY_RUN" != "true" ]]; then
    mkdir -p "$PROJECT_ROOT/$TESTS_DIR"
    mkdir -p "$PROJECT_ROOT/$TESTS_DIR/logs"
fi

# Copy main test files
log_info "Copying test templates..."

# Core config files
copy_template "$TEMPLATE_SOURCE/tests/conftest.py" "$PROJECT_ROOT/$TESTS_DIR/conftest.py"
copy_template "$TEMPLATE_SOURCE/tests/jest.config.js" "$PROJECT_ROOT/$TESTS_DIR/jest.config.js"
copy_template "$TEMPLATE_SOURCE/tests/TEST_CONTRACT.md" "$PROJECT_ROOT/$TESTS_DIR/TEST_CONTRACT.md"
copy_template "$TEMPLATE_SOURCE/tests/patterns.md" "$PROJECT_ROOT/$TESTS_DIR/patterns.md"

# Copy test directories based on mode
if [[ "$INSTALL_MODE" == "full" ]]; then
    log_info "Installing full test suite..."

    # Unit tests
    if [[ -d "$TEMPLATE_SOURCE/tests/unit" ]]; then
        copy_directory "$TEMPLATE_SOURCE/tests/unit" "$PROJECT_ROOT/$TESTS_DIR/unit"
    fi

    # Integration tests
    if [[ -d "$TEMPLATE_SOURCE/tests/integration" ]]; then
        copy_directory "$TEMPLATE_SOURCE/tests/integration" "$PROJECT_ROOT/$TESTS_DIR/integration"
    fi

    # E2E tests
    if [[ -d "$TEMPLATE_SOURCE/tests/e2e" ]]; then
        copy_directory "$TEMPLATE_SOURCE/tests/e2e" "$PROJECT_ROOT/$TESTS_DIR/e2e"
    fi

    # Browser tests
    if [[ -d "$TEMPLATE_SOURCE/tests/browser" ]]; then
        copy_directory "$TEMPLATE_SOURCE/tests/browser" "$PROJECT_ROOT/$TESTS_DIR/browser"
    fi

    # UI tests
    if [[ -d "$TEMPLATE_SOURCE/tests/ui" ]]; then
        copy_directory "$TEMPLATE_SOURCE/tests/ui" "$PROJECT_ROOT/$TESTS_DIR/ui"
    fi

    # Utils
    if [[ -d "$TEMPLATE_SOURCE/tests/utils" ]]; then
        copy_directory "$TEMPLATE_SOURCE/tests/utils" "$PROJECT_ROOT/$TESTS_DIR/utils"
    fi
else
    log_info "Installing minimal test suite..."

    # Create minimal starter tests
    if [[ "$DRY_RUN" != "true" ]]; then
        mkdir -p "$PROJECT_ROOT/$TESTS_DIR/unit"

        # Create a basic starter test
        cat > "$PROJECT_ROOT/$TESTS_DIR/unit/test_example.py" << 'PYTEST_EOF'
"""
Example unit test - customize for your project.
"""

import pytest


class TestExample:
    """Example test class."""

    def test_addition(self):
        """Basic test to verify pytest is working."""
        assert 1 + 1 == 2

    def test_string_operations(self):
        """Example string test."""
        greeting = "Hello, World!"
        assert "Hello" in greeting
        assert greeting.lower() == "hello, world!"

    @pytest.mark.skip(reason="Template placeholder - implement your tests")
    def test_your_feature_here(self):
        """Replace this with your actual tests."""
        pass
PYTEST_EOF

        log_success "Created: $TESTS_DIR/unit/test_example.py"
        track_created "$TESTS_DIR/unit/test_example.py"
    fi
fi

# ===================================================================
# Framework-Specific Files
# ===================================================================

log_info "Installing framework configurations..."

# Parse frameworks
IFS=',' read -ra FRAMEWORK_LIST <<< "$FRAMEWORKS"

for framework in "${FRAMEWORK_LIST[@]}"; do
    framework=$(echo "$framework" | tr -d ' ')

    case "$framework" in
        pytest)
            if [[ -d "$TEMPLATE_SOURCE/frameworks/pytest" ]]; then
                copy_template "$TEMPLATE_SOURCE/frameworks/pytest/pytest.ini" "$PROJECT_ROOT/pytest.ini"
                # Don't overwrite conftest if already copied
                if [[ ! -f "$PROJECT_ROOT/$TESTS_DIR/conftest.py" ]]; then
                    copy_template "$TEMPLATE_SOURCE/frameworks/pytest/conftest.py" "$PROJECT_ROOT/$TESTS_DIR/conftest.py"
                fi
            fi
            ;;
        jest)
            if [[ -d "$TEMPLATE_SOURCE/frameworks/jest" ]]; then
                copy_template "$TEMPLATE_SOURCE/frameworks/jest/jest.setup.js" "$PROJECT_ROOT/$TESTS_DIR/jest.setup.js"
            fi
            ;;
        vitest)
            if [[ -d "$TEMPLATE_SOURCE/frameworks/vitest" ]]; then
                copy_template "$TEMPLATE_SOURCE/frameworks/vitest/vitest.config.ts" "$PROJECT_ROOT/vitest.config.ts"
                copy_template "$TEMPLATE_SOURCE/frameworks/vitest/vitest.setup.ts" "$PROJECT_ROOT/$TESTS_DIR/vitest.setup.ts"
            fi
            ;;
        playwright)
            if [[ -d "$TEMPLATE_SOURCE/frameworks/playwright" ]]; then
                copy_template "$TEMPLATE_SOURCE/frameworks/playwright/playwright.config.ts" "$PROJECT_ROOT/playwright.config.ts"
                copy_template "$TEMPLATE_SOURCE/frameworks/playwright/playwright.setup.ts" "$PROJECT_ROOT/$TESTS_DIR/playwright.setup.ts"
            fi
            ;;
        puppeteer)
            # Puppeteer uses Jest config, already handled
            log_info "Puppeteer: Using Jest configuration"
            ;;
        *)
            log_warning "Unknown framework: $framework"
            ;;
    esac
done

# ===================================================================
# Create .gitignore entries
# ===================================================================

if [[ "$DRY_RUN" != "true" ]]; then
    GITIGNORE="$PROJECT_ROOT/.gitignore"

    # Add test artifacts to gitignore
    declare -a GITIGNORE_ENTRIES=(
        "# Test artifacts"
        "$TESTS_DIR/logs/"
        "$TESTS_DIR/coverage/"
        "$TESTS_DIR/.pytest_cache/"
        "*.pyc"
        "__pycache__/"
        ".coverage"
        "htmlcov/"
        "playwright-report/"
        "test-results/"
    )

    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if [[ -f "$GITIGNORE" ]]; then
            if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
                echo "$entry" >> "$GITIGNORE"
            fi
        else
            echo "$entry" >> "$GITIGNORE"
        fi
    done

    log_success "Updated .gitignore with test artifacts"
fi

# ===================================================================
# Summary
# ===================================================================

log_section "Installation Complete"

echo ""
log_info "Test suite installed to: $PROJECT_ROOT/$TESTS_DIR"
echo ""

log_info "Next steps:"
echo "  1. Review and customize test files for your project"
echo "  2. Install test dependencies:"

for framework in "${FRAMEWORK_LIST[@]}"; do
    framework=$(echo "$framework" | tr -d ' ')
    case "$framework" in
        pytest)
            echo "     pip install pytest pytest-asyncio pytest-cov"
            ;;
        jest)
            echo "     npm install --save-dev jest @types/jest"
            ;;
        vitest)
            echo "     npm install --save-dev vitest @vitest/coverage-v8"
            ;;
        playwright)
            echo "     npm install --save-dev @playwright/test"
            echo "     npx playwright install"
            ;;
        puppeteer)
            echo "     npm install --save-dev puppeteer jest"
            ;;
    esac
done

echo "  3. Run tests:"
echo "     pytest (Python)"
echo "     npm test (JavaScript)"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "This was a dry run - no files were created"
fi

show_summary
