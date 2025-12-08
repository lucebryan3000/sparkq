# KB Writer Agent - Knowledge Base Content Generator

## Overview

Build an agent/system to populate `kb-bootstrap/` with technology-specific documentation that powers the bootstrap script generation system.

## Current State

**Exists:**
- `kb-bootstrap/` - 35+ technology folders (babel, claude, docker, eslint, git, typescript, etc.)
- `bootstrap-kb-sync.sh` - Scanner that inventories docs, tracks status (documented/partial/missing)
- `kb-bootstrap-manifest.json` - Manifest tracking documentation coverage

**Missing:**
- No writer/generator to create actual documentation content
- Folders exist but contain minimal or placeholder content
- No automated way to populate best practices, config patterns, examples

## Requirements

### 1. KB Article Structure

Each technology folder should contain:

```
kb-bootstrap/{technology}/
├── MANIFEST.json           # Metadata about this tech's docs
├── overview.md             # What it is, why use it, when to use it
├── config-patterns.md      # Common configuration patterns
├── best-practices.md       # Industry best practices
├── integration.md          # How it integrates with other tools
├── troubleshooting.md      # Common issues and solutions
└── examples/               # Example configurations
    ├── minimal.json        # Minimal viable config
    ├── standard.json       # Recommended config
    └── advanced.json       # Full-featured config
```

### 2. Content Requirements per Article

**overview.md:**
- One-paragraph description
- Use cases (when to use, when not to use)
- Key features
- Version requirements
- Links to official docs

**config-patterns.md:**
- Common configuration scenarios
- Config file formats supported
- Environment-specific patterns (dev/staging/prod)
- Monorepo vs single-repo patterns

**best-practices.md:**
- Industry standards
- Security considerations
- Performance tips
- Maintenance patterns

**integration.md:**
- How it works with other bootstrap technologies
- Order of operations / dependencies
- Conflict resolution patterns

**troubleshooting.md:**
- Common error messages and fixes
- Debugging tips
- Migration guides (version upgrades)

### 3. MANIFEST.json Schema

```json
{
  "technology": "eslint",
  "version": "9.x",
  "category": "linting",
  "status": "documented",
  "lastUpdated": "2025-12-07",
  "articles": [
    { "file": "overview.md", "status": "complete" },
    { "file": "config-patterns.md", "status": "complete" },
    { "file": "best-practices.md", "status": "partial" }
  ],
  "examples": ["minimal.json", "standard.json"],
  "dependencies": ["prettier", "typescript"],
  "sources": [
    "https://eslint.org/docs/latest/",
    "https://typescript-eslint.io/"
  ]
}
```

### 4. Agent Capabilities

The KB Writer Agent should:

1. **Scan** - Check current documentation status via `bootstrap-kb-sync.sh`
2. **Prioritize** - Focus on technologies used in bootstrap scripts first
3. **Research** - Fetch current best practices from official docs (WebFetch)
4. **Generate** - Create structured markdown content
5. **Validate** - Ensure content follows schema, no broken links
6. **Update** - Refresh outdated content when versions change

### 5. Priority Technologies

Based on bootstrap script usage, prioritize:

**Phase 1 (Core):**
- git, typescript, eslint, prettier, docker, vscode

**Phase 2 (Infrastructure):**
- docker-compose, database (postgres/mysql), kubernetes

**Phase 3 (Quality):**
- jest/vitest, husky, commitlint, security (snyk/npm-audit)

**Phase 4 (CI/CD):**
- github-actions, gitlab-ci, azure-pipelines

### 6. Integration with Bootstrap System

The KB content should be usable by:

- Bootstrap scripts (read patterns when generating configs)
- Claude agents (context for helping users)
- Documentation generation (auto-generate user docs)

### 7. Implementation Options

**Option A: Dedicated Agent**
Create `.claude/agents/kb-writer-agent.md` with instructions to:
- Read manifest for missing/partial docs
- Generate one technology at a time
- Validate and commit

**Option B: Slash Command**
Create `.claude/commands/kb-generate.md`:
```
/kb-generate eslint
/kb-generate --all-missing
/kb-generate --update-outdated
```

**Option C: Automated Pipeline**
Create `scripts/kb-generate.sh` that:
- Runs periodically or on-demand
- Uses Codex/Claude to generate content
- Commits updates automatically

### 8. Quality Gates

Before marking a technology as "documented":
- [ ] All required articles exist
- [ ] At least 2 example configs
- [ ] No placeholder text remaining
- [ ] Links validated
- [ ] Reviewed against official docs (< 6 months old)

## Next Steps

1. Choose implementation option (A, B, or C)
2. Create the agent/command structure
3. Generate content for 3 pilot technologies
4. Validate approach works
5. Scale to remaining technologies

## Related Files

- `__bootbuild/kb-bootstrap/` - Target directory
- `__bootbuild/scripts/bootstrap-kb-sync.sh` - Scanner
- `__bootbuild/kb-bootstrap/kb-bootstrap-manifest.json` - Status manifest
- `__bootbuild/config/bootstrap-manifest.json` - Main bootstrap manifest
