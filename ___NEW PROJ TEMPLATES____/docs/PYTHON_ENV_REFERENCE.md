# Python Environment Block Reference

> **Purpose**: Reference for blocking Python-related directories from Claude context  
> **Use**: Add to `additionalDirectories` in `.claude/settings.json`

---

## Why Block Python Environments?

Python virtual environments contain:
- Thousands of installed packages (massive token waste)
- Compiled bytecode (`.pyc` files)
- Platform-specific binaries
- Nothing Claude needs to read or modify

---

## Directories to Hard Block

### Virtual Environments

```json
"additionalDirectories": [
  // Standard venv names
  "./.venv",
  "./venv",
  "./.env",           // Sometimes used for venvs (careful - conflicts with dotenv)
  "./env",
  
  // Tool-specific
  "./.pythonenv",
  "./.pyenv",
  "./.conda",
  "./.virtualenv",
  
  // Poetry
  "./.poetry",
  
  // Pipenv
  "./.pipenv",
  
  // Hatch
  "./.hatch",
  
  // PDM
  "./.pdm",
  "./__pypackages__"
]
```

### Python Cache & Build Artifacts

```json
"additionalDirectories": [
  // Bytecode cache
  "./__pycache__",
  "./.pyc",
  
  // Type checker caches
  "./.mypy_cache",
  "./.pytype",
  "./.pyre",
  
  // Test caches
  "./.pytest_cache",
  "./.tox",
  "./.nox",
  
  // Linter caches
  "./.ruff_cache",
  "./.pylint.d",
  
  // Build artifacts
  "./build",
  "./dist",
  "./*.egg-info",
  "./.eggs"
]
```

### Package Installation

```json
"additionalDirectories": [
  // Installed packages (if in project)
  "./site-packages",
  "./lib/python*",
  
  // Wheel cache
  "./.wheel",
  "./wheelhouse"
]
```

---

## Complete Python Block List

Copy this entire block to your `additionalDirectories`:

```json
"additionalDirectories": [
  // === PYTHON ENVIRONMENTS ===
  "./.venv",
  "./venv",
  "./.pythonenv",
  "./.pyenv",
  "./.conda",
  "./.virtualenv",
  "./.poetry",
  "./.pipenv",
  "./.hatch",
  "./.pdm",
  "./__pypackages__",
  
  // === PYTHON CACHE ===
  "./__pycache__",
  "./.mypy_cache",
  "./.pytype",
  "./.pyre",
  "./.pytest_cache",
  "./.tox",
  "./.nox",
  "./.ruff_cache",
  "./.pylint.d",
  
  // === PYTHON BUILD ===
  "./dist",
  "./*.egg-info",
  "./.eggs",
  "./wheelhouse"
]
```

---

## Also Add to .claudeignore

For files that should be excluded from auto-context but Claude CAN still read if needed:

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.venv/
venv/
ENV/
env/
.pythonenv/

# Type checkers
.mypy_cache/
.pytype/
.pyre/

# Testing
.pytest_cache/
.tox/
.nox/
htmlcov/
.coverage
.coverage.*
coverage.xml
*.cover

# Linting
.ruff_cache/
.pylint.d/
```

---

## Quick Reference

| Directory | What it contains | Block? |
|-----------|------------------|--------|
| `.venv/`, `venv/` | Installed packages, binaries | ✅ Hard block |
| `__pycache__/` | Compiled bytecode | ✅ Hard block |
| `.mypy_cache/` | Type check results | ✅ Hard block |
| `.pytest_cache/` | Test session data | ✅ Hard block |
| `.ruff_cache/` | Linter results | ✅ Hard block |
| `dist/` | Built packages | ✅ Hard block |
| `requirements.txt` | Dependency list | ❌ Keep accessible |
| `pyproject.toml` | Project config | ❌ Keep accessible |
| `setup.py` | Install script | ❌ Keep accessible |

---

## Integration with settings.json

```json
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "additionalDirectories": [
      // Python (copy from above)
      "./.venv",
      "./venv",
      "./.pythonenv",
      "./__pycache__",
      "./.mypy_cache",
      "./.pytest_cache",
      "./.ruff_cache",
      
      // Node (standard)
      // ... other blocks
    ]
  }
}
```
