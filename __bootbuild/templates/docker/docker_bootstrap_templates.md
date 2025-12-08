# Docker Bootstrap Templates

Three configuration tiers for different development stages. Copy the appropriate tier to your project.

---

## Tier Overview

| Tier | Use Case | Security | Convenience |
|------|----------|----------|-------------|
| **Tier 1: Sandbox** | Rapid prototyping, learning, throwaway projects | ⚠️ Insecure | ⭐⭐⭐⭐⭐ Maximum |
| **Tier 2: Development** | Active development, team projects, staging | ⚡ Balanced | ⭐⭐⭐⭐ High |
| **Tier 3: Production** | Production deployments, security-sensitive | ✅ Hardened | ⭐⭐ Necessary friction |

---

## Tier 1: Sandbox (Maximum Velocity)

**Use when:** Rapid prototyping, experimenting, learning Docker, throwaway projects

**Trade-offs:** 
- ✅ Full host access for debugging
- ✅ No permission issues
- ✅ Hot reload works perfectly
- ⚠️ Root user in container
- ⚠️ Host network exposure
- ⚠️ No resource limits

### docker-compose.sandbox.yml

```yaml
# TIER 1: SANDBOX - Maximum velocity, minimum friction
# ⚠️ NOT FOR PRODUCTION - Security deliberately relaxed for development speed
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.sandbox
    container_name: ${COMPOSE_PROJECT_NAME:-app}_dev
    
    # Full host network access - no port mapping needed
    network_mode: host
    
    # Run as root for zero permission issues
    user: root
    
    volumes:
      # Full project mount with native performance
      - .:/app
      # Persist node_modules in named volume (faster than bind mount)
      - node_modules:/app/node_modules
      # Share host Docker socket (for Docker-in-Docker scenarios)
      - /var/run/docker.sock:/var/run/docker.sock
      # Mount SSH keys for git operations
      - ~/.ssh:/root/.ssh:ro
      # Mount git config
      - ~/.gitconfig:/root/.gitconfig:ro
    
    environment:
      - NODE_ENV=development
      - DEBUG=*
      # Trust all hosts for development
      - DANGEROUSLY_DISABLE_HOST_CHECK=true
      # Database - localhost works with host network
      - DATABASE_URL=postgresql://postgres:postgres@localhost:5432/${COMPOSE_PROJECT_NAME:-app}
      - REDIS_URL=redis://localhost:6379
    
    # No healthcheck - faster startup
    # No resource limits - use full host capacity
    
    # Keep running for shell access
    stdin_open: true
    tty: true
    
    # Restart on crash during development
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-app}_postgres
    network_mode: host
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ${COMPOSE_PROJECT_NAME:-app}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    # No healthcheck for faster startup

  redis:
    image: redis:7-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-app}_redis
    network_mode: host
    volumes:
      - redis_data:/data
    # Disable persistence for speed
    command: redis-server --save ""

volumes:
  node_modules:
  postgres_data:
  redis_data:
```

### Dockerfile.sandbox

```dockerfile
# TIER 1: SANDBOX - Fast builds, full access
# ⚠️ NOT FOR PRODUCTION

FROM node:20-bookworm

# Install useful dev tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    htop \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Install global dev tools
RUN npm install -g \
    pnpm \
    typescript \
    ts-node \
    nodemon \
    prisma

WORKDIR /app

# No COPY - everything mounted via volume
# No USER - running as root for full access

# Default command - override in compose
CMD ["bash"]
```

### .env.sandbox

```bash
# TIER 1: SANDBOX ENVIRONMENT
COMPOSE_PROJECT_NAME=myapp

# All services on localhost (host network mode)
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp
REDIS_URL=redis://localhost:6379

# Wide open for development
NODE_ENV=development
DEBUG=*
LOG_LEVEL=debug

# Disable security features that slow development
DANGEROUSLY_DISABLE_HOST_CHECK=true
NEXT_TELEMETRY_DISABLED=1
```

---

## Tier 2: Development (Balanced)

**Use when:** Active development, team projects, CI/CD pipelines, staging environments

**Trade-offs:**
- ✅ Isolated network (predictable ports)
- ✅ Non-root user (catches permission bugs early)
- ✅ Resource limits (mimics production constraints)
- ✅ Health checks (reliable service startup)
- ⚡ Some security without friction

### docker-compose.dev.yml

```yaml
# TIER 2: DEVELOPMENT - Balanced security and convenience
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
      args:
        - NODE_VERSION=20
        - USER_ID=${USER_ID:-1000}
        - GROUP_ID=${GROUP_ID:-1000}
    container_name: ${COMPOSE_PROJECT_NAME:-app}_dev
    
    ports:
      - "${APP_PORT:-3000}:3000"
      - "${DEBUG_PORT:-9229}:9229"  # Node debugger
    
    networks:
      - app_network
    
    volumes:
      # Project files
      - .:/app
      # Persist node_modules
      - node_modules:/app/node_modules
      # Persist pnpm store
      - pnpm_store:/home/node/.local/share/pnpm/store
    
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://${DB_USER:-postgres}:${DB_PASSWORD:-postgres}@db:5432/${DB_NAME:-app}
      - REDIS_URL=redis://redis:6379
      - LOG_LEVEL=${LOG_LEVEL:-debug}
    
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    
    # Reasonable resource limits
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 1G
    
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    stdin_open: true
    tty: true
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-app}_postgres
    
    ports:
      - "${DB_PORT:-5432}:5432"
    
    networks:
      - app_network
    
    environment:
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
      POSTGRES_DB: ${DB_NAME:-app}
    
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./docker/postgres/init:/docker-entrypoint-initdb.d:ro
    
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
    
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres} -d ${DB_NAME:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  redis:
    image: redis:7-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-app}_redis
    
    ports:
      - "${REDIS_PORT:-6379}:6379"
    
    networks:
      - app_network
    
    volumes:
      - redis_data:/data
    
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
    
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Optional: Database admin UI
  adminer:
    image: adminer:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}_adminer
    ports:
      - "${ADMINER_PORT:-8080}:8080"
    networks:
      - app_network
    depends_on:
      - db
    profiles:
      - tools

networks:
  app_network:
    driver: bridge

volumes:
  node_modules:
  pnpm_store:
  postgres_data:
  redis_data:
```

### Dockerfile.dev

```dockerfile
# TIER 2: DEVELOPMENT - Balanced for team development
ARG NODE_VERSION=20

FROM node:${NODE_VERSION}-bookworm-slim AS base

# Build arguments for user mapping
ARG USER_ID=1000
ARG GROUP_ID=1000

# Install essential tools only
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN corepack enable && corepack prepare pnpm@latest --activate

# Create non-root user matching host UID/GID
RUN groupmod -g ${GROUP_ID} node && usermod -u ${USER_ID} -g ${GROUP_ID} node

WORKDIR /app

# Change ownership to node user
RUN chown -R node:node /app

# Switch to non-root user
USER node

# Copy package files first (better layer caching)
COPY --chown=node:node package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy application code
COPY --chown=node:node . .

# Generate Prisma client if present
RUN if [ -f "prisma/schema.prisma" ]; then pnpm prisma generate; fi

EXPOSE 3000 9229

# Development command with hot reload
CMD ["pnpm", "dev"]
```

### .env.dev

```bash
# TIER 2: DEVELOPMENT ENVIRONMENT
COMPOSE_PROJECT_NAME=myapp

# User mapping (run: id -u && id -g)
USER_ID=1000
GROUP_ID=1000

# Ports
APP_PORT=3000
DEBUG_PORT=9229
DB_PORT=5432
REDIS_PORT=6379
ADMINER_PORT=8080

# Database
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=myapp

# Application
NODE_ENV=development
LOG_LEVEL=debug

# Disable telemetry
NEXT_TELEMETRY_DISABLED=1
```

---

## Tier 3: Production (Hardened)

**Use when:** Production deployments, security-sensitive applications, compliance requirements

**Trade-offs:**
- ✅ Minimal attack surface
- ✅ Read-only filesystem
- ✅ No root, no shell
- ✅ Secrets management
- ✅ Security headers
- ⚠️ More configuration required

### docker-compose.prod.yml

```yaml
# TIER 3: PRODUCTION - Security hardened
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.prod
      args:
        - NODE_VERSION=20
    container_name: ${COMPOSE_PROJECT_NAME}_app
    
    ports:
      - "${APP_PORT:-3000}:3000"
    
    networks:
      - frontend
      - backend
    
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}?sslmode=require
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
    
    # Secrets from Docker secrets or external secret manager
    secrets:
      - db_password
      - redis_password
      - app_secret
    
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    
    deploy:
      mode: replicated
      replicas: 2
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        order: start-first
    
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
    # Security hardening
    read_only: true
    tmpfs:
      - /tmp:size=100M,mode=1777
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  db:
    image: postgres:16-alpine
    container_name: ${COMPOSE_PROJECT_NAME}_postgres
    
    # No external port exposure in production
    networks:
      - backend
    
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: ${DB_NAME}
      # Hardening
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256"
    
    secrets:
      - db_password
    
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./docker/postgres/postgresql.conf:/etc/postgresql/postgresql.conf:ro
    
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 1G
    
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    
    security_opt:
      - no-new-privileges:true
    
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  redis:
    image: redis:7-alpine
    container_name: ${COMPOSE_PROJECT_NAME}_redis
    
    networks:
      - backend
    
    volumes:
      - redis_data:/data
      - ./docker/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
    
    command: redis-server /usr/local/etc/redis/redis.conf
    
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
    
    healthcheck:
      test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID

  # Reverse proxy with TLS termination
  nginx:
    image: nginx:alpine
    container_name: ${COMPOSE_PROJECT_NAME}_nginx
    
    ports:
      - "80:80"
      - "443:443"
    
    networks:
      - frontend
    
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./docker/nginx/ssl:/etc/nginx/ssl:ro
      - nginx_cache:/var/cache/nginx
    
    depends_on:
      - app
    
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 256M
    
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
    
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /var/run:size=10M
      - /tmp:size=10M

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  nginx_cache:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt
  redis_password:
    file: ./secrets/redis_password.txt
  app_secret:
    file: ./secrets/app_secret.txt
```

### Dockerfile.prod

```dockerfile
# TIER 3: PRODUCTION - Multi-stage, minimal, secure
ARG NODE_VERSION=20

# ============================================
# Stage 1: Dependencies
# ============================================
FROM node:${NODE_VERSION}-alpine AS deps

RUN apk add --no-cache libc6-compat

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy dependency files
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod

# ============================================
# Stage 2: Builder
# ============================================
FROM node:${NODE_VERSION}-alpine AS builder

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY package.json pnpm-lock.yaml ./

# Install all dependencies (including devDependencies for build)
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Generate Prisma client if present
RUN if [ -f "prisma/schema.prisma" ]; then pnpm prisma generate; fi

# Build application
RUN pnpm build

# Remove devDependencies after build
RUN pnpm prune --prod

# ============================================
# Stage 3: Production Runner
# ============================================
FROM node:${NODE_VERSION}-alpine AS runner

# Security: Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nextjs

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy only necessary files from builder
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy Prisma client if present
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/.prisma ./node_modules/.prisma

# Copy healthcheck script
COPY --chown=nextjs:nodejs healthcheck.js ./

# Security: Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set hostname
ENV HOSTNAME="0.0.0.0"

# Run the application
CMD ["node", "server.js"]
```

### healthcheck.js (for production)

```javascript
// healthcheck.js - Lightweight health check for production
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/health',
  method: 'GET',
  timeout: 5000,
};

const req = http.request(options, (res) => {
  process.exit(res.statusCode === 200 ? 0 : 1);
});

req.on('error', () => process.exit(1));
req.on('timeout', () => {
  req.destroy();
  process.exit(1);
});

req.end();
```

### .env.prod.example

```bash
# TIER 3: PRODUCTION ENVIRONMENT
# ⚠️ DO NOT COMMIT ACTUAL VALUES - Use secrets management
COMPOSE_PROJECT_NAME=myapp

# Ports (only nginx exposed publicly)
APP_PORT=3000

# Database (strong passwords required)
DB_USER=myapp_prod
DB_PASSWORD=  # Set via secret
DB_NAME=myapp_production

# Redis
REDIS_PASSWORD=  # Set via secret

# Application
NODE_ENV=production
LOG_LEVEL=info

# TLS/SSL
SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/key.pem
```

### docker/redis/redis.conf (production)

```conf
# Redis production configuration
bind 0.0.0.0
port 6379

# Authentication
requirepass ${REDIS_PASSWORD}

# Memory management
maxmemory 1gb
maxmemory-policy allkeys-lru

# Persistence (AOF for durability)
appendonly yes
appendfsync everysec

# Security
protected-mode yes
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""
rename-command CONFIG ""

# Logging
loglevel notice
logfile ""

# Connection limits
maxclients 1000
timeout 300
tcp-keepalive 300
```

### docker/postgres/postgresql.conf (production)

```conf
# PostgreSQL production configuration

# Connection settings
listen_addresses = '*'
max_connections = 100

# Memory (adjust based on available RAM)
shared_buffers = 1GB
effective_cache_size = 3GB
work_mem = 16MB
maintenance_work_mem = 256MB

# Write-ahead log
wal_level = replica
max_wal_senders = 3
wal_keep_size = 1GB

# Query planning
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d.log'
log_min_duration_statement = 1000
log_connections = on
log_disconnections = on

# Security
ssl = on
ssl_cert_file = '/var/lib/postgresql/ssl/server.crt'
ssl_key_file = '/var/lib/postgresql/ssl/server.key'
password_encryption = scram-sha-256
```

---

## Shared Files (All Tiers)

### .dockerignore

```
# Git
.git
.gitignore

# Dependencies (rebuilt in container)
node_modules
.pnpm-store

# Build outputs
.next
dist
build
out

# Environment files (use Docker secrets in prod)
.env
.env.*
!.env.example

# IDE
.idea
.vscode
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs
*.log
npm-debug.log*

# Test & coverage
coverage
.nyc_output

# Docker
Dockerfile*
docker-compose*
.docker

# Documentation
*.md
!README.md
docs

# Secrets (never include)
secrets
*.pem
*.key
```

---

## Quick Start Commands

### Tier 1: Sandbox
```bash
# Copy files
cp docker-compose.sandbox.yml docker-compose.yml
cp Dockerfile.sandbox Dockerfile
cp .env.sandbox .env

# Start everything
docker compose up -d

# Shell into container
docker compose exec app bash
```

### Tier 2: Development
```bash
# Copy files
cp docker-compose.dev.yml docker-compose.yml
cp Dockerfile.dev Dockerfile
cp .env.dev .env

# Set user IDs
echo "USER_ID=$(id -u)" >> .env
echo "GROUP_ID=$(id -g)" >> .env

# Start with optional tools
docker compose --profile tools up -d

# View logs
docker compose logs -f app
```

### Tier 3: Production
```bash
# Copy files
cp docker-compose.prod.yml docker-compose.yml
cp Dockerfile.prod Dockerfile

# Create secrets directory
mkdir -p secrets
echo "strong-db-password" > secrets/db_password.txt
echo "strong-redis-password" > secrets/redis_password.txt
echo "strong-app-secret" > secrets/app_secret.txt
chmod 600 secrets/*

# Build and deploy
docker compose build
docker compose up -d

# Check health
docker compose ps
docker compose logs -f
```

---

## Migration Path

```
Sandbox → Development → Production
   │           │            │
   │           │            └── Add: TLS, secrets, replicas, monitoring
   │           │
   │           └── Add: User mapping, health checks, resource limits, networks
   │
   └── Start here: Full access, fast iteration, learn Docker
```

**Recommendation:** Start with Sandbox for prototyping, migrate to Development when collaborating, use Production for deployments.
