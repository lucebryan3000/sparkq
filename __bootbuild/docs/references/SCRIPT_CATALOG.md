---
title: Bootstrap Script Catalog
category: Reference
version: 1.0
created: 2025-12-07
updated: 2025-12-07
purpose: "Complete reference guide to all 14 bootstrap scripts organized by phase"
audience: Developers, System Administrators, Script Maintainers
---

# Bootstrap Script Catalog

Complete reference of all available bootstrap scripts, their purposes, dependencies, and outputs.

---

## Overview

Bootstrap scripts are organized by phase:
- **Phase 1**: Foundation (Git, packages, environment)
- **Phase 2**: Development (Linting, testing, TypeScript)
- **Phase 3**: Advanced (Docker, CI/CD, documentation)
- **Phase 4**: Optional/Planned (Advanced tooling)

---

## Phase 1: Foundation

### bootstrap-git.sh

**Purpose:** Initialize Git repository and create standard Git configuration files.

**Status:** ✅ Active & Standardized

**Dependencies:**
- Git must be installed
- Project directory must be writable
- No dependencies on other bootstrap scripts

**Runtime:** ~2 seconds

**Files Created:**
- `.gitignore` - Standard ignore patterns for dependencies, build artifacts, IDE files, logs, OS files, testing, databases, cache, temporary files
- `.gitattributes` - Line ending normalization for text files, binary file handling
- `.git/` - Git repository directory (if not already initialized)

**Configuration Section:**
```ini
[git]
init_repo = true
create_gitignore = true
create_gitattributes = true
```

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve without confirmation
- `PROJECT_ROOT` - Explicit project directory path

**Location:** `__bootbuild/scripts/bootstrap-git.sh`

**Example:**
```bash
./bootstrap-git.sh
# or
./bootstrap-git.sh /path/to/project
```

**Next Step:** Run `bootstrap-packages.sh` to install project dependencies.

---

### bootstrap-packages.sh

**Purpose:** Install project package management and dependencies based on detected environment.

**Status:** ✅ Active

**Dependencies:**
- Requires Node.js or Python environment (detected automatically)
- Package manager must be available (npm, yarn, pnpm, or pip)
- bootstrap-git.sh should run first (recommended)

**Runtime:** ~30-60 seconds (depending on dependencies)

**Files Created:**
- `package.json` (Node.js projects) - Project metadata and dependencies
- `package-lock.json` (Node.js with npm) - Dependency lock file
- `requirements.txt` (Python projects) - Python dependencies list
- `.npmrc` or similar config files for package manager

**Configuration Section:**
```ini
[packages]
manager = "npm"  # Options: npm, yarn, pnpm, pip
install = true
include_dev = true
```

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve
- `BOOTSTRAP_PACKAGE_MANAGER` - Override detected manager
- `BOOTSTRAP_SKIP_INSTALL` - Create config without installing

**Location:** `__bootbuild/scripts/bootstrap-packages.sh`

**Example:**
```bash
# Auto-detect manager
./bootstrap-packages.sh

# Specify manager
BOOTSTRAP_PACKAGE_MANAGER=pnpm ./bootstrap-packages.sh
```

**Next Step:** Run `bootstrap-environment.sh` for environment configuration.

---

### bootstrap-environment.sh

**Purpose:** Create environment configuration files and set up development environment variables.

**Status:** ✅ Active

**Dependencies:**
- Project directory must be writable
- No hard dependencies on other scripts, but typically runs after packages script

**Runtime:** ~1 second

**Files Created:**
- `.env.example` - Template environment variables (tracked in git)
- `.env.local` - Actual environment variables (git-ignored, user-specific)
- `.env.*.local` - Environment-specific overrides (development, testing, production)

**Configuration Section:**
```ini
[environment]
create_example = true
create_local = false  # Creates template, user adds values manually
development_env = true
testing_env = false
```

**Content of .env.example:**
```
# API Configuration
API_URL=http://localhost:3000
API_KEY=your-api-key-here

# Database
DATABASE_URL=postgresql://user:pass@localhost/dbname

# Development
DEBUG=true
LOG_LEVEL=info

# Other
NODE_ENV=development
```

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve
- `BOOTSTRAP_ENV_FILE` - Custom environment file location

**Location:** `__bootbuild/scripts/bootstrap-environment.sh`

**Example:**
```bash
./bootstrap-environment.sh
# Creates .env.example (committed)
# Creates .env.local (git-ignored, user configures)
```

**Next Step:** Manually configure `.env.local` with actual values, then proceed to Phase 2 scripts.

---

## Phase 2: Development

### bootstrap-linting.sh

**Purpose:** Set up code linting and formatting tools (ESLint, Prettier, StyleLint).

**Status:** ✅ Active

**Dependencies:**
- Node.js project (detects package.json)
- bootstrap-packages.sh should run first
- NPM/Yarn available

**Runtime:** ~5-10 seconds

**Files Created:**
- `.eslintrc.json` - ESLint configuration
- `.eslintignore` - ESLint ignore patterns
- `.prettierrc.json` - Prettier formatting configuration
- `.prettierignore` - Prettier ignore patterns
- `.stylelintrc` - StyleLint configuration for CSS/SCSS

**Configuration Section:**
```ini
[linting]
eslint = true
prettier = true
stylelint = true
auto_fix = true
```

**Scripts Added to package.json:**
```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  }
}
```

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve
- `BOOTSTRAP_LINTING_PRESET` - Preset configuration (standard, airbnb, etc.)

**Location:** `__bootbuild/scripts/bootstrap-linting.sh`

**Example:**
```bash
./bootstrap-linting.sh

# Then use
npm run lint
npm run lint:fix
npm run format
```

**Next Step:** Run `bootstrap-testing.sh` for test configuration.

---

### bootstrap-testing.sh

**Purpose:** Configure testing framework and test utilities.

**Status:** ✅ Active

**Dependencies:**
- Node.js or Python project
- bootstrap-packages.sh should run first
- Package manager available

**Runtime:** ~5-10 seconds

**Files Created (Node.js):**
- `jest.config.js` - Jest test configuration
- `.jestignore` - Files to ignore in test runs

**Files Created (Python):**
- `pytest.ini` - Pytest configuration
- `.coveragerc` - Code coverage configuration

**Configuration Section:**
```ini
[testing]
framework = "jest"  # Options: jest, pytest, vitest
coverage = true
coverage_threshold = 80
```

**Scripts Added to package.json (Node.js):**
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve
- `BOOTSTRAP_TEST_FRAMEWORK` - Override detected framework

**Location:** `__bootbuild/scripts/bootstrap-testing.sh`

**Example:**
```bash
./bootstrap-testing.sh

# Then use
npm test
npm run test:watch
npm run test:coverage
```

**Next Step:** Run `bootstrap-typescript.sh` if using TypeScript.

---

### bootstrap-typescript.sh

**Purpose:** Configure TypeScript compiler and type checking.

**Status:** ✅ Active

**Dependencies:**
- Node.js project with package.json
- TypeScript should be installed (script can install it)
- bootstrap-packages.sh should run first

**Runtime:** ~3-5 seconds

**Files Created:**
- `tsconfig.json` - TypeScript compiler configuration
- `tsconfig.eslint.json` - ESLint-specific TypeScript config
- `.eslintrc.json` updates - Add TypeScript parser

**Configuration Section:**
```ini
[typescript]
enabled = true
version = "5.0"
target = "ES2020"
module = "ES2020"
strict = true
```

**Scripts Added to package.json:**
```json
{
  "scripts": {
    "type-check": "tsc --noEmit",
    "type-check:watch": "tsc --noEmit --watch"
  }
}
```

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve
- `BOOTSTRAP_TYPESCRIPT_VERSION` - Specific TypeScript version

**Location:** `__bootbuild/scripts/bootstrap-typescript.sh`

**Example:**
```bash
./bootstrap-typescript.sh

# Then use
npm run type-check
npm run type-check:watch
```

**Next Step:** Proceed to Phase 3 if using Docker.

---

## Phase 3: Advanced

### bootstrap-docker.sh

**Purpose:** Set up Docker containerization for development and deployment.

**Status:** ✅ Active

**Dependencies:**
- Docker must be installed
- Docker Compose recommended for orchestration
- Project should have dependencies configured first

**Runtime:** ~2-3 seconds (file creation only, no container operations)

**Files Created:**
- `Dockerfile` - Multi-stage Docker image definition
- `docker-compose.yml` - Service orchestration configuration
- `.dockerignore` - Files to exclude from Docker build context

**Configuration Section:**
```ini
[docker]
enabled = true
compose = true
registry = "docker.io"
base_image = "node:20-alpine"  # Or appropriate base
```

**Dockerfile Structure (Node.js example):**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

**Docker Compose Services:**
- Application container
- Database container (if applicable)
- Cache/Redis container (if applicable)
- Development volume mounts

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve
- `BOOTSTRAP_DOCKER_BASE` - Base image specification
- `BOOTSTRAP_DOCKER_PORT` - Exposed port

**Location:** `__bootbuild/scripts/bootstrap-docker.sh`

**Example:**
```bash
./bootstrap-docker.sh

# Then use
docker build -t my-app .
docker-compose up -d
docker-compose logs -f
```

**Next Step:** Optional - run `bootstrap-vscode.sh` for VS Code integration.

---

### bootstrap-ci.sh (Planned)

**Purpose:** Configure CI/CD pipeline (GitHub Actions, GitLab CI, or similar).

**Status:** 📋 Planned for Phase 3

**Expected Files:**
- `.github/workflows/ci.yml` (GitHub Actions)
- `.github/workflows/test.yml` - Automated testing
- `.github/workflows/deploy.yml` - Deployment pipeline
- `.gitlab-ci.yml` (GitLab CI alternative)

**Expected Configuration:**
- Linting validation
- Type checking
- Test execution
- Code coverage reporting
- Build verification
- Deployment to staging/production

---

### bootstrap-documentation.sh (Planned)

**Purpose:** Set up documentation generation and hosting configuration.

**Status:** 📋 Planned for Phase 3

**Expected Files:**
- `docs/` directory structure
- `mkdocs.yml` or `docusaurus.config.js`
- Documentation templates
- Deployment configuration for docs hosting

---

## Phase 4: Optional/Advanced

### bootstrap-vscode.sh

**Purpose:** Configure VS Code settings and extensions for the project.

**Status:** ✅ Active

**Dependencies:**
- VS Code installed (recommended, not required)
- Project directory writable

**Runtime:** ~1-2 seconds

**Files Created:**
- `.vscode/settings.json` - Workspace settings
- `.vscode/extensions.json` - Recommended extensions
- `.vscode/launch.json` - Debugger configuration

**Configuration Section:**
```ini
[vscode]
create_settings = true
create_extensions = true
create_launch = true
```

**Extensions Recommended:**
- ESLint - Linting
- Prettier - Code formatter
- GitLens - Git integration
- Debugger - Language-specific debuggers
- Docker - Docker support
- Thunder Client/REST Client - API testing

**Environment Variables:**
- `BOOTSTRAP_YES=true` - Auto-approve

**Location:** `__bootbuild/scripts/bootstrap-vscode.sh`

**Example:**
```bash
./bootstrap-vscode.sh

# Then in VS Code, install recommended extensions:
# Open Command Palette: Ctrl+Shift+P
# Type: Extensions: Show Recommended Extensions
```

---

## Usage Patterns

### Quick Start (Phase 1 Only)

For a quick project setup with essential tools:

```bash
./bootstrap-git.sh
./bootstrap-packages.sh
./bootstrap-environment.sh
```

**Time:** ~1-2 minutes
**Result:** Git-ready, dependencies installed, environment configured

---

### Full Development Setup (Phase 1 + 2)

Complete development environment with all tools:

```bash
./bootstrap-git.sh
./bootstrap-packages.sh
./bootstrap-environment.sh
./bootstrap-linting.sh
./bootstrap-testing.sh
./bootstrap-typescript.sh  # If using TypeScript
./bootstrap-vscode.sh      # If using VS Code
```

**Time:** ~3-5 minutes
**Result:** Professional development environment ready

---

### Production-Ready Setup (All Phases)

Enterprise-grade setup with Docker and CI/CD:

```bash
./bootstrap-git.sh
./bootstrap-packages.sh
./bootstrap-environment.sh
./bootstrap-linting.sh
./bootstrap-testing.sh
./bootstrap-typescript.sh
./bootstrap-docker.sh
./bootstrap-ci.sh         # When available
./bootstrap-vscode.sh
```

**Time:** ~5-10 minutes
**Result:** Full production-ready project structure

---

## Script Execution Order

**Critical:**
1. `bootstrap-git.sh` - Always first
2. `bootstrap-packages.sh` - Before Phase 2 scripts

**Recommended but flexible:**
3. `bootstrap-environment.sh` - Before development work
4. `bootstrap-linting.sh` - Code quality tools
5. `bootstrap-testing.sh` - Testing framework
6. `bootstrap-typescript.sh` - If using TypeScript
7. `bootstrap-docker.sh` - If using Docker
8. `bootstrap-vscode.sh` - If using VS Code

---

## Finding Scripts

All scripts located in: `__bootbuild/scripts/`

List available scripts:

```bash
ls -la __bootbuild/scripts/bootstrap-*.sh
```

View script details:

```bash
head -20 __bootbuild/scripts/bootstrap-git.sh
```

---

## Adding New Scripts

To create a new bootstrap script:

1. Read [PLAYBOOK_CREATING_SCRIPTS.md](../playbooks/PLAYBOOK_CREATING_SCRIPTS.md)
2. Use template structure from existing scripts
3. Source `lib/common.sh` for standard functions
4. Register in `bootstrap-menu.sh`
5. Add to appropriate phase in `bootstrap-*.profile`
6. Update this catalog

---

## Support

For detailed execution instructions, see:
- [PLAYBOOK_RUNNING.md](../playbooks/PLAYBOOK_RUNNING.md) - How to run scripts
- [REFERENCE_LIBRARY.md](REFERENCE_LIBRARY.md) - Available functions
- [REFERENCE_CONFIG.md](REFERENCE_CONFIG.md) - Configuration options

For creating new scripts:
- [PLAYBOOK_CREATING_SCRIPTS.md](../playbooks/PLAYBOOK_CREATING_SCRIPTS.md) - Step-by-step guide
- [PLAYBOOK_MIGRATING_SCRIPTS.md](../playbooks/PLAYBOOK_MIGRATING_SCRIPTS.md) - Standardizing existing scripts
