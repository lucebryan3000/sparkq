# Bootstrap Menu Evolution Plan

**Current Version**: 2.0.0
**Analysis Date**: 2025-12-07
**Status**: Production-ready core, opportunities for enhancement

---

## Executive Summary

The `bootstrap-menu.sh` is well-architected with excellent foundations:
- ✅ **Manifest-driven** architecture (dynamic, not hardcoded)
- ✅ **80/20 philosophy** (pre-configured defaults + minimal Q&A)
- ✅ **Background scanning** for performance
- ✅ **Multiple execution modes** (interactive, CLI, profiles, phases)
- ✅ **Session tracking** and summaries
- ✅ **Comprehensive help** and status displays

**Recommended Evolution Path**: Incremental enhancements while maintaining stability.

---

## Current Architecture Assessment

### Strengths

1. **Manifest-Driven Design** ⭐⭐⭐⭐⭐
   - Scripts, phases, profiles all defined in JSON
   - Easy to add new scripts without code changes
   - Registry abstraction ([script-registry.sh](../lib/script-registry.sh)) works well

2. **User Experience** ⭐⭐⭐⭐
   - Clean visual hierarchy with colors and icons
   - Multiple interaction modes (menu, CLI, auto)
   - 80% defaults shown, 20% questions preview
   - Session summaries with run/fail/skip counts

3. **Performance** ⭐⭐⭐⭐
   - Background scanning (3s timeout)
   - JSON caching for manifest reads
   - Non-blocking environment detection

4. **Flexibility** ⭐⭐⭐⭐⭐
   - Profiles (minimal, standard, full, api, frontend, library)
   - Phases (1-4 for staged rollout)
   - Dry-run mode
   - Auto-yes for CI/CD

5. **Error Handling** ⭐⭐⭐⭐
   - Validates manifest before running
   - Tracks failures separately from skips
   - Non-fatal mode (continues on errors)

### Gaps and Opportunities

#### Gap 1: Limited Error Recovery
**Current**: Scripts fail → logged → continue
**Missing**:
- No retry mechanism for transient failures
- No rollback on partial failures
- No dependency chain validation before execution

**Impact**: Medium
**Priority**: P2

#### Gap 2: No Pre-flight Dependency Checks
**Current**: Scripts check dependencies individually
**Missing**:
- No upfront "can I run this phase?" check
- No "what's missing?" report before starting
- No auto-install suggestions

**Impact**: High (wastes time on failed runs)
**Priority**: P1

#### Gap 3: Limited Progress Visibility
**Current**: Linear execution, logs to stdout
**Missing**:
- No progress bar for multi-script runs
- No ETA for phase completion
- No parallel execution visualization

**Impact**: Low (nice-to-have)
**Priority**: P3

#### Gap 4: No Undo/Rollback Integration
**Current**: Menu doesn't integrate with `bootstrap-rollback.sh`
**Missing**:
- No "undo last script" menu option
- No "show what was changed" command
- No restoration workflow

**Impact**: Medium
**Priority**: P2

#### Gap 5: Configuration Management
**Current**: Manual config editing or Q&A mode
**Missing**:
- No interactive config editor (`e` command)
- No config diffing ("what changed from defaults?")
- No config import/export between projects

**Impact**: Medium
**Priority**: P2

#### Gap 6: Script Testing Integration
**Current**: Tests exist but not integrated into menu
**Missing**:
- No "test bootstrap system" command
- No health check integration
- No validation before running scripts

**Impact**: Medium (quality gate missing)
**Priority**: P1

---

## Evolution Roadmap

### Phase 1: Stability & Quality Gates (Week 1)

**Goal**: Prevent failed runs, validate before execution

#### Task 1.1: Pre-flight Dependency Checks
```bash
# New function: pre_flight_check()
# - Check all required tools for selected phase/profile
# - Report missing dependencies upfront
# - Offer auto-install suggestions
# - Exit if critical dependencies missing

# Integration point:
# - Run before run_phase()
# - Run before run_profile()
# - New menu command: 'v' for validate
```

**Files to modify**:
- [bootstrap-menu.sh:349](bootstrap-menu.sh#L349) - Add to `run_phase()`
- [bootstrap-menu.sh:366](bootstrap-menu.sh#L366) - Add to `run_profile()`
- New lib function: `lib/dependency-checker.sh:validate_phase_dependencies()`

**Benefits**:
- ✅ Fail fast (don't start if doomed to fail)
- ✅ Clear error messages before work begins
- ✅ Auto-install suggestions reduce friction

---

#### Task 1.2: Health Check Integration
```bash
# Integrate bootstrap-healthcheck.sh into menu

# New menu command: 'hc' for health check
# Shows:
# - Library file integrity
# - Manifest validation
# - Test suite status (pass/fail count)
# - Environment compatibility

# Integration point:
# - Menu command 'hc' calls bootstrap-healthcheck.sh
# - Auto-run on startup if cache stale
# - Display warning banner if issues found
```

**Files to modify**:
- [bootstrap-menu.sh:653](bootstrap-menu.sh#L653) - Add 'hc' command
- [bootstrap-healthcheck.sh](bootstrap-healthcheck.sh) - Add `--quick` mode for menu

**Benefits**:
- ✅ Catch library corruption early
- ✅ Validate system integrity before critical operations
- ✅ Build user confidence

---

#### Task 1.3: Test Suite Integration
```bash
# Run library tests before allowing script execution

# New menu command: 't' for test
# - Runs __bootbuild/tests/lib/test-runner.sh
# - Shows pass/fail summary
# - Blocks critical operations if tests fail

# Integration point:
# - Optional pre-flight check (config flag)
# - Menu command for manual testing
```

**Files to modify**:
- [bootstrap-menu.sh:653](bootstrap-menu.sh#L653) - Add 't' command
- [bootstrap-menu.sh:803](bootstrap-menu.sh#L803) - Optional pre-flight in `main()`

**Benefits**:
- ✅ Confidence in library functions
- ✅ Catch regressions before they cause damage
- ✅ Developer workflow integration

---

### Phase 2: Recovery & Safety (Week 2)

**Goal**: Enable rollback, undo, safe experimentation

#### Task 2.1: Rollback Integration
```bash
# Integrate bootstrap-rollback.sh into menu

# New menu commands:
# - 'u' for undo (rollback last script)
# - 'rb' for rollback (show options)
# - Auto-rollback on failure (optional flag)

# Integration point:
# - Track rollback points in session
# - Link to bootstrap-rollback.sh
# - Show "what changed" before undo
```

**Files to modify**:
- [bootstrap-menu.sh:397](bootstrap-menu.sh#L397) - Track rollback points in `track_session_script()`
- [bootstrap-menu.sh:653](bootstrap-menu.sh#L653) - Add 'u' and 'rb' commands
- New lib function: `lib/rollback-utils.sh:create_rollback_point()`

**Benefits**:
- ✅ Safe experimentation (easy to undo)
- ✅ Recover from partial failures
- ✅ Confidence to try new scripts

---

#### Task 2.2: Retry Mechanism
```bash
# Add retry logic for transient failures

# Features:
# - Auto-retry network failures (npm install, git clone)
# - Exponential backoff (1s, 2s, 4s)
# - Max 3 retries default (configurable)
# - Smart retry (don't retry for permanent errors)

# Integration point:
# - Wrap run_script() with retry logic
# - Detect retryable vs permanent failures
# - Show retry attempts in logs
```

**Files to modify**:
- [bootstrap-menu.sh:301](bootstrap-menu.sh#L301) - Enhance `run_script()`
- New lib function: `lib/retry-utils.sh:retry_with_backoff()`

**Benefits**:
- ✅ Resilient to network hiccups
- ✅ Fewer manual re-runs
- ✅ Better CI/CD reliability

---

### Phase 3: User Experience Enhancements (Week 3)

**Goal**: Make menu more intuitive, informative, efficient

#### Task 3.1: Progress Indicators
```bash
# Add progress bars for multi-script operations

# Features:
# - ASCII progress bar for phases
# - ETA calculation based on avg script time
# - Parallel task visualization (future)
# - Real-time log streaming option

# Integration point:
# - run_phase() shows progress bar
# - run_profile() shows progress bar
# - Live updates (not just on completion)
```

**Files to modify**:
- [bootstrap-menu.sh:349](bootstrap-menu.sh#L349) - Add progress to `run_phase()`
- New lib function: `lib/ui-utils.sh:show_progress_bar()`

**Benefits**:
- ✅ Reduced perceived wait time
- ✅ Clear indication of progress
- ✅ Professional UX

---

#### Task 3.2: Interactive Config Editor
```bash
# Add in-menu configuration editing

# New menu command: 'e' for edit config
# Features:
# - Show current config in sections
# - Edit specific keys interactively
# - Validate changes before saving
# - Show diff vs defaults

# Integration point:
# - Menu command 'e' launches editor
# - Uses existing config-manager.sh functions
```

**Files to modify**:
- [bootstrap-menu.sh:653](bootstrap-menu.sh#L653) - Add 'e' command
- [lib/config-manager.sh](../lib/config-manager.sh) - Add `config_edit_interactive()`

**Benefits**:
- ✅ No need to leave menu
- ✅ Guided config changes
- ✅ Validation prevents errors

---

#### Task 3.3: Smart Recommendations
```bash
# Suggest next steps based on context

# Features:
# - "You ran docker, want to run postgres next?"
# - "You're in a TypeScript project, consider linting"
# - "Phase 1 complete, ready for Phase 2?"
# - Learn from common patterns

# Integration point:
# - After script completion
# - Show in menu as suggestions
# - Optional auto-queue for batch execution
```

**Files to modify**:
- [bootstrap-menu.sh:336](bootstrap-menu.sh#L336) - Add suggestions after `run_script()`
- New lib function: `lib/recommendation-engine.sh:suggest_next_scripts()`

**Benefits**:
- ✅ Guided workflow for beginners
- ✅ Discover related scripts
- ✅ Optimize common paths

---

### Phase 4: Advanced Features (Week 4+)

**Goal**: Power user features, automation, extensibility

#### Task 4.1: Parallel Execution
```bash
# Run independent scripts in parallel

# Features:
# - Detect independent scripts (no shared dependencies)
# - Run in parallel with job control
# - Aggregate logs cleanly
# - Show parallel progress bars

# Integration point:
# - Optional flag --parallel
# - Analyze dependency graph
# - Execute in parallel where safe
```

**Complexity**: High
**Priority**: P3
**Benefits**: 2-3x faster for large phases

---

#### Task 4.2: Script Composition (Workflows)
```bash
# Define custom workflows beyond phases/profiles

# Features:
# - YAML workflow definitions
# - Conditional execution (if has_docker then...)
# - Variable passing between scripts
# - Loops and error handling

# Example workflow:
# name: "Full Stack Setup"
# steps:
#   - git
#   - packages
#   - if: config.docker.enabled
#     then: [docker, postgres]
#   - typescript
#   - linting
```

**Complexity**: High
**Priority**: P3
**Benefits**: Ultimate flexibility

---

#### Task 4.3: Plugin System
```bash
# Allow external scripts to integrate with menu

# Features:
# - Plugin manifest (extends bootstrap-manifest.json)
# - Plugin discovery in ~/.bootbuild/plugins/
# - Sandboxed execution
# - Plugin marketplace (future)

# Integration point:
# - Load plugins on startup
# - Merge into script registry
# - Show plugin indicator in menu
```

**Complexity**: Very High
**Priority**: P4
**Benefits**: Ecosystem growth

---

## Incremental Implementation Plan

### Sprint 1 (Week 1): Quality Gates
```bash
Day 1-2: Pre-flight dependency checks
Day 3:   Health check integration
Day 4-5: Test suite integration
```

**Deliverables**:
- ✅ Menu command: `v` (validate)
- ✅ Menu command: `hc` (health check)
- ✅ Menu command: `t` (test)
- ✅ Auto pre-flight for phases/profiles

**Testing**: Run against all phases, verify early failures

---

### Sprint 2 (Week 2): Recovery
```bash
Day 1-2: Rollback integration
Day 3-4: Retry mechanism
Day 5:   Testing and docs
```

**Deliverables**:
- ✅ Menu command: `u` (undo)
- ✅ Menu command: `rb` (rollback)
- ✅ Auto-retry for network failures
- ✅ Rollback point tracking

**Testing**: Simulate failures, verify rollback works

---

### Sprint 3 (Week 3): UX Enhancements
```bash
Day 1-2: Progress indicators
Day 3-4: Config editor
Day 5:   Smart recommendations
```

**Deliverables**:
- ✅ Progress bars for phases
- ✅ Menu command: `e` (edit config)
- ✅ Post-run suggestions

**Testing**: User acceptance testing, UX feedback

---

### Sprint 4+ (Future): Advanced Features
```bash
Week 4+: Parallel execution (if needed)
Week 5+: Workflow composition (if requested)
Week 6+: Plugin system (exploration)
```

**Deliverables**: TBD based on user feedback

---

## Metrics for Success

### Performance Metrics
- **Pre-flight validation**: < 2s for full phase check
- **Menu responsiveness**: < 100ms for all commands
- **Background scan**: < 3s (current target maintained)
- **Retry overhead**: < 5s per retry attempt

### Quality Metrics
- **Pre-flight accuracy**: 95%+ correct dependency detection
- **Rollback success**: 99%+ successful undos
- **Test coverage**: 80%+ for new menu functions
- **User errors**: 50% reduction (via validation)

### User Experience Metrics
- **Commands to complete task**: 30% reduction (via suggestions)
- **Failed runs**: 60% reduction (via pre-flight)
- **Setup time**: 20% reduction (via retry/parallel)
- **User confidence**: Measured via survey (target: 4.5/5)

---

## Risk Assessment

### Low Risk
- ✅ Pre-flight checks (additive, no breaking changes)
- ✅ Health check integration (independent feature)
- ✅ Test integration (optional, safe)

### Medium Risk
- ⚠️ Rollback integration (depends on rollback.sh quality)
- ⚠️ Retry mechanism (could mask real errors)
- ⚠️ Config editor (could corrupt config if buggy)

### High Risk
- 🔴 Parallel execution (race conditions, hard to debug)
- 🔴 Workflow composition (DSL complexity, edge cases)
- 🔴 Plugin system (security, sandboxing, trust)

**Mitigation**:
- Extensive testing for medium-risk features
- Feature flags for high-risk features
- Gradual rollout (opt-in initially)

---

## Technical Debt to Address

### Current Issues
1. **No input validation** on menu commands (crash on invalid input)
2. **Hard-coded menu layout** (line 599-664) - should be data-driven
3. **No command history** (readline not configured)
4. **Global state** (SCRIPTS_RUN, etc.) - should be in session object
5. **No signal handling** (SIGINT during script execution)

### Refactoring Recommendations
1. Extract display logic → `lib/menu-ui.sh`
2. Extract session tracking → `lib/session-manager.sh`
3. Add command validation → `validate_menu_command()`
4. Add signal handlers → `trap_sigint_during_execution()`
5. Add readline support → `read -e -p` with history

---

## Backward Compatibility

All enhancements MUST maintain backward compatibility:

✅ **Existing CLI flags** work unchanged
✅ **Existing config format** supported
✅ **Existing manifest format** compatible
✅ **Existing scripts** run without modification

**Versioning**:
- Minor version bump for new features (2.0 → 2.1)
- Patch version for bug fixes (2.0.0 → 2.0.1)
- Major version ONLY if breaking changes (rare)

---

## Documentation Updates Required

1. **User Guide**: New menu commands, workflows
2. **Developer Guide**: Extension points, plugin API
3. **Migration Guide**: For any breaking changes
4. **Video Tutorial**: Walkthrough of new features
5. **Changelog**: Detailed release notes

---

## Next Actions

### Immediate (This Week)
1. ✅ Review this evolution plan
2. ⏳ Prioritize Sprint 1 tasks
3. ⏳ Create GitHub issues for each task
4. ⏳ Set up feature branch: `feature/menu-enhancements`

### Short-term (Next 2 Weeks)
1. ⏳ Implement Sprint 1 (Quality Gates)
2. ⏳ Write tests for new functions
3. ⏳ Update documentation
4. ⏳ User testing with real projects

### Long-term (Next Month+)
1. ⏳ Implement Sprint 2 (Recovery)
2. ⏳ Gather user feedback
3. ⏳ Iterate on UX improvements
4. ⏳ Evaluate advanced features based on need

---

## Conclusion

The `bootstrap-menu.sh` is **production-ready** with excellent foundations. The evolution path focuses on:

1. **Preventing failures** before they happen (pre-flight, validation)
2. **Recovering gracefully** when failures occur (rollback, retry)
3. **Improving UX** for faster, more intuitive workflows
4. **Enabling extensibility** for future growth

**Recommended approach**: Incremental, test-driven, user-feedback-guided evolution.

**Timeline**: 4 weeks for core improvements, ongoing for advanced features.

**Success criteria**: Fewer failed runs, faster setups, higher user confidence.

---

**Author**: Claude Sonnet 4.5
**Date**: 2025-12-07
**Next Review**: After Sprint 1 completion
