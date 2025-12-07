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

1. **[PLAYBOOK_RUNNING.md](playbooks/PLAYBOOK_RUNNING.md)** - How to execute bootstrap scripts
   - Prerequisites and setup
   - Running individual scripts or full phases
   - Troubleshooting common issues
   - Rolling back changes

2. **[REFERENCE_SCRIPT_CATALOG.md](references/REFERENCE_SCRIPT_CATALOG.md)** - Available bootstrap scripts
   - What each script does
   - Files it creates
   - Dependencies and runtime
   - Execution order

---

## Documentation Structure

### Playbooks (Step-by-Step Guides)

Detailed workflows for specific tasks:

- **[PLAYBOOK_CREATING_SCRIPTS.md](playbooks/PLAYBOOK_CREATING_SCRIPTS.md)** - Create new bootstrap scripts
  - 9-step guide from scope to testing
  - Template and checklist
  - Standardization requirements
  - Real-world example (bootstrap-redis.sh)

- **[PLAYBOOK_RUNNING.md](playbooks/PLAYBOOK_RUNNING.md)** - Execute bootstrap scripts
  - Prerequisites verification
  - Running individual scripts
  - Running multiple scripts
  - Configuration and environment variables
  - Troubleshooting
  - Post-execution steps
  - Rollback procedures

- **[PLAYBOOK_MIGRATING_SCRIPTS.md](playbooks/PLAYBOOK_MIGRATING_SCRIPTS.md)** - Standardize existing scripts
  - 13-step transformation guide
  - Pattern migration checklist
  - Function reference mappings
  - Before/after examples
  - Troubleshooting

---

### References (Complete Function/Configuration Lists)

Comprehensive lookup tables and command references:

- **[REFERENCE_SCRIPT_CATALOG.md](references/REFERENCE_SCRIPT_CATALOG.md)** - All bootstrap scripts
  - Organized by phase (1-4)
  - Purpose, status, dependencies
  - Files created and configuration sections
  - Usage patterns and examples

- **[REFERENCE_CONFIG.md](references/REFERENCE_CONFIG.md)** - Configuration and environment variables
  - Configuration file sections and options
  - Environment variable reference
  - Configuration precedence rules
  - Validation procedures

- **[REFERENCE_LIBRARY.md](references/REFERENCE_LIBRARY.md)** - Bootstrap library functions
  - Complete function reference from `lib/common.sh`
  - Organized by category (logging, files, validation, etc.)
  - Syntax, examples, return values
  - Working example script

---

## By Task

### I want to...

**Run bootstrap scripts on my project**
→ [PLAYBOOK_RUNNING.md](playbooks/PLAYBOOK_RUNNING.md)

**Create a new bootstrap script**
→ [PLAYBOOK_CREATING_SCRIPTS.md](playbooks/PLAYBOOK_CREATING_SCRIPTS.md)

**Standardize an existing script**
→ [PLAYBOOK_MIGRATING_SCRIPTS.md](playbooks/PLAYBOOK_MIGRATING_SCRIPTS.md)

**See what scripts are available**
→ [REFERENCE_SCRIPT_CATALOG.md](references/REFERENCE_SCRIPT_CATALOG.md)

**Configure bootstrap behavior**
→ [REFERENCE_CONFIG.md](references/REFERENCE_CONFIG.md)

**Use a specific library function**
→ [REFERENCE_LIBRARY.md](references/REFERENCE_LIBRARY.md)

**Find troubleshooting help**
→ [PLAYBOOK_RUNNING.md - Troubleshooting](playbooks/PLAYBOOK_RUNNING.md#common-issues--troubleshooting)

---

## By Role

### I'm a Developer

Use these to bootstrap your project:
- [PLAYBOOK_RUNNING.md](playbooks/PLAYBOOK_RUNNING.md) - How to run bootstrap scripts
- [REFERENCE_SCRIPT_CATALOG.md](references/REFERENCE_SCRIPT_CATALOG.md) - What scripts do
- [REFERENCE_CONFIG.md](references/REFERENCE_CONFIG.md) - Configuration options

### I'm a DevOps/Infrastructure

Use these to extend bootstrap:
- [PLAYBOOK_CREATING_SCRIPTS.md](playbooks/PLAYBOOK_CREATING_SCRIPTS.md) - Create new scripts
- [REFERENCE_LIBRARY.md](references/REFERENCE_LIBRARY.md) - Available functions
- [PLAYBOOK_MIGRATING_SCRIPTS.md](playbooks/PLAYBOOK_MIGRATING_SCRIPTS.md) - Standardization

### I'm Maintaining Bootstrap System

Use these for system maintenance:
- [PLAYBOOK_CREATING_SCRIPTS.md](playbooks/PLAYBOOK_CREATING_SCRIPTS.md) - Script creation guide
- [PLAYBOOK_MIGRATING_SCRIPTS.md](playbooks/PLAYBOOK_MIGRATING_SCRIPTS.md) - Standardization guide
- [REFERENCE_LIBRARY.md](references/REFERENCE_LIBRARY.md) - Function reference

---

## File Organization

Bootstrap documentation is organized as:

```
__bootbuild/docs/
├── PLAYBOOK_INDEX.md          # You are here
├── DECISION_LOG.md            # Implementation decisions
├── playbooks/
│   ├── PLAYBOOK_CREATING_SCRIPTS.md
│   ├── PLAYBOOK_RUNNING.md
│   └── PLAYBOOK_MIGRATING_SCRIPTS.md
├── references/
│   ├── REFERENCE_SCRIPT_CATALOG.md
│   ├── REFERENCE_CONFIG.md
│   └── REFERENCE_LIBRARY.md
├── cleanup/                    # Files needing review/decision
├── bryan/                      # Personal/project documentation
├── archived/                   # Previous versions
└── [Other documentation]
```

---

## Quick Links

**Common Tasks:**
- [Quick Start (5 minutes)](playbooks/PLAYBOOK_RUNNING.md#quick-start-5-minutes)
- [Running Individual Scripts](playbooks/PLAYBOOK_RUNNING.md#running-individual-scripts)
- [Configuration & Environment Variables](playbooks/PLAYBOOK_RUNNING.md#configuration--environment-variables)

**Common Issues:**
- [Permission Denied](playbooks/PLAYBOOK_RUNNING.md#issue-1-permission-denied-when-running-script)
- [Library Not Found](playbooks/PLAYBOOK_RUNNING.md#issue-2-libcommonsh-not-found)
- [Config File Not Found](playbooks/PLAYBOOK_RUNNING.md#issue-3-bootstrap-config-file-not-found)

**Function Lookup:**
- [Logging Functions](references/REFERENCE_LIBRARY.md#logging-functions)
- [File Operations](references/REFERENCE_LIBRARY.md#file-operations)
- [Validation Functions](references/REFERENCE_LIBRARY.md#validation-functions)
- [Configuration Functions](references/REFERENCE_LIBRARY.md#configuration-functions)

**Scripts by Phase:**
- [Phase 1: Foundation](references/REFERENCE_SCRIPT_CATALOG.md#phase-1-foundation)
- [Phase 2: Development](references/REFERENCE_SCRIPT_CATALOG.md#phase-2-development)
- [Phase 3: Advanced](references/REFERENCE_SCRIPT_CATALOG.md#phase-3-advanced)
- [Phase 4: Optional](references/REFERENCE_SCRIPT_CATALOG.md#phase-4-optionaladvanced)

---

## Documentation Versions

| File | Version | Status | Updated |
|------|---------|--------|---------|
| PLAYBOOK_INDEX.md | 1.0 | Active | 2025-12-07 |
| PLAYBOOK_CREATING_SCRIPTS.md | 1.0 | Active | 2025-12-07 |
| PLAYBOOK_RUNNING.md | 1.0 | Active | 2025-12-07 |
| PLAYBOOK_MIGRATING_SCRIPTS.md | 1.0 | Active | 2025-12-07 |
| REFERENCE_SCRIPT_CATALOG.md | 1.0 | Active | 2025-12-07 |
| REFERENCE_CONFIG.md | 1.0 | Active | 2025-12-07 |
| REFERENCE_LIBRARY.md | 1.0 | Active | 2025-12-07 |

---

## Architecture Overview

Bootstrap documentation follows a **single-source-of-truth** architecture:

- **Playbooks** define workflows and step-by-step procedures
- **References** provide complete lookup tables and function documentation
- **Slash commands** reference playbooks (not duplicate content)
- **Scripts** follow standardized patterns from PLAYBOOK_CREATING_SCRIPTS.md

This design eliminates documentation drift and ensures consistency.

---

## Support & Maintenance

For updates, issues, or contributions:

1. **Found an error?** Check [DECISION_LOG.md](DECISION_LOG.md) for known issues
2. **Need clarification?** Review the specific playbook or reference
3. **Want to add content?** See [PLAYBOOK_CREATING_SCRIPTS.md](playbooks/PLAYBOOK_CREATING_SCRIPTS.md)
4. **Standardizing scripts?** See [PLAYBOOK_MIGRATING_SCRIPTS.md](playbooks/PLAYBOOK_MIGRATING_SCRIPTS.md)

---

## Next Steps

- **First time?** → [PLAYBOOK_RUNNING.md - Quick Start](playbooks/PLAYBOOK_RUNNING.md#quick-start-5-minutes)
- **Create scripts?** → [PLAYBOOK_CREATING_SCRIPTS.md](playbooks/PLAYBOOK_CREATING_SCRIPTS.md)
- **Need help?** → [PLAYBOOK_RUNNING.md - Troubleshooting](playbooks/PLAYBOOK_RUNNING.md#common-issues--troubleshooting)

---

**Last Updated:** 2025-12-07
**Status:** Complete and Ready for Use
