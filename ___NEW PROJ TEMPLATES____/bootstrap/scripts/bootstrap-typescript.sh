#!/bin/bash

# ===================================================================
# bootstrap-typescript.sh
#
# Bootstrap TypeScript and build configuration
# Sets up tsconfig.json, next.config.js, babel.config.js, vite.config.ts
# ===================================================================

set -euo pipefail

# ===================================================================
# Setup
# ===================================================================

# Get script directory and bootstrap root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common library
source "${BOOTSTRAP_DIR}/lib/common.sh"

# Initialize script
init_script "bootstrap-typescript"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-typescript"

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "TypeScript Configuration" \
    "tsconfig.json" \
    "next.config.js" \
    "babel.config.js" \
    "vite.config.ts" \
    "src/ (directory structure)"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

# Warn if jq not available (optional tool)
if ! command -v jq &>/dev/null; then
    track_warning "jq not installed - JSON validation will be skipped"
    log_warning "jq not installed - JSON validation will be skipped"
    log_info "Install with: sudo apt install jq (or brew install jq)"
fi

log_success "Environment validated"

# ===================================================================
# Create tsconfig.json
# ===================================================================

log_info "Creating tsconfig.json..."

# Skip if file exists
if file_exists "$PROJECT_ROOT/tsconfig.json"; then
    log_warning "tsconfig.json already exists, skipping"
    track_skipped "tsconfig.json"
else
    if cat > "$PROJECT_ROOT/tsconfig.json" << 'EOFTSCONFIG'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowJs": true,
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "noImplicitReturns": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "allowUnusedLabels": false,
    "allowUnreachableCode": false,
    "exactOptionalPropertyTypes": true,
    "noFallthroughCasesInSwitch": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "baseUrl": "./",
    "paths": {
      "@/*": ["./src/*"]
    },
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "allowSyntheticDefaultImports": true
  },
  "include": [
    "src/**/*",
    "tests/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "build",
    "coverage"
  ]
}
EOFTSCONFIG
    then
        verify_file "$PROJECT_ROOT/tsconfig.json"
        track_created "tsconfig.json"
        log_file_created "$SCRIPT_NAME" "tsconfig.json"

        # Validate JSON if jq available
        if command -v jq &>/dev/null; then
            source "${LIB_DIR}/json-validator.sh"
            if validate_json_file "$PROJECT_ROOT/tsconfig.json" > /dev/null 2>&1; then
                log_success "JSON syntax validated"
            else
                log_warning "JSON syntax validation failed - please check file manually"
            fi
        fi
    else
        log_fatal "Failed to create tsconfig.json"
    fi
fi

# ===================================================================
# Create next.config.js
# ===================================================================

log_info "Creating next.config.js..."

if file_exists "$PROJECT_ROOT/next.config.js"; then
    log_warning "next.config.js already exists, skipping"
    track_skipped "next.config.js"
else
    if cat > "$PROJECT_ROOT/next.config.js" << 'EOFNEXT'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  typescript: {
    tsconfigPath: './tsconfig.json',
  },
  env: {
    // Add public environment variables here
  },
  headers: async () => [
    {
      source: '/:path*',
      headers: [
        {
          key: 'X-Content-Type-Options',
          value: 'nosniff',
        },
        {
          key: 'X-Frame-Options',
          value: 'DENY',
        },
      ],
    },
  ],
  // Redirect old paths to new ones
  redirects: async () => [
    // Example redirect
    // {
    //   source: '/old-path',
    //   destination: '/new-path',
    //   permanent: true,
    // },
  ],
  // Rewrite rules
  rewrites: async () => ({
    beforeFiles: [
      // Example rewrite
      // {
      //   source: '/api/:path*',
      //   destination: 'http://localhost:3001/api/:path*',
      // },
    ],
  }),
}

module.exports = nextConfig
EOFNEXT
    then
        verify_file "$PROJECT_ROOT/next.config.js"
        track_created "next.config.js"
        log_file_created "$SCRIPT_NAME" "next.config.js"
    else
        log_fatal "Failed to create next.config.js"
    fi
fi

# ===================================================================
# Create babel.config.js
# ===================================================================

log_info "Creating babel.config.js..."

if file_exists "$PROJECT_ROOT/babel.config.js"; then
    log_warning "babel.config.js already exists, skipping"
    track_skipped "babel.config.js"
else
    if cat > "$PROJECT_ROOT/babel.config.js" << 'EOFBABEL'
module.exports = {
  presets: [
    ['@babel/preset-env', { targets: { node: 'current' } }],
    '@babel/preset-typescript',
    ['@babel/preset-react', { runtime: 'automatic' }],
  ],
  plugins: [
    ['@babel/plugin-proposal-class-properties', { loose: true }],
  ],
  env: {
    test: {
      presets: [
        ['@babel/preset-env', { targets: { node: 'current' } }],
        '@babel/preset-typescript',
      ],
    },
  },
}
EOFBABEL
    then
        verify_file "$PROJECT_ROOT/babel.config.js"
        track_created "babel.config.js"
        log_file_created "$SCRIPT_NAME" "babel.config.js"
    else
        log_fatal "Failed to create babel.config.js"
    fi
fi

# ===================================================================
# Create vite.config.ts
# ===================================================================

log_info "Creating vite.config.ts..."

if file_exists "$PROJECT_ROOT/vite.config.ts"; then
    log_warning "vite.config.ts already exists, skipping"
    track_skipped "vite.config.ts"
else
    if cat > "$PROJECT_ROOT/vite.config.ts" << 'EOFVITE'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    open: true,
  },
  build: {
    target: 'ES2022',
    sourcemap: true,
    outDir: 'dist',
  },
})
EOFVITE
    then
        verify_file "$PROJECT_ROOT/vite.config.ts"
        track_created "vite.config.ts"
        log_file_created "$SCRIPT_NAME" "vite.config.ts"
    else
        log_fatal "Failed to create vite.config.ts"
    fi
fi

# ===================================================================
# Create src directory structure
# ===================================================================

log_info "Creating src directory structure..."

# Create base src directory
ensure_dir "$PROJECT_ROOT/src"

# Create subdirectories
for dir in components hooks lib types services; do
    if dir_exists "$PROJECT_ROOT/src/$dir"; then
        log_debug "src/$dir already exists, skipping"
    else
        ensure_dir "$PROJECT_ROOT/src/$dir"
        log_dir_created "$SCRIPT_NAME" "src/$dir"
    fi
done

log_success "src directory structure created"

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "TypeScript and build configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Install TypeScript: npm install --save-dev typescript @types/node"
echo "  2. Choose your build tool (Next.js, Vite, or plain tsc)"
echo "  3. Create src/index.ts or src/index.tsx"
echo "  4. Run: npm run build"
echo ""
echo "Configuration notes:"
echo "  - Strict TypeScript mode enabled (no implicit any)"
echo "  - Path alias configured: @/* → ./src/*"
echo "  - Multiple build configs provided (choose based on your stack)"
echo ""

show_log_location
