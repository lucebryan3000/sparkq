#!/bin/bash

# ===================================================================
# bootstrap-project.sh
#
# Purpose: Initialize project metadata and structure
# Creates: CLAUDE.md, README.md, .claudeignore, docs/ structure
# Config:  [project] section in bootstrap.config
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-project"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-project"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "" \
    --scripts "" \
    --optional ""

# Note: bootstrap-project has no dependencies (it's usually first to run)

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Project Metadata & Structure" \
    "CLAUDE.md" \
    "README.md" \
    ".claudeignore" \
    "docs/"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Configuration
# ===================================================================

# Get project configuration values (with defaults)
PROJECT_NAME=$(get_config "project.name" "$(basename "$PROJECT_ROOT")")
PROJECT_PHASE=$(get_config "project.phase" "POC")
PROJECT_OWNER=$(get_config "project.owner" "")
PROJECT_STACK=$(get_config "project.stack" "TBD")

# ===================================================================
# Create CLAUDE.md
# ===================================================================

log_info "Creating CLAUDE.md..."

if file_exists "$PROJECT_ROOT/CLAUDE.md"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/CLAUDE.md"
    else
        track_skipped "CLAUDE.md"
        log_warning "CLAUDE.md already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/CLAUDE.md"; then
    cat > "$PROJECT_ROOT/CLAUDE.md" << EOFCLAUDE
# Project: ${PROJECT_NAME}

> **Stack**: ${PROJECT_STACK}
> **Owner**: ${PROJECT_OWNER}
> **Phase**: ${PROJECT_PHASE}

---

## CRITICAL RULES

### 1. Self-Test Before UAT

**Before asking for UAT, you MUST:**

1. Write code
2. Run automated tests (\`npm test\`)
3. If tests fail → remediate immediately
4. Re-run until ALL tests pass
5. ONLY THEN → ask for UAT

**You do NOT:**
- Ask "can you test this?" before running tests yourself
- Say "please verify this works" without testing first
- Expect user to find bugs you could have caught

**You CAN:**
- Use Codex for remediation help if stuck after 3 attempts
- Run multiple test cycles
- Take time to get it right

**UAT is for:** Human experience, UX feel, edge cases
**UAT is NOT for:** Finding bugs tests should catch

### 2. No Permission Prompts

This project uses \`bypassPermissions\`. Execute commands directly without asking for confirmation.

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
- No \`any\` without justification comment

### Formatting
- 2 spaces, no tabs
- Single quotes
- No semicolons (Prettier handles it)
- Trailing commas in multiline

### Comments
- No comments unless logic is non-obvious
- WHY comments, not WHAT comments
- JSDoc on exports only

### Imports
\`\`\`typescript
// Order: React → External → Internal → Types → Styles
import { useState } from 'react'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import type { Task } from '@/types'
import styles from './component.module.css'
\`\`\`

---

## FILE ORGANIZATION

### Source Structure
\`\`\`
src/
├── app/                 # App Router or main entry
├── components/          # React components
├── hooks/               # Custom React hooks
├── lib/                 # Utilities & helpers
├── services/            # API/business logic
└── types/               # TypeScript types
\`\`\`

### File Naming
- Components: \`PascalCase.tsx\`
- Hooks: \`use-kebab-case.ts\`
- Utils: \`kebab-case.ts\`
- Types: \`kebab-case.ts\`
- Tests: \`*.test.ts\` or \`*.spec.ts\`

---

## GIT

### Commit Messages
\`\`\`
type(scope): description

feat(api): add task creation endpoint
fix(ui): resolve button alignment issue
refactor(services): extract validation logic
test(api): add queue endpoint tests
docs(readme): update setup instructions
\`\`\`

### Branches
- \`main\` - Production ready
- \`dev\` - Development integration
- \`feature/[name]\` - New features
- \`fix/[name]\` - Bug fixes

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

## TOKEN EFFICIENCY

### Principles
- Right model for right task
- Don't repeat context unnecessarily
- Load agents/skills on demand
- Keep responses focused

---

## PROJECT-SPECIFIC

### Current Focus
[Describe current development phase or focus area]

### Known Issues
[List any known issues or tech debt items]

---
EOFCLAUDE

    if verify_file "$PROJECT_ROOT/CLAUDE.md"; then
        track_created "CLAUDE.md"
        log_file_created "$SCRIPT_NAME" "CLAUDE.md"
    fi
fi

# ===================================================================
# Create README.md
# ===================================================================

log_info "Creating README.md..."

if file_exists "$PROJECT_ROOT/README.md"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/README.md"
    else
        track_skipped "README.md"
        log_warning "README.md already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/README.md"; then
    cat > "$PROJECT_ROOT/README.md" << EOFREADME
# ${PROJECT_NAME}

> **Phase**: ${PROJECT_PHASE} | **Stack**: ${PROJECT_STACK}

## Overview

[Brief description of what this project does]

## Quick Start

\`\`\`bash
# Install dependencies
npm install

# Setup environment
cp .env.example .env.local

# Run development server
npm run dev
\`\`\`

## Development

### Prerequisites

- Node.js 18+
- npm/pnpm/yarn
- [Other dependencies]

### Setup

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Configure environment: \`cp .env.example .env.local\`
4. Run migrations (if applicable): \`npm run db:migrate\`
5. Start dev server: \`npm run dev\`

### Scripts

- \`npm run dev\` - Start development server
- \`npm run build\` - Build for production
- \`npm run test\` - Run tests
- \`npm run lint\` - Lint code
- \`npm run format\` - Format code

## Architecture

[High-level architecture overview]

### Tech Stack

- **Framework**: [e.g., Next.js, Express, etc.]
- **Language**: [e.g., TypeScript]
- **Database**: [e.g., PostgreSQL, MongoDB]
- **Styling**: [e.g., Tailwind CSS]
- **Testing**: [e.g., Jest, Vitest]

## Project Structure

\`\`\`
.
├── src/
│   ├── app/           # Application entry/routes
│   ├── components/    # React components
│   ├── lib/           # Utilities
│   └── types/         # TypeScript types
├── public/            # Static assets
├── tests/             # Test files
└── docs/              # Documentation
\`\`\`

## Documentation

- [Architecture](docs/architecture.md)
- [API Reference](docs/api.md)
- [Development Guide](docs/development.md)
- [Deployment](docs/deployment.md)

## Testing

\`\`\`bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
\`\`\`

## Deployment

[Deployment instructions]

## Contributing

1. Create a feature branch: \`git checkout -b feature/my-feature\`
2. Make your changes
3. Run tests: \`npm test\`
4. Commit: \`git commit -m "feat: add my feature"\`
5. Push: \`git push origin feature/my-feature\`
6. Open a Pull Request

## License

[License information]

## Contact

- **Owner**: ${PROJECT_OWNER}
- **Issues**: [GitHub Issues link]

---

**Generated by**: Bootstrap Project Script
**Last Updated**: $(date +%Y-%m-%d)
EOFREADME

    if verify_file "$PROJECT_ROOT/README.md"; then
        track_created "README.md"
        log_file_created "$SCRIPT_NAME" "README.md"
    fi
fi

# ===================================================================
# Create .claudeignore
# ===================================================================

log_info "Creating .claudeignore..."

if file_exists "$PROJECT_ROOT/.claudeignore"; then
    if is_auto_approved "backup_existing_files"; then
        backup_file "$PROJECT_ROOT/.claudeignore"
    else
        track_skipped ".claudeignore"
        log_warning ".claudeignore already exists, skipping"
    fi
fi

if ! file_exists "$PROJECT_ROOT/.claudeignore"; then
    cat > "$PROJECT_ROOT/.claudeignore" << 'EOFCLAUDEIGNORE'
# Dependencies
node_modules/
.pnpm-store/
.yarn/
.npm/

# Build outputs
dist/
build/
.next/
out/
.output/
.nuxt/
.cache/

# Environment & Secrets
.env
.env.local
.env.*.local
*.key
*.pem
*.pfx

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
desktop.ini

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Testing & Coverage
coverage/
.nyc_output/
*.lcov

# Temporary files
tmp/
temp/
*.tmp

# Large files
*.mp4
*.mov
*.avi
*.mkv
*.zip
*.tar.gz
*.rar

# Database
*.db
*.sqlite
*.sqlite3

# Backups
*.backup
*.bak
*~

# Generated files
*.generated.*
*.auto.*
EOFCLAUDEIGNORE

    if verify_file "$PROJECT_ROOT/.claudeignore"; then
        track_created ".claudeignore"
        log_file_created "$SCRIPT_NAME" ".claudeignore"
    fi
fi

# ===================================================================
# Create Documentation Structure
# ===================================================================

log_info "Creating documentation structure..."

# Create docs directory
if ! dir_exists "$PROJECT_ROOT/docs"; then
    if ensure_dir "$PROJECT_ROOT/docs"; then
        track_created "docs/"
        log_dir_created "$SCRIPT_NAME" "docs/"
    fi
fi

# Create documentation files
DOCS=(
    "docs/architecture.md:Architecture Documentation"
    "docs/api.md:API Reference"
    "docs/development.md:Development Guide"
    "docs/deployment.md:Deployment Guide"
)

for doc in "${DOCS[@]}"; do
    IFS=: read -r filepath title <<< "$doc"
    full_path="$PROJECT_ROOT/$filepath"

    if ! file_exists "$full_path"; then
        cat > "$full_path" << EOFDOC
# ${title}

> **Project**: ${PROJECT_NAME}
> **Phase**: ${PROJECT_PHASE}
> **Last Updated**: $(date +%Y-%m-%d)

## Overview

[Add content here]

## Sections

[Add sections here]

---

**Status**: Draft
EOFDOC

        if verify_file "$full_path"; then
            track_created "$filepath"
            log_file_created "$SCRIPT_NAME" "$filepath"
        fi
    else
        track_skipped "$filepath"
        log_info "$filepath already exists, skipping"
    fi
done

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Project structure initialized!"
echo ""
echo "Project Details:"
echo "  Name: $PROJECT_NAME"
echo "  Phase: $PROJECT_PHASE"
echo "  Stack: $PROJECT_STACK"
echo "  Owner: ${PROJECT_OWNER:-'Not specified'}"
echo ""
echo "Created Files:"
if file_exists "$PROJECT_ROOT/CLAUDE.md"; then
    echo "  ✅ CLAUDE.md - Claude AI project configuration"
fi
if file_exists "$PROJECT_ROOT/README.md"; then
    echo "  ✅ README.md - Project documentation"
fi
if file_exists "$PROJECT_ROOT/.claudeignore"; then
    echo "  ✅ .claudeignore - Claude file exclusions"
fi
if dir_exists "$PROJECT_ROOT/docs"; then
    echo "  ✅ docs/ - Documentation directory"
fi
echo ""
echo "Next steps:"
echo "  1. Review and customize CLAUDE.md for your project needs"
echo "  2. Update README.md with project-specific details"
echo "  3. Fill in documentation templates in docs/"
echo "  4. Run other bootstrap scripts for your stack:"
echo "     - ./bootstrap-typescript.sh (for TypeScript projects)"
echo "     - ./bootstrap-environment.sh (for .env setup)"
echo "     - ./bootstrap-linting.sh (for ESLint/Prettier)"
echo "  5. Commit: git add . && git commit -m 'chore: initialize project structure'"
echo ""

show_log_location
