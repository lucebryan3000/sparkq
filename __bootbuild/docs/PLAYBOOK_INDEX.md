---
title: Bootstrap Documentation Index
version: 1.0
created: 2025-12-07
updated: 2025-12-07
---

# Bootstrap Documentation Index

Navigation hub for all bootstrap system documentation, playbooks, and references.

---

## Getting Started

**New to bootstrap?** Start here:

1. **[run-bootstrap-scripts.md](playbooks/run-bootstrap-scripts.md)** - How to execute bootstrap scripts
   - Prerequisites and setup
   - Running individual scripts or full phases
   - Troubleshooting common issues
   - Rolling back changes

2. **[SCRIPT_CATALOG.md](references/SCRIPT_CATALOG.md)** - Available bootstrap scripts
   - What each script does
   - Files it creates
   - Dependencies and runtime
   - Execution order

---

## Documentation Structure

### Playbooks (Step-by-Step Guides)

Detailed workflows for specific tasks:

- **[create-bootstrap-script.md](playbooks/create-bootstrap-script.md)** - Create new bootstrap scripts
  - 9-step guide from scope to testing
  - Template and checklist
  - Standardization requirements
  - Real-world example (bootstrap-redis.sh)

- **[run-bootstrap-scripts.md](playbooks/run-bootstrap-scripts.md)** - Execute bootstrap scripts
  - Prerequisites verification
  - Running individual scripts
  - Running multiple scripts
  - Configuration and environment variables
  - Troubleshooting
  - Post-execution steps
  - Rollback procedures

- **[standardize-bootstrap-script.md](playbooks/standardize-bootstrap-script.md)** - Standardize existing scripts
  - 13-step transformation guide
  - Pattern migration checklist
  - Function reference mappings
  - Before/after examples
  - Troubleshooting

---

### References (Complete Function/Configuration Lists)

Comprehensive lookup tables and command references:

- **[SCRIPT_CATALOG.md](references/SCRIPT_CATALOG.md)** - All bootstrap scripts
  - Organized by phase (1-4)
  - Purpose, status, dependencies
  - Files created and configuration sections
  - Usage patterns and examples

- **[CONFIG.md](references/CONFIG.md)** - Configuration and environment variables
  - Configuration file sections and options
  - Environment variable reference
  - Configuration precedence rules
  - Validation procedures

- **[LIBRARY.md](references/LIBRARY.md)** - Bootstrap library functions
  - Complete function reference from `lib/common.sh`
  - Organized by category (logging, files, validation, etc.)
  - Syntax, examples, return values
  - Working example script

---

## By Task

### I want to...

**Run bootstrap scripts on my project**
→ [run-bootstrap-scripts.md](playbooks/run-bootstrap-scripts.md)

**Create a new bootstrap script**
→ [create-bootstrap-script.md](playbooks/create-bootstrap-script.md)

**Standardize an existing script**
→ [standardize-bootstrap-script.md](playbooks/standardize-bootstrap-script.md)

**See what scripts are available**
→ [SCRIPT_CATALOG.md](references/SCRIPT_CATALOG.md)

**Configure bootstrap behavior**
→ [CONFIG.md](references/CONFIG.md)

**Use a specific library function**
→ [LIBRARY.md](references/LIBRARY.md)

**Find troubleshooting help**
→ [run-bootstrap-scripts.md - Troubleshooting](playbooks/run-bootstrap-scripts.md#common-issues--troubleshooting)

---

## By Role

### I'm a Developer

Use these to bootstrap your project:
- [run-bootstrap-scripts.md](playbooks/run-bootstrap-scripts.md) - How to run bootstrap scripts
- [SCRIPT_CATALOG.md](references/SCRIPT_CATALOG.md) - What scripts do
- [CONFIG.md](references/CONFIG.md) - Configuration options

### I'm a DevOps/Infrastructure

Use these to extend bootstrap:
- [create-bootstrap-script.md](playbooks/create-bootstrap-script.md) - Create new scripts
- [LIBRARY.md](references/LIBRARY.md) - Available functions
- [standardize-bootstrap-script.md](playbooks/standardize-bootstrap-script.md) - Standardization

### I'm Maintaining Bootstrap System

Use these for system maintenance:
- [create-bootstrap-script.md](playbooks/create-bootstrap-script.md) - Script creation guide
- [standardize-bootstrap-script.md](playbooks/standardize-bootstrap-script.md) - Standardization guide
- [LIBRARY.md](references/LIBRARY.md) - Function reference

---

## File Organization

Bootstrap documentation is organized as:

```
__bootbuild/docs/
├── PLAYBOOK_INDEX.md          # You are here
├── DECISION_LOG.md            # Implementation decisions
├── playbooks/
│   ├── create-bootstrap-script.md
│   ├── run-bootstrap-scripts.md
│   └── standardize-bootstrap-script.md
├── references/
│   ├── SCRIPT_CATALOG.md
│   ├── CONFIG.md
│   ├── LIBRARY.md
│   ├── MENU_STRUCTURE.md
│   ├── TEMPLATES.md
│   ├── DEPLOYMENT_GUIDE.md
│   ├── IMPLEMENTATION_STATUS.md
│   └── README.md
├── cleanup/                    # Files needing review/decision
├── bryan/                      # Personal/project documentation
├── archived/                   # Previous versions
└── [Other documentation]
```

---

## Quick Links

**Common Tasks:**
- [Quick Start (5 minutes)](playbooks/run-bootstrap-scripts.md#quick-start-5-minutes)
- [Running Individual Scripts](playbooks/run-bootstrap-scripts.md#running-individual-scripts)
- [Configuration & Environment Variables](playbooks/run-bootstrap-scripts.md#configuration--environment-variables)

**Common Issues:**
- [Permission Denied](playbooks/run-bootstrap-scripts.md#issue-1-permission-denied-when-running-script)
- [Library Not Found](playbooks/run-bootstrap-scripts.md#issue-2-libcommonsh-not-found)
- [Config File Not Found](playbooks/run-bootstrap-scripts.md#issue-3-bootstrap-config-file-not-found)

**Function Lookup:**
- [Logging Functions](references/LIBRARY.md#logging-functions)
- [File Operations](references/LIBRARY.md#file-operations)
- [Validation Functions](references/LIBRARY.md#validation-functions)
- [Configuration Functions](references/LIBRARY.md#configuration-functions)

**Scripts by Phase:**
- [Phase 1: Foundation](references/SCRIPT_CATALOG.md#phase-1-foundation)
- [Phase 2: Development](references/SCRIPT_CATALOG.md#phase-2-development)
- [Phase 3: Advanced](references/SCRIPT_CATALOG.md#phase-3-advanced)
- [Phase 4: Optional](references/SCRIPT_CATALOG.md#phase-4-optionaladvanced)

---

## Documentation Versions

| File | Version | Status | Updated |
|------|---------|--------|---------|
| PLAYBOOK_INDEX.md | 1.0 | Active | 2025-12-07 |
| playbooks/create-bootstrap-script.md | 1.0 | Active | 2025-12-07 |
| playbooks/run-bootstrap-scripts.md | 1.0 | Active | 2025-12-07 |
| playbooks/standardize-bootstrap-script.md | 1.0 | Active | 2025-12-07 |
| references/SCRIPT_CATALOG.md | 1.0 | Active | 2025-12-07 |
| references/CONFIG.md | 1.0 | Active | 2025-12-07 |
| references/LIBRARY.md | 1.0 | Active | 2025-12-07 |
| references/MENU_STRUCTURE.md | 1.0 | Active | 2025-12-07 |
| references/TEMPLATES.md | 1.0 | Active | 2025-12-07 |
| references/DEPLOYMENT_GUIDE.md | 1.0 | Active | 2025-12-07 |
| references/IMPLEMENTATION_STATUS.md | 1.0 | Active | 2025-12-07 |

---

## Architecture Overview

Bootstrap documentation follows a **single-source-of-truth** architecture:

- **Playbooks** define workflows and step-by-step procedures
- **References** provide complete lookup tables and function documentation
- **Slash commands** reference playbooks (not duplicate content)
- **Scripts** follow standardized patterns from create-bootstrap-script.md

This design eliminates documentation drift and ensures consistency.

---

## Support & Maintenance

For updates, issues, or contributions:

1. **Found an error?** Check [DECISION_LOG.md](DECISION_LOG.md) for known issues
2. **Need clarification?** Review the specific playbook or reference
3. **Want to add content?** See [create-bootstrap-script.md](playbooks/create-bootstrap-script.md)
4. **Standardizing scripts?** See [standardize-bootstrap-script.md](playbooks/standardize-bootstrap-script.md)

---

## Next Steps

- **First time?** → [run-bootstrap-scripts.md - Quick Start](playbooks/run-bootstrap-scripts.md#quick-start-5-minutes)
- **Create scripts?** → [create-bootstrap-script.md](playbooks/create-bootstrap-script.md)
- **Need help?** → [run-bootstrap-scripts.md - Troubleshooting](playbooks/run-bootstrap-scripts.md#common-issues--troubleshooting)

---

**Last Updated:** 2025-12-07
**Status:** Complete and Ready for Use
