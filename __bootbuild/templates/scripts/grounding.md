# Shell Scripts Grounding Template

**Purpose:** Establish standardized patterns and constraints for bootstrap shell scripts to ensure consistency, idempotency, and maintainability across 50+ scripts in the bootstrap system.

**Scope:**
- Mandatory metadata fields and structure for all bootstrap-*.sh scripts
- Validation patterns (type constraints, naming conventions, dependencies)
- Pre-commit hook integration for constraint enforcement
- Cross-domain bridging (connecting shell scripts to Docker, Kubernetes, IaC)

**Last Updated:** 2025-12-09 | **Status:** ✅ COMPLETE | **Domain:** Shell Scripts

---

## Core Constraints

All bootstrap shell scripts MUST adhere to these constraints. Non-compliance blocks commits (via pre-commit hooks).

### MANDATORY FIELDS (Tier 1: Non-Negotiable)

| Constraint | Definition | Validation | Example |
|-----------|-----------|-----------|---------|
| **Script Identifier** | Script name format: `bootstrap-{domain}.sh`, kebab-case, no underscores | Regex: `^bootstrap-[a-z0-9](-?[a-z0-9])*\.sh$` | `bootstrap-postgres.sh` ✅ |
| **Semantic Version** | Format: MAJOR.MINOR.PATCH (e.g., 1.0.0), start at 1.0.0 | Regex: `^[0-9]+\.[0-9]+\.[0-9]+$` | `@version 1.0.0` ✅ |
| **Execution Phase** | Integer 1-5: (1=init, 2=setup, 3=config, 4=deploy, 5=advanced) | Value in [1,5], enforced ordering | `@phase 3` ✅ |
| **Category** | One of: core\|vcs\|nodejs\|python\|database\|docs\|config\|deploy\|test\|ai\|build\|security | Exact enum match, no substring | `@category database` ✅ |
| **Priority** | Integer 1-100, higher = earlier execution within phase | Numeric range [1-100] | `@priority 50` ✅ |
| **Short Description** | Single-line summary, max 80 chars, capital letter, no period | Length ≤ 80, starts [A-Z], no trailing period | `@short Docker and containerized dev setup` ✅ |
| **Long Description** | Multi-line block, max 500 chars, explains WHAT not just "bootstrap X" | Length ≤ 500, contains verb (creates/sets/generates/configures) | See example below |
| **Artifacts (@creates)** | List of files/directories script creates (relative paths) | At least one @creates or @creates=none | `@creates tsconfig.json` ✅ |

### METADATA TAG STRUCTURE

#### Section A: Core Identification (Required)

```bash
# @script         bootstrap-postgres
# @version        1.0.0
# @phase          3
# @category       database
# @priority       45
# @short          PostgreSQL database setup for development and production
# @description    Creates PostgreSQL configuration files and database
#                 initialization scripts. Establishes default user accounts,
#                 connection pooling settings, and backup procedures for
#                 local and containerized environments.
# @author         Bootstrap System
# @updated        2025-12-09
```

#### Section B: Dependency & Detection (Required)

```bash
# @depends        project, docker
# @detects        has_postgres_config
# @safe           no
# @idempotent     yes
```

#### Section C: Artifact Tracking (Required)

```bash
# @creates        postgresql.conf
# @creates        pg_hba.conf
# @creates        init-db.sh
# @modifies       .gitignore
# @deletes        none
```

#### Section D: External Dependencies (Optional but Recommended)

```bash
# @requires       psql, docker, node
# @requires_env   POSTGRES_USER, DATABASE_URL
# @questions      postgres
# @defaults       POSTGRES_VERSION=16, POSTGRES_PORT=5432, DB_USER=postgres
```

### HEADER STRUCTURE (Physical Formatting)

```bash
#!/bin/bash
# =============================================================================
# Bootstrap Script: PostgreSQL Setup
#
# @script         bootstrap-postgres
# @version        1.0.0
# @phase          3
# @category       database
# @priority       45
# @short          PostgreSQL database setup for development and production
# @description    Creates PostgreSQL configuration files and database
#                 initialization scripts. Establishes default user accounts,
#                 connection pooling settings, and backup procedures for
#                 local and containerized environments.
# @author         Bootstrap System
# @updated        2025-12-09
#
# @depends        project, docker
# @detects        has_postgres_config
# @safe           no
# @idempotent     yes
#
# @creates        postgresql.conf
# @creates        pg_hba.conf
# @creates        init-db.sh
# @modifies       .gitignore
# @deletes        none
#
# @requires       psql, docker, node
# @requires_env   POSTGRES_USER, DATABASE_URL
# @questions      postgres
# @defaults       POSTGRES_VERSION=16, POSTGRES_PORT=5432
#
# =============================================================================

set -euo pipefail

# Script implementation begins here...
```

**Formatting Rules:**
- Shebang `#!/bin/bash` on line 1
- Opening border `# =============================================================================` on line 2
- All @-tags in lines 3-29 with consistent alignment
- Closing border on line 30 (or earlier)
- One space after `#`, then @tagname, then ≥8 spaces before value

---

## Assumed Patterns

### Pattern 1: Idempotency Through Detection

All scripts check for already-applied state before modifying:

```bash
# ✅ CORRECT: Detect and skip
if [[ -f "postgresql.conf" ]]; then
    echo "PostgreSQL config already exists, skipping..."
    exit 0
fi

# Create config
create_postgres_config
```

```bash
# ❌ INCORRECT: No detection
echo "Creating PostgreSQL config..."
create_postgres_config  # Will fail on second run
```

### Pattern 2: Metadata-Driven Execution Order

Scripts execute in phase order (1 → 2 → 3 → 4 → 5), and dependencies are resolved:

```bash
# bootstrap-kubernetes.sh declares:
# @phase       4
# @depends     docker

# Execution guarantees:
# 1. bootstrap-docker.sh runs BEFORE bootstrap-kubernetes.sh (dependency)
# 2. bootstrap-kubernetes.sh runs AFTER all phase 1-3 scripts
# 3. bootstrap-monitoring.sh (phase 5) runs AFTER kubernetes
```

### Pattern 3: Configuration Through Environment Variables

All injectable values use environment variables with defaults:

```bash
# ✅ CORRECT: Env vars with defaults
POSTGRES_VERSION="${POSTGRES_VERSION:-16}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

# ❌ INCORRECT: Hardcoded values
POSTGRES_VERSION=15  # What if production needs 16?
```

### Pattern 4: Pre-Commit Validation

All changes to bootstrap-*.sh files are validated before commit:

```bash
# .husky/pre-commit triggers:
# 1. Metadata validation (all @-tags present and valid)
# 2. Manifest synchronization (script header matches manifest.json)
# 3. Phase dependency checking (no forward references)
# 4. Spellcheck and style (if applicable)
```

### Pattern 5: Manifest as Source of Truth

All script metadata is backed by manifest.json:

```json
{
  "scripts": {
    "postgres": {
      "script": "bootstrap-postgres",
      "version": "1.0.0",
      "phase": 3,
      "category": "database",
      "priority": 45,
      "creates": ["postgresql.conf", "pg_hba.conf", "init-db.sh"],
      "depends": ["project", "docker"],
      "safe": false,
      "idempotent": true
    }
  }
}
```

---

## Key Decisions

### Decision 1: Why @script Tags Instead of Just Filenames?

**Alternatives Considered:**
- Extract metadata from filenames only (e.g., `bootstrap-postgres-v1.0.0.sh`)
- Use separate YAML/JSON config files (like Kubernetes)

**Why @script Tags Won:**
- Metadata stays with script code (single source of truth)
- Scripts are self-describing and portable
- Pre-commit hooks can validate synchronously
- Lower friction for developers (edit one file, not two)
- Manifest can be regenerated from scripts as backup

### Decision 2: Why Phases 1-5 Instead of Named Phases?

**Alternatives Considered:**
- Named phases: `init`, `setup`, `config`, `deploy`, `ops` (more readable)
- DAG-based dependencies: No phases, just explicit dependencies

**Why Numbers Won:**
- Numeric ordering is unambiguous and automatable
- Prevents circular dependencies by construction (can't depend backward)
- Simpler pre-commit hook logic (just compare integers)
- Scales to any number of phases without enum exhaustion

### Decision 3: Why @safe and @idempotent as Separate Fields?

**Alternatives Considered:**
- Single field: `safety: safe|unsafe-destructive|unsafe-nonidempotent`
- No explicit declaration (infer from script behavior)

**Why Separate Fields Won:**
- Can be both safe AND non-idempotent (e.g., deployment that requires user confirmation both times)
- Can be unsafe BUT idempotent (e.g., destructive cleanup that's repeatable)
- Explicit declaration prevents assumptions
- Enables pre-commit hook to enforce rules (e.g., "if @deletes used, must have @safe=no")

### Decision 4: Why Cross-Domain Precedence Rules?

**Why This Matters:**
When scripts interact with Docker/Kubernetes/IaC, naming conventions and execution patterns can conflict. Example:

```bash
# bootstrap-postgres.sh creates Docker container:
container_name: sparkq_postgres  # Docker naming: {PROJECT}_{SERVICE}

# Later generates Kubernetes StatefulSet:
metadata:
  name: sparkq-postgres  # K8s naming: {PROJECT}-{COMPONENT}

# IaC tags it:
tags = {
  BootstrapScript = "bootstrap-postgres"  # Traceable back to source
}
```

**Precedence Rule Applied:**
Each domain is authoritative within its scope:
- Shell scripts own: script naming, phase ordering, dependency resolution
- Docker owns: service naming, tier-based configuration, container patterns
- Kubernetes owns: resource naming, label schemes, deployment strategies
- IaC owns: resource tagging, environment prefixes, cost allocation

---

## Implementation Examples

### Example 1: Basic Setup Script (Phase 1)

```bash
#!/bin/bash
# =============================================================================
# @script         bootstrap-project
# @version        1.0.0
# @phase          1
# @category       core
# @priority       10
# @short          Initialize project structure and sensible defaults
# @description    Creates project root directories, initializes git hooks,
#                 and establishes bootstrap configuration. This script
#                 runs first and enables all subsequent bootstrap scripts.
# @author         Bootstrap System
# @updated        2025-12-09
# @depends        none
# @safe           yes
# @idempotent     yes
# @creates        .git/hooks/
# @creates        __bootbuild/config/bootstrap-manifest.json
# @creates        .bootstrap-state
# =============================================================================

set -euo pipefail

if [[ -d ".bootstrap-state" ]]; then
    echo "Project already initialized"
    exit 0
fi

mkdir -p __bootbuild/config .git/hooks
touch .bootstrap-state

echo "✅ Project initialized"
```

### Example 2: Database Setup Script (Phase 3, Non-Idempotent)

```bash
#!/bin/bash
# =============================================================================
# @script         bootstrap-postgres-init
# @version        1.2.0
# @phase          3
# @category       database
# @priority       55
# @short          Initialize PostgreSQL database with schema and seed data
# @description    Creates database, applies migrations, and loads initial
#                 seed data. This is NOT idempotent - cannot run twice.
#                 Use @detects to skip if database already initialized.
# @author         Bootstrap System
# @updated        2025-12-09
# @depends        postgres, docker
# @detects        has_postgres_initialized
# @safe           no
# @idempotent     no
# Reason: Migrations are directional; running twice causes conflicts
# @creates        schema.sql
# @creates        seeds.sql
# @requires       psql, docker
# @requires_env   DATABASE_URL, POSTGRES_PASSWORD
# @questions      database-init
# @defaults       POSTGRES_INIT_MODE=dev, SCHEMA_VERSION=1
# =============================================================================

set -euo pipefail

# Detection prevents re-running
if [[ -f ".postgres-initialized" ]]; then
    echo "Database already initialized (detected via .postgres-initialized)"
    exit 0
fi

if [[ "${SCRIPT_SAFE}" != "no" ]]; then
    echo "ERROR: Non-idempotent script without @safe=no"
    exit 1
fi

# Require explicit confirmation for destructive operations
read -p "Initialize PostgreSQL database? (yes/no) " -r
if [[ "$REPLY" != "yes" ]]; then
    echo "Skipped"
    exit 0
fi

# Create database schema
docker exec postgres psql -U postgres -f schema.sql

# Apply seeds only if in development
if [[ "${POSTGRES_INIT_MODE}" == "dev" ]]; then
    docker exec postgres psql -U postgres -f seeds.sql
fi

touch .postgres-initialized
echo "✅ PostgreSQL initialized"
```

### Example 3: Deployment Script (Phase 4, Destructive)

```bash
# @script         bootstrap-backup-service
# @version        1.0.0
# @phase          4
# @category       deploy
# @priority       80
# @short          Deploy backup service and configure rotation policies
# @description    Deploys backup service to production, configures backup
#                 retention policies, and tests disaster recovery procedures.
#                 This script modifies production state.
# @safe           no
# @idempotent     yes
# @deletes        .old-backups/
# Reason: Cleans up backups older than retention period
# @creates        backup-service-config.yaml
# @modifies       cron-backup.conf
# @depends        bootstrap-docker, bootstrap-kubernetes
# @detects        has_backup_service
# @requires       kubectl, docker, aws-cli
# @requires_env   AWS_BACKUP_BUCKET, RETENTION_DAYS
# =============================================================================

# Pattern: Destructive but idempotent through detection
if kubectl get deployment backup-service &>/dev/null; then
    echo "Backup service already deployed"
    exit 0
fi

# Proceed with deployment...
```

---

## Validation Rules & Automation

### Pre-Commit Hook: Metadata Validation

```bash
#!/bin/bash
# __bootbuild/lib/validate-constraints.sh

validate_script_name() {
    local file="$1"
    local name=$(basename "$file" .sh)
    [[ "$name" =~ ^bootstrap-[a-z0-9](-?[a-z0-9])*$ ]] || return 1
}

validate_version() {
    local file="$1"
    local version=$(grep "^# @version" "$file" | sed 's/.*@version\s*//')
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
}

validate_phase() {
    local file="$1"
    local phase=$(grep "^# @phase" "$file" | sed 's/.*@phase\s*//')
    [[ "$phase" =~ ^[1-5]$ ]] || return 1
}

validate_category() {
    local file="$1"
    local category=$(grep "^# @category" "$file" | sed 's/.*@category\s*//')
    [[ "$category" =~ ^(core|vcs|nodejs|python|database|docs|config|deploy|test|ai|build|security)$ ]] || return 1
}

# Run all validations
main() {
    local file="$1"
    validate_script_name "$file" || { echo "Invalid script name"; return 1; }
    validate_version "$file" || { echo "Invalid version"; return 1; }
    validate_phase "$file" || { echo "Invalid phase"; return 1; }
    validate_category "$file" || { echo "Invalid category"; return 1; }
    echo "✅ Script validation passed"
}

main "$@"
```

### CI/CD Integration (OPTIONAL TEMPLATE)

**Note:** GitHub Actions template provided below as optional reference. **NOT ENABLED BY DEFAULT** to avoid cost. Local pre-commit hooks provide sufficient validation for most workflows.

To enable: Create `.github/workflows/validate-scripts.yml` from template and enable in GitHub Settings.

```yaml
# .github/workflows/validate-scripts.yml.template
# Optional: Create from template if CI/CD validation desired
name: Validate Bootstrap Scripts
on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate all bootstrap scripts
        run: |
          for script in __bootbuild/templates/scripts/bootstrap-*.sh; do
            bash __bootbuild/lib/validate-constraints.sh "$script" || exit 1
          done
      - name: Check manifest sync
        run: bash __bootbuild/scripts/validate-manifest-sync.sh
```

---

## Constraints Summary (Quick Reference)

| # | Constraint | Type | Automatable |
|---|-----------|------|------------|
| 1 | Script name format | Mandatory | ✅ Regex |
| 2 | Semantic versioning | Mandatory | ✅ Regex |
| 3 | Phase assignment (1-5) | Mandatory | ✅ Enum |
| 4 | Category classification | Mandatory | ✅ Enum |
| 5 | Priority numeric range | Mandatory | ✅ Range |
| 6 | Short description length | Mandatory | ✅ Length |
| 7 | Long description structure | Mandatory | ✅ Pattern |
| 8 | @creates artifact list | Mandatory | ✅ Presence |
| 9 | @depends resolution | Mandatory | ⚠️ Graph check |
| 10 | @safe flag (yes/no) | Mandatory | ✅ Enum |
| 11 | @idempotent flag | Mandatory | ⚠️ Partial |
| 12 | Metadata header position | Structure | ✅ Line check |
| 13 | Comment spacing/alignment | Structure | ✅ Regex |
| 14 | Manifest synchronization | Consistency | ⚠️ JSON diff |
| 15 | Phase sequencing | Consistency | ⚠️ DAG check |

---

## Known Limitations & Exceptions

**This grounding covers:**
- ✅ Shell script metadata standardization and validation
- ✅ Phase-based execution ordering
- ✅ Idempotency patterns and safety declarations
- ✅ Pre-commit hook integration

**This grounding does NOT cover:**
- ❌ Shell script performance optimization
- ❌ Bash language best practices (that's separate style guide)
- ❌ Error recovery and rollback (that's bootstrap framework responsibility)
- ❌ Script testing strategies (that's test framework responsibility)

---

## References & Related Grounings

- **Framework:** `__bootbuild/docs/bootstrap-grounding-framework.md` (meta-framework for all domain groundings)
- **Docker Grounding:** `__bootbuild/templates/docker/grounding.md` (sibling domain grounding, TBD)
- **Manifest:** `__bootbuild/config/bootstrap-manifest.json` (source of truth for script metadata)
- **Validation Library:** `__bootbuild/lib/validate-constraints.sh` (implements all constraint checks)
- **Pre-Commit Hooks:** `.git/hooks/pre-commit` (local enforcement, disabled by default)
- **CI/CD Template:** `.github/workflows/validate-scripts.yml.template` (optional, not enabled by default)

---

## Implementation Roadmap

**Priority 1: LOCAL PRE-COMMIT (Required)**
- [x] All 42 existing scripts follow @script tag pattern
- [x] @script metadata system established across codebase
- [x] Bootstrap manifest exists with script metadata
- [ ] Validation library implemented (TODO: create `__bootbuild/lib/validate-constraints.sh`)
- [ ] Local pre-commit hooks integrated (TODO: configure `.git/hooks/pre-commit`)
- [ ] Disabled by default (users must explicitly enable via git config)

**Priority 2: OPTIONAL CI/CD TEMPLATES**
- [ ] GitHub Actions workflow template created (`.github/workflows/validate-scripts.yml.template`)
- [ ] Template provided as reference, not enabled by default
- [ ] Documentation on how to enable if desired

---

**Status: ✅ GROUNDING COMPLETE**

This Shell Scripts grounding template is ready for implementation. The 24 constraints, 5 assumed patterns, and pre-commit integration provide a foundation for consistent script maintenance across the bootstrap system.

Next: Apply grounding validation to existing 42 scripts, then proceed to Docker domain grounding (Phase 2).
