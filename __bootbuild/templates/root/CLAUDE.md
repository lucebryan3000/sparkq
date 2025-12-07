# Project: [PROJECT_NAME]

> **Stack**: Next.js 14+ / TypeScript / PostgreSQL / Prisma / Docker  
> **Owner**: Bryan Luce (bryan@appmelia.com)  
> **Phase**: [MVP / POC / Production]

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

### Imports
```typescript
// Order: React → External → Internal → Types → Styles
import { useState } from 'react'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import type { Task } from '@/types'
import styles from './component.module.css'
```

---

## FILE ORGANIZATION

### Source Structure
```
src/
├── app/                 # Next.js App Router
├── components/
│   ├── ui/              # Reusable primitives
│   ├── layout/          # Layout components
│   └── [feature]/       # Feature-specific
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

## DATABASE

### Prisma Conventions
- Table names: `snake_case`, plural (`tasks`, `queue_items`)
- Columns: `snake_case`
- Relations: Explicit names
- Every table needs: `id`, `created_at`, `updated_at`

### Required Fields
```prisma
model Example {
  id         String   @id @default(cuid())
  created_at DateTime @default(now())
  updated_at DateTime @updatedAt
  // ... other fields
}
```

### Seeds
- Must be idempotent (use upsert)
- Include realistic test data
- Run on every `docker compose up`

---

## API PATTERNS

### Route Structure
```typescript
// src/app/api/[resource]/route.ts
export async function GET() { }
export async function POST(request: NextRequest) { }

// src/app/api/[resource]/[id]/route.ts
export async function GET(request: NextRequest, { params }) { }
export async function PUT(request: NextRequest, { params }) { }
export async function DELETE(request: NextRequest, { params }) { }
```

### Response Format
```typescript
// Success
{ data: T }
{ data: T[], meta: { total, page, limit } }

// Error
{ error: string, code: string, details?: unknown }
```

### Service Pattern
```typescript
// src/services/[resource]-service.ts
export const ResourceService = {
  list: async () => { },
  getById: async (id: string) => { },
  create: async (data: CreateResource) => { },
  update: async (id: string, data: UpdateResource) => { },
  delete: async (id: string) => { },
}
```

---

## TESTING

### Test Location
- Unit tests: `src/**/*.test.ts` (colocated)
- Integration tests: `testing/custom/`
- E2E tests: `testing/e2e/`
- Fixtures: `testing/fixtures/`

### Test Structure
```typescript
describe('ResourceService', () => {
  describe('create', () => {
    it('creates resource with valid data', async () => { })
    it('throws on invalid data', async () => { })
  })
})
```

### What to Test
- ✅ Service layer logic
- ✅ API route handlers
- ✅ Custom hooks
- ✅ Utility functions
- ⚠️ Components (only complex logic)
- ❌ Prisma queries (trust the ORM)

---

## DOCKER

### Commands
```bash
# Start everything
docker compose up -d

# Rebuild from scratch (must work!)
docker compose down -v && docker compose up -d

# View logs
docker compose logs -f [service]

# Database shell
docker compose exec db psql -U postgres
```

### Container Names
Use explicit names: `[project]-db`, `[project]-app`

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

## TOKEN EFFICIENCY

### Principles
- Right model for right task
- Don't repeat context unnecessarily
- Load agents/skills on demand
- Keep responses focused

### Context Management
- Check `_build/context/` for pre-built patterns
- Use slash commands to load what you need
- Don't ask for files already in context

---

## PROJECT-SPECIFIC

### Key Files
- PRD: `_build/docs_build/PRD/`
- Architecture: `_build/docs_build/architecture/`
- Current Phase: `_build/prompts/[phase]/`

### Current Focus
[Describe current development phase or focus area]

### Known Issues
[List any known issues or tech debt items]

---

## SLASH COMMANDS

| Command | Purpose |
|---------|---------|
| `/wf-test` | Run full test suite |
| `/wf-build` | Build the project |
| `/rv-code` | Trigger code review agent |
| `/cx-load [name]` | Load context module |
| `/ag-fix` | Trigger remediator agent |

---

## LAYERED CLAUDE.md

This project uses layered CLAUDE.md files:
- `./CLAUDE.md` - This file (global rules)
- `./src/CLAUDE.md` - Source code patterns
- `./prisma/CLAUDE.md` - Database conventions
- `./testing/CLAUDE.md` - Test framework usage

Check subdirectory CLAUDE.md files for specific guidance.
