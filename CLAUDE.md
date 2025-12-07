# Project: sparkq

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
