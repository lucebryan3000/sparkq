#!/bin/bash
# =============================================================================
# @name           bootstrap-claude
# @phase          1
# @category       ai
# @short          Complete Claude Code configuration with agents & commands
# @description    Bootstraps complete Claude Code development environment with
#                 comprehensive agent system, custom slash commands, hooks, and
#                 project-specific instructions. Creates .claude/ structure with
#                 agents, commands, skills, MCP config, and team settings.
#
# @creates        .claude/settings.json
# @creates        .claude/agents/code-reviewer.md
# @creates        .claude/agents/debugger.md
# @creates        .claude/commands/analyze.md
# @creates        .claude/hooks/post-write.sh
# @creates        .mcp.json
# @creates        .claudeignore
# @creates        CLAUDE.md
#
# @defaults       model=claude-opus-4-5-20251101, bypassPermissions=true
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
# =============================================================================

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-claude.sh"

# Source additional libraries
source "${BOOTSTRAP_DIR}/lib/template-utils.sh"
source "${BOOTSTRAP_DIR}/lib/validation-common.sh"
source "${BOOTSTRAP_DIR}/lib/config-manager.sh"

# Get project root
PROJECT_ROOT=$(get_project_root "${1:-.}")
CLAUDE_DIR="${PROJECT_ROOT}/.claude"
TEMPLATE_CLAUDE="${TEMPLATES_DIR}/.claude"

# Answers file
ANSWERS_FILE=".bootstrap-answers.env"

# Script identifier for logging
SCRIPT_NAME="bootstrap-claude"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "" \
    --scripts "" \
    --optional "node"


# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Claude Code Configuration" \
    ".claude/ directory" \
    "agents/, commands/, hooks/, skills/" \
    "settings.json" \
    "CLAUDE.md" \
    ".mcp.json" \
    ".claudeignore"

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping Claude Code configuration..."

require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
require_dir "$TEMPLATE_CLAUDE" || log_fatal "Template .claude directory not found: $TEMPLATE_CLAUDE"

# ===================================================================
# Create Directory Structure
# ===================================================================

log_info "Creating .claude directory structure..."
ensure_dir "$CLAUDE_DIR"
for dir in agents commands hooks skills; do
    ensure_dir "$CLAUDE_DIR/$dir"
    log_dir_created "$SCRIPT_NAME" ".claude/$dir"
done
track_created ".claude/ structure"
log_success "Directory structure created"

# ===================================================================
# Copy Template Files
# ===================================================================

log_info "Copying files from template..."

if [[ -f "$TEMPLATE_CLAUDE/codex.md" ]]; then
    cp "$TEMPLATE_CLAUDE/codex.md" "$CLAUDE_DIR/"
    log_success "Copied codex.md"
fi

if [[ -f "$TEMPLATE_CLAUDE/codex_prompt.md" ]]; then
    cp "$TEMPLATE_CLAUDE/codex_prompt.md" "$CLAUDE_DIR/"
    log_success "Copied codex_prompt.md"
fi

if [[ -f "$TEMPLATE_CLAUDE/haiku.md" ]]; then
    cp "$TEMPLATE_CLAUDE/haiku.md" "$CLAUDE_DIR/"
    log_success "Copied haiku.md"
fi

if [[ -f "$TEMPLATE_CLAUDE/self-testing-protocol.md" ]]; then
    cp "$TEMPLATE_CLAUDE/self-testing-protocol.md" "$CLAUDE_DIR/"
    log_success "Copied self-testing-protocol.md"
fi

if [[ -f "$TEMPLATE_CLAUDE/codex-optimization.md" ]]; then
    cp "$TEMPLATE_CLAUDE/codex-optimization.md" "$CLAUDE_DIR/"
    log_success "Copied codex-optimization.md"
fi

# ===================================================================
# Create Example Agents
# ===================================================================

log_info "Creating example agents..."

cat > "$CLAUDE_DIR/agents/code-reviewer.md" << 'EOF'
---
description: Specialized code reviewer for security, performance, and style
tools:
  - Bash
  - Read
  - Grep
  - Edit
model: claude-opus-4-5-20251101
---

# Code Reviewer Subagent

You are a meticulous code reviewer specializing in:

## Review Focus Areas

### Security
- Input validation and sanitization
- SQL injection vulnerabilities
- XSS vulnerabilities
- CSRF protections
- Authentication/authorization flaws
- Secrets in code
- Dependency vulnerabilities

### Performance
- Time complexity (O(n²) algorithms)
- Unnecessary loops and iterations
- Memory leaks
- Database query efficiency
- N+1 query problems
- Bundle size issues

### Code Quality
- Adherence to TypeScript strict mode
- Proper error handling
- Code duplication
- Testability
- Documentation completeness
- Naming conventions

### Accessibility & Standards
- WCAG compliance for UI components
- Semantic HTML
- ARIA attributes
- Keyboard navigation

## Review Process

When reviewing code:

1. **Identify issues** - Flag each issue with severity (Critical, High, Medium, Low)
2. **Explain why** - Provide context for each issue
3. **Suggest fixes** - Provide concrete code examples
4. **Reference standards** - Link to best practices and docs when relevant

## Output Format

```markdown
## Review Results

### 🔴 Critical Issues
- [Description with severity]

### 🟠 High Priority Issues
- [Description]

### 🟡 Medium Priority Issues
- [Description]

### 🔵 Low Priority / Suggestions
- [Description]

### ✅ Strengths
- [Positive findings]
```
EOF

log_success "Created code-reviewer agent"

cat > "$CLAUDE_DIR/agents/debugger.md" << 'EOF'
---
description: Expert debugger for systematic issue diagnosis and resolution
tools:
  - Bash
  - Read
  - Grep
  - Edit
  - Write
model: claude-opus-4-5-20251101
---

# Debugger Subagent

You are an expert debugger specializing in systematic problem diagnosis and resolution.

## Debugging Methodology

### Phase 1: Symptom Gathering
- What is the exact error message?
- When does it occur (conditions)?
- What was the last code change?
- What environment (dev/prod)?
- Reproducible? Consistently?

### Phase 2: Hypothesis Formation
- Likely root causes (ranked by probability)
- Scope (single file, module, system-wide?)
- Recent changes related to the issue?

### Phase 3: Investigation
- Search error logs
- Trace execution path
- Check recent changes
- Review related dependencies
- Verify assumptions

### Phase 4: Diagnosis
- Root cause identification
- Why does the fix work?
- Are there related issues?

### Phase 5: Resolution
- Implement minimal fix
- Add defensive checks if needed
- Write regression test

## Investigation Techniques

- **Log Analysis**: Search logs for error context
- **Stack Trace Review**: Trace execution path
- **Git History**: Check recent commits
- **Dependency Check**: Review version changes
- **Test Case**: Create minimal reproduction
- **Isolation**: Test specific functions in isolation

## Output Format

```markdown
## Debug Analysis

### 🔍 Symptoms
- [Exact error message]
- [When it occurs]
- [Reproducibility status]

### 💡 Hypotheses (Ranked)
1. [Most likely cause] - Confidence: High
2. [Secondary cause] - Confidence: Medium
3. [Alternative cause] - Confidence: Low

### 🔎 Investigation Results
[Findings from log analysis, git history, etc.]

### ✅ Root Cause
[Exact root cause with explanation]

### 🛠️ Solution
[Fix with code example]

### 🧪 Verification
[How to verify the fix works]
```
EOF

log_success "Created debugger agent"

# ===================================================================
# Create Example Slash Commands
# ===================================================================

log_info "Creating example slash commands..."

cat > "$CLAUDE_DIR/commands/analyze.md" << 'EOF'
---
description: Analyze code structure, dependencies, and architecture
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Analyze Command

Analyze the selected code or specified files for:
- Architecture and structure
- Key dependencies
- Code organization patterns
- Potential issues
- Performance characteristics

## Usage

```
/analyze
# Analyzes selection or current file

/analyze src/services
# Analyzes specific directory

/analyze src/components/Button.tsx src/hooks/use-button.ts
# Analyzes multiple files
```

## Analysis Includes

- **Structure**: File organization and module relationships
- **Complexity**: Cyclomatic complexity and cognitive load
- **Dependencies**: External and internal dependencies
- **Patterns**: Design patterns used
- **Issues**: Potential bugs or anti-patterns
- **Performance**: Time/space complexity concerns
EOF

log_success "Created analyze command"

cat > "$CLAUDE_DIR/commands/test.md" << 'EOF'
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
EOF

log_success "Created test command"

cat > "$CLAUDE_DIR/commands/document.md" << 'EOF'
---
description: Generate documentation for code, create JSDoc, or update README
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
---

# Document Command

Generate comprehensive documentation for code, add JSDoc comments, or update project documentation.

## Usage

```
/document src/services/api.ts
# Generate JSDoc for all exports

/document api
# Document entire module

/document --readme
# Update README with architecture overview

/document --types
# Generate type documentation
```

## Documentation Types

- **JSDoc**: Generate function/class documentation comments
- **Architecture**: Document system design and data flow
- **API**: Document endpoints and request/response formats
- **Types**: Document TypeScript interfaces and types
- **README**: Update project documentation and setup guides

## Output Includes

- Function signatures and parameters
- Return types and examples
- Usage examples
- Edge cases and limitations
- Cross-references to related code
EOF

log_success "Created document command"

# ===================================================================
# Create settings.json
# ===================================================================

log_info "Creating .claude/settings.json..."

cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "cleanupPeriodDays": 30,
  "model": "claude-opus-4-5-20251101",

  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": [
      "Bash(npm run test:*)",
      "Bash(npm run lint:*)",
      "Bash(npm run build:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)"
    ],
    "deny": [
      "Read(./.env*)",
      "Read(./secrets/**)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Bash(rm -rf /)",
      "Bash(git push origin -f)"
    ],
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

log_success "Created settings.json"

# ===================================================================
# Create settings.local.json.example
# ===================================================================

log_info "Creating settings.local.json.example..."

cat > "$CLAUDE_DIR/settings.local.json.example" << 'EOF'
{
  "model": "claude-haiku-4-5-20251001",
  "alwaysThinkingEnabled": false,
  "spinnerTipsEnabled": false,
  "permissions": {
    "allow": [
      "WebSearch"
    ]
  },
  "env": {
    "DEBUG": "sparkq:*",
    "LOG_LEVEL": "debug"
  }
}
EOF

log_success "Created settings.local.json.example"

# ===================================================================
# Create .mcp.json
# ===================================================================

log_info "Creating .mcp.json..."

cat > "$PROJECT_ROOT/.mcp.json" << 'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "disabled": false
    },
    "github": {
      "command": "uvx",
      "args": ["mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "disabled": true
    },
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "$(pwd)"],
      "disabled": false
    }
  }
}
EOF

log_success "Created .mcp.json"

# ===================================================================
# Create .claudeignore
# ===================================================================

log_info "Creating .claudeignore..."

cat > "$PROJECT_ROOT/.claudeignore" << 'EOF'
# ===================================================================
# .claudeignore - Context Optimization (Soft Block)
# ===================================================================

node_modules/
pnpm-lock.yaml
yarn.lock
package-lock.json
.next/
dist/
build/
coverage/
.pytest_cache/
.nyc_output/
.git/
.gitmodules
.env.local
.env.production
.env.*.local
*.pem
*.key
.vault*
.vscode/
.idea/
.DS_Store
Thumbs.db
logs/
*.log
_build/
docs/
documentation/
wiki/
.github/workflows/
.claude/agents/
.claude/skills/
.claude/orchestrator/
.claude/prompts/
__bootbuild/
EOF

log_success "Created .claudeignore"

# ===================================================================
# Create CLAUDE.md
# ===================================================================

log_info "Creating CLAUDE.md..."

cat > "$PROJECT_ROOT/CLAUDE.md" << 'EOF'
# Project: [PROJECT_NAME]

> **Stack**: TBD
> **Owner**: Bryan Luce (bryan@appmelia.com)
> **Phase**: POC

---

## CRITICAL RULES

### 1. Self-Test Before UAT

**Before asking Bryan for UAT, you MUST:**

1. Write code
2. Run automated tests (`npm test`)
3. If tests fail → remediate immediately
4. Re-run until ALL tests pass
5. ONLY THEN → ask for UAT

**You do NOT:**
- Ask "can you test this?" before running tests yourself
- Say "please verify this works" without testing first
- Expect Bryan to find bugs you could have caught

**You CAN:**
- Use Codex for remediation help if stuck after 3 attempts
- Run multiple test cycles
- Take time to get it right

**UAT is for:** Human experience, UX feel, edge cases
**UAT is NOT for:** Finding bugs tests should catch

### 2. No Permission Prompts

This project uses `bypassPermissions`. Execute commands directly without asking for confirmation.

### 3. Implementation Over Explanation

When given a task:
- Implement first, explain briefly after
- No "here's what I'm going to do" preambles
- No "let me know if you want me to..." hedging
- Just do it, then summarize what you did

---

## CODE STYLE

### TypeScript
- Strict mode always
- Explicit return types on exports
- Zod for runtime validation
- No `any` without justification comment

### Formatting
- 2 spaces, no tabs
- Single quotes
- No semicolons (Prettier handles it)
- Trailing commas in multiline

### Comments
- No comments unless logic is non-obvious
- WHY comments, not WHAT comments
- JSDoc on exports only

---

## FILE ORGANIZATION

### Source Structure
```
src/
├── app/                 # App Router or main entry
├── components/          # React components
├── hooks/               # Custom React hooks
├── lib/                 # Utilities & helpers
├── services/            # API/business logic
└── types/               # TypeScript types
```

### File Naming
- Components: `PascalCase.tsx`
- Hooks: `use-kebab-case.ts`
- Utils: `kebab-case.ts`
- Types: `kebab-case.ts`
- Tests: `*.test.ts` or `*.spec.ts`

---

## GIT

### Commit Messages
```
type(scope): description

feat(api): add task creation endpoint
fix(ui): resolve button alignment issue
refactor(services): extract validation logic
test(api): add queue endpoint tests
docs(readme): update setup instructions
```

### Branches
- `main` - Production ready
- `dev` - Development integration
- `feature/[name]` - New features
- `fix/[name]` - Bug fixes

---

## COMMUNICATION

### When to Ask vs Execute
**Just execute:**
- Clear implementation tasks
- Bug fixes with obvious solutions
- Refactors following established patterns
- Test additions

**Ask first:**
- Architecture changes
- New dependencies
- Breaking changes
- Ambiguous requirements

### Progress Updates
- Brief status after completing major items
- No play-by-play commentary
- Report blockers immediately

---

## PROJECT-SPECIFIC

### Current Focus
[Describe current development phase or focus area]

### Known Issues
[List any known issues or tech debt items]

---
EOF

log_success "Created CLAUDE.md"

# ===================================================================
# Create .claude/README.md
# ===================================================================

log_info "Creating .claude/README.md..."

cat > "$CLAUDE_DIR/README.md" << 'EOF'
# Claude Code Configuration

This directory contains all Claude Code-specific configuration and customization.

## Directory Structure

```
.claude/
├── settings.json              # Team-shared project settings
├── settings.local.json        # Personal settings (git-ignored)
├── README.md                  # This file
├── agents/                    # Custom AI subagents
│   ├── code-reviewer.md
│   └── debugger.md
├── commands/                  # Custom slash commands
│   ├── analyze.md
│   ├── test.md
│   └── document.md
├── hooks/                     # Hook script files
└── skills/                    # Complex reusable capabilities
```

## Files at Project Root

- **`.mcp.json`** - MCP (Model Context Protocol) server configuration
- **`CLAUDE.md`** - Project-specific instructions and conventions
- **`.claudeignore`** - Files excluded from Claude's auto-loaded context

## Quick Start

### Using Custom Agents

```bash
# Use the code reviewer agent
/agents code-reviewer
Review src/api/handler.ts for security issues

# Use the debugger agent
/agents debugger
The app crashes with "Cannot read property 'id' of undefined"
```

### Using Slash Commands

```bash
/analyze src/services
/test --watch
/document src/types
```

### Personal Configuration

1. Copy: `cp .claude/settings.local.json.example .claude/settings.local.json`
2. Edit with your personal preferences
3. It's git-ignored and overrides `settings.json` for you only

## Configuration Hierarchy

Settings are applied (highest priority first):

1. Command line arguments
2. Local settings (`.claude/settings.local.json`)
3. Shared settings (`.claude/settings.json`)
4. User settings (`~/.claude/settings.json`)

## Documentation

- [Claude Code Documentation](https://code.claude.com)
- [Settings Reference](https://code.claude.com/docs/en/settings.md)
- [Slash Commands Guide](https://code.claude.com/docs/en/slash-commands.md)
- [Subagents](https://code.claude.com/docs/en/sub-agents.md)
EOF

log_success "Created .claude/README.md"

# ===================================================================
# Validation & Testing (Self-Testing Protocol)
# ===================================================================

validate_bootstrap() {
    local errors=0

    log_info "Validating bootstrap configuration..."
    echo ""

    # Test 1: Directory structure
    log_info "Checking directory structure..."
    for dir in agents commands hooks skills; do
        if [[ -d "$CLAUDE_DIR/$dir" ]]; then
            log_success "Directory: .claude/$dir exists"
        else
            log_error "Missing directory: .claude/$dir"
            errors=$((errors + 1))
        fi
    done

    # Test 2: Core configuration files
    log_info "Checking core configuration files..."
    for file in settings.json settings.local.json.example README.md; do
        if [[ -f "$CLAUDE_DIR/$file" ]]; then
            log_success "File: .claude/$file exists"
        else
            log_error "Missing file: .claude/$file"
            errors=$((errors + 1))
        fi
    done

    # Test 3: Root-level files
    log_info "Checking root-level files..."
    for file in .mcp.json .claudeignore CLAUDE.md; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "File: $file exists"
        else
            log_error "Missing file: $file"
            errors=$((errors + 1))
        fi
    done

    # Test 4: Validate JSON files (Haiku-style validation)
    log_info "Validating JSON syntax..."
    if python3 -m json.tool "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
        log_success "JSON: .claude/settings.json is valid"
    else
        log_error "Invalid JSON in .claude/settings.json"
        errors=$((errors + 1))
    fi

    if python3 -m json.tool "$PROJECT_ROOT/.mcp.json" >/dev/null 2>&1; then
        log_success "JSON: .mcp.json is valid"
    else
        log_error "Invalid JSON in .mcp.json"
        errors=$((errors + 1))
    fi

    if python3 -m json.tool "$CLAUDE_DIR/settings.local.json.example" >/dev/null 2>&1; then
        log_success "JSON: settings.local.json.example is valid"
    else
        log_error "Invalid JSON in settings.local.json.example"
        errors=$((errors + 1))
    fi

    # Test 5: Agents
    log_info "Checking agents..."
    for agent in code-reviewer debugger; do
        if [[ -f "$CLAUDE_DIR/agents/${agent}.md" ]]; then
            if grep -q "^---" "$CLAUDE_DIR/agents/${agent}.md" && grep -q "description:" "$CLAUDE_DIR/agents/${agent}.md"; then
                log_success "Agent: $agent.md has YAML frontmatter"
            else
                log_warning "Agent: $agent.md may be missing YAML frontmatter"
            fi
        else
            log_error "Missing agent: $agent.md"
            errors=$((errors + 1))
        fi
    done

    # Test 6: Commands
    log_info "Checking commands..."
    for cmd in analyze test document; do
        if [[ -f "$CLAUDE_DIR/commands/${cmd}.md" ]]; then
            log_success "Command: $cmd.md exists"
        else
            log_error "Missing command: $cmd.md"
            errors=$((errors + 1))
        fi
    done

    # Test 7: Template files
    log_info "Checking template files..."
    for tmpl in codex codex_prompt codex-optimization haiku self-testing-protocol; do
        if [[ -f "$CLAUDE_DIR/${tmpl}.md" ]]; then
            log_success "Template: $tmpl.md copied"
        else
            log_warning "Template: $tmpl.md not found (optional)"
        fi
    done

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_error "Validation found $errors error(s)"
        return 1
    fi
}

# ===================================================================
# Template Customization
# ===================================================================

customize_templates() {
    log_info "Customizing templates with your configuration..."

    # Only customize if answers file exists
    if [[ ! -f "$ANSWERS_FILE" ]]; then
        log_warning "No answers file found. Skipping customization."
        log_info "Run with --interactive mode or manually edit files."
        return 0
    fi

    # Source answers
    source "$ANSWERS_FILE"

    local customized=0

    # Customize CLAUDE.md if it exists in project root
    if [[ -f "${PROJECT_ROOT}/CLAUDE.md" ]]; then
        log_info "Customizing CLAUDE.md..."

        # Replace PROJECT_NAME placeholder
        if [[ -n "${PROJECT_NAME:-}" ]]; then
            replace_in_file "${PROJECT_ROOT}/CLAUDE.md" "\\[PROJECT_NAME\\]" "$PROJECT_NAME" || \
            replace_in_file "${PROJECT_ROOT}/CLAUDE.md" "sparkq" "$PROJECT_NAME"
            ((customized++))
        fi

        # Replace project phase
        if [[ -n "${PROJECT_PHASE:-}" ]]; then
            replace_in_file "${PROJECT_ROOT}/CLAUDE.md" "Phase: POC" "Phase: $PROJECT_PHASE" || \
            sed -i "s/\*\*Phase\*\*: .*/\*\*Phase\*\*: $PROJECT_PHASE/" "${PROJECT_ROOT}/CLAUDE.md"
            ((customized++))
        fi

        log_success "CLAUDE.md customized"
    fi

    # Customize .claude/settings.json
    if [[ -f "${CLAUDE_DIR}/settings.json" ]]; then
        log_info "Customizing .claude/settings.json..."

        # Update AI model if specified
        if [[ -n "${AI_MODEL:-}" ]]; then
            update_json_field "${CLAUDE_DIR}/settings.json" "defaultModel" "claude-$AI_MODEL-4-5-20251101" || true
            ((customized++))
        fi

        log_success ".claude/settings.json customized"
    fi

    # Remove Codex files if not enabled
    if [[ "${ENABLE_CODEX:-true}" == "false" ]]; then
        log_info "Codex disabled. Removing Codex files..."
        rm -f "${CLAUDE_DIR}/codex.md" \
              "${CLAUDE_DIR}/codex_prompt.md" \
              "${CLAUDE_DIR}/codex-optimization.md"
        log_success "Codex files removed"
        ((customized++))
    fi

    # Update config with answers
    config_update_from_answers "$ANSWERS_FILE"

    if [[ $customized -gt 0 ]]; then
        log_success "Applied $customized customizations"
        return 0
    else
        log_info "No customizations applied"
        return 0
    fi
}

# ===================================================================
# Summary & Next Steps
# ===================================================================

# Run customization if answers exist
if [[ -f "$ANSWERS_FILE" ]]; then
    customize_templates
fi

validate_bootstrap

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} items created"
show_summary
show_log_location

log_info "Next steps:"
if [[ -f "$ANSWERS_FILE" ]]; then
    echo "  ✓ Templates have been customized with your configuration"
    echo "  1. Review CLAUDE.md and .claude/settings.json"
    echo "  2. Commit to git:"
    echo "     git add -A && git commit -m 'Setup Claude configuration'"
    echo "  3. (Optional) Create personal settings:"
    echo "     cp .claude/settings.local.json.example .claude/settings.local.json"
else
    echo "  1. Edit CLAUDE.md - replace [PROJECT_NAME], update Stack/Owner/Phase"
    echo "  2. Review .claude/settings.json - customize model and permissions"
    echo "  3. Commit: git add -A && git commit -m 'Setup Claude configuration'"
    echo "  4. (Optional) cp .claude/settings.local.json.example .claude/settings.local.json"
fi
echo ""
