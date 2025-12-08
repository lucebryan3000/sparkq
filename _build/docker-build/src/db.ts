// src/db.ts
// SparkQ Bootstrap database client

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
