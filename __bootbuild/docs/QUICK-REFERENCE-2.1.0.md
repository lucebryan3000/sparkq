# Quick Reference Guide: v2.1.0

**Version**: 2.1.0 (Quality Gates Release)
**Release Date**: 2025-12-07

---

## What's New in v2.1.0

### Pre-flight Dependency Checker

Automatically validates dependencies before running phases or profiles.

**How it works**:
- Runs automatically before `--phase` or `--profile` execution
- Checks for required tools (git, node, docker, etc.)
- Validates script files exist
- Provides installation suggestions

**Example**:
```bash
# Pre-flight runs automatically
./scripts/bootstrap-menu.sh --phase=1

# Output if dependency missing:
╔════════════════════════════════════════════╗
║  Pre-flight Check: Phase 1                 ║
╚════════════════════════════════════════════╝

Checking required tools...
  ✓ git found
  ✓ node found
  ✗ docker not found

Pre-flight failed: 1 missing dependencies
Suggested fix: sudo apt install docker.io
```

**Skip pre-flight** (if needed):
```bash
./scripts/bootstrap-menu.sh --phase=1 --skip-preflight
```

---

### Enhanced Input Validation

Better error messages with helpful suggestions.

**Before** (v2.0.0):
```
Selection: 999
Unknown command: 999
```

**After** (v2.1.0):
```
Selection: 999
ERROR: Number out of range: 999
Valid range: 1-24
Type 'h' for help, 'l' to list scripts, or 'q' to quit
```

---

### Comprehensive Test Suite

135 automated tests ensure system reliability.

**Run tests**:
```bash
cd __bootbuild
bash tests/lib/test-runner.sh
```

**Test coverage**:
- 29 tests for core utilities (common.sh)
- 45 tests for configuration (config-manager.sh)
- 61 tests for validation (validation functions)
- Additional tests for pre-flight checker

**Results**:
- Total: 135 tests
- Pass rate: 100%
- Execution time: ~3 seconds

---

## CLI Reference

### New Flags in v2.1.0

| Flag | Description | Example |
|------|-------------|---------|
| `--skip-preflight` | Bypass dependency checks | `./bootstrap-menu.sh --phase=1 --skip-preflight` |

### All Available Flags

| Flag | Description | Example |
|------|-------------|---------|
| `-i, --interactive` | Enable Q&A customization | `./bootstrap-menu.sh -i` |
| `-y, --yes` | Auto-approve all prompts | `./bootstrap-menu.sh -y --phase=1` |
| `--dry-run` | Show what would run | `./bootstrap-menu.sh --dry-run --profile=standard` |
| `--profile=NAME` | Run predefined profile | `./bootstrap-menu.sh --profile=minimal` |
| `--phase=N` | Run entire phase (1-4) | `./bootstrap-menu.sh --phase=2` |
| `--status` | Show environment status | `./bootstrap-menu.sh --status` |
| `--list` | List all scripts | `./bootstrap-menu.sh --list` |
| `--scan` | Force rescan | `./bootstrap-menu.sh --scan` |
| `--project=PATH` | Target project directory | `./bootstrap-menu.sh --project=/path/to/project` |
| `--skip-preflight` | Skip dependency checks | `./bootstrap-menu.sh --phase=1 --skip-preflight` |
| `-h, --help` | Show help | `./bootstrap-menu.sh --help` |
| `-v, --version` | Show version | `./bootstrap-menu.sh --version` |

---

## Menu Commands

All v2.0.0 commands remain unchanged:

| Command | Description |
|---------|-------------|
| `1-N` | Run specific script by number |
| `p1-p4` | Run entire phase |
| `all` | Run all scripts |
| `d` | Show 80% defaults |
| `qa` | Show 20% questions |
| `s` | Show status |
| `c` | Show config |
| `l` | List all scripts |
| `r` | Refresh scan |
| `h` | Help |
| `q/x` | Quit |

**Note**: Commands `v`, `hc`, `t`, `e`, `u`, `rb` are planned for future releases.

---

## Common Workflows

### First Time Setup
```bash
# 1. Run menu
cd __bootbuild
./scripts/bootstrap-menu.sh

# 2. View available scripts
Type: l

# 3. Run Phase 1 (AI toolkit)
Type: p1
# Pre-flight checks run automatically

# 4. Check status
Type: s
```

### Running Specific Phases
```bash
# Phase 1: AI Development Toolkit
./scripts/bootstrap-menu.sh --phase=1

# Phase 2: Infrastructure Setup
./scripts/bootstrap-menu.sh --phase=2

# Phase 3: Quality & Testing
./scripts/bootstrap-menu.sh --phase=3

# Phase 4: CI/CD Pipeline
./scripts/bootstrap-menu.sh --phase=4
```

### Using Profiles
```bash
# Minimal setup (fastest)
./scripts/bootstrap-menu.sh --profile=minimal

# Standard setup (recommended)
./scripts/bootstrap-menu.sh --profile=standard

# Full setup (everything)
./scripts/bootstrap-menu.sh --profile=full

# API-focused setup
./scripts/bootstrap-menu.sh --profile=api

# Frontend-focused setup
./scripts/bootstrap-menu.sh --profile=frontend

# Library-focused setup
./scripts/bootstrap-menu.sh --profile=library
```

### Testing & Validation
```bash
# Run test suite
cd __bootbuild
bash tests/lib/test-runner.sh

# Check system health
./scripts/bootstrap-healthcheck.sh

# Validate configuration
./scripts/bootstrap-validate.sh

# Dry-run before executing
./scripts/bootstrap-menu.sh --dry-run --phase=1
```

---

## Troubleshooting

### Pre-flight Check Fails

**Problem**: Pre-flight reports missing dependency
```
✗ docker not found
Pre-flight failed: 1 missing dependencies
```

**Solutions**:
1. Install the missing tool:
   ```bash
   sudo apt install docker.io
   ```

2. Skip pre-flight (not recommended):
   ```bash
   ./scripts/bootstrap-menu.sh --phase=1 --skip-preflight
   ```

### Input Validation Error

**Problem**: "Number out of range" error
```
ERROR: Number out of range: 99
Valid range: 1-24
```

**Solution**: Use a number within the valid range, or use `l` to list all scripts.

### Test Failures

**Problem**: Test suite reports failures
```
Failed: 3
```

**Solution**:
1. Check which tests failed in the output
2. Review error messages
3. Fix underlying issues
4. Re-run tests

---

## Configuration

### Pre-flight Configuration

Add to `__bootbuild/config/bootstrap.config`:

```bash
# Disable pre-flight checks globally (not recommended)
SKIP_PREFLIGHT=true
```

---

## Migration from v2.0.0

**No action required**. v2.1.0 is 100% backward compatible.

**What still works**:
- All CLI flags
- All menu commands
- All configuration files
- All bootstrap scripts
- All profiles and phases

**What changed**:
- Pre-flight checks now run automatically (can be skipped)
- Error messages are more descriptive
- Input validation is stricter

**Verify your upgrade**:
```bash
# 1. Check version
./scripts/bootstrap-menu.sh --version
# Should show: Bootstrap Menu v2.1.0

# 2. Run tests
bash tests/lib/test-runner.sh
# Should show: 135 passed, 0 failed

# 3. Test menu
./scripts/bootstrap-menu.sh
# Should work normally
```

---

## Getting Help

### Documentation
- **Changelog**: `__bootbuild/CHANGELOG.md`
- **Release Notes**: `__bootbuild/docs/RELEASE-2.1.0.md`
- **Quick Start**: `__bootbuild/QUICK-START.md`
- **Testing Guide**: `__bootbuild/README-TESTING.md`
- **Evolution Roadmap**: `__bootbuild/docs/bootstrap-menu-evolution.md`

### Support
- Create GitHub issue with `question` label
- Include version number (v2.1.0)
- Include relevant error messages

---

## What's Next

### v2.2.0 - Recovery (Planned)
- Rollback integration (`u`, `rb` commands)
- Retry mechanism with exponential backoff
- Rollback point tracking

### v2.3.0 - UX Enhancements (Planned)
- Progress bars for multi-script runs
- Interactive config editor (`e` command)
- Smart recommendations
- Health check integration (`hc` command)
- Test suite integration (`t` command)
- Validation report (`v` command)

---

**Last Updated**: 2025-12-07
**Version**: 2.1.0
**Status**: Production Ready
