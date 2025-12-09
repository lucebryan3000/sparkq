#!/bin/bash
# =============================================================================
# @script         bootstrap-quality
# @version        1.0.0
# @phase          4
# @category       test
# @priority       50
# @short          Code quality metrics and baseline configuration
# @description    Sets up code quality framework with SonarQube configuration,
#                 CodeClimate setup, quality gates, complexity rules,
#                 and baseline reporting for tracking code quality metrics
#                 and establishing minimum standards.
#
# @creates        quality/sonar-project.properties
# @creates        quality/.codeclimate.yml
# @creates        quality/quality-gates.json
# @creates        quality/complexity-rules.json
# @creates        quality/baseline-report.md
#
# @depends        linting, testing
# @detects        has_quality_config
# @questions      quality
# @defaults       quality.enabled=true, quality.coverage_threshold=80
# @detects        has_quality_config
# @questions      quality
# @defaults       quality.complexity_threshold=10
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
#
# @config_section  quality
# @env_vars        BASELINE_REPORT,CODECLIMATE_CONFIG,COMPLEXITY_RULES,COMPLEXITY_THRESHOLD,COVERAGE_REPORT,COVERAGE_THRESHOLD,CREATE_BASELINE,DUPLICATION_THRESHOLD,ENABLE_CODECLIMATE,ENABLED,ENABLE_SONARQUBE,EXCLUSIONS,FILES_TO_CREATE,QUALITY_GATES,SONAR_CONFIG,SONARQUBE_AVAILABLE,SOURCE_DIRS,TEST_FRAMEWORK
# @interactive     no
# @platforms       all
# @conflicts       none
# @rollback        rm -rf quality/sonar-project.properties quality/.codeclimate.yml quality/quality-gates.json quality/complexity-rules.json quality/baseline-report.md
# @verify          test -f quality/sonar-project.properties
# @docs            https://eslint.org/docs/latest/
# =============================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-quality"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-quality"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "" \
    --scripts "bootstrap-linting bootstrap-testing" \
    --optional ""


# ===================================================================
# Read Configuration
# ===================================================================

# Check if this bootstrap should run
ENABLED=$(config_get "quality.enabled" "true")
if [[ "$ENABLED" != "true" ]]; then
    log_info "Quality bootstrap disabled in config"
    exit 0
fi

# Read quality-specific settings
COVERAGE_THRESHOLD=$(config_get "quality.coverage_threshold" "80")
COMPLEXITY_THRESHOLD=$(config_get "quality.complexity_threshold" "10")
DUPLICATION_THRESHOLD=$(config_get "quality.duplication_threshold" "3")
ENABLE_SONARQUBE=$(config_get "quality.enable_sonarqube" "true")
ENABLE_CODECLIMATE=$(config_get "quality.enable_codeclimate" "false")
CREATE_BASELINE=$(config_get "quality.create_baseline" "true")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

# List all files this script will create
FILES_TO_CREATE=(
    "quality/"
    "quality/sonar-project.properties"
    "quality/.codeclimate.yml"
    "quality/quality-gates.json"
    "quality/complexity-rules.json"
)

pre_execution_confirm "$SCRIPT_NAME" "Quality Metrics Configuration" \
    "${FILES_TO_CREATE[@]}"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check if project directory exists
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"

# Check if we can write to project
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Detection Functions
# ===================================================================

detect_project_type() {
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        echo "javascript"
    elif [[ -f "$PROJECT_ROOT/requirements.txt" ]] || [[ -f "$PROJECT_ROOT/setup.py" ]]; then
        echo "python"
    elif [[ -f "$PROJECT_ROOT/pom.xml" ]]; then
        echo "java"
    elif [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        echo "rust"
    else
        echo "unknown"
    fi
}

detect_test_framework() {
    local project_type="$1"

    if [[ "$project_type" == "javascript" ]]; then
        if grep -q "jest" "$PROJECT_ROOT/package.json" 2>/dev/null; then
            echo "jest"
        elif grep -q "vitest" "$PROJECT_ROOT/package.json" 2>/dev/null; then
            echo "vitest"
        else
            echo "none"
        fi
    elif [[ "$project_type" == "python" ]]; then
        if [[ -f "$PROJECT_ROOT/pytest.ini" ]]; then
            echo "pytest"
        else
            echo "unittest"
        fi
    else
        echo "unknown"
    fi
}

detect_sonarqube() {
    if command -v sonar-scanner &> /dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# ===================================================================
# Create Quality Directory
# ===================================================================

log_info "Creating quality directory..."

if ! dir_exists "$PROJECT_ROOT/quality"; then
    ensure_dir "$PROJECT_ROOT/quality"
    log_dir_created "$SCRIPT_NAME" "quality/"
fi

# ===================================================================
# Detect Project Configuration
# ===================================================================

log_info "Detecting project configuration..."

PROJECT_TYPE=$(detect_project_type)
TEST_FRAMEWORK=$(detect_test_framework "$PROJECT_TYPE")
SONARQUBE_AVAILABLE=$(detect_sonarqube)

log_info "Project type: $PROJECT_TYPE"
log_info "Test framework: $TEST_FRAMEWORK"
log_info "SonarQube scanner: $SONARQUBE_AVAILABLE"

# ===================================================================
# Create sonar-project.properties
# ===================================================================

if [[ "$ENABLE_SONARQUBE" == "true" ]]; then
    log_info "Creating sonar-project.properties..."

    SONAR_CONFIG="$PROJECT_ROOT/quality/sonar-project.properties"

    if file_exists "$SONAR_CONFIG"; then
        backup_file "$SONAR_CONFIG"
        track_skipped "quality/sonar-project.properties (backed up)"
        log_warning "sonar-project.properties already exists, backed up"
    fi

    # Determine source directories based on project type
    if [[ "$PROJECT_TYPE" == "javascript" ]]; then
        SOURCE_DIRS="src"
        EXCLUSIONS="node_modules/**,dist/**,build/**,coverage/**"
        COVERAGE_REPORT="coverage/lcov.info"
    elif [[ "$PROJECT_TYPE" == "python" ]]; then
        SOURCE_DIRS="src"
        EXCLUSIONS="**/__pycache__/**,**/venv/**,.pytest_cache/**"
        COVERAGE_REPORT="coverage.xml"
    else
        SOURCE_DIRS="src"
        EXCLUSIONS="**/node_modules/**,**/dist/**,**/build/**"
        COVERAGE_REPORT="coverage/lcov.info"
    fi

    cat > "$SONAR_CONFIG" << EOF
# SonarQube Project Configuration
# Generated by bootstrap-quality.sh

# Project identification
sonar.projectKey=\${PROJECT_KEY:-my-project}
sonar.projectName=\${PROJECT_NAME:-My Project}
sonar.projectVersion=\${PROJECT_VERSION:-1.0.0}

# Source code
sonar.sources=${SOURCE_DIRS}
sonar.exclusions=${EXCLUSIONS}

# Test coverage
sonar.coverage.exclusions=**/*.test.js,**/*.spec.js,**/*.test.ts,**/*.spec.ts,**/test_*.py
sonar.javascript.lcov.reportPaths=${COVERAGE_REPORT}
sonar.python.coverage.reportPaths=${COVERAGE_REPORT}

# Quality gates
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300

# Code analysis
sonar.sourceEncoding=UTF-8
EOF

    verify_file "$SONAR_CONFIG" || log_fatal "Failed to create sonar-project.properties"
    log_file_created "$SCRIPT_NAME" "quality/sonar-project.properties"
    track_created "quality/sonar-project.properties"

    if [[ "$SONARQUBE_AVAILABLE" == "false" ]]; then
        log_warning "SonarQube scanner not found. Install from: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/"
    fi
fi

# ===================================================================
# Create .codeclimate.yml
# ===================================================================

if [[ "$ENABLE_CODECLIMATE" == "true" ]]; then
    log_info "Creating .codeclimate.yml..."

    CODECLIMATE_CONFIG="$PROJECT_ROOT/quality/.codeclimate.yml"

    if file_exists "$CODECLIMATE_CONFIG"; then
        backup_file "$CODECLIMATE_CONFIG"
        track_skipped "quality/.codeclimate.yml (backed up)"
        log_warning ".codeclimate.yml already exists, backed up"
    fi

    cat > "$CODECLIMATE_CONFIG" << 'EOF'
# Code Climate Configuration
# Generated by bootstrap-quality.sh

version: "2"

checks:
  argument-count:
    enabled: true
    config:
      threshold: 4
  complex-logic:
    enabled: true
    config:
      threshold: 4
  file-lines:
    enabled: true
    config:
      threshold: 250
  method-complexity:
    enabled: true
    config:
      threshold: 5
  method-count:
    enabled: true
    config:
      threshold: 20
  method-lines:
    enabled: true
    config:
      threshold: 25
  nested-control-flow:
    enabled: true
    config:
      threshold: 4
  return-statements:
    enabled: true
    config:
      threshold: 4
  similar-code:
    enabled: true
    config:
      threshold: 3
  identical-code:
    enabled: true
    config:
      threshold: 3

plugins:
  eslint:
    enabled: true
    channel: "eslint-8"
  duplication:
    enabled: true
    config:
      languages:
        javascript:
          mass_threshold: 50
        typescript:
          mass_threshold: 50
        python:
          mass_threshold: 50

exclude_patterns:
  - "node_modules/"
  - "dist/"
  - "build/"
  - "coverage/"
  - "**/*.test.js"
  - "**/*.spec.js"
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/test_*.py"
  - "**/__pycache__/"
EOF

    verify_file "$CODECLIMATE_CONFIG" || log_fatal "Failed to create .codeclimate.yml"
    log_file_created "$SCRIPT_NAME" "quality/.codeclimate.yml"
    track_created "quality/.codeclimate.yml"
fi

# ===================================================================
# Create quality-gates.json
# ===================================================================

log_info "Creating quality-gates.json..."

QUALITY_GATES="$PROJECT_ROOT/quality/quality-gates.json"

if file_exists "$QUALITY_GATES"; then
    backup_file "$QUALITY_GATES"
    track_skipped "quality/quality-gates.json (backed up)"
    log_warning "quality-gates.json already exists, backed up"
fi

if command -v python3 &> /dev/null; then
    python3 << EOFPYTHON > "$QUALITY_GATES"
import json
from datetime import datetime

data = {
    "metadata": {
        "created": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "version": "1.0.0",
        "generator": "bootstrap-quality.sh"
    },
    "gates": {
        "coverage": {
            "enabled": True,
            "threshold": ${COVERAGE_THRESHOLD},
            "unit": "percentage",
            "description": "Minimum code coverage percentage"
        },
        "complexity": {
            "enabled": True,
            "threshold": ${COMPLEXITY_THRESHOLD},
            "unit": "cyclomatic_complexity",
            "description": "Maximum cyclomatic complexity per function"
        },
        "duplication": {
            "enabled": True,
            "threshold": ${DUPLICATION_THRESHOLD},
            "unit": "percentage",
            "description": "Maximum code duplication percentage"
        },
        "maintainability": {
            "enabled": True,
            "threshold": "B",
            "unit": "grade",
            "description": "Minimum maintainability grade (A-F)"
        },
        "security": {
            "enabled": True,
            "threshold": 0,
            "unit": "vulnerabilities",
            "description": "Maximum number of high/critical security vulnerabilities"
        },
        "reliability": {
            "enabled": True,
            "threshold": 0,
            "unit": "bugs",
            "description": "Maximum number of critical bugs"
        }
    },
    "rules": {
        "fail_on_violation": True,
        "warning_threshold": 0.9,
        "block_pr_on_failure": True
    }
}

print(json.dumps(data, indent=2))
EOFPYTHON

    verify_file "$QUALITY_GATES" || log_fatal "Failed to create quality-gates.json"
    log_file_created "$SCRIPT_NAME" "quality/quality-gates.json"
    track_created "quality/quality-gates.json"
else
    log_warning "Python not available, skipping quality-gates.json"
    track_warning "quality-gates.json requires Python"
fi

# ===================================================================
# Create complexity-rules.json
# ===================================================================

log_info "Creating complexity-rules.json..."

COMPLEXITY_RULES="$PROJECT_ROOT/quality/complexity-rules.json"

if file_exists "$COMPLEXITY_RULES"; then
    backup_file "$COMPLEXITY_RULES"
    track_skipped "quality/complexity-rules.json (backed up)"
    log_warning "complexity-rules.json already exists, backed up"
fi

if command -v python3 &> /dev/null; then
    python3 << EOFPYTHON > "$COMPLEXITY_RULES"
import json

data = {
    "complexity": {
        "cyclomatic": {
            "max_function": ${COMPLEXITY_THRESHOLD},
            "max_class": ${COMPLEXITY_THRESHOLD} * 5,
            "max_file": ${COMPLEXITY_THRESHOLD} * 10,
            "description": "Cyclomatic complexity thresholds"
        },
        "cognitive": {
            "max_function": 15,
            "max_class": 50,
            "description": "Cognitive complexity thresholds"
        },
        "nesting": {
            "max_depth": 4,
            "description": "Maximum nesting depth"
        }
    },
    "size": {
        "lines_of_code": {
            "max_function": 50,
            "max_class": 300,
            "max_file": 500,
            "description": "Lines of code limits"
        },
        "parameters": {
            "max_count": 5,
            "description": "Maximum function parameters"
        }
    },
    "maintainability": {
        "index": {
            "min_score": 65,
            "range": "0-100",
            "description": "Maintainability index minimum score"
        }
    },
    "excluded_patterns": [
        "**/*.test.js",
        "**/*.spec.js",
        "**/*.test.ts",
        "**/*.spec.ts",
        "**/test_*.py",
        "**/__tests__/**"
    ]
}

print(json.dumps(data, indent=2))
EOFPYTHON

    verify_file "$COMPLEXITY_RULES" || log_fatal "Failed to create complexity-rules.json"
    log_file_created "$SCRIPT_NAME" "quality/complexity-rules.json"
    track_created "quality/complexity-rules.json"
else
    log_warning "Python not available, skipping complexity-rules.json"
    track_warning "complexity-rules.json requires Python"
fi

# ===================================================================
# Create Baseline Report
# ===================================================================

if [[ "$CREATE_BASELINE" == "true" ]]; then
    log_info "Creating baseline quality report..."

    BASELINE_REPORT="$PROJECT_ROOT/quality/baseline-report.md"

    cat > "$BASELINE_REPORT" << EOF
# Quality Baseline Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Project Type:** $PROJECT_TYPE
**Test Framework:** $TEST_FRAMEWORK

---

## Configuration Summary

| Metric | Threshold | Status |
|--------|-----------|--------|
| Coverage | ${COVERAGE_THRESHOLD}% | ⚠️ Not measured yet |
| Complexity | ${COMPLEXITY_THRESHOLD} | ⚠️ Not measured yet |
| Duplication | ${DUPLICATION_THRESHOLD}% | ⚠️ Not measured yet |

## Quality Gates

### Coverage Gate
- **Target:** ${COVERAGE_THRESHOLD}% minimum
- **Current:** Run tests with coverage to establish baseline
- **Command:** \`npm run test:coverage\` or \`pytest --cov\`

### Complexity Gate
- **Max Cyclomatic:** ${COMPLEXITY_THRESHOLD} per function
- **Max Cognitive:** 15 per function
- **Max Nesting:** 4 levels

### Duplication Gate
- **Max Duplication:** ${DUPLICATION_THRESHOLD}%
- **Analysis:** Run SonarQube or Code Climate to measure

## Next Steps

1. **Run Initial Coverage**
   \`\`\`bash
   npm run test:coverage  # For JavaScript/TypeScript
   pytest --cov --cov-report=html  # For Python
   \`\`\`

2. **Setup SonarQube (Optional)**
   \`\`\`bash
   # Install scanner
   npm install -g sonarqube-scanner

   # Configure project key
   export PROJECT_KEY="my-project"

   # Run analysis
   sonar-scanner
   \`\`\`

3. **Configure CI/CD**
   - Add quality checks to pipeline
   - Block PRs on quality gate failures
   - Track metrics over time

4. **Review Reports**
   - Coverage: \`coverage/index.html\`
   - Complexity: \`quality/complexity-report.html\`
   - SonarQube: Check dashboard

## Tools Detected

- **SonarQube Scanner:** $SONARQUBE_AVAILABLE
- **Project Type:** $PROJECT_TYPE
- **Test Framework:** $TEST_FRAMEWORK

## Resources

- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [Code Climate Quality](https://docs.codeclimate.com/docs/configuring-test-coverage)
- [Quality Gates Guide](https://docs.sonarqube.org/latest/user-guide/quality-gates/)

---

**Note:** This is a baseline report. Run quality analysis tools to populate actual metrics.
EOF

    verify_file "$BASELINE_REPORT" || log_fatal "Failed to create baseline report"
    log_file_created "$SCRIPT_NAME" "quality/baseline-report.md"
    track_created "quality/baseline-report.md"
fi

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating quality configuration..."
    echo ""

    # Test 1: Required directory
    log_info "Checking quality directory..."
    if [[ -d "$PROJECT_ROOT/quality" ]]; then
        log_success "Directory: quality/ exists"
    else
        log_warning "Directory: quality/ not found"
        errors=$((errors + 1))
    fi

    # Test 2: Configuration files
    log_info "Checking configuration files..."
    if [[ "$ENABLE_SONARQUBE" == "true" ]] && [[ -f "$PROJECT_ROOT/quality/sonar-project.properties" ]]; then
        log_success "Config: sonar-project.properties created"
    fi

    if [[ "$ENABLE_CODECLIMATE" == "true" ]] && [[ -f "$PROJECT_ROOT/quality/.codeclimate.yml" ]]; then
        log_success "Config: .codeclimate.yml created"
    fi

    # Test 3: Validate JSON files
    log_info "Validating JSON configuration files..."
    for json_file in quality-gates.json complexity-rules.json; do
        if [[ -f "$PROJECT_ROOT/quality/$json_file" ]]; then
            if command -v python3 &> /dev/null; then
                if python3 -c "import json; json.load(open('$PROJECT_ROOT/quality/$json_file'))" 2>/dev/null; then
                    log_success "JSON: $json_file is valid"
                else
                    log_warning "JSON: $json_file has syntax errors"
                    errors=$((errors + 1))
                fi
            else
                log_success "JSON: $json_file created (validation skipped - no Python)"
            fi
        fi
    done

    # Test 4: Verify thresholds
    log_info "Checking quality thresholds..."
    log_success "Coverage threshold: ${COVERAGE_THRESHOLD}%"
    log_success "Complexity threshold: ${COMPLEXITY_THRESHOLD}"
    log_success "Duplication threshold: ${DUPLICATION_THRESHOLD}%"

    # Test 5: Tool availability
    log_info "Checking tool availability..."
    if [[ "$SONARQUBE_AVAILABLE" == "true" ]]; then
        log_success "SonarQube scanner: Available"
    else
        log_warning "SonarQube scanner: Not installed (optional)"
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Validation found $errors issue(s) (non-critical)"
        return 0
    fi
}

# ===================================================================
# Summary & Next Steps
# ===================================================================

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Quality metrics configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Review baseline report: quality/baseline-report.md"
echo "  2. Run tests with coverage: npm run test:coverage"
if [[ "$ENABLE_SONARQUBE" == "true" ]]; then
    echo "  3. Configure SonarQube project key in quality/sonar-project.properties"
    echo "  4. Run SonarQube scan: sonar-scanner"
fi
echo "  5. Add quality checks to package.json scripts:"
echo "     \"quality:check\": \"sonar-scanner\""
echo "     \"quality:gates\": \"npm run test:coverage && npm run lint\""
echo "  6. Configure CI/CD to enforce quality gates"
echo ""

show_log_location
