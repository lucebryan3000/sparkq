#!/bin/bash

# ===================================================================
# bootstrap-environment.sh
#
# Bootstrap environment configuration
# Sets up .env.example and .env.local templates
# ===================================================================

set -e

# Configuration
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${1:-.}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===================================================================
# Utility Functions
# ===================================================================

log_info() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# ===================================================================
# Validation
# ===================================================================

log_info "Bootstrapping environment configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# ===================================================================
# Create .env.example
# ===================================================================

log_info "Creating .env.example..."

cat > "$PROJECT_ROOT/.env.example" << 'EOF'
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
EOF

log_success ".env.example created"

# ===================================================================
# Create .env.local (if it doesn't exist)
# ===================================================================

if [[ ! -f "$PROJECT_ROOT/.env.local" ]]; then
    log_info "Creating .env.local..."
    
    cat > "$PROJECT_ROOT/.env.local" << 'EOF'
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
EOF
    
    log_success ".env.local created"
    log_warning "⚠ .env.local created with placeholder values. Update with your actual development values."
else
    log_warning ".env.local already exists, skipping creation"
fi

# ===================================================================
# Create .env.production (template)
# ===================================================================

log_info "Creating .env.production..."

cat > "$PROJECT_ROOT/.env.production" << 'EOF'
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
EOF

log_success ".env.production created"

# ===================================================================
# Create environment validation schema (optional)
# ===================================================================

log_info "Creating env.d.ts (TypeScript types)..."

cat > "$PROJECT_ROOT/env.d.ts" << 'EOF'
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
EOF

log_success "env.d.ts created"

# ===================================================================
# Summary
# ===================================================================

echo ""
log_success "Environment configuration complete!"
echo ""
echo "Files created:"
echo "  - .env.example (template with all variables)"
echo "  - .env.local (local development values)"
echo "  - .env.production (production template)"
echo "  - env.d.ts (TypeScript type definitions)"
echo ""
echo "Next steps:"
echo "  1. Edit .env.local with your local database/service credentials"
echo "  2. For production, set up secure secrets management:"
echo "     - AWS Secrets Manager"
echo "     - HashiCorp Vault"
echo "     - 1Password / LastPass"
echo "     - Environment variables in CI/CD"
echo "  3. Never commit .env.local or actual secrets"
echo "  4. Commit .env.example and env.d.ts only"
echo ""
echo "Security checklist:"
echo "  - .env.local is in .gitignore (never commit secrets)"
echo "  - Use strong, random values for secrets"
echo "  - Rotate secrets regularly in production"
echo "  - Use env.d.ts to catch missing required variables at compile time"
echo ""
