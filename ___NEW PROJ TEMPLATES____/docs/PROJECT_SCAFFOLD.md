# Project Scaffold Template

> **Purpose**: Standard folder structure for all Bryan's projects  
> **Use**: Copy this structure when starting a new project  
> **Stack**: Next.js + TypeScript + PostgreSQL + Docker

---

## Quick Setup

```bash
# Create new project
mkdir -p ~/apps/[project-name]
cd ~/apps/[project-name]

# Initialize
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir

# Create folder structure
mkdir -p .claude/{commands,agents,skills}
mkdir -p .codex
mkdir -p .vscode
mkdir -p _build/{docs_build/{PRD,FRD,architecture,decisions,diagrams/exports,references,reviews},prompts/{foundation/_completed,api/_completed,ui/_completed,polish/_completed},chats,playbooks,context,summaries,backups/{snapshots,archive}}
mkdir -p docs
mkdir -p scripts/claude
mkdir -p src/components/{ui,layout,shared}
mkdir -p src/hooks
mkdir -p src/lib/utils
mkdir -p src/services
mkdir -p src/types
mkdir -p testing/{framework,e2e/flows,custom,fixtures/{mock-api-responses,sample-records,component-props},screenshots}

# Create gitkeeps for empty folders
find _build -type d -empty -exec touch {}/.gitkeep \;
touch testing/custom/.gitkeep
touch testing/screenshots/.gitkeep
touch scripts/claude/.gitkeep
touch .claude/skills/.gitkeep

# Create tech-debt.md
echo "# Tech Debt Log\n\n| Date | Item | Priority | Notes |\n|------|------|----------|-------|" > _build/tech-debt.md

# Initialize Prisma
npx prisma init

# Create CLAUDE.md files
touch CLAUDE.md
touch src/CLAUDE.md
touch prisma/CLAUDE.md
touch testing/CLAUDE.md
touch scripts/CLAUDE.md

# Create .claude/settings.json
cat > .claude/settings.json << 'EOF'
{
  "cleanupPeriodDays": 30,
  "model": "sonnet",
  
  "permissions": {
    "defaultMode": "bypassPermissions",
    "additionalDirectories": [
      "./.venv",
      "./venv",
      "./.pythonenv",
      "./.conda",
      "./.pyenv",
      "./__pycache__",
      "./.mypy_cache",
      "./.pytest_cache",
      "./.ruff_cache",
      "./.npm",
      "./.yarn",
      "./.pnpm-store",
      "./target",
      "./.cargo",
      "./vendor",
      "./.terraform",
      "./.terragrunt-cache",
      "./postgres_data",
      "./mysql_data",
      "./redis_data",
      "./legacy",
      "./deprecated",
      "./secrets",
      "./.secrets"
    ]
  },

  "env": {
    "BASH_DEFAULT_TIMEOUT_MS": "120000",
    "BASH_MAX_TIMEOUT_MS": "600000",
    "BASH_MAX_OUTPUT_LENGTH": "150000",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "128000",
    "CLAUDE_MAX_READ_FILES": "1000",
    "CLAUDE_MAX_FILE_SIZE_BYTES": "2097152",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "DISABLE_AUTOUPDATER": "0",
    "DISABLE_COST_WARNINGS": "0",
    "SKIP_TESTS": "0",
    "COMMIT_BATCH_SECONDS": "600",
    "TARGET_BRANCH": "main",
    "TZ": "America/Chicago",
    "LANG": "en_US.UTF-8",
    "LC_ALL": "en_US.UTF-8",
    "NODE_ENV": "development",
    "NODE_OPTIONS": "--max-old-space-size=8192",
    "NODE_NO_WARNINGS": "1",
    "FORCE_COLOR": "1",
    "TERM": "xterm-256color",
    "COLORTERM": "truecolor",
    "NON_INTERACTIVE": "false",
    "CI": "false",
    "PROJECT_ROOT": "/home/luce/apps",
    "BACKUP_DIR": "/home/luce/backups",
    "DOCKER_BUILDKIT": "1",
    "COMPOSE_DOCKER_CLI_BUILD": "1",
    "GIT_AUTHOR_NAME": "Bryan Luce",
    "GIT_AUTHOR_EMAIL": "bryan@appmelia.com",
    "GIT_COMMITTER_NAME": "Bryan Luce",
    "GIT_COMMITTER_EMAIL": "bryan@appmelia.com",
    "PRISMA_HIDE_UPDATE_MESSAGE": "true",
    "NPM_CONFIG_FUND": "false",
    "NPM_CONFIG_AUDIT": "false",
    "NPM_CONFIG_UPDATE_NOTIFIER": "false",
    "DISABLE_OPENCOLLECTIVE": "true",
    "ADBLOCK": "true",
    "JEST_WORKER_ID": "1",
    "PLAYWRIGHT_BROWSERS_PATH": "0",
    "LOG_LEVEL": "info",
    "DEBUG": "",
    "EDITOR": "micro",
    "VISUAL": "micro"
  },

  "includeCoAuthoredBy": true,
  "spinnerTipsEnabled": true,
  "alwaysThinkingEnabled": true,
  
  "statusLine": {
    "type": "command",
    "command": "printf \"\\033[01;32m$(whoami)@$(hostname -s)\\033[00m:\\033[01;34m$(basename $(pwd))\\033[00m\""
  },

  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write(*.ts)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.tsx)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.js)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.jsx)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(prisma/schema.prisma)",
        "hooks": [{ "type": "command", "command": "npx prisma format 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.sh)",
        "hooks": [{ "type": "command", "command": "bash -n \"$CLAUDE_FILE_PATH\" || echo '[HOOK:SYNTAX] $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(*.json)",
        "hooks": [{ "type": "command", "command": "python3 -m json.tool \"$CLAUDE_FILE_PATH\" >/dev/null 2>&1 || echo '[HOOK:JSON] Invalid: $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(*.yaml)",
        "hooks": [{ "type": "command", "command": "python3 -c \"import yaml; yaml.safe_load(open('$CLAUDE_FILE_PATH'))\" 2>/dev/null || echo '[HOOK:YAML] Invalid: $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(*.yml)",
        "hooks": [{ "type": "command", "command": "python3 -c \"import yaml; yaml.safe_load(open('$CLAUDE_FILE_PATH'))\" 2>/dev/null || echo '[HOOK:YAML] Invalid: $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(docker-compose.yml)",
        "hooks": [{ "type": "command", "command": "docker compose config -q 2>/dev/null || echo '[HOOK:DOCKER] Invalid compose'" }]
      }
    ]
  }
}
EOF
```

---

## Full Structure

```
[project-name]/
│
├── .claude/                         # Claude Code configuration
│   ├── settings.json                # Project settings (in git)
│   ├── settings.local.json          # Personal overrides (NOT in git)
│   ├── commands/                    # Slash commands (IN context)
│   │   ├── build.md
│   │   ├── test.md
│   │   ├── commit.md
│   │   ├── docs-cleanup.md
│   │   ├── phase-summarize.md
│   │   ├── context-load.md
│   │   ├── codex-send.md
│   │   └── review.md
│   ├── agents/                      # Subagents (EXCLUDED, loaded on demand)
│   │   ├── code-reviewer.md
│   │   ├── test-writer.md
│   │   ├── remediator.md
│   │   ├── codex-handoff.md
│   │   └── documenter.md
│   └── skills/                      # Agent Skills (EXCLUDED, loaded on demand)
│       └── self-test/
│           └── SKILL.md
│
├── .codex/                          # OpenAI Codex configuration
│   └── config.yaml
│
├── .vscode/                         # VS Code configuration
│   ├── settings.json
│   ├── extensions.json
│   └── launch.json
│
├── .github/                         # GitHub (future CI/CD)
│   └── workflows/
│       └── .gitkeep
│
├── _build/                          # YOUR workspace (EXCLUDED - read on demand)
│   │
│   ├── docs_build/                  # ALL build-related documentation
│   │   ├── PRD/
│   │   ├── FRD/
│   │   ├── architecture/
│   │   ├── decisions/
│   │   ├── diagrams/
│   │   │   └── exports/
│   │   ├── references/
│   │   ├── reviews/
│   │   └── backlog.md
│   │
│   ├── prompts/                     # Opus-created phase prompts
│   │   ├── foundation/
│   │   │   └── _completed/
│   │   ├── api/
│   │   │   └── _completed/
│   │   ├── ui/
│   │   │   └── _completed/
│   │   └── polish/
│   │       └── _completed/
│   │
│   ├── chats/                       # AI communication (prefixed, ephemeral)
│   │   └── .gitkeep                 # claude-*, codex-*, gemini-*, copilot-*
│   │
│   ├── playbooks/                   # Automation playbooks (pre-filled)
│   │   ├── docs-cleanup.md
│   │   ├── phase-summarize.md
│   │   ├── context-audit.md
│   │   ├── test-audit.md
│   │   └── prompt-archive.md
│   │
│   ├── context/                     # Pre-built loadable context (pre-filled)
│   │   ├── api-patterns.md
│   │   ├── ui-patterns.md
│   │   ├── db-patterns.md
│   │   └── testing-patterns.md
│   │
│   ├── summaries/                   # Phase completion summaries
│   │   └── .gitkeep
│   │
│   ├── backups/
│   │   ├── snapshots/               # Point-in-time state captures
│   │   │   └── .gitkeep
│   │   └── archive/                 # Tarballed old content
│   │       └── .gitkeep
│   │
│   └── tech-debt.md
│
├── docs/                            # App documentation (EXCLUDED)
│   ├── API.md
│   └── ARCHITECTURE.md
│
├── prisma/                          # Database
│   ├── schema.prisma
│   ├── migrations/
│   ├── seed.ts
│   └── CLAUDE.md
│
├── public/                          # Static assets
│   ├── favicon.ico
│   └── images/
│
├── scripts/                         # Utility scripts
│   ├── backup.sh
│   ├── restore.sh
│   ├── clean.sh
│   ├── setup.sh
│   ├── secrets-edit.sh
│   ├── claude/                      # Claude-specific scripts (IN context)
│   │   └── .gitkeep
│   └── CLAUDE.md
│
├── src/                             # Source code
│   ├── app/                         # Next.js App Router
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── globals.css
│   │   ├── (dashboard)/
│   │   │   └── dashboard/
│   │   │       └── page.tsx
│   │   ├── (settings)/
│   │   │   └── settings/
│   │   │       └── page.tsx
│   │   └── api/
│   │       └── health/
│   │           └── route.ts
│   │
│   ├── components/
│   │   ├── ui/                      # shadcn/ui components
│   │   ├── layout/                  # Header, Sidebar, Footer
│   │   ├── shared/                  # LoadingSpinner, ErrorBoundary
│   │   └── [feature]/               # Feature-specific
│   │
│   ├── hooks/
│   │   └── useConfig.ts
│   │
│   ├── lib/
│   │   ├── db.ts
│   │   ├── config.ts
│   │   ├── paths.ts
│   │   ├── secrets.ts
│   │   └── utils/
│   │       ├── dates.ts
│   │       └── validation.ts
│   │
│   ├── services/
│   │   └── [resource]-service.ts
│   │
│   ├── types/
│   │   └── index.ts
│   │
│   ├── styles/
│   │
│   └── CLAUDE.md
│
├── testing/                         # Test framework
│   ├── framework/
│   │   ├── auto-discover.ts
│   │   ├── page-tests.ts
│   │   ├── api-tests.ts
│   │   ├── component-tests.ts
│   │   └── db-tests.ts
│   ├── e2e/
│   │   └── flows/
│   ├── fixtures/                    # Auto-evolving test data (used by test suite)
│   │   ├── mock-api-responses/      # Mock API data
│   │   ├── sample-records/          # Sample DB records
│   │   └── component-props/         # Test props for components
│   ├── custom/
│   ├── screenshots/
│   ├── jest.config.ts
│   ├── playwright.config.ts
│   ├── puppeteer.config.ts
│   ├── setup.ts
│   ├── config.ts
│   └── CLAUDE.md
│
├── .claudeignore
├── .gitignore
├── .env
├── .env.example
├── .secrets.yaml
├── .sops.yaml
├── .eslintrc.js
├── .prettierrc
├── CLAUDE.md
├── docker-compose.yml
├── Dockerfile
├── next.config.js
├── package.json
├── tailwind.config.js
├── tsconfig.json
└── README.md
```

---

## Template Files

### .env.example

```bash
# ===================
# DATABASE
# ===================
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/[project]

# ===================
# APPLICATION
# ===================
PORT=3000
NODE_ENV=development

# ===================
# SECRETS (see .secrets.yaml for encrypted values)
# ===================
# API keys loaded from SOPS-encrypted .secrets.yaml

# ===================
# OPTIONAL
# ===================
# DEBUG_ENABLED=true
```

### .secrets.yaml (before encryption)

```yaml
# Encrypted by SOPS (keys ending in _api_key, _secret, _token, _password)
openai_api_key: sk-your-key
claude_api_key: sk-ant-your-key
session_secret: generate-random-string

# Not encrypted (plain text)
default_model: gpt-4
poll_interval: 60
```

### .sops.yaml

```yaml
creation_rules:
  - path_regex: \.secrets\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    encrypted_regex: '^(.*_api_key|.*_secret|.*_token|.*_password)$'
```

### .claudeignore

```
# Dependencies
node_modules/
pnpm-store/
pnpm-lock.yaml
yarn.lock
package-lock.json

# Build outputs
.next/
dist/
build/
out/
*.tsbuildinfo
.turbo/
.vercel/
.netlify/

# _build/ workspace (read on demand, not auto-loaded)
_build/

# Agents & Skills (loaded via slash commands)
.claude/agents/
.claude/skills/

# Database artifacts
postgres_data/
drizzle/
*.sql

# Test artifacts
coverage/
test-results/
playwright-report/
__snapshots__/

# Logs
logs/
*.log

# Archives & generated files
*.tar.gz
*.zip
*.pdf
*.csv
*.xlsx

# References (read on demand)
docs/

# IDE/OS
.vscode/
.idea/
.DS_Store
Thumbs.db

# Git internals
.git/

# Cache
.eslintcache
.sass-cache/
```

### .claude/settings.json Reference

```json
{
  "cleanupPeriodDays": 30,
  "model": "sonnet",
  
  "permissions": {
    "defaultMode": "bypassPermissions",
    "additionalDirectories": [
      "./.venv",
      "./venv",
      "./.pythonenv",
      "./.conda",
      "./.pyenv",
      "./__pycache__",
      "./.mypy_cache",
      "./.pytest_cache",
      "./.ruff_cache",
      "./.npm",
      "./.yarn",
      "./.pnpm-store",
      "./target",
      "./.cargo",
      "./vendor",
      "./.terraform",
      "./.terragrunt-cache",
      "./postgres_data",
      "./mysql_data",
      "./redis_data",
      "./legacy",
      "./deprecated",
      "./secrets",
      "./.secrets"
    ]
  },

  "env": {
    "BASH_DEFAULT_TIMEOUT_MS": "120000",
    "BASH_MAX_TIMEOUT_MS": "600000",
    "BASH_MAX_OUTPUT_LENGTH": "150000",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "128000",
    "CLAUDE_MAX_READ_FILES": "1000",
    "CLAUDE_MAX_FILE_SIZE_BYTES": "2097152",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "DISABLE_AUTOUPDATER": "0",
    "DISABLE_COST_WARNINGS": "0",
    "SKIP_TESTS": "0",
    "COMMIT_BATCH_SECONDS": "600",
    "TARGET_BRANCH": "main",
    "TZ": "America/Chicago",
    "LANG": "en_US.UTF-8",
    "LC_ALL": "en_US.UTF-8",
    "NODE_ENV": "development",
    "NODE_OPTIONS": "--max-old-space-size=8192",
    "NODE_NO_WARNINGS": "1",
    "FORCE_COLOR": "1",
    "TERM": "xterm-256color",
    "COLORTERM": "truecolor",
    "NON_INTERACTIVE": "false",
    "CI": "false",
    "PROJECT_ROOT": "/home/luce/apps",
    "BACKUP_DIR": "/home/luce/backups",
    "DOCKER_BUILDKIT": "1",
    "COMPOSE_DOCKER_CLI_BUILD": "1",
    "GIT_AUTHOR_NAME": "Bryan Luce",
    "GIT_AUTHOR_EMAIL": "bryan@appmelia.com",
    "GIT_COMMITTER_NAME": "Bryan Luce",
    "GIT_COMMITTER_EMAIL": "bryan@appmelia.com",
    "PRISMA_HIDE_UPDATE_MESSAGE": "true",
    "NPM_CONFIG_FUND": "false",
    "NPM_CONFIG_AUDIT": "false",
    "NPM_CONFIG_UPDATE_NOTIFIER": "false",
    "DISABLE_OPENCOLLECTIVE": "true",
    "ADBLOCK": "true",
    "JEST_WORKER_ID": "1",
    "PLAYWRIGHT_BROWSERS_PATH": "0",
    "LOG_LEVEL": "info",
    "DEBUG": "",
    "EDITOR": "micro",
    "VISUAL": "micro"
  },

  "includeCoAuthoredBy": true,
  "spinnerTipsEnabled": true,
  "alwaysThinkingEnabled": true,
  
  "statusLine": {
    "type": "command",
    "command": "printf \"\\033[01;32m$(whoami)@$(hostname -s)\\033[00m:\\033[01;34m$(basename $(pwd))\\033[00m\""
  },

  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write(*.ts)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.tsx)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.js)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.jsx)",
        "hooks": [{ "type": "command", "command": "npx eslint --fix \"$CLAUDE_FILE_PATH\" 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(prisma/schema.prisma)",
        "hooks": [{ "type": "command", "command": "npx prisma format 2>/dev/null || true" }]
      },
      {
        "matcher": "Write(*.sh)",
        "hooks": [{ "type": "command", "command": "bash -n \"$CLAUDE_FILE_PATH\" || echo '[HOOK:SYNTAX] $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(*.json)",
        "hooks": [{ "type": "command", "command": "python3 -m json.tool \"$CLAUDE_FILE_PATH\" >/dev/null 2>&1 || echo '[HOOK:JSON] Invalid: $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(*.yaml)",
        "hooks": [{ "type": "command", "command": "python3 -c \"import yaml; yaml.safe_load(open('$CLAUDE_FILE_PATH'))\" 2>/dev/null || echo '[HOOK:YAML] Invalid: $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(*.yml)",
        "hooks": [{ "type": "command", "command": "python3 -c \"import yaml; yaml.safe_load(open('$CLAUDE_FILE_PATH'))\" 2>/dev/null || echo '[HOOK:YAML] Invalid: $CLAUDE_FILE_PATH'" }]
      },
      {
        "matcher": "Write(docker-compose.yml)",
        "hooks": [{ "type": "command", "command": "docker compose config -q 2>/dev/null || echo '[HOOK:DOCKER] Invalid compose'" }]
      }
    ]
  }
}
```

#### Two-Tier Context System

| Mechanism | What it does | Claude can still... |
|-----------|--------------|---------------------|
| `.claudeignore` | Excludes from auto-loaded context | Search, read, cat, grep |
| `additionalDirectories` | **Hard blocks** ALL access | Nothing - completely invisible |

#### Settings Philosophy

| Setting | Value | Rationale |
|---------|-------|-----------|
| `defaultMode` | `bypassPermissions` | No prompts, full velocity (dev/POC) |
| `cleanupPeriodDays` | 30 | More history to reference |
| `BASH_MAX_TIMEOUT_MS` | 600000 (10 min) | Long operations without timeout |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 128000 | Max capacity (ceiling, not floor) |
| `CLAUDE_MAX_READ_FILES` | 1000 | Small projects, prevent overload |
| `SKIP_TESTS` | 0 | Tests enabled (self-test rule) |
| `COMMIT_BATCH_SECONDS` | 600 (10 min) | Reasonable commit batching |
| `includeCoAuthoredBy` | true | Credit in git commits |
| `alwaysThinkingEnabled` | true | Better reasoning |

#### Hooks (PostToolUse Only)

| Matcher | Action | Behavior |
|---------|--------|----------|
| `*.ts`, `*.tsx`, `*.js`, `*.jsx` | eslint --fix | Auto-fix, silent on failure |
| `prisma/schema.prisma` | prisma format | Auto-format schema |
| `*.sh` | bash -n | Syntax check, report errors |
| `*.json` | json.tool | Validate JSON, report errors |
| `*.yaml`, `*.yml` | yaml.safe_load | Validate YAML, report errors |
| `docker-compose.yml` | compose config | Validate compose file |

**Hook Pattern:** `command 2>/dev/null || true` ensures silent success, only reports errors.

### .gitignore

```gitignore
# Dependencies
node_modules/

# Build outputs
.next/
dist/
build/

# Environment (local only)
.env.local

# Database
*.db
*.db-journal

# Logs
*.log

# Archives
*.tar.gz

# OS
.DS_Store
Thumbs.db

# IDE (optional - uncomment to exclude)
# .vscode/
# .idea/
```

### docker-compose.yml

```yaml
services:
  db:
    image: postgres:16
    container_name: [project]-db
    restart: unless-stopped
    ports:
      - "${DB_PORT:-5432}:5432"
    environment:
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
      POSTGRES_DB: ${DB_NAME:-[project]}
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

  app:
    build: .
    container_name: [project]-app
    restart: unless-stopped
    ports:
      - "${PORT:-3000}:3000"
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://${DB_USER:-postgres}:${DB_PASSWORD:-postgres}@db:5432/${DB_NAME:-[project]}
      NODE_ENV: ${NODE_ENV:-development}
    volumes:
      - .:/app
      - /app/node_modules
      - /app/.next

volumes:
  db_data:
```

### Dockerfile

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Dependencies
COPY package*.json ./
RUN npm ci

# Source
COPY . .

# Build
RUN npm run build

# Run
EXPOSE 3000
CMD ["npm", "start"]
```

### package.json scripts

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest && playwright test",
    "test:unit": "jest",
    "test:e2e": "playwright test",
    "test:audit": "node testing/framework/audit.js",
    "docker:up": "docker compose up -d",
    "docker:down": "docker compose down",
    "docker:logs": "docker compose logs -f",
    "docker:clean": "docker compose down -v && docker system prune -f",
    "db:shell": "docker compose exec db psql -U postgres",
    "db:migrate": "npx prisma migrate dev",
    "db:seed": "npx prisma db seed",
    "db:export": "./scripts/backup.sh",
    "secrets:edit": "./scripts/secrets-edit.sh"
  }
}
```

### tsconfig.json paths

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

---

## Root CLAUDE.md Template

```markdown
# CLAUDE.md - [Project Name]

## Project Overview
[One sentence description]

## Tech Stack
- Next.js 14+ (App Router)
- TypeScript (strict mode)
- PostgreSQL 16 (via Docker)
- Prisma ORM
- Tailwind CSS + shadcn/ui
- Jest + Playwright + Puppeteer

## Critical Rules
1. NO markdown summary files
2. NO fake data or placeholders
3. NO hardcoded paths or values
4. Files go in proper folders, not root
5. **SELF-TEST before asking for UAT** (run tests, confirm passing, remediate failures)
6. Use Codex for remediation help if needed

## File Placement

| File Type | Location |
|-----------|----------|
| Pages | `src/app/[route]/page.tsx` |
| API routes | `src/app/api/[route]/route.ts` |
| Components | `src/components/[domain]/` |
| Hooks | `src/hooks/` |
| Services | `src/services/` |
| Types | `src/types/` |
| Utils | `src/lib/utils/` |
| Scripts | `scripts/` |
| Prompts | `_build/prompts/[phase]/` |

## Prompt Workflow
After completing a prompt:
1. Run tests (Jest, Playwright, Puppeteer)
2. If fail → remediate immediately
3. Re-run until passing
4. Move prompt to `_completed/` folder
5. ONLY THEN ask for UAT if needed

## Commands

```bash
npm run dev          # Start dev server
npm run test         # Run test suite
npm run docker:up    # Start containers
npm run docker:clean # Full reset
npm run db:shell     # PostgreSQL CLI
```

## See Also
- `src/CLAUDE.md` - Code patterns
- `prisma/CLAUDE.md` - Database conventions
- `testing/CLAUDE.md` - Test framework
- `_build/PRD/` - Requirements
```

---

## testing/CLAUDE.md Template

```markdown
# CLAUDE.md - Testing

## HARD RULE: Self-Test Before UAT

Before asking Bryan for UAT, Claude MUST:
1. Run automated tests (Jest, Playwright, Puppeteer)
2. Confirm tests pass
3. If fail → remediate immediately (use Codex if needed)
4. Re-run until passing
5. ONLY THEN → ask for UAT

**UAT is for:** Human experience, UX feel, edge cases  
**UAT is NOT for:** Finding bugs tests should catch

## When Tests Run
- After each prompt → Claude self-tests
- End of queue → Full suite
- Before merge → Must pass
- Before UAT → Must pass first

## Framework Auto-Discovers
- Pages in `src/app/**/page.tsx`
- API routes in `src/app/api/**/route.ts`
- Components in `src/components/**/*.tsx`

## testing/fixtures/ Purpose
Auto-evolving test data used by automated test suite:
- `mock-api-responses/` - Mock API data
- `sample-records/` - Sample DB records  
- `component-props/` - Test props for components

These are used by Jest/Playwright/Puppeteer automatically.  
NOT for manual testing. Claude maintains these.

## Adding Custom Tests
Place in `testing/custom/[name].test.ts`

## Timeouts (Generous)
- Unit: 30s
- E2E: 5 minutes
- Suite: 15 minutes

Don't fail working processes with strict timeouts.

## Remediation Workflow
```
Test fails
    ↓
Read error output (last 50 lines)
    ↓
Fix the issue
    ↓
Re-run test
    ↓
Still failing? → Create prompt for Codex help
    ↓
Codex fixes → Re-run
    ↓
Pass? → Continue to next task
```
```

---

## scripts/backup.sh

```bash
#!/bin/bash
set -e

PROJECT_NAME="${PWD##*/}"
BACKUP_DIR="$HOME/backups/$PROJECT_NAME"
DATE=$(date +%m-%d-%Y)

mkdir -p "$BACKUP_DIR"

echo "Backing up $PROJECT_NAME..."

# DB export
docker compose exec -T db pg_dump -U postgres "$PROJECT_NAME" > "$BACKUP_DIR/backup-$DATE.sql"
echo "✓ Database exported"

# Env snapshot
cp .env "$BACKUP_DIR/backup-$DATE.env"
echo "✓ Environment saved"

# Decrypted secrets (plain backup)
if [ -f ".secrets.yaml" ]; then
  sops -d .secrets.yaml > "$BACKUP_DIR/backup-$DATE.secrets"
  echo "✓ Secrets exported (plain)"
fi

echo ""
echo "Backup complete: $BACKUP_DIR/backup-$DATE.*"
```

---

## scripts/setup.sh

```bash
#!/bin/bash
set -e

echo "Setting up project..."

# Install dependencies
npm install

# Setup Prisma
npx prisma generate

# Start Docker
docker compose up -d

# Wait for DB
echo "Waiting for database..."
sleep 5

# Run migrations
npx prisma migrate dev

# Seed database
npx prisma db seed

echo ""
echo "✓ Setup complete!"
echo "Run 'npm run dev' to start development server"
```

---

## scripts/clean.sh

```bash
#!/bin/bash
set -e

echo "Cleaning project..."

# Stop containers, remove volumes
docker compose down -v

# Prune Docker
docker system prune -f

# Remove build artifacts
rm -rf .next dist build

# Remove node_modules (optional)
# rm -rf node_modules

echo ""
echo "✓ Clean complete!"
echo "Run './scripts/setup.sh' to rebuild"
```

---

## Playbook Templates

### _build/playbooks/docs-cleanup.md

```markdown
# Docs Cleanup Playbook

## Purpose
Find loose documentation files and organize them properly.

## Steps

### 1. Find Loose Docs
Scan for .md files in wrong locations:
- Root directory (except CLAUDE.md, README.md)
- src/ directory (except CLAUDE.md)
- Any *.md in unexpected places

### 2. Categorize Found Docs
| Type | Destination |
|------|-------------|
| PRD, requirements | `_build/docs_build/PRD/` |
| Architecture, decisions | `_build/docs_build/architecture/` |
| API documentation | `docs/` |
| Phase prompts | `_build/prompts/[phase]/` |
| Ephemeral AI files | `_build/chats/` (prefix: claude-*, codex-*) or DELETE |
| Summary files (IMPLEMENTATION_*.md) | DELETE |

### 3. Report Actions
Output:
- Files moved (from → to)
- Files deleted
- Files that need manual review

## Execution
Run via: `/docs-cleanup`
```

### _build/playbooks/phase-summarize.md

```markdown
# Phase Summarize Playbook

## Purpose
Summarize completed phases and archive old prompts to reduce context.

## Trigger
Run when `_build/prompts/` has 10+ completed phases.

## Steps

### 1. Identify Completed Phases
- Check each phase-XX/ folder
- Phase is complete if all prompts executed and tests pass

### 2. Create Summary
Create `_build/summaries/Phase_Summary_XX-YY.md`:

```markdown
# Phase Summary: Phases XX-YY

## Date Range
[Start date] - [End date]

## Features Implemented
- Feature 1: Brief description
- Feature 2: Brief description

## Key Decisions Made
- Decision 1: Why
- Decision 2: Why

## Tech Debt Introduced
- Item 1 (see tech-debt.md)

## Files Changed
- Major files added/modified

## Lessons Learned
- What went well
- What to improve
```

### 3. Archive Prompts
```bash
cd _build
tar -czf backups/archive/prompts-phase-XX-YY.tar.gz prompts/[phase-folders]
rm -rf prompts/[phase-folders]
```

### 4. Update tech-debt.md
Move any resolved items to "Resolved" section.

## Execution
Run via: `/phase-summarize`
```

### _build/playbooks/context-audit.md

```markdown
# Context Audit Playbook

## Purpose
Check for context bloat and recommend cleanup.

## Steps

### 1. Check File Counts
- Count files in src/ (should be manageable)
- Count files in testing/ 
- Count total .ts/.tsx files

### 2. Check Large Files
Find files >500 lines:
```bash
find src -name "*.ts" -o -name "*.tsx" | xargs wc -l | sort -n | tail -20
```

### 3. Check for AUDIT Tags
```bash
grep -rn "AUDIT:" src/
```

### 4. Check _build/ Size
- Should old prompts be archived?
- Are chats/ files stale? (claude-*, codex-*, etc.)

### 5. Report
Output:
- Files over 500 lines (recommend review)
- AUDIT tags found
- Stale files in _build/
- Recommended actions

## Execution
Run via: `/context-audit`
```

### _build/playbooks/test-audit.md

```markdown
# Test Audit Playbook

## Purpose
Find gaps in test coverage.

## Steps

### 1. Run Coverage Report
```bash
npm run test:coverage
```

### 2. Check Auto-Discovery
- Are all pages discovered?
- Are all API routes discovered?
- Are all components discovered?

### 3. Find Missing Tests
- Pages without custom tests
- API routes without error case tests
- Components with untested props

### 4. Report
Output:
- Coverage percentage by folder
- Files with 0% coverage
- Recommended tests to add

## Execution
Run via: `/test-audit`
```

---

## Checklist for New Projects

- [ ] Create folder structure
- [ ] Initialize Next.js
- [ ] Setup Prisma
- [ ] Create docker-compose.yml
- [ ] Create .env and .env.example
- [ ] Setup SOPS if using secrets
- [ ] Create CLAUDE.md files (root + subdirs)
- [ ] Create scripts (backup, setup, clean)
- [ ] Create playbooks
- [ ] Create slash commands
- [ ] Initialize git repo
- [ ] First commit with scaffold
- [ ] Run ./scripts/setup.sh
- [ ] Verify dev server runs

---

## Slash Command Templates

### .claude/commands/docs-cleanup.md

```markdown
# /docs-cleanup

Execute the docs cleanup playbook to organize loose documentation.

## Instructions
1. Read `_build/playbooks/docs-cleanup.md`
2. Execute each step
3. Report what was moved/organized/deleted
4. Do NOT create summary markdown files about what you did
```

### .claude/commands/phase-summarize.md

```markdown
# /phase-summarize

Summarize completed phases and archive old prompts.

## Instructions
1. Read `_build/playbooks/phase-summarize.md`
2. Check how many phases are complete
3. If 10+, create summary and archive
4. Report what was summarized and archived
```

### .claude/commands/context-audit.md

```markdown
# /context-audit

Check for context bloat and recommend cleanup.

## Instructions
1. Read `_build/playbooks/context-audit.md`
2. Execute checks
3. Report findings and recommendations
```

### .claude/commands/test-audit.md

```markdown
# /test-audit

Find gaps in test coverage.

## Instructions
1. Read `_build/playbooks/test-audit.md`
2. Run coverage analysis
3. Report gaps and recommendations
```

### .claude/commands/context-load.md

```markdown
# /context-load [name]

Load a pre-built context module.

## Usage
/context-load api      → Read _build/context/api-patterns.md
/context-load ui       → Read _build/context/ui-patterns.md
/context-load db       → Read _build/context/db-patterns.md

## Instructions
1. Read the specified context file from `_build/context/`
2. Apply patterns to current work
3. Acknowledge what was loaded
```

### .claude/commands/build.md

```markdown
# /build

Run build and report any errors.

## Instructions
1. Run `npm run build`
2. If errors, report them clearly
3. If success, confirm build complete
```

### .claude/commands/test.md

```markdown
# /test

Run full test suite and report results.

## Instructions
1. Run `npm test`
2. Report summary: passed/failed counts
3. If failures, show last 50 lines of output
4. Suggest fixes if obvious
```

---

## Context Pattern Templates (Pre-Fill These)

### _build/context/api-patterns.md

```markdown
# API Patterns Context

## Route Structure
- `/api/[resource]/route.ts` - Collection (GET list, POST create)
- `/api/[resource]/[id]/route.ts` - Individual (GET one, PUT, DELETE)

## Response Format
```typescript
// Success
return NextResponse.json({ data: result });

// Error
return NextResponse.json(
  { error: 'Not found', code: 'NOT_FOUND' },
  { status: 404 }
);
```

## Service Pattern
API routes call services, not database directly:
```typescript
// route.ts
import { TaskService } from '@/services/task-service';
const task = await TaskService.create(data);
```

## Validation
Use Zod for input validation:
```typescript
const schema = z.object({
  prompt: z.string().min(1),
  queueId: z.string().cuid()
});
```

## Error Handling
- 400: Bad request (validation failed)
- 401: Unauthorized
- 404: Not found
- 500: Server error (log, don't expose details)
```

### _build/context/ui-patterns.md

```markdown
# UI Patterns Context

## Component Structure
```typescript
// === TYPES ===
interface Props { ... }

// === COMPONENT ===
export function TaskCard({ task }: Props) {
  // hooks first
  const [state, setState] = useState();
  
  // handlers
  const handleClick = () => { ... };
  
  // render
  return ( ... );
}
```

## Import Order
1. React/Next.js
2. Third-party libraries
3. Components (@/components)
4. Hooks (@/hooks)
5. Services (@/services)
6. Types (@/types)
7. Utils (@/lib)

## Styling
- Tailwind classes, not inline styles
- Dark mode default (dark: prefix for light)
- Use shadcn/ui components as base

## Data Fetching
- SWR for client-side fetching
- Server components for initial data
- Optimistic updates for UX

## Keyboard Shortcuts
- `/` - Focus search
- `Cmd+Enter` - Submit
- `Escape` - Close modals
```

### _build/context/db-patterns.md

```markdown
# Database Patterns Context

## Schema Conventions
- Tables: snake_case plural (`tasks`, `queues`)
- Columns: snake_case (`created_at`, `queue_id`)
- Prisma models: PascalCase singular (`Task`, `Queue`)

## Required Fields (Every Table)
```prisma
id         String   @id @default(cuid())
created_at DateTime @default(now())
updated_at DateTime @updatedAt
```

## Foreign Keys
```prisma
queue_id String
queue    Queue @relation(fields: [queue_id], references: [id], onDelete: Cascade)
```

## Views for Readability
Create views for common joins:
```sql
CREATE VIEW tasks_with_queue AS
SELECT t.*, q.name as queue_name
FROM tasks t JOIN queues q ON t.queue_id = q.id;
```

## Seeds (Idempotent)
```typescript
await prisma.config.upsert({
  where: { key: 'poll_interval' },
  update: {},
  create: { key: 'poll_interval', value: '60' }
});
```
```

### _build/context/testing-patterns.md

```markdown
# Testing Patterns Context

## Test Location
- Unit/Integration: `testing/custom/[name].test.ts`
- E2E flows: `testing/e2e/flows/[name].spec.ts`
- Fixtures: `testing/fixtures/`

## Test Structure
```typescript
describe('TaskService', () => {
  beforeEach(async () => {
    // Setup
  });

  it('creates task with valid data', async () => {
    const result = await TaskService.create({ ... });
    expect(result.id).toBeDefined();
  });

  it('throws on invalid data', async () => {
    await expect(TaskService.create({})).rejects.toThrow();
  });
});
```

## Fixtures
Use realistic data, not "foo" or "test123":
```typescript
export const sampleTask = {
  prompt: 'Implement user authentication with JWT',
  status: 'pending',
  priority: 'high'
};
```

## Self-Test Rule
1. Run tests after each change
2. Fix failures immediately
3. Only ask for UAT after tests pass
```

---

## Agent Templates

### .claude/agents/code-reviewer.md

```markdown
---
name: code-reviewer
description: Expert code reviewer for quality, security, and maintainability. Use when reviewing code changes, PRs, or completed features.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a senior code reviewer with expertise in TypeScript, React, and Next.js.

## Review Checklist
1. **Security**: SQL injection, XSS, exposed secrets, auth bypasses
2. **Performance**: N+1 queries, unnecessary re-renders, memory leaks
3. **Maintainability**: Clear naming, proper abstractions, no magic numbers
4. **Testing**: Adequate coverage, edge cases handled
5. **Patterns**: Consistent with project conventions

## Output Format
- List issues by severity: 🔴 Critical, 🟡 Warning, 🔵 Suggestion
- Include file path and line numbers
- Provide specific fix recommendations

## Constraints
- Do NOT make changes, only report findings
- Be concise — no padding or excessive praise
- Focus on actionable feedback
```

### .claude/agents/remediator.md

```markdown
---
name: remediator
description: Bug fix and test failure specialist. Use when tests fail and need fixing.
tools: Read, Write, Bash, Grep, Glob
model: sonnet
---

You are a debugging specialist focused on fixing test failures and bugs quickly.

## Workflow
1. Read the error output (last 50 lines)
2. Identify root cause
3. Implement minimal fix
4. Re-run failing test
5. Repeat until passing

## Constraints
- Fix the bug, don't refactor unrelated code
- Prefer minimal changes over rewrites
- If stuck after 3 attempts, create Codex prompt

## Escalation
If issue requires >15 minutes:
1. Document findings in `_build/chats/claude-debug-[date].md`
2. Create Codex prompt: `_build/chats/codex-help-[issue].md`
3. Report status and blockers
```

### .claude/agents/codex-handoff.md

```markdown
---
name: codex-handoff
description: Creates well-structured prompts for OpenAI Codex. Use when offloading heavy code generation.
tools: Read, Write, Grep, Glob
model: sonnet
---

You create structured prompts for OpenAI Codex CLI.

## Prompt Structure
```markdown
# Task: [Clear title]

## Context
[What exists, what we're building, relevant files]

## Requirements
[Numbered list of specific requirements]

## Constraints
- [Technical constraints]
- [Patterns to follow]

## Expected Output
[What files to create/modify]

## Files to Reference
- `path/to/file1.ts`
```

## Output Location
Save prompts to: `_build/chats/codex-[task-name].md`
```

---

*Copy this template when starting any new project.*
