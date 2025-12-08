# KB Writer - Knowledge Base Content Generation

> **Purpose**: Generate authoritative, structured documentation for any knowledge base
> **First Application**: `__bootbuild/kb-bootstrap/` - Technology documentation for rapid project scaffolding

---

## How It Works

When invoked, I will:

1. **Scan** - Read the target KB manifest to identify what needs documentation
2. **Research** - Fetch authoritative sources (official docs, best practices)
3. **Generate** - Create structured articles following the KB schema
4. **Validate** - Check syntax, completeness, no placeholders
5. **Report** - Summary of what was created/updated

---

## Invocation

```
Generate KB documentation for {target}

Target options:
- Single item: "eslint", "typescript", "docker"
- Batch: "batch:core", "batch:infrastructure", "batch:quality"
- All missing: "all-missing"
- Update outdated: "update-outdated"
```

---

## Generic KB Structure

Every KB follows this pattern:

```
{kb-root}/
├── {kb-name}-manifest.json    # Master manifest tracking all items
└── {item}/                    # One folder per documented item
    ├── MANIFEST.json          # Item metadata
    ├── overview.md            # What, why, when to use
    ├── config-patterns.md     # Configuration patterns
    ├── best-practices.md      # Industry standards
    ├── integration.md         # How it works with other items
    ├── troubleshooting.md     # Common issues and fixes
    └── examples/              # Concrete examples
        ├── minimal.{ext}
        ├── standard.{ext}
        └── advanced.{ext}
```

---

## First Application: Bootstrap KB

### Target Directory
`__bootbuild/kb-bootstrap/`

### Purpose
Authoritative documentation for each technology in the bootstrap system, enabling:
- Fast, informed decisions when scaffolding new projects
- Consistent configuration patterns across projects
- Quick troubleshooting reference
- Context for Claude agents helping with setup

### Data Sources

**Primary**: `__bootbuild/kb-bootstrap/kb-bootstrap-manifest.json`
- 36 technologies with metadata
- Priority levels (high/medium/low)
- Categories (linting, testing, devops, etc.)
- Official source URLs per technology

**Secondary**: `__bootbuild/templates/root/{tech}/`
- Actual template files used by bootstrap scripts
- These become canonical examples in KB articles

**Tertiary**: Official documentation (via WebFetch)
- Use `source_url` from manifest
- Fetch current version requirements, breaking changes

### Priority Order (from manifest)

**High Priority** (document first):
- git, typescript, eslint, prettier, docker, docker-compose
- github, jest, linting, next, packages, pytest
- stylelint, testing, vite, vscode, webpack

**Medium Priority**:
- babel, claudeignore, codex, coverage, direnv
- environment, gitignore, nvm, prompts, rollup

**Low Priority**:
- coveragerc, dockerignore, editor, editorconfig
- gitattributes, nvmrc, tool-versions

### Consolidation Strategy

Some folders are sub-topics of a primary technology. Generate docs for primary, reference in sub-topics:

| Primary | Sub-topics (reference only) |
|---------|----------------------------|
| git | gitignore, gitattributes |
| docker | docker-compose, dockerignore |
| coverage | coveragerc |
| nvm | nvmrc |
| eslint | linting (merge) |
| jest | testing (merge) |

### Cross-Reference to Templates

Each KB article should reference the actual template files:

```markdown
## Bootstrap Template

The bootstrap system uses this configuration:
- Template: `__bootbuild/templates/root/eslint/.eslintrc.json`
- Script: `__bootbuild/templates/scripts/bootstrap-linting.sh`
```

---

## Article Templates

### MANIFEST.json (per item)

```json
{
  "technology": "{name}",
  "version": "{current_stable}",
  "category": "{from_master_manifest}",
  "status": "documented",
  "lastUpdated": "{YYYY-MM-DD}",
  "articles": [
    { "file": "overview.md", "status": "complete" },
    { "file": "config-patterns.md", "status": "complete" },
    { "file": "best-practices.md", "status": "complete" },
    { "file": "integration.md", "status": "complete" },
    { "file": "troubleshooting.md", "status": "complete" }
  ],
  "examples": [],
  "sources": ["{from_master_manifest.source_url}"],
  "bootstrapTemplate": "{path_to_template_if_exists}",
  "bootstrapScript": "{path_to_script_if_exists}"
}
```

### overview.md

```markdown
# {Technology} Overview

## What It Is
{Concise description - what problem it solves}

## When to Use
- {Primary use case}
- {Secondary use case}

## When NOT to Use
- {Anti-pattern or alternative}

## Key Features
- {Feature 1}
- {Feature 2}

## Version Requirements
- Current stable: {version}
- Minimum supported: {version}
- Runtime requirement: {Node X.x / Python X.x / etc.}

## Official Documentation
- {source_url from manifest}

## Bootstrap Integration
- Template: `{path}`
- Script: `{path}`
```

### config-patterns.md

```markdown
# {Technology} Configuration Patterns

## Config File Locations
{Where config files live, order of precedence}

## Minimal Configuration
{Simplest working config - copy-paste ready}

## Standard Configuration
{Recommended for most projects - what bootstrap uses}

## Advanced Configuration
{Full-featured with explanations}

## Environment-Specific

### Development
{Dev overrides}

### Production
{Prod considerations}

## Monorepo vs Single Repo
{Differences in configuration approach}
```

### best-practices.md

```markdown
# {Technology} Best Practices

## Industry Standards
- {Standard 1 with rationale}
- {Standard 2 with rationale}

## Security Considerations
- {Security practice}

## Performance
- {Performance tip}

## Maintenance
- {How to keep it updated}
- {When to upgrade versions}

## Common Mistakes
- {Mistake}: {Why it's wrong and how to fix}
```

### integration.md

```markdown
# {Technology} Integration

## Bootstrap Dependencies
- Requires: {technologies that must run first}
- Required by: {technologies that depend on this}

## Common Integrations

### With {Related Tech}
{How they work together, config snippets}

## Conflict Resolution
{What to do when configs clash}

## Order of Operations
{When to run relative to other bootstrap scripts}
```

### troubleshooting.md

```markdown
# {Technology} Troubleshooting

## Common Errors

### {Error message or symptom}
**Cause**: {Why this happens}
**Fix**: {How to resolve}

## Debugging
- {Debug tip 1}
- {Debug tip 2}

## Version Migration

### {Old version} → {New version}
{Breaking changes and migration steps}

## FAQ

**Q: {Common question}**
A: {Answer}
```

---

## Execution Process

### For Single Technology

```
1. Read master manifest for metadata (priority, category, source_url)
2. Check if template exists at __bootbuild/templates/root/{tech}/
3. Check if script exists at __bootbuild/templates/scripts/bootstrap-{tech}.sh
4. Fetch source_url if needed for current version info
5. Generate all 5 articles + MANIFEST.json
6. Create examples/ from template files if they exist
7. Validate: JSON syntax, no placeholders, markdown formatting
8. Update master manifest status to "documented"
```

### For Batch

```
1. Filter master manifest by priority or category
2. Process each technology sequentially
3. After each: validate and report
4. After batch: update master manifest summary counts
```

### For All Missing

```
1. Read master manifest, filter status="missing"
2. Sort by priority (high → medium → low)
3. Process high priority first
4. Continue until all documented or error
```

---

## Validation

```bash
# JSON syntax
python3 -c "import json; json.load(open('MANIFEST.json'))"

# No placeholders
grep -r "TODO\|FIXME\|TBD\|{.*}" *.md

# All required files exist
ls overview.md config-patterns.md best-practices.md integration.md troubleshooting.md

# Example configs valid (JSON)
python3 -c "import json; json.load(open('examples/minimal.json'))"

# Example configs valid (YAML)
python3 -c "import yaml; yaml.safe_load(open('examples/minimal.yaml'))"
```

---

## Quality Gates

Before marking as "documented":

- [ ] MANIFEST.json exists and valid
- [ ] All 5 required articles exist
- [ ] No placeholder text remaining
- [ ] Source URL referenced
- [ ] Bootstrap template/script cross-referenced (if exists)
- [ ] At least minimal example provided

---

## Progress Tracking

When running batch or all-missing:

```
=== KB Generation Progress ===
Target: __bootbuild/kb-bootstrap/
Total: 36 technologies
Documented: 1 (claude)
Missing: 35

High Priority (17): 0/17 complete
Medium Priority (10): 0/10 complete
Low Priority (8): 0/8 complete

Currently processing: {technology}
```

---

## Future KB Applications

This same pattern can generate documentation for:

- `docs/api/` - API endpoint documentation
- `docs/architecture/` - System architecture docs
- `docs/runbooks/` - Operational runbooks
- Any structured knowledge base following the item/article pattern

---

## Related Files

**Bootstrap KB specific:**
- `__bootbuild/kb-bootstrap/` - Target directory
- `__bootbuild/kb-bootstrap/kb-bootstrap-manifest.json` - Master manifest
- `__bootbuild/templates/root/` - Template files to reference
- `__bootbuild/templates/scripts/` - Bootstrap scripts to reference
- `__bootbuild/config/bootstrap-manifest.json` - Script definitions

**Generic:**
- Article templates above
- Validation commands above
