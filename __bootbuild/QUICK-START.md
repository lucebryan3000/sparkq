# Bootstrap System - Quick Start Guide

## New Scripts at a Glance

### Safety & Validation
| Script | Purpose | Command |
|--------|---------|---------|
| `bootstrap-validate.sh` | Pre-flight system check | `./scripts/bootstrap-validate.sh` |
| `bootstrap-healthcheck.sh` | Post-execution verification | `./scripts/bootstrap-healthcheck.sh` |
| `bootstrap-validate-scripts.sh` | Check script quality | `./scripts/bootstrap-validate-scripts.sh` |

### Backup & Recovery
| Script | Purpose | Command |
|--------|---------|---------|
| `bootstrap-rollback.sh` | Backup/restore system | `./scripts/bootstrap-rollback.sh --list` |
| `bootstrap-repair.sh` | Recover from failures | `./scripts/bootstrap-repair.sh --status` |

### Enhancement
| Script | Purpose | Command |
|--------|---------|---------|
| `bootstrap-dry-run-wrapper.sh` | Preview changes safely | `./bootstrap-dry-run-wrapper.sh ./scripts/...` |
| `bootstrap-kb-sync.sh` (enhanced) | KB documentation scanner | `./scripts/bootstrap-kb-sync.sh --dry-run` |

---

## Common Workflows

### Before Bootstrap
```bash
# 1. Validate everything is ready
./scripts/bootstrap-validate.sh

# 2. Preview what will happen
./scripts/bootstrap-menu.sh --dry-run

# 3. Create backup
./scripts/bootstrap-rollback.sh --create

# 4. Run bootstrap
./scripts/bootstrap-menu.sh --profile=standard -y
```

### After Bootstrap
```bash
# 1. Check system health
./scripts/bootstrap-healthcheck.sh

# 2. Compare with baseline
./scripts/bootstrap-healthcheck.sh --compare-baseline

# 3. Validate script quality
./scripts/bootstrap-validate-scripts.sh
```

### If Something Fails
```bash
# 1. Check what happened
./scripts/bootstrap-repair.sh --status

# 2. Deep validation
./scripts/bootstrap-repair.sh --check

# 3. Restore backup if needed
./scripts/bootstrap-rollback.sh --restore=latest

# 4. Continue from checkpoint
./scripts/bootstrap-repair.sh --continue
```

### Previewing Changes
```bash
# Option 1: Use --dry-run flag (on most scripts)
./scripts/bootstrap-kb-sync.sh --dry-run

# Option 2: Use --verify-changes (confirm before applying)
./scripts/bootstrap-kb-sync.sh --verify-changes

# Option 3: Use universal wrapper
./bootstrap-dry-run-wrapper.sh ./scripts/bootstrap-menu.sh --profile=standard
```

---

## Most Useful New Features

### 1. Dry-Run Everything (SAFE)
```bash
./scripts/bootstrap-detect.sh --dry-run
./scripts/bootstrap-manifest-gen.sh --dry-run --pretty
./scripts/bootstrap-kb-sync.sh --dry-run --verbose
```

### 2. Backup & Restore (RECOVERY)
```bash
./scripts/bootstrap-rollback.sh --list      # See all backups
./scripts/bootstrap-rollback.sh --restore=latest  # Revert changes
```

### 3. Health Checks (CONFIDENCE)
```bash
./scripts/bootstrap-healthcheck.sh          # Verify system state
./scripts/bootstrap-validate.sh             # Check prerequisites
```

### 4. Configuration Standards (CONSISTENCY)
In your scripts:
```bash
source "${LIB_DIR}/config-standard.sh"
node_version=$(config_get_node_version)
package_manager=$(config_get_package_manager)
```

---

## Script Help

All scripts include comprehensive help:
```bash
./scripts/bootstrap-validate.sh --help
./scripts/bootstrap-healthcheck.sh -h
./scripts/bootstrap-rollback.sh --help
# etc.
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Critical error |
| 2 | Warnings only (unless --strict) |
| 3 | Recovery/rollback needed |

---

## Troubleshooting

**Can't create files?**
```bash
./scripts/bootstrap-validate.sh --fix
```

**Need to undo changes?**
```bash
./scripts/bootstrap-rollback.sh --restore=latest
```

**Want to check script quality?**
```bash
./scripts/bootstrap-validate-scripts.sh --fix
```

**Don't know current state?**
```bash
./scripts/bootstrap-repair.sh --status
./scripts/bootstrap-healthcheck.sh
```

---

## Documentation

- **Detailed guide**: `IMPLEMENTATION-COMPLETE.md`
- **Testing guide**: `README-TESTING.md`
- **Dry-run & config**: `docs/DRY-RUN-AND-CONFIG-STANDARDS.md`
- **Script help**: Use `--help` on any script

---

## Key Takeaways

✅ **Validation**: Run `bootstrap-validate.sh` before bootstrap
✅ **Dry-run**: Use `--dry-run` to preview changes
✅ **Backup**: Use `bootstrap-rollback.sh --create` before major changes
✅ **Health**: Run `bootstrap-healthcheck.sh` after bootstrap
✅ **Recovery**: Use `bootstrap-repair.sh` if something goes wrong

---

**All scripts are production-ready and backward compatible.**
