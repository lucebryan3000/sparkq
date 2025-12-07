# Claude Code Documentation

This directory contains local copies of the official Claude Code documentation from https://code.claude.com/docs

## Documentation Files

### Getting Started
- **[overview.md](overview.md)** - Introduction to Claude Code and key features
- **[quickstart.md](quickstart.md)** - 5-minute guide to get up and running

### Reference
- **[cli-reference.md](cli-reference.md)** - Complete CLI commands and flags reference
- **[slash-commands.md](slash-commands.md)** - All built-in and custom slash commands

### Features & Guides
The following documentation files are available online at https://code.claude.com/docs:

#### Core Features
- `common-workflows.md` - Real-world usage patterns and examples
- `interactive-mode.md` - Keyboard shortcuts and interactive features
- `memory.md` - Managing Claude's memory with CLAUDE.md files
- `plugins.md` - Extend Claude Code with plugins
- `skills.md` - Create and use Agent Skills
- `slash-commands.md` - Custom command reference
- `sub-agents.md` - Custom agents for specialized tasks

#### Configuration
- `settings.md` - Complete settings reference
- `model-config.md` - Model selection and configuration
- `terminal-config.md` - Terminal setup and optimization
- `statusline.md` - Custom status line display
- `vs-code.md` - VS Code extension and IDE integration
- `jetbrains.md` - JetBrains IDE integration

#### Advanced Features
- `mcp.md` - Model Context Protocol integration
- `hooks.md` - Hooks reference for event handling
- `hooks-guide.md` - Getting started with hooks
- `sandboxing.md` - Filesystem and network isolation
- `checkpointing.md` - Rewind and restore functionality
- `output-styles.md` - Customize output presentation

#### Cloud & Deployment
- `headless.md` - Using Claude Code without a terminal
- `claude-code-on-the-web.md` - Web-based Claude Code
- `devcontainer.md` - Development containers
- `github-actions.md` - GitHub Actions integration
- `gitlab-ci-cd.md` - GitLab CI/CD integration

#### Cloud Provider Setup
- `amazon-bedrock.md` - Amazon Bedrock configuration
- `google-vertex-ai.md` - Google Vertex AI setup
- `microsoft-foundry.md` - Microsoft Foundry configuration
- `network-config.md` - Network and proxy configuration
- `llm-gateway.md` - LLM gateway configuration

#### Administration & Monitoring
- `setup.md` - Installation and system requirements
- `iam.md` - Identity and access management
- `security.md` - Security features and best practices
- `costs.md` - Cost tracking and optimization
- `monitoring-usage.md` - OpenTelemetry monitoring
- `analytics.md` - Usage analytics
- `plugin-marketplaces.md` - Creating and managing plugin marketplaces
- `third-party-integrations.md` - Third-party integration guides

#### Troubleshooting & Help
- `troubleshooting.md` - Common issues and solutions
- `legal-and-compliance.md` - Legal and compliance information

## How to Use This Documentation

### Local Reference
These documentation files are optimized for quick local reference. You can:
- Read them directly in your editor or terminal
- Search them with grep or your editor's search function
- Reference them without needing internet connectivity

### Online Version
For the most up-to-date documentation with interactive features, visit:
**https://code.claude.com/docs**

## Key Sections

### Quick Links
- **Setup**: Read `setup.md` and `quickstart.md`
- **Commands**: Check `cli-reference.md` for CLI options
- **Slash Commands**: See `slash-commands.md` for all available commands
- **Troubleshooting**: Start with `troubleshooting.md`
- **Security**: Read `security.md` and `iam.md`
- **Team Setup**: See `settings.md` and `iam.md`

## Document Organization

### By User Type
**For beginners:**
1. overview.md
2. quickstart.md
3. common-workflows.md
4. interactive-mode.md

**For developers:**
1. cli-reference.md
2. slash-commands.md
3. mcp.md
4. hooks-guide.md
5. plugins.md

**For administrators:**
1. setup.md
2. iam.md
3. security.md
4. monitoring-usage.md
5. costs.md

## Fetching Latest Documentation

To update the documentation to the latest version from code.claude.com, run:

```bash
# Fetch all documentation
./fetch-docs.sh

# Or fetch specific sections
./fetch-docs.sh getting-started
./fetch-docs.sh reference
```

## Contributing

These are official Claude Code documentation files. For corrections or suggestions:
- File issues on GitHub: https://github.com/anthropics/claude-code
- Contribute to documentation: https://github.com/anthropics/claude-code

## License

Claude Code and its documentation are copyright Anthropic. See the LICENSE file for details.

---

**Last Updated**: December 2025
**Source**: https://code.claude.com/docs
**Version**: Matches latest Claude Code release