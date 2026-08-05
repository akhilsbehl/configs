import { readFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'
import process from 'node:process'
import { z } from 'zod'

export const EXTENSION_ID = 'pi-permission-auto-review'
export const AUTHORIZER_NAME = 'auto-review'
export const DEFAULT_PROVIDER = 'openai-codex'
export const DEFAULT_MODEL = 'codex-auto-review'
export const DEFAULT_TIMEOUT_MS = 90_000
export const CONFIG_SCHEMA_URL =
  'https://raw.githubusercontent.com/mzwing/pi-packages/main/packages/pi-permission-auto-review/schemas/config.schema.json'

export const REASONING_LEVELS = ['off', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max'] as const

type AutoReviewConfigSchema = z.ZodObject<
  {
    $schema: z.ZodOptional<z.ZodString>
    additionalPolicy: z.ZodOptional<z.ZodString>
    provider: z.ZodDefault<z.ZodString>
    model: z.ZodDefault<z.ZodString>
    reasoning: z.ZodDefault<
      z.ZodEnum<{
        off: 'off'
        minimal: 'minimal'
        low: 'low'
        medium: 'medium'
        high: 'high'
        xhigh: 'xhigh'
        max: 'max'
      }>
    >
    timeoutMs: z.ZodDefault<z.ZodNumber>
    includeBaselinePolicy: z.ZodDefault<z.ZodBoolean>
  },
  z.core.$strict
>

const configFileShape = {
  $schema: z.string().min(1).optional(),
  provider: z.string().trim().min(1).optional(),
  model: z.string().trim().min(1).optional(),
  reasoning: z.enum(REASONING_LEVELS).optional(),
  timeoutMs: z.number().int().positive().max(300_000).optional(),
  includeBaselinePolicy: z.boolean().optional(),
  additionalPolicy: z.string().trim().min(1).optional(),
}

const autoReviewConfigFileSchema = z.strictObject(configFileShape)

export const autoReviewConfigSchema: AutoReviewConfigSchema = z
  .strictObject({
    ...configFileShape,
    provider: z.string().trim().min(1).default(DEFAULT_PROVIDER),
    model: z.string().trim().min(1).default(DEFAULT_MODEL),
    reasoning: z.enum(REASONING_LEVELS).default('low'),
    timeoutMs: z.number().int().positive().max(300_000).default(DEFAULT_TIMEOUT_MS),
    includeBaselinePolicy: z.boolean().default(true),
  })
  .superRefine((config, context) => {
    if (!config.includeBaselinePolicy && config.additionalPolicy === undefined) {
      context.addIssue({
        code: 'custom',
        message: 'additionalPolicy is required when includeBaselinePolicy is false',
        path: ['additionalPolicy'],
      })
    }
  })

export type AutoReviewConfig = z.infer<typeof autoReviewConfigSchema>

export interface AutoReviewConfigFile {
  $schema?: string | undefined
  provider?: string | undefined
  model?: string | undefined
  reasoning?: (typeof REASONING_LEVELS)[number] | undefined
  timeoutMs?: number | undefined
  includeBaselinePolicy?: boolean | undefined
  additionalPolicy?: string | undefined
}

export interface ConfigIssue {
  sourcePath: string
  message: string
}

export interface LoadConfigResult {
  config: AutoReviewConfig | undefined
  issues: ConfigIssue[]
  globalPath: string
  projectPath: string
}

export interface LoadConfigOptions {
  cwd: string
  agentDir?: string
  readFile?: (path: string) => string | undefined
}

export interface AutoReviewConfigPaths {
  globalPath: string
  projectPath: string
}

export type ParseAutoReviewConfigFileResult =
  | { ok: true; config: AutoReviewConfigFile }
  | { ok: false; issue: ConfigIssue }

export function defaultAutoReviewAgentDir(): string {
  return process.env['PI_CODING_AGENT_DIR'] ?? join(homedir(), '.pi', 'agent')
}

export function getAutoReviewConfigPaths(
  cwd: string,
  agentDir: string = defaultAutoReviewAgentDir(),
): AutoReviewConfigPaths {
  return {
    globalPath: join(agentDir, 'extensions', EXTENSION_ID, 'config.json'),
    projectPath: join(cwd, '.pi', 'extensions', EXTENSION_ID, 'config.json'),
  }
}

function defaultReadFile(path: string): string | undefined {
  try {
    return readFileSync(path, 'utf8')
  } catch (error) {
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
      return undefined
    }
    throw error
  }
}

function formatZodIssue(error: z.ZodError): string {
  return error.issues
    .map(issue => {
      const path = issue.path.length > 0 ? issue.path.join('.') : '(root)'
      return `${path}: ${issue.message}`
    })
    .join('; ')
}

export function validateAutoReviewConfigFile(value: unknown, sourcePath: string): ParseAutoReviewConfigFileResult {
  const parsed = autoReviewConfigFileSchema.safeParse(value)
  if (!parsed.success) {
    return {
      ok: false,
      issue: {
        sourcePath,
        message: formatZodIssue(parsed.error),
      },
    }
  }
  return { ok: true, config: parsed.data }
}

export function parseAutoReviewConfigFile(source: string, sourcePath: string): ParseAutoReviewConfigFileResult {
  let value: unknown
  try {
    value = JSON.parse(source)
  } catch (error) {
    return {
      ok: false,
      issue: {
        sourcePath,
        message: `invalid JSON: ${error instanceof Error ? error.message : String(error)}`,
      },
    }
  }
  return validateAutoReviewConfigFile(value, sourcePath)
}

function readScope(
  path: string,
  readFile: (path: string) => string | undefined,
  issues: ConfigIssue[],
): AutoReviewConfigFile | undefined {
  let source: string | undefined
  try {
    source = readFile(path)
  } catch (error) {
    issues.push({
      sourcePath: path,
      message: error instanceof Error ? error.message : String(error),
    })
    return undefined
  }

  if (source === undefined) {
    return {}
  }

  const parsed = parseAutoReviewConfigFile(source, path)
  if (!parsed.ok) {
    issues.push(parsed.issue)
    return undefined
  }
  return parsed.config
}

export function loadAutoReviewConfig(options: LoadConfigOptions): LoadConfigResult {
  const { globalPath, projectPath } = getAutoReviewConfigPaths(options.cwd, options.agentDir)
  const readFile = options.readFile ?? defaultReadFile
  const issues: ConfigIssue[] = []
  const globalConfig = readScope(globalPath, readFile, issues)
  const projectConfig = readScope(projectPath, readFile, issues)

  if (globalConfig === undefined || projectConfig === undefined) {
    return { config: undefined, issues, globalPath, projectPath }
  }

  const merged = autoReviewConfigSchema.safeParse({
    ...globalConfig,
    ...projectConfig,
  })
  if (!merged.success) {
    issues.push({
      sourcePath: projectPath,
      message: formatZodIssue(merged.error),
    })
    return { config: undefined, issues, globalPath, projectPath }
  }

  return {
    config: merged.data,
    issues,
    globalPath,
    projectPath,
  }
}

export function buildAutoReviewJsonSchema(): Record<string, unknown> {
  const { $schema, ...schema } = z.toJSONSchema(autoReviewConfigSchema, {
    target: 'draft-2020-12',
    io: 'input',
  })
  return {
    $schema,
    $id: CONFIG_SCHEMA_URL,
    ...schema,
    allOf: [
      {
        if: {
          properties: {
            includeBaselinePolicy: { const: false },
          },
          required: ['includeBaselinePolicy'],
        },
        then: {
          required: ['additionalPolicy'],
        },
      },
    ],
  }
}
