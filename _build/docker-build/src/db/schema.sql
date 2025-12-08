-- src/db/schema.sql
-- SparkQ Bootstrap database schema (idempotent)

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
