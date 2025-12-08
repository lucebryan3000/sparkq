# Python Bootstrap Standardization Plan

## Executive Summary

Refactor the sophisticated `__bootbuild/templates/python-bootstrap/` system into a standardized `bootstrap-python.sh` script that integrates seamlessly with the existing 27-script bootstrap ecosystem.

**Status**: APPROVED FOR STANDARDIZATION
**Approach**: Full integration as first-class bootstrap script
**Timeline**: 6-8 hours (can be broken into 2-3 sprints)
**Risk**: LOW (backward compatibility maintained, old system preserved)

---

## Current State: Python Bootstrap System

### Location & Size
- **Path**: `__bootbuild/templates/python-bootstrap/`
- **Core Script**: `bootstrap.sh` (1,748 lines)
- **Total Files**: 10+ files (config, docs, utilities)
- **Status**: Fully functional, battle-tested, sophisticated

### Key Components

#### bootstrap.sh (1,748 lines)
- **5-Phase Execution Model**:
  1. Project Layout Detection
  2. Python Environment Setup
  3. Virtual Environment Management
  4. Dependency Installation
  5. Environment File & Cleanup

- **Smart Features**:
  - Venv reuse detection with detailed info display
  - Python version constraint validation
  - Pyenv integration for missing Python versions
  - Dependency hash-based caching (skips reinstall if unchanged)
  - Manifest-based surgical cleanup
  - Pre/post-install hooks
  - Editable install mode for development

#### Configuration Files
- `python-bootstrap.config` - Project-specific configuration
- `pyproject.toml`, `requirements.txt`, `requirements-dev.txt` - Dependencies
- `.env.example` - Environment template

#### Documentation
- `README.md` - Comprehensive 370+ line guide
- `STOP-ENV-GUIDE.md` - Environment management guide
- Inline comments and phase-based help

#### Utility Scripts
- `stop-env.sh` - Stop venv gracefully
- `kill-python.sh` - Force kill Python processes

---

## The Integration Problem

### Current Issues

1. **Isolation from Bootstrap System**
   - Not in `bootstrap-manifest.json` registry
   - Not in `bootstrap-menu.sh` menu options
   - Users unaware of existence vs. standard bootstrap scripts
   - Separate documentation pathway

2. **Configuration Fragmentation**
   - Custom `python-bootstrap.config` format
   - Different from main `bootstrap.config` philosophy
   - Inconsistent with 27 other scripts
   - Creates "two config systems" confusion

3. **No Library Reuse**
   - Doesn't use `lib/common.sh` functions
   - Duplicates validation logic
   - Duplicates file operations and logging
   - Custom error handling patterns

4. **Inconsistent Patterns**
   - Custom CLI flag parsing (vs. standard approach)
   - Custom logging/output functions
   - Custom cleanup mechanism
   - Doesn't follow 11-step standardized pattern

5. **Documentation Scattered**
   - Separate README.md (not in unified system)
   - Not registered in bootstrap documentation structure
   - Maintenance split between systems

---

## Why This System Deserves Standardization

### Sophistication Assessment

✅ **Enterprise-Grade Features**:
- Smart venv reuse detection (shows Python version, package count, age, size)
- Interactive prompt: [R]euse, [C]lean & recreate, [A]bort
- Python version management with constraint validation
- Dependency hash optimization (SHA256 of config + deps + interpreter)
- Manifest-based tracking for surgical cleanup
- pyenv integration for automatic Python version installation
- Path auto-detection (git root, app directory)
- Pre/post-install hooks for custom setup
- Editable install mode for development workflows
- Environment variable and .gitignore/.claudeignore management

✅ **Well-Documented**:
- 370+ line README with usage scenarios
- 5-phase execution model explained
- Command-line flags documented
- Configuration section detailed
- Real-world workflow examples

✅ **Proven & Stable**:
- Handles edge cases (external paths, missing Python versions, existing venvs)
- Graceful error handling with detailed messages
- Safe cleanup (never deletes user files, only bootstrap-added entries)
- Log rotation with configurable size limits

### Comparison to Other Bootstrap Scripts

| Script | Sophistication | Scope | Status |
|--------|---|---|---|
| bootstrap-docker.sh | Moderate | Container setup | ✅ Standardized |
| bootstrap-kubernetes.sh | Moderate | Orchestration | ✅ Standardized |
| bootstrap-monitoring.sh | Moderate | Observability | ✅ Standardized |
| **python-bootstrap.sh** | **HIGH** | **Venv Management** | ❌ Isolated |

**The python-bootstrap system IS sophisticated enough to be alongside (or exceed) these standardized scripts.**

---

## Standardization Plan

### PHASE 1: Create bootstrap-python.sh (4-6 hours)

**Objective**: Refactor python-bootstrap into standardized format while preserving all features.

#### 1.1 Create Template Script Structure

**File**: `__bootbuild/templates/scripts/bootstrap-python.sh`

```bash
#!/bin/bash

# ===================================================================
# bootstrap-python.sh
#
# Purpose: Python runtime and virtual environment setup
# Creates: .venv/, .env, .bootstrap.hash, .bootstrap.manifest
# Config:  [python] section in bootstrap.config
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-python"

PROJECT_ROOT=$(get_project_root "${1:-.}")
SCRIPT_NAME="bootstrap-python"

# ===================================================================
# Dependency Validation
# ===================================================================

source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

declare_dependencies \
    --tools "python3 git" \
    --scripts "bootstrap-project" \
    --optional "pyenv"

# ===================================================================
# Read Configuration
# ===================================================================

ENABLED=$(config_get "python.enabled" "true")
[[ "$ENABLED" != "true" ]] && { log_info "Python bootstrap disabled"; exit 0; }

PY_VERSION=$(config_get "python.version" "3.11")
VENV_MODE=$(config_get "python.venv_mode" "reuse")
WRITE_ENV=$(config_get "python.write_env" "true")
INSTALL_DEPS=$(config_get "python.install_deps" "true")
MANAGE_GITIGNORE=$(config_get "python.manage_gitignore" "true")

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Python Configuration" \
    ".venv/" ".env" ".bootstrap.hash" ".bootstrap.manifest"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable"

# Validate Python availability
if ! has_command "python3"; then
    log_warning "Python3 not found - will attempt to install via pyenv"
fi

log_success "Environment validated"

# ===================================================================
# Phase 1: Project Layout Detection
# ===================================================================

log_info "Detecting project layout..."

# Auto-detect configuration file
CONFIG_FILE=""
if [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
    CONFIG_FILE="$PROJECT_ROOT/pyproject.toml"
elif [[ -f "$PROJECT_ROOT/setup.py" ]]; then
    CONFIG_FILE="$PROJECT_ROOT/setup.py"
fi

# Auto-detect app directory
APP_DIR="$PROJECT_ROOT"
[[ -d "$PROJECT_ROOT/src" ]] && APP_DIR="$PROJECT_ROOT/src"

log_success "Project layout detected"

# ===================================================================
# Phase 2: Python Environment
# ===================================================================

log_info "Setting up Python environment..."

# Ensure Python version is available
ensure_python_version "$PY_VERSION"

# Detect required Python from pyproject.toml
REQUIRED_PY=$(detect_required_python "$CONFIG_FILE")
if [[ -n "$REQUIRED_PY" ]]; then
    log_info "Detected Python requirement: $REQUIRED_PY"
    validate_python_version "$REQUIRED_PY"
fi

log_success "Python environment ready"

# ===================================================================
# Phase 3: Virtual Environment
# ===================================================================

log_info "Setting up virtual environment..."

VENV_DIR="$PROJECT_ROOT/.venv"

if [[ -d "$VENV_DIR" ]]; then
    log_info "Existing virtual environment found"

    if [[ "$VENV_MODE" == "reuse" ]]; then
        # Display venv info and prompt
        VENV_INFO=$(get_venv_info "$VENV_DIR")

        if ! prompt_reuse_venv "$VENV_DIR" "$VENV_INFO"; then
            # User chose to recreate
            log_info "Removing old virtual environment..."
            rm -rf "$VENV_DIR"
            create_venv "$VENV_DIR" "$PY_VERSION"
        fi
    else
        # Clean mode: recreate
        log_info "Recreating virtual environment (clean mode)..."
        rm -rf "$VENV_DIR"
        create_venv "$VENV_DIR" "$PY_VERSION"
    fi
else
    create_venv "$VENV_DIR" "$PY_VERSION"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

log_success "Virtual environment ready"

# ===================================================================
# Phase 4: Dependency Installation
# ===================================================================

if [[ "$INSTALL_DEPS" == "true" ]]; then
    log_info "Installing dependencies..."

    # Check for dependency changes via hash
    HASH_FILE="$VENV_DIR/.bootstrap.hash"
    CURRENT_HASH=$(calculate_dep_hash "$PROJECT_ROOT" "$CONFIG_FILE")

    if [[ -f "$HASH_FILE" ]]; then
        LAST_HASH=$(<"$HASH_FILE")
        if [[ "$LAST_HASH" == "$CURRENT_HASH" ]]; then
            log_info "Dependencies unchanged; skipping install"
        else
            install_python_deps "$PROJECT_ROOT" "$CONFIG_FILE"
            echo "$CURRENT_HASH" > "$HASH_FILE"
        fi
    else
        install_python_deps "$PROJECT_ROOT" "$CONFIG_FILE"
        echo "$CURRENT_HASH" > "$HASH_FILE"
    fi

    log_success "Dependencies installed"
else
    log_info "Dependency installation disabled"
fi

# ===================================================================
# Phase 5: Environment Setup
# ===================================================================

log_info "Setting up environment files..."

if [[ "$WRITE_ENV" == "true" ]]; then
    write_python_env "$PROJECT_ROOT" "$VENV_DIR" "$CONFIG_FILE"
    log_file_created "$SCRIPT_NAME" ".env"
    track_created ".env"
fi

if [[ "$MANAGE_GITIGNORE" == "true" ]]; then
    ensure_gitignore "$PROJECT_ROOT/.gitignore" ".venv/" ".env" "*.pyc" "__pycache__/"
    log_file_created "$SCRIPT_NAME" ".gitignore"
fi

# Save manifest for cleanup
save_python_manifest "$VENV_DIR" "$VENV_DIR/.bootstrap.manifest"

log_success "Environment setup complete"

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary

echo ""
log_success "Python environment ready!"
echo ""
echo "Next steps:"
echo "  1. Activate venv: source .venv/bin/activate"
echo "  2. Verify installation: python --version"
echo "  3. Run your app: python -m your_module"
echo ""
echo "Venv location: $VENV_DIR"
echo "Python version: $PY_VERSION"
echo ""

show_log_location
```

#### 1.2 Extract Core Functions

Create helper functions for reuse. These will be integrated into the main script or extracted to `lib/python-manager.sh` depending on complexity.

**Key Functions to Implement**:

```bash
# Version Management
detect_required_python(config_file)
validate_python_version(spec)
ensure_python_version(version)
find_python_binary(version)
install_python_with_pyenv(version)

# Virtual Environment
create_venv(venv_dir, py_version)
get_venv_info(venv_dir)
prompt_reuse_venv(venv_dir, venv_info)

# Dependency Management
calculate_dep_hash(project_root, config_file)
install_python_deps(project_root, config_file)
run_pre_install_hook()
run_post_install_hook()

# File Management
write_python_env(project_root, venv_dir, config_file)
save_python_manifest(venv_dir, manifest_path)
remove_python_manifest(venv_dir, manifest_path)
```

#### 1.3 Preserve Special Features

**Venv Reuse Detection**:
- Detect existing `.venv/`
- Display Python version, package count, age, size
- Prompt user: [R]euse, [C]lean, [A]bort
- Auto-reuse with `--yes` flag

**Dependency Hash Optimization**:
- Calculate SHA256 hash of:
  - Config file contents
  - requirements.txt contents
  - pyproject.toml contents
  - Python interpreter path
  - Pip version
- Store in `.bootstrap.hash`
- Skip reinstall if hash unchanged

**Manifest-Based Cleanup**:
- Track what was added (env vars, gitignore entries)
- Surgical removal (only deletes bootstrap-added entries)
- Preserves user's own .env values
- File: `.bootstrap.manifest`

**pyenv Integration**:
- Detect missing Python version
- Auto-install via pyenv if available
- Fall back to system Python
- Respect `requires-python` from pyproject.toml

---

### PHASE 2: Create Configuration & Templates (1 hour)

#### 2.1 Add to bootstrap.config

**File**: `__bootbuild/config/bootstrap.config`

Add new section:

```ini
# ===================================================================
# [python] - Python Runtime and Virtual Environment Setup
# ===================================================================
[python]
enabled=true                    # Enable/disable Python bootstrap
version=3.11                    # Default Python version
venv_mode=reuse                # Mode: reuse|clean|recreate
write_env=true                 # Create .env with PYTHON_VENV, etc.
manage_gitignore=true          # Add .venv/ to .gitignore
manage_claudeignore=true       # Add .venv/ to .claudeignore
install_deps=true              # Install requirements.txt/pyproject.toml
editable_install=false         # Install in editable mode (-e flag)
allow_external_paths=false     # Allow venv outside project root
```

#### 2.2 Create Template Files

**Directory**: `__bootbuild/templates/root/python/`

Create minimal template files:

**`pyproject.toml.template`**:
```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "my-project"
version = "0.0.1"
description = "Python project"
requires-python = ">=3.10"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
]
```

**`requirements.txt.template`**:
```
# Production dependencies
# Add packages here
```

**`requirements-dev.txt.template`**:
```
# Development dependencies
pytest>=7.0
pytest-cov>=4.0
black>=22.0
ruff>=0.1.0
mypy>=0.990
```

#### 2.3 Register in Manifest

**File**: `__bootbuild/config/bootstrap-manifest.json`

Add entry in `scripts` section:

```json
"python": {
  "file": "bootstrap-python.sh",
  "phase": 1,
  "category": "runtime",
  "description": "Python runtime and virtual environment setup (venv, pyenv, pip)",
  "templates": ["python/"],
  "questions": null,
  "detects": ["has_pyproject_toml", "has_requirements_txt"],
  "depends": ["bootstrap-project"]
}
```

---

### PHASE 3: Integrate with Menu & System (1 hour)

#### 3.1 Update bootstrap-menu.sh

**File**: `__bootbuild/scripts/bootstrap-menu.sh`

Add to Phase 1 scripts array (alphabetically):

```bash
declare -a PHASE1_SCRIPTS=(
    "bootstrap-claude.sh"
    "bootstrap-codex.sh"
    "bootstrap-git.sh"
    "bootstrap-nodejs.sh"
    "bootstrap-packages.sh"
    "bootstrap-project.sh"
    "bootstrap-python.sh"        # ← ADD HERE
    "bootstrap-typescript.sh"
    "bootstrap-vscode.sh"
)
```

Update script count documentation if needed.

#### 3.2 Add to Bootstrap Profiles

**File**: `__bootbuild/config/bootstrap.config`

Add to profiles section:

```ini
[profiles]
minimal=claude,git,packages
standard=claude,git,vscode,packages,typescript,environment,linting,editor
full=claude,git,vscode,codex,packages,python,typescript,environment,docker,linting,editor,testing,security,github
api=claude,git,packages,python,typescript,environment,docker,database,testing,security
python-backend=claude,git,packages,python,environment,docker,database,testing,github
python-cli=claude,git,packages,python,environment,testing,github
```

---

### PHASE 4: Testing Strategy (1-2 hours)

#### 4.1 Unit Tests

**Test Script**: `__bootbuild/tests/test-bootstrap-python.sh`

```bash
#!/bin/bash
set -euo pipefail

TEST_DIR="/tmp/test-python-bootstrap"
cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

# Test 1: Basic venv creation
mkdir -p "$TEST_DIR"
BOOTSTRAP_YES=1 bash bootstrap-python.sh "$TEST_DIR"
[[ -d "$TEST_DIR/.venv" ]] || { echo "FAIL: .venv not created"; exit 1; }
[[ -f "$TEST_DIR/.venv/bin/activate" ]] || { echo "FAIL: activate script missing"; exit 1; }
echo "PASS: Basic venv creation"

# Test 2: Dependency installation
cp requirements.txt "$TEST_DIR/"
BOOTSTRAP_YES=1 bash bootstrap-python.sh "$TEST_DIR"
PIP_COUNT=$("$TEST_DIR/.venv/bin/pip" list | wc -l)
[[ $PIP_COUNT -gt 5 ]] || { echo "FAIL: Dependencies not installed"; exit 1; }
echo "PASS: Dependency installation"

# Test 3: Venv reuse detection
BOOTSTRAP_YES=1 bash bootstrap-python.sh "$TEST_DIR"
[[ -d "$TEST_DIR/.venv" ]] || { echo "FAIL: venv removed on second run"; exit 1; }
echo "PASS: Venv reuse"

# Test 4: Environment file
[[ -f "$TEST_DIR/.env" ]] || { echo "FAIL: .env not created"; exit 1; }
grep -q "PYTHON_VENV" "$TEST_DIR/.env" || { echo "FAIL: PYTHON_VENV not in .env"; exit 1; }
echo "PASS: Environment file"

# Test 5: .gitignore management
[[ -f "$TEST_DIR/.gitignore" ]] || { echo "FAIL: .gitignore not created"; exit 1; }
grep -q ".venv/" "$TEST_DIR/.gitignore" || { echo "FAIL: .venv/ not in .gitignore"; exit 1; }
echo "PASS: .gitignore management"

# Test 6: Clean mode
BOOTSTRAP_YES=1 bash bootstrap-python.sh --clean "$TEST_DIR"
[[ ! -d "$TEST_DIR/.venv" ]] || { echo "FAIL: .venv not removed in clean mode"; exit 1; }
echo "PASS: Clean mode"

echo ""
echo "All tests passed!"
```

#### 4.2 Integration Tests

1. **Test with different Python versions**:
   ```bash
   PY_VERSION=3.10 BOOTSTRAP_YES=1 bash bootstrap-python.sh
   PY_VERSION=3.11 BOOTSTRAP_YES=1 bash bootstrap-python.sh
   PY_VERSION=3.12 BOOTSTRAP_YES=1 bash bootstrap-python.sh
   ```

2. **Test with pyproject.toml**:
   ```bash
   mkdir -p /tmp/test-pyproject
   cat > /tmp/test-pyproject/pyproject.toml << 'EOF'
   [project]
   requires-python = ">=3.11"
   EOF
   BOOTSTRAP_YES=1 bash bootstrap-python.sh /tmp/test-pyproject
   ```

3. **Test menu integration**:
   ```bash
   bash __bootbuild/scripts/bootstrap-menu.sh
   # Select option for bootstrap-python.sh
   # Verify it runs without errors
   ```

4. **Test syntax validation**:
   ```bash
   bash -n __bootbuild/templates/scripts/bootstrap-python.sh
   ```

---

### PHASE 5: Documentation & Deprecation (30 minutes)

#### 5.1 Update System Documentation

**File**: `__bootbuild/docs/references/REFERENCE_SCRIPT_CATALOG.md`

Add entry:

```markdown
### bootstrap-python.sh

| Aspect | Detail |
|--------|--------|
| **Purpose** | Python runtime and virtual environment setup |
| **Status** | ✅ Active (standardized) |
| **Dependencies** | bootstrap-project |
| **Runtime** | ~2-5 minutes |
| **Creates** | .venv/, .env, .bootstrap.hash, .bootstrap.manifest |
| **Config** | `[python]` section in bootstrap.config |
| **Location** | `scripts/bootstrap-python.sh` |
| **Features** | Smart venv reuse, pyenv integration, dependency hashing, manifest cleanup |

#### Features

- **Smart Venv Reuse**: Detects existing .venv, shows Python version/packages/age/size, prompts [R]euse/[C]lean/[A]bort
- **Python Version Management**: Respects requires-python from pyproject.toml, auto-installs via pyenv
- **Dependency Optimization**: Hash-based caching skips reinstall if dependencies unchanged
- **Manifest Cleanup**: Surgical removal of bootstrap-added entries, preserves user files
- **Environment Management**: Creates .env with standard variables, manages .gitignore entries

#### Configuration

```ini
[python]
enabled=true                    # Enable/disable
version=3.11                    # Default Python version
venv_mode=reuse                # reuse|clean|recreate existing .venv
write_env=true                 # Create .env file
manage_gitignore=true          # Add .venv/ to .gitignore
install_deps=true              # Install requirements
```

#### Examples

```bash
# Basic setup
BOOTSTRAP_YES=1 bash bootstrap-python.sh

# Clean and recreate
BOOTSTRAP_YES=1 bash bootstrap-python.sh --clean

# Dry run (preview)
bash bootstrap-python.sh --dry-run
```
```

#### 5.2 Deprecation Notice

**File**: `__bootbuild/templates/python-bootstrap/README.md`

Add at the top:

```markdown
# ⚠️ DEPRECATED - Use bootstrap-python.sh Instead

This directory is deprecated. The Python bootstrap functionality has been integrated
into the main bootstrap system as a standardized script.

## What Changed?

The sophisticated python-bootstrap system is now:
- ✅ Integrated into the main bootstrap menu
- ✅ Registered in bootstrap-manifest.json
- ✅ Configured via main bootstrap.config
- ✅ Uses shared lib/common.sh functions
- ✅ Follows standardized 11-step pattern

**All features are preserved** — venv reuse, pyenv integration, dependency hashing,
manifest cleanup, etc.

## Migration Path

### Old System (Deprecated)
```bash
cd __bootbuild/templates/python-bootstrap
./bootstrap.sh
```

### New System (Recommended)
```bash
# From project root:
cd __bootbuild/scripts
bash bootstrap-menu.sh
# Select "python" from Phase 1 options

# Or directly:
bash ../templates/scripts/bootstrap-python.sh
```

### Configuration

**Old** (`__bootbuild/templates/python-bootstrap/python-bootstrap.config`):
```ini
PY_VERSION=3.11
INSTALL_DEPS=true
WRITE_ENV=true
```

**New** (`__bootbuild/config/bootstrap.config`):
```ini
[python]
version=3.11
install_deps=true
write_env=true
```

## Legacy Support

This directory will be maintained for backward compatibility but receive no new features.
Recommend migrating to the integrated `bootstrap-python.sh` for consistency.

## Questions?

See `__bootbuild/docs/references/REFERENCE_SCRIPT_CATALOG.md` for bootstrap-python.sh documentation.
```

---

## Implementation Checklist

### Pre-Implementation
- [ ] Review this plan with team
- [ ] Identify any special features to preserve
- [ ] Set up test environment (/tmp/test-python-bootstrap)
- [ ] Schedule refactoring work

### Phase 1: Script Creation
- [ ] Create `bootstrap-python.sh` template structure
- [ ] Adapt core Python logic from python-bootstrap/bootstrap.sh
- [ ] Implement venv reuse detection
- [ ] Implement dependency hash calculation
- [ ] Implement pyenv integration
- [ ] Implement manifest-based cleanup
- [ ] Add all logging and error handling
- [ ] Validate syntax: `bash -n bootstrap-python.sh`
- [ ] Test core functionality

### Phase 2: Configuration & Templates
- [ ] Add `[python]` section to bootstrap.config
- [ ] Create `templates/root/python/` with template files
- [ ] Add entry to bootstrap-manifest.json
- [ ] Validate JSON: `python3 -c "import json; json.load(open('bootstrap-manifest.json'))"`

### Phase 3: Menu Integration
- [ ] Add to PHASE1_SCRIPTS in bootstrap-menu.sh
- [ ] Update script count documentation
- [ ] Add to bootstrap profiles
- [ ] Test menu appears and selects properly

### Phase 4: Testing
- [ ] Run unit tests (basic venv creation, dependency install, reuse)
- [ ] Test different Python versions
- [ ] Test with pyproject.toml
- [ ] Test menu integration
- [ ] Test syntax validation
- [ ] Test --clean flag
- [ ] Test in CI/CD context

### Phase 5: Documentation & Cleanup
- [ ] Update REFERENCE_SCRIPT_CATALOG.md
- [ ] Add deprecation notice to old python-bootstrap/README.md
- [ ] Update bootstrap system docs to mention Python support
- [ ] Create migration guide for existing users
- [ ] Verify all cross-references updated

### Post-Implementation
- [ ] Announce deprecation of old system
- [ ] Provide migration timeline (e.g., "deprecated for 3 months, then archived")
- [ ] Keep old directory accessible for backward compatibility
- [ ] Monitor for issues and patch as needed

---

## Risk Mitigation

| Risk | Likelihood | Severity | Mitigation |
|------|-----------|----------|-----------|
| Feature loss during refactor | Low | High | Extract all functions carefully, comprehensive testing |
| Broken existing projects | Low | High | Keep old directory, provide migration guide |
| Configuration confusion | Medium | Medium | Clear docs, examples, deprecation notice |
| Performance regression | Low | Medium | Profile and compare with original |
| pyenv integration issues | Low | Medium | Test thoroughly with different Python versions |

---

## Success Criteria

- [ ] ✅ `bootstrap-python.sh` created with feature parity
- [ ] ✅ All bash syntax validation passes
- [ ] ✅ Registered in bootstrap-manifest.json
- [ ] ✅ Appears in bootstrap-menu.sh PHASE1_SCRIPTS
- [ ] ✅ Configuration works from bootstrap.config
- [ ] ✅ All unit tests pass
- [ ] ✅ All integration tests pass
- [ ] ✅ Backward compatibility maintained (old system preserved)
- [ ] ✅ Documentation updated
- [ ] ✅ Team agrees on deprecation timeline

---

## Timeline & Effort Estimate

| Phase | Tasks | Effort | Status |
|-------|-------|--------|--------|
| 1 | Create bootstrap-python.sh | 4-6h | Pending |
| 2 | Config, templates, manifest | 1h | Pending |
| 3 | Menu integration | 1h | Pending |
| 4 | Testing (unit + integration) | 1-2h | Pending |
| 5 | Docs & deprecation | 30m | Pending |
| **TOTAL** | | **6-8h** | **START READY** |

### Sprint Breakdown Option A (Single Sprint)
- Sprint 1: All phases (6-8 hours)

### Sprint Breakdown Option B (Two Sprints)
- Sprint 1: Phases 1-2 (5 hours) - Script creation + config
- Sprint 2: Phases 3-5 (3 hours) - Integration, testing, docs

### Sprint Breakdown Option C (Three Sprints)
- Sprint 1: Phase 1 (4-6 hours) - Script creation
- Sprint 2: Phases 2-3 (2 hours) - Config + menu
- Sprint 3: Phases 4-5 (2 hours) - Testing + docs

---

## Long-term Benefits

### Immediate
- Single unified bootstrap system for users
- Consistent configuration approach
- Python in main menu (discoverable)
- Better maintainability

### Medium-term
- Foundation for standardizing other languages (Go, Rust, Ruby)
- "Polyglot project" bootstrap profiles
- Reduced documentation fragmentation
- Easier to add new Python-specific features

### Long-term
- Enterprise-ready bootstrap system supporting all major languages
- Users can quickly set up projects in any language/stack
- Unified testing and quality standards
- Industry-standard bootstrap approach

---

## Next Steps

1. **Review this plan** - Confirm approach, timeline, priorities
2. **Create Phase 1** - Implement bootstrap-python.sh
3. **Testing** - Comprehensive testing before integration
4. **Integration** - Add to menu, config, manifests
5. **Documentation** - Update guides, add deprecation notice
6. **Release** - Announce standardization, provide migration path

---

## Questions & Clarifications

**Q: Do we need to support the old python-bootstrap.config format?**
A: No. Users will migrate to bootstrap.config. Old directory kept for reference only.

**Q: What about projects currently using python-bootstrap/?**
A: Old directory remains functional indefinitely. Can migrate at their pace with provided migration guide.

**Q: Will we support both systems simultaneously?**
A: Yes, for backward compatibility. Old system marked as deprecated but functional.

**Q: Can we maintain feature parity?**
A: Yes. All features from python-bootstrap (venv reuse, pyenv, hashing, etc.) will be preserved in new script.

**Q: Timeline: Can this be done in one sprint?**
A: Yes, 6-8 hours as a single focused sprint. Can also spread over 2-3 sprints if preferred.

---

## Conclusion

The python-bootstrap system is **sophisticated enough to deserve first-class status** in the bootstrap ecosystem. Standardizing it will:

✅ Improve consistency across bootstrap scripts
✅ Make Python support discoverable to users
✅ Establish pattern for other languages
✅ Simplify maintenance and documentation
✅ Enable powerful "polyglot project" profiles

**Status**: READY TO IMPLEMENT

**Recommendation**: Proceed with Phase 1 immediately.
