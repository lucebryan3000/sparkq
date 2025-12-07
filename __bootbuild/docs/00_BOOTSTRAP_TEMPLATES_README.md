# Project Bootstrap Templates

A complete collection of production-ready configuration files for modern TypeScript/React/Next.js development. These templates encode opinionated defaults optimized for AI-assisted development workflows, fast iteration, and minimal configuration overhead.

---

## Quick Start

```bash
# Clone templates to your machine
git clone [templates-repo] ~/templates/bootstrap

# Start a new project
mkdir my-project && cd my-project
git init

# Copy core files (always needed)
cp ~/templates/bootstrap/{.gitignore,.gitattributes,.editorconfig,.prettierrc.json,.prettierignore,.eslintrc.json,.eslintignore,.npmrc,.nvmrc} .

# Copy project files based on stack
cp ~/templates/bootstrap/{package.json,tsconfig.json,next.config.js,docker-compose.yml,Dockerfile,.dockerignore} .
cp ~/templates/bootstrap/{env.example,env.local} .
mv env.example .env.example
mv env.local .env.local

# Copy Claude/AI configuration
mkdir -p .claude
cp ~/templates/bootstrap/claude_settings_template.json .claude/settings.json
cp ~/templates/bootstrap/CLAUDE_md_template.example CLAUDE.md
cp ~/templates/bootstrap/claudeignore_template.example .claudeignore

# Copy VS Code configuration
mkdir -p .vscode
cp ~/templates/bootstrap/vscode_settings.json .vscode/settings.json
cp ~/templates/bootstrap/vscode_extensions.json .vscode/extensions.json
cp ~/templates/bootstrap/vscode_launch.json .vscode/launch.json
cp ~/templates/bootstrap/vscode_tasks.json .vscode/tasks.json

# Install and go
pnpm install
docker compose up -d
pnpm dev
```

---

## File Inventory

### Summary by Category

| Category | Files | Purpose |
|----------|-------|---------|
| **Git & Version Control** | 2 | Repository configuration |
| **Editor & Formatting** | 5 | Code style enforcement |
| **Linting** | 3 | Code quality rules |
| **Package Management** | 4 | Node.js/Python version pinning |
| **Environment** | 3 | Environment variables |
| **Docker** | 3 | Containerization |
| **TypeScript/Build** | 6 | Compilation and bundling |
| **Testing** | 3 | Test configuration |
| **Claude/AI** | 4 | AI assistant configuration |
| **VS Code** | 14 | Editor setup |
| **GitHub** | 5 | CI/CD and templates |
| **DevContainer** | 2 | Remote development |
| **Documentation** | 4 | Project docs |

**Total: 54 files**

---

## Detailed File Reference

### Git & Version Control

#### `.gitignore`
**Location:** Project root  
**When to use:** Every project  
**Purpose:** Excludes build artifacts, dependencies, secrets, and generated files from version control.

```bash
cp gitignore .gitignore
```

**Includes exclusions for:**
- Node.js (`node_modules/`, lock files)
- Next.js (`.next/`, `dist/`, `build/`)
- Python (`.venv/`, `__pycache__/`)
- Docker (`postgres_data/`)
- IDE files (`.vscode/*`, `.idea/`)
- Secrets (`.env*`, `*.pem`)
- Claude (`.claude/settings.local.json`)

---

#### `.gitattributes`
**Location:** Project root  
**When to use:** Every project  
**Purpose:** Ensures consistent line endings (LF) across all platforms, marks binary files, and configures diff behavior.

```bash
cp gitattributes .gitattributes
```

**Key settings:**
- Forces LF line endings for all text files
- Marks lock files as generated (no diff)
- Identifies binary file types
- Sets linguist overrides for GitHub stats

---

### Editor & Formatting

#### `.editorconfig`
**Location:** Project root  
**When to use:** Every project  
**Purpose:** Universal editor configuration that works across VS Code, JetBrains, Sublime, and others.

```bash
cp editorconfig .editorconfig
```

**Settings:**
- 2-space indentation (4 for Python/Go)
- LF line endings
- UTF-8 encoding
- Trim trailing whitespace
- Insert final newline

---

#### `.prettierrc.json`
**Location:** Project root (rename from `prettierrc.json` or `prettierrc_bootstrap.json`)  
**When to use:** JavaScript/TypeScript projects  
**Purpose:** Consistent code formatting.

```bash
cp prettierrc_bootstrap.json .prettierrc.json
# or
cp prettierrc.json .prettierrc
```

**Style:**
- No semicolons
- Single quotes
- Trailing commas (all)
- 2-space tabs
- 100 character line width
- Tailwind CSS plugin enabled

---

#### `.prettierignore`
**Location:** Project root (rename from `prettierignore`)  
**When to use:** With Prettier  
**Purpose:** Excludes files from formatting.

```bash
cp prettierignore .prettierignore
```

---

#### `.stylelintrc`
**Location:** Project root (rename from `stylelintrc`)  
**When to use:** Projects with CSS/SCSS  
**Purpose:** CSS linting with Tailwind support.

```bash
cp stylelintrc .stylelintrc.json
```

**Features:**
- Tailwind `@apply`, `@layer` support
- Alphabetical property ordering
- Modern color function notation

---

### Linting

#### `.eslintrc.json`
**Location:** Project root (rename from `eslintrc.json`)  
**When to use:** TypeScript/React/Next.js projects  
**Purpose:** Code quality and consistency rules.

```bash
cp eslintrc.json .eslintrc.json
```

**Includes:**
- TypeScript strict rules
- React hooks rules
- Next.js specific rules
- Import ordering
- Prettier compatibility
- Test file overrides

---

#### `.eslintignore`
**Location:** Project root (rename from `eslintignore`)  
**When to use:** With ESLint  
**Purpose:** Excludes files from linting.

```bash
cp eslintignore .eslintignore
```

---

### Package Management

#### `.npmrc`
**Location:** Project root (rename from `npmrc`)  
**When to use:** Node.js projects  
**Purpose:** npm/pnpm configuration.

```bash
cp npmrc .npmrc
```

**Settings:**
- `engine-strict=true` - Enforce Node version
- `save-exact=true` - Pin exact versions
- `fund=false` - No funding messages
- `audit=false` - No audit on install

---

#### `.nvmrc`
**Location:** Project root (rename from `nvmrc`)  
**When to use:** Node.js projects  
**Purpose:** Pins Node.js version for nvm/fnm.

```bash
cp nvmrc .nvmrc
```

**Current version:** `20`

---

#### `.tool-versions`
**Location:** Project root (rename from `tool-versions`)  
**When to use:** When using asdf version manager  
**Purpose:** Pins multiple runtime versions.

```bash
cp tool-versions .tool-versions
```

**Versions:**
- Node.js 20.17.0
- pnpm 9.6.0
- Python 3.12.4

---

#### `.envrc`
**Location:** Project root (rename from `envrc`)  
**When to use:** When using direnv  
**Purpose:** Automatic environment setup when entering directory.

```bash
cp envrc .envrc
direnv allow
```

**Features:**
- Loads `.env` files automatically
- Activates Node version from `.nvmrc`
- Activates Python venv if present
- Adds `node_modules/.bin` to PATH
- Disables telemetry

---

### Environment Variables

#### `.env.example`
**Location:** Project root (rename from `env.example`)  
**When to use:** Every project  
**Purpose:** Documents required environment variables (committed to git).

```bash
cp env.example .env.example
```

---

#### `.env.local`
**Location:** Project root (rename from `env.local`)  
**When to use:** Local development  
**Purpose:** Actual environment values (never committed).

```bash
cp env.local .env.local
# Edit values as needed
```

**Pre-configured for:**
- PostgreSQL on localhost:5432
- Development mode
- Debug logging enabled

---

### Docker

#### `docker-compose.yml`
**Location:** Project root  
**When to use:** Containerized development  
**Purpose:** Development stack with PostgreSQL and app service.

```bash
cp docker-compose.yml .
docker compose up -d
```

**Services:**
- `db` - PostgreSQL 16 Alpine with health checks
- `app` - Next.js with hot reload

---

#### `Dockerfile`
**Location:** Project root  
**When to use:** Containerized deployment  
**Purpose:** Multi-stage build for development and production.

```bash
cp Dockerfile .
```

**Stages:**
1. `base` - Alpine Node.js
2. `deps` - Install dependencies
3. `development` - Dev server with volume mounts
4. `builder` - Production build
5. `production` - Minimal production image

---

#### `.dockerignore`
**Location:** Project root (rename from `dockerignore`)  
**When to use:** With Docker  
**Purpose:** Excludes files from Docker build context.

```bash
cp dockerignore .dockerignore
```

---

### TypeScript & Build Tools

#### `tsconfig.json`
**Location:** Project root  
**When to use:** TypeScript projects  
**Purpose:** TypeScript compiler configuration.

```bash
cp tsconfig.json .
```

**Features:**
- Strict mode enabled
- `noUncheckedIndexedAccess` for safer arrays
- Path alias `@/*` → `./src/*`
- Next.js plugin

---

#### `next.config.js`
**Location:** Project root  
**When to use:** Next.js projects  
**Purpose:** Next.js configuration.

```bash
cp next.config.js .
```

**Features:**
- Standalone output for Docker
- Typed routes (experimental)
- Security headers
- No telemetry

---

#### `babel.config.js`
**Location:** Project root  
**When to use:** Projects needing Babel (older tooling, Jest)  
**Purpose:** JavaScript/TypeScript transpilation.

```bash
cp babel.config.js .
```

---

#### `vite.config.ts`
**Location:** Project root  
**When to use:** Vite-based projects (not Next.js)  
**Purpose:** Vite bundler configuration.

```bash
cp vite.config.ts .
```

**Features:**
- React plugin
- TypeScript paths
- Vitest integration
- Vendor chunking

---

#### `rollup.config.js`
**Location:** Project root  
**When to use:** Library/package builds  
**Purpose:** Rollup bundler for publishing packages.

```bash
cp rollup.config.js .
```

**Outputs:**
- CommonJS (`.cjs`)
- ES Modules (`.mjs`)
- TypeScript declarations (`.d.ts`)

---

#### `webpack.config.js`
**Location:** Project root  
**When to use:** Webpack-based projects  
**Purpose:** Webpack bundler configuration.

```bash
cp webpack.config.js .
```

---

### Testing

#### `jest.config.js`
**Location:** Project root  
**When to use:** Jest testing  
**Purpose:** Jest test runner configuration.

```bash
cp jest.config.js .
```

**Features:**
- jsdom environment
- Path aliases
- Coverage thresholds (70%)
- 30 second timeout

**Requires setup file:**
```bash
mkdir -p testing
cat > testing/setup.ts << 'EOF'
import '@testing-library/jest-dom'
EOF
```

---

#### `pytest.ini`
**Location:** Project root  
**When to use:** Python projects  
**Purpose:** pytest configuration.

```bash
cp pytest.ini .
```

**Features:**
- Strict markers
- 5-minute timeout
- Async mode auto
- Coverage integration

---

#### `.coveragerc`
**Location:** Project root (rename from `coveragerc`)  
**When to use:** Python coverage  
**Purpose:** Python coverage.py configuration.

```bash
cp coveragerc .coveragerc
```

---

### Claude & AI Configuration

#### `.claude/settings.json`
**Location:** `.claude/settings.json` (from `claude_settings_template.json`)  
**When to use:** Projects using Claude Code  
**Purpose:** Claude Code configuration.

```bash
mkdir -p .claude
cp claude_settings_template.json .claude/settings.json
```

**Key settings:**
- `bypassPermissions` enabled
- 128K max output tokens
- PostToolUse hooks for linting
- Hard-blocked directories

---

#### `CLAUDE.md`
**Location:** Project root (from `CLAUDE_md_template.example`)  
**When to use:** Projects using Claude Code  
**Purpose:** Project-specific instructions for Claude.

```bash
cp CLAUDE_md_template.example CLAUDE.md
# Edit [PROJECT_NAME] and project-specific sections
```

**Sections:**
- Critical rules (self-test, permissions)
- Code style
- File organization
- Database conventions
- API patterns
- Testing expectations

---

#### `.claudeignore`
**Location:** Project root (from `claudeignore_template.example`)  
**When to use:** Projects using Claude Code  
**Purpose:** Excludes files from Claude's auto-loaded context.

```bash
cp claudeignore_template.example .claudeignore
```

**Note:** Files in `.claudeignore` are excluded from context but Claude can still search/read them if needed.

---

#### `.codex.json`
**Location:** Project root (from `codex.json`)  
**When to use:** Projects using OpenAI Codex CLI  
**Purpose:** Codex CLI configuration.

```bash
cp codex.json .codex.json
```

**Settings:**
- `full-auto` approval mode
- Full sandbox permissions
- History persistence

---

### VS Code Configuration

All VS Code files go in `.vscode/` directory:

```bash
mkdir -p .vscode
```

#### `.vscode/settings.json`
**From:** `vscode_settings.json`  
**Purpose:** Workspace editor settings.

```bash
cp vscode_settings.json .vscode/settings.json
```

**Features:**
- Dark theme (GitHub Dark)
- Format on save
- ESLint/Prettier integration
- Claude Code as primary AI
- Copilot inline disabled
- TypeScript 8GB memory

---

#### `.vscode/extensions.json`
**From:** `vscode_extensions.json`  
**Purpose:** Recommended extensions.

```bash
cp vscode_extensions.json .vscode/extensions.json
```

**Core extensions (38)** including:
- Claude Code
- GitHub Copilot (chat only)
- ESLint, Prettier
- Tailwind CSS
- Prisma
- GitLens

---

#### `.vscode/launch.json`
**From:** `vscode_launch.json`  
**Purpose:** Debug configurations.

```bash
cp vscode_launch.json .vscode/launch.json
```

**Configurations:**
- Next.js server + client
- Jest (all, current file, debug)
- Playwright
- Docker attach
- Prisma tools

---

#### `.vscode/tasks.json`
**From:** `vscode_tasks.json`  
**Purpose:** Common development tasks.

```bash
cp vscode_tasks.json .vscode/tasks.json
```

**Tasks:**
- `dev`, `build`, `lint`, `test`
- `docker:up`, `docker:down`, `docker:rebuild`
- `prisma:migrate`, `prisma:studio`

---

#### `.vscode/snippets/typescript.json`
**From:** `vscode_snippets_typescript.json`  
**Purpose:** Code snippets for TypeScript/React.

```bash
mkdir -p .vscode/snippets
cp vscode_snippets_typescript.json .vscode/snippets/typescript.json
```

**Snippets:**
| Prefix | Description |
|--------|-------------|
| `rfc` | React functional component |
| `rcc` | React client component |
| `rsc` | React server component |
| `hook` | Custom hook |
| `zod` | Zod schema |
| `api` | API route handler |
| `service` | Prisma service |
| `desc` | Jest describe |
| `it` | Jest it block |

---

#### Additional VS Code Files

| Template File | Target Location | Purpose |
|---------------|-----------------|---------|
| `vscode_keybindings.json` | User settings (not project) | Global keyboard shortcuts |
| `vscode_extensions-python.json` | `.vscode/extensions.json` | Python extension pack |
| `vscode_extensions-azure.json` | `.vscode/extensions.json` | Azure extension pack |
| `vscode_extensions-remote.json` | `.vscode/extensions.json` | Remote SSH/containers |
| `vscode_extensions-jupyter.json` | `.vscode/extensions.json` | Jupyter notebooks |
| `vscode_extensions-go.json` | `.vscode/extensions.json` | Go development |
| `vscode_extensions-ai-experimental.json` | `.vscode/extensions.json` | Additional AI tools |

---

### GitHub Configuration

#### `.github/workflows/ci.yml`
**From:** `github_workflows_ci.yml`  
**Purpose:** CI/CD pipeline.

```bash
mkdir -p .github/workflows
cp github_workflows_ci.yml .github/workflows/ci.yml
```

**Jobs:**
1. `lint` - ESLint + Prettier
2. `typecheck` - TypeScript
3. `test` - Jest with PostgreSQL service
4. `build` - Next.js build

---

#### `.github/PULL_REQUEST_TEMPLATE.md`
**From:** `github_PULL_REQUEST_TEMPLATE.md`  
**Purpose:** PR template.

```bash
mkdir -p .github
cp github_PULL_REQUEST_TEMPLATE.md .github/PULL_REQUEST_TEMPLATE.md
```

---

#### `.github/ISSUE_TEMPLATE/`
**From:** `github_ISSUE_TEMPLATE_*.md` and `github_ISSUE_TEMPLATE_config.yml`  
**Purpose:** Issue templates.

```bash
mkdir -p .github/ISSUE_TEMPLATE
cp github_ISSUE_TEMPLATE_bug_report.md .github/ISSUE_TEMPLATE/bug_report.md
cp github_ISSUE_TEMPLATE_feature_request.md .github/ISSUE_TEMPLATE/feature_request.md
cp github_ISSUE_TEMPLATE_config.yml .github/ISSUE_TEMPLATE/config.yml
```

---

### DevContainer

#### `.devcontainer/devcontainer.json`
**From:** `devcontainer.json`  
**Purpose:** VS Code Dev Container configuration.

```bash
mkdir -p .devcontainer
cp devcontainer.json .devcontainer/devcontainer.json
```

---

#### `.devcontainer/Dockerfile`
**From:** `devcontainer_Dockerfile`  
**Purpose:** Dev container image.

```bash
cp devcontainer_Dockerfile .devcontainer/Dockerfile
```

**Includes:**
- Node.js 20
- pnpm
- PostgreSQL client
- Oh My Zsh

---

### Documentation

#### `README.md`
**Location:** Project root  
**When to use:** Every project  
**Purpose:** Project documentation.

```bash
cp README.md .
# Edit project-specific content
```

---

#### `project_scaffold_template.md`
**Purpose:** Comprehensive project structure reference.  
**Usage:** Reference document, not copied to projects.

---

#### `0_bryan_developer_profile_v0.2.md`
**Purpose:** Developer preferences and standards reference.  
**Usage:** Reference document for AI context, add to project knowledge.

---

#### `python_env_block_reference.md`
**Purpose:** Reference for Python environment blocking patterns.  
**Usage:** Consult when configuring `.claudeignore` or `additionalDirectories`.

---

## Project Type Recipes

### Next.js + PostgreSQL (Standard)

```bash
# Core
cp {.gitignore,.gitattributes,.editorconfig,.prettierrc.json,.prettierignore,.eslintrc.json,.eslintignore,.npmrc,.nvmrc} .

# Project
cp {package.json,tsconfig.json,next.config.js,jest.config.js} .
cp {docker-compose.yml,Dockerfile,.dockerignore} .

# Environment
cp env.example .env.example
cp env.local .env.local

# Claude
mkdir -p .claude
cp claude_settings_template.json .claude/settings.json
cp CLAUDE_md_template.example CLAUDE.md
cp claudeignore_template.example .claudeignore

# VS Code
mkdir -p .vscode
cp vscode_{settings,extensions,launch,tasks}.json .vscode/

# GitHub
mkdir -p .github/workflows .github/ISSUE_TEMPLATE
cp github_workflows_ci.yml .github/workflows/ci.yml
cp github_PULL_REQUEST_TEMPLATE.md .github/
cp github_ISSUE_TEMPLATE_*.md .github/ISSUE_TEMPLATE/
cp github_ISSUE_TEMPLATE_config.yml .github/ISSUE_TEMPLATE/config.yml
```

### Python + FastAPI

```bash
# Core
cp {.gitignore,.gitattributes,.editorconfig} .

# Python-specific
cp {pytest.ini,.coveragerc,.tool-versions} .

# Environment
cp env.example .env.example
cp envrc .envrc

# Claude
mkdir -p .claude
cp claude_settings_template.json .claude/settings.json
cp CLAUDE_md_template.example CLAUDE.md

# VS Code (with Python extensions)
mkdir -p .vscode
cp vscode_settings.json .vscode/settings.json
# Merge vscode_extensions-python.json into extensions.json
```

### Library/Package

```bash
# Core
cp {.gitignore,.gitattributes,.editorconfig,.prettierrc.json,.eslintrc.json,.npmrc,.nvmrc} .

# Build
cp {tsconfig.json,rollup.config.js} .

# Testing
cp jest.config.js .
```

---

## Customization Guide

### Adding Project-Specific Exclusions

**`.gitignore`** - Add at bottom:
```gitignore
# Project-specific
data/raw/
exports/
```

**`.claudeignore`** - Add at bottom:
```gitignore
# Project-specific
data/
exports/
```

**`.eslintignore`** - Add patterns as needed

---

### Updating Dependencies

The `package.json` template uses caret ranges. To pin exact versions:

```bash
# After install, update package.json with exact versions
pnpm update
```

---

### Modifying Claude Settings

Edit `.claude/settings.json`:

```jsonc
{
  "env": {
    // Add project-specific env vars
    "MY_VAR": "value"
  },
  "permissions": {
    "additionalDirectories": [
      // Add more hard-blocked paths
      "./data"
    ]
  }
}
```

---

### VS Code Extension Profiles

For heavy projects, merge additional extension packs:

```bash
# Python project
jq -s '.[0].recommendations + .[1].recommendations | {recommendations: .}' \
  vscode_extensions.json vscode_extensions-python.json > .vscode/extensions.json
```

---

## Maintenance

### Keeping Templates Updated

1. Clone templates repo
2. Make changes to templates
3. Test in a new project
4. Commit and push

### Version Pinning Strategy

| File | Strategy |
|------|----------|
| `.nvmrc` | Major version only (`20`) |
| `.tool-versions` | Full version (`20.17.0`) |
| `package.json` | Exact versions via `.npmrc` |
| `Dockerfile` | Specific tags (`node:20-alpine`) |

---

## Troubleshooting

### ESLint Errors on Fresh Project

```bash
# Ensure TypeScript is installed
pnpm add -D typescript

# Generate tsconfig if missing
npx tsc --init
```

### Prettier/ESLint Conflicts

The templates include `eslint-config-prettier` to disable conflicting rules. If issues persist:

```bash
pnpm add -D eslint-config-prettier
```

### Docker Compose Database Issues

```bash
# Reset database completely
docker compose down -v
docker compose up -d

# Check logs
docker compose logs db
```

### Claude Code Not Using Settings

1. Ensure `.claude/settings.json` exists (not `settings.local.json`)
2. Restart Claude Code
3. Check for JSON syntax errors

---

## File Naming Reference

Templates use modified names to avoid conflicts. Rename when copying:

| Template Name | Target Name |
|---------------|-------------|
| `gitignore` | `.gitignore` |
| `gitattributes` | `.gitattributes` |
| `editorconfig` | `.editorconfig` |
| `prettierrc.json` | `.prettierrc` or `.prettierrc.json` |
| `prettierrc_bootstrap.json` | `.prettierrc.json` |
| `prettierignore` | `.prettierignore` |
| `eslintrc.json` | `.eslintrc.json` |
| `eslintignore` | `.eslintignore` |
| `stylelintrc` | `.stylelintrc.json` |
| `coveragerc` | `.coveragerc` |
| `tool-versions` | `.tool-versions` |
| `npmrc` | `.npmrc` |
| `nvmrc` | `.nvmrc` |
| `envrc` | `.envrc` |
| `env.example` | `.env.example` |
| `env.local` | `.env.local` |
| `dockerignore` | `.dockerignore` |
| `codex.json` | `.codex.json` |
| `claude_settings_template.json` | `.claude/settings.json` |
| `claudeignore_template.example` | `.claudeignore` |
| `CLAUDE_md_template.example` | `CLAUDE.md` |
| `vscode_*.json` | `.vscode/*.json` |
| `github_*.yml` | `.github/workflows/*.yml` |
| `github_*.md` | `.github/*.md` |
| `devcontainer.json` | `.devcontainer/devcontainer.json` |
| `devcontainer_Dockerfile` | `.devcontainer/Dockerfile` |
