---
description: Generate documentation for code, create JSDoc, or update README
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
---

# Document Command

Generate comprehensive documentation for code, add JSDoc comments, or update project documentation.

## Usage

```
/document src/services/api.ts
# Generate JSDoc for all exports

/document api
# Document entire module

/document --readme
# Update README with architecture overview

/document --types
# Generate type documentation
```

## Documentation Types

- **JSDoc**: Generate function/class documentation comments
- **Architecture**: Document system design and data flow
- **API**: Document endpoints and request/response formats
- **Types**: Document TypeScript interfaces and types
- **README**: Update project documentation and setup guides

## Output Includes

- Function signatures and parameters
- Return types and examples
- Usage examples
- Edge cases and limitations
- Cross-references to related code
