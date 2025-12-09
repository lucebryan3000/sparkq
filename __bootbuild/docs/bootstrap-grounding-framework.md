# Bootstrap Grounding Framework

**Purpose:** Establish the architectural framework for grounding templates across all bootstrap system domains. This document defines the concept, standards, and expansion path for creating technology-specific grounding templates that standardize patterns across `__bootbuild/templates/scripts/` and `__bootbuild/templates/[technology]/` domains.

**Scope:**
- Generic grounding template concept and structure
- Specification completeness validation checklist (reusable across all projects)
- Framework for domain-specific implementations (Shell Scripts, Docker, Kubernetes, IaC, etc.)
- Pattern consistency enforcement and failure recovery procedures

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
| **Shell Scripts** | ✅ Core | `__bootbuild/scripts/` + `__bootbuild/templates/scripts/` | TBD (in-progress) | Foundation; @script tag metadata system established; awaiting formal grounding doc |
| **Docker/Compose** | 🟡 Emerging | `__bootbuild/templates/docker/` | TBD (in-progress) | Patterns established during bootstrap expansion; tier system (sandbox/dev/prod) |
| **Specifications** | 📋 Framework | `__bootbuild/docs/bootstrap-grounding-framework.md` (this file) | Active | Generic spec completeness validation; applies to API specs, migrations, configs, execution plans |
| **Kubernetes** | ⏳ Reserved | `__bootbuild/templates/kubernetes/` | TBD | Planned for Phase 2; no grounding yet |
| **Infrastructure-as-Code** | ⏳ Reserved | `__bootbuild/templates/iac/` | TBD | Planned for Phase 3; Terraform, CloudFormation patterns |
| **[Custom Domain]** | ⏳ TBD | `__bootbuild/templates/[domain]/` | TBD | Reserved for project-specific expansions |

---

## Failure Recovery & Escalation

**STATUS: REQUIRED SECTION - IN PROGRESS**

When a script or pattern conflicts with established grounding:

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

**STATUS: REQUIRED SECTION - IN PROGRESS**

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

## Next Steps

**Implementation Roadmap:**

- [ ] //TODO: Expand Shell Scripts grounding template
  - Location: `__bootbuild/templates/scripts/grounding.md`
  - Goal: Document patterns for bootstrap script metadata (@script tags, phases, categories, dependencies)
  - Reference: Bootstrap header structure in `__bootbuild/templates/scripts/`

- [ ] //TODO: Create Docker grounding template
  - Location: `__bootbuild/templates/docker/grounding.md`
  - Goal: Document Docker container patterns, Compose structure, tier configurations
  - Reference: Existing work in `__bootbuild/templates/docker/`

- [ ] //TODO: Create `__bootbuild/docs/bryan/spec-templates/` with domain-specific checklists
  - Goal: Improve structural validation in `/bryan` before deep analysis
  - When ready: Move spec checklist items into domain-specific files (api.md, migration.md, config.md, execution.md)
  - Integration: `/bryan` PLAY 1.4 will load domain-specific checklist based on spec type

- [ ] Use as reference during architecture reviews for new tooling (Kubernetes, IaC, etc.)
