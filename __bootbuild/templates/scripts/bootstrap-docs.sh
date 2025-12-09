#!/bin/bash
# =============================================================================
# @name           bootstrap-docs
# @phase          4
# @category       setup
# @short          Documentation generation and management
# @description    Sets up documentation generation with TypeDoc for API docs,
#                 VitePress for site building, changelog generation,
#                 architecture documentation, and deployment configuration
#                 for hosting generated documentation.
#
# @creates        typedoc.json
# @creates        docs/api/openapi.yaml
# @creates        CHANGELOG.md
# @creates        docs/architecture/ARCHITECTURE.md
# @creates        docs/.vitepress/config.js
# @creates        docs/index.md
#
# @depends        bootstrap-project
# @defaults       DOC_TOOL=auto, DOC_SITE=vitepress, GENERATE_CHANGELOG=true
#
# @safe           yes
# @idempotent     yes
#
# @author         Bootstrap System
# @updated        2025-12-08
# =============================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-docs"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-docs"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "" \
    --scripts "bootstrap-project" \
    --optional "node npm"


# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Documentation Generation & Management" \
    "TypeDoc/JSDoc configuration" \
    "OpenAPI/Swagger specs" \
    "CHANGELOG.md generation" \
    "Architecture documentation" \
    "Documentation site (VitePress/Docusaurus)"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Configuration
# ===================================================================

# Get documentation configuration values (with defaults)
DOC_TOOL=$(get_config "docs.tool" "auto")  # auto, typedoc, jsdoc, swagger
DOC_SITE=$(get_config "docs.site" "vitepress")  # vitepress, docusaurus, none
GENERATE_CHANGELOG=$(get_config "docs.changelog" "true")
GENERATE_API_DOCS=$(get_config "docs.api" "true")
DOCS_DIR=$(get_config "docs.dir" "docs")

# Auto-detect documentation tool if set to auto
if [[ "$DOC_TOOL" == "auto" ]]; then
    log_info "Auto-detecting documentation tool..."

    if file_exists "$PROJECT_ROOT/package.json"; then
        # Check if TypeScript project
        if file_exists "$PROJECT_ROOT/tsconfig.json" || grep -q '"typescript"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            DOC_TOOL="typedoc"
            log_info "Detected TypeScript project, using TypeDoc"
        else
            DOC_TOOL="jsdoc"
            log_info "Detected JavaScript project, using JSDoc"
        fi
    elif file_exists "$PROJECT_ROOT/go.mod"; then
        DOC_TOOL="godoc"
        log_info "Detected Go project, using godoc"
    elif file_exists "$PROJECT_ROOT/Cargo.toml"; then
        DOC_TOOL="rustdoc"
        log_info "Detected Rust project, using rustdoc"
    else
        DOC_TOOL="markdown"
        log_info "No specific language detected, using Markdown only"
    fi
fi

# ===================================================================
# Detect Project Type
# ===================================================================

log_info "Detecting project type..."

PROJECT_TYPE="unknown"
HAS_TYPESCRIPT=false
HAS_JAVASCRIPT=false
HAS_API=false
HAS_GIT=false

if file_exists "$PROJECT_ROOT/package.json"; then
    PROJECT_TYPE="node"
    HAS_JAVASCRIPT=true

    if file_exists "$PROJECT_ROOT/tsconfig.json"; then
        HAS_TYPESCRIPT=true
    fi

    # Check for API frameworks
    if grep -qE '"(express|fastify|koa|hapi|nestjs)"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        HAS_API=true
    fi
fi

if dir_exists "$PROJECT_ROOT/.git"; then
    HAS_GIT=true
fi

log_success "Project type detected: $PROJECT_TYPE (TS: $HAS_TYPESCRIPT, API: $HAS_API, Git: $HAS_GIT)"

# ===================================================================
# Create Docs Directory Structure
# ===================================================================

log_info "Creating documentation directory structure..."

# Ensure docs directory exists
if ! dir_exists "$PROJECT_ROOT/$DOCS_DIR"; then
    if ensure_dir "$PROJECT_ROOT/$DOCS_DIR"; then
        track_created "$DOCS_DIR/"
        log_dir_created "$SCRIPT_NAME" "$DOCS_DIR/"
    fi
fi

# Create subdirectories
DOC_SUBDIRS=(
    "$DOCS_DIR/api"
    "$DOCS_DIR/guides"
    "$DOCS_DIR/architecture"
)

for subdir in "${DOC_SUBDIRS[@]}"; do
    if ! dir_exists "$PROJECT_ROOT/$subdir"; then
        if ensure_dir "$PROJECT_ROOT/$subdir"; then
            track_created "$subdir/"
            log_dir_created "$SCRIPT_NAME" "$subdir/"
        fi
    fi
done

# ===================================================================
# Create TypeDoc Configuration
# ===================================================================

if [[ "$DOC_TOOL" == "typedoc" ]] && [[ "$HAS_TYPESCRIPT" == true ]]; then
    log_info "Creating TypeDoc configuration..."

    TYPEDOC_CONFIG="$PROJECT_ROOT/typedoc.json"

    if ! file_exists "$TYPEDOC_CONFIG"; then
        cat > "$TYPEDOC_CONFIG" << 'EOFTYPEDOC'
{
  "$schema": "https://typedoc.org/schema.json",
  "entryPoints": ["src"],
  "entryPointStrategy": "expand",
  "out": "docs/api",
  "exclude": [
    "**/*.test.ts",
    "**/*.spec.ts",
    "**/node_modules/**",
    "**/dist/**"
  ],
  "excludePrivate": true,
  "excludeProtected": false,
  "excludeExternals": true,
  "includeVersion": true,
  "readme": "README.md",
  "plugin": [],
  "theme": "default",
  "categorizeByGroup": true,
  "sort": ["source-order"],
  "validation": {
    "notExported": true,
    "invalidLink": true,
    "notDocumented": false
  }
}
EOFTYPEDOC

        if verify_file "$TYPEDOC_CONFIG"; then
            track_created "typedoc.json"
            log_file_created "$SCRIPT_NAME" "typedoc.json"
        fi
    else
        track_skipped "typedoc.json"
        log_info "typedoc.json already exists, skipping"
    fi
fi

# ===================================================================
# Create OpenAPI/Swagger Configuration
# ===================================================================

if [[ "$HAS_API" == true ]] && [[ "$GENERATE_API_DOCS" == "true" ]]; then
    log_info "Creating OpenAPI/Swagger specification template..."

    SWAGGER_FILE="$PROJECT_ROOT/$DOCS_DIR/api/openapi.yaml"

    if ! file_exists "$SWAGGER_FILE"; then
        PROJECT_NAME=$(get_config "project.name" "$(basename "$PROJECT_ROOT")")

        cat > "$SWAGGER_FILE" << EOFSWAGGER
openapi: 3.0.3
info:
  title: ${PROJECT_NAME} API
  description: API documentation for ${PROJECT_NAME}
  version: 1.0.0
  contact:
    name: API Support
    email: support@example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: http://localhost:3000/api
    description: Local development server
  - url: https://staging.example.com/api
    description: Staging server
  - url: https://api.example.com
    description: Production server

tags:
  - name: health
    description: Health check endpoints
  - name: auth
    description: Authentication endpoints

paths:
  /health:
    get:
      tags:
        - health
      summary: Health check
      description: Returns the health status of the API
      operationId: healthCheck
      responses:
        '200':
          description: API is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: ok
                  timestamp:
                    type: string
                    format: date-time

components:
  schemas:
    Error:
      type: object
      properties:
        error:
          type: string
          description: Error message
        code:
          type: string
          description: Error code
        details:
          type: object
          description: Additional error details
      required:
        - error
        - code

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
EOFSWAGGER

        if verify_file "$SWAGGER_FILE"; then
            track_created "$DOCS_DIR/api/openapi.yaml"
            log_file_created "$SCRIPT_NAME" "$DOCS_DIR/api/openapi.yaml"
        fi
    else
        track_skipped "$DOCS_DIR/api/openapi.yaml"
        log_info "OpenAPI specification already exists, skipping"
    fi
fi

# ===================================================================
# Generate CHANGELOG.md
# ===================================================================

if [[ "$GENERATE_CHANGELOG" == "true" ]] && [[ "$HAS_GIT" == true ]]; then
    log_info "Generating CHANGELOG.md from git commits..."

    CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"

    if ! file_exists "$CHANGELOG_FILE"; then
        cat > "$CHANGELOG_FILE" << EOFCHANGELOG
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup

---

EOFCHANGELOG

        # Append recent commits grouped by type
        if command -v git &> /dev/null; then
            {
                echo "## Recent Commits"
                echo ""
                git log --pretty=format:"- %s (%h) - %ar" --max-count=20 2>/dev/null || echo "No git history found"
            } >> "$CHANGELOG_FILE"
        fi

        if verify_file "$CHANGELOG_FILE"; then
            track_created "CHANGELOG.md"
            log_file_created "$SCRIPT_NAME" "CHANGELOG.md"
        fi
    else
        track_skipped "CHANGELOG.md"
        log_info "CHANGELOG.md already exists, skipping"
    fi
fi

# ===================================================================
# Create Architecture Documentation
# ===================================================================

log_info "Creating architecture documentation template..."

ARCH_FILE="$PROJECT_ROOT/$DOCS_DIR/architecture/ARCHITECTURE.md"

if ! file_exists "$ARCH_FILE"; then
    PROJECT_NAME=$(get_config "project.name" "$(basename "$PROJECT_ROOT")")

    cat > "$ARCH_FILE" << 'EOFARCH'
# Architecture Documentation

> **Last Updated**: $(date +%Y-%m-%d)

## Overview

High-level architectural overview of the system.

## System Architecture

### Components

```mermaid
graph TB
    A[Client] --> B[API Gateway]
    B --> C[Application Server]
    C --> D[Database]
    C --> E[Cache]
```

### Layers

1. **Presentation Layer**: UI components and user interactions
2. **Application Layer**: Business logic and orchestration
3. **Data Layer**: Data persistence and retrieval
4. **Infrastructure Layer**: Cross-cutting concerns (logging, monitoring, etc.)

## Design Patterns

### Architectural Patterns
- [Pattern Name]: [Description and rationale]

### Design Principles
- Single Responsibility Principle
- Dependency Inversion
- Interface Segregation

## Data Flow

### Request/Response Flow

```
Client Request → API → Controller → Service → Repository → Database
Database → Repository → Service → Controller → Response → Client
```

### Event Flow

[Describe event-driven architecture if applicable]

## Infrastructure

### Deployment Architecture

- **Environment**: [Production, Staging, Development]
- **Hosting**: [Cloud provider, on-premise, etc.]
- **Scaling Strategy**: [Horizontal, Vertical, Auto-scaling]

### Dependencies

#### External Services
- Service A: Purpose
- Service B: Purpose

#### Internal Modules
- Module X: Responsibility
- Module Y: Responsibility

## Security Architecture

### Authentication & Authorization
- [Auth strategy]

### Data Security
- Encryption at rest
- Encryption in transit
- Data privacy measures

## Performance Considerations

### Caching Strategy
[Describe caching approach]

### Database Optimization
[Describe indexing, query optimization, etc.]

### Monitoring & Observability
[Describe logging, metrics, tracing]

## Future Considerations

### Known Limitations
[List current limitations]

### Planned Improvements
[List architectural improvements planned]

---

**Status**: Living Document
**Owner**: Architecture Team
EOFARCH

    if verify_file "$ARCH_FILE"; then
        track_created "$DOCS_DIR/architecture/ARCHITECTURE.md"
        log_file_created "$SCRIPT_NAME" "$DOCS_DIR/architecture/ARCHITECTURE.md"
    fi
else
    track_skipped "$DOCS_DIR/architecture/ARCHITECTURE.md"
    log_info "ARCHITECTURE.md already exists, skipping"
fi

# ===================================================================
# Create Documentation Site Configuration (VitePress)
# ===================================================================

if [[ "$DOC_SITE" == "vitepress" ]] && [[ "$HAS_JAVASCRIPT" == true ]]; then
    log_info "Creating VitePress documentation site configuration..."

    VITEPRESS_DIR="$PROJECT_ROOT/$DOCS_DIR/.vitepress"

    if ! dir_exists "$VITEPRESS_DIR"; then
        ensure_dir "$VITEPRESS_DIR"
        track_created "$DOCS_DIR/.vitepress/"
    fi

    VITEPRESS_CONFIG="$VITEPRESS_DIR/config.js"

    if ! file_exists "$VITEPRESS_CONFIG"; then
        PROJECT_NAME=$(get_config "project.name" "$(basename "$PROJECT_ROOT")")

        cat > "$VITEPRESS_CONFIG" << EOFVITEPRESS
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: '${PROJECT_NAME}',
  description: 'Documentation for ${PROJECT_NAME}',

  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guides/' },
      { text: 'API', link: '/api/' },
      { text: 'Architecture', link: '/architecture/' }
    ],

    sidebar: {
      '/guides/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guides/' },
            { text: 'Quick Start', link: '/guides/quick-start' },
            { text: 'Installation', link: '/guides/installation' }
          ]
        },
        {
          text: 'Development',
          items: [
            { text: 'Setup', link: '/guides/development-setup' },
            { text: 'Testing', link: '/guides/testing' },
            { text: 'Deployment', link: '/guides/deployment' }
          ]
        }
      ],

      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
            { text: 'Authentication', link: '/api/authentication' },
            { text: 'Endpoints', link: '/api/endpoints' }
          ]
        }
      ],

      '/architecture/': [
        {
          text: 'Architecture',
          items: [
            { text: 'Overview', link: '/architecture/' },
            { text: 'System Design', link: '/architecture/system-design' },
            { text: 'Data Flow', link: '/architecture/data-flow' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/yourusername/${PROJECT_NAME}' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © $(date +%Y)'
    },

    search: {
      provider: 'local'
    }
  }
})
EOFVITEPRESS

        if verify_file "$VITEPRESS_CONFIG"; then
            track_created "$DOCS_DIR/.vitepress/config.js"
            log_file_created "$SCRIPT_NAME" "$DOCS_DIR/.vitepress/config.js"
        fi
    else
        track_skipped "$DOCS_DIR/.vitepress/config.js"
        log_info "VitePress config already exists, skipping"
    fi

    # Create index.md for VitePress
    VITEPRESS_INDEX="$PROJECT_ROOT/$DOCS_DIR/index.md"

    if ! file_exists "$VITEPRESS_INDEX"; then
        PROJECT_NAME=$(get_config "project.name" "$(basename "$PROJECT_ROOT")")

        cat > "$VITEPRESS_INDEX" << EOFINDEX
---
layout: home

hero:
  name: ${PROJECT_NAME}
  text: Documentation
  tagline: Comprehensive documentation for ${PROJECT_NAME}
  actions:
    - theme: brand
      text: Get Started
      link: /guides/
    - theme: alt
      text: View on GitHub
      link: https://github.com/yourusername/${PROJECT_NAME}

features:
  - icon: 📚
    title: Comprehensive Guides
    details: Step-by-step guides to help you get started and master the platform
  - icon: 🔧
    title: API Reference
    details: Complete API documentation with examples and use cases
  - icon: 🏗️
    title: Architecture
    details: Deep dive into system design and architectural decisions
  - icon: 🚀
    title: Quick Start
    details: Get up and running in minutes with our quick start guide
---
EOFINDEX

        if verify_file "$VITEPRESS_INDEX"; then
            track_created "$DOCS_DIR/index.md"
            log_file_created "$SCRIPT_NAME" "$DOCS_DIR/index.md"
        fi
    fi
fi

# ===================================================================
# Update package.json with Documentation Scripts
# ===================================================================

if [[ "$HAS_JAVASCRIPT" == true ]]; then
    log_info "Adding documentation scripts to package.json..."

    # Note: This is informational - actual package.json modification would require jq or node
    log_info "Recommended scripts to add to package.json:"

    if [[ "$DOC_TOOL" == "typedoc" ]]; then
        log_info "  \"docs:api\": \"typedoc\""
    fi

    if [[ "$DOC_SITE" == "vitepress" ]]; then
        log_info "  \"docs:dev\": \"vitepress dev docs\""
        log_info "  \"docs:build\": \"vitepress build docs\""
        log_info "  \"docs:preview\": \"vitepress preview docs\""
    fi

    log_info "  \"docs:changelog\": \"conventional-changelog -p angular -i CHANGELOG.md -s\""
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Documentation structure initialized!"
echo ""
echo "Documentation Configuration:"
echo "  Tool: $DOC_TOOL"
echo "  Site: $DOC_SITE"
echo "  Directory: $DOCS_DIR"
echo "  Changelog: $GENERATE_CHANGELOG"
echo "  API Docs: $GENERATE_API_DOCS"
echo ""
echo "Created Files:"
if file_exists "$PROJECT_ROOT/typedoc.json"; then
    echo "  ✅ typedoc.json - TypeDoc configuration"
fi
if file_exists "$PROJECT_ROOT/$DOCS_DIR/api/openapi.yaml"; then
    echo "  ✅ $DOCS_DIR/api/openapi.yaml - OpenAPI specification"
fi
if file_exists "$PROJECT_ROOT/CHANGELOG.md"; then
    echo "  ✅ CHANGELOG.md - Project changelog"
fi
if file_exists "$PROJECT_ROOT/$DOCS_DIR/architecture/ARCHITECTURE.md"; then
    echo "  ✅ $DOCS_DIR/architecture/ARCHITECTURE.md - Architecture docs"
fi
if file_exists "$PROJECT_ROOT/$DOCS_DIR/.vitepress/config.js"; then
    echo "  ✅ $DOCS_DIR/.vitepress/config.js - VitePress configuration"
fi
echo ""
echo "Next steps:"
echo "  1. Install documentation dependencies:"
if [[ "$DOC_TOOL" == "typedoc" ]]; then
    echo "     npm install -D typedoc"
fi
if [[ "$DOC_SITE" == "vitepress" ]]; then
    echo "     npm install -D vitepress"
fi
echo "     npm install -D conventional-changelog-cli"
echo ""
echo "  2. Generate API documentation:"
if [[ "$DOC_TOOL" == "typedoc" ]]; then
    echo "     npm run docs:api"
fi
echo ""
echo "  3. Start documentation site:"
if [[ "$DOC_SITE" == "vitepress" ]]; then
    echo "     npm run docs:dev"
fi
echo ""
echo "  4. Update CHANGELOG.md:"
echo "     npm run docs:changelog"
echo ""
echo "  5. Customize documentation templates in $DOCS_DIR/"
echo "  6. Commit: git add . && git commit -m 'docs: initialize documentation structure'"
echo ""

show_log_location
