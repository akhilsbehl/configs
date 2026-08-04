import type { AutoReviewConfig } from './config.js'
import type { Api, Model, Provider } from '@earendil-works/pi-ai'
import type { ModelRegistry } from '@earendil-works/pi-coding-agent'
import { getModelRegistryProvider } from '@mzwing/pi-polyfill'
import { DEFAULT_MODEL, DEFAULT_PROVIDER } from './config.js'

export type ReviewModelRegistry = Pick<ModelRegistry, 'find' | 'getAll' | 'getApiKeyAndHeaders'> & {
  getProvider?: (providerId: string) => Provider | undefined
}

interface ResolvedReviewModel {
  model: Model<Api>
  provider: Provider<Api>
  synthesized: boolean
}

export type ResolveReviewModelResult =
  | { ok: true; value: ResolvedReviewModel }
  | {
      ok: false
      category: 'provider-unresolved' | 'model-unresolved'
    }

function findCodexTemplate(registry: ReviewModelRegistry, provider: Provider<Api>): Model<Api> | undefined {
  return (
    registry.getAll().find(model => model.provider === DEFAULT_PROVIDER && model.api === 'openai-codex-responses') ??
    provider.getModels().find(model => model.api === 'openai-codex-responses')
  )
}

export function resolveReviewModel(registry: ReviewModelRegistry, config: AutoReviewConfig): ResolveReviewModelResult {
  const provider =
    typeof registry.getProvider === 'function'
      ? registry.getProvider(config.provider)
      : getModelRegistryProvider(registry as ModelRegistry, config.provider)
  if (provider === undefined) {
    return { ok: false, category: 'provider-unresolved' }
  }

  const registeredModel = registry.find(config.provider, config.model)
  if (registeredModel !== undefined) {
    return {
      ok: true,
      value: { model: registeredModel, provider, synthesized: false },
    }
  }

  if (config.provider !== DEFAULT_PROVIDER || config.model !== DEFAULT_MODEL) {
    return { ok: false, category: 'model-unresolved' }
  }

  const template = findCodexTemplate(registry, provider)
  if (template === undefined) {
    return { ok: false, category: 'model-unresolved' }
  }

  return {
    ok: true,
    value: {
      model: {
        ...template,
        id: DEFAULT_MODEL,
        name: 'Codex Auto Review',
        reasoning: true,
        input: ['text'],
      },
      provider,
      synthesized: true,
    },
  }
}
