# Deployment Guide

> This guide covers deploying projects that have been bootstrapped with the SparkQ Bootstrap System.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Bootstrap Deployment Steps](#bootstrap-deployment-steps)
3. [Environment Configuration](#environment-configuration)
4. [Verification & Testing](#verification--testing)
5. [Rollback Procedures](#rollback-procedures)
6. [Troubleshooting](#troubleshooting)

---

## Pre-Deployment Checklist

### Required Tools
- [ ] Node.js installed (version from `.nvmrc`)
- [ ] Git configured globally
- [ ] Package manager installed (`npm`, `pnpm`, or `yarn`)
- [ ] Docker installed (if using devcontainer)
- [ ] GitHub CLI (`gh`) installed (if using GitHub workflows)

### Project Setup
- [ ] Project directory initialized (`git init`)
- [ ] `.gitignore` file in place
- [ ] `.env.local` created with sensitive values
- [ ] `.env` file created with non-sensitive config
- [ ] `package.json` exists with `type: "module"` (if ES modules)

### Code Quality
- [ ] Linting rules defined (`.eslintrc`)
- [ ] TypeScript configured (`tsconfig.json`)
- [ ] Test framework selected and configured
- [ ] Build scripts defined in `package.json`

---

## Bootstrap Deployment Steps

### Step 1: Initialize Bootstrap System

```bash
# Clone or copy bootstrap templates to your project
cp -r bootstrap/ your-project/

# Navigate to bootstrap directory
cd your-project/bootstrap

# Generate manifest (auto-discovers structure)
./scripts/bootstrap-manifest-gen.sh --validate
```

### Step 2: Run Bootstrap Menu

```bash
# Interactive menu mode
./scripts/bootstrap-menu.sh --interactive

# Or run specific profile
./scripts/bootstrap-menu.sh --profile=standard --yes

# Or run specific phase
./scripts/bootstrap-menu.sh --phase=1 --yes
```

### Step 3: Choose Bootstrap Profile

**Minimal** (3 scripts): `claude`, `git`, `packages`
```bash
./scripts/bootstrap-menu.sh --profile=minimal --yes
```

**Standard** (8 scripts): `claude`, `git`, `vscode`, `packages`, `typescript`, `environment`, `linting`, `editor`
```bash
./scripts/bootstrap-menu.sh --profile=standard --yes
```

**Full** (all scripts): Includes docker, testing, github, devcontainer, documentation
```bash
./scripts/bootstrap-menu.sh --profile=full --yes
```

**API** (backend): `claude`, `git`, `packages`, `typescript`, `environment`, `docker`, `testing`
```bash
./scripts/bootstrap-menu.sh --profile=api --yes
```

**Frontend**: `claude`, `git`, `vscode`, `packages`, `typescript`, `linting`, `editor`
```bash
./scripts/bootstrap-menu.sh --profile=frontend --yes
```

**Library**: `claude`, `git`, `packages`, `typescript`, `linting`, `testing`
```bash
./scripts/bootstrap-menu.sh --profile=library --yes
```

### Step 4: Verify Installation

```bash
# Check Node version
node --version

# Check npm version
npm --version

# Check git status
git status

# List created files
ls -la | grep -E "^-"  # Show all dotfiles
```

---

## Environment Configuration

### Create `.env.local` (Git-ignored)

```bash
# Development environment
NODE_ENV=development

# API Configuration
API_KEY=your-secret-key
API_BASE_URL=https://api.dev.example.com

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# Third-party services
OPENAI_API_KEY=sk-...
GITHUB_TOKEN=ghp_...
```

**Important**: Never commit `.env.local` - it's in `.gitignore`

### Create `.env` (Git-tracked, non-secrets)

```bash
# Public configuration
NODE_ENV=development
LOG_LEVEL=debug
DEBUG=app:*

# Public service URLs
API_BASE_URL=https://api.example.com
FRONTEND_URL=http://localhost:3000
```

### Update `package.json`

```json
{
  "name": "your-project-name",
  "version": "0.0.1",
  "description": "Your project description",
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

---

## Verification & Testing

### Step 1: Syntax Validation

```bash
# Validate all shell scripts
for script in bootstrap/templates/scripts/bootstrap-*.sh; do
  bash -n "$script" && echo "✓ $(basename $script)" || echo "✗ $(basename $script)"
done
```

### Step 2: Configuration Validation

```bash
# Check manifest is valid
jq empty bootstrap/config/bootstrap-manifest.json && echo "✓ Manifest valid" || echo "✗ Invalid manifest"

# Check config file
[[ -f bootstrap/config/bootstrap.config ]] && echo "✓ Config file exists" || echo "✗ Config missing"
```

### Step 3: Dependency Check

```bash
# Install dependencies
npm install

# Run linter (if configured)
npm run lint

# Run tests (if configured)
npm test

# Check build (if applicable)
npm run build
```

### Step 4: Git Setup Verification

```bash
# Check git status
git status

# Check .gitignore is in place
cat .gitignore | head -20

# Verify git hooks (if any)
ls -la .git/hooks/
```

---

## Rollback Procedures

### Backup Locations

The bootstrap system creates timestamped backups:
```bash
# Find all backups
find . -name "*.backup.*" -type f

# Example:
# .npmrc.backup.1733606400
# .gitignore.backup.1733606401
```

### Restore from Backup

```bash
# Restore specific file
mv .npmrc.backup.1733606400 .npmrc

# Restore all files in a directory
for backup in bootstrap/config/*.backup.*; do
  original="${backup%.backup*}"
  mv "$backup" "$original"
done
```

### Full Bootstrap Rollback

```bash
# Remove bootstrap system entirely
rm -rf bootstrap/

# Restore from git (if committed before bootstrap)
git checkout .npmrc .nvmrc .tool-versions .envrc

# Or restore from backup directory
cp ~/.trash/bootstrap-backup/* ./
```

---

## Troubleshooting

### Issue: "Node.js is not installed"

**Solution**:
```bash
# Install Node.js using nvm
curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install

# Or using asdf
asdf install nodejs
```

### Issue: "Permission denied: bootstrap-menu.sh"

**Solution**:
```bash
# Make scripts executable
chmod +x bootstrap/scripts/*.sh
chmod +x bootstrap/templates/scripts/*.sh
```

### Issue: "Cannot write to .npmrc"

**Solution**:
```bash
# Check file permissions
ls -la .npmrc

# Fix permissions (backup first)
cp .npmrc .npmrc.backup
chmod 644 .npmrc

# Or remove and regenerate
rm .npmrc
./bootstrap/templates/scripts/bootstrap-packages.sh
```

### Issue: "bootstrap-manifest.json not found"

**Solution**:
```bash
# Regenerate manifest
cd bootstrap
./scripts/bootstrap-manifest-gen.sh --validate

# Check it was created
ls -la config/bootstrap-manifest.json
```

### Issue: Interrupted deployment

**Solution**:
```bash
# Check bootstrap log
cat bootstrap/bootstrap.log

# Find where it stopped
tail bootstrap/bootstrap.log

# Rerun specific script
./bootstrap/templates/scripts/bootstrap-typescript.sh

# Or start from interrupted phase
./bootstrap/scripts/bootstrap-menu.sh --phase=2
```

### Issue: "Bootstrap profile not found"

**Solution**:
```bash
# List available profiles
./bootstrap/scripts/bootstrap-menu.sh --list

# Use valid profile name
./bootstrap/scripts/bootstrap-menu.sh --profile=standard --yes
```

---

## Deployment Checklist (Final)

Before considering deployment complete:

- [ ] All bootstrap scripts ran successfully
- [ ] No error messages in `bootstrap/bootstrap.log`
- [ ] `.npmrc`, `.nvmrc`, `.tool-versions`, `.envrc` created
- [ ] `package.json` customized with project name
- [ ] `.env` and `.env.local` configured
- [ ] Dependencies installed (`npm install`)
- [ ] Linting passes (`npm run lint`)
- [ ] Tests pass (if configured)
- [ ] Build succeeds (if applicable)
- [ ] Git repository initialized with commits
- [ ] GitHub workflows configured (if using CI/CD)
- [ ] Docker image builds (if using devcontainer)

---

## Next Steps

After bootstrap deployment:

1. **Start Development**: `npm run dev`
2. **Run Tests**: `npm test`
3. **Create First Feature Branch**: `git checkout -b feature/initial-setup`
4. **Configure IDE**: VS Code extensions and settings
5. **Set Up Linting Hooks**: Pre-commit hooks for automatic linting
6. **Configure CI/CD**: GitHub Actions workflows (if applicable)

---

## Reference

- [SparkQ Bootstrap README](00_BOOTSTRAP_TEMPLATES_README.md)
- [Bootstrap Menu Structure](BOOTSTRAP_MENU_STRUCTURE.md)
- [Implementation Guide](Bootstrap%20Playbooks%20-%20Script%20Implementation%20Guide.md)
- [Bootstrap Script List](IMPLEMENTATION_SUMMARY.md)

---

**Last Updated**: 2025-12-07
**Version**: 1.0
**Status**: Production-Ready
