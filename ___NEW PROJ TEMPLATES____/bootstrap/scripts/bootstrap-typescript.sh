#!/bin/bash

# ===================================================================
# bootstrap-typescript.sh
#
# Bootstrap TypeScript and build configuration
# Sets up tsconfig.json, next.config.js, babel.config.js, etc.
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

log_info "Bootstrapping TypeScript and build configuration..."

if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory not found: $PROJECT_ROOT"
fi

# ===================================================================
# Create tsconfig.json
# ===================================================================

log_info "Creating tsconfig.json..."

cat > "$PROJECT_ROOT/tsconfig.json" << 'EOF'
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
    "noImplicitAnyIndexer": true,
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
EOF

log_success "tsconfig.json created"

# ===================================================================
# Create next.config.js (if Next.js project)
# ===================================================================

log_info "Creating next.config.js..."

cat > "$PROJECT_ROOT/next.config.js" << 'EOF'
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
EOF

log_success "next.config.js created"

# ===================================================================
# Create babel.config.js
# ===================================================================

log_info "Creating babel.config.js..."

cat > "$PROJECT_ROOT/babel.config.js" << 'EOF'
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
EOF

log_success "babel.config.js created"

# ===================================================================
# Create vite.config.ts (optional)
# ===================================================================

log_info "Creating vite.config.ts (optional)..."

cat > "$PROJECT_ROOT/vite.config.ts" << 'EOF'
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
EOF

log_success "vite.config.ts created"

# ===================================================================
# Create src directory structure
# ===================================================================

log_info "Creating src directory structure..."

mkdir -p "$PROJECT_ROOT/src"/{components,hooks,lib,types,services}
log_success "src directory structure created"

# ===================================================================
# Summary
# ===================================================================

echo ""
log_success "TypeScript and build configuration complete!"
echo ""
echo "Files created:"
echo "  - tsconfig.json"
echo "  - next.config.js"
echo "  - babel.config.js"
echo "  - vite.config.ts"
echo "  - src/ (directory structure)"
echo ""
echo "Next steps:"
echo "  1. Install TypeScript: npm install --save-dev typescript @types/node"
echo "  2. Configure for your project type (Next.js, Vite, plain Node, etc.)"
echo "  3. Create src/index.ts or src/index.tsx"
echo "  4. Run: npm run build"
echo "  5. Commit files: git add tsconfig.json next.config.js babel.config.js vite.config.ts"
echo ""
echo "Strict TypeScript Mode:"
echo "  - All strict flags enabled by default"
echo "  - No implicit 'any' types"
echo "  - Full null checking enabled"
echo "  - Requires explicit return types"
echo ""
