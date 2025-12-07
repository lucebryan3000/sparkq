# Bootstrap System Deployment Guide

> Comprehensive guide for deploying the SparkQ Bootstrap System to new projects.

---

## Overview

The SparkQ Bootstrap System automates project setup through 4 phases of interactive scripts:
- **Phase 1**: AI Development Toolkit (Claude, Git, VS Code, Dependencies)
- **Phase 2**: Infrastructure (Docker, Linting, Editor)
- **Phase 3**: Testing & Quality
- **Phase 4**: CI/CD & Deployment

This document covers deploying the bootstrap system itself to a new project.

---

## Quick Start

### For the Impatient

```bash
# Copy bootstrap to your project
cp -r /path/to/sparkq/bootstrap ./

# Run standard profile (recommended)
./bootstrap/scripts/bootstrap-menu.sh --profile=standard --yes

# Verify
npm install && npm run lint && npm test
```

**Time**: ~5 minutes
**Result**: Fully configured project ready for development

---

## Prerequisites

### System Requirements

- **OS**: macOS, Linux, or WSL2 (Windows)
- **Shell**: Bash 4.0+
- **Git**: 2.0+
- **Node.js**: 18+ (will be installed during bootstrap)
- **Disk Space**: ~500MB
- **Internet**: Required for package manager and GitHub

### Permissions

- Write access to project directory
- No `sudo` required (bootstrap doesn't modify system files)
- Can create files and directories in project root

### Pre-Bootstrap Setup

```bash
# Create project directory
mkdir my-new-project
cd my-new-project

# Initialize git (optional, bootstrap-git.sh can do this)
git init

# Create basic README
echo "# My Project" > README.md
git add README.md
git commit -m "Initial commit"
```

---

## Installation Methods

### Method 1: Copy from Template Repository

```bash
# Clone sparkq to get templates
git clone https://github.com/appmelia/sparkq.git /tmp/sparkq

# Copy bootstrap system to your project
cp -r /tmp/sparkq/bootstrap ./my-project/bootstrap

# Initialize
cd my-project/bootstrap
./scripts/bootstrap-menu.sh
```

### Method 2: Download Specific Files

```bash
# If you only need specific parts
mkdir bootstrap
wget -q https://github.com/appmelia/sparkq/raw/main/bootstrap/scripts/bootstrap-menu.sh
wget -q https://github.com/appmelia/sparkq/raw/main/bootstrap/lib/common.sh

# This method requires manual file management - not recommended
```

### Method 3: Use as Git Submodule

```bash
# Add sparkq as submodule
git submodule add https://github.com/appmelia/sparkq.git

# Use specific bootstrap directory
ln -s sparkq/bootstrap ./bootstrap

# Initialize
./bootstrap/scripts/bootstrap-menu.sh
```

---

## Deployment Workflow

### Phase 0: Preparation

```bash
# 1. Verify prerequisites
node --version  # Should be 18.0.0 or higher
npm --version
git --version

# 2. Check project structure
ls -la
# Should have: README.md, .git/, and soon: bootstrap/

# 3. Ensure project is writable
touch .bootstrap-test && rm .bootstrap-test && echo "✓ Writable"
```

### Phase 1: Run Bootstrap Menu

#### Interactive Mode (Recommended)

```bash
# Launch interactive menu
./bootstrap/scripts/bootstrap-menu.sh --interactive

# Menu displays:
#  1. bootstrap-claude.sh    - Claude Code integration
#  2. bootstrap-git.sh       - Git configuration
#  3. bootstrap-vscode.sh    - VS Code setup
#  4. bootstrap-codex.sh     - OpenAI Codex
#  5. bootstrap-packages.sh  - Package management
#  6. bootstrap-typescript.sh- TypeScript config
#  7. bootstrap-environment.sh - Environment setup
#  ... and more

# Enter script number to run, 'h' for help, 'q' to quit
```

#### Profile Mode (Recommended for CI/CD)

```bash
# Standard profile (most projects)
./bootstrap/scripts/bootstrap-menu.sh --profile=standard --yes

# Or choose profile:
# - minimal: claude, git, packages
# - standard: minimal + vscode, typescript, environment, linting, editor
# - full: all scripts
# - api: backend-focused (no vscode/editor)
# - frontend: frontend-focused (no docker/testing)
# - library: library-focused
```

#### Custom Phase Execution

```bash
# Run all Phase 1 scripts (AI toolkit)
./bootstrap/scripts/bootstrap-menu.sh --phase=1 --yes

# Run Phase 2 (Infrastructure)
./bootstrap/scripts/bootstrap-menu.sh --phase=2 --yes

# Dry run (preview without changes)
./bootstrap/scripts/bootstrap-menu.sh --phase=1 --dry-run
```

### Phase 2: Verify Results

```bash
# Check created files
ls -la | grep "^\-"  # Show dotfiles

# Expected files:
# .npmrc          ✓
# .nvmrc          ✓
# .tool-versions  ✓
# .envrc          ✓
# package.json    ✓
# .gitignore      ✓
# .gitattributes  ✓

# Verify each file
[[ -f .npmrc ]] && echo "✓ .npmrc"
[[ -f .nvmrc ]] && echo "✓ .nvmrc"
[[ -f package.json ]] && echo "✓ package.json"
```

### Phase 3: Install Dependencies

```bash
# Install Node packages
npm install

# Verify installation
npm list | head -20

# Check build
npm run build

# Lint (if configured)
npm run lint
```

### Phase 4: Configure Environment

```bash
# Create environment files
cp .env.example .env       # Template → tracked
# Create .env.local        # Not tracked, secrets go here

# Edit .env
vim .env

# Edit .env.local (add secrets)
cat > .env.local << 'EOF'
API_KEY=your-secret-key
DATABASE_PASSWORD=secret
OPENAI_API_KEY=sk-...
EOF

# Add to .gitignore (usually done by bootstrap-git.sh)
echo ".env.local" >> .gitignore
```

---

## Configuration After Bootstrap

### Project Customization

#### package.json

```json
{
  "name": "your-project-name",        // ← Update this
  "version": "0.0.1",
  "description": "Project description", // ← Update this
  "type": "module",
  "scripts": {
    "dev": "node --watch src/index.js",
    "build": "tsc",
    "test": "node --test",
    "lint": "eslint src/",
    "format": "prettier --write ."
  }
}
```

#### TypeScript Configuration

If using TypeScript (recommended):

```bash
# Verify tsconfig.json was created
cat tsconfig.json

# Key settings:
# {
#   "compilerOptions": {
#     "target": "ES2020",
#     "module": "ES2020",
#     "lib": ["ES2020"],
#     "moduleResolution": "node",
#     "strict": true,
#     "esModuleInterop": true,
#     "skipLibCheck": true,
#     "forceConsistentCasingInFileNames": true
#   }
# }
```

#### Environment Variables

```bash
# Bootstrap creates .env template, now customize it:

# .env (tracked - public config)
NODE_ENV=development
LOG_LEVEL=debug
API_BASE_URL=https://api.example.com
FRONTEND_URL=http://localhost:3000

# .env.local (NOT tracked - secrets)
# Add to .gitignore if not already there
echo ".env.local" >> .gitignore

# Create .env.local with secrets
cat > .env.local << 'EOF'
DATABASE_URL=postgresql://user:password@localhost/dbname
API_KEY=sk-...
GITHUB_TOKEN=ghp_...
OPENAI_API_KEY=sk-...
EOF
```

---

## Verification & Testing

### Syntax Validation

```bash
# Validate all bootstrap scripts
for script in bootstrap/templates/scripts/*.sh; do
  bash -n "$script" && echo "✓ $(basename $script)" || echo "✗ $(basename $script)"
done

# Check manifest
jq empty bootstrap/config/bootstrap-manifest.json && echo "✓ Manifest valid"

# Validate paths
./bootstrap/scripts/bootstrap-paths-validate.sh
```

### Dependency Checks

```bash
# List installed packages
npm list

# Check for vulnerabilities
npm audit

# Update dependencies (careful!)
npm update

# Check outdated packages
npm outdated
```

### Code Quality

```bash
# Run linter
npm run lint

# Format code
npm run format

# Run tests
npm test

# Build project
npm run build
```

### Git Setup

```bash
# Verify git is configured
git config --list

# Check .gitignore
cat .gitignore

# Verify .gitattributes (for consistent line endings)
cat .gitattributes

# Check git status
git status
```

---

## Troubleshooting Deployment

### Issue: "bootstrap-menu.sh: Permission denied"

```bash
# Make scripts executable
chmod +x bootstrap/scripts/*.sh
chmod +x bootstrap/templates/scripts/*.sh

# Run again
./bootstrap/scripts/bootstrap-menu.sh
```

### Issue: "BOOTSTRAP_DIR not found"

```bash
# Ensure you're in project root
pwd  # Should show your-project/

# Verify bootstrap/ exists
ls bootstrap/

# Run from correct directory
cd /path/to/project
./bootstrap/scripts/bootstrap-menu.sh
```

### Issue: "Node.js is not installed"

```bash
# Install Node.js
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install node

# Or using Homebrew (macOS)
brew install node

# Or using asdf
asdf install nodejs
asdf global nodejs <version>

# Verify
node --version
npm --version
```

### Issue: "Cannot write to .npmrc"

```bash
# Check permissions
ls -la .npmrc

# Backup and fix
cp .npmrc .npmrc.backup
chmod 644 .npmrc

# Or remove and regenerate
rm .npmrc
./bootstrap/templates/scripts/bootstrap-packages.sh
```

### Issue: "manifest-cache.json not found"

```bash
# Regenerate manifest
cd bootstrap
./scripts/bootstrap-manifest-gen.sh --validate

# Verify
ls config/bootstrap-manifest.json
```

### Issue: Dependencies fail to install

```bash
# Clear npm cache
npm cache clean --force

# Delete lock file and reinstall
rm package-lock.json
npm install

# Check for peer dependency issues
npm install --legacy-peer-deps  # If needed
```

### Issue: Scripts interrupted (Ctrl+C)

```bash
# Check bootstrap log for progress
cat bootstrap/bootstrap.log

# See what ran
grep "✓" bootstrap/bootstrap.log

# See what failed
grep "✗" bootstrap/bootstrap.log

# Rerun from interrupted phase
./bootstrap/scripts/bootstrap-menu.sh --phase=2 --yes
```

---

## Uninstall / Rollback

### Remove Bootstrap System Entirely

```bash
# Keep project, remove bootstrap
rm -rf bootstrap/

# Restore tracked files from git
git checkout .npmrc .nvmrc .tool-versions .envrc .gitignore

# Restore from backup (if using timestamps)
# Find backups created during bootstrap
find . -name "*.backup.*" -type f | xargs ls -lh
```

### Selective Rollback

```bash
# Restore specific file from backup
mv .npmrc.backup.1733606400 .npmrc

# Restore all backups in directory
for file in *.backup.*; do
  original="${file%.backup*}"
  [[ -f "$file" ]] && mv "$file" "$original"
done
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Bootstrap on New PR

on: [pull_request]

jobs:
  bootstrap:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Run bootstrap
        run: |
          ./bootstrap/scripts/bootstrap-menu.sh --profile=standard --yes

      - name: Verify
        run: |
          npm install
          npm run lint
          npm test
          npm run build
```

### GitLab CI

```yaml
bootstrap:
  stage: setup
  script:
    - ./bootstrap/scripts/bootstrap-menu.sh --profile=standard --yes
    - npm install
    - npm run lint
  artifacts:
    paths:
      - bootstrap/bootstrap.log
```

---

## Best Practices

### ✅ Do's

- Run bootstrap immediately after `git init`
- Use `--profile` for reproducible deployments
- Commit `bootstrap/` directory to git
- Keep bootstrap system up-to-date
- Use bootstrap logs for troubleshooting
- Run verification checks after bootstrap

### ❌ Don'ts

- Don't run bootstrap as root (uses `sudo`)
- Don't modify bootstrap system unless extending
- Don't ignore bootstrap errors
- Don't commit `.env.local` or secrets
- Don't use `--force` flag without understanding consequences
- Don't modify scripts without testing

---

## Advanced Usage

### Dry Run (Preview Changes)

```bash
# See what would run without executing
./bootstrap/scripts/bootstrap-menu.sh --phase=1 --dry-run

# Example output:
# [DRY RUN] Would run: bootstrap-claude.sh
# [DRY RUN] Would run: bootstrap-git.sh
# ... etc
```

### Custom Profiles

Edit `bootstrap/config/bootstrap.config` to create custom profiles:

```bash
# Example: minimal-backend profile
profiles.minimal-backend=claude,git,packages,docker
```

Then run:
```bash
./bootstrap/scripts/bootstrap-menu.sh --profile=minimal-backend --yes
```

### Debug Mode

```bash
# Enable verbose logging
export BOOTSTRAP_DEBUG=true
./bootstrap/scripts/bootstrap-menu.sh --phase=1

# Or see what happens without running
BOOTSTRAP_DEBUG=true ./bootstrap/scripts/bootstrap-menu.sh --dry-run
```

---

## Support & Resources

- **Issues**: Check `bootstrap/bootstrap.log`
- **Docs**: See `bootstrap/docs/` directory
- **Scripts**: See `bootstrap/templates/scripts/` for implementation
- **Config**: See `bootstrap/config/` for settings
- **Templates**: See `bootstrap/templates/` for file templates

---

## Checklist: Deployment Complete?

- [ ] Bootstrap scripts downloaded
- [ ] All prerequisite tools installed
- [ ] Bootstrap menu runs without errors
- [ ] All expected files created (.npmrc, .nvmrc, etc.)
- [ ] `npm install` succeeds
- [ ] `npm run lint` passes
- [ ] `npm test` passes (if tests exist)
- [ ] `npm run build` succeeds (if build exists)
- [ ] `.env` and `.env.local` configured
- [ ] Git repository initialized with commits
- [ ] GitHub workflows configured (if using CI/CD)
- [ ] Team members can run bootstrap successfully

---

**Last Updated**: 2025-12-07
**Version**: 1.0
**Status**: Production-Ready
**Next**: Begin development with `npm run dev`
