# Bootstrap System Dockerization Plan

> **Target Host**: CodeSwarm (Ubuntu dev server) — single-user secure sandbox
> **Stack**: Node.js + TypeScript + PostgreSQL (all-in-one container)
> **Philosophy**: Maximum dev velocity, zero friction, full host access
> **Usage**: Just Bryan. No auth. No validation theater. Ship fast.

---

## Design Principles

1. **Docker = localhost** — `--network host` means ports work identically
2. **Full filesystem access** — Mount `/` read-write, no path translation
3. **Hot reload everything** — Code changes apply instantly
4. **One command** — `make dev` starts everything with logs tailing
5. **Direct DB access** — `psql` works from host, no wrappers
6. **Skip ceremony** — No API versioning, no idempotency, no validation
7. **Sync execution** — One user = no job queue needed

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CodeSwarm Host                                   │
│                                                                         │
│   Everything runs as if local - no containers in the mental model      │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │  sparkq-bootstrap (--network host, --privileged)                │  │
│   │                                                                  │  │
│   │   localhost:3000  →  Node.js API (hot reload via tsx watch)     │  │
│   │   localhost:5432  →  PostgreSQL (direct psql access)            │  │
│   │                                                                  │  │
│   │   Mount: / → /host (entire filesystem, rw)                      │  │
│   │                                                                  │  │
│   │   /home/user/project accessible as /host/home/user/project      │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│   Usage:                                                                │
│     curl localhost:3000/bootstrap -d '{"path":"/home/user/proj"}'      │
│     psql -h localhost -U bootstrap sparkq                              │
│     make dev   # starts container with logs                            │
│     make reset # drops and recreates schema                            │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Container Foundation

### 1.1 Dockerfile

```dockerfile
# _build/Dockerfile
FROM node:20-bookworm

# System deps including supervisor and cron
RUN apt-get update && apt-get install -y \
    postgresql-15 postgresql-contrib-15 \
    supervisor cron \
    git curl jq sudo make \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable && corepack prepare pnpm@latest --activate \
    && npm install -g tsx

# PostgreSQL setup
USER postgres
RUN /usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/data && \
    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data -l /tmp/pg.log start && \
    psql -c "CREATE USER bootstrap WITH SUPERUSER PASSWORD 'bootstrap';" && \
    createdb -O bootstrap sparkq && \
    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data stop

USER root

# Match host user for seamless file ops
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd -g ${HOST_GID} dev 2>/dev/null || true && \
    useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Supervisor and cron config
COPY _build/supervisord.conf /etc/supervisor/conf.d/sparkq.conf
COPY _build/crontab /etc/cron.d/sparkq
RUN chmod 0644 /etc/cron.d/sparkq && crontab /etc/cron.d/sparkq

# Log directory
RUN mkdir -p /var/log/sparkq && chown dev:dev /var/log/sparkq

WORKDIR /app
COPY _build/start.sh /start.sh
RUN chmod +x /start.sh

# Run as root so supervisor can manage all processes
ENTRYPOINT ["/start.sh"]
```

### 1.2 Startup Script

```bash
#!/bin/bash
# _build/start.sh
set -e

echo "=== SparkQ Bootstrap ==="
echo "Starting supervisor (manages PostgreSQL + API + Cron)..."

# Fix PostgreSQL data permissions
chown -R postgres:postgres /var/lib/postgresql/data 2>/dev/null || true
chmod 700 /var/lib/postgresql/data

# Apply schema on first boot (after PostgreSQL starts via supervisor)
(
  sleep 3  # Wait for PostgreSQL to start
  until pg_isready -q; do sleep 0.5; done
  echo "PostgreSQL ready, applying schema..."
  cd /app
  PGPASSWORD=bootstrap psql -h localhost -U bootstrap -d sparkq -f src/db/schema.sql 2>/dev/null || true
  echo "Schema applied"
) &

# Start supervisor (runs PostgreSQL, API, and cron as managed processes)
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
```

### 1.3 Supervisor Config

```ini
# _build/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/sparkq/supervisord.log
pidfile=/var/run/supervisord.pid

[program:postgresql]
command=/usr/lib/postgresql/15/bin/postgres -D /var/lib/postgresql/data
user=postgres
autostart=true
autorestart=true
stdout_logfile=/var/log/sparkq/postgresql.log
stderr_logfile=/var/log/sparkq/postgresql.log

[program:sparkq-api]
command=tsx watch /app/src/index.ts
directory=/app
user=dev
environment=DATABASE_URL="postgresql://bootstrap:bootstrap@localhost:5432/sparkq",PORT="3000"
autostart=true
autorestart=true
startsecs=5
startretries=3
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:cron]
command=/usr/sbin/cron -f
autostart=true
autorestart=true
stdout_logfile=/var/log/sparkq/cron.log
stderr_logfile=/var/log/sparkq/cron.log
```

### 1.4 Cron Jobs

```cron
# _build/crontab
# SparkQ scheduled maintenance

# Cleanup old jobs (30+ days) - daily at 2am
0 2 * * * curl -s localhost:3000/sql -H "Content-Type: application/json" -d '{"sql":"DELETE FROM jobs WHERE started_at < NOW() - INTERVAL '\''30 days'\''"}' >> /var/log/sparkq/cleanup.log 2>&1

# Health check ping every 5 minutes (for uptime logging)
*/5 * * * * curl -s localhost:3000/health >> /var/log/sparkq/health.log 2>&1

# Vacuum PostgreSQL weekly (Sunday 3am)
0 3 * * 0 sudo -u postgres vacuumdb --all --analyze >> /var/log/sparkq/vacuum.log 2>&1

# Rotate logs monthly (1st of month, 4am)
0 4 1 * * find /var/log/sparkq -name "*.log" -size +10M -exec truncate -s 0 {} \;
```

### 1.5 Docker Compose

```yaml
# docker-compose.yml
services:
  sparkq:
    build:
      context: .
      dockerfile: _build/Dockerfile
      args:
        HOST_UID: ${HOST_UID:-1000}
        HOST_GID: ${HOST_GID:-1000}
    container_name: sparkq
    network_mode: host
    privileged: true

    # Auto-restart on crash or host reboot
    restart: always

    # UNCAPPED RESOURCES - use everything available
    # No cpu/memory limits. If it causes issues, add limits later.

    volumes:
      - /:/host:rw                              # Entire filesystem
      - .:/app:rw                               # Source for hot reload
      - pgdata:/var/lib/postgresql/data         # Persist DB
      - sparkq-logs:/var/log/sparkq             # Persist logs
      - ${HOME}/.ssh:/home/dev/.ssh:ro          # Git creds
      - ${HOME}/.gitconfig:/home/dev/.gitconfig:ro
      - /var/run/docker.sock:/var/run/docker.sock

    environment:
      DATABASE_URL: postgresql://bootstrap:bootstrap@localhost:5432/sparkq
      PORT: 3000

    working_dir: /app

volumes:
  pgdata:
  sparkq-logs:
```

### 1.6 Makefile

```makefile
# Makefile
.PHONY: dev up stop logs reset db shell build clean health

dev:
	@docker compose up --build

up:
	@docker compose up -d --build

stop:
	@docker compose down

logs:
	@docker compose logs -f

reset:
	@docker compose exec sparkq psql -U bootstrap sparkq -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	@docker compose exec sparkq psql -U bootstrap sparkq -f /app/src/db/schema.sql
	@echo "Database reset"

db:
	@psql -h localhost -U bootstrap sparkq

shell:
	@docker compose exec sparkq bash

build:
	@docker compose build

clean:
	@docker compose down -v --rmi local

health:
	@curl -s localhost:3000/health | jq .

# Usage: make bootstrap P=/home/user/myproject
bootstrap:
	@curl -s -X POST localhost:3000/bootstrap -H "Content-Type: application/json" -d '{"path":"$(P)"}' | jq .
```

---

## Phase 2: TypeScript Application (~200 lines total)

### 2.1 Project Structure

```
sparkq/
├── src/
│   ├── index.ts          # Express app (~80 lines)
│   ├── db.ts             # pg client (~40 lines)
│   ├── bootstrap.ts      # Script executor (~60 lines)
│   └── db/
│       └── schema.sql    # Single schema file
├── bootstrap/            # Existing bash scripts
├── _build/
│   ├── Dockerfile
│   └── start.sh
├── Makefile
├── docker-compose.yml
├── package.json
└── tsconfig.json
```

### 2.2 Schema

```sql
-- src/db/schema.sql
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT UNIQUE NOT NULL,
    profile TEXT DEFAULT 'standard',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    config JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS jobs (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'running',
    log TEXT DEFAULT '',
    exit_code INTEGER,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_jobs_project ON jobs(project_id);
CREATE INDEX IF NOT EXISTS idx_projects_path ON projects(path);
```

### 2.3 Database Client

```typescript
// src/db.ts
import { Pool } from 'pg'

const pool = new Pool({ connectionString: process.env.DATABASE_URL })

export const db = {
  query: (sql: string, params?: any[]) => pool.query(sql, params),

  async getProject(path: string) {
    const { rows } = await pool.query('SELECT * FROM projects WHERE path = $1', [path])
    return rows[0]
  },

  async upsertProject(name: string, path: string) {
    const { rows } = await pool.query(
      `INSERT INTO projects (name, path) VALUES ($1, $2)
       ON CONFLICT (path) DO UPDATE SET name = $1 RETURNING *`,
      [name, path]
    )
    return rows[0]
  },

  async createJob(projectId: number) {
    const { rows } = await pool.query(
      'INSERT INTO jobs (project_id) VALUES ($1) RETURNING *',
      [projectId]
    )
    return rows[0]
  },

  async completeJob(id: number, exitCode: number, log: string) {
    await pool.query(
      `UPDATE jobs SET status = $1, exit_code = $2, log = $3, completed_at = NOW() WHERE id = $4`,
      [exitCode === 0 ? 'completed' : 'failed', exitCode, log, id]
    )
  },

  async getJob(id: number) {
    const { rows } = await pool.query('SELECT * FROM jobs WHERE id = $1', [id])
    return rows[0]
  },

  async listJobs(limit = 20) {
    const { rows } = await pool.query(
      `SELECT j.*, p.name, p.path FROM jobs j
       JOIN projects p ON j.project_id = p.id
       ORDER BY j.started_at DESC LIMIT $1`,
      [limit]
    )
    return rows
  }
}
```

### 2.4 Bootstrap Executor

```typescript
// src/bootstrap.ts
import { spawn } from 'child_process'
import { existsSync } from 'fs'
import { db } from './db'

const SCRIPTS_DIR = '/app/bootstrap/scripts'

const PROFILES: Record<string, string[]> = {
  minimal: ['init', 'git'],
  standard: ['init', 'git', 'deps', 'lint', 'test'],
  full: ['init', 'git', 'deps', 'lint', 'test', 'docker', 'ci'],
}

export async function runBootstrap(projectPath: string, profile = 'standard') {
  // Translate host path to container path
  const containerPath = projectPath.startsWith('/host') ? projectPath : `/host${projectPath}`
  const hostPath = projectPath.startsWith('/host') ? projectPath.slice(5) : projectPath

  const name = hostPath.split('/').pop() || 'project'
  const project = await db.upsertProject(name, hostPath)
  const job = await db.createJob(project.id)

  const scripts = PROFILES[profile] || PROFILES.standard
  let log = `Bootstrap: ${hostPath}\nProfile: ${profile}\nScripts: ${scripts.join(', ')}\n\n`
  let exitCode = 0

  for (const script of scripts) {
    const scriptPath = `${SCRIPTS_DIR}/bootstrap-${script}.sh`

    if (!existsSync(scriptPath)) {
      log += `[SKIP] ${script} - script not found\n`
      continue
    }

    log += `\n=== ${script} ===\n`
    const result = await runScript(scriptPath, containerPath)
    log += result.output

    if (result.code !== 0) {
      log += `\n[FAILED] ${script} exited with ${result.code}\n`
      exitCode = result.code
      break
    }
    log += `[OK]\n`
  }

  await db.completeJob(job.id, exitCode, log)
  return { jobId: job.id, exitCode, success: exitCode === 0 }
}

function runScript(scriptPath: string, cwd: string): Promise<{ code: number; output: string }> {
  return new Promise(resolve => {
    const proc = spawn('bash', [scriptPath, cwd], {
      cwd,
      env: { ...process.env, BOOTSTRAP_YES: 'true', PROJECT_ROOT: cwd }
    })
    let output = ''
    proc.stdout.on('data', d => output += d)
    proc.stderr.on('data', d => output += d)
    proc.on('close', code => resolve({ code: code || 0, output }))
    proc.on('error', e => resolve({ code: 1, output: e.message }))
  })
}
```

### 2.5 Express API

```typescript
// src/index.ts
import express from 'express'
import { db } from './db'
import { runBootstrap } from './bootstrap'

const app = express()
app.use(express.json())

// Health check
app.get('/health', async (_, res) => {
  try {
    await db.query('SELECT 1')
    res.json({ status: 'ok', timestamp: new Date().toISOString() })
  } catch (e: any) {
    res.status(500).json({ status: 'error', error: e.message })
  }
})

// Bootstrap a project
app.post('/bootstrap', async (req, res) => {
  const { path, profile } = req.body
  if (!path) return res.status(400).json({ error: 'path required' })

  console.log(`Bootstrap: ${path} (${profile || 'standard'})`)
  const result = await runBootstrap(path, profile)
  res.json(result)
})

// Get job status
app.get('/job/:id', async (req, res) => {
  const job = await db.getJob(parseInt(req.params.id))
  if (!job) return res.status(404).json({ error: 'not found' })
  res.json(job)
})

// Get job log
app.get('/job/:id/log', async (req, res) => {
  const job = await db.getJob(parseInt(req.params.id))
  if (!job) return res.status(404).json({ error: 'not found' })
  res.type('text/plain').send(job.log || '')
})

// List recent jobs
app.get('/jobs', async (req, res) => {
  const limit = parseInt(req.query.limit as string) || 20
  const jobs = await db.listJobs(limit)
  res.json(jobs)
})

// List projects
app.get('/projects', async (_, res) => {
  const { rows } = await db.query('SELECT * FROM projects ORDER BY created_at DESC')
  res.json(rows)
})

// Direct SQL (dev convenience)
app.post('/sql', async (req, res) => {
  try {
    const result = await db.query(req.body.sql, req.body.params)
    res.json({ rows: result.rows, rowCount: result.rowCount })
  } catch (e: any) {
    res.status(400).json({ error: e.message })
  }
})

const port = process.env.PORT || 3000
app.listen(port, () => console.log(`SparkQ API on :${port}`))
```

### 2.6 Package Configuration

```json
{
  "name": "sparkq-bootstrap",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "start": "tsx src/index.ts"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.0",
    "@types/pg": "^8.10.9",
    "tsx": "^4.6.2",
    "typescript": "^5.3.2"
  }
}
```

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "strict": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

---

## Phase 3: Local Dev (No Docker)

For times when even Docker is overhead:

```bash
# Install PostgreSQL locally (one-time)
sudo apt install postgresql
sudo -u postgres createuser -s $(whoami)
createdb sparkq

# Run directly
export DATABASE_URL=postgresql://localhost/sparkq
pnpm install
pnpm dev
```

---

## Phase 4: Quick Reference

### Commands

```bash
# Development
make dev              # Start with logs
make reset            # Wipe and recreate DB
make db               # psql shell

# Bootstrap
make bootstrap P=/home/user/myproject
curl localhost:3000/bootstrap -d '{"path":"/home/user/proj","profile":"full"}'

# Check status
make health
curl localhost:3000/jobs
curl localhost:3000/job/1/log
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/bootstrap` | Run bootstrap `{path, profile?}` |
| GET | `/job/:id` | Job status |
| GET | `/job/:id/log` | Job log (text) |
| GET | `/jobs` | List jobs |
| GET | `/projects` | List projects |
| POST | `/sql` | Execute SQL `{sql, params?}` |

### Profiles

| Profile | Scripts |
|---------|---------|
| minimal | init, git |
| standard | init, git, deps, lint, test |
| full | init, git, deps, lint, test, docker, ci |

---

## What This Gets You

| Feature | Benefit |
|---------|---------|
| **`restart: always`** | Survives crashes, host reboots — always running |
| **Supervisor** | Manages PostgreSQL + Node API + Cron as one unit |
| **Uncapped resources** | Full host CPU/RAM available, no artificial limits |
| **Cron cleanup** | Old jobs auto-deleted after 30 days |
| **Health logging** | `/var/log/sparkq/health.log` — audit trail of uptime |
| **PostgreSQL vacuum** | Weekly optimization, keeps DB fast |
| **Log rotation** | Auto-truncates logs over 10MB monthly |
| **Hot reload** | Edit TypeScript, save, API restarts instantly |
| **`network_mode: host`** | Ports work exactly like localhost |
| **`privileged: true`** | No permission friction anywhere |
| **Full filesystem mount** | Any host path accessible, no translation |

### What Supervisor Manages

```
sparkq-api      RUNNING   → tsx watch (hot reload)
postgresql      RUNNING   → PostgreSQL 15
cron            RUNNING   → Scheduled maintenance
```

If any process crashes, supervisor restarts it automatically. If the container crashes, Docker restarts it.

### Cron Schedule

| Time | Task |
|------|------|
| Daily 2am | Delete jobs older than 30 days |
| Every 5 min | Health check ping (logged) |
| Sunday 3am | PostgreSQL vacuum/analyze |
| 1st of month 4am | Rotate large log files |

---

## Implementation Checklist

- [ ] Create `_build/Dockerfile`
- [ ] Create `_build/start.sh`
- [ ] Create `_build/supervisord.conf`
- [ ] Create `_build/crontab`
- [ ] Create `docker-compose.yml`
- [ ] Create `Makefile`
- [ ] Create `src/db/schema.sql`
- [ ] Create `src/db.ts`
- [ ] Create `src/bootstrap.ts`
- [ ] Create `src/index.ts`
- [ ] Create `package.json` and `tsconfig.json`
- [ ] Run `make up` and verify all processes running
- [ ] Test `curl localhost:3000/health`

---

*Document Version: 5.0 — Production-Ready Dev Sandbox*
*Total app code: ~200 lines*
*Added: supervisor, cron, auto-restart, uncapped resources*
