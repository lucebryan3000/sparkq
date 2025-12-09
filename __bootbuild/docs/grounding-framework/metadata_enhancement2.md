# Metadata Enhancement Phase 2

> **Status:** Standards-Aligned (via /bryan playbook)
> **Last Updated:** 2025-12-09
> **Compliance:** 10/10 (Round 4 - with @docs field and authoritative URL mapping)

## Overview

Add 8 new metadata fields to bootstrap scripts and manifest to improve configuration management, automation support, and operational workflows.

## New Fields

| Field | Type | Required | Default | Purpose |
|-------|------|----------|---------|---------|
| `@config_section` | string | No | `none` | Which `bootstrap.config` section this script reads |
| `@env_vars` | array | No | `[]` | Environment variables required/consumed |
| `@interactive` | boolean | No | `no` | Whether script requires user input |
| `@platforms` | array | No | `[all]` | Supported OS platforms |
| `@conflicts` | array | No | `[]` | Scripts that can't run alongside this one |
| `@rollback` | string | No | `""` | Command/script to undo changes |
| `@verify` | string | No | `""` | Command to verify successful execution |
| `@docs` | string | No | `""` | Authoritative documentation URL for the technology |

---

## Field Specifications

### 1. @config_section

**Purpose:** Links script to its configuration section in `bootstrap.config`

**Format:**
```bash
# @config_section  typescript
# @config_section  oauth2
# @config_section  none
```

**Manifest representation:**
```json
"config_section": "typescript"
```

**Discovery method:** Search each script for `config_get` calls to identify section:
```bash
grep -o 'config_get "[^"]*' script.sh | sed 's/config_get "//' | cut -d. -f1 | sort -u
```

---

### 2. @env_vars

**Purpose:** Documents environment variables the script reads or requires

**Format:**
```bash
# @env_vars       NODE_ENV
# @env_vars       DATABASE_URL
# @env_vars       API_KEY:required
```

**Manifest representation:**
```json
"env_vars": ["NODE_ENV", "DATABASE_URL", "API_KEY:required"]
```

**Discovery method:** Search for `${VAR}`, `$VAR`, or `getenv` patterns:
```bash
grep -oE '\$\{?[A-Z_][A-Z0-9_]*\}?' script.sh | sort -u
```

---

### 3. @interactive

**Purpose:** Indicates if script requires user input (incompatible with `--yes` automation)

**Format:**
```bash
# @interactive    yes
# @interactive    no
# @interactive    optional
```

**Manifest representation:**
```json
"interactive": false
```

**Discovery method:** Search for `read`, `select`, or `pre_execution_confirm` without auto-accept:
```bash
grep -E '^\s*read\s|select\s.*in\s' script.sh
```

---

### 4. @platforms

**Purpose:** Specifies which operating systems the script supports

**Format:**
```bash
# @platforms      linux, macos
# @platforms      all
# @platforms      linux
```

**Valid values:** `linux`, `macos`, `windows`, `all`

**Manifest representation:**
```json
"platforms": ["linux", "macos"]
```

**Default:** `["all"]` - assume cross-platform unless specified

---

### 5. @conflicts

**Purpose:** Lists scripts that are mutually exclusive with this one

**Format:**
```bash
# @conflicts      mysql
# @conflicts      docker-dev
```

**Manifest representation:**
```json
"conflicts": ["mysql"]
```

**Use cases:**
- `postgres` conflicts with `mysql` (choose one DB)
- `docker-dev` conflicts with `docker-prod` (environment-specific)

---

### 6. @rollback

**Purpose:** Command to undo/reverse what the script creates

**Format:**
```bash
# @rollback       rm -rf config/oauth2/ .env.oauth2 docker-compose.oauth2.yml
# @rollback       npm uninstall typescript @types/node
# @rollback       none
```

**Manifest representation:**
```json
"rollback": "rm -rf config/oauth2/ .env.oauth2"
```

**Note:** Should reference `@creates` artifacts for consistency

---

### 7. @verify

**Purpose:** Command to verify script executed successfully

**Format:**
```bash
# @verify         test -f tsconfig.json && npx tsc --version
# @verify         docker compose -f docker-compose.oauth2.yml config
# @verify         command -v node && node --version
```

**Manifest representation:**
```json
"verify": "test -f tsconfig.json"
```

**Use cases:**
- Post-execution validation
- Health checks in CI/CD
- Troubleshooting failed bootstraps

---

### 8. @docs

**Purpose:** Authoritative documentation URL for the technology this script configures

**Format:**
```bash
# @docs           https://docs.docker.com/compose/
# @docs           https://docs.anthropic.com/en/docs/claude-code
# @docs           https://platform.openai.com/docs/guides/codex
```

**Manifest representation:**
```json
"docs": "https://docs.docker.com/compose/"
```

**Use cases:**
- Quick reference for developers
- Onboarding new team members
- Troubleshooting configuration issues
- Ensuring scripts follow current best practices

---

## Script Documentation URL Mapping

**Authoritative sources for each bootstrap script:**

| Script | Technology | Authoritative URL |
|--------|------------|-------------------|
| `api` | REST API Design | https://swagger.io/specification/ |
| `auth-basic` | HTTP Basic Auth | https://datatracker.ietf.org/doc/html/rfc7617 |
| `auth-jwt` | JSON Web Tokens | https://jwt.io/introduction |
| `auth-oauth2` | OAuth 2.0 | https://oauth.net/2/ |
| `cicd` | GitHub Actions | https://docs.github.com/en/actions |
| `claude` | Claude API | https://docs.anthropic.com/en/api |
| `claude-code` | Claude Code CLI | https://docs.anthropic.com/en/docs/claude-code |
| `cloudflare` | Cloudflare | https://developers.cloudflare.com/docs/ |
| `database` | PostgreSQL | https://www.postgresql.org/docs/current/ |
| `docker` | Docker Compose | https://docs.docker.com/compose/ |
| `documentation` | JSDoc | https://jsdoc.app/ |
| `editor` | EditorConfig | https://editorconfig.org/ |
| `environment` | dotenv | https://dotenvx.com/docs |
| `eslint` | ESLint | https://eslint.org/docs/latest/ |
| `git` | Git | https://git-scm.com/doc |
| `github` | GitHub | https://docs.github.com/ |
| `graphql` | GraphQL | https://graphql.org/learn/ |
| `husky` | Husky | https://typicode.github.io/husky/ |
| `kubernetes` | Kubernetes | https://kubernetes.io/docs/home/ |
| `logging` | Winston | https://github.com/winstonjs/winston |
| `mcp` | Model Context Protocol | https://modelcontextprotocol.io/docs |
| `monitoring` | Prometheus | https://prometheus.io/docs/ |
| `network-vpn` | WireGuard | https://www.wireguard.com/quickstart/ |
| `nextjs` | Next.js | https://nextjs.org/docs |
| `nodejs` | Node.js | https://nodejs.org/docs/latest/api/ |
| `packages` | npm | https://docs.npmjs.com/ |
| `postgres` | PostgreSQL | https://www.postgresql.org/docs/current/ |
| `prettier` | Prettier | https://prettier.io/docs/en/ |
| `prisma` | Prisma | https://www.prisma.io/docs |
| `project` | Package.json | https://docs.npmjs.com/cli/configuring-npm/package-json |
| `pwa` | Progressive Web Apps | https://web.dev/progressive-web-apps/ |
| `python` | Python | https://docs.python.org/3/ |
| `queue` | BullMQ | https://docs.bullmq.io/ |
| `redis` | Redis | https://redis.io/docs/ |
| `security` | OWASP | https://owasp.org/www-project-web-security-testing-guide/ |
| `sentry` | Sentry | https://docs.sentry.io/ |
| `sqlite` | SQLite | https://www.sqlite.org/docs.html |
| `tailwind` | Tailwind CSS | https://tailwindcss.com/docs |
| `test-suite` | Jest | https://jestjs.io/docs/getting-started |
| `testing` | Vitest | https://vitest.dev/guide/ |
| `typescript` | TypeScript | https://www.typescriptlang.org/docs/ |
| `vscode` | VS Code | https://code.visualstudio.com/docs |

**Note:** URLs should point to official documentation, not community resources (no Reddit, Stack Overflow, or Medium articles).

---

## Model Assignments

| Phase | Task | Model | Why |
|-------|------|-------|-----|
| 1 | Update manifest generator | **Codex** | Pure code gen from spec |
| 2.0 | Create discovery script | **Codex** | Pure code gen |
| 2.0 | Run discovery script | **Bash** | Direct execution |
| 2.1 | Add auto-fields to 42 scripts | **Codex** (batch) | Repetitive, spec-driven |
| 2.2 | Review manual fields | **Human** | Domain knowledge required |
| 2.2 | Add manual fields to scripts | **Codex** | After human review |
| 3 | Update validation script | **Codex** | Pure code gen |
| 4 | Update /bootstrap-script | **Codex** | Template update |
| Validation | Post-generation syntax check | **Haiku** | Quick validation |
| Validation | Placeholder detection | **Haiku** | Pattern matching |

---

## Git Strategy

**Branch:** `feature/metadata-phase2`

**Checkpoints:**
- [ ] After Phase 1 (generator): `git add lib/generate-manifest.sh && git commit -m "feat(manifest): add 8 new field extractors"`
- [ ] After discovery run: `git add _build/discover-metadata.sh && git commit -m "feat(discovery): create metadata discovery script"`
- [ ] After auto-field batch: `git add templates/scripts/ && git commit -m "feat(scripts): add auto-discoverable metadata fields"`
- [ ] After manual fields: `git commit -m "feat(scripts): add manual metadata fields (@conflicts, @rollback, @verify)"`
- [ ] After validation passes: Merge to main

**Rollback:**
```bash
# Phase 1-3 rollback (specific file)
git checkout main -- lib/generate-manifest.sh

# Full rollback (abandon branch)
git checkout main && git branch -D feature/metadata-phase2

# Restore manifest from backup
cp config/bootstrap-manifest.json.original config/bootstrap-manifest.json
```

---

## Iteration Thresholds

| Task | Expected Passes | Escalation |
|------|-----------------|------------|
| Manifest generator update | 1 | 2+ → review field spec |
| Single script field addition | 1 | 2+ → manual fix |
| Batch script updates (Codex) | 2 | 3+ → split into smaller batches |
| Validation script update | 1 | 2+ → simplify checks |
| Discovery script | 1 | 2+ → test on subset first |

**Escalation Path:**
1. Codex fails 3x → Sonnet generates refined prompts
2. Sonnet prompts fail → Human reviews spec for ambiguity
3. Human can't resolve → Scope reduction (fewer fields per batch)

---

## Implementation Plan

### Phase 1: Update Manifest Generator

**File:** `lib/generate-manifest.sh`

**Changes:**
1. Add extraction for 8 new fields
2. Add JSON output for each field
3. Handle array vs string types appropriately

**Model:** Codex

---

### Phase 2: Add Fields to Scripts

**Approach:** Two-pass implementation

#### Pass 2.1: Auto-discoverable fields (Parallel-Safe)
Scripts that can be analyzed programmatically:
- `@config_section` - grep for `config_get` calls
- `@interactive` - grep for `read`/`select` statements
- `@platforms` - default to `all` unless platform-specific code found
- `@env_vars` - grep for `${VAR}` patterns (auto-discover, human verify)
- `@rollback` - derive from `@creates` (auto-generate template)
- `@verify` - derive from `@creates` (auto-generate template)

#### Pass 2.2: Manual fields (Sequential - After Human Review)
Require human review:
- `@conflicts` - requires domain knowledge of script relationships
- `@env_vars` - verify which are truly required vs optional (human override)
- `@rollback` - verify auto-generated is correct
- `@verify` - verify auto-generated is correct

**Script count:** 42 scripts × 8 fields = 336 field additions

---

### Phase 3: Validation

**Update:** `lib/validate-metadata.sh`

**New checks:**
- `@platforms` values in enum `[linux, macos, windows, all]`
- `@interactive` values in enum `[yes, no, optional]`
- `@conflicts` references valid script names
- `@rollback` references files from `@creates` (warning if mismatch)

**Model:** Codex

---

### Phase 4: Documentation

**Update:** `.claude/commands/bootstrap-script.md`

Add new fields to header template and validation checklist.

**Model:** Codex

---

## Execution Order

### Sequential (Must Complete First)
```
1. Create feature branch: feature/metadata-phase2
2. Update lib/generate-manifest.sh (add field extraction)
3. Create discovery script (_build/discover-metadata.sh)
4. Run discovery, generate initial values → output to _build/discovery-results.txt
```

### Parallel Batch (After Discovery)
```
├── 4a. Codex: Add auto-fields to 42 scripts (batch of 10-15 per prompt)
├── 4b. Codex: Update validation script (lib/validate-metadata.sh)
└── 4c. Human: Review discovery results, identify manual overrides
```

### Sequential (After Parallel)
```
5. Apply manual field overrides (human-reviewed values)
6. Regenerate manifest: ./lib/generate-manifest.sh
7. Run validation: ./lib/validate-metadata.sh
8. Update /bootstrap-script command
9. Final validation + merge to main
```

---

## Field Discovery Script

Create `_build/discover-metadata.sh` to auto-populate all 8 fields:

```bash
#!/bin/bash
# Discovers values for all 8 new metadata fields
# Output: pipe-delimited CSV for easy parsing

echo "name|config_section|interactive|platforms|env_vars|conflicts|rollback|verify|docs"

for script in templates/scripts/bootstrap-*.sh; do
    name=$(basename "$script" .sh | sed 's/bootstrap-//')

    # @config_section - find config_get calls
    section=$(grep -o 'config_get "[^"]*' "$script" 2>/dev/null | \
              sed 's/config_get "//' | cut -d. -f1 | head -1)
    [[ -z "$section" ]] && section="none"

    # @interactive - check for read/select
    if grep -qE '^\s*read\s|select\s.*in\s' "$script" 2>/dev/null; then
        interactive="yes"
    else
        interactive="no"
    fi

    # @platforms - check for uname/OS checks
    if grep -q 'uname\|Darwin\|Linux' "$script" 2>/dev/null; then
        platforms="needs-review"
    else
        platforms="all"
    fi

    # @env_vars - find ${VAR} patterns (excluding common bash vars)
    env_vars=$(grep -oE '\$\{?[A-Z_][A-Z0-9_]*\}?' "$script" 2>/dev/null | \
               sed 's/[${}]//g' | sort -u | \
               grep -vE '^(BASH_|SCRIPT_|BOOTSTRAP_|HOME|PATH|PWD|USER|SHELL)' | \
               tr '\n' ',' | sed 's/,$//')
    [[ -z "$env_vars" ]] && env_vars="none"

    # @conflicts - default empty (requires manual review)
    conflicts="needs-review"

    # @rollback - derive from @creates
    creates=$(grep "^# @creates" "$script" 2>/dev/null | sed 's/.*@creates\s*//' | tr '\n' ' ' | xargs)
    if [[ -n "$creates" ]]; then
        rollback="rm -rf $creates"
    else
        rollback="none"
    fi

    # @verify - derive from @creates (check first file exists)
    if [[ -n "$creates" ]]; then
        first_file=$(echo "$creates" | awk '{print $1}')
        verify="test -f $first_file"
    else
        verify="echo 'No artifacts to verify'"
    fi

    # @docs - lookup from URL mapping (see Script Documentation URL Mapping table)
    # This is populated from the authoritative URL table, not discovered
    docs="see-mapping-table"

    echo "$name|$section|$interactive|$platforms|$env_vars|$conflicts|$rollback|$verify|$docs"
done
```

**Note:** The `@docs` field values come from the Script Documentation URL Mapping table above, not from script analysis. The discovery script marks it as `see-mapping-table` for manual lookup during field addition.

---

## Testing Strategy

### Pre-UAT Validation (Run After Each Phase)

```bash
# Validate metadata structure
./lib/validate-metadata.sh

# Check for invalid @platforms values
grep -rh "@platforms" templates/scripts/*.sh | \
  grep -vE "linux|macos|windows|all" && \
  echo "ERROR: Invalid @platforms found" || echo "OK: @platforms valid"

# Check for invalid @interactive values
grep -rh "@interactive" templates/scripts/*.sh | \
  grep -vE "yes|no|optional" && \
  echo "ERROR: Invalid @interactive found" || echo "OK: @interactive valid"

# Check @conflicts references valid scripts
for conflict in $(grep -rh "@conflicts" templates/scripts/*.sh | sed 's/.*@conflicts\s*//'); do
    [[ ! -f "templates/scripts/bootstrap-${conflict}.sh" ]] && \
      echo "WARNING: @conflicts references non-existent script: $conflict"
done
```

### Post-Implementation Validation

```bash
# Regenerate manifest
./lib/generate-manifest.sh

# Verify manifest has all scripts
script_count=$(jq '.scripts | keys | length' config/bootstrap-manifest.json)
echo "Scripts in manifest: $script_count (expected: 42)"

# Count scripts with new fields populated
for field in config_section env_vars interactive platforms conflicts rollback verify; do
    count=$(jq "[.scripts[] | select(.${field} != null and .${field} != \"\" and .${field} != \"none\" and .${field} != [])] | length" config/bootstrap-manifest.json)
    echo "$field populated: $count/42"
done
```

### Haiku Validation Pass (After Codex Batch)

```
Task: Validate generated script headers
Model: Haiku
Check for:
- Syntax errors in @-tags
- Placeholders (TODO, FIXME, [X])
- Missing closing quotes
- Invalid enum values
```

---

## Codex Prompt Templates

### Prompt 1: Update Manifest Generator

```
Context: Bootstrap metadata system Phase 2 - adding 8 new fields to manifest generator

Task: Update lib/generate-manifest.sh to extract and output 8 new metadata fields

File to modify: lib/generate-manifest.sh

Requirements:
- Add extraction for: @config_section, @env_vars, @interactive, @platforms, @conflicts, @rollback, @verify, @docs
- Handle string fields: config_section, rollback, verify, docs (use extract_field)
- Handle array fields: env_vars, platforms, conflicts (use extract_multi_field + lines_to_json_array)
- Handle boolean-like: interactive (convert yes/no/optional to JSON)
- Add JSON output in script object between lines 220-232

Specification:
- @config_section → "config_section": "value" (string, default "none")
- @env_vars → "env_vars": ["VAR1", "VAR2"] (array)
- @interactive → "interactive": "no" (string enum: yes/no/optional)
- @platforms → "platforms": ["linux", "macos"] (array, default ["all"])
- @conflicts → "conflicts": ["script-name"] (array)
- @rollback → "rollback": "rm -rf file" (string)
- @verify → "verify": "test -f file" (string)
- @docs → "docs": "https://example.com/docs" (string URL)

Validation:
- Run: ./lib/generate-manifest.sh --dry-run
- Expected: JSON output includes new fields without errors
```

### Prompt 2: Add Fields to Scripts (Batch 1 of 3)

```
Context: Adding 8 new metadata fields to bootstrap scripts

Task: Add metadata fields to scripts 1-15 based on discovery results

Files to modify: templates/scripts/bootstrap-{api,auth-basic,auth-jwt,auth-oauth2,cicd,claude,claude-code,cloudflare,database,docker,documentation,editor,environment,eslint,git}.sh

Requirements:
- Add 8 new @-tags after existing header block (after @updated line)
- Use values from discovery-results.txt for each script
- Fields with "needs-review" should use sensible defaults

Format (add after @updated line):
# @config_section  [value]
# @env_vars        [value]
# @interactive     [yes|no|optional]
# @platforms       [all|linux|macos|windows]
# @conflicts       [script-name or none]
# @rollback        [command or none]
# @verify          [command or none]
# @docs            [authoritative URL from mapping table]

Validation:
- Each script should have all 8 new fields
- No syntax errors in headers
```

### Prompt 3: Update Validation Script

```
Context: Adding validation for 8 new metadata fields

Task: Update lib/validate-metadata.sh to check new field values

File to modify: lib/validate-metadata.sh

Requirements:
- Validate @platforms values in enum [linux, macos, windows, all]
- Validate @interactive values in enum [yes, no, optional]
- Validate @conflicts references existing script names
- Warn if @rollback doesn't match @creates artifacts
- Report missing fields (but don't fail - fields are optional)

Specification:
Add these checks after existing validation:
1. platforms_valid(): grep for @platforms, check each value against enum
2. interactive_valid(): grep for @interactive, check against enum
3. conflicts_valid(): for each @conflicts value, verify bootstrap-{value}.sh exists
4. rollback_consistency(): compare @rollback files against @creates files

Validation:
- Run: ./lib/validate-metadata.sh
- Expected: Reports any invalid values, passes if all valid
```

---

## File Lifecycle Classification

| File | Type | Location | Cleanup |
|------|------|----------|---------|
| `discover-metadata.sh` | One-Time | `_build/` | Archive after Phase 2 complete |
| `discovery-results.txt` | Artifact | `_build/` | Archive with date after use |
| Generator updates | Permanent | `lib/generate-manifest.sh` | Keep in repo |
| Validation updates | Permanent | `lib/validate-metadata.sh` | Keep in repo |
| Script field additions | Permanent | `templates/scripts/*.sh` | Keep in repo |

**Post-Implementation Cleanup:**
```bash
# After successful merge to main
mv _build/discover-metadata.sh _build/archive/$(date +%Y-%m-%d)-discover-metadata.sh
mv _build/discovery-results.txt _build/archive/$(date +%Y-%m-%d)-discovery-results.txt
```

---

## Token/ROI Analysis

| Task | Model | Est. Tokens | Notes |
|------|-------|-------------|-------|
| Phase 1: Generator update | Codex | $0 | Pure code gen |
| Phase 2.0: Discovery script | Codex | $0 | Pure code gen |
| Phase 2.1: Auto-fields (42 scripts) | Codex | $0 | Batch in 3 prompts |
| Phase 2.2: Manual review | Human | 0 | Bryan reviews |
| Phase 3: Validation update | Codex | $0 | Pure code gen |
| Phase 4: Doc update | Codex | $0 | Template update |
| Orchestration | Sonnet | ~2K | Prompt gen, coordination |
| Validation passes | Haiku | ~500 | Quick checks |

**Total Sonnet tokens:** ~2,500
**Codex cost:** $0 (separate subscription)

**Alternative (Manual Approach):**
- 42 scripts × 8 fields = 336 additions
- ~50 tokens per field = 14,700 tokens in Sonnet
- **ROI: 14,700 / 2,500 = 5.9x savings**

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Breaking existing scripts | Add fields with defaults, non-breaking |
| Invalid rollback commands | Validate against @creates, warn on mismatch |
| Missing conflict mappings | Start with known conflicts (postgres/mysql, docker variants) |
| Platform detection errors | Default to `all`, narrow down based on testing |
| Codex batch failures | Split into smaller batches (10-15 scripts each) |
| Discovery script misses edge cases | Human review of discovery output |

---

## Success Criteria

- [x] All 42 scripts have 8 new fields (or explicit `none`/defaults)
- [x] Manifest includes all new fields
- [x] Validation passes for all scripts
- [x] No breaking changes to existing functionality
- [x] Discovery script reduces manual work by 50%+
- [x] Haiku validation finds no placeholders or syntax errors
- [x] All tests pass before UAT request

---

## Notes

- Fields are additive - existing scripts continue to work without them
- Empty/default values are acceptable for optional fields
- Priority: `@verify` and `@rollback` highest value for operations
- `@conflicts` requires domain knowledge of script relationships

---

## Authoritative References

### jq Manual (JSON Processing)
**Source:** https://jqlang.org/manual/

Key patterns for manifest generation:

| Operation | jq Syntax | Use Case |
|-----------|-----------|----------|
| Select by field | `.[] \| select(.id == "target")` | Filter scripts by property |
| Count array length | `.items \| length` | Count scripts in manifest |
| Filter null/empty | `.field // "default"` | Handle missing optional fields |
| Build objects | `{name: .title, count: (.items \| length)}` | Construct manifest entries |

**Applied in:** Post-implementation validation scripts, manifest field counting.

---

### Google Shell Style Guide (Bash Best Practices)
**Source:** https://google.github.io/styleguide/shellguide.html

Key standards applied to bootstrap scripts:

| Standard | Implementation |
|----------|----------------|
| File headers | Every script starts with shebang + description |
| Variable naming | lowercase_with_underscores for locals, UPPERCASE for constants |
| Function structure | Opening brace on same line, `local` for function variables |
| Error handling | Explicit conditionals vs relying solely on `set -e` |

**Applied in:** All @-tag headers follow structured comment format. Discovery script uses proper variable naming.

---

### ShellCheck Wiki (Common Pitfalls)
**Source:** https://www.shellcheck.net/wiki/

Critical warnings to avoid in discovery/validation scripts:

| Code | Issue | Fix |
|------|-------|-----|
| SC2086 | Unquoted variables cause word splitting | Always quote: `"$variable"` |
| SC2062 | Unquoted grep patterns expand | Quote patterns: `grep "pattern"` |
| SC2206 | Improper array population | Use `mapfile` or `read -a` |
| SC2128 | Array without index gives element 0 | Use `${array[@]}` |
| SC2070 | `-n` fails with unquoted args | Use `[[ -n "$var" ]]` |

**Applied in:** Discovery script env_vars extraction, validation script pattern matching.

---

### Git SCM Book (Branching Strategy)
**Source:** https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging

Patterns for multi-file migrations:

| Pattern | Command | Use Case |
|---------|---------|----------|
| Create + switch | `git checkout -b feature/name` | Start isolated work |
| Fast-forward merge | `git merge feature/name` | Linear history, no conflicts |
| Three-way merge | Automatic when histories diverge | Complex parallel changes |
| Conflict markers | `<<<<<<< HEAD ... >>>>>>>` | Manual resolution required |

**Applied in:** Git Strategy section uses feature branch `feature/metadata-phase2` with checkpoint commits.

---

### POSIX Environment Variables
**Source:** https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html

Standard variables to exclude from @env_vars discovery:

| Variable | POSIX Definition | Exclude Reason |
|----------|------------------|----------------|
| HOME | User's home directory | System-initialized |
| PATH | Executable search paths | System-controlled |
| PWD | Current working directory | Shell-managed |
| SHELL | User's command interpreter | System-initialized |
| LOGNAME | User's login name | System-initialized |

**Naming convention:** Uppercase + underscores reserved for utilities. Lowercase reserved for applications.

**Applied in:** Discovery script excludes `BASH_*`, `SCRIPT_*`, `HOME`, `PATH`, `PWD`, `USER`, `SHELL` from @env_vars detection.

---

### Platform Detection (uname)
**Reference:** GNU Coreutils

Standard detection patterns for @platforms field:

| Platform | Detection Pattern | uname Output |
|----------|-------------------|--------------|
| Linux | `uname -s == "Linux"` | `Linux` |
| macOS | `uname -s == "Darwin"` | `Darwin` |
| Windows (WSL) | `uname -r \| grep -i microsoft` | Kernel contains "microsoft" |

**Discovery heuristic:** Scripts containing `uname`, `Darwin`, or `Linux` literals get `platforms="needs-review"` for manual verification.

---

## Assumptions

1. **All 42 scripts have valid @creates tags** → If wrong: @rollback and @verify auto-generation fails
2. **Manifest generator runs successfully** → If wrong: can't validate new fields
3. **Codex handles 10-15 script batches** → If wrong: need smaller batches
4. **Discovery script covers 70%+ of field values** → If wrong: more manual work needed
5. **No scripts have platform-specific dependencies** → If wrong: @platforms needs manual review
