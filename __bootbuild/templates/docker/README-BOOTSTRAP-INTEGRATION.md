# Docker Bootstrap Integration Guide

This directory contains Docker configuration templates integrated with the bootstrap system. Each tier (Sandbox, Development, Production) includes entrypoints that automatically run bootstrap phases during container startup.

---

## Quick Start

### Tier 1: Sandbox (Rapid Development)
```bash
cd docker_tier1_sandbox
docker-compose build
docker-compose up
docker-compose exec app bash
# Bootstrap runs automatically (phases 1-4)
```

### Tier 2: Development (Team Development)
```bash
cd docker_tier2_dev
docker-compose build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)
docker-compose up
docker-compose logs -f app
# Bootstrap runs automatically (phases 1-3, skips CI/CD)
```

### Tier 3: Production (Hardened)
```bash
cd docker_tier3_prod
# Create secrets
mkdir -p secrets
echo "strong-password" > secrets/db_password.txt
echo "strong-redis-password" > secrets/redis_password.txt
docker-compose build
docker-compose up
# Bootstrap runs automatically (phase 1 only)
```

---

## How Bootstrap Integration Works

### Entrypoint Flow

```
Container Start
    ↓
[entrypoint.sh]
    ↓
Setup Environment
    ├─ Configure PostgreSQL
    ├─ Start Redis
    └─ Setup user permissions
    ↓
Run Bootstrap (if SKIP_BOOTSTRAP != true)
    ├─ Detect BOOTSTRAP_TIER
    ├─ Run appropriate phases
    └─ Configure application
    ↓
Start Application
    └─ exec "$@"
```

### Bootstrap Phase Execution Per Tier

| Phase | Description | Tier 1 | Tier 2 | Tier 3 |
|-------|-------------|--------|--------|--------|
| 1 | AI/Dev Toolkit | ✅ | ✅ | ✅ |
| 2 | Infrastructure | ✅ | ✅ | ❌ |
| 3 | Code Quality | ✅ | ✅ | ❌ |
| 4 | CI/CD | ✅ | ❌ | ❌ |

---

## Configuration Files

### docker-compose.yml (Each tier)

**Environment variables for bootstrap:**
```yaml
environment:
  BOOTSTRAP_TIER: 1|2|3          # Which tier to run (set automatically)
  SKIP_BOOTSTRAP: false          # Set to true to skip bootstrap
  BOOTSTRAP_DIR: /__bootbuild    # Location of bootstrap system
```

### entrypoint.sh (Each tier)

**Key functions:**
- `configure_postgres()` - Setup PostgreSQL service
- `start_redis()` - Start Redis service
- `run_bootstrap()` - Execute bootstrap based on BOOTSTRAP_TIER
- `main()` - Orchestrate all steps

**Environment detection:**
```bash
BOOTSTRAP_TIER="${BOOTSTRAP_TIER:-1|2|3}"  # Default per tier
BOOTSTRAP_IN_DOCKER="true"                  # Auto-set
BOOTSTRAP_NO_COLOR="true"                   # Disable ANSI colors
BOOTSTRAP_LOG_FORMAT="text|json"            # Logging format
```

---

## Common Workflows

### Skip Bootstrap (Already Pre-configured)

If your image already has everything bootstrapped:

```bash
SKIP_BOOTSTRAP=1 docker-compose up
```

### Run Bootstrap Only (No Application)

```bash
docker-compose run app --phase=1-3  # Tier 2 example
```

### Check Bootstrap Logs

Logs are printed to stderr, captured by Docker:

```bash
docker-compose logs app | grep -E "Bootstrap|Error"
```

### Rebuild Without Cache

Forces fresh bootstrap setup:

```bash
docker-compose build --no-cache
docker-compose up
```

---

## Tier Characteristics

### TIER 1: Sandbox

**When to use:**
- Local development
- Rapid prototyping
- Learning Docker
- Full feature access

**Bootstrap behavior:**
- Runs **all phases** (1-4)
- Full developer tools
- No security restrictions
- Fastest startup

**Services:**
- PostgreSQL (embedded)
- Redis (embedded)
- Node.js with dev tools

**User:**
- root (full permissions)

**Example:**
```bash
cd docker_tier1_sandbox
docker-compose up
docker-compose exec app npm run dev
```

---

### TIER 2: Development

**When to use:**
- Team development
- Testing realistic constraints
- Pre-production testing
- Staging environments

**Bootstrap behavior:**
- Runs **phases 1-3** (skips CI/CD)
- Balanced security/convenience
- User mapping for file permissions
- Resource limits enabled

**Services:**
- PostgreSQL (embedded)
- Redis (embedded)
- Node.js with dev tools

**User:**
- `node` (UID/GID matching host)

**Example:**
```bash
cd docker_tier2_dev
# Match your host user ID
docker-compose build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g)
docker-compose up
docker-compose logs -f app
```

---

### TIER 3: Production

**When to use:**
- Production deployments
- Security-sensitive applications
- Performance-critical systems
- Compliance requirements

**Bootstrap behavior:**
- Runs **phase 1 only** (essentials)
- Minimal image size
- Strict security enforced
- Fail-fast on errors
- JSON structured logging

**Services:**
- PostgreSQL (embedded)
- Redis (embedded)
- Nginx (reverse proxy)
- Node.js runtime only

**User:**
- `appuser` (non-root, UID 1001)

**Example:**
```bash
cd docker_tier3_prod
mkdir -p secrets
echo "$(openssl rand -base64 32)" > secrets/db_password.txt
docker-compose build
docker-compose up
```

---

## Environment Variables

### All Tiers

```bash
# Service configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=app
POSTGRES_PORT=5432
REDIS_PORT=6379

# Bootstrap control
BOOTSTRAP_TIER=1|2|3
SKIP_BOOTSTRAP=false
BOOTSTRAP_DIR=/__bootbuild
```

### Tier 2 & 3 (User Mapping)

```bash
USER_ID=1000              # Host user ID (Tier 2 example)
GROUP_ID=1000             # Host group ID
```

### Tier 3 (Production)

```bash
POSTGRES_PASSWORD=        # REQUIRED
REDIS_PASSWORD=           # REQUIRED
APP_USER=appuser
APP_GROUP=appgroup
USER_ID=1001
GROUP_ID=1001
```

---

## Health Checks

### Tier 1: None (Fast startup)
```yaml
healthcheck:
  disable: true
```

### Tier 2: Moderate
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Tier 3: Strict
```yaml
healthcheck:
  test: ["CMD", "node", "healthcheck.js"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

---

## Entrypoint Customization

### Override Entrypoint

```yaml
# Use default entrypoint with custom bootstrap
docker-compose -f docker-compose.yml up

# Skip entrypoint entirely
docker-compose run --entrypoint bash app

# Custom bootstrap phases
docker-compose run app --phase=1
```

### Environment Overrides

```bash
# Custom PostgreSQL
export POSTGRES_DB=mydb
export POSTGRES_USER=myuser
docker-compose up

# Skip bootstrap
export SKIP_BOOTSTRAP=1
docker-compose up
```

---

## Troubleshooting

### Bootstrap Times Out

**Symptom:** Container exits with "timeout waiting for service"

**Solution:**
```bash
# Increase service startup time
docker-compose up --timeout 120

# Or check logs
docker-compose logs app | grep -i error
```

### PostgreSQL Won't Start

**Symptom:** "No PostgreSQL version found"

**Solution:**
Ensure the image includes PostgreSQL. Check your Dockerfile has:
```dockerfile
apt-get install postgresql postgresql-client
```

### Permission Denied on Files

**Symptom:** "Permission denied" when writing files

**Solution (Tier 2):**
Rebuild with correct USER_ID/GROUP_ID:
```bash
docker-compose build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g)
```

### Bootstrap Fails in Production

**Symptom:** Container exits on startup

**Solution:**
- Check environment variables are set
- Verify bootstrap directory exists in image
- Check logs: `docker-compose logs app`
- Try with SKIP_BOOTSTRAP=1 to isolate the issue

---

## Advanced Usage

### Multi-Stage Bootstrap

Run bootstrap at different times:

```bash
# Build with bootstrap
docker build -f Dockerfile.tier2 -t myapp:with-bootstrap .

# Or skip and run later
SKIP_BOOTSTRAP=1 docker run myapp:with-bootstrap

# Then run bootstrap inside
docker exec myapp /bootstrap/scripts/bootstrap-menu.sh --phase=1-3
```

### Selective Phase Execution

```bash
# Tier 2: Skip phase 3 (testing)
docker-compose run app \
  --phase=1-2 /app

# Tier 1: Run only phase 2 (infrastructure)
docker-compose run app \
  --phase=2 /app
```

### Custom Bootstrap Flags

Environment variables are passed through:

```bash
export BOOTSTRAP_LOG_FORMAT=json
export BOOTSTRAP_DEBUG=true
docker-compose up
```

---

## Integration with docker-compose Override

Create `docker-compose.override.yml` for local customization:

```yaml
version: '3.8'

services:
  app:
    environment:
      SKIP_BOOTSTRAP: "1"
      DEBUG: "app:*"
      LOG_LEVEL: "debug"
    volumes:
      - ~/.ssh:/root/.ssh:ro
      - ~/.gitconfig:/root/.gitconfig:ro
```

---

## Debugging

### View Bootstrap Output

```bash
docker-compose logs -f app | grep -E "Bootstrap|Running|Complete"
```

### Run Bootstrap Manually

```bash
docker-compose exec app \
  /bootstrap/scripts/bootstrap-menu.sh \
  --phase=1 \
  /app
```

### Check Bootstrap System

```bash
docker-compose exec app ls -la /__bootbuild/
docker-compose exec app cat /__bootbuild/config/bootstrap.config
```

### Test Individual Services

```bash
# Test PostgreSQL
docker-compose exec app psql -U postgres -d app -c "SELECT 1"

# Test Redis
docker-compose exec app redis-cli ping

# Test app connectivity
docker-compose exec app curl http://localhost:3000/health
```

---

## Best Practices

1. **Always match user IDs (Tier 2/3)**
   ```bash
   docker-compose build --build-arg USER_ID=$(id -u)
   ```

2. **Use SKIP_BOOTSTRAP for pre-configured images**
   ```bash
   SKIP_BOOTSTRAP=1 docker-compose up
   ```

3. **Check logs immediately**
   ```bash
   docker-compose logs -f app
   ```

4. **Test health check endpoint**
   ```bash
   docker-compose exec app curl http://localhost:3000/health
   ```

5. **Keep production secrets out of images**
   ```bash
   # Use Docker secrets or .env files
   mkdir -p secrets
   echo "strong-password" > secrets/db_password.txt
   ```

---

## References

- [Bootstrap System Documentation](../../docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

For more information on bootstrap integration, see:
- `DOCKER-BOOTSTRAP-EVALUATION.md` (overall architecture)
- `docker-bootstrap.config` (Docker-specific settings)
- `lib/docker-utils.sh` (Docker detection functions)
