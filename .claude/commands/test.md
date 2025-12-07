---
description: Run tests, create test files, or debug failing tests
allowed-tools:
  - Bash(npm run test:*)
  - Bash(npm test)
  - Read
  - Write
  - Edit
---

# Test Command

Run tests, create test files, or debug failing tests.

## Usage

```
/test
# Run full test suite

/test --watch
# Run tests in watch mode

/test api
# Run tests matching pattern

/test --debug
# Run with debug output
```

## Test Operations

- **Run**: Execute test suite with various patterns and filters
- **Create**: Generate test files for specified source files
- **Debug**: Add debugging and logging to failing tests
- **Coverage**: Check test coverage reports
- **Compare**: Compare test results before/after changes
