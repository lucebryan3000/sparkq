---
title: Bootstrap Menu Structure & Execution Order
category: Reference
version: 1.0
created: 2025-12-07
purpose: "Documents the 4-phase bootstrap menu structure and AI-first execution order"
audience: Developers, Bootstrap Users
---

# Bootstrap Menu Structure & Execution Order

Reference guide for the 14-script bootstrap menu organized in 4 phases for optimal AI-assisted development workflow.

## Setup Order Overview (14 Scripts Total)

### 🔴 PHASE 1: AI Development Toolkit (FIRST) - 7 Scripts
Set up AI tools and development environment first for optimal workflow.

1. **bootstrap-claude.sh** ✓ *Available*
   - Claude Code configuration (.claude/settings.json)
   - Project instructions for Claude (CLAUDE.md)
   - Files excluded from Claude context (.claudeignore)
   - Optional: Codex configuration (.codex.json)
   - **Why First**: Enables AI-assisted development from the start

2. **bootstrap-git.sh** *(coming soon)*
   - Git configuration (.gitignore, .gitattributes)
   - Version control setup
   - **Rationale**: Version control is foundational

3. **bootstrap-vscode.sh** ✓ *Available*
   - VS Code workspace settings (.vscode/settings.json)
   - Editor extensions (.vscode/extensions.json)
   - Debug configurations (.vscode/launch.json)
   - Task definitions (.vscode/tasks.json)
   - Code snippets (.vscode/snippets/typescript.json)
   - **Why Early**: IDE setup needed for efficient coding

4. **bootstrap-codex.sh** *(coming soon)*
   - Codex CLI integration (if using OpenAI Codex)
   - Configuration and authentication
   - **Why Here**: Complements Claude Code setup

5. **bootstrap-packages.sh** *(coming soon)*
   - Package manager setup (.npmrc)
   - Node version pinning (.nvmrc)
   - Tool versions (.tool-versions)
   - Direnv configuration (.envrc)
   - **Critical**: Dependencies needed before development starts

6. **bootstrap-typescript.sh** *(coming soon)*
   - TypeScript configuration (tsconfig.json)
   - Next.js configuration (next.config.js)
   - Build tool configs (babel.config.js, vite.config.ts, rollup.config.js, webpack.config.js)
   - **Critical**: Type safety and build setup needed immediately

7. **bootstrap-environment.sh** *(coming soon)*
   - Environment variables (.env.example)
   - Local development setup (.env.local)
   - Database defaults and connection strings
   - **Critical**: Development can't start without env vars

**Phase 1 Total: 7 files**

---

### 🔴 PHASE 2: Infrastructure (Core Development) - 3 Scripts
Set up the development infrastructure needed for active coding.

8. **bootstrap-docker.sh** *(coming soon)*
   - Docker Compose configuration (docker-compose.yml)
   - Docker image setup (Dockerfile)
   - Docker ignore patterns (.dockerignore)
   - Services: PostgreSQL, Redis, app container
   - **Critical**: Database and services needed for development

9. **bootstrap-linting.sh** *(coming soon)*
   - ESLint configuration (.eslintrc.json)
   - ESLint ignore patterns (.eslintignore)
   - Code quality rules
   - Prettier integration
   - **Important**: Catch bugs early during development

10. **bootstrap-editor.sh** *(coming soon)*
    - Editor configuration (.editorconfig)
    - Code formatting rules (.prettierrc.json, .stylelintrc)
    - Prettier ignore patterns (.prettierignore)
    - **Nice to Have**: Formatting enforced by linting anyway

**Phase 2 Total: 3 files**

---

### 🟡 PHASE 3: Testing & Quality - 1 Script
Ensure code quality through testing.

11. **bootstrap-testing.sh** *(coming soon)*
    - Jest configuration (jest.config.js)
    - Pytest configuration (pytest.ini)
    - Coverage configuration (.coveragerc)
    - Test environment setup
    - **Important**: Needed for TDD workflows

**Phase 3 Total: 3 files**

---

### 🟢 PHASE 4: CI/CD & Deployment (Optional) - 3 Scripts
Set up automation and deployment pipelines (can be done later).

12. **bootstrap-github.sh** ✓ *Available*
    - GitHub workflows (.github/workflows/ci.yml)
    - Pull request templates (.github/PULL_REQUEST_TEMPLATE.md)
    - Issue templates (.github/ISSUE_TEMPLATE/)
    - **Optional**: Not needed until ready to commit

13. **bootstrap-devcontainer.sh** *(coming soon)*
    - Dev container setup (.devcontainer/devcontainer.json)
    - Dev container image (.devcontainer/Dockerfile)
    - **Optional**: Only needed for remote development

14. **bootstrap-documentation.sh** *(coming soon)*
    - Project README (README.md)
    - Documentation structure (docs/)
    - Contributing guidelines (CONTRIBUTING.md)
    - **Optional**: Can be done manually or later

**Phase 4 Total: 3 files**

---

## Quick Phase Reference

| Phase | Purpose | Timing | Scripts |
|-------|---------|--------|---------|
| **Phase 1** | 🔴 AI Development Toolkit | **DO FIRST** | 7 |
| **Phase 2** | 🔴 Infrastructure (Core Dev) | Before coding | 3 |
| **Phase 3** | 🟡 Testing & Quality | During development | 1 |
| **Phase 4** | 🟢 CI/CD & Deployment | Can be later | 3 |
| **TOTAL** | | | **14 scripts** |

---

## File Categories by Phase

### Phase 1: AI Development (7 files)
| Category | Files | Purpose |
|----------|-------|---------|
| Claude/AI | 4 | AI code assistance configuration |
| Git & VC | 2 | Repository setup |
| IDE | 5 | Editor configuration |
| Package Mgmt | 4 | Runtime version management |
| TypeScript | 6 | Type safety and builds |
| Environment | 2 | Dev environment setup |

**Total: 23 files**

### Phase 2: Infrastructure (3 files)
| Category | Files | Purpose |
|----------|-------|---------|
| Docker | 3 | Containerization and services |
| Linting | 3 | Code quality enforcement |
| Editor | 3 | Code formatting standards |

**Total: 9 files**

### Phase 3: Testing (3 files)
| Category | Files | Purpose |
|----------|-------|---------|
| Testing | 3 | Test configuration and coverage |

**Total: 3 files**

### Phase 4: CI/CD (3 files)
| Category | Files | Purpose |
|----------|-------|---------|
| GitHub | 3 | Workflows and templates |
| DevContainer | 2 | Remote dev environment |
| Documentation | 3 | Project knowledge base |

**Total: 8 files**

---

## Why This Order?

### The AI-First Approach
1. **Claude Code First** - Set up AI assistance immediately so it helps with all subsequent setup
2. **IDE Ready** - Configure VS Code so the development environment is comfortable
3. **Dependencies & Types** - Get packages and TypeScript working before coding
4. **Infrastructure** - Add Docker and databases for complete dev environment
5. **Quality** - Add linting and testing for production-ready code
6. **Automation** - CI/CD is last because code is already working locally

### Why Not Template Order?
- **Template order** prioritizes file organization (Git → Editor → Linting → Packages)
- **AI-first order** prioritizes developer workflow (AI → IDE → Dependencies → Infrastructure)
- **Difference**: We want the developer ready to code ASAP, using AI to accelerate

---

## Usage Guide

### Run the Menu
```bash
cd ___NEW\ PROJ\ TEMPLATES____/scripts
./bootstrap-menu.sh
```

### Menu Display Example
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

### Available Commands
| Input | Action |
|-------|--------|
| `1-14` | Run the corresponding script |
| `q` or `x` | Exit the menu |
| Enter (blank) | Show "No selection" message |
| Any other key | Show error message |

### Confirmations
- **Run script?** - Default is YES (just press Enter)
- **Continue to menu?** - Default is YES (just press Enter)
- Scripts marked as "(coming soon)" cannot be selected

---

## Implementation Progress

### ✅ Currently Available (3 scripts)
```
Phase 1:
✓ bootstrap-claude.sh      - Claude Code integration
✓ bootstrap-vscode.sh      - VS Code setup
Phase 4:
✓ bootstrap-github.sh      - GitHub workflows
```

### 🔴 Priority Implementation (Phase 1 - 5 scripts needed)
```
1. bootstrap-git.sh          - Foundation
2. bootstrap-codex.sh        - AI tooling
3. bootstrap-packages.sh     - Dependencies
4. bootstrap-typescript.sh   - Type safety & builds
5. bootstrap-environment.sh  - Dev config
```

### 🔴 Core Implementation (Phase 2 - 3 scripts needed)
```
6. bootstrap-docker.sh       - PostgreSQL, Redis, services
7. bootstrap-linting.sh      - ESLint, Prettier
8. bootstrap-editor.sh       - EditorConfig, code formatting
```

### 🟡 Secondary Implementation (Phase 3 - 1 script needed)
```
9. bootstrap-testing.sh      - Jest, Pytest, coverage
```

### 🟢 Optional Implementation (Phase 4 - no new scripts needed)
```
Remaining scripts can be done later
```

---

## Notes

- **Color System**:
  - 🔴 **Red** = Critical (Phase 1-2) - Must complete before productive development
  - 🟡 **Yellow** = Important (Phase 3) - Needed for quality code
  - 🟢 **Green** = Optional (Phase 4) - Can be done later

- **Status Indicators**:
  - ✓ = Available now, ready to use
  - (coming soon) = Not yet created, shows in grey text, cannot be selected

- **Total Scripts**: 14 planned (3 available, 11 coming soon)
- **Current Milestone**: Phase 1 & 2 core scripts needed for full stack setup
- **Next Steps**: Implement Phase 1 required scripts, then Phase 2

---

**Last Updated:** December 2025
**Optimization**: AI-First Development Order (SparkQ optimized)
**Status**: Menu structure complete, 3 scripts available, 11 coming soon
