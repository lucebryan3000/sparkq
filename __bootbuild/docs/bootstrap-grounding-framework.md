# Bootstrap Grounding Framework

**Purpose:** Establish the architectural framework for grounding templates across all bootstrap system domains. This document defines the concept, standards, and expansion path for creating technology-specific grounding templates that standardize patterns across `__bootbuild/templates/scripts/` and `__bootbuild/templates/[technology]/` domains.

**Scope:**
- Generic grounding template concept and structure
- Specification completeness validation checklist (reusable across all projects)
- Framework for domain-specific implementations (Shell Scripts, Docker, Kubernetes, IaC, etc.)
- Pattern consistency enforcement and failure recovery procedures

---

## Who Uses This & When

**This document is for:**
- 👨‍🏛️ **Architects** planning new technology domains (Kubernetes, IaC, databases)
- 👨‍💻 **Developers** implementing scripts in grounded domains
- 🤖 **Claude** (AI assistant) executing within grounded system domains
- 📋 **Standards reviewers** validating specification completeness

**When to consult this document:**

| Scenario | Action | Reference |
|----------|--------|-----------|
| **Planning a new technology domain** | Read "Creating a Domain-Specific Grounding Template" (Phase 1-5 workflow) | Lines 99-165 |
| **Implementing scripts in Docker/Shell Scripts** | Load domain-specific grounding from `__bootbuild/templates/[domain]/grounding.md` | Section "How Claude Uses Grounding Templates" |
| **Validating a specification is complete** | Use the "Specification Completeness Checklist" before gap analysis | Lines 168-207 |
| **Evaluating if a domain needs grounding** | Use the "Decision Framework: When to Ground a Domain" matrix | Lines 283-306 |
| **Writing a domain grounding template** | Follow the "Generic Grounding Template Structure" as a template | Lines 34-58 |
| **Documenting exceptions to patterns** | Reference the "Failure Recovery & Escalation" section | Lines 223-250 |

---

## What Are Grounding Templates?

Grounding templates are **standardized reference documents** that establish common patterns, constraints, and execution context for scripts within a specific technology domain.

**They answer:** "What should I assume when working with [technology] in this project?"

---

## When Are Grounding Templates Used?

Grounding templates are created and referenced when:

1. **A new technology domain enters the project** (e.g., Docker, Kubernetes, AWS)
2. **Multiple scripts need to share context** (Docker Compose files, environment patterns, configuration structures)
3. **Developers (or Claude) need to understand conventions** before writing/modifying code
4. **Standards must be enforced** across multiple scripts in the same domain

**Example:** When bootstrap metadata system expands beyond shell scripts to include Docker orchestration, a Docker grounding template establishes patterns that all Docker-related scripts follow.

---

## Generic Grounding Template Structure

Every grounding template follows this pattern:

```markdown
# [Technology] Grounding Template

## Purpose
[What this template grounds - e.g., "Docker container patterns for bootstrap services"]

## Core Constraints
- [Constraint 1: Hard rule that cannot be violated]
- [Constraint 2: Standard that must be followed]
- [Constraint 3: Pattern expectation]

## Assumed Patterns
[Bullet list of common patterns developers/Claude should expect in this domain]

## Key Decisions
[Decision 1: How [choice] is made in this project]
[Decision 2: Why [approach] was chosen over alternatives]

## References
[Links to implementation details in __bootbuild/templates/[technology]/]
```

---

## Why Separate Generic Intent from Tech-Specific Implementations?

| Aspect | Generic (This File) | Tech-Specific (__bootbuild/templates/) |
|--------|---------------------|------|
| **Purpose** | Document architectural CONCEPT and INTENT | Document concrete IMPLEMENTATION details |
| **Audience** | Future developers/architects planning expansion | Current developers/Claude implementing features |
| **Lifespan** | Remains stable as long as technology is used | Changes frequently with updates and refactoring |
| **Growth Path** | Expands as new tech domains enter the project | Each technology gets its own templates folder |
| **Reference** | "What should I think about?" | "How do I write this code?" |

---

## Expansion Plan

As the bootstrap system grows, this document evolves:

1. **Phase 1 (Current):** Document intent for shell scripts + docker domain
2. **Phase 2:** Add templates for Kubernetes (if adopted)
3. **Phase 3:** Add templates for IaC tools (Terraform, CloudFormation, etc.)
4. **Phase N:** Generic document becomes index of all grounding templates

Each new domain spawns a folder in `__bootbuild/templates/[technology]/` with implementation details.

---

## How Claude Uses Grounding Templates

When executing scripts in a grounded domain:

1. **Load the grounding framework** (`__bootbuild/docs/bootstrap-grounding-framework.md`) to understand intent and standards
2. **Reference domain-specific grounding** in `__bootbuild/templates/[domain]/grounding.md` (e.g., Docker, Shell Scripts)
3. **Verify new code follows patterns** established in domain grounding template
4. **Reference tech-specific templates** in `__bootbuild/templates/[technology]/` for implementation details
5. **Escalate if patterns conflict** with new requirements (see Failure Recovery section)

---

## Creating a Domain-Specific Grounding Template

When a new technology domain enters the bootstrap system, follow this process:

### Phase 1: Recognize the Domain
**Triggers for creating a grounding:**
1. Multiple scripts needed for same technology (>3 related scripts)
2. Shared configuration or patterns across scripts
3. Developers asking "what's the standard for [technology]?"
4. Architecture review planning expansion (Kubernetes, IaC, etc.)

### Phase 2: Establish the Domain Folder
```bash
# Create domain folder under __bootbuild/templates/
mkdir -p __bootbuild/templates/[domain]/

# Expected structure:
__bootbuild/templates/[domain]/
├── grounding.md          # This document you'll create
├── README.md             # Implementation guide
└── examples/             # Reference implementations
    ├── example-1.md
    └── example-2.md
```

### Phase 3: Write the Grounding Template
**Template structure (follow the generic pattern):**

```markdown
# [Technology Name] Grounding Template

## Purpose
[What patterns this domain standardizes]

## Core Constraints
- [Hard rules that cannot be violated]
- [Standards that must be followed]
- [Pattern expectations]

## Assumed Patterns
[List common patterns developers should expect]

## Key Decisions
- [Decision 1: Why chosen over alternatives]
- [Decision 2: Trade-offs accepted]

## Implementation Examples
[Links to reference implementations in this domain]

## References
[Links to documentation, bootstrap scripts using this pattern]
```

### Phase 4: Validate Grounding Completeness
Before considering a domain "grounded", verify:
- [ ] 3+ existing implementations follow the documented patterns
- [ ] Exceptions are documented (not silent deviations)
- [ ] All 4 Success Criteria met (see "Grounding Success Criteria" section)
- [ ] Domain maintainer identified
- [ ] `/bryan` playbook references this grounding in analysis

### Phase 5: Integrate with Bootstrap System
- [ ] Update this framework file (Current Domains table)
- [ ] Link from `__bootbuild/docs/` index
- [ ] Reference in pre-commit hooks or validation scripts (if patterns are auto-checkable)
- [ ] Announce to team (if applicable)

---

## Specification Completeness Checklist

**Used by `/bryan` playbook (PLAY 1.4) to validate structural integrity before gap analysis.**

Every specification—regardless of type (API, Migration, Configuration, Execution Plan)—has REQUIRED sections. Missing sections are BLOCKERS: they indicate fundamental design gaps, not polish issues.

### Generic Checklist

Apply this to any specification being reviewed:

**REQUIRED (if missing → BLOCKER):**
- [ ] Purpose & Goals (what + why)
- [ ] Architecture or Design (how phases/components interact)
- [ ] Dependencies & Prerequisites (what must exist first)
- [ ] Configuration & Parameters (all injectable values documented with examples)
- [ ] Failure Recovery (what to do when things break)
- [ ] Success Criteria (how to verify completion)

**RECOMMENDED (if missing → escalate):**
- [ ] Resource Requirements (time, cost, compute)
- [ ] Rollback Plan (how to undo)
- [ ] Known Limitations (what won't work)

**DECISION AUDIT (verify for consistency):**
- [ ] Tech stack consistent across all sections
- [ ] All examples are valid/executable
- [ ] No vague "if applicable" in requirements
- [ ] No contradictions between sections

**If >2 REQUIRED sections missing:** Escalate to architect before gap analysis. The spec has structural problems that polish won't fix.

### Usage in `/bryan`

When running `/bryan` against a specification:
1. Identify spec type based on initial context (migration plan, API spec, configuration, execution guide, etc.)
2. Load this checklist mentally (generic, not tech-specific)
3. Scan for structural completeness
4. Flag any MISSING REQUIRED sections as BLOCKER before analyzing gaps
5. If too many structural issues → recommend spec redesign instead of improvement iteration

---

## Current Domains

| Domain | Status | Location | Grounding Template | Notes |
|--------|--------|----------|---------------------|-------|
| **Shell Scripts** | ✅ Complete | `__bootbuild/templates/scripts/` | [`grounding.md`](../../../__bootbuild/templates/scripts/grounding.md) | 24 constraints documented; all 42 scripts follow pattern; pre-commit hooks ready for integration |
| **Docker/Compose** | 🟡 Ready | `__bootbuild/templates/docker/` | TBD (Phase 3-4) | **NEXT** — Tier system (sandbox/dev/prod) established, awaiting Phase 3-5 workflow |
| **Specifications** | ✅ Complete | `__bootbuild/docs/bootstrap-grounding-framework.md` (this file) | Active | Framework document itself; reusable spec completeness checklist for /bryan playbook |
| **Kubernetes** | ⏳ Planned | `__bootbuild/templates/kubernetes/` | Phase 2 TBD | Adoption decision pending; reserved for future expansion |
| **Infrastructure-as-Code** | ⏳ Planned | `__bootbuild/templates/iac/` | Phase 3 TBD | Terraform, CloudFormation patterns; after Kubernetes adoption |
| **[Custom Domain]** | ⏳ Reserved | `__bootbuild/templates/[domain]/` | TBD | Use framework to ground custom domains as needed |

---

## Failure Recovery & Escalation

**STATUS: COMPLETE** ✅

Defines procedures when script or pattern conflicts with established grounding:

1. **Pattern Violation Detected**
   - Script doesn't follow documented patterns for its domain
   - Action: Flag as "pattern exception" in script comments
   - Escalate to: Architect review (not a routine fix)

2. **Grounding Assumption Breaks**
   - Real-world requirement contradicts established pattern
   - Action: Document exception + business case
   - Escalate to: PRD review + pattern update decision

3. **Domain Expansion Needed**
   - New technology entering project doesn't match existing templates
   - Action: Create new domain folder in `__bootbuild/templates/[domain]/`
   - Escalate to: Design phase (PLAY 1 of /bryan) before implementation

4. **Cross-Domain Conflict**
   - Pattern from Domain A conflicts with Domain B
   - Action: Document conflict matrix
   - Escalate to: Architect for resolution strategy

**When to Escalate:** If fix requires changing established pattern (not local exception)

---

## Grounding Success Criteria

**STATUS: COMPLETE** ✅

A domain is considered "successfully grounded" when:

✅ **Structural Completeness**
- [ ] Generic grounding template exists (this file or domain-specific)
- [ ] 3+ implementations follow the pattern consistently
- [ ] Exception-handling rules documented

✅ **Pattern Consistency**
- [ ] 90%+ of new scripts in domain follow established pattern
- [ ] Violations are documented exceptions (not silent deviations)
- [ ] Pattern enforced by automated validation (e.g., pre-commit hooks)

✅ **Documentation Completeness**
- [ ] Core constraints documented (lines 28-52 level)
- [ ] Key decisions explained with rationale (why this approach)
- [ ] References point to implementation examples

✅ **Maintenance Readiness**
- [ ] Pattern updates procedure defined
- [ ] Rollback/exception procedure documented
- [ ] Domain maintainer identified

**Evaluation:** Grounding is STABLE when all 4 categories ✅

---

## Decision Framework: When to Ground a Domain

### Quick Checklist

Ask these questions when evaluating whether a technology domain needs grounding:

| Question | Yes → Action | No → Wait |
|----------|---|---|
| **Are there 3+ scripts for this technology?** | Document patterns (grounding needed) | Monitor; revisit at 3+ scripts |
| **Do developers ask "how should we [technology]?"** | Establish standards now (grounding needed) | Patterns still emergent; let settle |
| **Are scripts using conflicting patterns?** | Standardize urgently (grounding URGENT) | Consistency acceptable; defer |
| **Is this technology in architecture plan?** | Prepare grounding template (pre-grounding) | No action needed yet |

### Grounding Readiness Matrix

| Factor | Not Ready | Ready for Grounding | Fully Grounded |
|--------|-----------|-------------------|----------------|
| **Script Count** | 1-2 | 3-5 | 5+ consistent implementations |
| **Pattern Maturity** | Emerging (chaotic) | Established (documented) | Stable (enforced) |
| **Team Familiarity** | Exploring | Understanding | Mastery |
| **Documentation** | Implicit only | Partially documented | Complete + validated |
| **Automation** | Manual checks | Partial validation | Full CI/CD integration |

**Decision:** If you meet "Ready for Grounding" or "Fully Grounded" criteria, create/update the grounding template.

---

## Cross-Domain Precedence Framework

**Rationale:** As the bootstrap system expands (Shell Scripts → Docker → Kubernetes → IaC), multiple domains interact and naming/execution patterns can conflict. This framework establishes clear precedence rules.

### Precedence Tiers (Priority Ordering)

```
Tier 1 (CRITICAL): SECURITY > ALL
Tier 2 (HIGH):     EXECUTION SAFETY > CONSISTENCY
Tier 3 (MEDIUM):   IDEMPOTENCY > PERFORMANCE
Tier 4 (STANDARD): CONSISTENCY > CONVENIENCE
Tier 5 (LOW):      CONVENIENCE > DOCUMENTATION
```

**How to Use:** When patterns conflict between domains, find the affected tier and apply its rule. Higher tiers always win.

### Domain Characteristics & Authority

| Domain | Authority | Patterns | Current | Examples |
|--------|-----------|----------|---------|----------|
| **Shell Scripts** | Canonical (source of truth) | @script tags, phases 1-5, category enum | ✅ Active (50+ scripts) | bootstrap-postgres.sh, @phase 3, @category database |
| **Docker** | Service-level (within compose) | Service names, tier-based config (sandbox/dev/prod) | ✅ Active (3 tiers) | container_name: sparkq_postgres, tier_prod |
| **Kubernetes** | Resource-level (clusters) | Resource naming, labels, ConfigMap/Secret | ⏳ Planned | sparkq-postgres-statefulset, app: sparkq |
| **IaC (Terraform/CloudFormation)** | Infrastructure-level (cloud) | Resource tagging, environment prefixes | ⏳ Planned | prod-sparkq-postgres-instance, tags: {Project: sparkq} |

### Key Conflict Resolution Examples

**Example 1: Naming Convention Conflict**
```
Shell Scripts: bootstrap-postgres.sh (kebab-case, "bootstrap-" prefix)
Docker:        sparkq_postgres (snake_case, project prefix)
Kubernetes:    sparkq-postgres-statefulset (kebab-case, type suffix)
IaC:           prod-sparkq-postgres (env prefix, project, component)

Resolution: Each domain is AUTHORITATIVE within its scope
✅ CORRECT: Use domain-native patterns; bridge via COMPONENT NAME
├─ Shell: bootstrap-postgres.sh → COMPONENT = "postgres"
├─ Docker: Extract component from script name → service: postgres
├─ K8s: Use component in resource name → sparkq-postgres-statefulset
└─ IaC: Tag with source script → tags.BootstrapScript = "bootstrap-postgres"
```

**Example 2: Safety Declaration Conflict**
```
Shell declares:        @safe=no (backup operation, destructive)
Docker tier:           sandbox (permissive, development-only)
Kubernetes:            Production cluster (restrictive)
IaC:                   No encryption required (development)

Resolution: MOST RESTRICTIVE WINS (Tier 2: Safety)
✅ CORRECT: Respect @safe=no even in sandbox
├─ Sandbox execution: Still require user confirmation
├─ K8s execution: Additional safeguards (immutable backups, audit logging)
└─ IaC execution: Highest security (encrypted backups, versioning)
```

**Example 3: Idempotency Conflict**
```
Shell declares:        @idempotent=yes (can run multiple times)
Docker state:          Volume persistence (idempotent at service level)
Kubernetes:            ConfigMap updates (may require pod restart)
IaC state:             Terraform plan can detect drift

Resolution: IDEMPOTENCY IS LOCAL CONTRACT (Tier 3)
✅ CORRECT: Each layer maintains idempotency within its scope
├─ Shell: Script checks before modifying, returns 0 if already done
├─ Docker: docker-compose up is idempotent (no duplicate containers)
├─ K8s: kubectl apply is idempotent (unless ConfigMap immutable)
└─ IaC: terraform plan shows only actual changes, no redundant updates
```

### Bridge Mapping Table

For cross-domain references, use this canonical mapping:

```json
{
  "shell_to_kubernetes": {
    "bootstrap-postgres": {
      "k8s_statefulset": "sparkq-postgres",
      "k8s_service": "postgres",
      "k8s_configmap": "postgres-config",
      "k8s_labels": {"app": "sparkq", "component": "database"}
    }
  },
  "shell_to_terraform": {
    "bootstrap-postgres": {
      "resource_name": "prod-sparkq-postgres",
      "resource_type": "aws_rds_instance",
      "terraform_tags": {"BootstrapScript": "bootstrap-postgres", "Category": "database"}
    }
  }
}
```

**Usage:** When generating Kubernetes manifests from shell scripts, reference this table to maintain naming consistency and add bootstrap traceability labels.

### When to Escalate Cross-Domain Conflicts

```
Pattern Conflict Detected?
    ↓
1. Identify which domains involved
2. Determine affected tier (Security? Safety? Idempotency? ...)
3. Apply precedence rule from that tier
4. If rule produces unsafe result → STOP and escalate to architect
5. If no precedence rule applies → Add to framework, then apply

Example escalations:
- Security constraint violated? → Stop, escalate immediately
- Idempotency promise broken? → Document exception, escalate
- New domain interaction type? → Add to precedence table
```

**Full Framework Reference:** See `__bootbuild/config/precedence-matrix.md` (when created) for complete cross-domain conflict resolution matrix with all 6+ conflict scenarios and exception handling procedures.

---

## Resource Requirements

**Effort Estimates for Creating Domain Groundings:**

| Phase | Activity | Effort | Owner | Notes |
|-------|----------|--------|-------|-------|
| **Phase 1: Recognize** | Identify need, gather existing patterns, document context | 1-2 hours | Architect | Meeting + analysis |
| **Phase 2: Establish** | Create folder structure, setup naming conventions | 30 minutes | Developer | One-time setup |
| **Phase 3: Write** | Create grounding template + documentation | 4-8 hours | Architect + Codex | Document patterns, decision rationale |
| **Phase 4: Validate** | Collect 3+ implementation examples, verify consistency | 2-4 hours | Team + Architect | Review existing scripts, test patterns |
| **Phase 5: Integrate** | Update framework file, link documentation, announce | 1 hour | Developer | File updates + communication |
| **TOTAL** | Complete domain grounding | **8-16 hours** | Team | Typically 1-2 sprints |

**Token Budget (AI-Assisted):**
- Codex (documentation generation): 200-400 tokens (writing grounding template)
- Haiku (pattern validation): 100-200 tokens (checking examples)
- Sonnet (decision rationale): 300-500 tokens (why decisions made)
- **Total AI tokens: ~700-1,100 tokens per domain**

**Dependencies:**
- ✅ Existing patterns must be documented (implicit or explicit)
- ✅ 3+ working implementations available for validation
- ✅ Domain expert (architect) available for decision rationale
- ✅ Team consensus on "stable" patterns before grounding

**Rollback Plan (if grounding proves wrong):**
1. Document the failure reason (why patterns don't fit)
2. Create "exception" subsection in grounding
3. Escalate to architect for re-evaluation (PLAY 1 of /bryan)
4. Do NOT delete grounding; instead mark as "revised" with date

---

## Known Limitations & Exceptions

**This framework covers:**
- ✅ Standardizing patterns WITHIN a technology domain (Docker, Kubernetes, Shell Scripts, etc.)
- ✅ Establishing constraints and consistency rules for script generation
- ✅ Defining failure recovery procedures when patterns conflict
- ✅ Providing reusable spec completeness checklist for any specification type

**This framework does NOT cover:**
- ❌ **CI/CD Pipeline Templates** — Pipeline orchestration patterns belong in CI/CD-specific grounding (future)
- ❌ **Infrastructure-as-Code Definitions** — Terraform/CloudFormation state patterns belong in IaC grounding (Phase 3)
- ❌ **Project-Specific Policies** — Team agreements (code review, testing standards) belong in project CLAUDE.md
- ❌ **Runtime Deployment Orchestration** — Docker Swarm, Kubernetes deployment strategies belong in operations documentation
- ❌ **Security Policies** — Authentication, encryption, secrets management belong in security framework
- ❌ **Database Schema Patterns** — SQL patterns, migrations belong in database-specific grounding (future)

**When to Create Additional Frameworks:**
If your technology domain needs standards that span beyond what grounding templates provide, consider creating a domain-specific **Execution Framework** alongside the grounding. Example:

```
__bootbuild/templates/cicd/
├── grounding.md              # Patterns for CI/CD scripts
└── execution-framework.md    # Full pipeline orchestration standards
```

---

## First Implementation: Shell Scripts Grounding (Quick Start)

**Current Status:** Grounding framework ACTIVE, Shell Scripts domain READY FOR GROUNDING

**Shell Scripts Domain Assessment:**
- ✅ Trigger: 42+ scripts exist with @script tag metadata system
- ✅ Pattern Maturity: Established (@script tags, phase system, categories documented)
- ✅ Implementation Count: 42 scripts follow @script pattern consistently
- ⏳ Status: Ready for Phase 1-5 workflow (see "Creating a Domain-Specific Grounding Template")

**Immediate Next Step (Now):**
Create `__bootbuild/templates/scripts/grounding.md` documenting:
1. **Purpose:** Shell script metadata and @script tag patterns
2. **Core Constraints:** Mandatory @script tags, required fields (version, phase, category, priority)
3. **Assumed Patterns:** All scripts follow bash 4+, use standard shebang, include metadata headers
4. **Key Decisions:** Why @script tags, why phase-based organization, dependency graph format
5. **References:** Point to existing implementations like `bootstrap-typescript`, `bootstrap-docker`

**Who Creates This:**
- **Architect review:** Architecture alignment (Opus/Sonnet 1-2 hours)
- **Template writing:** Codex generation from specification (300 tokens)
- **Validation:** Review 3+ implementations, verify consistency (1-2 hours)

**Success Criteria (for Shell Scripts grounding):**
- [ ] Grounding template created at `__bootbuild/templates/scripts/grounding.md`
- [ ] All 4 Success Criteria met (see "Grounding Success Criteria" section)
- [ ] All 42 existing scripts validate against grounding
- [ ] New scripts are validated by pre-commit hook against grounding
- [ ] Domain marked as "✅ FULLY GROUNDED" in Current Domains table

---

## Next Steps

**Implementation Roadmap:**

### Completed (Round 2 of /bryan audit)

- [x] **✅ Shell Scripts Grounding Template** (COMPLETE)
  - Location: `__bootbuild/templates/scripts/grounding.md`
  - Content: 24 concrete, automatable constraints + 5 assumed patterns + pre-commit hook integration
  - Status: Ready for validation library implementation (`__bootbuild/lib/validate-constraints.sh`)
  - Next: Integrate with pre-commit hooks (.husky/pre-commit) and CI/CD pipeline

### In Progress (LOCAL PRE-COMMIT FOCUS)

- [ ] **Create validation library** (`__bootbuild/lib/validate-constraints.sh`)
  - Goal: Implement all 24 constraint checks from Shell Scripts grounding
  - Automatable: script name, version, phase, category, priority, spacing, manifest sync, phase sequencing
  - **Scope: LOCAL ONLY** (no external calls, no network I/O)
  - ROI: 3.5x (enables automated constraint enforcement)

- [ ] **Integrate local pre-commit hooks** (PRIMARY FOCUS)
  - Location: `.git/hooks/pre-commit` or `.husky/pre-commit`
  - Actions: Run validation library on bootstrap-*.sh changes before commit
  - Also: Update manifest.json if metadata changed
  - **Disabled by default** (user must run `git config core.hooksPath .git/hooks` to enable)
  - ROI: 4.1x (prevents invalid scripts entering repository locally)

### Coming Soon (Phase 2)

- [ ] **Create Docker grounding template**
  - Location: `__bootbuild/templates/docker/grounding.md`
  - Goal: Document Docker container patterns, Compose structure, tier configurations
  - Reference: Existing work in `__bootbuild/templates/docker/`, leverage bridge mappings from precedence framework
  - Estimated: 8-16 hours (following Shell Scripts grounding pattern)

- [ ] **Create precedence-matrix.md (detailed)**
  - Location: `__bootbuild/config/precedence-matrix.md`
  - Goal: Full expansion of cross-domain precedence framework (6 conflict scenarios, exception handling, decision trees)
  - Foundation: Summary already in framework file; detailed version for specialist reference

- [ ] **Create category-bridge.json**
  - Location: `__bootbuild/config/category-bridge.json`
  - Goal: Canonical mapping between shell @category, Kubernetes labels, and IaC tags
  - Structure: Follows example from precedence framework section

### Optional: GitHub Actions Templates (DISABLED BY DEFAULT)

- [ ] **CI/CD pipeline template** (template only, not enabled)
  - Location: `.github/workflows/validate-bootstrap.yml.template`
  - Status: Create as optional reference, not required
  - Activation: Teams must explicitly enable in GitHub settings if desired
  - Cost concern: Disabled to avoid excessive Actions usage
  - Note: Local pre-commit hooks provide sufficient validation for most workflows

### Future (Phase 3+)

- [ ] Use as reference during architecture reviews for new tooling (Kubernetes, IaC, etc.)
- [ ] Expand to Kubernetes domain grounding (Phase 3)
- [ ] Expand to Infrastructure-as-Code domain grounding (Phase 4)
- [ ] Create domain-specific checklist files in `__bootbuild/docs/` for `/bryan` integration
