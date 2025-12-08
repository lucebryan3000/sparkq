# Docker Bootstrap Integration Evaluation & Recommendations

## Executive Summary

**Current Status:** ✅ **DOCKER-READY FOUNDATIONAL ARCHITECTURE**

Your bootstrap system has excellent foundational patterns for Docker integration. The scripts are well-structured, configuration-driven, and use proper error handling. However, they are currently designed to run **on the host machine** to set up projects. To truly support **deploying into Docker containers**, you need:

1. **Docker-aware bootstrap mode** (detect Docker environment)
2. **Container-specific initialization** (entry points and health checks)
3. **Layered Dockerfile strategy** (each tier bootstraps on startup)
4. **Common files structure** (shared across all three tiers)
5. **Bootstrap service integration** (runs inside containers)

---

## Part 1: Current State Analysis

### ✅ Strengths

| Aspect | Status | Why It Works |
|--------|--------|-------------|
| **Configuration-driven** | ✅ Excellent | bootstrap.config + bootstrap-manifest.json = no hardcoding |
| **Error handling** | ✅ Strong | set -euo pipefail, pre-execution checks, validation |
| **Modular design** | ✅ Good | Templates are tier-specific, clear separation of concerns |
| **File tracking** | ✅ Great | Scripts track what they create (perfect for Docker layer caching) |
| **Idempotency** | ✅ Good | Scripts check before creating (won't fail on re-runs) |
| **Phase-based execution** | ✅ Excellent | Manifest drives which scripts run - perfect for container layers |

### ⚠️ Current Limitations (Docker Context)

| Limitation | Impact | Severity |
|-----------|--------|----------|
| **Color output** | Won't work well in Docker logs | Medium - needs `NO_COLOR` env var support |
| **Interactive mode** | Can't use `-i` flag in containers | High - must auto-detect Docker |
| **TTY assumption** | stdin_open/tty won't exist in containers | High - scripts need to detect TTY |
| **Direct file creation** | Scripts create to `PROJECT_ROOT` which is `/app` in containers | Low - actually works fine, just needs different paths |
| **Host commands** | Some scripts assume host tooling available | Medium - need to pin versions in container |
| **Path resolution** | Relative paths work on host, need absolute in containers | Medium - already using absolute paths mostly |

---

## Part 2: Docker Bootstrap Architecture

### 2.1 Three-Tier Bootstrap Strategy

```
┌─────────────────────────────────────────────────────────────┐
│ DOCKERFILE STRUCTURE (Bootstrap Embedded)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ FROM node:20-bookworm                                        │
│ COPY __bootbuild /bootstrap                                  │
│ ENV BOOTSTRAP_MODE=docker                    ← NEW          │
│ ENV BOOTSTRAP_TIER=1|2|3                     ← NEW          │
│                                                              │
│ # Layer 1: Install bootstrap dependencies                    │
│ RUN apt-get install -y bash curl git ...                     │
│                                                              │
│ # Layer 2: Copy bootstrap system                             │
│ COPY __bootbuild /bootstrap                                  │
│                                                              │
│ # Layer 3: Run Phase 1 (immutable layer)                     │
│ RUN BOOTSTRAP_YES=1 BOOTSTRAP_TIER=1 \                       │
│     /bootstrap/scripts/bootstrap-menu.sh \                   │
│     --phase=1 --auto-docker /app                             │
│                                                              │
│ # Layer 4: Run Phase 2 (infrastructure)                      │
│ RUN BOOTSTRAP_YES=1 BOOTSTRAP_TIER=1 \                       │
│     /bootstrap/scripts/bootstrap-menu.sh \                   │
│     --phase=2 --auto-docker /app                             │
│                                                              │
│ # Layer 5: Application code                                  │
│ COPY . /app                                                  │
│                                                              │
│ # Layer 6: Install app dependencies                          │
│ WORKDIR /app                                                 │
│ RUN pnpm install                                             │
│                                                              │
│ # Layer 7: Runtime bootstrap (development only)              │
│ ENTRYPOINT ["/bootstrap/entrypoint.sh"]                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Bootstrap Tier Characteristics in Docker

```
┌──────────────────────────────────────────────────────────────┐
│ TIER 1: SANDBOX (Max Velocity)                               │
├──────────────────────────────────────────────────────────────┤
│ Bootstrap Behavior:                                           │
│   • Run ALL phases (1-4) at build time                       │
│   • Install dev tools, debuggers, profilers                  │
│   • Configure hot-reload volumes                             │
│   • Enable all logging and debugging                         │
│   • BOOTSTRAP_SKIP_QUESTIONS=1 (auto-defaults)              │
│   • BOOTSTRAP_NO_COLOR=1 (JSON-friendly logging)             │
│                                                              │
│ Docker Specifics:                                            │
│   • Network mode: host                                       │
│   • User: root (no permission friction)                      │
│   • Resource limits: none                                    │
│   • Health checks: disabled (slower startup)                 │
│   • stdin_open/tty: true                                     │
│                                                              │
│ Use Case:                                                    │
│   docker-compose -f docker-compose.sandbox.yml up           │
│   docker-compose exec app bash                              │
│   # Now you have full dev environment with all tools         │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TIER 2: DEVELOPMENT (Balanced)                               │
├──────────────────────────────────────────────────────────────┤
│ Bootstrap Behavior:                                           │
│   • Run phases 1-3 at build time (fixed layer)              │
│   • Phase 4 (CI/CD) is SKIPPED or marked with warning        │
│   • Install essential dev tools only                         │
│   • Configure resource limits                               │
│   • Enable health checks                                    │
│   • BOOTSTRAP_SKIP_QUESTIONS=1 (auto-defaults)              │
│   • BOOTSTRAP_NO_COLOR=1 (structured logging)                │
│                                                              │
│ Docker Specifics:                                            │
│   • Network mode: bridge (isolated network)                  │
│   • User: node (UID/GID matching)                            │
│   • Resource limits: 4 CPUs, 4GB RAM                         │
│   • Health checks: enabled (curl /health)                    │
│   • stdin_open/tty: true                                     │
│   • Depends on: db, redis health                             │
│                                                              │
│ Use Case:                                                    │
│   docker-compose up --profile tools                         │
│   docker-compose logs -f app                                │
│   # Team development with isolated services                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ TIER 3: PRODUCTION (Hardened)                                │
├──────────────────────────────────────────────────────────────┤
│ Bootstrap Behavior:                                           │
│   • Run only phase 1 (production essentials) at build        │
│   • Phases 2-4 are SKIPPED (not in container)               │
│   • Minimal layer, production-only tooling                   │
│   • All secrets from environment/secrets manager             │
│   • BOOTSTRAP_SKIP_QUESTIONS=1 (auto-defaults)              │
│   • BOOTSTRAP_NO_COLOR=1 (JSON logging to stdout)            │
│   • BOOTSTRAP_SKIP_UNUSED_PHASES=true                        │
│                                                              │
│ Docker Specifics:                                            │
│   • Network mode: bridge (multi-tier architecture)           │
│   • User: nextjs (UID 1001, non-root)                        │
│   • Resource limits: strict (2 CPUs, 2GB per instance)      │
│   • Health checks: lightweight (node healthcheck.js)         │
│   • Read-only filesystem: true                               │
│   • /tmp tmpfs: 100MB                                        │
│   • Multi-stage build (slim final image)                     │
│                                                              │
│ Use Case:                                                    │
│   docker stack deploy -c docker-compose.prod.yml production  │
│   # Production-grade security, monitoring, orchestration     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Part 3: Implementation Recommendations

### 3.1 Add Docker-Aware Bootstrap Mode

**File:** `/bootstrap/scripts/bootstrap-menu.sh` (modify)

Add these environment variable checks at startup:

```bash
# Detect Docker environment
detect_docker_environment() {
    if [[ -f "/.dockerenv" ]] || grep -q docker /proc/self/cgroup 2>/dev/null; then
        BOOTSTRAP_IN_DOCKER="true"
        BOOTSTRAP_TTY_AVAILABLE="false"  # Assume no TTY in container
        BOOTSTRAP_NO_COLOR="${BOOTSTRAP_NO_COLOR:-true}"  # Disable colors by default
        return 0
    fi

    BOOTSTRAP_IN_DOCKER="${BOOTSTRAP_IN_DOCKER:-false}"
    return 1
}

# Suppress interactive features in Docker
if [[ "$BOOTSTRAP_IN_DOCKER" == "true" ]]; then
    INTERACTIVE_MODE=false          # Never ask questions in containers
    AUTO_YES=true                   # Auto-approve everything
    SKIP_PREFLIGHT=true             # Preflight checks already done at build

    # Log to structured format
    export BOOTSTRAP_LOG_FORMAT="${BOOTSTRAP_LOG_FORMAT:-json}"
fi
```

### 3.2 Create Common Files Structure

**Shared across ALL tiers:**

```
project-root/
├── __bootbuild/              ← Copy to Docker build context
│   ├── docker/               ← NEW SECTION
│   │   ├── entrypoint.sh     ← Runs at container startup
│   │   ├── healthcheck.sh    ← Health probe script
│   │   ├── common-bootstrap.env    ← Common across all tiers
│   │   └── README.md
│   │
│   ├── templates/
│   │   ├── docker/
│   │   │   ├── docker-bootstrap.yml     ← Shared bootstrap config
│   │   │   ├── Dockerfile.sandbox       ← TIER 1
│   │   │   ├── Dockerfile.dev           ← TIER 2
│   │   │   ├── Dockerfile.prod          ← TIER 3
│   │   │   ├── docker-compose.sandbox.yml
│   │   │   ├── docker-compose.dev.yml
│   │   │   ├── docker-compose.prod.yml
│   │   │   ├── .dockerignore
│   │   │   └── docker_bootstrap_templates.md
│   │   │
│   │   ├── root/
│   │   │   ├── docker/       ← NEW
│   │   │   │   ├── entrypoint.sh
│   │   │   │   ├── healthcheck.sh
│   │   │   │   ├── bootstrap-inside-container.sh
│   │   │   │   └── init.d/   (optional startup scripts)
│   │   │   │
│   │   │   ├── postgres/
│   │   │   ├── redis/
│   │   │   └── ...
│   │   │
│   │   └── scripts/
│   │       └── bootstrap-docker.sh ← NEW
│   │
│   ├── config/
│   │   ├── bootstrap.config
│   │   ├── bootstrap-manifest.json
│   │   ├── docker-bootstrap.config  ← NEW (Docker-specific overrides)
│   │   └── bootstrap-questions.json
│   │
│   ├── lib/
│   │   ├── common.sh
│   │   ├── docker-utils.sh          ← NEW
│   │   ├── config-manager.sh
│   │   └── ...
│   │
│   ├── scripts/
│   │   ├── bootstrap-menu.sh
│   │   └── bootstrap-postgres.sh
│   │
│   └── docs/
│       └── DOCKER-BOOTSTRAP-INTEGRATION.md  ← NEW
│
└── docker/                   ← Project-specific Docker files
    ├── entrypoint.sh        ← Calls bootstrap then starts app
    ├── healthcheck.sh
    ├── postgres/            ← init scripts
    ├── redis/               ← config files
    └── nginx/               ← config files (prod only)
```

### 3.3 Create Docker Entrypoint Script

**File:** `__bootbuild/templates/root/docker/entrypoint.sh`

```bash
#!/bin/bash

# ===================================================================
# Docker Entrypoint - Runs at container startup
# Purpose: Execute bootstrap and start application
# Environment:
#   BOOTSTRAP_TIER: 1, 2, or 3 (set in docker-compose)
#   BOOTSTRAP_MODE: docker (auto-detected)
#   BOOTSTRAP_YES: true (auto-approve)
# ===================================================================

set -euo pipefail

# Get bootstrap directory (should be at /__bootbuild in container)
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-/__bootbuild}"
export BOOTSTRAP_DIR

# Setup logging
log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >&2
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# ===================================================================
# Phase 1: Verify Bootstrap System
# ===================================================================

log_info "🐳 Docker Container Starting (Tier ${BOOTSTRAP_TIER:-unknown})"
log_info "Bootstrap system: $BOOTSTRAP_DIR"

if [[ ! -f "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" ]]; then
    log_error "Bootstrap system not found at $BOOTSTRAP_DIR"
    exit 1
fi

# ===================================================================
# Phase 2: Run Bootstrap (if enabled)
# ===================================================================

# TIER 1: Run phases 1-4 (development)
# TIER 2: Run phases 1-3 (dev + infrastructure, skip CI/CD)
# TIER 3: Run phase 1 only (production essentials)

if [[ "${SKIP_BOOTSTRAP:-false}" == "true" ]]; then
    log_info "⏭️  Skipping bootstrap (SKIP_BOOTSTRAP=true)"
else
    log_info "🔧 Running bootstrap system..."

    case "${BOOTSTRAP_TIER:-2}" in
        1)
            log_info "Tier 1: Sandbox - Running all phases (1-4)"
            BOOTSTRAP_YES=1 BOOTSTRAP_IN_DOCKER=true \
                "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" \
                --phase=1-4 --auto-docker /app
            ;;
        2)
            log_info "Tier 2: Development - Running phases 1-3"
            BOOTSTRAP_YES=1 BOOTSTRAP_IN_DOCKER=true \
                "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" \
                --phase=1-3 --auto-docker /app
            ;;
        3)
            log_info "Tier 3: Production - Running phase 1 only"
            BOOTSTRAP_YES=1 BOOTSTRAP_IN_DOCKER=true \
                BOOTSTRAP_SKIP_UNUSED_PHASES=true \
                "$BOOTSTRAP_DIR/scripts/bootstrap-menu.sh" \
                --phase=1 --auto-docker /app
            ;;
    esac

    if [[ $? -eq 0 ]]; then
        log_info "✅ Bootstrap completed successfully"
    else
        log_error "❌ Bootstrap failed with exit code $?"
        # In development, warn but continue; in production, fail hard
        if [[ "${BOOTSTRAP_TIER:-2}" == "3" ]]; then
            exit 1
        fi
    fi
fi

# ===================================================================
# Phase 3: Run Application
# ===================================================================

log_info "🚀 Starting application..."

# Execute the command passed to this entrypoint
# Examples:
#   npm run dev
#   pnpm dev
#   node server.js

exec "$@"
```

### 3.4 Create Health Check Script

**File:** `__bootbuild/templates/root/docker/healthcheck.sh`

```bash
#!/bin/bash

# ===================================================================
# Docker Health Check
# Called by: healthcheck directive in docker-compose.yml
# Exit: 0 = healthy, 1 = unhealthy
# ===================================================================

set -euo pipefail

HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-http://localhost:3000/api/health}"
TIMEOUT="${HEALTH_CHECK_TIMEOUT:-5}"

# Try to reach health endpoint
if curl -sf --max-time "$TIMEOUT" "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed"
    exit 1
fi
```

### 3.5 Create Docker Configuration Override

**File:** `__bootbuild/config/docker-bootstrap.config`

```ini
# ===================================================================
# Docker-Specific Bootstrap Configuration
# These values override bootstrap.config when running in Docker
# ===================================================================

[docker]
# Auto-detect tier from environment
auto_detect_tier=true

# Docker-specific settings
host=0.0.0.0                    # Listen on all interfaces
bind_all_interfaces=true

# Disable interactive features
skip_interactive=true
auto_approve_all=true

# Logging for container environments
log_format=json
log_to_stdout=true
disable_colors=true

# Skip host-specific checks
skip_docker_check=false
skip_port_availability_check=true   # Docker handles port conflicts

# Performance
cache_bootstrap_results=true
parallel_bootstrap=true

# Development tier specifics
[docker.tier1]
install_dev_tools=true
enable_debugging=true
skip_security_checks=true
allow_host_network=true

# Development tier specifics
[docker.tier2]
install_dev_tools=true
enable_debugging=false
user_mapping=true
resource_limits=true

# Production tier specifics
[docker.tier3]
install_dev_tools=false
enable_debugging=false
user_mapping=true
resource_limits=strict
read_only_filesystem=true
secrets_management=true
```

### 3.6 Create Bootstrap Docker Utility Library

**File:** `__bootbuild/lib/docker-utils.sh`

```bash
#!/bin/bash

# ===================================================================
# Docker Utility Functions
# Source this in bootstrap scripts that need Docker awareness
# ===================================================================

[[ -n "${_BOOTSTRAP_DOCKER_UTILS_LOADED:-}" ]] && return 0
_BOOTSTRAP_DOCKER_UTILS_LOADED=1

# ===================================================================
# Docker Detection
# ===================================================================

is_in_docker() {
    [[ -f "/.dockerenv" ]] || grep -q docker /proc/self/cgroup 2>/dev/null
}

docker_tier() {
    echo "${BOOTSTRAP_TIER:-2}"
}

# ===================================================================
# Docker-Specific Logging (structured for container logs)
# ===================================================================

log_docker_info() {
    local message="$1"
    if [[ "${BOOTSTRAP_LOG_FORMAT:-text}" == "json" ]]; then
        printf '{"level":"info","timestamp":"%s","message":"%s"}\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$message" >&2
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $message" >&2
    fi
}

# ===================================================================
# Docker Resource Detection
# ===================================================================

available_cpus() {
    if [[ -f /sys/fs/cgroup/cpuset.cpus_allowed_list ]]; then
        grep -o . /sys/fs/cgroup/cpuset.cpus_allowed_list | wc -l
    else
        nproc
    fi
}

available_memory_mb() {
    if [[ -f /sys/fs/cgroup/memory.limit_in_bytes ]]; then
        local bytes=$(cat /sys/fs/cgroup/memory.limit_in_bytes)
        echo $((bytes / 1024 / 1024))
    else
        free -m | awk '/^Mem:/{print $2}'
    fi
}

# ===================================================================
# Bootstrap Phase Control
# ===================================================================

should_run_phase() {
    local phase_num="$1"
    local tier="${BOOTSTRAP_TIER:-2}"

    case "$tier" in
        1) return 0 ;;  # Run all phases
        2)
            [[ "$phase_num" -le 3 ]] && return 0  # Phases 1-3
            return 1
            ;;
        3)
            [[ "$phase_num" -eq 1 ]] && return 0  # Phase 1 only
            return 1
            ;;
    esac
}

# ===================================================================
# Secrets Management (Docker Secrets)
# ===================================================================

get_docker_secret() {
    local secret_name="$1"
    local default_value="${2:-}"

    if [[ -f "/run/secrets/$secret_name" ]]; then
        cat "/run/secrets/$secret_name"
    else
        echo "$default_value"
    fi
}
```

### 3.7 Create Bootstrap Docker Script

**File:** `__bootbuild/templates/scripts/bootstrap-docker.sh`

```bash
#!/bin/bash

# ===================================================================
# bootstrap-docker.sh
#
# Purpose: Setup Docker integration for bootstrap system
# Creates: Dockerfiles, docker-compose files, entrypoints
# Config:  [docker] section in bootstrap.config
# ===================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${BOOTSTRAP_DIR}/lib/common.sh"
init_script "bootstrap-docker"

PROJECT_ROOT=$(get_project_root "${1:-.}")

# ===================================================================
# Configuration
# ===================================================================

DOCKER_ENABLED=$(config_get "docker.enabled" "true")

if [[ "$DOCKER_ENABLED" != "true" ]]; then
    log_info "Docker bootstrap disabled"
    exit 0
fi

DOCKER_TIER="${BOOTSTRAP_TIER:-2}"
DOCKERFILE_VARIANTS=("sandbox" "dev" "prod")

# ===================================================================
# Create Docker Directory Structure
# ===================================================================

log_info "Creating Docker integration files..."

ensure_dir "$PROJECT_ROOT/docker"
ensure_dir "$PROJECT_ROOT/docker/postgres"
ensure_dir "$PROJECT_ROOT/docker/redis"
ensure_dir "$PROJECT_ROOT/docker/nginx"

# ===================================================================
# Copy Entrypoints
# ===================================================================

log_info "Installing entrypoints..."

cp "$BOOTSTRAP_DIR/templates/root/docker/entrypoint.sh" \
   "$PROJECT_ROOT/docker/entrypoint.sh"
chmod +x "$PROJECT_ROOT/docker/entrypoint.sh"

cp "$BOOTSTRAP_DIR/templates/root/docker/healthcheck.sh" \
   "$PROJECT_ROOT/docker/healthcheck.sh"
chmod +x "$PROJECT_ROOT/docker/healthcheck.sh"

# ===================================================================
# Copy Dockerfiles based on tier
# ===================================================================

log_info "Copying Dockerfile variants..."

for variant in "${DOCKERFILE_VARIANTS[@]}"; do
    src="$BOOTSTRAP_DIR/templates/docker/Dockerfile.$variant"
    dst="$PROJECT_ROOT/Dockerfile.$variant"

    if [[ -f "$src" ]]; then
        cp "$src" "$dst"
        log_success "Copied Dockerfile.$variant"
    fi
done

# ===================================================================
# Copy Docker Compose Files
# ===================================================================

log_info "Copying docker-compose configurations..."

for variant in "${DOCKERFILE_VARIANTS[@]}"; do
    src="$BOOTSTRAP_DIR/templates/docker/docker-compose.$variant.yml"
    dst="$PROJECT_ROOT/docker-compose.$variant.yml"

    if [[ -f "$src" ]]; then
        cp "$src" "$dst"
        log_success "Copied docker-compose.$variant.yml"
    fi
done

log_success "Docker integration complete!"
```

---

## Part 4: Best Practices Summary

### 4.1 Dockerfile Layer Strategy

```dockerfile
# RULE: Least-changed → Most-changed

FROM base

# Layer 1: System dependencies (rarely changed)
RUN apt-get install -y ...

# Layer 2: Bootstrap system (stable until bootstrap.config changes)
COPY __bootbuild /bootstrap

# Layer 3: Run bootstrap phases (cached across builds)
RUN BOOTSTRAP_YES=1 /bootstrap/scripts/bootstrap-menu.sh --phase=1

# Layer 4: Application code (changes frequently)
COPY . /app

# Layer 5: Install dependencies (changes with package.json)
RUN pnpm install

# Layer 6: Entrypoint (rarely changed)
ENTRYPOINT ["/bootstrap/entrypoint.sh"]
```

**Benefit:** Docker caches bootstrap output layers, rebuilding is fast.

### 4.2 Environment Variables (Container-friendly)

```bash
# DO: Use environment variables for configuration
BOOTSTRAP_TIER=2
BOOTSTRAP_YES=1
BOOTSTRAP_IN_DOCKER=true
BOOTSTRAP_NO_COLOR=true
BOOTSTRAP_LOG_FORMAT=json

# DON'T: Use interactive prompts
BOOTSTRAP_INTERACTIVE=false

# DON'T: Assume TTY
stdin_open: true    # Only for dev containers
tty: true          # Only for dev containers
```

### 4.3 Phase Execution Per Tier

| Phase | Description | Tier 1 | Tier 2 | Tier 3 |
|-------|-------------|--------|--------|--------|
| 1 | AI/Dev Toolkit | ✅ Build | ✅ Build | ✅ Build |
| 2 | Infrastructure (Docker, DB) | ✅ Build | ✅ Build | ❌ Skip |
| 3 | Code Quality (tests, lint) | ✅ Build | ✅ Build | ❌ Skip |
| 4 | CI/CD & Deployment | ✅ Build | ❌ Skip | ❌ Skip |

### 4.4 Health Checks

```yaml
# TIER 1: Minimal (faster startup for dev)
healthcheck:
  disable: true

# TIER 2: Moderate (catch most issues)
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s

# TIER 3: Strict (production reliability)
healthcheck:
  test: ["CMD", "node", "healthcheck.js"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### 4.5 Logging for Containers

```bash
# DO: Log to stdout/stderr
echo "message" >&2

# DO: Use structured logging (JSON)
echo '{"level":"info","message":"..."}' >&2

# DON'T: Log to files in containers
# (container logs are ephemeral)

# DON'T: Use color codes
# (won't appear in container logs)
```

---

## Part 5: Implementation Roadmap

### Phase 1: Foundation (1 week)
- [ ] Add `docker-utils.sh` library with detection functions
- [ ] Modify `bootstrap-menu.sh` to support `--auto-docker` flag
- [ ] Create `docker-bootstrap.config` override file
- [ ] Add `BOOTSTRAP_IN_DOCKER` environment variable support

### Phase 2: Entrypoints (1 week)
- [ ] Create `entrypoint.sh` with phase control logic
- [ ] Create `healthcheck.sh` with configurable endpoints
- [ ] Add bootstrap logging to structured JSON format
- [ ] Test in all three tier containers

### Phase 3: Docker Scripts (1 week)
- [ ] Create `bootstrap-docker.sh` for Docker integration setup
- [ ] Create `.dockerignore` template
- [ ] Add Docker secrets support to config-manager
- [ ] Document Docker-specific configuration options

### Phase 4: Testing & Documentation (1 week)
- [ ] Create test containers for each tier
- [ ] Verify phase execution order
- [ ] Test health checks
- [ ] Document Docker workflow in README

---

## Part 6: Migration Guide: From Host to Container

### Example: Adding Docker Support to sparkq

**Before (Host-only):**
```bash
# Run bootstrap on host machine
./scripts/bootstrap-menu.sh -i ./my-project

# Then start dev environment
npm run dev
```

**After (Host + Docker):**
```bash
# Option 1: Run on host (unchanged)
./scripts/bootstrap-menu.sh -i ./my-project
docker compose up

# Option 2: Run bootstrap IN container (new)
docker compose build --no-cache  # Bootstrap runs during build
docker compose up

# Option 3: Skip bootstrap, start pre-configured container
SKIP_BOOTSTRAP=1 docker compose up
```

---

## Part 7: Common Files Template

### docker/.gitignore
```
# Secrets (never commit)
secrets/
*.pem
*.key

# Build artifacts
Dockerfile
docker-compose.yml
```

### docker/entrypoint.sh
```bash
#!/bin/bash
exec "$@"
```

### docker-compose.override.yml (local development)
```yaml
version: '3.8'

services:
  app:
    environment:
      BOOTSTRAP_TIER: 1
      DEBUG: 'app:*'
      LOG_LEVEL: debug
    volumes:
      - ~/.ssh:/root/.ssh:ro
```

---

## Part 8: Questions & Next Steps

**Questions for Bryan:**

1. Should bootstrap run at **build time** (immutable layers) or **runtime** (more flexible)?
   - **Recommendation:** Build time for phases 1-3, runtime for phase 4 only

2. Do you want **runtime bootstrap** capability (skip bootstrap at build)?
   - **Recommendation:** Yes - allows `SKIP_BOOTSTRAP=1` for faster iteration

3. Should Docker tier selection be **automatic** or **manual**?
   - **Recommendation:** Auto-detect from `BOOTSTRAP_TIER` env var, fall back to config

4. Do you need **secrets management** integration (Docker secrets, .env files)?
   - **Recommendation:** Yes - template both approaches, default to .env

**Next Implementation:**
1. ✅ Create `docker-utils.sh`
2. ✅ Modify `bootstrap-menu.sh` for `--auto-docker` support
3. ✅ Create `entrypoint.sh` and `healthcheck.sh`
4. ✅ Create `bootstrap-docker.sh` script
5. ✅ Add Docker configuration override file
6. ✅ Test all three tiers end-to-end

---

## Conclusion

Your bootstrap system is **excellent for Docker integration**. The configuration-driven architecture, phase-based execution, and idempotent scripts are exactly what Docker needs. The main work is:

1. **Detect Docker environment** (1 function)
2. **Suppress interactive features** (3 environment variables)
3. **Create entrypoints** (2 shell scripts)
4. **Add tier-specific logic** (configuration)

This gets you from "bootstrap runs on host" to "bootstrap runs IN containers" while keeping everything backward compatible.

Would you like me to implement any of these recommendations?
