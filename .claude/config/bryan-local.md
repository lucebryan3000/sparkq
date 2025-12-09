# Local /bryan Configuration for sparkq

> **Project:** sparkq
> **Last Updated:** 2025-12-08
> **Profile Version:** v1.0

---

## Path Configuration

These variables are used throughout `/bryan` playbook when analyzing sparkq work.

```
{PROFILE_PATH}    = __bootbuild/docs/bryan
{PROFILE_FILE}    = __bootbuild/docs/bryan/bryan_developer_profile_v1.0.md
{BUILD_DIR}       = _build
{SCRIPTS_DIR}     = __bootbuild/scripts
{LIB_DIR}         = __bootbuild/lib
{CONFIG_DIR}      = __bootbuild/config
{TEMPLATES_DIR}   = __bootbuild/templates
{GIT_HOOKS_DIR}   = .git/hooks
{BOOTSTRAP_HOOKS} = __bootbuild/.git/hooks
```

---

## Hard Rules for sparkq

**These rules are non-negotiable.** Any work violating these should be flagged in /bryan analysis.

1. **No Permission Prompts**
   - All work executes autonomously (bypasses permission checks)
   - Never ask "is this ok?" or "should I proceed?"
   - Feature: `bypassPermissions` enabled in project

2. **Implementation Over Explanation**
   - Write code first, explain briefly after
   - No "here's what I'm going to do" preambles
   - No "let me know if you want me to..." hedging
   - Just do it, then summarize

3. **Self-Test Before UAT**
   - Run automated tests (`npm test`) BEFORE requesting Bryan's UAT
   - Fix failing tests immediately
   - Only ask for UAT after tests pass
   - UAT is for UX/edge cases, not finding bugs

4. **TypeScript Strict Mode**
   - Explicit return types on exports
   - No `any` without justification comment
   - Zod for runtime validation
   - Strict mode always enabled

5. **Code Style**
   - 2 spaces, no tabs
   - Single quotes
   - No semicolons (Prettier handles)
   - Trailing commas in multiline
   - No comments unless logic is non-obvious

6. **No Fake Data or Placeholders**
   - Real values or deterministic generation
   - No `TODO`, `FIXME`, `[X]` in deliverables
   - Configuration from environment variables

7. **Git Discipline**
   - Feature branches for major changes (10+ files)
   - Feature branch format: `feature/[name]` or `fix/[name]`
   - No force-push on main
   - Commit messages: `type(scope): description`

---

## Tool Stack & Dependencies

### Runtime
- **Language:** TypeScript (strict mode)
- **Framework:** [TBD - POC phase]
- **Node.js:** Latest LTS

### Build & Test
- **Build Tool:** npm
- **Test Framework:** Jest
- **Linter:** ESLint
- **Formatter:** Prettier
- **TypeScript:** Latest stable

### Bootstrap System
- **Shell:** bash 4+
- **Config Format:** JSON (manifest)
- **Scripts:** bash with @-tag metadata headers
- **Validation:** Haiku pre-check before execution

### Parallel Execution
- **Max Parallel:** 4 (Codex batches)
- **Model Delegation:** Codex (code gen) → Sonnet (orchestration) → Haiku (validation)
- **Feature Flag:** Not required (autonomous execution)

---

## Model Selection Hierarchy (sparkq)

**Reference Bryan's Profile** (lines 126-133) for full matrix. Quick reference:

| Task | Best Model | Why |
|------|------------|-----|
| Code generation (scripts, boilerplate, 10+ files) | **Codex** | Pure spec → $0 cost, fastest |
| Syntax/validation/placeholder checks | **Haiku** | Quick checks → <1K tokens |
| Prompt generation, orchestration, multi-step | **Sonnet** | Reasoning required → handles complexity |
| Architecture decisions, PRD feedback | **Opus** | Strategic thinking → rare use |

---

## Directory Structure for File Placement

Use this when classifying files during major refactors (Gate 3.5):

```
__bootbuild/
├── lib/                              # Reusable libraries (sourced by others)
│   ├── generate-manifest.sh          # Manifest generator (permanent)
│   ├── validate-metadata.sh          # Metadata validator (permanent)
│   ├── detect-functions.sh           # Detection functions (auto-generated)
│   └── paths.sh                      # Path constants (permanent)
│
├── scripts/                           # Executable scripts & tools
│   ├── bootstrap-manifest-gen.sh     # Major generators
│   ├── reconcile-state.sh            # Analysis tools
│   └── setup-hooks.sh                # Installation scripts
│
├── .git/hooks/                        # Actual Git hook implementations
│   ├── pre-commit                    # Pre-commit validation
│   └── post-merge                    # Post-merge checks
│
├── templates/
│   ├── scripts/                      # Bootstrap scripts (@script tagged)
│   └── root/                         # Source templates for scripts
│
├── config/                            # Configuration files
│   ├── bootstrap-manifest.json       # Generated, never edit directly
│   ├── bootstrap-manifest.json.original  # Backup before refactor
│   ├── bootstrap-questions.json      # Questions for scripts
│   └── bootstrap-metadata.json       # Metadata reference
│
├── docs/
│   └── bryan/
│       └── bryan_developer_profile_v1.0.md  # Standards profile
│
└── _build/                            # Temporary workspace (gitignored)
    ├── prompts/                      # Generated prompts (temporary)
    ├── output/                       # Build output (temporary)
    └── archive/                      # Historical records
        ├── 2025-12-08-reconciliation-report.sh
        ├── checkpoints-2025-12-08.log
        └── migration-notes.md
```

### File Placement Decision Tree (Major Refactors)

```
Is this file generated during the refactor?
  ├─ Yes → Will it run again after initial use?
  │   ├─ No (one-time) → _build/ or _build/archive/
  │   └─ Yes (permanent)
  │       ├─ Is it a generator/utility? → lib/
  │       ├─ Is it a Git hook? → .git/hooks/
  │       ├─ Is it a major script? → scripts/
  │       └─ Is it config? → config/
  │
  └─ No → Where does it belong?
      ├─ If output/artifacts → _build/
      ├─ If permanent → lib/, scripts/, config/, or hooks/
      └─ If historical → _build/archive/
```

---

## Profile Reference Points

When `/bryan` analysis references the profile, use these sections:

| Section | Location | Purpose |
|---------|----------|---------|
| Model Selection Matrix | Profile lines 126-133 | Verify correct AI assignment |
| Haiku Use Cases | Lines 148-170 | When to use lightweight model |
| Codex Use Cases | Lines 172-200 | When to use code generator |
| Output Constraints | Lines 218-236 | Token limits, formatting rules |
| Token Tracking | Lines 251-262 | Cost/savings estimation |
| Iteration Thresholds | Lines 208-216 | Expected passes before escalation |
| Hard Rules | Lines 79-98 | Non-negotiables for sparkq |
| Git Strategy | Lines 890-915 | Branching, commits, rollback |
| Location Guidance | Lines 890-950 | Where files belong |
| Token Constraints | Lines 489-493 | Cost defaults per task |

---

## Token Budget Reference

**Profile defaults for sparkq (from lines 489-493):**
- Code generation task: ~1K tokens per file
- Orchestration/prompt generation: 1-3K tokens
- Validation passes: <1K tokens each
- Architecture review: 2-5K tokens
- ROI threshold: >1.5x (implement), 1.0-1.5x (optional), <1.0x (skip)

---

## Playbook Enhancements (v1.1)

The `/bryan` playbook has been enhanced with 5 new gates to formalize the Sonnet-as-keeper workflow:

| Enhancement | Gate | Purpose | Pattern |
|---|---|---|---|
| **Codex Refinement Cycles** | Gate 1.2b | Formalizes 1-3 Sonnet ↔ Codex loops for spec hardening until 9/10 ready | Sonnet writes → Codex validates → Sonnet refines → Freeze |
| **Behavioral Coordination** | Gate 2.1b | Audits cross-spec contracts and temporal dependencies | Catches coordination gaps that Codex will flag |
| **Validation Executability** | Gate 3.2b | Identifies manual grep chains that waste tokens | Codex scans for; Sonnet delegates to Haiku |
| **Validation Cost Analysis** | Gate 4.1a | Calculates ROI of delegating validation to Haiku | Part of Sonnet's keeper decisions on quality gates |
| **Pre-Flight Decision** | Gate 5.1b | Determines if plan needs pre-flight validation script | Codex can pre-write after spec is 9/10 ready |

**Workflow Context:**
- Sonnet acts as **keeper** (scope, tradeoffs, process decisions)
- Codex acts as **validator** (scans specs for gaps, suggests improvements)
- Loop: 1-3 cycles until spec reaches 9/10 readiness (implementation-ready)
- After 9/10 ready: Codex can pre-write code from specs (like menu_fixes batch generation)
- Token optimization: Stop at 9/10, don't chase 10/10 perfection (diminishing ROI)

---

## Known Issues & Tech Debt

*None currently tracked. Update as issues discovered during /bryan analysis.*

---

## How to Update This File

1. After running `/bryan` analysis, review new gaps or hard rules discovered
2. Add new sections if playbook references paths not listed above
3. Update directory structure if project layout changes
4. Commit changes to main (this file is project-specific, not shared)

---

## Notes for Other Projects

**To adapt `/bryan` for another project:**
1. Copy this file as a template
2. Update all `{VARIABLE}` paths to match the new project
3. Replace Hard Rules section with project-specific standards
4. Update Tool Stack based on new project's tech choices
5. Update Directory Structure tree to match actual layout
6. Add project-specific model selection preferences if different from default
7. Create a slash command `/load-bryan-local` that sources this file before `/bryan`

**Example for different project:**
```markdown
# Local /bryan Configuration for [project-name]

{PROFILE_PATH}    = docs/standards/developer-profile
{BUILD_DIR}       = build
{SCRIPTS_DIR}     = scripts
...
```

---

**Last verified:** 2025-12-08
**Status:** Ready for use with `/bryan` playbook
