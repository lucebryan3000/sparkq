# Bootstrap Testing Quick Reference

## Quick Commands

### Validate All Scripts
```bash
cd __bootbuild
./scripts/bootstrap-validate-scripts.sh
```

### Validate Single Script
```bash
./scripts/bootstrap-validate-scripts.sh scripts/bootstrap-helper.sh
```

### Run Integration Tests (Dry Run)
```bash
./tests/integration-test.sh --phase=1 --dry-run
```

### Run All Tests
```bash
# Unit tests
./tests/lib/test-runner.sh

# Integration tests
./tests/integration-test.sh --all --dry-run

# Script validation
./scripts/bootstrap-validate-scripts.sh
```

## Error Handling in Scripts

### Template
```bash
#!/bin/bash
set -euo pipefail

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source libraries
source "${BOOTSTRAP_DIR}/lib/paths.sh"
source "${BOOTSTRAP_DIR}/lib/error-handler.sh"

# Enable error handling
enable_error_handling

# Your code here
if ! some_command; then
    handle_error $ERR_DEPENDENCY_MISSING \
        "Tool not found" \
        "$(basename "$0")" \
        "Context info" \
        "Install with: apt install tool"
    exit $ERR_DEPENDENCY_MISSING
fi

# Show errors if any
error_summary
```

## Error Codes Reference

| Code | Name | Use Case |
|------|------|----------|
| 0 | SUCCESS | Operation completed successfully |
| 1 | GENERAL | Generic error |
| 2 | DEPENDENCY_MISSING | Required tool/file missing |
| 3 | PERMISSION_DENIED | Insufficient permissions |
| 4 | VALIDATION_FAILED | Input validation failed |
| 5 | ROLLBACK_NEEDED | Operation requires rollback |
| 6 | CONFIG_INVALID | Config file corrupt/invalid |
| 7 | FILE_NOT_FOUND | Required file not found |
| 8 | NETWORK_ERROR | Network operation failed |
| 9 | TIMEOUT | Operation timed out |

## Validation Checklist

Before committing a bootstrap script:

- [ ] Has proper shebang (`#!/bin/bash`)
- [ ] Sources `lib/paths.sh`
- [ ] Has help text (`--help` flag)
- [ ] Uses `set -euo pipefail`
- [ ] Has error handling (trap or handle_error)
- [ ] Has header comment explaining purpose
- [ ] Has main() function
- [ ] No TODO/FIXME markers
- [ ] No hardcoded paths
- [ ] Is executable (`chmod +x`)
- [ ] Listed in bootstrap-manifest.json
- [ ] Passes validation: `./scripts/bootstrap-validate-scripts.sh <script>`

## Test Output Locations

| Output | Location |
|--------|----------|
| Error log | `logs/errors.log` |
| Integration tests | `logs/integration-tests/` |
| TAP output | `logs/integration-tests/integration-tests.tap` |
| Test report | `logs/integration-tests/integration-test-report.md` |
| Validation JSON | `logs/script-validation.json` |

## Quality Scores

| Score | Rating | Action |
|-------|--------|--------|
| 90-100 | Excellent | Good to go |
| 75-89 | Good | Minor improvements recommended |
| 50-74 | Warnings | Address warnings before committing |
| 0-49 | Failed | Fix critical issues |

## CI/CD Integration

```bash
# In your CI pipeline:

# 1. Validate all scripts
./scripts/bootstrap-validate-scripts.sh --json || exit 1

# 2. Run integration tests (dry run)
./tests/integration-test.sh --all --dry-run || exit 1

# 3. Run unit tests
./tests/lib/test-runner.sh || exit 1
```

## Debugging Tips

### View Recent Errors
```bash
tail -50 logs/errors.log
```

### Test Specific Phase
```bash
./tests/integration-test.sh --phase=1 --verbose
```

### Check Script Quality
```bash
./scripts/bootstrap-validate-scripts.sh --verbose scripts/my-script.sh
```

### Generate Test Report
```bash
./tests/integration-test.sh --all --dry-run
cat logs/integration-tests/integration-test-report.md
```

## Documentation

Full documentation: [docs/testing-infrastructure.md](docs/testing-infrastructure.md)
