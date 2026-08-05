import type { AutoReviewConfigFile, AutoReviewConfigPaths, ConfigIssue, LoadConfigResult } from './config.js'
import { mkdirSync, readFileSync, renameSync, unlinkSync, writeFileSync } from 'node:fs'
import { dirname } from 'node:path'
import {
  CONFIG_SCHEMA_URL,
  defaultAutoReviewAgentDir,
  getAutoReviewConfigPaths,
  loadAutoReviewConfig,
  parseAutoReviewConfigFile,
  validateAutoReviewConfigFile,
} from './config.js'

export type AutoReviewConfigScope = 'global' | 'project'

interface ScopeSnapshotBase {
  scope: AutoReviewConfigScope
  cwd: string
  path: string
  source: string | undefined
}

export type AutoReviewScopeSnapshot =
  | (ScopeSnapshotBase & {
      valid: true
      config: AutoReviewConfigFile
    })
  | (ScopeSnapshotBase & {
      valid: false
      issue: ConfigIssue
    })

export type ConfigMutationResult =
  | {
      ok: true
      loadResult: LoadConfigResult
      snapshot: AutoReviewScopeSnapshot
    }
  | {
      ok: false
      message: string
    }

export interface AutoReviewConfigFileSystem {
  readFile: (path: string) => string | undefined
  writeFile: (path: string, source: string) => void
  rename: (sourcePath: string, destinationPath: string) => void
  mkdir: (path: string) => void
  unlink: (path: string) => void
}

export interface AutoReviewConfigStoreOptions {
  agentDir?: string
  fileSystem?: AutoReviewConfigFileSystem
}

function isNodeError(error: unknown, code: string): boolean {
  return error instanceof Error && 'code' in error && error.code === code
}

const defaultFileSystem: AutoReviewConfigFileSystem = {
  readFile(path) {
    try {
      return readFileSync(path, 'utf8')
    } catch (error) {
      if (isNodeError(error, 'ENOENT')) {
        return undefined
      }
      throw error
    }
  },
  writeFile(path, source) {
    writeFileSync(path, source, 'utf8')
  },
  rename(sourcePath, destinationPath) {
    renameSync(sourcePath, destinationPath)
  },
  mkdir(path) {
    mkdirSync(path, { recursive: true })
  },
  unlink(path) {
    unlinkSync(path)
  },
}

function formatIssues(issues: ConfigIssue[]): string {
  return issues.map(issue => `${issue.sourcePath}: ${issue.message}`).join('\n')
}

export class AutoReviewConfigStore {
  readonly agentDir: string
  private readonly fileSystem: AutoReviewConfigFileSystem

  constructor(options: AutoReviewConfigStoreOptions = {}) {
    this.agentDir = options.agentDir ?? defaultAutoReviewAgentDir()
    this.fileSystem = options.fileSystem ?? defaultFileSystem
  }

  getPaths(cwd: string): AutoReviewConfigPaths {
    return getAutoReviewConfigPaths(cwd, this.agentDir)
  }

  load(cwd: string): LoadConfigResult {
    return loadAutoReviewConfig({
      cwd,
      agentDir: this.agentDir,
      readFile: path => this.fileSystem.readFile(path),
    })
  }

  readScope(cwd: string, scope: AutoReviewConfigScope): AutoReviewScopeSnapshot {
    const paths = this.getPaths(cwd)
    const path = scope === 'global' ? paths.globalPath : paths.projectPath
    let source: string | undefined
    try {
      source = this.fileSystem.readFile(path)
    } catch (error) {
      return {
        scope,
        cwd,
        path,
        source: undefined,
        valid: false,
        issue: {
          sourcePath: path,
          message: error instanceof Error ? error.message : String(error),
        },
      }
    }

    if (source === undefined) {
      return { scope, cwd, path, source, valid: true, config: {} }
    }

    const parsed = parseAutoReviewConfigFile(source, path)
    if (!parsed.ok) {
      return { scope, cwd, path, source, valid: false, issue: parsed.issue }
    }
    return { scope, cwd, path, source, valid: true, config: parsed.config }
  }

  save(snapshot: AutoReviewScopeSnapshot, draft: AutoReviewConfigFile): ConfigMutationResult {
    if (!snapshot.valid) {
      return {
        ok: false,
        message: `Cannot save invalid config at '${snapshot.path}': ${snapshot.issue.message}`,
      }
    }

    const parsed = validateAutoReviewConfigFile(draft, snapshot.path)
    if (!parsed.ok) {
      return { ok: false, message: `${parsed.issue.sourcePath}: ${parsed.issue.message}` }
    }

    const source = this.serialize(parsed.config)
    const loadResult = this.loadWithOverride(snapshot, source)
    if (loadResult.config === undefined) {
      return { ok: false, message: formatIssues(loadResult.issues) }
    }

    const conflict = this.checkForConflict(snapshot)
    if (conflict !== undefined) {
      return { ok: false, message: conflict }
    }

    const tempPath = `${snapshot.path}.tmp`
    try {
      this.fileSystem.mkdir(dirname(snapshot.path))
      this.fileSystem.writeFile(tempPath, source)
      this.fileSystem.rename(tempPath, snapshot.path)
    } catch (error) {
      this.cleanupTempFile(tempPath)
      return {
        ok: false,
        message: `Failed to save config at '${snapshot.path}': ${error instanceof Error ? error.message : String(error)}`,
      }
    }

    return {
      ok: true,
      loadResult,
      snapshot: {
        scope: snapshot.scope,
        cwd: snapshot.cwd,
        path: snapshot.path,
        source,
        valid: true,
        config: parsed.config,
      },
    }
  }

  reset(snapshot: AutoReviewScopeSnapshot): ConfigMutationResult {
    if (!snapshot.valid && snapshot.source === undefined) {
      return {
        ok: false,
        message: `Cannot reset unreadable config at '${snapshot.path}': ${snapshot.issue.message}`,
      }
    }

    const conflict = this.checkForConflict(snapshot)
    if (conflict !== undefined) {
      return { ok: false, message: conflict }
    }

    if (snapshot.source !== undefined) {
      try {
        this.fileSystem.unlink(snapshot.path)
      } catch (error) {
        return {
          ok: false,
          message: `Failed to reset config at '${snapshot.path}': ${error instanceof Error ? error.message : String(error)}`,
        }
      }
    }

    const loadResult = this.loadWithOverride(snapshot, undefined)
    return {
      ok: true,
      loadResult,
      snapshot: {
        scope: snapshot.scope,
        cwd: snapshot.cwd,
        path: snapshot.path,
        source: undefined,
        valid: true,
        config: {},
      },
    }
  }

  private loadWithOverride(snapshot: AutoReviewScopeSnapshot, source: string | undefined): LoadConfigResult {
    return loadAutoReviewConfig({
      cwd: snapshot.cwd,
      agentDir: this.agentDir,
      readFile: path => (path === snapshot.path ? source : this.fileSystem.readFile(path)),
    })
  }

  private serialize(config: AutoReviewConfigFile): string {
    const { $schema = CONFIG_SCHEMA_URL, ...fields } = config
    return `${JSON.stringify({ $schema, ...fields }, null, 2)}\n`
  }

  private checkForConflict(snapshot: AutoReviewScopeSnapshot): string | undefined {
    let currentSource: string | undefined
    try {
      currentSource = this.fileSystem.readFile(snapshot.path)
    } catch (error) {
      return `Failed to re-read config at '${snapshot.path}': ${error instanceof Error ? error.message : String(error)}`
    }
    return currentSource === snapshot.source
      ? undefined
      : `Config at '${snapshot.path}' changed while it was being edited; reopen the command and try again.`
  }

  private cleanupTempFile(tempPath: string): void {
    try {
      this.fileSystem.unlink(tempPath)
    } catch (error) {
      if (!isNodeError(error, 'ENOENT')) {
        // The original write error is more actionable than a best-effort cleanup failure.
      }
    }
  }
}
