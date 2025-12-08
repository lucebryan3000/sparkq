---
title: Bootstrap System Playbooks
description: Comprehensive guides for creating, standardizing, and running bootstrap scripts
---

# Bootstrap System Playbooks

Complete guides for working with the bootstrap system. Choose your playbook based on what you need to accomplish.

---

## Quick Decision Tree

```
Do you want to...?

├─ CREATE a new bootstrap script?
│  └─ → Read: create-bootstrap-script.md
│
├─ STANDARDIZE an existing bootstrap script?
│  └─ → Read: standardize-bootstrap-script.md
│
└─ RUN bootstrap scripts in your project?
   └─ → Read: run-bootstrap-scripts.md
```

---

## The Three Playbooks

### 1. [create-bootstrap-script.md](create-bootstrap-script.md)

**Use this when:** You want to add a new bootstrap capability (e.g., Redis setup, Stripe integration, Prisma configuration)

**What you'll do:**
1. Define scope and purpose
2. Create template files with placeholders
3. Add configuration section
4. Write the bootstrap script following the standard pattern
5. Register in the bootstrap menu
6. Test and document

**Time estimate:** 45-60 minutes for a complete script

**Output:** A new, working bootstrap script ready to distribute

---

### 2. [standardize-bootstrap-script.md](standardize-bootstrap-script.md)

**Use this when:** You have an existing bootstrap script with hardcoded values and duplicate code that needs refactoring

**What you'll do:**
1. Analyze the current script against the standard pattern
2. Replace duplicate functions with lib/common.sh calls
3. Convert hardcoded paths to use variables
4. Add configuration support
5. Add pre-execution confirmation
6. Implement proper tracking and logging
7. Validate syntax

**Time estimate:** 15-30 minutes depending on script complexity

**Output:** A standardized bootstrap script using the shared library

---

### 3. [run-bootstrap-scripts.md](run-bootstrap-scripts.md)

**Use this when:** You need to bootstrap a new project, configure it, troubleshoot issues, or rollback changes

**What you'll do:**
1. Verify prerequisites and permissions
2. Run bootstrap scripts (individual or phases)
3. Configure behavior with environment variables
4. Troubleshoot common issues
5. Verify results and customize configuration
6. Rollback if needed

**Time estimate:** 5-20 minutes for initial setup, 2-5 minutes for subsequent runs

**Output:** A fully bootstrapped project with all configuration files in place

---

## Relationship to Other Systems

### Bootstrap Commands

- **`/bootstrap-standardize`** - Wrapper command that executes the standardize playbook
- **`/bootstrap-create`** - Wrapper command for the create playbook (coming soon)

### Reference Materials

After using these playbooks, refer to:
- [LIBRARY.md](../references/LIBRARY.md) - Complete function reference for lib/common.sh
- [CONFIG.md](../references/CONFIG.md) - Configuration file format and options
- [SCRIPT_CATALOG.md](../references/SCRIPT_CATALOG.md) - Inventory of all bootstrap scripts

---

## Common Workflows

### Workflow 1: Add a New Technology to Bootstrap

```
1. Read: create-bootstrap-script.md
2. Create: templates/root/{name}/, scripts/bootstrap-{name}.sh
3. Update: config/bootstrap.config
4. Register: in bootstrap-menu.sh
5. Test: Run the script on a test project
```

**Result:** Users can bootstrap the new technology in their projects

---

### Workflow 2: Improve an Existing Bootstrap Script

```
1. Read: standardize-bootstrap-script.md
2. Run: /bootstrap-standardize bootstrap-{name}.sh
3. Review: Generated output against checklist
4. Validate: bash -n scripts/bootstrap-{name}.sh
5. Test: Run on fresh project
6. Commit: bootstrap-{name}.sh changes
```

**Result:** Script is cleaner, more maintainable, uses shared library

---

### Workflow 3: Bootstrap a New Project

```
1. Read: run-bootstrap-scripts.md (Quick Start section)
2. Navigate: cd __bootbuild/scripts
3. Run: ./bootstrap-menu.sh
4. Select: Phase 1, Phase 2, etc.
5. Verify: Files created, config customized
6. Commit: Bootstrap configuration files
```

**Result:** Project is fully configured and ready for development

---

## Phase Organization

Bootstrap scripts are organized into phases:

| Phase | Focus | Scripts |
|-------|-------|---------|
| **1** | Foundation | Git, packages, environment |
| **2** | Development | Linting, testing, TypeScript |
| **3** | Advanced | Docker, CI/CD, documentation |
| **Custom** | Individual | Run specific scripts by name |

---

## Key Concepts

### Shared Library Pattern

All modern bootstrap scripts use `lib/common.sh` for:
- Standardized logging (colors, timestamps)
- File operations (with tracking)
- Validation checks (directories, commands)
- Configuration management
- Pre-execution confirmation

### Configuration-Driven

Rather than hardcoding values, scripts read from:
- `config/bootstrap.config` - Static configuration
- Environment variables - Runtime overrides
- Interactive questions (optional)

### Idempotent Design

All scripts can be run multiple times safely:
- Existing files are backed up, not overwritten
- Missing files are created
- Configuration is re-applied
- Operations are logged

---

## Getting Started

**First time using bootstrap?**
→ Start with [run-bootstrap-scripts.md](run-bootstrap-scripts.md) → Quick Start section

**Want to add new bootstrap capability?**
→ Read [create-bootstrap-script.md](create-bootstrap-script.md)

**Have an old bootstrap script to modernize?**
→ Read [standardize-bootstrap-script.md](standardize-bootstrap-script.md)

---

**Version:** 2.0
**Last Updated:** 2025-12-07
**Maintained by:** Bootstrap System Team
