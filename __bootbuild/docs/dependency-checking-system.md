# Mandatory Dependency Checking System

**Created**: 2025-12-07
**Status**: Implemented ✅

---

## Overview

The bootstrap system now includes **mandatory dependency validation** that runs before any file operations. Dependencies are declared upfront, validated automatically, and if missing, the system offers auto-installation with user consent.

## Key Components

### 1. `/home/luce/apps/sparkq/__bootbuild/lib/dependency-checker.sh` (494 lines)

Core library providing:
- **Mandatory dependency validation** (non-optional)
- **Version checking** for common tools (node, python3, docker, git, kubectl, helm)
- **Script dependency tracking** via completion markers
- **Auto-install prompting** with user consent
- **Package manager integration** (apt, brew, dnf, yum)
- **Actionable error messages** with installation instructions

### 2. Updated `lib/common.sh`

**Changes:**
1. `log_script_complete()` now creates completion markers:
   ```bash
   # Creates: __bootbuild/logs/.{script_name}.completed
   touch "${BOOTSTRAP_DIR}/logs/.${script_name}.completed"
   ```

2. `pre_execution_confirm()` now displays satisfied dependencies:
   ```bash
   echo "Dependencies satisfied:"
   echo "  Tools: ${_REQUIRED_TOOLS[*]}"
   echo "  Scripts: ${_REQUIRED_SCRIPTS[*]}"
   ```

### 3. Updated Bootstrap Script Template

New dependency validation section added to playbook:
```bash
# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "node:18.0.0:min docker git" \
    --scripts "bootstrap-git bootstrap-project" \
    --optional "redis postgresql"
```

---

## How It Works

### 1. Dependency Declaration

Scripts declare dependencies upfront using `declare_dependencies`:

```bash
declare_dependencies \
    --tools "node:18.0.0:min docker git" \
    --scripts "bootstrap-git" \
    --optional "redis"
```

**Parameters:**
- `--tools`: Required external commands (format: `tool:version:comparison`)
  - `tool` - Command name
  - `version` - Required version (optional)
  - `comparison` - `min` (>=), `max` (<=), or `exact` (==)
  - Example: `"node:18.0.0:min"` means Node.js >= 18.0.0

- `--scripts`: Required bootstrap scripts that must have completed
  - Format: Space-separated script names (without `.sh`)
  - Example: `"bootstrap-git bootstrap-project"`
  - Checks for marker: `__bootbuild/logs/.{script}.completed`

- `--optional`: Optional tools (warnings only, won't fail)
  - Format: Space-separated tool names
  - Example: `"redis postgresql"`

### 2. Validation Process

When `declare_dependencies` is called:

1. **Check Tool Dependencies**
   - Verify each tool exists (`command -v`)
   - Extract current version (tool-specific logic)
   - Compare against required version using `version_satisfies()`
   - Track missing tools in `_MISSING_TOOLS` array
   - Track version failures in `_VERSION_FAILURES` array

2. **Check Script Dependencies**
   - Check for completion marker: `__bootbuild/logs/.{script}.completed`
   - Track missing scripts in `_MISSING_SCRIPTS` array

3. **Validate and Report**
   - If any errors found → display comprehensive error report
   - Show installation instructions for each missing tool
   - For missing scripts → show run order
   - Offer auto-install for supported tools
   - **Fail-fast**: Exit script if dependencies not met

### 3. Auto-Install Flow

If tools are missing and auto-installable:

1. Show list of installable tools
2. Prompt: "Install missing dependencies now? [Y/n]:"
3. If user approves:
   - Call `auto_install_tool()` for each
   - Re-validate after installation
   - Proceed if successful, fail if not

**Supported Auto-Install Tools:**
- `node`, `npm` (via nvm or package manager)
- `pnpm`, `yarn` (via npm)
- `docker` (via package manager + user group)
- `python3`, `pip3` (via package manager)
- `git`, `jq`, `curl` (via package manager)

### 4. Completion Marker Tracking

When a bootstrap script completes successfully:

```bash
log_script_complete "bootstrap-git" "3 files created"
```

This creates:
```
__bootbuild/logs/.bootstrap-git.completed
```

Other scripts can then depend on it:
```bash
declare_dependencies --scripts "bootstrap-git"
```

---

## Usage Examples

### Example 1: Bootstrap Script with No Dependencies

```bash
# bootstrap-project.sh (usually runs first)
declare_dependencies \
    --tools "" \
    --scripts "" \
    --optional ""
```

### Example 2: Bootstrap Script with Tool Dependencies

```bash
# bootstrap-docker.sh
declare_dependencies \
    --tools "docker:20.10.0:min docker-compose" \
    --optional "kubectl helm"
```

### Example 3: Bootstrap Script with Script Dependencies

```bash
# bootstrap-kubernetes.sh
declare_dependencies \
    --tools "kubectl:1.28.0:min helm:3.0.0:min" \
    --scripts "bootstrap-docker bootstrap-project" \
    --optional ""
```

### Example 4: Complex Dependencies

```bash
# bootstrap-nodejs-app.sh
declare_dependencies \
    --tools "node:18.0.0:min git docker" \
    --scripts "bootstrap-git bootstrap-project bootstrap-secrets" \
    --optional "pnpm redis postgresql"
```

---

## Error Messages

### Missing Tools Error

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEPENDENCY ERROR: Missing Required Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✗ node (not installed)
    Install: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
             nvm install --lts
    Or:      https://nodejs.org/

  ✗ docker (not installed)
    Install: https://docs.docker.com/get-docker/
    Linux:   sudo apt-get install docker.io docker-compose

The following tools can be installed automatically:
  • node
  • docker

Install missing dependencies now? [Y/n]:
```

### Version Failure Error

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEPENDENCY ERROR: Version Requirements Not Met
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✗ node: need min 18.0.0, have 16.20.0
```

### Missing Script Dependencies Error

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEPENDENCY ERROR: Required Bootstrap Scripts Not Run
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The following bootstrap scripts must run first:

  ✗ bootstrap-git.sh
  ✗ bootstrap-project.sh

Run missing scripts in order:

  bash __bootbuild/scripts/bootstrap-git.sh
  bash __bootbuild/scripts/bootstrap-project.sh
```

---

## Version Comparison

The system uses `sort -V` for semantic version comparison:

```bash
version_satisfies "18.2.0" "18.0.0" "min"  # Returns 0 (true)
version_satisfies "16.0.0" "18.0.0" "min"  # Returns 1 (false)
version_satisfies "18.2.0" "18.2.0" "exact" # Returns 0 (true)
version_satisfies "20.0.0" "18.0.0" "max"  # Returns 1 (false)
```

**Supported Comparisons:**
- `min`: Current version >= required version
- `max`: Current version <= required version
- `exact`: Current version == required version

**Version Extraction:**
- `node`: `node --version` → strip 'v' prefix
- `python3`: `python3 --version` → extract from output
- `docker`: `docker --version` → extract version number
- `git`: `git --version` → extract version number
- `kubectl`: `kubectl version --client -o json` → parse JSON
- `helm`: `helm version --short` → extract version

---

## Integration with Bootstrap Scripts

### Updated Script Template (playbook)

All new scripts should follow this pattern:

```bash
#!/bin/bash
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize
init_script "bootstrap-{name}"
PROJECT_ROOT=$(get_project_root "${1:-.}")
SCRIPT_NAME="bootstrap-{name}"

# ===================================================================
# DEPENDENCY VALIDATION (MANDATORY)
# ===================================================================

source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

declare_dependencies \
    --tools "tool1:version:min tool2" \
    --scripts "bootstrap-required" \
    --optional "optional-tool"

# ===================================================================
# Rest of script...
# ===================================================================
```

### Checklist Updates

The playbook checklist now includes:

- [x] **Dependency validation: source dependency-checker.sh, declare_dependencies call**
- [x] Validation: require_dir, is_writable (tools now via declare_dependencies)

---

## Testing

### Syntax Validation

All files pass syntax checks:

```bash
✅ bash -n __bootbuild/lib/dependency-checker.sh
✅ bash -n __bootbuild/lib/common.sh
✅ bash -n __bootbuild/templates/scripts/bootstrap-linting.sh
✅ bash -n __bootbuild/templates/scripts/bootstrap-project.sh
```

### Example Test Cases

**Test 1: Missing Tool**
```bash
# Remove node temporarily
mv /usr/bin/node /usr/bin/node.bak
./bootstrap-linting.sh
# Expected: Error with installation instructions + auto-install prompt
```

**Test 2: Version Mismatch**
```bash
# If node 16.x is installed but 18+ required
./bootstrap-nodejs.sh
# Expected: Version failure error
```

**Test 3: Missing Script Dependency**
```bash
# Run kubernetes script without docker script first
./bootstrap-kubernetes.sh
# Expected: Missing script dependency error with run order
```

**Test 4: Successful Validation**
```bash
# All dependencies satisfied
./bootstrap-linting.sh
# Expected: Pre-execution confirmation showing satisfied dependencies
```

---

## Implementation Status

| Component | Status | Lines | File |
|-----------|--------|-------|------|
| Dependency Checker Library | ✅ | 494 | `__bootbuild/lib/dependency-checker.sh` |
| Common.sh Updates | ✅ | +12 | `__bootbuild/lib/common.sh` |
| Playbook Template Update | ✅ | +19 | `docs/playbooks/create-bootstrap-script.md` |
| Example: bootstrap-linting.sh | ✅ | +11 | `templates/scripts/bootstrap-linting.sh` |
| Example: bootstrap-project.sh | ✅ | +11 | `templates/scripts/bootstrap-project.sh` |

**Total Implementation:** 547 lines of new/updated code

---

## Next Steps

### Immediate

1. ✅ Core implementation complete
2. ✅ Playbook documentation updated
3. ✅ Example scripts updated
4. ⏳ **Retroactive updates**: Add dependency declarations to all 21 existing bootstrap scripts

### Future Enhancements

1. **Network Dependency Checking**
   - Check if URLs are reachable (for downloading dependencies)
   - Validate API endpoints are accessible

2. **OS-Specific Dependencies**
   - Detect OS (Linux, macOS, Windows)
   - Declare OS-specific tool requirements

3. **Dependency Graph Visualization**
   - Generate dependency graph: `bootstrap-detect.sh --graph`
   - Show execution order based on dependencies

4. **Cache Dependency Checks**
   - Cache tool version lookups (expensive operations)
   - Invalidate cache periodically or on demand

5. **Custom Version Extractors**
   - Allow scripts to provide custom version extraction logic
   - Support more tools with non-standard version output

---

## Files Modified

```
__bootbuild/lib/dependency-checker.sh          NEW (494 lines)
__bootbuild/lib/common.sh                      MODIFIED (+12 lines)
__bootbuild/docs/playbooks/create-bootstrap-script.md  MODIFIED (+19 lines)
__bootbuild/templates/scripts/bootstrap-linting.sh     MODIFIED (+11 lines)
__bootbuild/templates/scripts/bootstrap-project.sh     MODIFIED (+11 lines)
__bootbuild/docs/dependency-checking-system.md NEW (this file)
```

---

## Design Principles

1. **Mandatory by Default**: Dependencies must be satisfied before proceeding
2. **Fail-Fast**: Stop execution immediately if dependencies not met
3. **User Consent**: Auto-install requires explicit user approval
4. **Actionable Errors**: Every error includes clear installation instructions
5. **Transparent**: Show what dependencies are satisfied before execution
6. **Completion Tracking**: Scripts mark completion for downstream dependencies
7. **Version Awareness**: Support semantic version comparisons
8. **Multi-Platform**: Support apt, brew, dnf, yum package managers

---

**Status**: System implemented and ready for use ✅
**Documentation**: Complete
**Testing**: Syntax validation passed
**Integration**: Template updated, examples provided
