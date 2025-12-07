# Bootstrap Playbooks - Script Implementation Guide

Complete documentation for all bootstrap scripts in the SparkQ bootstrap system.

---

## Phase 1: AI Development Toolkit (FIRST)

These scripts set up AI tools and development environment first for optimal workflow.

### 1. bootstrap-claude.sh

**Purpose**: Configure Claude Code for AI-assisted development

**What it does**:
- Creates `.claude/` directory structure with agents, commands, hooks, skills subdirectories
- Copies Claude Code configuration from templates
- Sets up project instructions for Claude AI
- Configures `.claudeignore` for files to exclude from context
- Optional: Sets up Codex integration

**Files created**:
- `.claude/settings.json` - Claude Code configuration
- `.claude/codex.md` - Codex documentation
- `.claude/codex_prompt.md` - Codex prompt templates
- `.claude/haiku.md` - Haiku instructions
- `.claude/self-testing-protocol.md` - Self-testing guidelines
- `.claude/codex-optimization.md` - Optimization tips
- `.claudeignore` - Files excluded from Claude context

**When to use**: First script - enables AI assistance for all subsequent setup

**Status**: ✅ Available

---

### 2. bootstrap-git.sh

**Purpose**: Initialize Git repository and set up version control configuration

**What it does**:
- Creates `.gitignore` with sensible defaults for Node.js, Python, IDE files
- Creates `.gitattributes` for consistent line endings across platforms
- Initializes Git repository if needed
- Sets up git user configuration

**Files created**:
- `.gitignore` - Files to exclude from git
- `.gitattributes` - Line ending normalization and binary file handling

**Key patterns**:
```
# Standard patterns included:
node_modules/, pnpm-lock.yaml, yarn.lock, package-lock.json
.env, .env.local, .env.*.local
dist/, build/, .next/, out/
.vscode/, .idea/, *.swp, .DS_Store
logs/, coverage/, .jest_cache/
```

**When to use**: Second - foundation for version control

**Status**: ✅ Available

---

### 3. bootstrap-vscode.sh

**Purpose**: Configure Visual Studio Code workspace

**What it does**:
- Creates `.vscode/settings.json` with editor preferences
- Sets up `.vscode/extensions.json` with recommended extensions
- Creates `.vscode/launch.json` for debugging (Node, Next.js, Jest)
- Adds `.vscode/tasks.json` for development tasks
- Includes TypeScript code snippets

**Files created**:
- `.vscode/settings.json` - Editor settings (formatting, theme, debugging)
- `.vscode/extensions.json` - Recommended extensions
- `.vscode/launch.json` - Debug configurations
- `.vscode/tasks.json` - Task definitions
- `.vscode/snippets/typescript.json` - Code snippets

**Default extensions**:
- ESLint
- Prettier - Code formatter
- TypeScript Vue Plugin
- Vitest
- Thunder Client

**When to use**: Early - comfortable IDE is essential for productive development

**Status**: ✅ Available

---

### 4. bootstrap-codex.sh

**Purpose**: Set up OpenAI Codex integration for code completion

**What it does**:
- Creates `.codex.json` with API key and model configuration
- Creates `.codexignore` to exclude files from Codex context
- Configures temperature, tokens, and sampling parameters
- Sets up context limits and cache settings

**Files created**:
- `.codex.json` - Codex configuration (API keys, model, parameters)
- `.codexignore` - Files and patterns to exclude

**Configuration options**:
```json
{
  "openai": {
    "apiKey": "${OPENAI_API_KEY}",
    "model": "code-davinci-002"
  },
  "codex": {
    "enabled": false,
    "temperature": 0.5,
    "maxTokens": 100
  }
}
```

**Requirements**:
- OpenAI API key (from https://beta.openai.com/account/api-keys)
- OPENAI_API_KEY environment variable

**When to use**: Critical for AI code completion

**Status**: ✅ Available

---

### 5. bootstrap-packages.sh

**Purpose**: Set up package manager and runtime version management

**What it does**:
- Creates `.npmrc` with npm/pnpm configuration
- Creates `.nvmrc` for Node.js version pinning (reads current version)
- Creates `.tool-versions` for asdf version manager
- Creates `.envrc` for direnv automatic environment setup
- Creates basic `package.json` if missing

**Files created**:
- `.npmrc` - NPM configuration (lockfile version, audit settings)
- `.nvmrc` - Node.js version (e.g., "20.10.0")
- `.tool-versions` - asdf version manager config
- `.envrc` - direnv automatic environment loading
- `package.json` - Basic project metadata if missing

**What it configures**:
```
save-exact=true          # Don't auto-update versions
lockfile-version=3       # Modern lock file format
loglevel=warn           # Reduce verbosity
audit=false             # Optional: disable audit checks
```

**Version managers supported**:
- nvm (Node Version Manager) - https://github.com/nvm-sh/nvm
- asdf (All languages) - https://asdf-vm.com/
- direnv (Auto environment) - https://direnv.net/

**When to use**: Critical - dependencies needed before development starts

**Status**: ✅ Available

---

### 6. bootstrap-typescript.sh

**Purpose**: Configure TypeScript and build tools

**What it does**:
- Creates `tsconfig.json` with strict type checking enabled
- Creates `next.config.js` for Next.js projects
- Creates `babel.config.js` for transpilation
- Creates `vite.config.ts` for Vite bundler
- Creates `src/` directory structure

**Files created**:
- `tsconfig.json` - TypeScript compiler options (strict mode enabled)
- `next.config.js` - Next.js configuration
- `babel.config.js` - Babel transpilation config
- `vite.config.ts` - Vite bundler configuration
- `src/` directory with subdirectories

**TypeScript strict flags enabled**:
```
"strict": true
"noImplicitAny": true
"strictNullChecks": true
"strictFunctionTypes": true
"strictPropertyInitialization": true
"noImplicitThis": true
"noImplicitReturns": true
"noUncheckedIndexedAccess": true
```

**Directory structure created**:
```
src/
├── components/
├── hooks/
├── lib/
├── types/
└── services/
```

**When to use**: Critical - type safety and build setup needed immediately

**Status**: ✅ Available

---

### 7. bootstrap-environment.sh

**Purpose**: Set up environment variables and development configuration

**What it does**:
- Creates `.env.example` template with all required variables
- Creates `.env.local` with placeholder development values
- Creates `.env.production` template for production deployment
- Creates `env.d.ts` for TypeScript environment type definitions

**Files created**:
- `.env.example` - Template with all variables and documentation
- `.env.local` - Local development values (excluded from git)
- `.env.production` - Production deployment template
- `env.d.ts` - TypeScript type definitions for environment variables

**Variables included**:
```
# Application
NODE_ENV, DEBUG, PORT, HOST

# Database
DATABASE_URL, DATABASE_POOL_SIZE

# Cache
REDIS_URL, REDIS_PASSWORD

# API Keys
API_KEY, SECRET_KEY, OPENAI_API_KEY, GITHUB_TOKEN

# Authentication
JWT_SECRET, JWT_EXPIRY

# Logging
LOG_LEVEL, LOG_FORMAT

# External Services
SENDGRID_API_KEY, SENTRY_DSN
```

**Key patterns**:
```
.env.example    → Committed to git (template)
.env.local      → .gitignored (local values)
.env.production → Committed to git (production template)
env.d.ts        → Committed to git (TypeScript types)
```

**When to use**: Critical - development can't start without env vars

**Status**: ✅ Available

---

## Phase 2: Infrastructure (Core Development)

Set up the development infrastructure needed for active coding.

### 8. bootstrap-docker.sh

**Purpose**: Set up Docker and containerized development environment

**What it does**:
- Copies docker-compose.yml with PostgreSQL, Redis, and app services
- Copies multi-stage Dockerfile for development and production
- Copies .dockerignore with comprehensive file exclusions
- Validates YAML syntax and Dockerfile structure before copying
- Checks if Docker is installed (informational)
- Backs up existing files with timestamps
- Performs post-bootstrap validation of all files

**Files created**:
- `docker-compose.yml` - Development services (PostgreSQL, Redis, app)
- `Dockerfile` - Multi-stage build (development, builder, production)
- `.dockerignore` - Files excluded from Docker build (40+ patterns)

**Key features**:
```yaml
# docker-compose.yml includes:
- PostgreSQL 16 Alpine with health checks
- App service with volume mounts
- Environment variable support
- Service dependencies

# Dockerfile includes:
- Node.js 20 Alpine base
- Multi-stage build (deps, development, builder, production)
- Production: unprivileged nextjs user (uid:1001)
- Development: npm run dev support
```

**Validation**:
- Pre-copy: Validates YAML syntax, services definition, FROM instruction
- Post-bootstrap: Confirms files exist, YAML valid, services and instructions present
- Idempotent: Backs up existing files, can run multiple times safely

**When to use**: After Phase 1 - containerized development improves consistency

**Status**: ✅ Available

---

### 9. bootstrap-linting.sh

**Purpose**: Set up code linting and quality enforcement

**Files created**:
- `.eslintrc.json` - ESLint rules
- `.eslintignore` - Files excluded from linting
- Prettier configuration and integration

**Status**: 🔴 Coming soon

---

### 10. bootstrap-editor.sh

**Purpose**: Set up editor formatting standards

**Files created**:
- `.editorconfig` - Universal editor settings
- `.prettierrc.json` - Prettier formatting rules
- `.prettierignore` - Files excluded from formatting
- `.stylelintrc` - CSS linting rules

**Status**: 🔴 Coming soon

---

## Phase 3: Testing & Quality

Ensure code quality through testing.

### 11. bootstrap-testing.sh

**Purpose**: Set up testing frameworks and coverage

**Files created**:
- `jest.config.js` - Jest test runner configuration
- `pytest.ini` - Pytest configuration (for Python)
- `.coveragerc` - Coverage reporting configuration

**Status**: 🔴 Coming soon

---

## Phase 4: CI/CD & Deployment (Optional)

Set up automation and deployment pipelines.

### 12. bootstrap-github.sh

**Purpose**: Set up GitHub workflows and templates

**Files created**:
- `.github/workflows/ci.yml` - CI/CD pipeline
- `.github/PULL_REQUEST_TEMPLATE.md` - PR description template
- `.github/ISSUE_TEMPLATE/` - Issue templates (bug, feature, docs)

**Status**: ✅ Available

---

### 13. bootstrap-devcontainer.sh

**Purpose**: Set up VS Code Dev Containers for remote development

**Files created**:
- `.devcontainer/devcontainer.json` - Dev Container configuration
- `.devcontainer/Dockerfile` - Dev Container image

**Status**: 🔴 Coming soon

---

### 14. bootstrap-documentation.sh

**Purpose**: Initialize project documentation structure

**Files created**:
- `README.md` - Project overview and setup guide
- `docs/` - Documentation directory structure
- `CONTRIBUTING.md` - Contribution guidelines

**Status**: 🔴 Coming soon

---

## Usage Guide

### Running Individually

```bash
# Run specific bootstrap script
./bootstrap-claude.sh
./bootstrap-git.sh
./bootstrap-vscode.sh
./bootstrap-packages.sh
./bootstrap-typescript.sh
./bootstrap-environment.sh

# Run with custom project root
./bootstrap-claude.sh /path/to/project
```

### Using the Bootstrap Menu

```bash
# Interactive menu
./bootstrap-menu.sh

# Follows AI-first order:
# 1. Select script by number (1-14)
# 2. Confirm before running (Y/n)
# 3. Script runs and reports results
# 4. Return to menu or exit
```

### Chaining Scripts

```bash
# Run Phase 1 in order
./bootstrap-claude.sh && \
./bootstrap-git.sh && \
./bootstrap-vscode.sh && \
./bootstrap-packages.sh && \
./bootstrap-typescript.sh && \
./bootstrap-environment.sh
```

### Example: New Project Setup

```bash
# 1. Create project directory
mkdir my-project && cd my-project

# 2. Run Phase 1 scripts (minimum viable)
../../bootstrap-scripts/bootstrap-claude.sh . && \
../../bootstrap-scripts/bootstrap-git.sh . && \
../../bootstrap-scripts/bootstrap-vscode.sh . && \
../../bootstrap-scripts/bootstrap-packages.sh . && \
../../bootstrap-scripts/bootstrap-typescript.sh . && \
../../bootstrap-scripts/bootstrap-environment.sh .

# 3. Make initial commit
git add .
git commit -m "chore: initial bootstrap setup"

# 4. Install dependencies
npm install

# 5. Start coding with AI assistance!
code .
```

---

## Configuration Customization

After running bootstrap scripts, customize for your project:

### .env.local
```bash
# Edit with your local values
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
REDIS_URL=redis://localhost:6379
API_KEY=your_api_key
```

### .claude/settings.json
```json
{
  "model": "claude-3-opus",
  "maxTokens": 4000,
  "temperature": 0.7
}
```

### package.json
```json
{
  "name": "your-project-name",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "test": "vitest"
  }
}
```

### tsconfig.json
```json
{
  "compilerOptions": {
    "lib": ["ES2022", "DOM"],
    "jsx": "react-jsx"
  }
}
```

---

## Troubleshooting

### Script fails to run
```bash
# Make executable
chmod +x bootstrap-*.sh

# Run with bash explicitly
bash bootstrap-git.sh
```

### Permission denied errors
```bash
# Check permissions
ls -la .env.local

# Fix permissions
chmod 600 .env.local
```

### Git initialization fails
```bash
# If git is not initialized
git init
git config user.name "Your Name"
git config user.email "your@email.com"

# Then run bootstrap scripts
./bootstrap-git.sh
```

### Environment variables not loading
```bash
# Ensure .env.local exists
ls -la .env.local

# Allow direnv
direnv allow

# Or manually source
source .env.local
```

### TypeScript errors after bootstrap
```bash
# Install TypeScript
npm install --save-dev typescript

# Verify config
npx tsc --noEmit

# Generate type definitions
npm run build
```

---

## References

- [Claude Code Documentation](https://code.claude.com/docs)
- [Node.js](https://nodejs.org/)
- [TypeScript](https://www.typescriptlang.org/)
- [Next.js](https://nextjs.org/)
- [npm](https://www.npmjs.com/)
- [direnv](https://direnv.net/)
- [asdf](https://asdf-vm.com/)

---

**Last Updated**: December 2025
**SparkQ Version**: Bootstrap System v1.0
