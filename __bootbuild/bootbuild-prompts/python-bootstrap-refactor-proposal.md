# Python Bootstrap Refactor Proposal

## Current State Analysis

The `__bootbuild/templates/python-bootstrap/` directory contains a **standalone, project-specific Python environment bootstrapper** that:

1. **Standalone Nature**: Self-contained in its own directory with its own bootstrap.sh script
2. **Scope**: Specialized for Python venv management (project-level infrastructure)
3. **Architecture**: 1700+ line monolithic bash script with heavy Python integration
4. **Configuration**: Custom `python-bootstrap.config` file (project-specific)
5. **Positioning**: Meant to be run once per Python project to set up `.venv/`
6. **Documentation**: Comprehensive README with 5-phase execution model

### Key Characteristics

✅ **Strengths**:
- Extremely comprehensive (handles pyenv, venv creation, dependency hashing, manifest-based cleanup)
- Self-contained (no dependencies on other bootstrap scripts)
- Intelligent venv reuse detection and smart reinstall logic
- Surgical cleanup (only removes bootstrap-added files/entries)
- Well-documented with clear 5-phase execution model
- Handles complex scenarios (external venv paths, editable installs, pre/post hooks)

❌ **Problems with Current Location**:
- Isolated from the main bootstrap system (27 scripts in `templates/scripts/`)
- Custom config format (`python-bootstrap.config` vs `bootstrap.config`)
- Not integrated with manifest registry (separate from bootstrap-manifest.json)
- Separate documentation flow (README.md, STOP-ENV-GUIDE.md vs unified docs)
- Not listed in bootstrap-menu.sh or phase arrays
- Duplication: Bootstrap-linting.sh does similar validation/cleanup
- No integration with `lib/common.sh` functions

---

## Refactoring Strategy

### Option 1: **Elevate as First-Class Python Script** (RECOMMENDED)

Convert python-bootstrap into `bootstrap-python.sh` following the standardized pattern.

#### Approach:

1. **Create `bootstrap-python.sh`** in `templates/scripts/`
   - Extract core python-venv setup logic
   - Refactor to use `lib/common.sh` functions
   - Implement dependency-checker.sh for tool validation
   - Keep specialized Python logic (pyenv, venv smart-reuse)

2. **Register in bootstrap-manifest.json**
   ```json
   "python": {
     "file": "bootstrap-python.sh",
     "phase": 1,
     "category": "runtime",
     "description": "Python runtime and virtual environment setup (venv, pyenv, pip)",
     "templates": ["python/"],
     "questions": null,
     "detects": ["has_pyproject_toml", "has_requirements_txt"],
     "depends": []
   }
   ```

3. **Create `templates/root/python/`** for template files:
   - `pyproject.toml` (stub template)
   - `requirements.txt` (stub template)
   - `requirements-dev.txt` (stub template)
   - `.pyvenv.cfg` (venv config template)

4. **Add to bootstrap-menu.sh**
   - Phase 1 array
   - Integrated with standard menu workflow

5. **Consolidate configuration**
   - Merge python-specific settings into main `bootstrap.config`
   - Remove duplicate config section

6. **Deprecate python-bootstrap/ directory**
   - Keep for backward compatibility (with deprecation notice)
   - Document migration path for existing projects

#### Advantages:
- ✅ Standardized pattern (matches other 27 scripts)
- ✅ Integrated with main bootstrap system
- ✅ Can be selected from unified menu
- ✅ Reuses common library functions
- ✅ Unified configuration
- ✅ Easier to maintain and extend
- ✅ Can be used in bootstrap profiles (e.g., "api", "full")

#### Disadvantages:
- ⚠️ Must preserve all specialized Python logic (venv reuse, pyenv, dependency hashing)
- ⚠️ Refactoring effort (~4-6 hours to maintain feature parity)
- ⚠️ Backward compatibility concerns with existing python-bootstrap configs

---

### Option 2: **Keep as Specialized Subsystem** (ALTERNATIVE)

Leave python-bootstrap isolated but document it as an optional supplementary tool.

#### Approach:

1. **Rename**: `python-bootstrap/` → `addons/python-bootstrap/` (signals optional nature)

2. **Add integration bridge**: Create `bootstrap-python-addon.sh`
   - Thin wrapper in `templates/scripts/`
   - Calls through to `addons/python-bootstrap/bootstrap.sh`
   - Integrates with main bootstrap menu
   - Allows configuration from main `bootstrap.config`

3. **Document relationship**:
   - Main bootstrap: Node.js/TypeScript/frontend setup
   - Python addon: Deep Python venv management (optional)

4. **For profiles**: Add "python-project" profile
   ```ini
   [profiles]
   python-project=claude,git,packages,python-addon
   ```

#### Advantages:
- ✅ No refactoring needed (preserve specialized code)
- ✅ Clear separation: "standard bootstrap" vs "Python specialization"
- ✅ Lower risk of breaking existing logic

#### Disadvantages:
- ❌ Maintains two separate systems (confusing)
- ❌ Configuration duplication
- ❌ Users must understand this is "optional addon"
- ❌ Doesn't improve consistency of bootstrap system

---

### Option 3: **Extract as Shared Library** (HYBRID)

Keep python-bootstrap independent but extract reusable functions into `lib/python-manager.sh`.

#### Approach:

1. **Create `lib/python-manager.sh`** with functions:
   - `python_version_check()`
   - `ensure_python()`
   - `create_venv()`
   - `prompt_venv_reuse()`
   - `calculate_dep_hash()`
   - `install_dependencies()`
   - `save_manifest()`
   - `remove_manifest()`

2. **Use in both places**:
   - `bootstrap-python.sh` (standardized script) → uses lib/python-manager.sh
   - `python-bootstrap/bootstrap.sh` (specialized tool) → uses lib/python-manager.sh

3. **Reduces duplication** while keeping both separate

#### Advantages:
- ✅ DRY principle (shared functions)
- ✅ Both systems benefit from improvements
- ✅ Flexibility: users can use either system

#### Disadvantages:
- ⚠️ Still maintains two entry points (confusion)
- ⚠️ Requires careful API design for library functions

---

## Recommendation: **Option 1 (Elevate as First-Class Script)**

### Rationale:

1. **System Maturity**: The python-bootstrap is sophisticated and battle-tested—worthy of first-class status
2. **Consistency**: Brings Python support in line with Node.js, TypeScript, Docker, etc.
3. **User Experience**: Single unified menu and configuration system
4. **Maintainability**: One codebase to maintain, shared library functions
5. **Ecosystem**: Can be part of bootstrap profiles ("python-api", "python-ml", etc.)
6. **Long-term**: Sets better precedent for adding other language/runtime support

---

## Implementation Plan: Option 1

### Phase 1: Create standardized bootstrap-python.sh

**Effort**: 4-6 hours

1. Create stub `bootstrap-python.sh` following standardized pattern
2. Adapt core Python logic from `python-bootstrap/bootstrap.sh`:
   - Python version detection/installation
   - Virtual environment creation with smart reuse
   - Dependency installation with hash-based optimization
   - .env and .gitignore management
3. Use `lib/common.sh` functions where applicable
4. Add dependency validation via `dependency-checker.sh`
5. Preserve all specialized Python features

**Key sections**:
```bash
#!/bin/bash
# Header + documentation

set -euo pipefail

# Setup (paths, library sourcing)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"  # NEW for tool validation

# Dependency validation
declare_dependencies \
    --tools "python3 git" \
    --scripts "bootstrap-project" \
    --optional "pyenv"

# Configuration reading
PYTHON_VERSION=$(config_get "python.version" "3.11")
VENV_MODE=$(config_get "python.venv_mode" "reuse")  # reuse|clean|recreate

# Pre-execution confirmation
pre_execution_confirm "$SCRIPT_NAME" "Python Configuration" \
    ".venv/" ".env" ".gitignore" ".bootstrap.hash"

# Validation (use library functions)
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable"

# Core Python logic (from python-bootstrap/bootstrap.sh)
# - detect_required_python()
# - ensure_python()
# - create_venv()
# - get_venv_info()
# - prompt_reuse_venv()
# - calculate_dep_hash()
# - install_dependencies()
# - write_env_file()
# - save_deployment_manifest()

# Summary
log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"
show_summary
show_log_location
```

### Phase 2: Create template files

**Effort**: 30 minutes

Create `templates/root/python/`:
- `pyproject.toml.template` → minimum valid pyproject.toml
- `requirements.txt` → stub with common packages
- `requirements-dev.txt` → development dependencies

### Phase 3: Register in manifest

**Effort**: 15 minutes

Update `bootstrap-manifest.json`:
```json
"python": {
  "file": "bootstrap-python.sh",
  "phase": 1,
  "category": "runtime",
  "description": "Python runtime and virtual environment setup (venv, pyenv, pip)",
  "templates": ["python/"],
  "questions": null,
  "detects": ["has_pyproject_toml", "has_requirements_txt"],
  "depends": []
}
```

### Phase 4: Update bootstrap-menu.sh

**Effort**: 15 minutes

Add to Phase 1 array (alphabetically):
```bash
declare -a PHASE1_SCRIPTS=(
    "bootstrap-claude.sh"
    "bootstrap-codex.sh"
    "bootstrap-git.sh"
    "bootstrap-nodejs.sh"
    "bootstrap-packages.sh"
    "bootstrap-project.sh"
    "bootstrap-python.sh"    # ADD HERE
    ...
)
```

### Phase 5: Update bootstrap.config

**Effort**: 15 minutes

Add Python section:
```ini
# ===================================================================
# [python] - Python Runtime and Virtual Environment
# ===================================================================
[python]
enabled=true                    # Enable/disable Python bootstrap
version=3.11                    # Required Python version
venv_mode=reuse                # reuse|clean|recreate on existing .venv
pyenv_install=true            # Use pyenv to install missing versions
write_env=true                 # Create .env file
manage_gitignore=true          # Add .venv/ to .gitignore
manage_claudeignore=true       # Add .venv/ to .claudeignore
install_deps=true              # Install requirements.txt/pyproject.toml
editable_install=false         # Install in editable mode for development
```

### Phase 6: Deprecate old python-bootstrap/

**Effort**: 15 minutes

Add deprecation notice to `python-bootstrap/README.md`:

```markdown
# ⚠️ DEPRECATED

**This directory is deprecated.** The Python bootstrap functionality has been
integrated into the main bootstrap system as `bootstrap-python.sh`.

## Migration

To use the new system:

1. The new `bootstrap-python.sh` is part of the standardized bootstrap menu
2. Configuration is now in `__bootbuild/config/bootstrap.config` (section [python])
3. All features from this directory are preserved in the new script

## Legacy Support

This directory will be maintained for backward compatibility, but new projects
should use the integrated `bootstrap-python.sh` instead.
```

### Phase 7: Testing

**Effort**: 1-2 hours

1. Create test Python project in `/tmp/test-python/`
2. Run `BOOTSTRAP_YES=1 bash bootstrap-python.sh /tmp/test-python`
3. Verify:
   - ✅ .venv created
   - ✅ Dependencies installed
   - ✅ .env file written
   - ✅ .gitignore updated
   - ✅ manifest created
4. Test venv reuse (run again, verify no reinstall)
5. Test --clean flag
6. Test menu integration
7. Test different Python versions

---

## Timeline

**Total estimated effort: 6-8 hours**

- Phase 1 (Python script): 4-6 hours
- Phase 2 (Templates): 30 min
- Phase 3 (Manifest): 15 min
- Phase 4 (Menu): 15 min
- Phase 5 (Config): 15 min
- Phase 6 (Deprecation): 15 min
- Phase 7 (Testing): 1-2 hours

Could be split into:
- Sprint 1: Create bootstrap-python.sh (Phase 1)
- Sprint 2: Integration (Phases 2-6)
- Sprint 3: Testing & refinement (Phase 7)

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Break existing Python projects | Low | High | Keep old directory, provide migration guide |
| Lose specialized features | Low | High | Comprehensive unit tests before release |
| Configuration confusion | Medium | Medium | Clear documentation, examples |
| Performance regression | Low | Low | Profile and compare with original |

---

## Success Criteria

- [ ] `bootstrap-python.sh` passes bash syntax validation
- [ ] All tests pass (venv creation, dependency install, cleanup)
- [ ] Can be selected from bootstrap menu
- [ ] Configuration works from `bootstrap.config`
- [ ] Feature parity with original `python-bootstrap/bootstrap.sh`
- [ ] Documentation updated
- [ ] Old system marked as deprecated

---

## Long-term Benefits

1. **Consistency**: All bootstrap scripts follow same pattern
2. **Maintainability**: Easier to find and fix issues
3. **Extensibility**: Can add Python-specific profiles to bootstrap system
4. **Discoverability**: Users find Python support from main menu
5. **Consolidation**: One configuration file, one manifest registry
6. **Ecosystem**: Sets precedent for supporting other languages (Go, Rust, Ruby, etc.)

---

## Questions for User

1. **Which option do you prefer?** (Option 1: Elevate, Option 2: Keep Isolated, Option 3: Extract Library)
2. **Timeline preference?** (Do in one sprint vs. three sprints)
3. **Backward compatibility important?** (Keep old directory vs. full migration)
4. **Should this block other work?** (Or run in parallel)
5. **Testing environment available?** (For comprehensive testing before release)
