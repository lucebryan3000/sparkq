# Bootstrap Template Implementation Playbook

> **Purpose**: Define a repeatable, systematic process for creating bootstrap scripts for all template categories in `___NEW PROJ TEMPLATES____/`
>
> **Author**: Bryan Luce
> **Version**: 1.0
> **Last Updated**: 2025-12-07

---

## Table of Contents

1. [Overview](#overview)
2. [Template Categories](#template-categories)
3. [Playbook Phases](#playbook-phases)
4. [Process Flow](#process-flow)
5. [Implementation Checklist](#implementation-checklist)
6. [Validation Criteria](#validation-criteria)
7. [Script Template](#script-template)
8. [Example Applications](#example-applications)

---

## Overview

### Problem Statement

When creating a new project, developers need to:
- Copy configuration files from templates
- Adapt them to the new project
- Set up directory structures
- Configure permissions and settings
- Validate everything works

Currently this is manual and error-prone. **Solution**: Create automated bootstrap scripts for each template category that follow a standard pattern.

### Solution Architecture

Each template category (`.claude/`, `.github/`, `.vscode/`, etc.) gets:

1. **Template Source Files** - Located in `___NEW PROJ TEMPLATES____/[category]/`
2. **Bootstrap Script** - Located in `___NEW PROJ TEMPLATES____/scripts/bootstrap-[category].sh`
3. **Validation Function** - Built into bootstrap script (Self-Testing Protocol)
4. **Documentation** - README in target directory explaining usage

### Key Principles

- **Source of Truth**: Template files in `___NEW PROJ TEMPLATES____/[category]/` are authoritative
- **Idempotent**: Scripts can run multiple times safely
- **Self-Validating**: Built-in checks ensure successful bootstrap
- **Documented**: Each script includes clear next steps
- **Reusable**: Same pattern applies to all categories

---

## Template Categories

### Category 1: Claude Code Configuration (✅ COMPLETE)

**Location**: `___NEW PROJ TEMPLATES____/.claude/`

**Bootstrap Script**: `___NEW PROJ TEMPLATES____/scripts/bootstrap-claude.sh`

**Source Files**:
- `codex.md` - Codex command guide
- `codex_prompt.md` - Codex prompt generator
- `codex-optimization.md` - Token optimization playbook
- `haiku.md` - Haiku model usage guide
- `self-testing-protocol.md` - Self-testing guidelines

**Target Structure**:
```
.claude/
├── agents/
│   ├── code-reviewer.md
│   └── debugger.md
├── commands/
│   ├── analyze.md
│   ├── test.md
│   └── document.md
├── hooks/
├── skills/
├── settings.json
├── settings.local.json.example
├── README.md
├── codex.md
├── codex_prompt.md
├── codex-optimization.md
├── haiku.md
└── self-testing-protocol.md
```

**Status**: ✅ Complete with validation

---

### Category 2: GitHub Configuration (📋 PLANNED)

**Location**: `___NEW PROJ TEMPLATES____/.github/`

**Bootstrap Script**: `___NEW PROJ TEMPLATES____/scripts/bootstrap-github.sh` (TO CREATE)

**Source Files**:
- `PULL_REQUEST_TEMPLATE.md`
- `ISSUE_TEMPLATE/bug_report.md`
- `ISSUE_TEMPLATE/feature_request.md`
- `ISSUE_TEMPLATE/config.yml`
- `workflows/ci.yml`

**Target Structure**:
```
.github/
├── PULL_REQUEST_TEMPLATE.md
├── ISSUE_TEMPLATE/
│   ├── bug_report.md
│   ├── feature_request.md
│   └── config.yml
└── workflows/
    └── ci.yml
```

**Status**: 📋 Planned

---

### Category 3: VS Code Configuration (📋 PLANNED)

**Location**: `___NEW PROJ TEMPLATES____/.vscode/`

**Bootstrap Script**: `___NEW PROJ TEMPLATES____/scripts/bootstrap-vscode.sh` (TO CREATE)

**Source Files**:
- `settings.json`
- `extensions.json`
- `launch.json`
- `tasks.json`
- `snippets/typescript.json`

**Target Structure**:
```
.vscode/
├── settings.json
├── extensions.json
├── launch.json
├── tasks.json
├── snippets/
│   └── typescript.json
└── optional/
    └── [user-specific files]
```

**Status**: 📋 Planned

---

### Category 4: DevContainer Configuration (📋 PLANNED)

**Location**: `___NEW PROJ TEMPLATES____/.devcontainer/`

**Bootstrap Script**: `___NEW PROJ TEMPLATES____/scripts/bootstrap-devcontainer.sh` (TO CREATE)

**Source Files**:
- `devcontainer.json`
- `Dockerfile`

**Target Structure**:
```
.devcontainer/
├── devcontainer.json
└── Dockerfile
```

**Status**: 📋 Planned

---

### Category 5: Root-Level Configuration (📋 PLANNED)

**Location**: `___NEW PROJ TEMPLATES____/root/`

**Bootstrap Script**: `___NEW PROJ TEMPLATES____/scripts/bootstrap-root.sh` (TO CREATE)

**Source Files**:
- `.editorconfig`
- `.gitignore`
- `.gitattributes`
- `.prettierrc.json`
- `.eslintrc.json`
- `.npmrc`
- `.nvmrc`
- `package.json`
- `tsconfig.json`
- `jest.config.js`
- (and others as needed)

**Target Structure**: Files copied to project root

**Status**: 📋 Planned

---

## Playbook Phases

### Phase 1: Template Analysis

**Goal**: Understand the template structure and dependencies

**Steps**:

1. **Identify Template Location**
   ```bash
   Template root: ___NEW PROJ TEMPLATES____/[CATEGORY]/
   ```

2. **Inventory Template Files**
   - List all files in template directory
   - Identify file types (configs, docs, scripts)
   - Note dependencies between files

3. **Document Structure**
   - Note directory hierarchy
   - Identify which files are required vs optional
   - Check for nested directories

4. **Read Key Documentation**
   - Read any README or documentation in the template
   - Understand purpose of each file
   - Note any special configuration needs

**Deliverable**: List of template files and target locations

---

### Phase 2: Bootstrap Script Design

**Goal**: Design the bootstrap script structure

**Steps**:

1. **Identify Script Scope**
   - What files to copy?
   - What directories to create?
   - What configuration changes needed?
   - What validation is required?

2. **Design Directory Creation**
   - Which directories are required?
   - Which directories are optional?
   - What permissions needed?

3. **Design File Copying**
   - Which files copy as-is?
   - Which files need templating (variable substitution)?
   - What about JSON/YAML validation?

4. **Design Validation**
   - File existence checks
   - JSON/YAML syntax validation (Haiku-style)
   - Directory structure verification
   - Content validation (YAML frontmatter, etc.)
   - Special format checks

5. **Design Output**
   - Success/error reporting
   - Summary of what was created
   - Clear next steps for user

**Deliverable**: Script design document

---

### Phase 3: Bootstrap Script Implementation

**Goal**: Create working bootstrap script

**Steps**:

1. **Create Script File**
   ```bash
   ___NEW PROJ TEMPLATES____/scripts/bootstrap-[category].sh
   ```

2. **Implement Core Sections**
   - Shebang and documentation
   - Configuration and variables
   - Utility functions (log_info, log_success, log_error, log_warning)
   - Validation section
   - Directory creation
   - File copying/generation
   - Validation function
   - Summary and next steps

3. **Add Error Handling**
   - Check for required directories/files
   - Validate input parameters
   - Handle missing prerequisites
   - Provide clear error messages

4. **Add Color Output**
   - Blue (→) for info
   - Green (✓) for success
   - Yellow (⚠) for warnings
   - Red (✗) for errors

5. **Make Executable**
   ```bash
   chmod +x bootstrap-[category].sh
   ```

**Deliverable**: Working bootstrap script

---

### Phase 4: Validation Implementation

**Goal**: Add comprehensive self-testing

**Steps**:

1. **Create validate_bootstrap() Function**
   - Separate validation from creation
   - Callable after bootstrap completes
   - Returns 0 on success, 1 on failure

2. **Test Directory Structure**
   - Check all required directories exist
   - Verify permissions if needed

3. **Test File Existence**
   - Check all required files exist
   - Check file sizes (basic sanity check)

4. **Test File Format**
   - JSON validation: `python3 -m json.tool`
   - YAML validation: `python3 -c "import yaml; yaml.safe_load(open(...)"`
   - Shell validation: `bash -n`
   - YAML frontmatter: grep checks

5. **Test Special Content**
   - YAML frontmatter in markdown files
   - Required fields in config files
   - Valid JSON structure

6. **Report Results**
   - Count pass/fail
   - Report specific failures
   - Suggest corrections if possible

**Deliverable**: Validation function integrated into script

---

### Phase 5: Testing & Documentation

**Goal**: Verify script works and document usage

**Steps**:

1. **Test in Clean Environment**
   ```bash
   mkdir /tmp/test-bootstrap-[category]
   cd /tmp/test-bootstrap-[category]
   /path/to/bootstrap-[category].sh .
   ```

2. **Verify Output**
   - All files created correctly
   - All directories exist
   - Validation passes
   - Error messages clear

3. **Create README**
   - Usage instructions
   - What it creates
   - Next steps
   - Troubleshooting

4. **Add Script Documentation**
   - Header comments
   - Function documentation
   - Inline comments for complex logic

**Deliverable**: Tested script + documentation

---

### Phase 6: Commit & Integration

**Goal**: Commit script and update documentation

**Steps**:

1. **Stage Files**
   ```bash
   git add ___NEW PROJ TEMPLATES____/scripts/bootstrap-[category].sh
   ```

2. **Commit with Context**
   - Describe what category
   - List source files copied
   - Note validation features
   - Reference this playbook

3. **Update Playbooks**
   - Mark category as ✅ Complete
   - Update status section

4. **Document Process**
   - Add to playbook for future reference

**Deliverable**: Committed bootstrap script

---

## Process Flow

```
START
  ↓
Phase 1: Template Analysis
  - Identify template files
  - Document structure
  - List dependencies
  ↓
Phase 2: Script Design
  - Plan directory creation
  - Design file copying logic
  - Design validation approach
  ↓
Phase 3: Implementation
  - Create bootstrap script
  - Implement all sections
  - Add error handling
  ↓
Phase 4: Validation
  - Add validation function
  - Test each component
  - Report results
  ↓
Phase 5: Testing
  - Test in clean env
  - Verify all files
  - Document usage
  ↓
Phase 6: Commit
  - Stage and commit
  - Update playbook
  ↓
END (Ready for next category)
```

---

## Implementation Checklist

For each bootstrap script, verify:

### Phase 1: Analysis
- [ ] Located template directory
- [ ] Listed all template files
- [ ] Documented directory structure
- [ ] Identified file types
- [ ] Noted dependencies

### Phase 2: Design
- [ ] Identified scope
- [ ] Designed directory creation
- [ ] Designed file copying
- [ ] Designed validation approach
- [ ] Planned output/reporting

### Phase 3: Implementation
- [ ] Created script file with shebang
- [ ] Added configuration variables
- [ ] Implemented utility functions
- [ ] Added validation section
- [ ] Implemented directory creation
- [ ] Implemented file copying/generation
- [ ] Integrated validation function
- [ ] Added summary and next steps
- [ ] Made script executable

### Phase 4: Validation
- [ ] Created validate_bootstrap() function
- [ ] Tests directory structure
- [ ] Tests file existence
- [ ] Tests JSON syntax
- [ ] Tests YAML syntax
- [ ] Tests special content (frontmatter, etc.)
- [ ] Reports results clearly
- [ ] Returns proper exit codes

### Phase 5: Testing
- [ ] Tested in clean environment
- [ ] Verified all files created
- [ ] Verified all directories created
- [ ] Validation passes
- [ ] Error messages clear
- [ ] Created documentation

### Phase 6: Commit
- [ ] Staged bootstrap script
- [ ] Created informative commit message
- [ ] Updated playbook status
- [ ] Pushed to repository

---

## Validation Criteria

Every bootstrap script MUST have:

### Minimum File Checks
```bash
# Directory existence
[[ -d "$TARGET_DIR/$subdir" ]]

# File existence
[[ -f "$TARGET_DIR/$file" ]]

# File not empty
[[ -s "$TARGET_DIR/$file" ]]
```

### JSON Validation
```bash
python3 -m json.tool "$file" >/dev/null 2>&1
```

### YAML Validation
```bash
python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
```

### Shell Syntax Validation
```bash
bash -n "$file"
```

### YAML Frontmatter Check
```bash
grep -q "^---" "$file" && grep -q "^---" <(tail -n +2 "$file")
```

### Error Handling
```bash
if [[ $errors -eq 0 ]]; then
    log_success "All checks passed!"
    return 0
else
    log_error "Found $errors error(s)"
    return 1
fi
```

---

## Script Template

```bash
#!/bin/bash

# ===================================================================
# bootstrap-[CATEGORY].sh
#
# Bootstrap [CATEGORY] configuration for a new project
# Pulls from ___NEW PROJ TEMPLATES____/[CATEGORY]/ and creates complete
# directory structure per project standards
# ===================================================================

set -e

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"
TARGET_DIR="${PROJECT_ROOT}/[TARGET_PATH]"
TEMPLATE_SOURCE="${TEMPLATE_DIR}/[SOURCE_PATH]"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===================================================================
# Utility Functions
# ===================================================================

log_info() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping [CATEGORY] configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

if [[ ! -d "$TEMPLATE_SOURCE" ]]; then
    log_error "Template directory not found: $TEMPLATE_SOURCE"
fi

# ===================================================================
# Create Directory Structure
# ===================================================================

log_info "Creating directory structure..."
mkdir -p "$TARGET_DIR"/{subdir1,subdir2}
log_success "Directory structure created"

# ===================================================================
# Copy/Create Files
# ===================================================================

log_info "Setting up configuration files..."

if [[ -f "$TEMPLATE_SOURCE/file1.json" ]]; then
    cp "$TEMPLATE_SOURCE/file1.json" "$TARGET_DIR/"
    log_success "Copied file1.json"
fi

# ... more file copying ...

# ===================================================================
# Validation & Testing
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Directory structure
    log_info "Checking directory structure..."
    for dir in subdir1 subdir2; do
        if [[ -d "$TARGET_DIR/$dir" ]]; then
            log_success "Directory: $dir exists"
        else
            log_error "Missing directory: $dir"
            errors=$((errors + 1))
        fi
    done

    # Test 2: File validation
    log_info "Checking files..."
    for file in file1.json file2.md; do
        if [[ -f "$TARGET_DIR/$file" ]]; then
            log_success "File: $file exists"
        else
            log_error "Missing file: $file"
            errors=$((errors + 1))
        fi
    done

    # Test 3: JSON validation
    log_info "Validating JSON..."
    if python3 -m json.tool "$TARGET_DIR/file1.json" >/dev/null 2>&1; then
        log_success "JSON: file1.json is valid"
    else
        log_error "Invalid JSON in file1.json"
        errors=$((errors + 1))
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_error "Validation found $errors error(s)"
        return 1
    fi
}

# ===================================================================
# Summary & Next Steps
# ===================================================================

echo ""
log_success "Bootstrap complete!"
echo ""

validate_bootstrap

echo ""
log_info "Bootstrap Summary:"
echo "  [Summary of what was created]"
echo ""

log_info "Next steps:"
echo "  1. [First action]"
echo "  2. [Second action]"
echo "  3. [Third action]"
echo ""
```

---

## Example Applications

### Example 1: Bootstrap Claude Code (✅ COMPLETE)

**Command**:
```bash
___NEW PROJ TEMPLATES____/scripts/bootstrap-claude.sh /path/to/project
```

**What It Does**:
- Creates `.claude/` directory with agents/, commands/, hooks/, skills/
- Copies 5 template files (codex, haiku, self-testing-protocol, etc.)
- Generates 2 example agents (code-reviewer, debugger)
- Generates 3 example commands (analyze, test, document)
- Creates settings.json with Sonnet model and hooks
- Creates .mcp.json, .claudeignore, CLAUDE.md, README.md
- Validates all files (JSON syntax, YAML frontmatter, existence)

**Test Result**:
✅ All 16+ validation checks pass

---

### Example 2: Bootstrap GitHub (📋 PLANNED)

**Expected Command**:
```bash
___NEW PROJ TEMPLATES____/scripts/bootstrap-github.sh /path/to/project
```

**Expected Behavior**:
- Creates `.github/` directory
- Copies PR template
- Copies issue templates (bug, feature, custom)
- Copies CI workflow
- Validates YAML syntax for workflows
- Validates markdown format for templates
- Creates documentation

---

### Example 3: Bootstrap VS Code (📋 PLANNED)

**Expected Command**:
```bash
___NEW PROJ TEMPLATES____/scripts/bootstrap-vscode.sh /path/to/project
```

**Expected Behavior**:
- Creates `.vscode/` directory
- Copies settings.json with recommended configuration
- Copies extensions.json with recommended extensions
- Copies launch.json with debug configurations
- Copies tasks.json with common tasks
- Copies snippets/typescript.json
- Validates JSON syntax for all config files
- Creates documentation

---

## Using This Playbook

### For Claude Code:

When implementing a new bootstrap script, follow the phases in order:

1. **Read Phase 1 & 2** - Understand what needs to be done
2. **Implement Phase 3** - Create the script
3. **Add Phase 4** - Implement validation
4. **Test Phase 5** - Verify it works
5. **Commit Phase 6** - Stage and push

### For Users:

After a bootstrap script is created, users can:

```bash
# Bootstrap a category
___NEW PROJ TEMPLATES____/scripts/bootstrap-[category].sh /path/to/new/project

# The script will:
# 1. Create required directories
# 2. Copy template files
# 3. Validate everything
# 4. Show clear next steps
```

---

## Quick Reference

| Category | Status | Script | Source | Target |
|----------|--------|--------|--------|--------|
| Claude Code | ✅ Complete | `bootstrap-claude.sh` | `.claude/` | `.claude/` |
| GitHub | 📋 Planned | `bootstrap-github.sh` | `.github/` | `.github/` |
| VS Code | 📋 Planned | `bootstrap-vscode.sh` | `.vscode/` | `.vscode/` |
| DevContainer | 📋 Planned | `bootstrap-devcontainer.sh` | `.devcontainer/` | `.devcontainer/` |
| Root Config | 📋 Planned | `bootstrap-root.sh` | `root/` | `./` |

---

## Contributing

To add a new bootstrap script:

1. Read this playbook completely
2. Follow all 6 phases in order
3. Use the script template provided
4. Test thoroughly in a clean environment
5. Update the status table above
6. Commit with reference to this playbook

---

## Glossary

- **Template**: Source configuration files in `___NEW PROJ TEMPLATES____/`
- **Bootstrap**: Automated setup process for a new project
- **Validation**: Self-testing to ensure bootstrap succeeded
- **Idempotent**: Can run safely multiple times
- **Haiku-style**: Quick validation checks (syntax, existence, format)
- **Source of Truth**: Template files are authoritative versions

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-07 | Bryan Luce | Initial playbook based on .claude/ implementation |

---
