---
title: Bootstrap Configuration Reference
category: Reference
version: 1.0
created: 2025-12-07
updated: 2025-12-07
purpose: "Complete reference for configuration options, environment variables, and settings"
audience: Developers, System Administrators, Advanced Users
---

# Bootstrap Configuration Reference

Complete reference for configuration options, environment variables, and settings that control bootstrap behavior.

---

## Table of Contents

1. [Configuration File](#configuration-file)
2. [Configuration Sections](#configuration-sections)
3. [Environment Variables](#environment-variables)
4. [Configuration Precedence](#configuration-precedence)
5. [Common Patterns](#common-patterns)
6. [Validation](#validation)

---

## Configuration File

### Location

The bootstrap configuration file is located at:

```
__bootbuild/config/bootstrap.config
```

### Format

Configuration uses INI format with sections and key-value pairs:

```ini
[section.name]
key = value
another_key = value
```

### File Structure

```ini
# Comments start with #

[project]
# Project metadata

[profiles.dev]
# Development-specific settings

[profiles.staging]
# Staging-specific settings

[profiles.production]
# Production-specific settings

[auto_approve]
# Global auto-approval settings

[claude]
# Claude-specific configuration

[git]
# Git configuration

[packages]
# Package manager configuration

[environment]
# Environment file configuration

[docker]
# Docker configuration

[linting]
# Linting tools configuration

[testing]
# Testing framework configuration

[typescript]
# TypeScript configuration

[vscode]
# VS Code configuration

[detected]
# Auto-detected values (read-only)
```

---

## Configuration Sections

### [project]

Project metadata and identification.

```ini
[project]
name = "my-awesome-project"
description = "A brief description of the project"
owner = "Your Name"
owner_email = "your.email@example.com"
repository = "https://github.com/your-org/your-repo"
homepage = "https://your-project.com"
```

**Options:**
- `name` - Project name (used in documentation, logs)
- `description` - Short project description
- `owner` - Primary project owner/maintainer
- `owner_email` - Owner email for contact
- `repository` - Git repository URL
- `homepage` - Project website

---

### [profiles.*]

Profile-specific configuration for different environments. Create separate sections for different profiles:

```ini
[profiles.dev]
auto_approve = true
skip_validation = false
install_optional = true
docker_network = "dev-network"

[profiles.staging]
auto_approve = false
skip_validation = false
docker_network = "staging-network"

[profiles.production]
auto_approve = false
skip_validation = true
install_optional = false
docker_network = "prod-network"
```

**Usage:**
When running bootstrap with a specific profile, only that profile's settings apply:

```bash
BOOTSTRAP_PROFILE=production ./bootstrap-docker.sh
```

**Common Options:**
- `auto_approve` - Auto-approve confirmations (default: false)
- `skip_validation` - Skip validation steps (default: false)
- `install_optional` - Install optional dependencies (default: false)
- `docker_network` - Docker network name
- `log_level` - Logging verbosity (debug, info, warn, error)

---

### [auto_approve]

Global auto-approval settings for each script. When enabled, scripts won't prompt for confirmation.

```ini
[auto_approve]
git = false
packages = false
environment = false
linting = false
testing = false
typescript = false
docker = false
vscode = false
```

**Usage:**
Only effective when `BOOTSTRAP_YES=true` environment variable is set:

```bash
BOOTSTRAP_YES=true ./bootstrap-git.sh
# Will auto-approve without confirmation
```

---

### [claude]

Claude integration and AI assistant settings.

```ini
[claude]
enabled = true
version = "4.5"
model = "claude-haiku-4-5"
api_timeout = 30
```

**Options:**
- `enabled` - Enable Claude integration
- `version` - Claude version to use
- `model` - Specific model identifier
- `api_timeout` - Request timeout in seconds

---

### [git]

Git configuration defaults.

```ini
[git]
init_repo = true
create_gitignore = true
create_gitattributes = true
user_name = "Your Name"
user_email = "you@example.com"
default_branch = "main"
```

**Options:**
- `init_repo` - Initialize git repository if not exists
- `create_gitignore` - Create .gitignore file
- `create_gitattributes` - Create .gitattributes for line endings
- `user_name` - Git user name for commits
- `user_email` - Git user email for commits
- `default_branch` - Default branch name (main, master, etc.)

---

### [packages]

Package manager configuration.

```ini
[packages]
manager = "npm"
install = true
install_dev = true
registry = "https://registry.npmjs.org"
```

**Options:**
- `manager` - Package manager to use
  - `npm` - Node Package Manager
  - `yarn` - Yarn package manager
  - `pnpm` - pnpm (performance-focused)
  - `pip` - Python pip
- `install` - Actually install dependencies (vs. just create config)
- `install_dev` - Install development dependencies
- `registry` - Custom package registry URL

**Manager-Specific Options:**

For npm:
```ini
[packages.npm]
use_legacy_peer_deps = false
strict_peer_dependencies = true
```

For yarn:
```ini
[packages.yarn]
use_workspaces = false
classic = false  # Use Yarn v3+
```

For pnpm:
```ini
[packages.pnpm]
shamefully_flatten = false
strict_peer_dependencies = true
```

---

### [environment]

Environment file (.env) configuration.

```ini
[environment]
create_example = true
create_local = false
create_dev = true
create_test = true
create_prod = false
```

**Options:**
- `create_example` - Create .env.example template
- `create_local` - Create .env.local for local overrides
- `create_dev` - Create .env.development
- `create_test` - Create .env.test
- `create_prod` - Create .env.production

**Content Sections:**

Define which variables appear in each environment file:

```ini
[environment.variables]
API_URL = "http://localhost:3000"
DEBUG = "true"
LOG_LEVEL = "info"

[environment.secrets]
# Secrets are commented out in .env.example
API_KEY = ""
DATABASE_PASSWORD = ""
```

---

### [docker]

Docker configuration.

```ini
[docker]
enabled = true
create_dockerfile = true
create_compose = true
base_image = "node:20-alpine"
compose_version = "3.9"
network = "dev-network"
```

**Options:**
- `enabled` - Enable Docker configuration
- `create_dockerfile` - Create Dockerfile
- `create_compose` - Create docker-compose.yml
- `base_image` - Base image for Dockerfile
- `compose_version` - Docker Compose file format version
- `network` - Docker network name for containers

**Service Configuration:**

```ini
[docker.services]
app = true
database = true
cache = true
nginx = false
```

---

### [linting]

Linting and code formatting configuration.

```ini
[linting]
eslint = true
prettier = true
stylelint = true
eslint_config = "eslint-config-airbnb"
prettier_print_width = 80
auto_fix = true
```

**Options:**
- `eslint` - Enable ESLint
- `prettier` - Enable Prettier formatter
- `stylelint` - Enable StyleLint for CSS
- `eslint_config` - ESLint configuration preset
- `prettier_print_width` - Line width for formatting
- `auto_fix` - Auto-fix issues in npm scripts

---

### [testing]

Testing framework configuration.

```ini
[testing]
framework = "jest"
coverage = true
coverage_threshold = 80
watch_mode = true
```

**Options:**
- `framework` - Test framework (jest, vitest, pytest, mocha)
- `coverage` - Enable code coverage
- `coverage_threshold` - Minimum coverage percentage
- `watch_mode` - Enable watch mode by default

**Framework-Specific:**

For Jest:
```ini
[testing.jest]
collect_coverage_from = ["src/**/*.ts"]
coverage_threshold_global = 80
max_workers = 4
```

For Pytest:
```ini
[testing.pytest]
python_version = "3.11"
min_coverage = 80
parallel = true
```

---

### [typescript]

TypeScript compiler configuration.

```ini
[typescript]
enabled = true
version = "5.0"
target = "ES2020"
module = "ESNext"
strict = true
declaration = true
source_map = true
```

**Options:**
- `enabled` - Enable TypeScript configuration
- `version` - TypeScript version
- `target` - ECMAScript target version
- `module` - Module system (ESNext, commonjs, esnext)
- `strict` - Enable strict mode
- `declaration` - Generate .d.ts files
- `source_map` - Generate source maps

---

### [vscode]

VS Code configuration.

```ini
[vscode]
create_settings = true
create_extensions = true
create_launch = true
theme = "One Dark Pro"
font_size = 13
```

**Options:**
- `create_settings` - Create .vscode/settings.json
- `create_extensions` - Create .vscode/extensions.json
- `create_launch` - Create .vscode/launch.json
- `theme` - VS Code theme
- `font_size` - Editor font size

---

### [detected]

Auto-detected configuration (read-only, set by bootstrap scripts).

```ini
[detected]
language = "typescript"
package_manager = "npm"
test_framework = "jest"
os = "linux"
shell = "bash"
```

These values are automatically detected and set by bootstrap scripts. Do not edit manually.

---

## Environment Variables

Environment variables override configuration file values.

### Global Variables

**BOOTSTRAP_YES**
```bash
export BOOTSTRAP_YES=true
# Auto-approve all confirmations without prompting
# Only works if [auto_approve] settings allow it
```

**BOOTSTRAP_VERBOSE**
```bash
export BOOTSTRAP_VERBOSE=true
# Enable verbose output with detailed logging
```

**PROJECT_ROOT**
```bash
export PROJECT_ROOT=/path/to/project
# Explicitly set project root directory
# Overrides automatic detection
```

**BOOTSTRAP_CONFIG**
```bash
export BOOTSTRAP_CONFIG=/path/to/custom.config
# Use custom configuration file instead of default
```

**SKIP_VALIDATION**
```bash
export SKIP_VALIDATION=true
# Skip validation steps (use with caution)
# Default: false
```

---

### Script-Specific Variables

**Git Configuration**
```bash
export BOOTSTRAP_GIT_USER="Your Name"
export BOOTSTRAP_GIT_EMAIL="you@example.com"
export BOOTSTRAP_GIT_BRANCH="main"
```

**Package Manager**
```bash
export BOOTSTRAP_PACKAGE_MANAGER="npm"  # npm, yarn, pnpm, pip
export BOOTSTRAP_SKIP_INSTALL=true      # Don't run npm install
export BOOTSTRAP_REGISTRY="https://..."  # Custom npm registry
```

**Environment Files**
```bash
export BOOTSTRAP_ENV_PROFILE="development"  # dev, test, prod
export BOOTSTRAP_ENV_VARS="API_URL,DEBUG"   # Specific variables
```

**Docker**
```bash
export BOOTSTRAP_DOCKER_BASE="node:20-alpine"
export BOOTSTRAP_DOCKER_PORT=3000
export BOOTSTRAP_DOCKER_REGISTRY="docker.io"
```

**Linting**
```bash
export BOOTSTRAP_LINTING_PRESET="airbnb"  # eslint preset
export BOOTSTRAP_AUTO_FIX=true
```

**Testing**
```bash
export BOOTSTRAP_TEST_FRAMEWORK="jest"
export BOOTSTRAP_COVERAGE_THRESHOLD=80
export BOOTSTRAP_WATCH_MODE=true
```

---

## Configuration Precedence

Values are applied in this order (highest to lowest priority):

1. **Environment Variables** - Highest priority
2. **Profile-Specific Config** - `[profiles.profile_name]`
3. **Global Config** - Main sections like `[packages]`
4. **Defaults** - Built-in script defaults

### Example

Given this configuration:

```ini
[packages]
manager = "npm"

[profiles.dev]
manager = "pnpm"
```

And these scenarios:

**Scenario A: Default**
```bash
./bootstrap-packages.sh
# Uses: npm (from [packages])
```

**Scenario B: With profile**
```bash
BOOTSTRAP_PROFILE=dev ./bootstrap-packages.sh
# Uses: pnpm (from [profiles.dev])
```

**Scenario C: Environment override**
```bash
BOOTSTRAP_PACKAGE_MANAGER=yarn ./bootstrap-packages.sh
# Uses: yarn (environment variable wins)
```

---

## Common Patterns

### Development Setup

Enable auto-approval for quick development iteration:

```bash
# In your profile
[profiles.dev]
auto_approve = true

# Or via environment
export BOOTSTRAP_YES=true
export BOOTSTRAP_PROFILE=dev
```

### Production Lockdown

Require explicit approval for production changes:

```ini
[profiles.production]
auto_approve = false
skip_validation = true  # But do validation
```

### Custom Registry

Use private npm registry:

```bash
export BOOTSTRAP_REGISTRY="https://registry.company.com"
# Or in config
[packages.npm]
registry = "https://registry.company.com"
```

### Monorepo Setup

Configure for monorepo workspaces:

```ini
[packages.yarn]
use_workspaces = true

[packages.pnpm]
shamefully_flatten = false
```

### Selective Installation

Install only specific dependencies:

```bash
export BOOTSTRAP_SKIP_INSTALL=true
# Manually install later:
npm install --only=production
```

---

## Validation

### Check Current Configuration

View effective configuration:

```bash
# Show all config values
cat __bootbuild/config/bootstrap.config

# Show specific section
grep -A 10 "^\[packages\]" __bootbuild/config/bootstrap.config

# Show specific value
grep "manager =" __bootbuild/config/bootstrap.config
```

### Validate Configuration

Test configuration before running scripts:

```bash
# Run with SKIP_VALIDATION=false (default)
BOOTSTRAP_VERBOSE=true ./bootstrap-git.sh

# Check bootstrap log for validation results
tail __bootbuild/bootstrap.log | grep -E "(VALID|INVALID|ERROR)"
```

### Configuration Troubleshooting

**Variable not found error:**
```bash
# Check if variable is defined in config
grep "variable_name" __bootbuild/config/bootstrap.config

# Check if it's in the right section
grep -B 5 "variable_name" __bootbuild/config/bootstrap.config
```

**Variable not being used:**
```bash
# Verify environment variable is exported
env | grep BOOTSTRAP_

# Check that section is correct
# Variable must be in matching [section] header
```

**Wrong value being used:**
```bash
# Check precedence:
# 1. Environment variable (highest)
echo $BOOTSTRAP_PACKAGE_MANAGER

# 2. Profile section
BOOTSTRAP_PROFILE=dev ./bootstrap-packages.sh

# 3. Global section
grep -A 20 "^\[packages\]" __bootbuild/config/bootstrap.config
```

---

## Reference Links

- [run-bootstrap-scripts.md](../playbooks/run-bootstrap-scripts.md) - How to run scripts with config
- [LIBRARY.md](LIBRARY.md) - Functions that read config
- [SCRIPT_CATALOG.md](SCRIPT_CATALOG.md) - Script-specific configuration

---

## Examples

### Complete Configuration for JavaScript/Node Project

```ini
[project]
name = "my-js-app"
owner = "Your Name"

[profiles.dev]
auto_approve = true

[git]
user_name = "Your Name"
user_email = "you@example.com"

[packages]
manager = "npm"
install = true
install_dev = true

[environment]
create_example = true
create_local = false

[linting]
eslint = true
prettier = true
eslint_config = "eslint-config-airbnb"

[testing]
framework = "jest"
coverage = true
coverage_threshold = 80

[docker]
enabled = false

[vscode]
create_settings = true
theme = "One Dark Pro"
```

### Complete Configuration for Python Project

```ini
[project]
name = "my-python-app"
owner = "Your Name"

[packages]
manager = "pip"
install = true

[environment]
create_example = true
create_local = false

[testing]
framework = "pytest"
coverage = true

[docker]
enabled = true
base_image = "python:3.11-slim"
```

---

## Quick Reference

```bash
# Set auto-approval
export BOOTSTRAP_YES=true

# Set custom config file
export BOOTSTRAP_CONFIG=/path/to/config

# Set explicit project root
export PROJECT_ROOT=/path/to/project

# Enable verbose logging
export BOOTSTRAP_VERBOSE=true

# Use specific package manager
export BOOTSTRAP_PACKAGE_MANAGER=pnpm

# Run with custom registry
export BOOTSTRAP_REGISTRY="https://registry.company.com"

# Enable all and run
BOOTSTRAP_YES=true BOOTSTRAP_VERBOSE=true ./bootstrap-git.sh
```
