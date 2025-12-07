# Claude Code Configuration

This directory contains all Claude Code-specific configuration and customization for the sparkq project.

## Directory Structure

```
.claude/
├── settings.json              # Team-shared project settings (commit to git)
├── settings.local.json        # Personal settings (git-ignored, use as template)
├── README.md                  # This file
│
├── agents/                    # Custom AI subagents
│   ├── code-reviewer.md       # Code review specialist
│   └── debugger.md            # Debug assistant
│
├── commands/                  # Custom slash commands
│   ├── analyze.md             # Analyze code structure
│   ├── test.md                # Run tests and create test files
│   └── document.md            # Generate documentation
│
├── hooks/                     # Hook script files
│   └── [custom scripts]
│
└── skills/                    # Complex reusable capabilities
    └── [ready for expansion]
```

## Files at Project Root

- **`.mcp.json`** - MCP (Model Context Protocol) server configuration
- **`CLAUDE.md`** - Project-specific instructions and conventions
- **`.claudeignore`** - Files excluded from Claude's auto-loaded context

## Quick Start

### Using Custom Agents

Agents extend Claude's capabilities for specialized tasks:

```bash
# Use the code reviewer agent
/agents code-reviewer
Review src/api/handler.ts for security issues

# Use the debugger agent
/agents debugger
The app crashes with "Cannot read property 'id' of undefined"
```

### Using Slash Commands

Commands provide quick access to common operations:

```bash
/analyze src/services
/test --watch
/document src/types
```

### Personal Configuration

1. Copy the example: `cp .claude/settings.local.json.example .claude/settings.local.json`
2. Edit with your personal preferences (model, debug level, etc.)
3. It will automatically override `settings.json` for you only
4. It's git-ignored, so your settings stay personal

## Configuration Hierarchy

Settings are applied in this order (highest priority first):

1. **Command line arguments** (temporary, single session)
2. **Local settings** (`.claude/settings.local.json`)
3. **Shared settings** (`.claude/settings.json`)
4. **User settings** (`~/.claude/settings.json`)

## Key Settings

### Permissions

**Allowed operations**:
- `npm run test:*` - Run tests
- `npm run lint:*` - Lint code
- `npm run build:*` - Build project
- `git log:*` - View git history
- `git diff:*` - View diffs

**Denied operations**:
- Reading `.env` files
- Reading secrets
- Force pushing
- Destructive rm commands

### Environment Variables

Key variables set for this project:

- `NODE_ENV=development` - Development mode by default
- `DISABLE_TELEMETRY=1` - Disable telemetry
- `GIT_AUTHOR_NAME` - Git attribution
- `DISABLE_COST_WARNINGS=0` - Show token usage

### Post-Tool Hooks

Automatic actions after Claude writes files:

- **TypeScript files** - ESLint auto-fix
- **JSON files** - JSON validation
- **Shell scripts** - Syntax validation
- **Docker Compose** - Configuration validation

## Adding Custom Agents

1. Create a new file in `.claude/agents/`: `my-agent.md`
2. Add YAML frontmatter with metadata
3. Write the agent instructions
4. Commit to git for team sharing

Example:

```markdown
---
description: My specialized agent
tools:
  - Bash
  - Read
  - Grep
model: claude-opus-4-5-20251101
---

# My Agent

You are an expert in...
```

## Adding Custom Commands

1. Create a new file in `.claude/commands/`: `my-command.md`
2. Optional: Add YAML frontmatter for permissions
3. Write the command prompt
4. Commit to git for team sharing

Example:

```markdown
---
description: Do something useful
allowed-tools:
  - Bash
  - Read
---

# My Command

Perform analysis on...
```

## MCP Servers

The `.mcp.json` file configures Model Context Protocol servers:

- **memory** - Persistent memory across sessions
- **github** - GitHub API access (requires GITHUB_TOKEN)
- **filesystem** - File system operations

Enable/disable as needed in `.mcp.json`.

## Team Collaboration

Files to commit to git (shared with team):
- `.claude/settings.json`
- `.claude/agents/**`
- `.claude/commands/**`
- `.claude/skills/**`
- `.claude/hooks/**`
- `CLAUDE.md`
- `.mcp.json`

Files NOT to commit (personal only):
- `.claude/settings.local.json`
- `.claude/settings.local.json.example` (can commit as template)

## Troubleshooting

### Commands Not Showing Up

1. Ensure file is in `.claude/commands/` directory
2. File name should not have spaces
3. Restart Claude Code if recently added

### Agents Not Running

1. Check YAML frontmatter syntax
2. Ensure all required fields are present
3. Verify file is in `.claude/agents/` directory

### Permissions Errors

Check `.claude/settings.json`:
- Is the operation in the `deny` list?
- Is the operation in the `allow` list?
- Check `defaultMode` setting

### Settings Not Applying

1. Ensure `.claude/settings.json` has valid JSON
2. Check file permissions (should be readable)
3. Restart Claude Code
4. Check for `settings.local.json` overrides

## Documentation

- [Claude Code Documentation](https://code.claude.com)
- [Settings Reference](https://code.claude.com/docs/en/settings.md)
- [Slash Commands Guide](https://code.claude.com/docs/en/slash-commands.md)
- [Subagents](https://code.claude.com/docs/en/sub-agents.md)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide.md)

## Additional Resources

- **[CLAUDE.md](../CLAUDE.md)** - Project conventions and development guidelines
- **[.claudeignore](../.claudeignore)** - Files excluded from context
- **[.mcp.json](../.mcp.json)** - MCP server configuration
