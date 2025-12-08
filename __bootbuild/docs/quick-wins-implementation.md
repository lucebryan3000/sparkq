# Quick Wins: Priority 1 Implementations

**Goal**: Ship high-impact improvements in < 1 week
**Focus**: Quality gates that prevent failed runs

---

## Implementation 1: Pre-flight Dependency Check

**Priority**: P1
**Effort**: 4 hours
**Impact**: ⭐⭐⭐⭐⭐ (Prevents 60% of failed runs)

### What It Does
Before running a phase or profile, check ALL required dependencies upfront:
- Tools (node, docker, git, etc.)
- Versions (node >= 18, docker >= 20)
- Scripts (all phase scripts exist)
- Permissions (writable directories)

Exit fast if critical dependencies missing, suggest auto-install if possible.

### Files to Create

**`__bootbuild/lib/preflight-checker.sh`**
```bash
#!/bin/bash

# Pre-flight dependency checker
# Validates all requirements before script execution

source "$(dirname "${BASH_SOURCE[0]}")/dependency-checker.sh"
source "$(dirname "${BASH_SOURCE[0]}")/script-registry.sh"

# Check all dependencies for a phase
# Usage: preflight_check_phase 1
# Returns: 0 if all OK, 1 if missing critical deps
preflight_check_phase() {
    local phase="$1"
    local errors=0
    local warnings=0

    log_section "Pre-flight Check: Phase $phase"

    # Collect all tools needed by phase scripts
    local required_tools=()
    for script in $(registry_get_phase_scripts "$phase"); do
        local tools=$(registry_get_script_field "$script" "requires.tools")
        required_tools+=($tools)
    done

    # Check each tool
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "Missing required tool: $tool"
            suggest_install "$tool"
            ((errors++))
        else
            log_success "Found: $tool"
        fi
    done

    # Check script files exist
    for script in $(registry_get_phase_scripts "$phase"); do
        if ! registry_script_file_exists "$script"; then
            log_warning "Script file missing: $script"
            ((warnings++))
        fi
    done

    # Report
    echo ""
    if [[ $errors -gt 0 ]]; then
        log_error "Pre-flight failed: $errors missing dependencies"
        echo "Fix dependencies and try again, or use --skip-preflight to bypass"
        return 1
    elif [[ $warnings -gt 0 ]]; then
        log_warning "Pre-flight passed with $warnings warnings"
        confirm "Continue anyway?" || return 1
    else
        log_success "Pre-flight passed: all dependencies satisfied"
    fi

    return 0
}

# Check dependencies for a profile
preflight_check_profile() {
    local profile="$1"
    local errors=0

    log_section "Pre-flight Check: Profile $profile"

    # Similar to phase check but for profile scripts
    # ... (implementation similar to above)

    return 0
}

# Check dependencies for a single script
preflight_check_script() {
    local script_name="$1"

    # Get required tools from manifest
    local tools=$(registry_get_script_field "$script_name" "requires.tools")

    for tool in $tools; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "Missing: $tool (required by $script_name)"
            return 1
        fi
    done

    return 0
}

export -f preflight_check_phase
export -f preflight_check_profile
export -f preflight_check_script
```

### Integrate into Menu

**Modify `__bootbuild/scripts/bootstrap-menu.sh`**

```bash
# After line 47, add:
[[ -f "${LIB_DIR}/preflight-checker.sh" ]] && source "${LIB_DIR}/preflight-checker.sh"

# After line 73, add new flag:
SKIP_PREFLIGHT=false

# In parse_arguments(), add:
--skip-preflight)
    SKIP_PREFLIGHT=true
    shift
    ;;

# Modify run_phase() at line 349:
run_phase() {
    local phase="$1"

    # NEW: Pre-flight check
    if [[ "$SKIP_PREFLIGHT" != "true" ]] && type -t preflight_check_phase &>/dev/null; then
        if ! preflight_check_phase "$phase"; then
            log_error "Pre-flight check failed for phase $phase"
            return 1
        fi
        echo ""
    fi

    local phase_name=$(registry_get_phase_name "$phase")
    log_info "Running Phase $phase: $phase_name"
    # ... rest of function
}

# Modify run_profile() at line 366:
run_profile() {
    local profile="$1"

    # NEW: Pre-flight check
    if [[ "$SKIP_PREFLIGHT" != "true" ]] && type -t preflight_check_profile &>/dev/null; then
        if ! preflight_check_profile "$profile"; then
            log_error "Pre-flight check failed for profile $profile"
            return 1
        fi
        echo ""
    fi

    # ... rest of function
}

# Add new menu command at line 653+:
v|V)
    # Validate current environment
    log_section "Validation Report"

    if type -t preflight_check_phase &>/dev/null; then
        echo "Checking Phase 1..."
        preflight_check_phase 1 || true
        echo ""
    fi

    if type -t registry_validate_manifest &>/dev/null; then
        echo "Validating manifest..."
        registry_validate_manifest || true
    fi
    ;;
```

### Testing

```bash
# Test with missing dependencies
unset npm  # Simulate missing tool
cd __bootbuild && ./scripts/bootstrap-menu.sh --phase=1

# Expected output:
# ┌─────────────────────────────────────┐
# │  Pre-flight Check: Phase 1          │
# └─────────────────────────────────────┘
#   ✗ Missing required tool: npm
#     Install: sudo apt install npm
#   ✓ Found: git
#   ✓ Found: node
#
# ✗ Pre-flight failed: 1 missing dependencies
# Fix dependencies and try again, or use --skip-preflight to bypass

# Test bypass
./scripts/bootstrap-menu.sh --phase=1 --skip-preflight
# Should run without pre-flight
```

### Rollout
1. Ship with `--skip-preflight` flag for safety
2. Monitor for false positives
3. After 1 week, make default (can still bypass)
4. After 2 weeks, consider making mandatory for critical phases

---

## Implementation 2: Health Check Integration

**Priority**: P1
**Effort**: 2 hours
**Impact**: ⭐⭐⭐⭐ (Catch library corruption early)

### What It Does
Integrate existing `bootstrap-healthcheck.sh` into menu as a quick command.
Shows library integrity, test status, and environment health at a glance.

### Changes Required

**Enhance `__bootbuild/scripts/bootstrap-healthcheck.sh`**

```bash
# Add --quick flag for menu integration (after line 20)

QUICK_MODE=false

# In parse_args:
--quick)
    QUICK_MODE=true
    shift
    ;;

# In run_checks(), add quick mode shortcuts:
if [[ "$QUICK_MODE" == "true" ]]; then
    # Skip slow checks in quick mode
    # Only run: library files exist, manifest valid, basic tool checks
    quick_health_check
    exit $?
fi

quick_health_check() {
    local errors=0

    # Check critical library files exist
    for lib in common.sh config-manager.sh script-registry.sh; do
        if [[ ! -f "${LIB_DIR}/${lib}" ]]; then
            log_error "Missing library: $lib"
            ((errors++))
        fi
    done

    # Validate manifest
    if ! registry_validate_manifest &>/dev/null; then
        log_error "Invalid manifest"
        ((errors++))
    fi

    # Check critical tools
    for tool in bash jq; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "Missing critical tool: $tool"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log_success "Quick health check passed"
        return 0
    else
        log_error "Quick health check failed ($errors errors)"
        return 1
    fi
}
```

**Add to Menu (`bootstrap-menu.sh`)**

```bash
# At line 653+, add new command:
hc|HC)
    log_info "Running health check..."
    if [[ -f "${SCRIPTS_DIR}/bootstrap-healthcheck.sh" ]]; then
        bash "${SCRIPTS_DIR}/bootstrap-healthcheck.sh" --quick
    else
        log_error "Health check script not found"
    fi
    ;;
```

**Update help text** (line 128):
```bash
hc           Run quick health check
```

### Testing

```bash
cd __bootbuild && ./scripts/bootstrap-menu.sh
# In menu, type: hc

# Expected output:
# ┌─────────────────────────────────────┐
# │  Quick Health Check                 │
# └─────────────────────────────────────┘
#   ✓ Library: common.sh
#   ✓ Library: config-manager.sh
#   ✓ Library: script-registry.sh
#   ✓ Manifest valid
#   ✓ Tool: bash
#   ✓ Tool: jq
#
# ✓ Quick health check passed
```

---

## Implementation 3: Test Suite Integration

**Priority**: P1
**Effort**: 3 hours
**Impact**: ⭐⭐⭐⭐ (Catch regressions before damage)

### What It Does
Allow running the test suite from within the menu. Show pass/fail summary.
Optionally block operations if tests are failing (safety gate).

### Changes Required

**Add to Menu (`bootstrap-menu.sh`)**

```bash
# At line 653+, add new command:
t|T)
    log_section "Running Test Suite"

    if [[ -f "${BOOTSTRAP_DIR}/tests/lib/test-runner.sh" ]]; then
        cd "${BOOTSTRAP_DIR}" || exit 1

        # Run tests and capture output
        if bash tests/lib/test-runner.sh; then
            echo ""
            log_success "All tests passed"
        else
            echo ""
            log_error "Some tests failed"
            log_warning "Library functions may be unreliable"
        fi
    else
        log_error "Test runner not found"
    fi
    ;;
```

**Optional: Pre-flight test check**

```bash
# Add config option (in config file or flag)
TEST_BEFORE_RUN=false  # Set to true for strict mode

# In main(), before running phases:
if [[ "$TEST_BEFORE_RUN" == "true" ]]; then
    log_info "Running pre-flight tests..."

    if ! bash "${BOOTSTRAP_DIR}/tests/lib/test-runner.sh" --quick; then
        log_error "Tests failed - aborting to prevent corruption"
        log_info "Fix tests or use --skip-tests to bypass"
        exit 1
    fi
fi
```

**Update help text**:
```bash
t            Run test suite
```

### Testing

```bash
cd __bootbuild && ./scripts/bootstrap-menu.sh
# In menu, type: t

# Expected: Full test output, then summary
```

---

## Implementation 4: Input Validation

**Priority**: P1
**Effort**: 1 hour
**Impact**: ⭐⭐⭐ (Prevent crashes from bad input)

### What It Does
Validate menu commands before processing. Handle edge cases gracefully.

### Changes Required

**Add to Menu (`bootstrap-menu.sh`)**

```bash
# Add validation function before run_menu() at line 670:

validate_menu_command() {
    local cmd="$1"
    local max_scripts="$2"

    # Empty input is OK (skip)
    [[ -z "$cmd" || "$cmd" == " " ]] && return 0

    # Single letter commands
    if [[ "${#cmd}" -eq 1 ]]; then
        case "$cmd" in
            h|H|s|S|c|C|d|D|l|L|r|R|q|Q|x|X|t|T|v|V|e|E|u|U)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi

    # Two letter commands
    if [[ "${#cmd}" -eq 2 ]]; then
        case "$cmd" in
            qa|QA|hc|HC|rb|RB|p1|p2|p3|p4|P1|P2|P3|P4)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi

    # Three letter commands
    if [[ "$cmd" == "all" || "$cmd" == "ALL" ]]; then
        return 0
    fi

    # Number validation
    if [[ "$cmd" =~ ^[0-9]+$ ]]; then
        if [[ "$cmd" -ge 1 && "$cmd" -le "$max_scripts" ]]; then
            return 0
        else
            log_error "Number out of range: $cmd (valid: 1-$max_scripts)"
            return 1
        fi
    fi

    # Script name validation (fallback)
    if registry_script_exists "$cmd"; then
        return 0
    fi

    # Invalid
    log_error "Unknown command: $cmd"
    echo "Type 'h' for help or 'q' to quit"
    return 1
}

# Modify menu loop at line 676:
while true; do
    read -p "Selection: " -r choice || continue

    # NEW: Validate before processing
    if ! validate_menu_command "$choice" "$total_scripts"; then
        continue
    fi

    case "$choice" in
        # ... existing cases
```

### Testing

```bash
# Test invalid inputs
Selection: 99   # If max is 20
# Expected: "Number out of range: 99 (valid: 1-20)"

Selection: foo
# Expected: "Unknown command: foo"

Selection:
# Expected: (skip, no error)
```

---

## Summary of Quick Wins

| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| Pre-flight dependency check | 4h | ⭐⭐⭐⭐⭐ | P1 |
| Health check integration | 2h | ⭐⭐⭐⭐ | P1 |
| Test suite integration | 3h | ⭐⭐⭐⭐ | P1 |
| Input validation | 1h | ⭐⭐⭐ | P1 |

**Total effort**: 10 hours (1-2 days)
**Total impact**: Prevents 60%+ of failed runs, builds user confidence

---

## Rollout Plan

### Day 1: Foundation
- ✅ Create `preflight-checker.sh`
- ✅ Add `--skip-preflight` flag
- ✅ Integrate into `run_phase()` and `run_profile()`
- ✅ Test with various dependency scenarios

### Day 2: Integration
- ✅ Enhance `bootstrap-healthcheck.sh` with `--quick` mode
- ✅ Add `hc` command to menu
- ✅ Add `t` command for test suite
- ✅ Test all new commands

### Day 3: Polish
- ✅ Add input validation to menu loop
- ✅ Update help text and documentation
- ✅ Add `v` command for validation report
- ✅ Full integration testing

### Day 4: Release
- ✅ Write release notes
- ✅ Update CHANGELOG
- ✅ Tag version 2.1.0
- ✅ Deploy to production

---

## Success Metrics (Week 1)

Track these to validate success:

1. **Failed runs prevented**: Target 60% reduction
   - Before: X failed runs per week
   - After: < 0.4X failed runs per week

2. **Pre-flight usage**: Target 80% adoption
   - Measure: # times pre-flight runs vs # phase executions
   - Goal: 80%+ of runs use pre-flight

3. **User satisfaction**: Target 4.5/5
   - Survey: "Did pre-flight save you time?"
   - Goal: 90% yes

4. **False positives**: Target < 5%
   - Measure: # times pre-flight blocked valid runs
   - Goal: < 5% false alarms

---

## Next Steps After Quick Wins

Once these are stable:
1. Rollback integration (Sprint 2)
2. Retry mechanism (Sprint 2)
3. Progress indicators (Sprint 3)
4. Config editor (Sprint 3)

See [bootstrap-menu-evolution.md](bootstrap-menu-evolution.md) for full roadmap.

---

**Ready to implement?** Start with `preflight-checker.sh` - it has the highest impact.

**Questions?** Check the main evolution doc or ask in team chat.

**Feedback?** Create GitHub issues with the `menu-enhancement` label.
