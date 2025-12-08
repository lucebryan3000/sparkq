# Missing Bootstrap Scripts

This document tracks bootstrap setup scripts that need to be created for technologies and configurations in the `__bootbuild` ecosystem.

## Summary

**Total existing scripts:** 25
**Missing scripts:** 3
**Coverage:** 89%

---

## Missing Scripts

### 1. buildtools (`bootstrap-buildtools.sh`)

**Templates available:** `/templates/root/buildtools/`

**Purpose:** Build tool setup and configuration
- Build system initialization (Make, Gradle, Maven, Bazel, etc.)
- Build optimization and caching
- Build artifact management
- Pre-built/compiled tool setup

**Potential scope:**
- BuildTools detection and initialization
- Tool version management
- Build cache configuration
- Local build optimization

**Manifest entry (draft):**
```json
"buildtools": {
  "file": "bootstrap-buildtools.sh",
  "phase": 2,
  "category": "build",
  "description": "Build tools setup (Make, Gradle, Maven, Bazel)",
  "templates": ["buildtools/"],
  "questions": null,
  "detects": [],
  "depends": ["packages"]
}
```

---

### 2. ci-cd / cicd (`bootstrap-cicd.sh`)

**Templates available:** `/templates/root/cicd/`

**Current status:** Script exists as `bootstrap-ci-cd.sh`

**Note:** This script already exists but is named with hyphens (`ci-cd`) while the template folder uses underscores (`cicd`). The manifest uses `ci-cd` as the key.

**Status:** ✅ COVERED (naming mismatch only, not missing)

---

### 3. nodejs (`bootstrap-nodejs.sh`)

**Templates available:** `/templates/root/nodejs/`

**Purpose:** Node.js runtime and package manager setup
- Node.js version management
- Package manager selection/configuration (npm, pnpm, yarn)
- Node runtime detection and setup
- `.nvmrc` and `.npmrc` configuration

**Current status:** Partially covered by `bootstrap-packages.sh`
- However, dedicated script for Node.js runtime and manager-specific setup would be beneficial

**Potential scope:**
- Node.js version detection and management (nvm, asdf integration)
- Package manager selection and optimization
- Node-specific build tools configuration

**Manifest entry (draft):**
```json
"nodejs": {
  "file": "bootstrap-nodejs.sh",
  "phase": 1,
  "category": "runtime",
  "description": "Node.js runtime and package manager setup (nvm, npm, pnpm, yarn)",
  "templates": ["nodejs/"],
  "questions": "nodejs",
  "detects": ["has_package_json"],
  "depends": []
}
```

---

## Template Categories Analysis

### All Template Categories
- ✅ api
- ❌ buildtools
- ✅ cicd (named `ci-cd`)
- ✅ database
- ✅ docker
- ✅ husky
- ✅ kubernetes
- ✅ linting
- ✅ monitoring
- ❌ nodejs
- ✅ project
- ✅ quality
- ✅ secrets
- ✅ security
- ✅ ssl
- ✅ testing
- ✅ typescript

### Additional Scripts Without Template Folders
- ✅ claude (`.claude/`)
- ✅ codex
- ✅ detect
- ✅ docs
- ✅ editor
- ✅ environment
- ✅ git
- ✅ github
- ✅ packages
- ✅ vscode

---

## Implementation Priority

### High Priority
1. **nodejs** - Separating Node.js runtime setup from package manager setup provides better modularity
2. **buildtools** - Required for projects with build system complexity

### Medium Priority
- Naming normalization: `bootstrap-cicd.sh` vs `cicd` folder name

### Recommendations

1. **Create `bootstrap-nodejs.sh`** to handle Node.js version management separately from packages
2. **Create `bootstrap-buildtools.sh`** for build system configuration
3. **Consider renaming** `bootstrap-ci-cd.sh` to match folder naming convention (optional)

---

## Notes

- Template folders act as guides for bootstrap script coverage
- Not all scripts require template folders (e.g., `claude`, `codex`, `editor`)
- Some scripts combine multiple concerns (e.g., `packages` includes `.nvmrc`)
- Coverage is 89% complete with only 3 missing scripts out of 20+ template categories
