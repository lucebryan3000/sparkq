#!/bin/bash

# ===================================================================
# bootstrap-environment.sh
#
# Bootstrap environment configuration
# Sets up .env.example, .env.local, .env.production, and env.d.ts
# ===================================================================

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
init_script "bootstrap-environment"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-environment"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Environment Configuration" \
    ".env.example" \
    ".env.local" \
    ".env.production" \
    "env.d.ts"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Create .env.example
# ===================================================================

log_info "Creating .env.example..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.env.example"; then
    log_warning ".env.example already exists, skipping"
    track_skipped ".env.example"
else
    if cat > "$PROJECT_ROOT/.env.example" << 'EOFENVEXAMPLE'
# ===================================================================
# Environment Configuration Template
# Copy this file to .env.local and fill in actual values
# ===================================================================

# Application
NODE_ENV=development
DEBUG=false

# Server Configuration
PORT=3000
HOST=localhost

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/appdb
DATABASE_POOL_SIZE=10

# Cache
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=

# API Keys
API_KEY=your_api_key_here
SECRET_KEY=your_secret_key_here

# External Services
OPENAI_API_KEY=
OPENAI_ORGANIZATION=

# GitHub (if applicable)
GITHUB_TOKEN=
GITHUB_WEBHOOK_SECRET=

# Email Service
SENDGRID_API_KEY=
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=

# Authentication
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRY=7d

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Sentry (Error Tracking)
SENTRY_DSN=

# Feature Flags
FEATURE_BETA=false
FEATURE_EXPERIMENTAL=false

# Custom Configuration
APP_NAME=MyApp
APP_VERSION=0.0.1
EOFENVEXAMPLE
    then
        verify_file "$PROJECT_ROOT/.env.example"
        track_created ".env.example"
        log_file_created "$SCRIPT_NAME" ".env.example"
    else
        log_fatal "Failed to create .env.example"
    fi
fi

# ===================================================================
# Create .env.local
# ===================================================================

log_info "Creating .env.local..."

# Skip if file exists (don't overwrite local env)
if file_exists "$PROJECT_ROOT/.env.local"; then
    log_warning ".env.local already exists, skipping"
    track_skipped ".env.local"
else
    if cat > "$PROJECT_ROOT/.env.local" << 'EOFENVLOCAL'
# Local Development Environment
# Copy from .env.example and fill in your local values

NODE_ENV=development
DEBUG=true
PORT=3000
HOST=localhost

# Database (local)
DATABASE_URL=postgresql://postgres:password@localhost:5432/dev_db
DATABASE_POOL_SIZE=5

# Cache (local)
REDIS_URL=redis://localhost:6379

# API Keys (use dummy values for development)
API_KEY=dev_key_12345
SECRET_KEY=dev_secret_67890

# Logging
LOG_LEVEL=debug
LOG_FORMAT=pretty
EOFENVLOCAL
    then
        verify_file "$PROJECT_ROOT/.env.local"
        track_created ".env.local"
        log_file_created "$SCRIPT_NAME" ".env.local"
        track_warning ".env.local created with placeholder values - update with your actual development values"
    else
        log_fatal "Failed to create .env.local"
    fi
fi

# ===================================================================
# Create .env.production
# ===================================================================

log_info "Creating .env.production..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/.env.production"; then
    log_warning ".env.production already exists, skipping"
    track_skipped ".env.production"
else
    if cat > "$PROJECT_ROOT/.env.production" << 'EOFENVPROD'
# Production Environment
# Use in production deployment. Never commit actual secrets.
# Load from secure secrets management system (AWS Secrets Manager, Vault, etc.)

NODE_ENV=production
DEBUG=false
PORT=3000

# Database (production)
DATABASE_URL=${DATABASE_URL}
DATABASE_POOL_SIZE=20

# Redis (production)
REDIS_URL=${REDIS_URL}

# Security
JWT_SECRET=${JWT_SECRET}
API_KEY=${API_KEY}
SECRET_KEY=${SECRET_KEY}

# Logging
LOG_LEVEL=warn
LOG_FORMAT=json

# Monitoring
SENTRY_DSN=${SENTRY_DSN}
EOFENVPROD
    then
        verify_file "$PROJECT_ROOT/.env.production"
        track_created ".env.production"
        log_file_created "$SCRIPT_NAME" ".env.production"
    else
        log_fatal "Failed to create .env.production"
    fi
fi

# ===================================================================
# Create env.d.ts (TypeScript types)
# ===================================================================

log_info "Creating env.d.ts..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/env.d.ts"; then
    log_warning "env.d.ts already exists, skipping"
    track_skipped "env.d.ts"
else
    if cat > "$PROJECT_ROOT/env.d.ts" << 'EOFENVDTS'
declare namespace NodeJS {
  interface ProcessEnv {
    NODE_ENV: 'development' | 'production' | 'test'
    DEBUG: string
    PORT: string
    HOST: string

    // Database
    DATABASE_URL: string
    DATABASE_POOL_SIZE: string

    // Cache
    REDIS_URL: string
    REDIS_PASSWORD?: string

    // API Keys
    API_KEY: string
    SECRET_KEY: string

    // External Services
    OPENAI_API_KEY?: string
    OPENAI_ORGANIZATION?: string
    GITHUB_TOKEN?: string

    // Authentication
    JWT_SECRET: string
    JWT_EXPIRY?: string

    // Logging
    LOG_LEVEL: 'debug' | 'info' | 'warn' | 'error'
    LOG_FORMAT: 'json' | 'pretty'

    // Error Tracking
    SENTRY_DSN?: string
  }
}

export {}
EOFENVDTS
    then
        verify_file "$PROJECT_ROOT/env.d.ts"
        track_created "env.d.ts"
        log_file_created "$SCRIPT_NAME" "env.d.ts"
    else
        log_fatal "Failed to create env.d.ts"
    fi
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Environment configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Edit .env.local with your local database/service credentials"
echo "  2. For production, set up secure secrets management:"
echo "     - AWS Secrets Manager"
echo "     - HashiCorp Vault"
echo "     - 1Password / LastPass"
echo "     - Environment variables in CI/CD"
echo "  3. Never commit .env.local or actual secrets to git"
echo ""
echo "Security checklist:"
echo "  ✓ .env.local is in .gitignore (never commit secrets)"
echo "  ✓ Use strong, random values for secrets"
echo "  ✓ Rotate secrets regularly in production"
echo "  ✓ Use env.d.ts to catch missing required variables at compile time"
echo ""

show_log_location
