# Quickstart

> Get up and running with Claude Code in 5 minutes.

## Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

or using a package manager:

```bash
# macOS
brew install anthropic/claude-code/claude-code

# Ubuntu/Debian
sudo apt-get install claude-code
```

## Login

```bash
claude
```

The first time you run Claude Code, you'll be prompted to login with your Anthropic account.

## Start coding

Try these common tasks to get familiar with Claude Code:

### Ask Claude to read a file

```
> Explain what src/utils/helpers.ts does
```

Claude will read the file and provide an explanation.

### Ask Claude to write code

```
> Add a function to validate email addresses
```

Claude will write the code and ask for your approval before saving.

### Ask Claude to run tests

```
> Run the tests and fix any failures
```

Claude will run your test suite and fix issues that arise.

### Ask Claude to make a commit

```
> Create a git commit for the changes we just made
```

Claude will create a well-formatted commit message.

## Key commands

Once you're in the Claude Code REPL, try these commands:

| Command      | Purpose                                      |
| ------------ | -------------------------------------------- |
| `/help`      | List all available commands                  |
| `/config`    | Configure Claude Code settings              |
| `/memory`    | Edit your CLAUDE.md memory file              |
| `/model`     | Switch between Claude models                 |
| `/clear`     | Clear the conversation history              |
| `/exit`      | Exit Claude Code                             |
| `Ctrl+C`     | Cancel the current operation                 |
| `Ctrl+D`     | Exit Claude Code                             |
| `Esc, Esc`   | Rewind to a previous state                   |

## Next steps

* **Learn common workflows** - See [Common workflows](/en/common-workflows) for task examples
* **Explore keyboard shortcuts** - Check [Interactive mode](/en/interactive-mode) for all keybindings
* **Set up MCP servers** - Connect to GitHub, databases, etc. via [MCP](/en/mcp)
* **Create custom commands** - Build slash commands for your team via [Slash commands](/en/slash-commands)
* **Configure permissions** - Set up access controls via [IAM](/en/iam)

## Tips for success

* **Be specific** - "Add error handling to the login function" is better than "fix the code"
* **Use file references** - Use `@filename` to include files in your prompt
* **Ask for explanations** - "Explain what this code does" helps you learn
* **Iterate** - Use `/rewind` to try different approaches without losing progress
* **Provide context** - Mention the project type, framework, and goals

## Common questions

**Q: Is my code secure?**
A: Claude Code runs locally and only sends code to Claude's servers when you prompt it. See [Security](/en/security) for details.

**Q: Can I use this offline?**
A: No, Claude Code requires an internet connection to communicate with Claude's API.

**Q: What models does Claude Code use?**
A: Claude Code uses the latest Claude models by default. See [Model configuration](/en/model-config) to change models.

**Q: Can I use Claude Code with my team?**
A: Yes! Check [Project configuration](/en/settings) and [Plugins](/en/plugins) for team setup options.

---

> To find navigation and other pages in this documentation, fetch the llms.txt file at: https://code.claude.com/docs/llms.txt