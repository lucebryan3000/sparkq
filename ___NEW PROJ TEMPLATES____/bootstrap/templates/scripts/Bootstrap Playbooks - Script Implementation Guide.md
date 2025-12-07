# Bootstrap Playbooks - Script Implementation Guide

Orchestration guide for Sonnet to bootstrap new projects with velocity and accuracy.

---

## Orchestration Model

**You (Sonnet)** are the orchestrator. Delegate to the right model for each task:

| Model | Use For | Invoke Via |
|-------|---------|------------|
| **Haiku** | Fast file ops, syntax checks, repetitive tasks | `--model haiku` or Task tool |
| **Opus** | Architecture decisions, complex debugging, CLAUDE.md | Task tool with opus |
| **Codex** | Shell commands, package installs, git ops | `codex "command"` in Bash |

### Delegation Rules

1. **Default to Haiku** for script execution and validation
2. **Escalate to Opus** when stuck after 2 attempts or architectural decisions needed
3. **Use Codex** for any bash command that doesn't need conversation context
4. **Handle yourself** template customization and orchestration logic

---

## Phase 1: AI Development Toolkit (FIRST)

Run these scripts first. They enable AI assistance for all subsequent work.

### 1. bootstrap-claude.sh

**Delegate to**: Haiku (file copying)

**Execute**:
```bash
./bootstrap-claude.sh [project-path]
```

**Files created**:
- `.claude/` directory with agents, commands, hooks, skills subdirectories
- `.claude/codex.md`, `.claude/haiku.md`, `.claude/self-testing-protocol.md`
- `.claudeignore`

**Validation** (delegate to Haiku):
```bash
[[ -d ".claude/agents" ]] && [[ -f ".claudeignore" ]]
```

---

### 2. bootstrap-git.sh

**Delegate to**: Haiku (simple file creation)

**Execute**:
```bash
./bootstrap-git.sh [project-path]
```

**Files created**:
- `.gitignore` - Node.js, Python, IDE exclusions
- `.gitattributes` - Line ending normalization

**Validation**:
```bash
git status  # Should not error
```

---

### 3. bootstrap-vscode.sh

**Delegate to**: Haiku (config copying)

**Execute**:
```bash
./bootstrap-vscode.sh [project-path]
```

**Files created**:
- `.vscode/settings.json`, `extensions.json`, `launch.json`, `tasks.json`
- `.vscode/snippets/typescript.json`

---

### 4. bootstrap-codex.sh

**Delegate to**: Haiku (config file)

**IMPORTANT**: Update the model reference - `code-davinci-002` is deprecated.

**Execute**:
```bash
./bootstrap-codex.sh [project-path]
```

**Files created**:
- `.codex.json` - Use `gpt-4o` not deprecated models
- `.codexignore`

**Post-run**: Verify OPENAI_API_KEY is set:
```bash
codex "echo 'Codex CLI working'"
```

---

### 5. bootstrap-packages.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-packages.sh [project-path]
```

**Files created**:
- `.npmrc`, `.nvmrc`, `.tool-versions`, `.envrc`
- `package.json` (if missing)

**Validation**:
```bash
node -v  # Should match .nvmrc
```

---

### 6. bootstrap-typescript.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-typescript.sh [project-path]
```

**Files created**:
- `tsconfig.json` (strict mode)
- `next.config.js`, `babel.config.js`, `vite.config.ts`
- `src/` directory structure

---

### 7. bootstrap-environment.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-environment.sh [project-path]
```

**Files created**:
- `.env.example`, `.env.local`, `.env.production`
- `env.d.ts` (TypeScript types)

---

## Phase 2: Infrastructure

### 8. bootstrap-docker.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-docker.sh [project-path]
```

**Files created**:
- `docker-compose.yml` (PostgreSQL, Redis, app)
- `Dockerfile` (multi-stage)
- `.dockerignore`

**Validation**:
```bash
docker compose config  # Should parse without error
```

---

### 9. bootstrap-linting.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-linting.sh [project-path]
```

**Files created**:
- `.eslintrc.json`, `.eslintignore`
- `.prettierrc.json`, `.prettierignore`

**Validation**:
```bash
npx eslint --print-config .eslintrc.json > /dev/null
```

---

### 10. bootstrap-editor.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-editor.sh [project-path]
```

**Files created**:
- `.editorconfig` (14 sections)
- `.stylelintrc` (Tailwind-aware)

---

## Phase 3: Testing & Quality

### 11. bootstrap-testing.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-testing.sh [project-path]
```

**Files created**:
- `jest.config.js` (70% coverage thresholds)
- `pytest.ini` (Python testing)
- `.coveragerc`

---

## Phase 4: CI/CD & Deployment

### 12. bootstrap-github.sh

**Delegate to**: Haiku

**Execute**:
```bash
./bootstrap-github.sh [project-path]
```

**Files created**:
- `.github/workflows/ci.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/` (bug, feature, docs)

---

### 13. bootstrap-devcontainer.sh

**Status**: Not implemented

**When implementing** (delegate to Sonnet):
- Create `.devcontainer/devcontainer.json`
- Create `.devcontainer/Dockerfile`

---

### 14. bootstrap-documentation.sh

**Status**: Not implemented

**When implementing** (delegate to Sonnet):
- Create `README.md` scaffold
- Create `docs/` structure
- Create `CONTRIBUTING.md`

---

## NEW: Scripts to Implement

### 15. bootstrap-claudemd.sh (CRITICAL)

**Implement yourself (Sonnet)** - requires project context understanding

**Purpose**: Generate customized CLAUDE.md for the project

**Implementation steps**:
1. Detect project characteristics (stack, structure)
2. Prompt for: project name, phase (poc/mvp/production)
3. Generate CLAUDE.md with:
   - Critical rules (self-test protocol, no permission prompts)
   - Code style matching detected linters
   - File organization from actual `src/` structure
   - Git conventions

**Template variables**:
```bash
PROJECT_NAME=""
STACK=""        # nextjs, vite, api, python
PHASE=""        # poc, mvp, production
OWNER=""
```

**Escalate to Opus if**: Complex multi-stack project or unusual requirements

---

### 16. bootstrap-validate.sh

**Delegate to**: Haiku (validation logic is straightforward)

**Purpose**: Verify bootstrap completed correctly

**Checks to implement**:
```bash
# Structure checks
[[ -d ".claude" ]] || fail ".claude directory missing"
[[ -f "tsconfig.json" ]] || fail "TypeScript not configured"
[[ -f ".eslintrc.json" ]] || fail "ESLint not configured"

# Syntax checks (delegate each to Codex)
codex "npx tsc --noEmit"
codex "npx eslint --print-config .eslintrc.json"
codex "node -e \"JSON.parse(require('fs').readFileSync('.prettierrc.json'))\""

# Version checks
[[ "$(node -v)" == "v$(cat .nvmrc)" ]] || warn "Node version mismatch"
```

**Output format**:
```
Bootstrap Validation: [project-name]
✓ Claude Code configuration
✓ Git repository
✓ TypeScript config
✗ ESLint: [error message]
Result: 6/7 passed
```

---

### 17. bootstrap-deps.sh

**Delegate to**: Codex (package installation)

**Purpose**: Install dependencies after config files created

**Execute via Codex**:
```bash
codex "Install dev dependencies: typescript @types/node eslint prettier vitest"
```

**Profile-based packages**:

| Profile | Packages |
|---------|----------|
| minimal | typescript |
| standard | typescript, eslint, prettier, @types/node |
| full | standard + vitest, @testing-library/react, husky, lint-staged |

---

### 18. bootstrap-recipe.sh

**Delegate to**: Haiku (script execution orchestration)

**Purpose**: Run predefined script combinations

**Recipes**:
```bash
# Next.js SaaS
./bootstrap-recipe.sh nextjs-saas
# Runs: claude, git, vscode, packages, typescript, environment, docker, linting, testing

# Vite Library
./bootstrap-recipe.sh vite-lib
# Runs: claude, git, vscode, packages, typescript, linting, testing

# Python API
./bootstrap-recipe.sh python-api
# Runs: claude, git, vscode, environment, testing, docker

# Minimal CLI
./bootstrap-recipe.sh cli-tool
# Runs: claude, git, packages, typescript
```

**Implementation**: Loop through script array, execute each, validate after

---

## Execution Patterns

### Sequential (Default)
```bash
./bootstrap-menu.sh
```

### Parallel Phase 1
Independent scripts can run simultaneously. Delegate to Codex:
```bash
codex "Run in parallel: bootstrap-git.sh bootstrap-vscode.sh bootstrap-codex.sh"
```

Then run dependent scripts:
```bash
./bootstrap-packages.sh && ./bootstrap-typescript.sh && ./bootstrap-environment.sh
```

### Quick Bootstrap (All Phase 1)
```bash
./bootstrap-claude.sh . && \
./bootstrap-git.sh . && \
./bootstrap-vscode.sh . && \
./bootstrap-codex.sh . && \
./bootstrap-packages.sh . && \
./bootstrap-typescript.sh . && \
./bootstrap-environment.sh .
```

Delegate entire chain to Codex:
```bash
codex "Run all Phase 1 bootstrap scripts in order for current directory"
```

### Dry-Run Mode
**Delegate to**: Haiku

Add `--dry-run` flag to each script:
```bash
./bootstrap-git.sh --dry-run
# Output: Would create .gitignore (87 lines), .gitattributes (23 lines)
```

---

## Error Handling

### When Script Fails

1. **First failure**: Retry once (delegate to Haiku)
2. **Second failure**: Check logs, fix obvious issues (delegate to Sonnet)
3. **Third failure**: Escalate to Opus for root cause analysis

### Common Fixes

| Error | Fix | Delegate to |
|-------|-----|-------------|
| Permission denied | `chmod +x bootstrap-*.sh` | Codex |
| Template not found | Check TEMPLATE_DIR path | Haiku |
| JSON parse error | Validate JSON syntax | Haiku |
| Node not found | `nvm use` or install Node | Codex |

---

## Post-Bootstrap Checklist

After all scripts complete, verify (delegate to Haiku):

```bash
# Run validation
./bootstrap-validate.sh .

# If validation passes, install deps
codex "pnpm install"

# Make initial commit
codex "git add . && git commit -m 'chore: bootstrap project setup'"

# Open in editor
code .
```

---

## Model Delegation Quick Reference

```
HAIKU (fast, cheap):
  - All script execution
  - File validation
  - Syntax checking
  - Dry-run logic
  - Simple error recovery

SONNET (you - orchestrator):
  - Template customization
  - CLAUDE.md generation
  - Script implementation
  - Complex error recovery
  - Decision making

OPUS (powerful, expensive):
  - Architecture decisions
  - Complex debugging (3+ failures)
  - Unusual project requirements
  - Security reviews

CODEX (task runner):
  - Package installation: codex "pnpm add -D typescript"
  - Git operations: codex "git add . && git commit -m 'msg'"
  - Running tests: codex "npm test"
  - Shell commands: codex "mkdir -p src/{components,hooks,lib}"
  - Parallel execution: codex "run scripts in parallel"
```

---

## Configuration Customization

After bootstrap, customize as needed:

### .env.local
```bash
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
API_KEY=your_key
```

### package.json scripts
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "test": "vitest",
    "lint": "eslint . --fix"
  }
}
```

---

## Troubleshooting

### Script won't run
```bash
chmod +x bootstrap-*.sh
bash bootstrap-git.sh  # Run with bash explicitly
```

### Git init fails
```bash
git config user.name "Name"
git config user.email "email@example.com"
```

### TypeScript errors
```bash
codex "Install TypeScript and run tsc --noEmit"
```

### Environment not loading
```bash
direnv allow
# or
source .env.local
```

---

**Version**: 2.0 - Orchestration Edition
**Last Updated**: December 2025
