// src/bootstrap.ts
// SparkQ Bootstrap script executor

import { spawn } from 'child_process'
import { existsSync } from 'fs'
import { db } from './db'

const SCRIPTS_DIR = '/app/bootstrap/templates/scripts'

const PROFILES: Record<string, string[]> = {
  minimal: ['git', 'environment'],
  standard: ['git', 'github', 'environment', 'typescript', 'packages', 'linting'],
  full: ['git', 'github', 'environment', 'typescript', 'packages', 'linting', 'testing', 'docker', 'vscode', 'claude'],
  claude: ['git', 'environment', 'claude'],
  codex: ['git', 'environment', 'codex'],
}

export async function runBootstrap(projectPath: string, profile = 'standard', scripts?: string[]) {
  // Translate host path to container path
  const containerPath = projectPath.startsWith('/host') ? projectPath : `/host${projectPath}`
  const hostPath = projectPath.startsWith('/host') ? projectPath.slice(5) : projectPath

  const name = hostPath.split('/').pop() || 'project'
  const project = await db.upsertProject(name, hostPath)
  const job = await db.createJob(project.id)

  // Use provided scripts or fall back to profile
  const scriptsToRun = scripts || PROFILES[profile] || PROFILES.standard
  let log = `Bootstrap: ${hostPath}\nProfile: ${profile}\nScripts: ${scriptsToRun.join(', ')}\n\n`
  let exitCode = 0

  for (const script of scriptsToRun) {
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

export function listProfiles() {
  return Object.entries(PROFILES).map(([name, scripts]) => ({ name, scripts }))
}
