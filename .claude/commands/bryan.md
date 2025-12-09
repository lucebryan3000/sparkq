# /bryan - Developer Standards Alignment Playbook

> **Version**: v1.1
> **Status**: Production Ready (Enhanced)
> **Last Updated**: 2025-12-09

**Purpose:** Systematic 6-PLAY audit process to validate structural completeness, identify architectural gaps, propose 1-2 high-value improvements aligned with your developer profile, and ground Claude in standards for this session.

**Recent Enhancements (v1.1):**
- **Gate 1.2b**: Controlled Spec Refinement Tracking (formalizes intentional Sonnet ↔ Codex loops for hardening)
- **Gate 2.1b**: Behavioral coordination audit for multi-spec work (catches cross-spec contract gaps)
- **Gate 3.2b**: Validation gate executability check (identifies manual validation chains that waste tokens)
- **Gate 4.1a**: Validation cost analysis (calculates ROI of delegating validation to Haiku)
- **Gate 5.1b**: Pre-flight validation decision gate (determines if plan complexity requires pre-flight script)
- These enhancements formalize the Sonnet-as-keeper workflow where Codex validates specs 1-3 cycles until 9/10 ready

**Focus:** Unlock "art of the possible" from your profile, not cosmetic polish. BLOCKER gaps + 1-2 architectural improvements per audit round.

---

## QUICK START

### Setup: Load Local Configuration

**Before using `/bryan`, load your project's configuration:**

```bash
/load-bryan-local
```

This loads path variables and project-specific standards used throughout (see REFERENCE section for details).

**Profile Location:** `.claude/config/bryan-local.md`

---

### When to Use `/bryan`

**NOT for routine work.** This playbook is for:

- Plans with architectural uncertainty (multiple phases, model delegation, handoffs)
- Specs that are large (>2K tokens) or complex (10+ files affected)
- Multi-phase migrations where Phase 1 gaps cascade into Phase 2+ failures
- When you want to validate "art of the possible" — unlock what your architecture truly enables

**Expected Output:** Structural validation (REQUIRED sections checked) + BLOCKER gaps + 1-2 high-value architectural improvements (not cosmetic polish)

**Quick Decision:** If failure cost < 5K tokens, skip. If failure cost > 10K tokens or uncertainty is high, run `/bryan` first.

**Example ROI:** metadata-fix.md plan had 7 gaps (2 BLOCKERS + 4 HIGH + 1 MEDIUM). Without audit: ~19.5K token waste. With `/bryan` pre-flight: 4.5K audit cost = **4.3x ROI**.

---

## EXECUTION FLOW

```
┌─────────────────────────────────────────────────────────────┐
│ PLAY 1: Load Profile & Validate Structural Completeness   │
│ ↓ Check REQUIRED sections, load standards, classify gaps  │
├─────────────────────────────────────────────────────────────┤
│ PLAY 2: Find Architectural Gaps                           │
│ ↓ Identify BLOCKERS + HIGH-value gaps (not polish)        │
├─────────────────────────────────────────────────────────────┤
│ PLAY 3: Propose 1-2 High-Value Architectural Improvements │
│ ↓ Each unlocks capability, assigned, ROI-justified        │
├─────────────────────────────────────────────────────────────┤
│ PLAY 4: Output Structured Report                           │
│ ↓ Choose format, generate findings, offer execution        │
├─────────────────────────────────────────────────────────────┤
│ PLAY 5: Ground Session in Standards                        │
│ ↓ Copy-paste checklist for remaining work                  │
└─────────────────────────────────────────────────────────────┘
```

**Decision Gates:** Each PLAY has explicit success criteria. All criteria must pass before proceeding to next PLAY.

---

## PLAY 1: Load Profile & Analyze Current Work

### A. Identify Work Type (Gate 1.1)

**Before deep analysis, identify your work type:**

| Type | Examples | Go To |
|------|----------|-------|
| **PLAN** | `_build/metadata-fix.md`, architecture proposal, migration strategy | PLAY 1.B |
| **CODE** | `src/services/parser.ts`, `lib/detect.sh`, `components/` folder | PLAY 1.B |
| **PRD** | `_build/PRD/feature-x.md`, requirements document | PLAY 1.B |
| **GIT** | merge strategy, commit protocol, branch naming | PLAY 1.B |

**Success Criterion:** ✅ Work type identified

---

### B. Work-Type-Specific Validation (Gate 1.2)

#### For Plans:

- [ ] Clear phases/milestones (Phase 1, 2, 3, etc.)
- [ ] Each phase has explicit success criteria and exit conditions
- [ ] Model assignments specified (Codex, Haiku, Sonnet per phase)
- [ ] Git strategy defined (branch, checkpoints, rollback instructions)
- [ ] Parallel vs sequential marked explicitly for each task/phase
- [ ] Testing/validation strategy present (self-test before UAT)
- [ ] Token cost/ROI analysis included
- [ ] Iteration thresholds defined (max cycles, escalation paths)
- [ ] **Codex refinement cycles tracked** (1-3 cycles documented; 9/10 readiness goal; keeper decisions captured)
- [ ] Behavioral coordination items documented (cross-spec contracts, temporal dependencies)

#### For Code:

- [ ] File sizes reasonable (<500 lines is baseline)
- [ ] Patterns follow project conventions (naming, structure, testing)
- [ ] Hard rules followed (no fake data, no permission prompts)
- [ ] Tech stack aligned (TypeScript, testing framework, build tool)
- [ ] Comments only where logic is non-obvious
- [ ] No premature abstractions or unused helpers
- [ ] Test coverage for public APIs/exports

#### For PRDs:

- [ ] Requirements clearly scoped (must-have vs nice-to-have marked)
- [ ] Success criteria measurable and specific
- [ ] Model selection appropriate
- [ ] Assumptions listed and justified
- [ ] Known constraints documented
- [ ] No ambiguity in acceptance criteria

#### For Git Decisions:

- [ ] Branch naming convention clear
- [ ] Merge strategy documented (squash, rebase, or standard)
- [ ] Rollback procedure spelled out
- [ ] No force-push on shared branches
- [ ] Commit message format defined

**Success Criterion:** ✅ All applicable checks completed

---

### Codex Refinement Cycle Tracking (Gate 1.2b - Sonnet ↔ Codex Refinement Loop)

**For spec plans being hardened through controlled Sonnet ↔ Codex cycles:**

**Pattern:** Sonnet writes spec → Codex validates by scanning/attempting → Codex feeds back gaps → Sonnet refines → Repeat 1-3 cycles until 9/10 ready

**Purpose:** Formalize this productive refinement loop (not waste oscillation, but intentional spec hardening)

**Tracking Template for Each Cycle:**

```
### Cycle N: [Focus Area]

**Sonnet writes/revises**: [What Sonnet changed in this cycle]
**Codex feedback**: [Specific gaps Codex found - missing sections, unclear Input/Output, coordination issues, etc.]
**Sonnet response**: [How Sonnet addressed feedback or decided to keep as-is]
**Keeper decisions made**: [Which items Sonnet decided to keep/remove/defer - scope choices]
**Readiness check**: [1/10 → 2/10 → 3/10... → 9/10 ready?]
**ROI assessment**: [Is each cycle improving, or diminishing returns?]
```

**Decision Gate - When to FREEZE (stop refining):**

```
After Cycle 1:
  ✅ IF Codex finds major gaps (3+ BLOCKER-level) → PRODUCTIVE → Continue to Cycle 2
  ❌ IF Codex finds nothing → Spec already mature → FREEZE, ready to implement

After Cycle 2:
  ✅ IF Codex feedback clearly addressed and spec now 8-9/10 ready → PRODUCTIVE → Optionally Cycle 3
  ⚠️  IF same issues persist → Spec fundamentally broken → Redesign or escalate

After Cycle 3:
  ✅ IF spec at 9/10 ready, Codex can pre-write (generate code from specs) → FREEZE HERE
  ❌ IF still <9/10 or issues repeat → Diminishing ROI → FREEZE and escalate to Opus

**Readiness Scoring**:
- 1-3/10: Early draft, major gaps expected
- 4-6/10: Partially specified, some coordination gaps
- 7-8/10: Well-specified, ready for small tweaks
- 9/10: Implementation-ready, Codex can pre-write
- 10/10: Perfect (rare; 9/10 is usually enough)
```

**Codex's Role as Spec Validator:**

Codex scans for:
- ✅ Input/Output format clear (can generate from this?)
- ✅ State contracts explicit (Spec 1.1 emits exit 124; Spec 2.3 must handle this?)
- ✅ Fallback behaviors defined (If jq fails, what happens?)
- ✅ Temporal dependencies clear (Write cache AFTER validation, BEFORE consumption?)
- ✅ Validation gates executable (Single command, not 10 manual grep steps?)
- ✅ No ambiguous "if applicable" requirements (Every requirement grounded in concrete scenario?)

**Sonnet's Role as Keeper:**

Sonnet decides:
- Scope: "Pre-flight validation is OPTIONAL (not BLOCKING)" → Stays in spec or moves to future work?
- Tradeoffs: "Behavioral coordination is 9 items → too much? Can we defer 2?" → Prioritize or keep all?
- Quality gates: "Manual validation chains waste tokens → delegate to Haiku" → Add improvement or keep manual?
- Process: "How many cycles needed? If 2 cycles get 9/10, freeze. Don't run cycle 3 for 10/10 perfection."

**Keeper decisions must be documented** in the spec (e.g., in header comments or assumptions section):
```
# Keeper Decisions:
# - Pre-flight validation: OPTIONAL (defer if time-constrained)
# - Behavioral coordination: ALL 9 items IN SCOPE (non-negotiable contracts)
# - Validation: Delegate manual gates to Haiku (see Improvement X in Gate 4.1a)
# - Cycles: Refined 2 cycles (Codex feedback on Batch 1 structure, coordination gaps);
#   spec now 9/10 ready → Freeze, proceed to implementation
```

**Success Criterion:** ✅ Codex refinement cycles tracked and keeper decisions documented (or N/A if single-pass spec)

---

### C. Structural Completeness Check (Gate 1.3)

**Before gap analysis, validate structural integrity:**

1. **Load Generic Checklist** → Reference spec completeness checklist in `_build/grounding_templates-scripts.md`
2. **Identify Work Type** → Based on context, determine spec type (migration plan, API spec, configuration, execution guide, architecture design, etc.)
3. **Scan for REQUIRED Sections** (context-aware):
   - Purpose & Goals
   - Architecture/Design
   - Dependencies & Prerequisites
   - Configuration & Parameters
   - Failure Recovery
   - Success Criteria

4. **Flag Missing Sections** → If >2 REQUIRED sections missing:
   - Mark as BLOCKER (not improvable)
   - Recommend spec redesign before `/bryan` continues
   - Suggest architect review

5. **Decision Consistency Audit** (if structural completeness ✅):
   - Tech stack consistent across all sections?
   - Examples valid/executable?
   - No vague "if applicable" requirements?

---

### D. Load Profile & Extract Standards (Gate 1.4)

**Steps:**

1. **Read Profile** → Load `{PROFILE_FILE}` in full (path configured in local setup)
2. **Identify Work Context** → Determine what is being reviewed (plan, script, code, folder, PRD, git strategy)
3. **Precedent Check** → Before analyzing, search for similar work:
   - Git log: `git log --oneline --grep="[keyword]" | head -20`
   - Related branches: `git branch -a | grep -E "feature/.*keyword|fix/.*keyword"`
   - Failed attempts: Check for reverted commits, abandoned branches
   - Extract lessons: "Why was previous similar work abandoned?"
   - Document assumption: "This avoids the trap from attempt X"
4. **Extract Standards** → Pull relevant sections from profile:
   - Global principles (quality, velocity, resources)
   - Model selection matrix (which AI does what)
   - Tech stack defaults
   - Execution rules (parallel, sequence, branching)
   - Hard rules (non-negotiable)
   - Testing standards
   - Git workflows

**Success Criterion:** ✅ Profile fully loaded, standards extracted, precedents checked

---

### D. Document Assumptions (Gate 1.4)

**List 3-5 core assumptions about this work. If any prove wrong, findings may be invalid.**

```markdown
### Assumptions
- Assumption 1: [Statement] → If wrong: [Impact on analysis]
- Assumption 2: [Statement] → If wrong: [Impact on analysis]
- Assumption 3: [Statement] → If wrong: [Impact on analysis]
```

**Examples:**
- "All scripts have bash shebangs" → If wrong: Parser may fail
- "Manifest is the source of truth" → If wrong: Generator produces stale data
- "Codex has >80% success rate on migrations" → If wrong: ROI calculation breaks

**Success Criterion:** ✅ 3-5 assumptions documented with impact statements

---

### SUCCESS CRITERIA FOR PLAY 1

- ✅ Profile fully loaded and understood
- ✅ Work type identified
- ✅ Type-specific validation complete (including Codex refinement cycle tracking for plans)
- ✅ Relevant standards extracted (3-5 sections minimum)
- ✅ Precedent check completed
- ✅ Assumptions documented
- ✅ **For multi-cycle specs**: Codex feedback cycles documented and keeper decisions captured (or N/A if single-pass)
- ✅ Ready to proceed to PLAY 2

---

## PLAY 2: Find Architectural Gaps

**Focus:** BLOCKERS + HIGH-value gaps aligned with the profile's "art of the possible." Skip cosmetic polish issues.

### Systematic Gap Detection (Gate 2.1)

Use this matrix to find gaps systematically. For each row, check if your work addresses it. Focus especially on BLOCKER categories:

| Category | Profile Rule | Check Against Current Work | Gap Indicator | Root Cause (Context) |
|----------|--------------|---------------------------|---|---|
| **Delegation** | Pure code generation → Codex | Is work delegable to $0 Codex? | Manual task that should be batched | Missing section in plan, underspecified, or wrong assumption about Codex capability |
| **Validation** | Haiku for syntax/checks | Are there validation steps without Haiku? | Custom validation scripts instead of Haiku | Plan assumes manual testing is sufficient |
| **Parallelization** | >70% tasks parallel | Are sequential tasks marked independent? | Tasks listed sequentially that could run concurrently | Plan author didn't identify independence, or dependencies are real |
| **Branching** | Major changes use feature branches | Is work touching 10+ files without branching? | No branch strategy for risky changes | Scope underestimated, or git discipline not prioritized |
| **Iteration** | Clear pass thresholds (1/2/3) | Does plan specify expected cycles? | No escalation paths or retry limits | Plan assumes first attempt succeeds (unrealistic) |
| **Model Choice** | Right model for right task | Is task assigned to correct AI? | Using Sonnet for pure code generation (should be Codex) | Author doesn't know model capabilities, or spec too unclear for Codex |
| **Testing** | Self-test before UAT | Is testing strategy in plan? | No automated test phase before UAT request | Plan skips automation, expects human to test (anti-pattern) |
| **Hard Rules** | No fake data, no permission prompts, Docker Compose mandatory | Does work violate hard rules? | Placeholders, asking for approval, no Compose file | Unknown hard rules or plan follows different standards |

**Context Analysis:** For each gap, determine WHY it exists:

- **Missing section:** Plan doesn't mention this aspect at all
- **Underspecified:** Plan mentions but lacks detail needed for execution
- **Violates pattern:** Breaks established convention in codebase
- **Wrong assumption:** Plan assumes something untrue about tech/team
- **Resource constraint:** Would require time/budget not available
- **Technical debt:** Known issue not worth fixing yet

**Success Criterion:** ✅ Systematic review of all categories complete

---

### Behavioral Coordination Audit (Gate 2.1b - NEW)

**For complex multi-spec plans:** Check for cross-spec contracts and temporal dependencies that could cause oscillation.

**Question:** Does this work involve 3+ specs/modules/batches with interdependencies?

If YES:
- [ ] Are state/behavioral contracts documented between specs? (e.g., "Spec 1.1 emits exit 124 on timeout; Spec 2.3 must handle this")
- [ ] Are temporal dependencies explicit? (e.g., "Cache must be written AFTER validation, before consumption")
- [ ] Are UX expectations coordinated? (e.g., "Progress bar shows current index, not next; message only on success")
- [ ] Are fallback behaviors defined? (e.g., "If jq fails, use grep parsing")

If you found cross-spec gaps:
- Mark these as HIGH-severity (prevent model oscillation)
- Propose improvement: "Document behavioral coordination matrix with validation tests"
- ROI: Prevents Sonnet ↔ Codex loops (saves 3-5K tokens per iteration)

If NO cross-spec complexity, skip this check.

**Success Criterion:** ✅ Behavioral coordination gaps identified (if applicable)

---

### Severity Classification Guide (Gate 2.2)

For each gap found, classify severity:

| Severity | Criteria | Example | Action |
|----------|----------|---------|--------|
| 🔴 **BLOCKER** | Prevents execution, causes failure, security risk | No handoff contract between phases = Codex instances might conflict | **MUST FIX** before execution |
| 🟡 **EXPENSIVE** | Wastes significant tokens or time, high ROI to fix | No Haiku pre-validation = underspecified prompts waste 2K tokens per failure | Fix if budget allows (ROI > 1.5x) |
| 🟢 **POLISH** | Optimization, quality improvement, nice-to-have | No checkpoint hashing = imprecise rollbacks (but still possible) | Fix if time permits |

---

### Output Format for Each Gap (Gate 2.3)

```markdown
Gap N: [Category] - [Title]
Severity: [🔴 BLOCKER | 🟡 EXPENSIVE | 🟢 POLISH]

Your Profile Says: [Direct quote or paraphrase from profile]

Current Work Problem: [Specific issue in the plan/code/approach]

Context (WHY the gap exists): [Root cause analysis - missing section? underspecified? violates pattern?]

Evidence: [Concrete example: "Plan lists 5 sequential script migrations but scripts are independent"]

Impact: [What breaks/costs if this isn't fixed - tokens wasted, time lost, regressions]

Severity Rationale:
- 🔴 BLOCKER: Prevents execution, causes regressions, or makes plan unexecutable
- 🟡 EXPENSIVE: Wastes >2K tokens or significantly delays project
- 🟢 POLISH: Optimization opportunity, non-critical improvement
```

**Success Criterion:** ✅ Minimum 5 gaps identified with category, severity, evidence, and context

---

### SUCCESS CRITERIA FOR PLAY 2

- ✅ Minimum 5 gaps identified
- ✅ Each gap has category, profile reference, concrete evidence, and context explanation
- ✅ Each gap severity classified (BLOCKER/EXPENSIVE/POLISH)
- ✅ Behavioral coordination audit complete (if multi-spec work)
- ✅ Cross-spec contracts and temporal dependencies documented (if applicable)
- ✅ Gaps ranked by impact
- ✅ Ready to proceed to PLAY 3

---

## PLAY 3: Propose 1-2 High-Value Architectural Improvements

**Focus: "Art of the Possible"** — Propose improvements that unlock architectural value, not cosmetic polish. If >5 gaps identified, prioritize blockers + 1-2 highest-ROI items. Escalate if spec fundamentally misses the mark.

### Improvement Priority Matrix (Gate 3.1)

**TIER 1 - BLOCKERS (always include):**
- Missing critical sections (handoff contracts, iteration limits, error recovery)
- Architectural contradictions (e.g., claiming parallelization that doesn't exist)
- Tech stack inconsistencies (documented vs. actual)

**TIER 2 - HIGH-VALUE ARCHITECTURAL (include 1-2 per round):**
- Unlocks new capability or prevents major failure mode
- ROI > 2.0x (real token savings or architectural clarity)
- Aligns with profile's "art of the possible"
- Example: "Add model handoff contracts" (enables parallel execution)

**TIER 3 - POLISH (skip unless trivial):**
- Cosmetic improvements, formatting, documentation
- ROI < 1.5x (benefit marginal relative to cost)
- Skip entirely if blocking items exist

**Decision:** Propose only TIER 1 + up to 2 from TIER 2. Mention TIER 3 as optional future work, don't implement.

### Model Selection - Critical Decision (Gate 3.2)

**Reference Profile's Model Selection Matrix before assigning any task:**

**Key References** (from loaded profile configuration):
- Model Selection Matrix → Verify correct model assignment
- Haiku Use Cases → Validation, quick checks, syntax verification
- Codex Use Cases → Code generation, implementation, boilerplate
- Sonnet Role → Orchestration, prompt generation, complex reasoning

**Decision Logic for Each Task:**

1. Is this pure code generation from a clear spec? → **Codex** ($0)
2. Is this syntax/import/placeholder validation? → **Haiku** (quick, cheap)
3. Is this orchestration or prompt generation? → **Sonnet**
4. Is this architecture/reasoning/PRD work? → **Opus**

**Model Selection Validation Grid:**

| Task Type | Best Choice | ❌ Wrong Choices | Why |
|-----------|-------------|-----------------|-----|
| Code generation (scripts, boilerplate, 10+ files) | **Codex** | Sonnet, Haiku | Pure spec → fastest, cheapest ($0) |
| Syntax/import validation, placeholder detection | **Haiku** | Sonnet, Codex | Quick checks → <1K tokens |
| Prompt generation, multi-step orchestration | **Sonnet** | Codex, Haiku | Reasoning required → handles complexity |
| Architecture decisions, PRD feedback, design | **Opus** | Sonnet (if needed for feedback) | Strategic thinking → rare use case |
| Creating/updating test suites | **Codex** (if from spec) or **Sonnet** (if complex logic) | Haiku | Test generation is code gen |
| Parallelization analysis, cost estimation | **Sonnet** | Codex | Reasoning, calculations → Sonnet |

**Anti-Patterns to Catch:**

- ❌ Using Sonnet for pure code generation (should be Codex)
- ❌ Using Haiku for reasoning/analysis (too limited context)
- ❌ Using Opus for execution tasks (too expensive, wrong role)
- ❌ Assigning validation to Sonnet (waste of tokens, use Haiku)

**Success Criterion:** ✅ Each improvement has clear model assignment verified against matrix

---

### Validation Gate Executability Check (Gate 3.2b - NEW)

**Before proposing improvements, verify that validation gates can actually execute as written.**

**Question:** Does the plan include validation or testing gates?

If YES, for each validation gate ask:
- [ ] Is the gate a **single command** (not 5+ manual steps)?
- [ ] Can it run **without human interpretation** (exit code, not subjective)?
- [ ] Are success/fail criteria **unambiguous** (e.g., "4/5 tests pass" not "looks mostly right")?
- [ ] Can it be **delegated to Haiku** instead of manual grep validation?

**Pattern Recognition:**
- ❌ Gate is manual grep commands → 🟡 Flag as EXPENSIVE
- ❌ Gate requires human judgment → 🟡 Flag as EXPENSIVE (propose Haiku validation)
- ❌ Gate is 10+ manual steps → 🔴 Flag as BLOCKER (simplify or script it)
- ✅ Gate is single command with clear pass/fail → Keep as-is

**Improvement Pattern:**
If manual validation found, propose:
```
Improvement: Delegate [gate name] to Haiku validation
Cost: 50 tokens (Haiku check)
Benefit: Reduces manual effort, clarifies pass criteria
ROI: 1.0-2.0x (clarity + automation)
Model: Haiku (fast validation)
```

**Success Criterion:** ✅ All validation gates verified as executable (or improvement proposed to make executable)

---

### Improvement Structure (Gate 3.2c)

For each gap, propose an improvement with this structure:

```markdown
Improvement N: [Category] - [Title]

Addresses Gap: [Which gap from Play 2]

Severity Fix: [🔴 BLOCKER | 🟡 EXPENSIVE | 🟢 POLISH]

Profile Pattern to Follow: [Section from profile + quote]

Recommended Action:
1. [Specific step 1]
2. [Specific step 2]
3. [Specific step 3]

Concrete Example:
[Code snippet, prompt template, or concrete workflow]

Who Executes: [Opus/Sonnet/Codex/Haiku]
(Verified against Profile Model Selection Matrix from loaded configuration)

Expected Result: [What success looks like]

Token Impact: [Estimate cost/savings, reference Profile token constraints]

ROI Analysis:
- Implementation cost: [X tokens] (estimate from profile constraints)
- Benefit (prevention value): [Y tokens] (tokens saved by preventing failure)
- ROI ratio: Y/X
- Decision Logic:
  - ✅ **IMPLEMENT NOW** if ROI > 1.5x (high confidence payoff)
  - ⚠️ **OPTIONAL** if ROI 1.0-1.5x (marginal, context-dependent)
  - ❌ **SKIP** if ROI < 1.0x (cost exceeds benefit)

//TODO: Real-Time Token Cost Tracking
- Current: Estimates from profile defaults
- Future: Implement actual cost/savings tracking once ROI threshold is established
- When to revisit: After 3 more projects using this model

Dependencies:
- Must complete before: [Improvement X, Y]
- Blocked by: [Improvement A, B]
- Independent of: [Improvement C, D]

Estimated Impact: High/Medium/Low
```

**Success Criterion:** ✅ Each improvement includes concrete example, model assignment, ROI analysis, and dependencies

---

### Improvement Dependency Rules (Gate 3.3)

- Do not propose improvements that depend on incomplete blockers
- Order improvements to minimize wait time (unblock others early)
- Identify improvements with zero dependencies (do those first)

**Common Improvement Patterns:**

| Pattern | When to Use | Example |
|---------|------------|---------|
| **Codex Batch Delegation** | Repetitive code generation, 10+ similar files | Migration of 42 scripts → Codex prompt batch |
| **Haiku Validation Pass** | After generation, before UAT | Post-migration syntax check, placeholder detection |
| **Parallelization Strategy** | Independent tasks listed sequentially | Fan-out Phase 2 into 3 parallel batches |
| **Feature Branch Strategy** | Destructive or major changes (10+ files) | Create `feature/metadata-unification`, test, merge |
| **Iteration Thresholds** | No escalation paths defined | Add table with expected passes, escalation at N cycles |
| **Model Selection Adjustment** | Wrong AI assigned to task | Sonnet → Codex for pure code generation |
| **Test-First Strategy** | No automated testing in plan | Add Jest/Playwright tests before UAT |
| **Hard Rule Compliance** | Work violates profile rules | Remove fake data, add Docker Compose, avoid permission prompts |

---

### Offering to Execute (Gate 3.4)

After proposing improvements, provide this standard offer:

```markdown
Ready to implement? I can:

✅ Update [artifact] with improvements
✅ Generate Codex prompts for [task]
✅ Create feature branch and execute [work]
✅ Add tests before UAT for [feature]
✅ Refactor [code] following profile patterns

What's your priority order?
```

**Success Criterion:** ✅ Offer to execute made, priority order clear

---

### File Lifecycle Planning (Gate 3.5 - MAJOR REFACTORS ONLY)

**This gate applies ONLY if improvements will create 3+ new files or tools.**

#### A. Detect Major Refactor

**Does this work create multiple new files?**

| Indicator | Example | Classification |
|-----------|---------|-----------------|
| 1-2 files | Single migration script, one test file | Minor (skip this gate) |
| 3-5 files | Script migration + validation + hooks | Major (apply this gate) |
| 5+ files | System rewrite with tools, tests, configs | Major (apply this gate) |
| Creates folder structure | New lib/, tools/, generators/ | Major (apply this gate) |

**If any "Major" indicator applies → Continue to section B. Otherwise, skip to PLAY 4.**

---

#### B. Classify Each File

For every file your improvements will create, classify it:

```markdown
File Classification Matrix

| File | Type | Lifecycle | Location | Cleanup |
|------|------|-----------|----------|---------|
| [name] | one-time/permanent | used once or forever | proper/ location | when |
```

**Type Categories:**

| Type | Description | Example |
|------|-------------|---------|
| **One-Time (Temporary)** | Migration script, analysis tool, temporary config | Migration script, reconciliation report, temporary validation |
| **Permanent (System)** | Generator, validator, hook, library | manifest-generator.sh, pre-commit hook, lib/detect.sh |
| **Artifact (Historical)** | Build output, logs, checkpoint records | checkpoint.log, migration-report.txt, build-output.json |

**Decision Questions:**

1. **Will this file run again after initial use?** → Permanent or Artifact
2. **Is it referenced by other tools?** → Permanent
3. **Is it part of the CI/CD or deployment?** → Permanent
4. **Will developers need to run this manually?** → Permanent
5. **Is it just for the migration/refactor phase?** → One-Time

---

#### C. Assign Proper Locations

**Permanent files MUST be moved to proper locations:**

| File Category | Location | Reasoning |
|---------------|----------|-----------|
| Generator scripts | `lib/` or `scripts/` | Reusable, referenced by other scripts |
| Validation scripts | `lib/validate-*.sh` or `tests/` | Used in CI/CD, pre-commit hooks |
| Pre-commit hooks | `.git/hooks/` (or `hooks/` + symlink) | Git requires this location |
| Utility libraries | `lib/` | Sourced by other scripts |
| Temporary tools | `_build/` → archive after use | Migration-specific, one-time use |
| Build artifacts | `_build/` → cleanup after build | Ephemeral, regenerated each build |
| Historical records | `_build/archive/` + git | Preserved for audit, off the main path |

**Profile Reference:** Location guidance from Profile File (configured in local setup)

---

#### D. Create Cleanup Plan

For ONE-TIME and ARTIFACT files, define cleanup:

```markdown
Post-Refactor Cleanup Checklist

One-Time Files:
- [ ] migration-script.sh → mv to _build/archive/ + document in CHANGELOG
- [ ] temp-config.json → delete or archive if audit trail needed
- [ ] reconciliation-report.sh → archive with date: _build/archive/2025-12-08-reconciliation-report.sh

Artifacts:
- [ ] checkpoints.log → _build/archive/checkpoints-2025-12-08.log
- [ ] validation-output.txt → Reference in PR, archive, delete from main
- [ ] .bak files → Delete (git history is the backup)

Permanent Files Verification:
- [ ] lib/generate-manifest.sh - linked in CI/CD? ✅ / ❌
- [ ] lib/validate-metadata.sh - called by pre-commit? ✅ / ❌
- [ ] hooks/pre-commit-validate - installed in .git? ✅ / ❌

Timing:
- Delete one-time files → After successful UAT
- Archive historical files → Document in refactor summary
- Verify permanent files → Before merge to main
```

---

#### E. Update Implementation Checklist

Add to your improvements' implementation checklist:

```markdown
### File Placement Verification
- [ ] All permanent files moved to proper locations
- [ ] One-time scripts archived in _build/archive/
- [ ] Backup/checkpoint files dated and archived
- [ ] No temporary files left in root or main directories
- [ ] Symlinks created for Git hooks (if needed)
- [ ] .gitignore updated if new build artifacts created
- [ ] Cleanup procedure documented in commit message
```

---

### SUCCESS CRITERIA FOR PLAY 3

- ✅ Minimum 5 improvements proposed
- ✅ Each improvement is actionable (not vague)
- ✅ Each includes concrete example or code
- ✅ Model assignment clear and verified
- ✅ Validation gates verified as executable (not manual grep chains)
- ✅ ROI analysis includes decision logic
- ✅ Dependencies mapped correctly
- ✅ Offer to execute provided
- ✅ **If major refactor: File lifecycle plan complete** (or N/A if minor)
- ✅ Ready to proceed to PLAY 4

---

## PLAY 4: Output Structured Report

### Choose Output Format (Gate 4.1)

**Select the format that fits your needs:**

| Format | Contents | When to Use |
|--------|----------|-------------|
| **Full Report** (Default) | Summary + gaps + improvements + next steps + compliance | Comprehensive review, complex projects, shared documentation |
| **Executive Summary** (Quick) | Summary + next steps + compliance only | Quick decision, already familiar with work |
| **Gap Deep-Dive** | Gaps only, with context and severity | Understanding what's wrong, no solutions needed yet |
| **Improvement Roadmap** | Improvements + next steps + ordered by ROI | Planning implementation, figuring out what to do |
| **Compliance Checklist** | Compliance checklist + action items per rule | Compliance audit, standards verification |
| **Evidence Bundle** | All gaps with evidence, severity, assumptions | Detailed review, regulatory audit |
| **Multi-Round Summary** ⭐ | Round 1/2/3 progression + gap trends + compliance evolution | Tracking improvements across audits, showing progress, compliance trends |

**Recommendation:** Default Full Report unless you have a specific reason for another format. Use Multi-Round Summary if you're running `/bryan` multiple times on the same work.

---

### Validation Cost Analysis (Gate 4.1a - NEW)

**Before generating report, calculate whether proposed validation approach is cost-effective.**

**Detected Validation Method**: [Manual / Haiku-delegated / Automated / Hybrid]

**Cost Analysis Checklist:**
- [ ] Manual validation identified? (grep commands, manual steps) → Mark as 🟡 EXPENSIVE
- [ ] How many manual steps? (1-3: acceptable / 4-6: reconsider / 7+: propose automation)
- [ ] Estimated token cost to fix with Haiku? (typically 50-200 tokens)
- [ ] Estimated token cost of NOT fixing? (prevents failed cycles: 2-5K per iteration)
- [ ] Decision: Is ROI > 1.5x to delegate to Haiku?

**Example Calculation:**
```
Scenario: Plan has 5 validation gates (grep-based, 3 steps each)
- Status quo: 15 manual checks per validation cycle
- Cost of failed cycle (rework + re-validation): 2-3K tokens
- Fix cost (Haiku validation + gate scripting): 200 tokens
- Iterations before ROI positive: 1 failed cycle = 2K + 200 = 2.2K tokens invested
- Expected benefit: Prevents 2-3 similar failed cycles = 4-6K tokens saved
- ROI: 5-6K / 200 = 25-30x ✅ IMPLEMENT NOW
```

**Decision Gate:**
- If validation is >50% manual → Include in EXPENSIVE improvements (ROI analysis required)
- If validation can be automated with <300 tokens → Propose as HIGH-value improvement
- If validation already lean → No improvement needed, proceed to report

**Success Criterion:** ✅ Validation cost analysis completed and included in improvements (if applicable)

---

### Multi-Round Consolidation (Gate 4.1b - Optional)

**If you're running `/bryan` multiple times on the same work:**

All rounds append to a single file in `{BUILD_DIR}/` with pattern: `[work-name]-ANALYSIS.md`

**File structure:**

```
_build/docker_config-ANALYSIS.md
├── # Round 1: [Focus Area] (2025-12-08 10:15)
│   ├── Gaps Identified
│   ├── Improvements Proposed
│   └── Status: [Compliance rating]
├── # Round 2: [Focus Area] (2025-12-08 11:30)
│   ├── Gaps Identified
│   ├── Improvements Proposed
│   └── Status: [Compliance rating]
└── # Round 3: [Focus Area] (2025-12-08 13:45)
    ├── Gaps Identified
    ├── Improvements Proposed
    └── Status: [Compliance rating]
```

**To consolidate existing audits:**

1. Verify single report file exists in `_build/`
2. Choose "Multi-Round Summary" format (above)
3. Playbook will:
   - Parse all rounds from single append file
   - Calculate progression (fixed, new, still pending)
   - Build consolidation tables
   - Show compliance rating trend
   - Highlight what changed between rounds

**Result:** Consolidated report with round-by-round history, all in one file.

---

### Report Structure Template (Gate 4.2)

**For Full Report (most common):**

```markdown
# Standards Alignment Analysis

## Summary
- Profile Version: [Link to profile]
- Work Analyzed: [Type: plan/code/script/PRD]
- Gaps Found: [N]
- Improvements Proposed: [N]
- Compliance Rating: [X/10]

## Part A: Gaps Identified

[Each gap from Play 2 with category, evidence, and impact]

## Part B: Improvements Proposed

[Each improvement from Play 3 with action steps and examples]

## Part C: Recommended Next Steps

1. [Priority 1 improvement - implement first]
2. [Priority 2 improvement]
3. [Priority 3 improvement]

## Part D: Compliance Checklist

- [ ] All hard rules followed
- [ ] Model selection correct
- [ ] Parallelization >70% where possible
- [ ] Testing strategy in place
- [ ] Feature branch if needed
- [ ] Iteration thresholds defined
- [ ] No permission prompts required
```

**For Multi-Round Summary (if running multiple audits):**

```markdown
# Standards Alignment Analysis - Multi-Round Summary

## Executive Summary Table

| Metric | Round 1 | Round 2 | Round 3 | Final Status |
|--------|---------|---------|---------|--------------|
| **Gaps Identified** | [N] | [N] | [N] | All documented |
| **BLOCKER Severity** | [N] | [N fixed/N pending] | [N fixed/N pending] | X/Y fixed |
| **HIGH Severity** | [N] | [N fixed/N pending] | [N fixed/N pending] | X/Y fixed |
| **MEDIUM Severity** | [N] | [N fixed/N pending] | [N fixed/N pending] | X/Y fixed |
| **Solutions Provided** | [N] | [N ready/N pending] | [N ready/N pending] | X ready to use |
| **Sections Added** | [N] | [+N] | [+N] | X comprehensive |
| **Compliance Rating** | [X]/10 | [Y]/10 | [Z]/10 | [Z]/10 ✅ |

## Round-by-Round Progress

### Round 1: [Focus Area]
- **Total Gaps Found**: [count]
- **Solutions Provided**: [count]
- **Solutions Integrated**: [count]/[count] ✅
- **Spec Sections Added**: [count] sections, ~[N] lines
- **Completeness**: [X]%
- **Key Achievements**: [Achievement 1], [Achievement 2]

### Round 2: [Focus Area]
- **New Gaps Identified**: +[count] (total now [N])
- **Solutions Provided**: [count]
- **Solutions Integrated**: [count]/[total] ✅ (R1 + R2 combined)
- **Spec Sections Added**: [count] new sections, ~[N] lines
- **Completeness**: [X]%
- **Key Achievements**: [Achievement 1], [Achievement 2]
- **Analysis**: [Why more gaps appeared in deeper analysis]

### Round 3: [Focus Area]
- **New Gaps Identified**: +[count] (total now [N])
- **Solutions Provided**: [count]
- **Solutions Integrated**: [count]/[total] ✅ (R1 + R2 + R3 combined)
- **Spec Sections Added**: [count] new sections, ~[N] lines
- **Completeness**: [X]%
- **Gaps Fixed from Previous Rounds**: [X of Y] ✅
- **Key Achievements**: [Achievement 1], [Achievement 2]

### Round 4: [Focus Area] (Final)
- **New Gaps Identified**: +[count] (OR "0 new gaps - all previous resolved")
- **Solutions Provided**: [count]
- **Solutions Integrated**: [count]/[total] ✅ **ALL GAPS SOLVED**
- **Spec Sections Added**: [count] new sections, ~[N] lines
- **Completeness**: 100% ✅
- **Status**: 🟢 PRODUCTION READY
- **Key Achievements**: [All gaps resolved], [Full integration], [Ready for deployment]

## What Changed Across Rounds

| Category | R1 | R2 | R3 | Final |
|----------|-----|-----|-----|-------|
| Spec Completeness | 40% | 60% | 75% | 75% ✅ |
| Blocker Issues Fixed | 0/N | X/N | Y/N | Y/N ✅ |
| Integrated Solutions | N/N | 0/N | M/N | (Total) ✅ |
| Documentation Actionability | 70% | 80% | 95% | 95% ✅ |
| Real-world Readiness | Development | Staging | Production-adjacent | [Status] |

## Final Assessment

**Status:** 🟢 [ASSESSMENT] — [One-line summary]

**Key Achievements:**
- [Achievement 1]
- [Achievement 2]
- [Achievement 3]

**Remaining Work (if any):**
- [Item 1]
- [Item 2]

## Recommendation

[Final verdict with confidence level and next steps]
```

**Success Criterion:** ✅ Report generated in chosen format

---

### SUCCESS CRITERIA FOR PLAY 4

- ✅ Output format chosen (Full Report, Executive Summary, Gap Deep-Dive, Improvement Roadmap, Compliance Checklist, Evidence Bundle, or Multi-Round Summary)
- ✅ Validation cost analysis completed (if applicable)
- ✅ Expensive validation methods identified and improvements proposed
- ✅ Report generated with all sections complete
- ✅ Structured, professional, actionable
- ✅ If Multi-Round Summary: Previous audit files detected and consolidated with progression tables
- ✅ Ready to proceed to PLAY 5

---

## PLAY 5: Ground Session in Standards

### Session Grounding Checklist (Gate 5.1)

**After analysis completes, provide this copy-paste checklist for remaining work:**

```markdown
## Standards Alignment Checklist for This Session

[Insert profile analysis date and what was reviewed]

### Key Rules Discovered
[List 3-5 top insights from the analysis - these are binding for rest of session]

1. [Gap insight 1] → If you encounter [scenario], apply [solution]
2. [Gap insight 2] → Before [decision], verify [constraint]
3. [Gap insight 3] → When [task], prioritize [standard]

### Before Every Major Decision
- [ ] Verify against Profile Model Selection Matrix (Codex→Sonnet→Haiku hierarchy)
- [ ] Check compliance checklist (Part D)
- [ ] Verify hard rules aren't violated
- [ ] Check if improvement ROI justifies cost

### Blockers Found in Analysis
[List BLOCKER-severity gaps that must be fixed before execution]

### High-Value Improvements to Implement
[List EXPENSIVE-severity improvements ordered by ROI]

### Token Budget
- Audit cost: [X tokens]
- Recommended budget for fixes: [Y tokens (high-ROI improvements)]
- Reserve for contingency: [Z tokens]
- Total: [X + Y + Z]

### When to Escalate
- If 3+ implementation attempts fail → Escalate to Opus for spec review
- If ambiguity discovered → Flag as assumption violation
- If hard rule breaks → Stop immediately, replan
```

**Success Criterion:** ✅ Grounding checklist provided

---

### Pre-Flight Validation Decision (Gate 5.1b - NEW)

**Determine if plan complexity requires pre-flight validation script.**

**Decision Tree:**
```
Does the plan have:
├─ 3+ batches/phases?
├─ 2+ validation gates?
├─ Environmental dependencies (jq, paths, git state)?

If ALL 3 YES:
  → Pre-flight validation is BLOCKING (not optional)
  → Recommendation: "Create _build/validate-[name].sh and run before execution"
  → ROI: Prevents 2-3 failed attempts (3-5K tokens saved)

If 2 YES (but not all 3):
  → Pre-flight validation is OPTIONAL
  → Recommendation: "Consider creating validation script if first attempt fails"
  → ROI: Medium (1.5-2.0x)

If 0-1 YES:
  → Skip pre-flight validation (too simple, unnecessary overhead)
```

**Pre-Flight Validation Script Scope** (if BLOCKING):

The script should check:
- ✅ Required tools installed (jq, bash, etc.)
- ✅ Required files exist (manifest, config, templates)
- ✅ Git state clean (no uncommitted changes)
- ✅ Feature branch ready (if major changes)
- ✅ Environment variables set
- ✅ Permission to write output directories

**Add to Grounding Checklist:**
If pre-flight validation is BLOCKING:
- [ ] Create `_build/validate-[name].sh` before execution
- [ ] Run: `bash _build/validate-[name].sh`
- [ ] Fix any failures before proceeding
- [ ] Saves ~3-5K tokens by catching issues early

**Success Criterion:** ✅ Pre-flight validation requirement determined and documented (or N/A if simple plan)

---

### Model Selection & Token Optimization (Gate 5.2)

Apply these rules to all subsequent execution:

**Model Selection** (from loaded profile configuration):
- ✅ Pure code generation → **Codex** ($0 cost, fastest, best output)
- ✅ Syntax/import/validation checks → **Haiku** (quick, cheap, <1K tokens)
- ✅ Orchestration & prompt generation → **Sonnet** (reasoning, multi-step)
- ✅ Architecture & strategic decisions → **Opus** (for gaps only)

**Token Impact Tracking:**
- Estimate cost/savings for each improvement (from loaded profile)
- Prioritize high-ROI improvements (ROI > 1.5x)
- Skip or delegate negative-ROI work (improvement cost > benefit)
- Batch similar tasks to Codex (one prompt → multiple files)

//TODO: Real-Time Token Cost Tracking
- Current: Estimates from profile defaults
- Future: Implement actual cost/savings tracking once ROI threshold is established
- Rationale: Token accounting adds 200-300 tokens per improvement; only worthwhile if repeated across 5+ projects
- When to revisit: After 3 more projects using this model, quantify ROI on tracking system itself

---

### Post-Report Actions (Gate 5.3)

- [ ] Apply discovered standards to all subsequent work
- [ ] Reference improvements when making decisions
- [ ] Use gap insights to avoid similar issues
- [ ] Check new work against compliance checklist
- [ ] Escalate decisions not covered by profile
- [ ] Validate assumptions as work proceeds

---

### Checklist for Remaining Session

After analysis, apply these standards throughout:

- ✅ Delegate code generation to Codex (not Sonnet)
- ✅ Use Haiku for validation passes (per loaded profile use cases)
- ✅ Target >70% parallel execution
- ✅ Use feature branches for major changes
- ✅ Define iteration thresholds before starting
- ✅ Run tests before asking for UAT
- ✅ No permission prompts (full auto-approval)
- ✅ No fake data or placeholders
- ✅ Docker Compose for everything that persists
- ✅ Track token cost/savings for improvements
- ✅ Reference Model Selection Matrix when assigning work

---

### SUCCESS CRITERIA FOR PLAY 5

- ✅ Grounding checklist provided
- ✅ Pre-flight validation requirement determined (BLOCKING / OPTIONAL / NOT NEEDED)
- ✅ Model selection rules clarified
- ✅ Token tracking approach defined
- ✅ Post-report actions clear
- ✅ Session checklist complete
- ✅ All subsequent work aligned with profile

---

## USAGE EXAMPLES

### Example 1: Review a Plan (with Model Selection & ROI Analysis)

```
/bryan

Context: I'm reviewing _build/metadata-fix.md for the metadata unification project.
```

**Claude will:**
1. Load profile
2. Analyze plan against profile standards
3. Identify 5+ gaps (missing Codex delegation, no parallel strategy, etc.)
4. Propose 5+ improvements with:
   - Model assignment (Codex for code gen, Haiku for validation, Sonnet for orchestration)
   - Token cost/savings estimates
   - ROI calculation (only high-ROI improvements prioritized)
5. Offer to update plan with improvements
6. Ground remaining work in profile standards

**Example output for metadata-fix.md:**

```
Improvement 1: Token Cost Tracking
Who Executes: Codex (generate templates) + Haiku (validate estimates)
Implementation Cost: 200 tokens
Prevention Value: 650 tokens (saves failed attempts + rework)
ROI Ratio: 650/200 = 3.25x
Status: ✅ IMPLEMENT NOW (ROI > 1.5x threshold)

Improvement 2: Codex Delegation Patterns
Who Executes: Codex (extract from profile + generate examples)
Implementation Cost: 100 tokens
Prevention Value: 1,400 tokens (automation + learning efficiency)
ROI Ratio: 1,400/100 = 14x
Status: ✅ IMPLEMENT NOW (ROI > 1.5x threshold)

Improvement 9: Post-Execution Feedback Loop
Who Executes: Would be Sonnet (documentation overhead)
Implementation Cost: 600 tokens per execution
Prevention Value: 450 tokens (learning value)
ROI Ratio: 450/600 = 0.75x
Status: ❌ SKIP (ROI < 1.0x - cost exceeds benefit)

Note on Real-Time Tracking: ROI estimates above use Profile defaults (from loaded configuration).
For future projects, consider tracking actual costs vs estimates to calibrate the model.
See "//TODO: Real-Time Token Cost Tracking" in PLAY 3 for details on when to revisit.
```

---

### Example 2: Review Code

```
/bryan

Context: Reviewing src/services/bootstrap-parser.ts for alignment with standards.
```

**Claude will:**
1. Load profile
2. Check code against tech stack defaults, patterns, hard rules
3. Find gaps (oversized file, missing tests, unused abstraction, etc.)
4. Propose improvements (split file, add Jest tests, remove premature abstraction)
5. Offer to remediate code
6. Apply standards to any remaining code review

---

### Example 3: Evaluate PRD

```
/bryan

Context: Review _build/docs_build/PRD/metadata-unification.md against Bryan's preferences.
```

**Claude will:**
1. Load profile
2. Extract PRD-specific standards (scope, architecture, model assignment)
3. Find gaps (underspecified, wrong model choice, missing hard rules)
4. Propose improvements (clearer specs, correct model matrix, hard rule compliance)
5. Offer to update PRD
6. Generate spec-ready prompts from improved PRD

---

### Example 4: Multi-Round Consolidation (After Multiple Audits)

**After running `/bryan` 3 times on the same work:**

Single accumulating audit file in `_build/`:
- `docker_config-ANALYSIS.md` (appends each round with timestamp)

```
/bryan

Context: Consolidate findings from 3 audit rounds on docker_config execution spec.
Use Multi-Round Summary format to show progression.
```

**Claude will:**
1. Read single ANALYSIS.md file
2. Parse all rounds (timestamps at each round separator)
3. Extract gaps, improvements, and compliance ratings from each round
4. Calculate progression (gaps fixed, new gaps, compliance trend)
5. Build Executive Summary Table (shows R1→R2→R3 progression)
6. Show Round-by-Round Progress (focus areas, achievements)
7. Create "What Changed" comparison table
8. Provide Final Assessment with Key Achievements
9. Append new round with timestamp to same file
10. Recommend next steps for remaining gaps

**Result:** Single file showing full evolution from R1 (40% complete) → R2 (60%) → R3 (75% complete), with metrics proving improvement across audits.

---

## REFERENCE SECTION

All reference materials for executing `/bryan` audits.

---

### Model Selection Matrix Quick Lookup

| Task | Best Model | Cost | Why |
|------|------------|------|-----|
| Generate 10+ boilerplate scripts from spec | **Codex** | $0 | Pure code generation, clear input spec |
| Validate generated code for syntax errors | **Haiku** | <1K tokens | Quick pattern matching, cheap validation |
| Create prompts for Codex code generation | **Sonnet** | 1-3K tokens | Prompt engineering, complex specs |
| Review architecture, decide tech stack | **Opus** | 2-5K tokens | Strategic decision, rare use case |
| Write Jest tests from spec | **Codex** | $0 | Code generation, clear spec provided |
| Estimate token cost of implementation plan | **Sonnet** | 1-2K tokens | Reasoning and calculation required |

---

### Severity Threshold Decision Tree

```
┌─ Does this prevent execution?
│  └─ YES → 🔴 BLOCKER
│  └─ NO → Continue
│
├─ Would fixing this save >2K tokens or significant time?
│  └─ YES → 🟡 EXPENSIVE (calculate ROI)
│  └─ NO → Continue
│
└─ Is this an optimization or nice-to-have?
   └─ YES → 🟢 POLISH
   └─ NO → Reconsider classification
```

---

### ROI Calculation Quick Reference

```
ROI = Benefit / Cost

Decision Logic:
- ROI > 1.5x: ✅ IMPLEMENT NOW (high confidence payoff)
- ROI 1.0-1.5x: ⚠️ OPTIONAL (marginal, context-dependent)
- ROI < 1.0x: ❌ SKIP (cost exceeds benefit)

Example:
- Cost: 200 tokens (time to implement improvement)
- Benefit: 650 tokens (prevented rework, failed attempts)
- ROI: 650/200 = 3.25x → ✅ IMPLEMENT NOW
```

---

### Standard Directory Structure for File Placement

Use this structure when classifying file locations during major refactors:

```
__bootbuild/
├── lib/                          # Reusable libraries & utilities
│   ├── generate-manifest.sh      # Generator scripts (run repeatedly)
│   ├── validate-metadata.sh      # Validators (used in CI/CD)
│   ├── detect-functions.sh       # Generated utilities
│   └── paths.sh                  # Path constants (sourced by others)
│
├── scripts/                       # Executable scripts & tools
│   ├── bootstrap-manifest-gen.sh # Major generators
│   ├── reconcile-state.sh        # Analysis tools
│   └── setup-hooks.sh            # Installation scripts
│
├── hooks/                         # Symlinks to actual hooks
│   ├── pre-commit -> ../git-hooks/pre-commit-validate.sh
│   └── post-merge -> ../git-hooks/post-merge-checks.sh
│
├── .git/hooks/                    # Actual hook implementations
│   ├── pre-commit               # Real executable hooks
│   └── post-merge
│
├── _build/                        # Temporary build artifacts & workspace
│   ├── prompts/                  # Generated prompts (temporary)
│   ├── output/                   # Build output (temporary, gitignored)
│   └── archive/                  # Historical records & one-time scripts
│       ├── 2025-12-08-reconciliation-report.sh  # Dated archives
│       ├── checkpoints-2025-12-08.log
│       └── migration-notes.md
│
├── config/                        # Configuration files
│   ├── bootstrap-manifest.json   # Generated, never edit directly
│   └── bootstrap-manifest.json.original  # Backup from before refactor
│
└── templates/                     # Templates directory
    ├── scripts/                   # Bootstrap scripts (migrated, @script tags)
    └── root/                      # Template source files
```

**File Placement Decision Tree:**

```
Is this file generated/created during the refactor?
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

**Examples from metadata-fix implementation:**

| File | Classification | Proper Location | Why |
|------|----------------|-----------------|-----|
| `reconciliation-report.sh` | One-Time | `_build/archive/2025-12-08-reconciliation-report.sh` | Runs once to understand state, won't run again |
| `generate-manifest.sh` | Permanent | `lib/generate-manifest.sh` | Referenced by CI/CD, pre-commit, other scripts |
| `validate-metadata.sh` | Permanent | `lib/validate-metadata.sh` | Used by self-tests and pre-commit hook |
| `pre-commit-validate.sh` | Permanent | `.git/hooks/pre-commit` | Git requires this exact location |
| `checkpoints.log` | Artifact | `_build/archive/checkpoints-2025-12-08.log` | Historical record, dated and archived |
| `generate-detect-functions.sh` | Permanent | `lib/generate-detect-functions.sh` | Auto-run after manifest generation |

---

### Local Configuration Setup

**This playbook is project-agnostic.** Each project provides its own config file:

**.claude/config/bryan-local.md** contains:
- `{PROFILE_PATH}` → Directory containing profile file
- `{PROFILE_FILE}` → Full path to `bryan_developer_profile_v1.0.md`
- `{BUILD_DIR}` → Build/temp directory (e.g., `_build`)
- `{SCRIPTS_DIR}` → Bootstrap scripts directory (e.g., `__bootbuild/scripts`)
- `{LIB_DIR}` → Reusable libraries directory (e.g., `__bootbuild/lib`)
- `{CONFIG_DIR}` → Configuration directory (e.g., `__bootbuild/config`)
- `{TEMPLATES_DIR}` → Templates directory (e.g., `__bootbuild/templates`)
- **Hard Rules** → Project-specific non-negotiables
- **Tool Stack** → Project-specific tech choices
- **Directory Structure** → Custom tree for this project

**To use this playbook on another project:**
1. Copy `/bryan` as-is (no modifications needed)
2. Create a new `.claude/config/bryan-local.md` for that project
3. Update paths and hard rules to match that project
4. Run `/load-bryan-local` before using `/bryan`

---

### Multi-Round File Format

**When running `/bryan` multiple times on the same work, all rounds accumulate in a single file:**

```
{BUILD_DIR}/{work-name}-ANALYSIS.md
```

**Example:**
```
_build/docker_config-ANALYSIS.md
```

**File Format (Append Protocol):**

Each round appends to the same file with this structure:

```markdown
---

## Round N: [Focus Area] ([Timestamp])

### Executive Summary
- Compliance Rating: [X]/10
- Gaps Found: [count]
- BLOCKER: [count]
- HIGH: [count]
- MEDIUM: [count]

### Gaps Identified
[Gap details...]

### Improvements Proposed
[Improvement details...]

### Next Steps
[Recommendations...]
```

**Auto-Detection:**
- When you run `/bryan` after file exists, the playbook will detect and read it
- Select "Multi-Round Summary" format in PLAY 4 to generate consolidated report
- Consolidation extracts all rounds from single file and builds comparison tables
- Shows progression: which gaps were fixed, which are new, compliance trend

**Naming Rules:**
- Work name: Use consistent slug (same name for all rounds of same work)
- Use hyphens, not underscores, between words
- File ends with `-ANALYSIS.md` (single file, no ROUND suffix)
- Extensions must be `.md` for auto-detection
- Store in configured `{BUILD_DIR}` (typically `_build/`)

---

## END OF REFERENCE SECTION

---

## SUCCESS CRITERIA (Overall)

✅ Structural completeness checked (REQUIRED sections flagged)
✅ Profile completely loaded and integrated
✅ Gaps identified with severity classification (BLOCKER vs HIGH vs MEDIUM)
✅ 1-2 high-value architectural improvements proposed (not polish)
✅ Each improvement has assigned owner (Opus/Sonnet/Codex/Haiku)
✅ ROI analysis justifies "art of the possible" alignment
✅ Structured report generated with actionable next steps
✅ If spec has >2 missing sections: recommend redesign instead of iteration
✅ Claude offers to execute approved improvements
✅ Remaining session grounded in standards
✅ All future work aligned with profile
