---
description: Analyze code structure, dependencies, and architecture
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Analyze Command

Analyze the selected code or specified files for:
- Architecture and structure
- Key dependencies
- Code organization patterns
- Potential issues
- Performance characteristics

## Usage

```
/analyze
# Analyzes selection or current file

/analyze src/services
# Analyzes specific directory

/analyze src/components/Button.tsx src/hooks/use-button.ts
# Analyzes multiple files
```

## Analysis Includes

- **Structure**: File organization and module relationships
- **Complexity**: Cyclomatic complexity and cognitive load
- **Dependencies**: External and internal dependencies
- **Patterns**: Design patterns used
- **Issues**: Potential bugs or anti-patterns
- **Performance**: Time/space complexity concerns
