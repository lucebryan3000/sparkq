#!/bin/bash

# ===================================================================
# bootstrap-buildtools.sh
#
# Purpose: Build tools setup and configuration
# Creates: Build configuration files (webpack, rollup, vite, tsup configs)
# Config:  [buildtools] section in bootstrap.config
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
init_script "bootstrap-buildtools"

# Get project root from argument or current directory
PROJECT_ROOT=$(get_project_root "${1:-.}")

# Script identifier for logging
SCRIPT_NAME="bootstrap-buildtools"

# ===================================================================
# Dependency Validation
# ===================================================================

# Source dependency checker
source "${BOOTSTRAP_DIR}/lib/dependency-checker.sh"

# Declare all dependencies (MANDATORY - fails if not met)
declare_dependencies \
    --tools "node npm" \
    --scripts "bootstrap-project bootstrap-packages" \
    --optional ""

# ===================================================================
# Pre-Execution Confirmation
# ===================================================================

pre_execution_confirm "$SCRIPT_NAME" "Build Tools Configuration" \
    "vite.config.ts" \
    "webpack.config.js" \
    "rollup.config.js" \
    "tsup.config.ts"

# ===================================================================
# Validation
# ===================================================================

log_info "Validating environment..."

# Check directory permissions
require_dir "$PROJECT_ROOT" || log_fatal "Project directory not found: $PROJECT_ROOT"
is_writable "$PROJECT_ROOT" || log_fatal "Project directory not writable: $PROJECT_ROOT"

log_success "Environment validated"

# ===================================================================
# Create vite.config.ts
# ===================================================================

log_info "Creating vite.config.ts..."

if file_exists "$PROJECT_ROOT/vite.config.ts"; then
    backup_file "$PROJECT_ROOT/vite.config.ts"
    track_skipped "vite.config.ts (backed up)"
    log_warning "vite.config.ts already exists, backed up"
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
    open: false,
    strictPort: false,
  },
  build: {
    target: 'ES2022',
    sourcemap: true,
    outDir: 'dist',
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
      },
    },
  },
  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
  },
})
EOFVITE
    then
        verify_file "$PROJECT_ROOT/vite.config.ts"
        log_file_created "$SCRIPT_NAME" "vite.config.ts"
        track_created "vite.config.ts"
    else
        log_fatal "Failed to create vite.config.ts"
    fi
fi

# ===================================================================
# Create webpack.config.js
# ===================================================================

log_info "Creating webpack.config.js..."

if file_exists "$PROJECT_ROOT/webpack.config.js"; then
    backup_file "$PROJECT_ROOT/webpack.config.js"
    track_skipped "webpack.config.js (backed up)"
    log_warning "webpack.config.js already exists, backed up"
else
    if cat > "$PROJECT_ROOT/webpack.config.js" << 'EOFWEBPACK'
const path = require('path')

module.exports = {
  mode: process.env.NODE_ENV || 'development',
  entry: './src/index.ts',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].[contenthash].js',
    clean: true,
  },
  module: {
    rules: [
      {
        test: /\.[jt]sx?$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
        },
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader', 'postcss-loader'],
      },
      {
        test: /\.(png|jpg|jpeg|gif|svg)$/,
        type: 'asset',
        parser: {
          dataUrlCondition: {
            maxSize: 8 * 1024,
          },
        },
      },
    ],
  },
  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.jsx', '.json'],
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  devtool: process.env.NODE_ENV === 'production' ? 'source-map' : 'eval-source-map',
  devServer: {
    port: 3000,
    hot: true,
    historyApiFallback: true,
  },
  performance: {
    maxEntrypointSize: 512000,
    maxAssetSize: 512000,
  },
}
EOFWEBPACK
    then
        verify_file "$PROJECT_ROOT/webpack.config.js"
        log_file_created "$SCRIPT_NAME" "webpack.config.js"
        track_created "webpack.config.js"
    else
        log_fatal "Failed to create webpack.config.js"
    fi
fi

# ===================================================================
# Create rollup.config.js
# ===================================================================

log_info "Creating rollup.config.js..."

if file_exists "$PROJECT_ROOT/rollup.config.js"; then
    backup_file "$PROJECT_ROOT/rollup.config.js"
    track_skipped "rollup.config.js (backed up)"
    log_warning "rollup.config.js already exists, backed up"
else
    if cat > "$PROJECT_ROOT/rollup.config.js" << 'EOFROLLUP'
import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import typescript from '@rollup/plugin-typescript'
import terser from '@rollup/plugin-terser'

export default {
  input: 'src/index.ts',
  output: [
    {
      file: 'dist/index.js',
      format: 'cjs',
      sourcemap: true,
    },
    {
      file: 'dist/index.esm.js',
      format: 'esm',
      sourcemap: true,
    },
  ],
  external: ['react', 'react-dom'],
  plugins: [
    resolve({
      extensions: ['.ts', '.tsx', '.js', '.jsx'],
    }),
    commonjs(),
    typescript({
      tsconfig: './tsconfig.json',
      declaration: true,
      declarationDir: 'dist/types',
    }),
    terser({
      compress: {
        drop_console: true,
      },
    }),
  ],
}
EOFROLLUP
    then
        verify_file "$PROJECT_ROOT/rollup.config.js"
        log_file_created "$SCRIPT_NAME" "rollup.config.js"
        track_created "rollup.config.js"
    else
        log_fatal "Failed to create rollup.config.js"
    fi
fi

# ===================================================================
# Create tsup.config.ts
# ===================================================================

log_info "Creating tsup.config.ts..."

if file_exists "$PROJECT_ROOT/tsup.config.ts"; then
    backup_file "$PROJECT_ROOT/tsup.config.ts"
    track_skipped "tsup.config.ts (backed up)"
    log_warning "tsup.config.ts already exists, backed up"
else
    if cat > "$PROJECT_ROOT/tsup.config.ts" << 'EOFTSUP'
import { defineConfig } from 'tsup'

export default defineConfig({
  entry: {
    index: 'src/index.ts',
  },
  format: ['esm', 'cjs'],
  target: 'es2022',
  dts: true,
  clean: true,
  sourcemap: true,
  minify: true,
  splitting: false,
  shims: true,
})
EOFTSUP
    then
        verify_file "$PROJECT_ROOT/tsup.config.ts"
        log_file_created "$SCRIPT_NAME" "tsup.config.ts"
        track_created "tsup.config.ts"
    else
        log_fatal "Failed to create tsup.config.ts"
    fi
fi

# ===================================================================
# Summary
# ===================================================================

log_script_complete "$SCRIPT_NAME" "${#_BOOTSTRAP_CREATED_FILES[@]} files created"

show_summary

echo ""
log_success "Build tools configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Review build tool configuration in vite.config.ts, webpack.config.js, rollup.config.js, or tsup.config.ts"
echo "  2. Install build dependencies: npm install --save-dev vite webpack rollup tsup"
echo "  3. Choose your primary build tool based on your project type"
echo "  4. Customize paths, targets, and plugins as needed"
echo ""
echo "Build tool recommendations:"
echo "  - Vite: Best for modern web development and React projects"
echo "  - Webpack: Best for complex SPAs with multiple entry points"
echo "  - Rollup: Best for library and package development"
echo "  - tsup: Best for lightweight TypeScript to JavaScript compilation"
echo ""

show_log_location
