import type { AutoReviewConfigStore, AutoReviewConfigScope, AutoReviewScopeSnapshot } from './config-store.js'
import type { AutoReviewConfig, AutoReviewConfigFile, LoadConfigResult } from './config.js'
import type { ExtensionAPI, ExtensionCommandContext, ModelRegistry } from '@earendil-works/pi-coding-agent'
import { DEFAULT_MODEL, DEFAULT_PROVIDER, REASONING_LEVELS, autoReviewConfigSchema } from './config.js'

const COMMAND_NAME = 'permission-auto-review'
const USAGE = 'Usage: /permission-auto-review [show|path|reset [global|project]|help]'
const INHERIT = 'Use inherited value'
const CUSTOM = 'Enter custom value...'
const SAVE = 'Save changes'
const CANCEL = 'Cancel'
const WHITESPACE = /\s+/
const DEFAULT_CONFIG = autoReviewConfigSchema.parse({})

const configFields = [
  'provider',
  'model',
  'reasoning',
  'timeoutMs',
  'includeBaselinePolicy',
  'additionalPolicy',
] as const

type ConfigField = (typeof configFields)[number]

const fieldLabels: Record<ConfigField, string> = {
  provider: 'Provider',
  model: 'Model',
  reasoning: 'Reasoning',
  timeoutMs: 'Timeout',
  includeBaselinePolicy: 'Baseline policy',
  additionalPolicy: 'Additional policy',
}

export type AutoReviewActivationResult = { kind: 'active' } | { kind: 'pending' } | { kind: 'failed'; message: string }

export interface AutoReviewCommandController {
  configStore: AutoReviewConfigStore
  getActiveConfig: () => AutoReviewConfig | undefined
  applyConfig: (result: LoadConfigResult) => AutoReviewActivationResult
}

interface ConfigLayers {
  global: AutoReviewConfigFile
  project: AutoReviewConfigFile
}

interface ConfigView {
  config: AutoReviewConfig
  layers: ConfigLayers
}

function hasField(config: AutoReviewConfigFile, field: ConfigField): boolean {
  return Object.hasOwn(config, field)
}

function fieldValue(config: AutoReviewConfigFile | AutoReviewConfig, field: ConfigField): unknown {
  return config[field]
}

function resolveView(layers: ConfigLayers): ConfigView {
  const merged = autoReviewConfigSchema.safeParse({
    ...layers.global,
    ...layers.project,
  })
  const additionalPolicy =
    layers.project.additionalPolicy ?? layers.global.additionalPolicy ?? DEFAULT_CONFIG.additionalPolicy
  const fallback: AutoReviewConfig = {
    provider: layers.project.provider ?? layers.global.provider ?? DEFAULT_CONFIG.provider,
    model: layers.project.model ?? layers.global.model ?? DEFAULT_CONFIG.model,
    reasoning: layers.project.reasoning ?? layers.global.reasoning ?? DEFAULT_CONFIG.reasoning,
    timeoutMs: layers.project.timeoutMs ?? layers.global.timeoutMs ?? DEFAULT_CONFIG.timeoutMs,
    includeBaselinePolicy:
      layers.project.includeBaselinePolicy ??
      layers.global.includeBaselinePolicy ??
      DEFAULT_CONFIG.includeBaselinePolicy,
    ...(additionalPolicy === undefined ? {} : { additionalPolicy }),
  }
  return {
    config: merged.success ? merged.data : fallback,
    layers,
  }
}

function resolveOrigin(layers: ConfigLayers, field: ConfigField): AutoReviewConfigScope | 'default' {
  if (hasField(layers.project, field)) {
    return 'project'
  }
  if (hasField(layers.global, field)) {
    return 'global'
  }
  return 'default'
}

function formatFieldValue(field: ConfigField, value: unknown): string {
  if (field === 'additionalPolicy') {
    return typeof value === 'string' && value.length > 0 ? 'configured' : 'not set'
  }
  if (field === 'timeoutMs' && typeof value === 'number') {
    return `${value} ms`
  }
  return String(value ?? 'not set')
}

function buildLayers(
  selected: AutoReviewScopeSnapshot,
  other: AutoReviewScopeSnapshot,
  draft: AutoReviewConfigFile,
): ConfigLayers | undefined {
  if (!selected.valid || !other.valid) {
    return undefined
  }
  if (selected.scope === 'global') {
    return { global: draft, project: other.config }
  }
  return { global: other.config, project: draft }
}

function removeField(config: AutoReviewConfigFile, field: ConfigField): AutoReviewConfigFile {
  const next = { ...config }
  switch (field) {
    case 'provider':
      delete next.provider
      break
    case 'model':
      delete next.model
      break
    case 'reasoning':
      delete next.reasoning
      break
    case 'timeoutMs':
      delete next.timeoutMs
      break
    case 'includeBaselinePolicy':
      delete next.includeBaselinePolicy
      break
    case 'additionalPolicy':
      delete next.additionalPolicy
      break
  }
  return next
}

function setField(
  config: AutoReviewConfigFile,
  field: ConfigField,
  value: string | number | boolean,
): AutoReviewConfigFile {
  switch (field) {
    case 'provider':
      return { ...config, provider: String(value) }
    case 'model':
      return { ...config, model: String(value) }
    case 'reasoning':
      return {
        ...config,
        reasoning: REASONING_LEVELS.find(level => level === value),
      }
    case 'timeoutMs':
      return { ...config, timeoutMs: Number(value) }
    case 'includeBaselinePolicy':
      return { ...config, includeBaselinePolicy: Boolean(value) }
    case 'additionalPolicy':
      return { ...config, additionalPolicy: String(value) }
  }
}

function uniqueSorted(values: string[]): string[] {
  return [...new Set(values)].toSorted((left, right) => left.localeCompare(right))
}

async function chooseStringValue(
  ctx: ExtensionCommandContext,
  title: string,
  knownValues: string[],
  currentValue: string,
): Promise<{ kind: 'inherit' } | { kind: 'value'; value: string } | undefined> {
  const values = uniqueSorted([...knownValues, currentValue])
  const valueOptions = values.map(value => `Value: ${value}`)
  const selected = await ctx.ui.select(title, [INHERIT, ...valueOptions, CUSTOM])
  if (selected === undefined) {
    return undefined
  }
  if (selected === INHERIT) {
    return { kind: 'inherit' }
  }
  if (selected === CUSTOM) {
    const custom = await ctx.ui.input(title, currentValue)
    const normalized = custom?.trim()
    if (normalized === undefined || normalized.length === 0) {
      return undefined
    }
    return { kind: 'value', value: normalized }
  }
  const index = valueOptions.indexOf(selected)
  return index < 0 ? undefined : { kind: 'value', value: values[index] ?? currentValue }
}

async function editStringField(
  ctx: ExtensionCommandContext,
  draft: AutoReviewConfigFile,
  field: 'provider' | 'model',
  view: ConfigView,
  registry: ModelRegistry,
): Promise<AutoReviewConfigFile> {
  const currentValue = String(fieldValue(view.config, field))
  const effectiveProvider = String(fieldValue(view.config, 'provider'))
  const knownValues =
    field === 'provider'
      ? registry.getAll().map(model => model.provider)
      : registry
          .getAll()
          .filter(model => model.provider === effectiveProvider)
          .map(model => model.id)
  if (field === 'provider') {
    knownValues.push(DEFAULT_PROVIDER)
  } else if (effectiveProvider === DEFAULT_PROVIDER) {
    knownValues.push(DEFAULT_MODEL)
  }

  const selected = await chooseStringValue(ctx, `Configure ${fieldLabels[field]}`, knownValues, currentValue)
  if (selected === undefined) {
    return draft
  }
  return selected.kind === 'inherit' ? removeField(draft, field) : setField(draft, field, selected.value)
}

async function editReasoning(ctx: ExtensionCommandContext, draft: AutoReviewConfigFile): Promise<AutoReviewConfigFile> {
  const selected = await ctx.ui.select('Configure Reasoning', [INHERIT, ...REASONING_LEVELS])
  if (selected === INHERIT) {
    return removeField(draft, 'reasoning')
  }
  const reasoning = REASONING_LEVELS.find(level => level === selected)
  return reasoning === undefined ? draft : setField(draft, 'reasoning', reasoning)
}

async function editTimeout(
  ctx: ExtensionCommandContext,
  draft: AutoReviewConfigFile,
  currentValue: number,
): Promise<AutoReviewConfigFile> {
  const action = await ctx.ui.select('Configure Timeout', [INHERIT, 'Enter timeout...'])
  if (action === INHERIT) {
    return removeField(draft, 'timeoutMs')
  }
  if (action !== 'Enter timeout...') {
    return draft
  }

  const source = await ctx.ui.input('Timeout in milliseconds', String(currentValue))
  if (source === undefined) {
    return draft
  }
  const value = Number(source.trim())
  if (!Number.isInteger(value) || value < 1 || value > 300_000) {
    ctx.ui.notify('timeoutMs must be an integer between 1 and 300000.', 'warning')
    return draft
  }
  return setField(draft, 'timeoutMs', value)
}

async function editBaselinePolicy(
  ctx: ExtensionCommandContext,
  draft: AutoReviewConfigFile,
): Promise<AutoReviewConfigFile> {
  const selected = await ctx.ui.select('Configure Baseline Policy', [INHERIT, 'Enabled', 'Disabled'])
  if (selected === INHERIT) {
    return removeField(draft, 'includeBaselinePolicy')
  }
  if (selected === 'Enabled') {
    return setField(draft, 'includeBaselinePolicy', true)
  }
  if (selected === 'Disabled') {
    return setField(draft, 'includeBaselinePolicy', false)
  }
  return draft
}

async function editAdditionalPolicy(
  ctx: ExtensionCommandContext,
  draft: AutoReviewConfigFile,
  currentValue: string | undefined,
): Promise<AutoReviewConfigFile> {
  const selected = await ctx.ui.select('Configure Additional Policy', ['Edit policy...', INHERIT])
  if (selected === INHERIT) {
    return removeField(draft, 'additionalPolicy')
  }
  if (selected !== 'Edit policy...') {
    return draft
  }
  const value = await ctx.ui.editor('Additional review policy', currentValue ?? '')
  if (value === undefined) {
    return draft
  }
  const normalized = value.trim()
  return normalized.length === 0
    ? removeField(draft, 'additionalPolicy')
    : setField(draft, 'additionalPolicy', normalized)
}

function formatMenuOptions(view: ConfigView, scope: AutoReviewConfigScope): string[] {
  return configFields.map(field => {
    const value = fieldValue(view.config, field)
    const origin = resolveOrigin(view.layers, field)
    const scopeState = hasField(view.layers[scope], field) ? 'override' : 'inherit'
    return `${fieldLabels[field]}: ${formatFieldValue(field, value)} (source: ${origin}; ${scope}: ${scopeState})`
  })
}

async function chooseScope(ctx: ExtensionCommandContext, title: string): Promise<AutoReviewConfigScope | undefined> {
  const selected = await ctx.ui.select(title, ['Global configuration', 'Project configuration'])
  if (selected === 'Global configuration') {
    return 'global'
  }
  if (selected === 'Project configuration') {
    return 'project'
  }
  return undefined
}

async function openSettingsMenu(ctx: ExtensionCommandContext, controller: AutoReviewCommandController): Promise<void> {
  if (ctx.mode !== 'tui') {
    ctx.ui.notify(`/${COMMAND_NAME} requires interactive TUI mode.`, 'warning')
    return
  }

  await ctx.waitForIdle()
  const scope = await chooseScope(ctx, 'Select configuration scope')
  if (scope === undefined) {
    return
  }

  const selected = controller.configStore.readScope(ctx.cwd, scope)
  const other = controller.configStore.readScope(ctx.cwd, scope === 'global' ? 'project' : 'global')
  if (!selected.valid) {
    ctx.ui.notify(
      `Cannot edit config at '${selected.path}': ${selected.issue.message}. Use reset to remove it or fix it manually.`,
      'error',
    )
    return
  }
  if (!other.valid) {
    ctx.ui.notify(
      `Cannot edit config at '${other.path}': ${other.issue.message}. Use reset to remove it or fix it manually.`,
      'error',
    )
    return
  }

  let draft: AutoReviewConfigFile = { ...selected.config }
  while (true) {
    const layers = buildLayers(selected, other, draft)
    if (layers === undefined) {
      return
    }
    const view = resolveView(layers)
    const fieldOptions = formatMenuOptions(view, scope)
    const selectedOption = await ctx.ui.select(`Permission auto-review settings (${scope})`, [
      ...fieldOptions,
      SAVE,
      CANCEL,
    ])
    if (selectedOption === undefined || selectedOption === CANCEL) {
      return
    }
    if (selectedOption === SAVE) {
      const saved = controller.configStore.save(selected, draft)
      if (!saved.ok) {
        ctx.ui.notify(saved.message, 'error')
        continue
      }
      const activation = controller.applyConfig(saved.loadResult)
      if (activation.kind === 'failed') {
        ctx.ui.notify(`Config saved, but the current reviewer could not be replaced: ${activation.message}`, 'error')
      } else if (activation.kind === 'pending') {
        ctx.ui.notify('Config saved. It will become active when pi-permission-system is ready.', 'warning')
      } else {
        ctx.ui.notify('Config saved and applied without reloading the Pi session.', 'info')
      }
      return
    }

    const fieldIndex = fieldOptions.indexOf(selectedOption)
    const field = configFields[fieldIndex]
    if (field === undefined) {
      continue
    }
    switch (field) {
      case 'provider':
      case 'model':
        draft = await editStringField(ctx, draft, field, view, ctx.modelRegistry)
        break
      case 'reasoning':
        draft = await editReasoning(ctx, draft)
        break
      case 'timeoutMs':
        draft = await editTimeout(ctx, draft, view.config.timeoutMs)
        break
      case 'includeBaselinePolicy':
        draft = await editBaselinePolicy(ctx, draft)
        break
      case 'additionalPolicy':
        draft = await editAdditionalPolicy(ctx, draft, view.config.additionalPolicy)
        break
    }
  }
}

function getScopeLayers(store: AutoReviewConfigStore, cwd: string): ConfigLayers | undefined {
  const global = store.readScope(cwd, 'global')
  const project = store.readScope(cwd, 'project')
  return global.valid && project.valid ? { global: global.config, project: project.config } : undefined
}

function showConfig(ctx: ExtensionCommandContext, controller: AutoReviewCommandController): void {
  const paths = controller.configStore.getPaths(ctx.cwd)
  const active = controller.getActiveConfig()
  const layers = getScopeLayers(controller.configStore, ctx.cwd)
  if (active === undefined || layers === undefined) {
    const result = controller.configStore.load(ctx.cwd)
    const issues = result.issues.map(issue => `${issue.sourcePath}: ${issue.message}`).join('\n')
    ctx.ui.notify(
      `Automatic review is disabled because the active config is invalid.${issues ? `\n${issues}` : ''}`,
      'warning',
    )
    return
  }

  const fields = configFields.map(field => {
    const origin = resolveOrigin(layers, field)
    return `${field}=${formatFieldValue(field, fieldValue(active, field))} (${origin})`
  })
  ctx.ui.notify(
    `permission-auto-review:\n${fields.join('\n')}\nglobal=${paths.globalPath}\nproject=${paths.projectPath}`,
    'info',
  )
}

function showPaths(ctx: ExtensionCommandContext, controller: AutoReviewCommandController): void {
  const paths = controller.configStore.getPaths(ctx.cwd)
  ctx.ui.notify(
    `permission-auto-review config paths:\nglobal=${paths.globalPath}\nproject=${paths.projectPath}`,
    'info',
  )
}

async function resetConfig(
  ctx: ExtensionCommandContext,
  controller: AutoReviewCommandController,
  requestedScope: string | undefined,
): Promise<void> {
  if (ctx.mode !== 'tui') {
    ctx.ui.notify(`/${COMMAND_NAME} reset requires interactive TUI mode.`, 'warning')
    return
  }
  await ctx.waitForIdle()

  let scope: AutoReviewConfigScope | undefined
  if (requestedScope === 'global' || requestedScope === 'project') {
    scope = requestedScope
  } else if (requestedScope === undefined) {
    scope = await chooseScope(ctx, 'Select configuration scope to reset')
  } else {
    ctx.ui.notify(USAGE, 'warning')
    return
  }
  if (scope === undefined) {
    return
  }

  const snapshot = controller.configStore.readScope(ctx.cwd, scope)
  const confirmed = await ctx.ui.confirm(
    `Reset ${scope} auto-review config?`,
    `Delete '${snapshot.path}' and immediately apply inherited values?`,
  )
  if (!confirmed) {
    return
  }

  const reset = controller.configStore.reset(snapshot)
  if (!reset.ok) {
    ctx.ui.notify(reset.message, 'error')
    return
  }
  const activation = controller.applyConfig(reset.loadResult)
  if (activation.kind === 'failed') {
    ctx.ui.notify(`Config reset, but the current reviewer could not be replaced: ${activation.message}`, 'error')
  } else if (activation.kind === 'pending') {
    ctx.ui.notify(
      `${scope} config reset. The inherited config will activate when pi-permission-system is ready.`,
      'warning',
    )
  } else if (reset.loadResult.config === undefined) {
    ctx.ui.notify(
      `${scope} config reset, but automatic review remains disabled because another config layer is invalid.`,
      'warning',
    )
  } else {
    ctx.ui.notify(`${scope} config reset and inherited values applied without reloading the Pi session.`, 'info')
  }
}

function getArgumentCompletions(
  argumentPrefix: string,
): Array<{ value: string; label: string; description: string }> | null {
  const normalized = argumentPrefix.trimStart().toLowerCase()
  const items = normalized.startsWith('reset ')
    ? [
        {
          value: 'reset global',
          label: 'Reset global config',
          description: 'Delete the global auto-review config',
        },
        {
          value: 'reset project',
          label: 'Reset project config',
          description: 'Delete the project auto-review config',
        },
      ]
    : [
        {
          value: 'show',
          label: 'Show active config',
          description: 'Display effective values and their origins',
        },
        {
          value: 'path',
          label: 'Show config paths',
          description: 'Display global and project config paths',
        },
        {
          value: 'reset',
          label: 'Reset config',
          description: 'Delete one config layer and apply inherited values',
        },
        {
          value: 'help',
          label: 'Show help',
          description: 'Display command usage',
        },
      ]
  const filtered = items.filter(item => item.value.startsWith(normalized))
  return filtered.length > 0 ? filtered : null
}

export function registerAutoReviewCommand(pi: ExtensionAPI, controller: AutoReviewCommandController): void {
  pi.registerCommand(COMMAND_NAME, {
    description: 'Configure pi-permission-auto-review without reloading the Pi session',
    getArgumentCompletions,
    handler: async (args, ctx) => {
      const normalized = args.trim().toLowerCase()
      if (!normalized) {
        await openSettingsMenu(ctx, controller)
        return
      }
      if (normalized === 'show') {
        showConfig(ctx, controller)
        return
      }
      if (normalized === 'path') {
        showPaths(ctx, controller)
        return
      }
      if (normalized === 'help') {
        ctx.ui.notify(USAGE, 'info')
        return
      }
      if (normalized === 'reset' || normalized.startsWith('reset ')) {
        const scope = normalized.split(WHITESPACE)[1]
        await resetConfig(ctx, controller, scope)
        return
      }
      ctx.ui.notify(USAGE, 'warning')
    },
  })
}
