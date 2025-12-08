# Bootstrap Scripts - SparkQ AI-First Development

Interactive menu and automated setup scripts for new SparkQ projects. Optimized for AI-assisted development with Claude Code.

## Quick Start

```bash
# Run the bootstrap menu
./bootstrap-menu.sh

# Or run individual scripts
./bootstrap-claude.sh
./bootstrap-vscode.sh
./bootstrap-github.sh
```

## Bootstrap Menu

The `bootstrap-menu.sh` script provides an interactive menu for running setup scripts in the **AI-first** recommended order.

### Menu Philosophy

Instead of organizing by file type (Git → Editor → Linting), we organize by **developer workflow**:

1. **Phase 1**: Get AI tools and IDE ready for development
2. **Phase 2**: Set up infrastructure (Docker, databases)
3. **Phase 3**: Add quality tools (testing, linting)
4. **Phase 4**: Automate CI/CD and deployment

This lets you start coding faster with AI assistance from the beginning.

### Features

✓ **Four Clear Phases**
- **Phase 1** 🔴 - AI Development Toolkit (DO FIRST)
- **Phase 2** 🔴 - Infrastructure (Core Development)
- **Phase 3** 🟡 - Testing & Quality (Important)
- **Phase 4** 🟢 - CI/CD & Deployment (Optional)

✓ **Color-Coded Status**
- **Red** (🔴) - Critical: Must complete before productive development
- **Yellow** (🟡) - Important: Needed for quality code
- **Green** (🟢) - Optional: Can be done later
- **Green** ✓ - Available and ready to run
- **Grey** - Coming soon (not yet created)

✓ **User-Friendly Input**
- Default to YES (press Enter to confirm)
- Type 'q' or 'x' to exit at any time
- Validates all input with helpful error messages
- Won't let you run scripts that aren't ready yet

✓ **Safety Features**
- Confirms before running each script
- Reports script exit codes
- Auto-chmod scripts if needed
- Offers to continue or exit after each run

### Menu Structure (14 Scripts Total)

```
═══════════════════════════════════════════════════════
   SparkQ Bootstrap Menu - AI-First Development Order
═══════════════════════════════════════════════════════

🔴 PHASE 1: AI Development Toolkit (FIRST)
────────────────────────────────────────────
  1. bootstrap-claude.sh
  2. bootstrap-git.sh (coming soon)
  3. bootstrap-vscode.sh
  4. bootstrap-codex.sh (coming soon)
  5. bootstrap-packages.sh (coming soon)
  6. bootstrap-typescript.sh (coming soon)
  7. bootstrap-environment.sh (coming soon)

🔴 PHASE 2: Infrastructure (Core Development)
────────────────────────────────────────────
  8. bootstrap-docker.sh (coming soon)
  9. bootstrap-linting.sh (coming soon)
  10. bootstrap-editor.sh (coming soon)

🟡 PHASE 3: Testing & Quality
────────────────────────────────
  11. bootstrap-testing.sh (coming soon)

🟢 PHASE 4: CI/CD & Deployment (Optional)
──────────────────────────────────────────
  12. bootstrap-github.sh
  13. bootstrap-devcontainer.sh (coming soon)
  14. bootstrap-documentation.sh (coming soon)

Press 'q' or 'x' to exit menu

Enter script number to run (1-14):
```

## Available Scripts

### Phase 1: AI Development Toolkit

#### ✓ bootstrap-claude.sh
Sets up Claude Code configuration for the project.

**Configures:**
- `.claude/settings.json` - Claude Code settings (permissions, models, etc.)
- `CLAUDE.md` - Project instructions for Claude
- `.claudeignore` - Files excluded from Claude context
- `.codex.json` - Codex CLI configuration (optional)

**Why First**: Claude Code helps with all subsequent setup tasks.

#### ✓ bootstrap-vscode.sh
Configures Visual Studio Code workspace settings and extensions.

**Configures:**
- `.vscode/settings.json` - Editor settings (theme, formatting, debugging)
- `.vscode/extensions.json` - Recommended extensions (ESLint, Prettier, etc.)
- `.vscode/launch.json` - Debug configurations (Node, Next.js, Jest)
- `.vscode/tasks.json` - Development tasks (dev, build, lint, test)
- `.vscode/snippets/typescript.json` - Code snippets

**Why Early**: Comfortable IDE is essential for productive development.

### Phase 2: Infrastructure

*All Phase 2 scripts coming soon*

### Phase 3: Testing & Quality

*Phase 3 script coming soon*

### Phase 4: CI/CD & Deployment

#### ✓ bootstrap-github.sh
Sets up GitHub workflows, PR templates, and issue templates.

**Configures:**
- `.github/workflows/ci.yml` - CI/CD pipeline (lint, test, build, deploy)
- `.github/PULL_REQUEST_TEMPLATE.md` - PR description template
- `.github/ISSUE_TEMPLATE/` - Issue templates (bug, feature, documentation)

**When to Use**: Set up after code is working locally, ready to commit to GitHub.

## Scripts Coming Soon

### Phase 1: AI Development Toolkit

#### bootstrap-git.sh (coming soon)
Sets up Git configuration for the project.

**Configures:**
- `.gitignore` - Files to ignore in version control
- `.gitattributes` - Line ending normalization and binary file handling

#### bootstrap-codex.sh (coming soon)
Configures OpenAI Codex CLI integration.

#### bootstrap-packages.sh (coming soon)
Sets up package manager and runtime version management.

**Configures:**
- `.npmrc` - npm/pnpm configuration
- `.nvmrc` - Node.js version pinning
- `.tool-versions` - asdf version manager config
- `.envrc` - direnv automatic environment setup

#### bootstrap-typescript.sh (coming soon)
Sets up TypeScript and JavaScript build configuration.

**Configures:**
- `tsconfig.json` - TypeScript compiler options
- `next.config.js` - Next.js application configuration
- `babel.config.js` - Babel transpilation config
- `vite.config.ts` - Vite bundler config
- `rollup.config.js` - Rollup bundler config
- `webpack.config.js` - Webpack bundler config

#### bootstrap-environment.sh (coming soon)
Sets up environment variables and local development configuration.

**Configures:**
- `.env.example` - Template for required environment variables
- `.env.local` - Local development environment values
- Database connection strings
- API keys and secrets

### Phase 2: Infrastructure (Core Development)

#### bootstrap-docker.sh (coming soon)
Sets up Docker and containerized development environment.

**Configures:**
- `docker-compose.yml` - Development services (PostgreSQL, Redis, app)
- `Dockerfile` - Production image definition
- `.dockerignore` - Files excluded from Docker build

#### bootstrap-linting.sh (coming soon)
Sets up code linting and quality enforcement.

**Configures:**
- `.eslintrc.json` - ESLint rules for JavaScript/TypeScript
- `.eslintignore` - Files excluded from linting
- Prettier integration for consistent formatting

#### bootstrap-editor.sh (coming soon)
Sets up editor formatting standards.

**Configures:**
- `.editorconfig` - Universal editor settings (indentation, line endings)
- `.prettierrc.json` - Prettier code formatting rules
- `.prettierignore` - Files excluded from formatting
- `.stylelintrc` - CSS linting rules

### Phase 3: Testing & Quality

#### bootstrap-testing.sh (coming soon)
Sets up testing frameworks and coverage.

**Configures:**
- `jest.config.js` - Jest test runner configuration
- `pytest.ini` - Pytest configuration (for Python)
- `.coveragerc` - Coverage reporting configuration

### Phase 4: CI/CD & Deployment

#### bootstrap-devcontainer.sh (coming soon)
Sets up VS Code Dev Containers for remote development.

**Configures:**
- `.devcontainer/devcontainer.json` - Dev Container configuration
- `.devcontainer/Dockerfile` - Dev Container image

#### bootstrap-documentation.sh (coming soon)
Initializes project documentation structure.

**Configures:**
- `README.md` - Project overview and setup guide
- `CONTRIBUTING.md` - Contribution guidelines
- `docs/` - Documentation directory structure

## Usage Examples

### Run the menu interactively
```bash
./bootstrap-menu.sh
```

### Run specific scripts
```bash
# Set up Claude Code
./bootstrap-claude.sh

# Set up VS Code
./bootstrap-vscode.sh

# Set up GitHub
./bootstrap-github.sh
```

### Combine multiple scripts (when available)
```bash
# Run Phase 1 scripts in order
./bootstrap-claude.sh && \
./bootstrap-git.sh && \
./bootstrap-vscode.sh
```

## Recommended Setup Sequence

### Minimum Setup (Get coding now)
```
1. bootstrap-claude.sh      - AI assistance ready
2. bootstrap-vscode.sh      - IDE ready
3. bootstrap-packages.sh    - Dependencies ready
4. bootstrap-typescript.sh  - Type safety & build ready
5. bootstrap-environment.sh - Dev environment ready
```

**Time**: ~10-15 minutes, then start coding with AI assistance

### Complete Setup (Production-ready)
```
Phase 1 (AI Toolkit): All 7 scripts
Phase 2 (Infrastructure): All 3 scripts
Phase 3 (Testing): 1 script
Phase 4 (Optional): As needed
```

**Time**: 30-45 minutes, fully configured for team development

## Customization

After running scripts, customize:
- `.env.local` - Your local environment variables
- `.claude/settings.json` - Claude Code AI model and capabilities
- `.vscode/extensions.json` - IDE extensions for your stack
- `.github/workflows/ci.yml` - CI/CD pipeline for your needs

## File Inventory

See [MENU_STRUCTURE.md](references/MENU_STRUCTURE.md) for:
- Complete list of all files created by each script
- Detailed setup strategy and philosophy
- File categorization by phase
- Why this AI-first order is optimal

## Error Handling

All scripts include:
- Input validation
- Error checking with helpful messages
- Exit codes for automation
- Recovery suggestions

## Integration with Claude Code

These bootstrap scripts are designed to work with **Claude Code** at the command line:

```bash
# Use Claude to help with setup
claude "Help me understand what bootstrap-typescript.sh does"

# Use Claude to troubleshoot
claude "Why am I getting ESLint errors after running the linting script?"

# Use Claude to customize
claude "Update my TypeScript config to be stricter"
```

## See Also

- [MENU_STRUCTURE.md](references/MENU_STRUCTURE.md) - Detailed setup strategy

## Project Philosophy

**SparkQ Bootstrap** is optimized for **AI-first development**:
- Claude Code integration comes first
- IDE and tools configured before coding
- Type safety and infrastructure in place
- Testing and CI/CD can be added when needed
- Focus on rapid development with AI assistance

This approach lets developers write code confidently with AI help from the first commit.

---

**Status**: Bootstrap menu operational, 3/14 scripts available
**Current Phase**: Building Phase 1 foundation scripts
**Next Milestone**: All Phase 1 & 2 scripts ready for complete stack setup
