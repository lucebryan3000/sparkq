# Bootstrap System Feature Roadmap

> **Purpose**: Future features to implement after Phase A (Question Engine Integration)
> **Status**: Backlog - ready for implementation
> **Last Updated**: 2025-12-07

---

## Phase B: Template System Enhancement

### Goal
Make template copying dynamic with variable substitution and conditional sections.

### Tasks

1. **Template Variable Substitution**
   - Replace `{{PROJECT_NAME}}`, `{{AUTHOR}}`, etc. in templates
   - Read values from bootstrap.config
   - Support nested variables like `{{docker.database_type}}`

2. **Conditional Template Sections**
   - Support `{{#if docker.enabled}}...{{/if}}` blocks
   - Enable/disable sections based on config values
   - Handle nested conditionals

3. **Template Registry**
   - Track which templates have been applied
   - Detect template conflicts
   - Support template versioning for updates

4. **Implementation Files**
   - `lib/template-engine.sh` - Variable substitution and conditionals
   - Update `lib/template-utils.sh` - Use new engine
   - Templates use mustache-like syntax: `{{variable}}`

### Example
```bash
# templates/docker/docker-compose.yml
version: '3.8'
services:
  app:
    container_name: {{project.name}}-app
    ports:
      - "{{docker_defaults.app_port}}:3000"
  {{#if docker.database_type == "postgres"}}
  db:
    image: postgres:15
    ports:
      - "{{docker_defaults.database_port}}:5432"
  {{/if}}
```

---

## Phase C: Smart Recommendations in Menu

### Goal
Menu suggests scripts based on detected environment and project state.

### Tasks

1. **Environment Detection Enhancement**
   - Detect existing frameworks (Next.js, Vite, Express, etc.)
   - Identify missing configurations
   - Score project "completeness"

2. **Recommendation Engine**
   - Calculate which scripts are most relevant
   - Prioritize based on dependencies
   - Show "recommended" scripts first in menu

3. **Project Analysis**
   - Scan package.json for framework hints
   - Check existing config files
   - Identify gaps in setup

4. **Implementation Files**
   - `lib/recommendation-engine.sh` - Logic for recommendations
   - Update `scripts/bootstrap-menu.sh` - Display recommendations
   - `config/detection-rules.json` - Framework detection patterns

### Example Menu Output
```
═══════════════════════════════════════════════════════
   Bootstrap Menu v2.0.0 - my-project Setup
═══════════════════════════════════════════════════════

📊 RECOMMENDED FOR YOUR PROJECT:
   Detected: Next.js, TypeScript, no testing

   → 1. testing     (adds Vitest + Playwright)
   → 2. linting     (adds ESLint + Prettier)
   → 3. husky       (adds pre-commit hooks)

🔴 PHASE 1: AI Development Toolkit
   ✓ claude (already configured)
   ✓ git (already configured)
   ...
```

---

## Phase D: Profile Execution & Dry Run

### Goal
Run predefined profiles and preview changes before applying.

### Tasks

1. **Profile Execution**
   - `./bootstrap-menu.sh --profile=standard` runs all profile scripts
   - Respect dependencies and order
   - Track progress and allow resume

2. **Dry Run Mode**
   - `./bootstrap-menu.sh --dry-run` shows what would be created
   - List all files that would be created/modified
   - Show config changes that would be made

3. **Rollback Support**
   - Track all changes made in session
   - Generate rollback script
   - Allow undo of last bootstrap run

4. **Progress Persistence**
   - Save progress to `.cache/session.json`
   - Resume interrupted sessions
   - Mark scripts as "completed" or "failed"

5. **Implementation Files**
   - `lib/session-manager.sh` - Progress tracking
   - `lib/rollback-engine.sh` - Change tracking and undo
   - Update `scripts/bootstrap-menu.sh` - New modes

### Example Commands
```bash
# Run standard profile
./bootstrap-menu.sh --profile=standard -y

# Preview what standard profile would do
./bootstrap-menu.sh --profile=standard --dry-run

# Resume interrupted session
./bootstrap-menu.sh --resume

# Rollback last run
./bootstrap-menu.sh --rollback
```

---

## Phase E: Advanced Features (Future)

### Ideas for Later
- **Interactive Profile Builder**: Create custom profiles interactively
- **Remote Templates**: Pull templates from GitHub repos
- **Plugin System**: Third-party bootstrap scripts
- **Project Validation**: Check project against best practices
- **Migration Scripts**: Upgrade configs when templates update
- **Multi-Project Support**: Bootstrap monorepo workspaces

---

## Implementation Priority

| Phase | Complexity | Value | Priority |
|-------|------------|-------|----------|
| B - Templates | Medium | High | 1 |
| C - Recommendations | Medium | Medium | 2 |
| D - Profiles/Dry-Run | High | High | 3 |
| E - Advanced | High | Medium | Backlog |

---

## Notes

- Each phase builds on previous work
- Phase B is most impactful for developer experience
- Phase C improves discoverability
- Phase D adds safety and automation
- All phases maintain backward compatibility with existing scripts
