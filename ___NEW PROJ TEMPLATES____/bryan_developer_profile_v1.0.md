# Bryan Luce — Developer Profile v1.0

> **Purpose**: Context document for AI assistants working on Bryan's projects  
> **Version**: 1.0  
> **Last Updated**: December 2024  
> **Use**: Include in project knowledge for consistent context across sessions

---

## Who I Am

**Name**: Bryan Luce  
**Role**: CEO, Appmelia (startup) | Infrastructure Architect | AI-Assisted Developer  
**GitHub**: [lucebryan3000](https://github.com/lucebryan3000) (personal, private repos)  
**Company**: [Appmelia](https://github.com/appmelia-ai) (team repo)  
**Location**: Central Time Zone (CST)  
**Background**: 10+ years infrastructure (VMware, Cisco, Microsoft, Azure, AWS), 25 certifications, MSP engineer → general manager

---

## Global Principles

**These apply to EVERYTHING:**

| Principle | Meaning |
|-----------|---------|
| **Quality over speed** | Do it right, not fast. Take the extra time. |
| **One notch above baseline** | Above average defaults, not bare minimum |
| **Resources are not an issue** | Codeswarm has 128GB RAM, 16 cores, RTX 3080 — use them |
| **Velocity matters** | But not at the cost of quality or creating tech debt |
| **Best practices by default** | Unless there's a good reason not to |
| **No fake data, no placeholders** | Real work only |
| **Disposable dev tooling** | Project-local, copy-in, delete at MVP. Prefer lightweight over frameworks. Tools accelerate, not accumulate. |

---

## My Development Approach

### What I Do vs What AI Does

| I Do | AI Does |
|------|---------|
| Design systems and architecture | Write implementation code |
| Create PRDs/FRDs/specs | Execute against specs |
| Write prompts for Claude Code | Generate code from prompts |
| UAT and validation | Unit tests and automation |
| Scope features and guardrails | Follow guardrails precisely |
| Know what good looks like | Produce the output |

**I am not a hands-on coder** — I direct AI to write code. I can read and understand code, but I don't write it from scratch. I have deep infrastructure knowledge and know the art of the possible.

### AI Workflow & Task Dispatch

**Design Goal:** Right model, right scope, right constraints. Single-pass execution is the target. Parallel execution is the multiplier.

#### Tiered Pipeline (Conceptual Overview)

```
┌─────────────────────────────────────────────────────────────────┐
│  DESIGN TIER (Strategic) — Opus                                 │
│  PRD/FRD creation, architecture, prompt engineering             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  EXECUTION TIER (Implementation) — Sonnet                       │
│  Execute prompts, orchestrate Codex/Haiku, integration          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PARALLEL TIER (Offload) — Codex + Haiku                        │
│  Codex: Heavy codegen ($0) | Haiku: Quick validation            │
└─────────────────────────────────────────────────────────────────┘
```

#### Spec-Driven Development Process

1. **Design** PRD/FRD with Opus
2. **Generate** implementation prompts as .md files
3. **Execute** prompts in batches
4. **Test** via automated test suite
5. **UAT** manually in terminal
6. **Summarize** completed batches
7. **Archive** old prompts (tarball to exclude from context)
8. **Repeat** with next feature batch

#### The Complete Orchestration Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: PLANNING (Opus)                                        │
│  - PRD/FRD creation, architecture decisions                     │
│  - Generate detailed prompts for execution tier                 │
│  - Output: Implementation-ready .md prompt files                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: ORCHESTRATION (Sonnet)                                 │
│  - Read specs, generate Codex prompts                           │
│  - Coordinate parallel execution                                │
│  - Integration and git operations                               │
│  - Cost: Primary token spend (worth it for quality prompts)     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: EXECUTION (Codex) — PARALLEL                           │
│  - All code generation from detailed specs                      │
│  - Run multiple instances simultaneously                        │
│  - Cost: $0 Claude tokens (separate subscription)               │
│  - DO NOT WAIT — execute in background                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: VALIDATION (Haiku)                                     │
│  - Syntax validation, import checks                             │
│  - Placeholder detection (TODO, FIXME)                          │
│  - Quick sanity tests                                           │
│  - Cost: Cheap, fast, disposable                                │
└─────────────────────────────────────────────────────────────────┘
```

#### Model Selection Matrix

| Model | Use For | Never Use For |
|-------|---------|---------------|
| **Opus** | PRD/FRD, architecture, prompt creation, strategic decisions | Code execution, simple tasks |
| **Sonnet** | Orchestration, prompt generation for Codex, integration, git ops, complex reasoning | Pure code generation (use Codex), simple validation (use Haiku) |
| **Codex** | All code generation from spec, boilerplate, CRUD, CLI, schemas, tests, docs, UI components | Architectural decisions, ambiguous requirements |
| **Haiku** | Syntax validation, import checks, placeholder detection, quick searches, file stats, log scanning | Exploratory analysis, code generation, reasoning |

#### Output Constraints by Task Type

**128K is the environment ceiling.** Match verbosity to task, not token count.

| Task Type | Model | Output Constraints |
|-----------|-------|-------------------|
| Simple validation | Haiku | Structured output only |
| Quick search/check | Haiku | Results only, no explanation |
| Standard feature | Sonnet/Codex | No comments unless non-obvious |
| Multi-file implementation | Codex | Implementation only, no prose |
| Complex integration | Sonnet | Minimal explanation |
| Comprehensive (rare) | Sonnet | Explicit constraints required |

#### Haiku Use Cases (15 Automatic Delegations)

Sonnet automatically delegates these to Haiku without asking:

1. **Syntax validation** — Running `python -m py_compile` on generated code
2. **Import resolution checks** — Verifying all imports are valid
3. **Placeholder detection** — Finding TODO, FIXME, NotImplementedError
4. **Quick file searches** — Simple grep/glob operations for specific files/keywords
5. **File structure verification** — Checking if files exist at expected paths
6. **Output summarization** — Condensing long command outputs
7. **Simple code lookups** — Finding where a function/class is defined (needle queries)
8. **Quick sanity tests** — Running basic test commands
9. **Log file scanning** — Searching for errors in logs
10. **Configuration file validation** — Checking YAML/JSON syntax
11. **Dependency list generation** — Extracting imports from files
12. **Line count checks** — Simple file statistics
13. **Recent file activity** — Finding recently modified files
14. **Git status checks** — Quick branch/status queries
15. **Simple text transformations** — Basic find/replace operations

**Detection patterns:** "find all files that...", "check if X exists...", "validate syntax...", "search for [keyword]..."

**Exception:** Do NOT use Haiku for exploratory codebase analysis (use Sonnet with reasoning).

#### Codex Use Cases (15 Automatic Delegations)

Sonnet automatically delegates these to Codex ($0 cost) without asking:

1. **API endpoint implementation** — Complete REST/HTTP handlers from spec
2. **Database model creation** — SQLAlchemy/Pydantic model generation
3. **CLI command scaffolding** — Click/argparse command implementations
4. **CRUD operation boilerplate** — Create/read/update/delete functions
5. **UI component generation** — HTML templates, Bootstrap components
6. **Schema definitions** — SQL DDL, JSON Schema, type definitions
7. **Test file generation** — pytest test cases from specifications
8. **Configuration file templates** — YAML/JSON/TOML config generation
9. **Utility function libraries** — Helper functions from requirements
10. **Form validation logic** — Input validation and error handling
11. **Data transformation pipelines** — ETL-style data processing
12. **API client wrappers** — HTTP client code for external APIs
13. **Migration scripts** — Database schema migrations
14. **Documentation generation** — README, API docs, usage examples
15. **Bash utility scripts** — Setup, teardown, deployment scripts

**Detection patterns:** "create a new [file]...", "implement [feature]...", "generate [artifact]...", "write a function that...", "scaffold [structure]..."

**Prerequisites:** Clear specification exists, no architectural decisions needed, pattern-based generation.

#### Automatic Delegation Rules

**Sonnet delegates without asking permission:**

| Task Pattern | Delegate To | Announce |
|--------------|-------------|----------|
| Simple search/check/validation | Haiku | "Using Haiku for quick search..." |
| Pure code generation from spec | Codex | "Delegating to Codex for implementation..." |
| Reasoning/orchestration required | Stay in Sonnet | (no announcement) |

**User override:** If user explicitly requests a specific model, honor that request.

#### Iteration Thresholds

| Task Complexity | Expected Passes | Review Threshold |
|-----------------|-----------------|------------------|
| Simple tasks | 1 pass | 2+ cycles |
| Standard features | 1-2 passes | 3+ cycles |
| Complex multi-file | 2-3 passes | 4+ cycles |

Prompts exceeding thresholds → decompose, add context, or reduce scope.

#### Output Constraints (Include in Prompts)

| Constraint | When to Use | Example |
|------------|-------------|---------|
| **Max tokens** | Prevent runaway output | `Limit response to 2000 tokens` |
| **No prose** | Code-only tasks | `Implementation only, no explanatory text` |
| **No comments** | Clean code preference | `No comments unless logic is non-obvious` |
| **Structured output** | Parseable results | `Respond in JSON format only` |
| **Line limits** | Focused changes | `Max 50 lines per file modification` |

**Constraint stacking example:**
```markdown
## Constraints
- Max 4000 tokens
- No comments unless non-obvious
- No explanatory prose
- Implementation only
- One file at a time
```

#### Batch Design Principles

| Principle | Target | Why |
|-----------|--------|-----|
| **Parallelization** | >70% of tasks parallel | Wall-clock time, not sequential time |
| **Dependency minimization** | <3 sequential batches | Maximize concurrent execution |
| **Batch size** | Manageable for context window and single review session | Fits working memory, enables focused review |

**Batch types:**
- **Sequential:** Task X MUST complete before task Y starts
- **Parallel:** Independent tasks run simultaneously
- **Hybrid:** Sequential foundation → parallel features → validation

#### Token Budget Tracking (Optional)

Token tracking is available for optimization analysis if costs seem high. Not required for routine work.

| Metric | When to Track |
|--------|---------------|
| Sonnet tokens | Debugging unexpectedly high costs |
| Haiku tokens | Usually negligible, skip |
| Codex cost | $0 (separate subscription) |
| Wall-clock time | If phase seems slow |

Subscription-first principle means routine token tracking is unnecessary.

#### Codex Prompt Format

```bash
codex exec --full-auto -C /path/to/project "
Context: [Phase/feature description]

Task: [Specific code generation task]

File to create/modify: [exact relative path]

Requirements:
- [Requirement 1 - specific and testable]
- [Requirement 2 - specific and testable]

Specification:
[Complete spec: signatures, structure, imports, error handling]

Validation:
- [Exact command to verify]
- [Expected output]
"
```

**Execute in background** — don't wait for completion.

---

## Subscriptions & Access

| Service | Plan | Cost | Use |
|---------|------|------|-----|
| Claude | Max | $200/month | Primary dev (20+ hrs/week) |
| OpenAI | GPT Pro | $200/month | Codex CLI for heavy codegen |
| Gemini | Access | — | Available, secondary |
| GitHub | Personal + Org | — | Private repos default |

### Subscription-First Principle (Preference)

**No API credits in dev** — subscriptions only. API credits reserved for production software.

| Context | Approach |
|---------|----------|
| Development | Maximize subscription value ($400/mo combined) |
| Testing | Use subscription tiers, not metered API |
| Production | API credits for customer-facing features only |
| Experimentation | Subscription headroom absorbs exploration |

**Rationale:** Fixed-cost subscriptions enable unlimited iteration without token anxiety. Squeeze maximum value from the monthly investment before considering API costs.

### Development Environment

| Component | Setup |
|-----------|-------|
| **Dev Server** | Remote Linux server ("codeswarm") |
| **Access** | VS Code Remote SSH |
| **Editor** | VS Code with Claude Code (panel) |
| **AI Chat** | Copilot Chat (sidebar, secondary) |
| **Terminal AI** | Codex CLI for heavy codegen |
| **Local Editor** | micro (for quick edits) |

**Typical workflow:** SSH into codeswarm via VS Code Remote → Claude Code in panel for primary AI → Codex CLI in terminal for bulk generation.

---

## Development Server: Codeswarm

### Hardware Specs

| Component | Spec |
|-----------|------|
| Platform | Alienware Aurora R13 Desktop |
| CPU | Intel Core i9-12900F (16 cores / 24 threads, 5.1 GHz max) |
| Memory | 128 GB RAM (typically ~3 GB used, 120+ GB available) |
| GPU | NVIDIA GeForce RTX 3080 (10 GB VRAM) |
| Storage | 900 GB root (ext4), 1.8 TB NVMe data, additional drives |
| BIOS | 1.20.0 (2024-05-29) |

### Software Environment

| Component | Version/Details |
|-----------|-----------------|
| OS | Ubuntu 25.04 (Plucky) — bleeding edge, non-LTS |
| Kernel | 6.14.0-36-generic |
| Docker | 28.2.2 with Compose |
| Node.js | via npm 10.8.2 |
| Python | 3.13 (pip 25.0) |
| Rust | 1.91.1 (cargo available) |
| NVIDIA Driver | 580.95.05 |

### Networking

| Interface | Address | Purpose |
|-----------|---------|---------|
| enp4s0 | 192.168.1.150 | Primary LAN |
| wg0 | 10.0.0.1/24 | Wireguard VPN |
| tailscale0 | 100.86.53.79 | Tailscale mesh |
| docker0 | 172.17.0.1/16 | Docker default bridge |

### Access Pattern

- **Primary**: SSH from Mac (iTerm2) via multiple devices
- **Devices**: MacBook Air M3, Mac Studio M1 Max (3× 41" monitors), Lenovo Chromebook 5i
- **Mobile**: WebSSH via iPhone after Wireguard connect
- **Session persistence**: TMUX installed — queues keep running if connection drops
- **IDE**: VS Code Remote-SSH

---

## Project Organization

### Directory Structure

```
/home/luce/apps/           # Project root — one folder per project
├── sparkqueue/            # SparkQ (current)
├── bloom2/                # Other project
├── melissa.ai/            # Other project
└── [project-name]/        # Lowercase, sometimes dots for proper nouns

/home/luce/apps/[project]/
├── _build/                # Build artifacts and prompts
│   ├── PRD/               # Product requirements docs
│   ├── Prompts/           # Claude Code prompts (.md files from Opus)
│   ├── Codex/             # Prompts for OpenAI Codex via CLI
│   ├── Phase_Summary_X-Y.md  # Summarize every 6-10 prompts
│   └── tech-debt.md       # Known shortcuts to address
├── docker-compose.yml     # Every project has one
├── src/                   # Source code
├── testing/               # Dynamic test framework
└── ...
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Project folders | Lowercase, minimal separators | `sparkqueue`, `bloom2`, `melissa.ai` |
| Database name | Match project name | `sparkqueue` |
| Branches | `feature/<name>` for major features | `feature/quick-add` |
| Files | Lowercase with dashes | `phase-summary-1-10.md` |
| Backup dates | MM-DD-YYYY format | `backup-12-06-2024.sql` |

---

## Project Structure Standards

### Root Directory (Only These Files)

| File | Purpose |
|------|---------|
| `CLAUDE.md` | AI instructions |
| `README.md` | Project overview |
| `package.json` | Node.js manifest |
| `tsconfig.json` | TypeScript config |
| `next.config.js` | Next.js config |
| `tailwind.config.js` | Tailwind config |
| `docker-compose.yml` | Docker services |
| `Dockerfile` | Container build |
| `.env*` | Environment files |
| `.secrets.yaml` | Encrypted secrets |
| `.*rc` / `.*ignore` | Tool configs |

### Standard Folder Structure

```
project/
├── .claude/                 # Claude Code config
│   ├── settings.json        # Project settings (in git)
│   ├── settings.local.json  # Personal overrides (NOT in git)
│   ├── commands/            # Slash commands (in context)
│   ├── agents/              # Subagents (EXCLUDED, loaded on demand)
│   └── skills/              # Agent Skills (EXCLUDED, loaded on demand)
├── .codex/                  # OpenAI Codex config
├── .vscode/                 # VS Code settings
│
├── _build/                  # YOUR workspace (EXCLUDED - read on demand)
│   ├── docs_build/          # PRD, FRD, architecture, decisions, diagrams, references, reviews
│   ├── prompts/             # Opus-created phase prompts
│   │   ├── foundation/
│   │   │   └── _completed/
│   │   └── api/
│   │       └── _completed/
│   ├── chats/               # AI communication (prefixed: claude-*, codex-*, etc.)
│   ├── playbooks/           # Automation playbooks (persistent)
│   ├── context/             # Pre-built loadable context (persistent)
│   ├── summaries/           # Phase completion summaries
│   ├── backups/
│   │   ├── snapshots/       # Point-in-time state captures
│   │   └── archive/         # Tarballed old content
│   └── tech-debt.md
│
├── docs/                    # App documentation (EXCLUDED)
├── prisma/                  # Database (in context)
├── public/                  # Static assets
├── scripts/                 # General utility scripts
│   └── claude/              # Claude-specific scripts (in context)
│
├── src/                     # ALL source code (in context)
│   ├── app/                 # Next.js pages & API
│   ├── components/          # React components
│   ├── hooks/               # Custom hooks
│   ├── lib/                 # Core utilities
│   ├── services/            # Business logic
│   ├── types/               # TypeScript types
│   └── styles/
│
└── testing/                 # Test framework
    ├── framework/           # Auto-discovery (in context)
    ├── fixtures/            # Test data (in context)
    ├── e2e/flows/
    └── custom/
```

### Context Rules

| Folder | In Context | Why |
|--------|------------|-----|
| `src/` | ✅ Yes | Active code |
| `prisma/` | ✅ Yes | Schema matters |
| `testing/framework/` | ✅ Yes | Test patterns |
| `testing/fixtures/` | ✅ Yes | Test data |
| `scripts/claude/` | ✅ Yes | Claude executes |
| `.claude/commands/` | ✅ Yes | Slash commands |
| `.claude/agents/` | ❌ No | Load via slash command |
| `.claude/skills/` | ❌ No | Load on demand |
| `_build/*` | ❌ No | Read on demand |
| `docs/` | ❌ No | Reference only |
| `node_modules/` | ❌ No | Never |
| `.git/` | ❌ No | Never |
| `*.tar.gz` | ❌ No | Archived |

### `_build/` Folder Structure (EXCLUDED from context)

```
_build/
├── docs_build/                  # ALL build-related documentation
│   ├── PRD/                     # Product requirements
│   ├── FRD/                     # Feature requirements
│   ├── architecture/            # Architecture docs
│   ├── decisions/               # ADRs - why we chose X
│   ├── diagrams/                # Mermaid, visuals
│   │   └── exports/             # PNG exports
│   ├── references/              # External docs, research
│   ├── reviews/                 # UAT feedback, retrospectives
│   └── backlog.md
│
├── prompts/                     # Opus-created phase prompts
│   ├── foundation/
│   │   └── _completed/
│   ├── api/
│   │   └── _completed/
│   └── ...
│
├── chats/                       # AI communication (ephemeral, prefixed)
│   ├── claude-*.md              # Claude one-offs
│   ├── codex-*.md               # Codex prompts/responses
│   ├── gemini-*.md              # Gemini tasks
│   └── copilot-*.md             # Copilot tasks
│
├── playbooks/                   # Automation playbooks (persistent)
├── context/                     # Pre-built loadable context (persistent)
├── summaries/                   # Phase completion summaries
│
├── backups/
│   ├── snapshots/               # Point-in-time state captures
│   └── archive/                 # Tarballed old content
│
└── tech-debt.md
```

### `_build/` Folder Purposes

| Subfolder | Purpose | Lifecycle |
|-----------|---------|-----------|
| `docs_build/` | PRD, FRD, architecture, decisions, diagrams, references, reviews, backlog | Evolves, may merge/archive |
| `prompts/` | Phase prompts from Opus (phase folders with `_completed/`) | Summarize & archive at 10 |
| `chats/` | AI communication (claude-*, codex-*, gemini-*, copilot-*) | Delete after use |
| `playbooks/` | Automation playbooks (pre-filled) | Persistent |
| `context/` | Pre-built loadable context modules | Persistent |
| `summaries/` | Phase completion & major work summaries | Persistent |
| `backups/snapshots/` | Pre-refactor state captures | Delete when confident |
| `backups/archive/` | Tarballed old prompts, chats | Persistent backup |

### Playbook Pattern

Playbooks live in `_build/playbooks/`, executed via slash commands:

```
/docs-cleanup     → Reads _build/playbooks/docs-cleanup.md, executes
/phase-summarize  → Summarizes phases, tarballs old prompts
/context-audit    → Checks for context bloat
/test-audit       → Finds test coverage gaps
```

### Prompt Naming Convention

```
[phase]-[##]-prompt-[description].md

Examples:
foundation-01-prompt-setup-project.md
api-05-prompt-task-quick-add.md
ui-03-prompt-quickadd-component.md
```

### Prompt Organization

```
_build/prompts/
├── foundation/                      # Phase folder
│   ├── foundation-01-prompt-setup-project.md
│   ├── foundation-02-prompt-database-schema.md
│   └── _completed/                  # Move here after execution
│       └── foundation-01-prompt-setup-project.md
├── api/
│   └── _completed/
├── ui/
│   └── _completed/
└── polish/
    └── _completed/
```

**After prompt execution:**
1. Claude self-tests (MUST pass before UAT)
2. Move prompt to `_completed/` folder
3. Continue to next prompt

### Phase Prompt Organization

Projects typically start with 10-12 phases, expand to 20+. Each phase gets a folder.

```
_build/prompts/
├── phase-01-foundation/
│   ├── 01-setup-project.md
│   ├── 02-database-schema.md
│   └── 03-docker-setup.md
├── phase-02-api/
├── ...
├── phase-10-polish/
│
# After phase 10 complete:
# 1. Create _build/summaries/Phase_Summary_01-10.md
# 2. Tarball: prompts-phase-01-10.tar.gz
# 3. Move to _build/archive/
```

### HARD RULE: File Placement

| File Type | Correct Location |
|-----------|------------------|
| React components | `src/components/[domain]/` |
| Pages | `src/app/[route]/page.tsx` |
| API routes | `src/app/api/[route]/route.ts` |
| Utility functions | `src/lib/utils/` |
| Type definitions | `src/types/` |
| Test files | `testing/` |
| Shell scripts | `scripts/` |
| Claude automation | `scripts/claude/` |
| App documentation | `docs/` |
| Build documentation | `_build/docs_build/` |
| Phase prompts | `_build/prompts/phase-XX/` |
| Summary markdown | ❌ DON'T CREATE IN ROOT |

### Layered CLAUDE.md Files

```
project/
├── CLAUDE.md                # Root: global rules
├── src/CLAUDE.md            # Code patterns
├── prisma/CLAUDE.md         # Database conventions
├── testing/CLAUDE.md        # Test framework usage
└── scripts/CLAUDE.md        # Script conventions
```

---

## .claude/ Folder Configuration

### Folder Structure

```
.claude/
├── settings.json            # Project settings (CHECKED INTO GIT)
├── settings.local.json      # Personal overrides (NOT in git, auto-ignored)
│
├── commands/                # Slash commands (IN context, small)
│   ├── build.md             # /build
│   ├── test.md              # /test
│   ├── commit.md            # /commit
│   ├── docs-cleanup.md      # /docs-cleanup → runs playbook
│   ├── phase-summarize.md   # /phase-summarize → runs playbook
│   ├── context-load.md      # /context-load [name]
│   ├── codex-send.md        # /codex-send [task]
│   └── review.md            # /review → triggers agent
│
├── agents/                  # Subagents (EXCLUDED, loaded on demand)
│   ├── code-reviewer.md     # Code review specialist
│   ├── test-writer.md       # Test creation specialist
│   ├── remediator.md        # Bug fix specialist
│   ├── codex-handoff.md     # Creates Codex prompts
│   └── documenter.md        # Documentation specialist
│
└── skills/                  # Agent Skills (EXCLUDED, loaded on demand)
    └── self-test/
        └── SKILL.md         # Self-testing workflow
```

### settings.json Template

**File:** `claude_settings_template.json`

#### Key Settings Summary

| Setting | Value | Purpose |
|---------|-------|---------|
| `defaultMode` | `bypassPermissions` | Full velocity, no prompts |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 128000 | Max capacity for complex tasks |
| `CLAUDE_MAX_READ_FILES` | 1000 | Small projects, prevent overload |
| `BASH_MAX_TIMEOUT_MS` | 600000 (10 min) | Long operations |
| `COMMIT_BATCH_SECONDS` | 600 (10 min) | Reasonable batching |
| `SKIP_TESTS` | 0 | Tests enabled (self-test rule) |
| `DISABLE_COST_WARNINGS` | 0 | Show token usage |
| `alwaysThinkingEnabled` | true | Better reasoning |

#### 128K Output Strategy

The 128K limit is a **ceiling, not a floor**. Claude uses only what's needed:
- Simple tasks: ~500-2000 tokens
- Standard features: ~5000-15000 tokens  
- Complex multi-file: ~30000-60000 tokens
- Maximum comprehensive: up to 128000

**To maximize effectiveness with high output limit, include in prompts:**
```markdown
## Constraints
- No comments unless logic is non-obvious
- No explanatory prose in code
- Implementation only, no "here's what I did" summaries
```

### Two-Tier Context System

| Mechanism | What it does | Claude can still... |
|-----------|--------------|---------------------|
| `.claudeignore` | Excludes from auto-loaded context | Search, read, cat, grep |
| `additionalDirectories` | **Hard blocks** ALL access | Nothing - completely invisible |

### Hooks (PostToolUse Only — Reliable)

| Matcher | Action | Behavior |
|---------|--------|----------|
| `*.ts`, `*.tsx`, `*.js`, `*.jsx` | eslint --fix | Auto-fix, silent fail |
| `prisma/schema.prisma` | prisma format | Auto-format |
| `*.sh` | bash -n | Syntax check, report errors |
| `*.json` | json.tool | Validate, report errors |
| `*.yaml`, `*.yml` | yaml.safe_load | Validate, report errors |
| `docker-compose.yml` | compose config | Validate compose file |

**Hook Pattern:** `command 2>/dev/null || true` — Silent success, report only errors.

### Agent Template (YAML Frontmatter)

```markdown
---
name: code-reviewer
description: Expert code reviewer for quality, security, and maintainability. Use when reviewing code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a senior code reviewer...
[System prompt for the agent]
```

### Command Template

```markdown
# /test

Run the full test suite and report results.

## Instructions
1. Run `npm test`
2. If pass: Report "✅ All tests passing"
3. If fail: Show errors, trigger remediator agent
4. Re-run until passing or escalate to Codex

## HARD RULE
Self-test first. Only ask for UAT after tests pass.
```

### Skill Template (SKILL.md)

```markdown
---
name: self-test
description: Run automated tests and remediate failures before UAT.
---

# Self-Test Skill

## Workflow
1. Run `npm test`
2. If passing → Ready for UAT
3. If failing → Remediate immediately
4. Loop until passing or escalate
```

---

## Tech Stack (Approved Defaults)

### Core Stack

| Layer | Technology | Why |
|-------|------------|-----|
| **Runtime** | Node.js + TypeScript | Type safety, better stability with AI assistance |
| **Frontend** | Next.js | Modern React, API routes built-in |
| **Styling** | Tailwind CSS | Fast, utility-first |
| **UI Components** | shadcn/ui + Radix | Own the code + accessible primitives |
| **State (Local)** | React useState/useReducer | Built-in |
| **State (Global)** | Zustand | When needed — tiny, simple |
| **Data Fetching** | SWR | Caching, revalidation |
| **Forms** | React Hook Form + Zod | Performant + type-safe validation |
| **Database** | PostgreSQL | Proper migrations, reliable |
| **ORM** | Prisma | Type-safe, great DX |
| **Container** | Docker Compose | Every project uses it |
| **Dates** | date-fns | Modular, tree-shakeable |
| **Icons** | Lucide React | Clean, consistent |
| **IDs** | nanoid | Tiny, fast |
| **Classnames** | clsx | Conditional Tailwind |
| **Validation** | Zod | TypeScript-first |
| **Testing** | Jest + Playwright + Puppeteer | Full coverage |

### Banned Packages (Never Use)

| Package | Why |
|---------|-----|
| Moment.js | Huge, deprecated |
| Axios | Unnecessary — fetch + SWR covers it |
| Material UI (MUI) | Massive, corporate feel |
| Redux | Overkill — Zustand is simpler |
| Formik | Outdated |
| Lodash (full) | Usually unnecessary |
| Ant Design | Enterprise bloat |
| jQuery | It's 2024 |

### Ask Before Adding

- Package >100KB
- <1000 GitHub stars
- Overlaps existing package
- New state management lib
- New UI component library

---

## Hard Rules (Non-Negotiable)

These are violations. Stop and fix immediately.

| Rule | Detail |
|------|--------|
| **No fake data, no placeholders** | Do the real work. Realistic examples only. |
| **No shortcuts without documentation** | Log in `_build/tech-debt.md` if you must cut corners |
| **No orphan TODOs** | Create a task or do it now |
| **No nuking working code** | Verify dependencies exist before bulk delete. Use feature branch for risky changes. |
| **No permission prompts** | Full auto-approve. Execute without asking. |
| **No enterprise patterns** | No RBAC, multi-tenant, distributed systems unless asked |
| **No wasting tokens** | Don't re-read files you wrote. Don't explain, just do. |
| **No markdown sprawl** | No IMPLEMENTATION_SUMMARY.md or "what I did" files |
| **Self-test before UAT** | Run tests, confirm passing, remediate failures — THEN ask for UAT. See Self-Testing Rule below. |
| **No inline explanation preamble** | Execute directly without "here's what I'm going to do" lead-ins. Action first, brief summary after. |
| **Docker Compose is mandatory** | Every project must have a working `docker-compose.yml`. No bare-metal setups for anything that persists data. |
| **128K output with verbosity control** | High output limits require explicit constraints: "No comments unless non-obvious, no explanatory prose, implementation only." |

### Self-Testing Rule (Critical)

**Before asking Bryan for UAT, Claude MUST:**
1. Write the code
2. Run automated tests (Jest, Playwright, Puppeteer)
3. Confirm tests pass
4. If tests fail → remediate immediately
5. Re-run tests until passing
6. ONLY THEN → prompt for UAT

**Claude does NOT:**
- Ask "can you test this?" before running tests itself
- Say "please verify this works" without testing first
- Expect Bryan to find bugs Claude could have caught

**Claude CAN:**
- Use Codex for remediation help (Sonnet creates prompts for Codex)
- Run multiple test cycles
- Take time to get it right

**UAT is for:** Confirming human experience, UX feel, edge cases tests can't catch  
**UAT is NOT for:** Finding bugs the test suite should have caught

---

## Execution Rules (How to Work)

| Rule | Detail |
|------|--------|
| **Parallel when possible** | Independent tasks run in parallel |
| **Sonnet orchestrates, doesn't wait** | Continue with other work if Codex is slow |
| **Max hardware utilization** | Use the 128GB RAM, 16 cores, RTX 3080 |
| **Sequence prompts correctly** | Follow order in .md files |
| **Self-healing apps** | Restart logic, health checks, graceful degradation |
| **Hot reload in dev** | Changes reflect immediately |

---

## Failure Protocol

When things don't work as expected:

| Scenario | Action |
|----------|--------|
| Tests fail repeatedly | Decompose task, add context, or try different approach |
| Iteration threshold exceeded | Flag in output, try decomposition. If stuck after 2 more attempts → escalate to Opus for prompt refinement → Codex for execution |
| Codex output unusable | Fall back to Sonnet for that task |
| Ambiguous requirements discovered mid-work | Make reasonable choice, note assumption, continue |

### Git Feature Branch Strategy

**For major changes, use feature branches:**

```
main (stable)
  └── feature/new-capability
        ├── Work iteratively
        ├── Success → merge to main
        └── Failure → abandon branch, start fresh
```

**Benefits:**
- No complex rollback logic — just `git checkout main`
- Clean history — failed experiments don't pollute main
- Safe experimentation — break things without consequence

**When to use feature branches:**
- Batch prompt execution (multiple .md files)
- Multi-file refactors
- Experimental or uncertain approaches

**Direct to main:**
- Single feature from clear spec
- Routine changes and bug fixes

---

## Decision Boundary (When to Ask)

**Default:** Autonomous execution. Don't ask permission.

### Don't Ask (Just Do It)

- Code generation from specs
- Running tests
- File creation/modification within scope
- Standard patterns and conventions
- Bug fixes with clear cause
- Formatting and linting
- Git commits within session

### Do Ask (Pause and Confirm)

- Destructive operations on user data
- Database schema changes in production
- Architectural pivots (replacing major technologies not requested in spec — e.g., swapping frameworks, changing API paradigms)
- Ambiguous requirements with multiple fundamentally different interpretations affecting architecture

### Notify But Proceed

- **Scope expansion:** If user requests something beyond original spec, proceed and offer to update PRD/FRD to reflect new scope. Don't block.
- **Iteration threshold exceeded (3+ cycles):** Flag in output, try decomposition or different approach. If still stuck after 2 more attempts, escalate to Opus for prompt refinement → Codex for execution.

---

## Git Workflow

### Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<name>` | `feature/quick-add` |
| Bug fix | `fix/<name>` | `fix/queue-timeout` |
| Refactor | `refactor/<name>` | `refactor/storage-layer` |
| Experiment | `experiment/<name>` | `experiment/new-ui` |

### Commit Standards

**Commit when:**
- Meaningful unit of work complete (not mid-thought)
- Tests pass
- 300+ lines changed OR 90+ minutes elapsed

**Commit message format:**
```
<type>: <short description>

[Optional body with details]

[Optional footer with breaking changes or issue refs]
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

**Examples:**
```
feat: add task timeout enforcement
fix: resolve queue peek returning stale data
refactor: extract storage operations to dedicated module
```

### Feature Branch Workflow

```bash
# Start new feature
git checkout -b feature/new-capability

# Work iteratively, commit often
git add . && git commit -m "feat: implement core logic"

# Success path
git checkout main
git merge feature/new-capability
git branch -d feature/new-capability

# Failure path
git checkout main
git branch -D feature/new-capability  # Abandon and start fresh
```

---

## Communication Standards

### Reporting Format

| Marker | Meaning | When to Use |
|--------|---------|-------------|
| ✅ **Tests pass** | All tests green | One line, don't list passing tests |
| ❌ **Fixed** | Issue found and resolved | One line per fix |
| ⚠️ **Warning** | Non-blocking issue | List with brief context |
| 🛑 **Blocked** | Cannot proceed with remaining phase work | Detailed — truly stuck |
| ❓ **User Verification Needed** | Requires human judgment | UX, visual design, domain questions |

### Success Reporting

No news is good news. Only surface problems.

```
✅ Tests pass.
```

If there were warnings or errors that got fixed, append them:

```
✅ Tests pass.
⚠️ Fixed: Missing null check in TaskService.getById()
⚠️ Fixed: Import order lint error
```

### Error Reporting

**Fixed issues (one line each):**
```
❌ Fixed: [issue] → [solution]
```

**Blocked (truly cannot proceed with remaining phase work):**
```
🛑 Blocked: [What's stuck]
- Attempted: [What was tried]
- Needed: [What would unblock]
```

Blocked is rare — most issues can be fixed interactively and just noted as "Fixed."

---

## Documentation Guidance

### What to Create

Bias toward brevity. If it won't be read, don't write it.

| Document Type | Create When | Format |
|---------------|-------------|--------|
| Phase summaries | Batch of work complete | Outcomes, files changed, decisions — not narrative |
| Tech debt log | Shortcuts that affect future work | One line per item (skip minor compromises) |
| README | AI context needed | Architecture, decisions, backlog, file index |
| CLAUDE.md updates | Patterns discovered within PRD/FRD scope | Actionable rules |

### README Purpose (AI Context)

README is for AI orientation, not public documentation:
- Current architecture state
- Key decisions made
- Backlog overview
- Tech debt summary
- File index with purposes
- Where to start for common tasks

Reduces search time, faster orientation when starting work.

### Phase Summary Format

Structured for recall, not narrative:

```
## Phase [X] Complete

**Outcomes:**
- [Feature/capability now working]
- [Feature/capability now working]

**Files changed:** [list or count]

**Key decisions:** [if any were made]
```

NOT: Step-by-step story of how it was done.

### What NOT to Create

- Implementation summaries ("what I did" recaps)
- Verbose change logs
- Standalone explanation files
- Documentation that won't be referenced
- Passing test listings (no news is good news)

**If it won't be read, don't write it.** Screen output is preferred for transient information.

---

## Quality Rules

| Rule | Detail |
|------|--------|
| **Consistent patterns** | Once established, use everywhere |
| **One file = one purpose** | Split by responsibility, not line count |
| **No dumping grounds** | No `utils.ts`, name files specifically |
| **Real error messages** | What failed and why, not "something went wrong" |
| **Modern but simple** | Best practices without over-engineering |
| **Resilient by default** | Retry logic, timeouts, fallbacks |

---

## File Organization

### Size Guidance (Not Limits)

| Range | Status | Action |
|-------|--------|--------|
| <500 lines | Normal | Keep building |
| 500-800 lines | Typical | Fine if cohesive |
| 800-1000 lines | Large | Note it, continue |
| 1000+ lines | Review candidate | Add AUDIT comment |

**TypeScript is verbose.** Interfaces and types don't count toward complexity.

### Split When

- Two unrelated features in one file
- Copy-pasting identical code between files
- Clear domain boundary exists

### Don't Split When

- File is cohesive, just long
- Splitting creates circular imports
- You'd have 3 files that always change together

### Audit Tags

```typescript
// AUDIT:SPLIT - File handles both queue CRUD and task rendering
// AUDIT:REFACTOR - This switch has 12 cases, consider lookup table
// AUDIT:COMPLEXITY - Nested ternaries, hard to read
// AUDIT:DEBT - Hardcoded timeout, should come from config
```

Find all: `grep -rn "AUDIT:" ./src`

### Structure Within Files

```typescript
// === TYPES & INTERFACES ===
// === CONSTANTS ===
// === HOOKS / UTILITIES ===
// === MAIN EXPORT ===
// === INTERNAL HELPERS ===
```

---

## Git Standards

### Branch Strategy

| Situation | Action |
|-----------|--------|
| Building core (phases 1-80%) | Work on `main` |
| Starting major feature | Create `feature/<name>` |
| Feature complete + tested | Merge to `main`, delete branch |
| Multiple features parallel | Multiple branches open (fine) |

### Commit Frequency

| Trigger | Action |
|---------|--------|
| Feature/prompt batch complete | Commit with summary |
| ~300+ lines changed | Checkpoint |
| 90+ minutes elapsed | Checkpoint |
| Before switching branches | Commit first |
| End of session | Commit and push |

### Commit Messages

```
<type>: <short summary>

<bullet list of what changed>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

### What to Include in Repo (Private = Backup)

**YES:**
- `.env` (actual values)
- `.env.example`
- `docker-compose.yml`
- All config files
- `_build/` folder
- Database seed files
- Periodic DB exports
- `.vscode/settings.json`

**NO (.gitignore):**
- `node_modules/`
- `.next/`, `dist/`, `build/`
- `*.db`, `*.db-journal`
- `*.log`
- `*.tar.gz`
- `.DS_Store`

---

## Testing Standards

### Stack

| Tool | Purpose |
|------|---------|
| Jest | Unit, integration, API tests |
| Playwright | E2E flows |
| Puppeteer | Headless browser, visual testing |
| React Testing Library | Component rendering |

### HARD RULE: Self-Test Before UAT

**Claude must test its own work before asking for UAT:**
1. Write the code
2. Run automated tests
3. If fail → remediate immediately (use Codex if needed)
4. Re-run until passing
5. ONLY THEN → ask for UAT

**UAT is for:** Human experience, UX feel, edge cases  
**UAT is NOT for:** Finding bugs tests should catch

### When Tests Run

| Timing | Action |
|--------|--------|
| After each prompt | YES — Claude self-tests |
| End of queue | YES — full suite |
| Before merge to main | YES — must pass |
| Before asking for UAT | YES — must pass first |

### testing/fixtures/ Purpose

Auto-evolving test data used by automated test suite:
- Mock API responses
- Sample database records
- Test user data
- Component props for rendering tests

**These are used by Jest/Playwright/Puppeteer automatically.**  
NOT for manual testing. The suite uses them, Claude maintains them.

### Auto-Discovery Tests (All Enabled)

- Page renders without error
- Page has no console errors
- API routes return expected status
- API routes handle bad input
- Components render
- Database connects
- Migrations run
- Required env vars exist
- TypeScript compiles
- ESLint passes

### Timeouts (Generous)

| Timeout | Value | Rationale |
|---------|-------|-----------|
| Unit test | 30s | Some hit DB |
| E2E test | **5 minutes** | Tests documenting failures need time |
| Suite total | 15 minutes | Full suite with remediation |
| Page load | 60s | Slow pages happen |
| API request | 30s | Cold starts, complex queries |

**Rule:** Never fail a working process due to impatient timeout. Set timeouts at 3-5× average observed time.

### Remediation Workflow

```
Queue completes → Run npm test → Failures? → Codex fixes → Re-run → Pass? → Commit
```

### CI/CD

- **Now:** Skip GitHub Actions (save credits)
- **Later:** Add when production-ready

---

## Documentation Standards

### HARD RULE: No Unsolicited Markdown Files

**Claude Code must NOT create:**
- `IMPLEMENTATION_SUMMARY.md`
- `CHANGES.md`
- `PHASE_COMPLETE.md`
- `WHAT_I_DID.md`
- Any "summary of work" files

**If created → delete immediately.**

### Screen Output: YES

Brief, informative terminal output:
- What was implemented
- Key decisions
- What to test
- Teaching moments (1-2 sentences)

### Files Claude Code SHOULD Maintain

| File | When |
|------|------|
| Source code | Always |
| README.md | When asked or major milestone |
| Inline comments | When WHY isn't obvious |
| JSDoc on exports | On public APIs |
| Schema comments | On models |

### Files YOU Create (With Opus)

| File | Location |
|------|----------|
| PRD | `_build/PRD/` |
| Phase summaries | `_build/Phase_Summary_X-Y.md` |
| Tech debt log | `_build/tech-debt.md` |
| Prompts | `_build/Prompts/` |
| Codex prompts | `_build/Codex/` |

### Comment Standards

**DO comment:** Complex logic, workarounds, integration points, config values (why)

**DON'T comment:** What code does, every function, obvious variables

---

## Error Handling (Lean)

### Philosophy

Build first, observe later. Test suites catch errors, not verbose logging.

### During Build (0-80%)

- Let errors throw naturally
- Use test suite output for debugging
- Fix when tests fail
- No elaborate error recovery yet

### When to Add Logging

- App is 80%+ complete
- Specific feature is complex
- Production-bound code
- Debugging something tests can't catch

### User-Facing Errors

- Clear message: what failed, what to do
- No stack traces in UI
- No "something went wrong" without context

---

## Time & Logging Preferences

### Time Format

- **Display:** 12-hour format, CST (not UTC)
- **Filenames:** MM-DD-YYYY format

### Logging

- **Verbosity:** Minimal
- **Retention:** 3 days, then purge
- **Scripts:** Create logging scripts that also purge

### Notifications

- **v1.0:** Logs and UI only
- **Nice-to-have:** Email for unrecoverable failures
- **Later:** Slack integration

---

## Task Timing

See **Appendix A: Timeout & Timing Values** for specific numbers. These values are tuned from evidence and should be updated as patterns emerge.

### Timeout Philosophy

- No estimates in hours/weeks
- Real factual numbers only
- Start generous, capture actuals
- Tune from evidence

---

## Context Management

### Token Efficiency

| Do | Don't |
|----|-------|
| Scan only relevant folders | Preload everything |
| Archive completed prompts | Keep old .md files active |
| Use `.claudeignore` strategically | Block too aggressively |
| Summarize phases | Verbose step-by-step logs |

### Block Only When NEVER Needed

- `node_modules/`
- `.git/`
- Archived tarballs
- Build outputs

### Archive-and-Exclude Pattern (Preference)

Completed work (prompts, logs, old phases) gets tarballed and excluded from context rather than deleted. History is preserved but tokens are protected.

| Stage | Action |
|-------|--------|
| Active | Files in `_build/Prompts/` — in context |
| Completed | Move to `_build/archive/` — still accessible |
| Archived | Tarball (`.tar.gz`) — excluded from context |
| Never Delete | Keep archives for reference, audit, rollback |

**Philosophy:** Preserve everything, expose only what's relevant to current work.

---

## Secrets & Backup Strategy

### Philosophy
Encrypt what matters in-project. Backups stay plain for velocity and recovery.

### Two Locations, Two Rules

| Location | Encrypted | Why |
|----------|-----------|-----|
| In-project (`.secrets.yaml`) | ✅ Selective (SOPS) | Goes in git, API keys protected |
| Outside-project (`~/backups/`) | ❌ Plain | Recovery speed, no lockout risk |

### SOPS Selective Encryption

```yaml
# .sops.yaml - only encrypt sensitive keys
creation_rules:
  - path_regex: \.secrets\.yaml$
    age: age1xxxxxxxx
    encrypted_regex: '^(.*_api_key|.*_secret|.*_token|.*_password)$'
```

| Suffix | Encrypted | Example |
|--------|-----------|---------|
| `*_api_key` | ✅ Yes | `openai_api_key` |
| `*_secret` | ✅ Yes | `session_secret` |
| `*_token` | ✅ Yes | `github_token` |
| `*_password` | ✅ Yes | `db_password` |
| Everything else | ❌ No | `app_db_path`, `poll_interval` |

### Backup Location (Outside Project)

```
~/backups/
├── sparkqueue/
│   ├── backup-12-06-2024.sql      # DB export (plain)
│   ├── backup-12-06-2024.env      # Full .env snapshot (plain)
│   └── backup-12-06-2024.secrets  # Decrypted secrets (plain)
└── [project]/
```

**Not in git. Not in project. Plain for easy recovery.**

### Age Key Backup

Store `~/.config/sops/age/keys.txt` in password manager.  
If lost: Restore from password manager, or use plain backups from `~/backups/`.

### Risk Accepted

- `~/backups/` unencrypted on disk — protected by SSH/Wireguard
- API keys can be revoked in 2 minutes if leaked

---

## Database Guidance

### My Strengths

- Tables, columns, column types
- Primary keys, foreign keys

### Need Help With

- Joins and complex relations
- Reading tables with UUIDs

### Request

Include database views for common lookups so data is human-readable without writing joins.

### Human-Readable Database Views (Preference)

Database design should include views that eliminate the need for joins in common lookups. Tables store normalized data; views provide denormalized convenience.

| Pattern | Implementation |
|---------|----------------|
| UUID resolution | Views that join and display names instead of IDs |
| Status lookups | Views that expand enum values to readable labels |
| Aggregate summaries | Views for counts, totals without writing GROUP BY |
| Audit trails | Views that join user IDs to names, timestamps to readable formats |

---

## Team Context (Appmelia)

- **Role:** CEO, startup founder
- **Team:** 2 senior developers (20+ years, ex-IBM, ex-Enron)
- **Their role:** Validate code, enforce best practices
- **AI role:** Junior engineer writing code under supervision
- **My role:** Design specs, enable team with AI tooling

---

## Quick Reference

| Item | Value |
|------|-------|
| Name | Bryan Luce |
| GitHub | lucebryan3000 (private), appmelia-ai (company) |
| Time Zone | America/Chicago (CST) |
| Dev Server | Codeswarm — 192.168.1.150 |
| Project Root | /home/luce/apps/ |
| Docker | Always use Compose |
| Database | PostgreSQL, name = project name |
| Claude | Max $200/mo, 20+ hrs/week |
| Codex | Via OpenAI Pro, heavy codegen |
| Commit threshold | 300+ lines or 90+ min |
| Test timeout | See Appendix A |
| File review threshold | 1000+ lines |

---

## Application Behavior Standards

These are confirmed preferences for how apps should behave:

| Standard | Behavior |
|----------|----------|
| **Fail-fast on startup** | Check config, DB, env vars on boot. Fail immediately with clear error if missing. Don't silently break later. |
| **Sensible defaults** | Run with minimal config. Detect paths, use standard ports, assume dev mode. Explicit config only for non-standard setups. |
| **Idempotent operations** | Running same command twice doesn't break things. Migrations, seeds, setup scripts safe to re-run. |
| **Graceful degradation** | Optional features fail (email, external API) → core app keeps working. Log issue, don't crash. |
| **CLI alongside UI** | Power-user operations available via terminal. Scripts, one-liners, `npm run` commands. |
| **Keyboard shortcuts** | Common actions have shortcuts: `/` focus search, `Cmd+Enter` submit, `Escape` close modals. |
| **Safe migrations** | Reversible where possible. Destructive migrations get extra warnings. Schema changes deliberate. |
| **Progress visibility** | Operations >5 seconds show progress (percentage, spinner, log stream). No silent hangs. |
| **Batch operations** | Support batch operations, not just one-at-a-time. |
| **Dark mode default** | UI defaults to dark mode. Light mode optional. |

---

## Art of the Possible (Forward-Looking)

These are emerging patterns and capabilities that align with the overall development philosophy. Not yet fully implemented but represent the trajectory of the workflow.

### Model Handoff Protocols

Establish explicit handoff rules between models: what context transfers, what gets summarized, what starts fresh.

| Handoff | Context Rule |
|---------|--------------|
| Opus → Sonnet | Full prompt as .md file, no conversation history |
| Sonnet → Codex | Specific task extraction, code-only context |
| Sonnet → Haiku | Validation criteria only, minimal context |
| Any → Summary | Phase summary captures decisions, not process |

**Goal:** Define interface contracts so each model receives appropriate context without pollution from upstream conversations.

### Automated Prompt Quality Scoring

Use Haiku or lightweight model to validate prompt completeness before expensive execution.

| Check | Purpose |
|-------|---------|
| Missing context | Does the prompt reference undefined entities? |
| Ambiguous requirements | Are there multiple valid interpretations? |
| Scope creep indicators | Does scope exceed single-phase expectations? |
| Dependency clarity | Are prerequisites explicitly stated? |

**Goal:** Catch underspecified work before wasting Sonnet/Codex cycles.

### Agent Skill Inheritance

Agents should inherit from base skill sets and extend with project-specific rules.

```
base-skills/
├── code-review-base.md      # Standard review criteria
├── testing-base.md          # Test expectations
└── documentation-base.md    # Doc standards

project-skills/
├── project-testing.md       # Extends testing-base + project rules
└── project-api.md           # Project-specific API patterns
```

**Goal:** DRY principle applied to agent capabilities. Faster project bootstrap, consistent standards.

### Context Budget Visualization

Real-time visibility into token usage across a session.

| Metric | Value |
|--------|-------|
| Current context | X tokens / 200K limit |
| Session usage | Y tokens consumed |
| Estimated remaining | Z responses at current rate |
| Warning threshold | Alert at 80% capacity |

**Goal:** Proactive context management. Know when to summarize or prune before hitting limits.

### Parallel Execution Orchestration

Formalized patterns for running multiple AI instances simultaneously on independent tasks.

| Pattern | Use Case |
|---------|----------|
| Fan-out | Split large task into independent subtasks |
| Pipeline | Chain outputs: Opus → Sonnet → Codex |
| Race | Multiple approaches, take first success |
| Batch | N similar tasks processed in parallel |

**Prerequisites:**
- Tasks must be truly independent (no shared state)
- Clear merge strategy for results
- Failure isolation (one failure doesn't cascade)

**Goal:** Maximize throughput on multi-core hardware (16 cores available). Queue systems enable this pattern.

---

## Template Files

These standalone template files should be kept alongside this developer profile:

### Core Claude Configuration
| File | Purpose |
|------|---------|
| `claude_settings_template.json` | Complete `.claude/settings.json` with all env vars, hooks, permissions |
| `claudeignore_template.example` | Comprehensive `.claudeignore` for context optimization |
| `CLAUDE_md_template.example` | Project-level `CLAUDE.md` with all rules and conventions |
| `python_env_block_reference.md` | Reference for blocking Python environments |
| `project_scaffold_template.md` | Complete project structure and setup scripts |

### VS Code Configuration
| File | Purpose |
|------|---------|
| `vscode_extensions.json` | Core extensions (38) - always install |
| `vscode_extensions-python.json` | Python dev extensions |
| `vscode_extensions-azure.json` | Azure cloud extensions |
| `vscode_extensions-remote.json` | SSH/container remote dev |
| `vscode_extensions-jupyter.json` | Jupyter/data science |
| `vscode_extensions-go.json` | Go development |
| `vscode_extensions-ai-experimental.json` | Additional AI tools (Gemini, ChatGPT) |
| `vscode_extension_cleanup.md` | Guide for removing redundant extensions |
| `vscode_settings.json` | Editor settings (dark mode, formatting, exclusions) |
| `vscode_launch.json` | Debug configurations (Next.js, Jest, Playwright, Docker) |
| `vscode_tasks.json` | Common tasks (dev, test, docker, prisma) |
| `vscode_keybindings.json` | Keyboard shortcuts (navigation, terminal, git) |
| `prettierrc.json` | Prettier config (no semi, single quotes, trailing commas) |

### Usage

1. Copy relevant templates to new project
2. Rename files:
   - `vscode_*.json` → `.vscode/[name].json`
   - `prettierrc.json` → `.prettierrc`
   - `claudeignore_template.example` → `.claudeignore`
   - `CLAUDE_md_template.example` → `CLAUDE.md`
3. Update `[PROJECT_NAME]` and project-specific sections
4. Customize `additionalDirectories` if needed

---

## For AI Assistants: Summary

### DO
- Lead with recommendations
- Use approved stack defaults
- Generous timeouts (see Appendix A)
- Commit with meaningful messages
- Output to screen, not markdown files
- Velocity matters, but not at the cost of quality
- Max out hardware

### DON'T
- Create summary markdown files
- Ask constraining questions about resources
- Use time estimates in hours/weeks
- Include fake data or placeholders
- Interrupt working processes with strict timeouts
- Over-modularize files
- Explain what you're about to do — just do it

---

## Appendix A: Timeout & Timing Values

**Purpose:** Centralized timing values for easy tuning. Update these based on observed patterns.

### AI Model Task Timing

| Task Type | Typical Duration | Timeout (2×) | Notes |
|-----------|------------------|--------------|-------|
| Claude Code prompt | ≤15 min | 30 min | Standard feature implementation |
| OpenAI Codex prompt | ~20 min | 40 min | Heavy code generation |
| Haiku validation | <1 min | 2 min | Syntax checks, quick searches |
| Opus planning | 5-15 min | 30 min | PRD/FRD, architecture decisions |

### Testing Timeouts

| Test Type | Timeout | Notes |
|-----------|---------|-------|
| Unit test (single) | 30 sec | Fail fast |
| Unit test suite | 5 min | Full suite run |
| Integration test | 2 min | Per test |
| E2E test | 5 min | Per test |
| E2E suite | 30 min | Full Playwright/Puppeteer run |

### Operation Timeouts

| Operation | Timeout | Notes |
|-----------|---------|-------|
| Database query | 30 sec | Kill long-running queries |
| HTTP request | 30 sec | External API calls |
| File operation | 60 sec | Large file reads/writes |
| Docker build | 10 min | With cache |
| Docker build (cold) | 30 min | No cache |

### Progress Indicators

| Duration | User Feedback |
|----------|---------------|
| <2 sec | None needed |
| 2-5 sec | Spinner |
| 5-30 sec | Spinner + message |
| 30+ sec | Progress bar or log stream |

**Tuning:** These values should be adjusted based on actual observed patterns. When a task consistently completes faster or slower, update the table.

---

*This document should be included in project knowledge for any AI assistant working on Bryan's projects.*
