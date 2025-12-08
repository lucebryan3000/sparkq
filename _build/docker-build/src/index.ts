// src/index.ts
// SparkQ Bootstrap API

import express from 'express'
import { db } from './db'
import { runBootstrap, listProfiles } from './bootstrap'

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

// List available profiles
app.get('/profiles', (_, res) => {
  res.json(listProfiles())
})

// Bootstrap a project
app.post('/bootstrap', async (req, res) => {
  const { path, profile, scripts } = req.body
  if (!path) return res.status(400).json({ error: 'path required' })

  console.log(`Bootstrap: ${path} (${profile || 'standard'})`)
  try {
    const result = await runBootstrap(path, profile, scripts)
    res.json(result)
  } catch (e: any) {
    res.status(500).json({ error: e.message })
  }
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
app.listen(port, () => {
  console.log(`SparkQ Bootstrap API on :${port}`)
  console.log(`Health: http://localhost:${port}/health`)
  console.log(`Profiles: http://localhost:${port}/profiles`)
})
