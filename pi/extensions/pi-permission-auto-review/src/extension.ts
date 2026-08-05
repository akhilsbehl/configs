import type { AutoReviewActivationResult } from './command.js'
import type { AutoReviewConfig, LoadConfigResult } from './config.js'
import type { ExtensionAPI, ModelRegistry, SessionManager } from '@earendil-works/pi-coding-agent'
import type { Authorizer, PermissionsService } from '@gotgenes/pi-permission-system'
import {
  getPermissionsService as getPublishedPermissionsService,
  PERMISSIONS_READY_CHANNEL,
} from '@gotgenes/pi-permission-system'
import { DenialCircuitBreaker } from './circuit-breaker.js'
import { registerAutoReviewCommand } from './command.js'
import { AutoReviewConfigStore } from './config-store.js'
import { AUTHORIZER_NAME, EXTENSION_ID } from './config.js'
import { createPermissionReviewer } from './reviewer.js'

interface ReviewerFactoryOptions {
  config: AutoReviewConfig
  registry: ModelRegistry
  sessionManager: Pick<SessionManager, 'buildContextEntries'>
  circuitBreaker: DenialCircuitBreaker
  sessionSignal: AbortSignal
}

export interface AutoReviewExtensionDependencies {
  loadConfig?: (cwd: string) => LoadConfigResult
  getPermissionsService?: () => PermissionsService | undefined
  createReviewer?: (options: ReviewerFactoryOptions) => Authorizer['authorize']
}

interface ReviewerGeneration {
  config: AutoReviewConfig | undefined
  controller: AbortController
  authorize: Authorizer['authorize']
  dispose: (() => void) | undefined
}

interface SessionRuntime {
  registry: ModelRegistry
  sessionManager: Pick<SessionManager, 'buildContextEntries'>
}

interface RegistrationOwnership {
  service: PermissionsService
  ownerToken: symbol
}

type RegistrationRole = 'pending' | 'owner' | 'passive'

// Pi loads extensions through isolated module graphs, while subagents still
// share one process-global PermissionsService. Symbol.for keeps ownership
// visible across those module boundaries without involving child lifetimes.
const REGISTRATION_OWNERSHIP_KEY = Symbol.for('@mzwing/pi-permission-auto-review:registration')
const PASSIVE_CONFIG_MESSAGE =
  'the auto-review authorizer is managed by the main Pi session; change its configuration there'

function getRegistrationOwnership(): RegistrationOwnership | undefined {
  return (globalThis as Record<symbol, unknown>)[REGISTRATION_OWNERSHIP_KEY] as RegistrationOwnership | undefined
}

function setRegistrationOwnership(ownership: RegistrationOwnership): void {
  const processGlobals = globalThis as Record<symbol, unknown>
  processGlobals[REGISTRATION_OWNERSHIP_KEY] = ownership
}

function clearRegistrationOwnership(service: PermissionsService, ownerToken: symbol): void {
  const ownership = getRegistrationOwnership()
  if (ownership?.service !== service || ownership.ownerToken !== ownerToken) {
    return
  }
  delete (globalThis as Record<symbol, unknown>)[REGISTRATION_OWNERSHIP_KEY]
}

function warn(message: string): void {
  console.warn(`[${EXTENSION_ID}] ${message}`)
}

function installAutoReviewExtension(
  pi: ExtensionAPI,
  configStore: AutoReviewConfigStore,
  dependencies: AutoReviewExtensionDependencies,
): void {
  const loadConfig = dependencies.loadConfig ?? ((cwd: string) => configStore.load(cwd))
  const getPermissionsService = dependencies.getPermissionsService ?? getPublishedPermissionsService
  const createReviewer =
    dependencies.createReviewer ??
    ((options: ReviewerFactoryOptions) =>
      createPermissionReviewer({
        ...options,
      }))

  const circuitBreaker = new DenialCircuitBreaker()
  const ownerToken = Symbol(EXTENSION_ID)
  let sessionRuntime: SessionRuntime | undefined
  let generation: ReviewerGeneration | undefined
  let registrationRole: RegistrationRole = 'pending'
  let ownedService: PermissionsService | undefined

  function createInvalidConfigReviewer(): Authorizer['authorize'] {
    return async (details, _query, log) => {
      log.review('auto_review.decision', {
        requestId: details.requestId,
        outcome: 'defer',
        errorCategory: 'config-invalid',
      })
      return { kind: 'defer' }
    }
  }

  function createGeneration(config: AutoReviewConfig | undefined): ReviewerGeneration | undefined {
    if (sessionRuntime === undefined) {
      return undefined
    }
    const controller = new AbortController()
    try {
      const authorize =
        config === undefined
          ? createInvalidConfigReviewer()
          : createReviewer({
              config,
              registry: sessionRuntime.registry,
              sessionManager: sessionRuntime.sessionManager,
              circuitBreaker,
              sessionSignal: controller.signal,
            })
      return {
        config,
        controller,
        authorize,
        dispose: undefined,
      }
    } catch (error) {
      controller.abort()
      throw error
    }
  }

  function ownsRegistration(service: PermissionsService): boolean {
    const ownership = getRegistrationOwnership()
    return ownership?.service === service && ownership.ownerToken === ownerToken
  }

  function claimRegistration(service: PermissionsService): void {
    setRegistrationOwnership({ service, ownerToken })
    ownedService = service
    registrationRole = 'owner'
  }

  function releaseRegistration(): void {
    if (ownedService !== undefined) {
      clearRegistrationOwnership(ownedService, ownerToken)
    }
    ownedService = undefined
    registrationRole = 'pending'
  }

  function cleanupGeneration(target: ReviewerGeneration | undefined): void {
    try {
      // Passive generations never receive a disposer. A stale owner may now
      // be passive for a replacement service, but must still release its own
      // old-service registration.
      target?.dispose?.()
    } finally {
      if (target !== undefined) {
        target.dispose = undefined
        target.controller.abort()
      }
      releaseRegistration()
    }
  }

  function tryRegister(): void {
    if (generation === undefined || generation.dispose !== undefined || registrationRole === 'passive') {
      return
    }
    const service = getPermissionsService()
    if (service === undefined) {
      return
    }

    const ownership = getRegistrationOwnership()
    if (ownership?.service === service) {
      if (ownership.ownerToken === ownerToken) {
        registrationRole = 'owner'
        ownedService = service
      } else {
        registrationRole = 'passive'
      }
      return
    }

    try {
      generation.dispose = service.registerAuthorizer(AUTHORIZER_NAME, generation.authorize)
      claimRegistration(service)
    } catch (error) {
      warn(`failed to register ${AUTHORIZER_NAME}: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  function reportIssues(result: LoadConfigResult): void {
    for (const issue of result.issues) {
      warn(`config issue at ${issue.sourcePath}: ${issue.message}`)
    }
  }

  function applyConfig(result: LoadConfigResult): AutoReviewActivationResult {
    reportIssues(result)
    const current = generation
    if (current === undefined || sessionRuntime === undefined) {
      return { kind: 'failed', message: 'the Pi session has not started' }
    }
    if (registrationRole === 'passive') {
      return { kind: 'failed', message: PASSIVE_CONFIG_MESSAGE }
    }
    if (result.config === undefined) {
      return {
        kind: 'failed',
        message: 'the merged config is invalid; the previous reviewer remains active',
      }
    }

    const service = getPermissionsService()
    const ownership = service === undefined ? undefined : getRegistrationOwnership()
    if (service !== undefined && ownership?.service === service && ownership.ownerToken !== ownerToken) {
      registrationRole = 'passive'
      return { kind: 'failed', message: PASSIVE_CONFIG_MESSAGE }
    }
    if (registrationRole === 'owner' && service !== undefined && !ownsRegistration(service)) {
      return { kind: 'failed', message: PASSIVE_CONFIG_MESSAGE }
    }

    let candidate: ReviewerGeneration | undefined
    try {
      candidate = createGeneration(result.config)
    } catch (error) {
      return {
        kind: 'failed',
        message: `failed to create the new reviewer: ${error instanceof Error ? error.message : String(error)}`,
      }
    }
    if (candidate === undefined) {
      return { kind: 'failed', message: 'the Pi session has not started' }
    }

    if (service === undefined) {
      if (current.dispose !== undefined) {
        candidate.controller.abort()
        return {
          kind: 'failed',
          message: 'pi-permission-system became unavailable while the old reviewer was still registered',
        }
      }
      generation = candidate
      current.controller.abort()
      circuitBreaker.resetTurn()
      return { kind: 'pending' }
    }

    if (current.dispose !== undefined) {
      try {
        current.dispose()
        current.dispose = undefined
      } catch (error) {
        candidate.controller.abort()
        return {
          kind: 'failed',
          message: `failed to unregister the old reviewer: ${error instanceof Error ? error.message : String(error)}`,
        }
      }
    }

    try {
      candidate.dispose = service.registerAuthorizer(AUTHORIZER_NAME, candidate.authorize)
      claimRegistration(service)
    } catch (error) {
      candidate.controller.abort()
      const registrationMessage = error instanceof Error ? error.message : String(error)
      try {
        current.dispose = service.registerAuthorizer(AUTHORIZER_NAME, current.authorize)
        claimRegistration(service)
      } catch (restoreError) {
        releaseRegistration()
        return {
          kind: 'failed',
          message: `new reviewer registration failed (${registrationMessage}) and the old reviewer could not be restored (${restoreError instanceof Error ? restoreError.message : String(restoreError)})`,
        }
      }
      return {
        kind: 'failed',
        message: `new reviewer registration failed and the old reviewer was restored: ${registrationMessage}`,
      }
    }

    generation = candidate
    current.controller.abort()
    circuitBreaker.resetTurn()
    return { kind: 'active' }
  }

  pi.on('session_start', (_event, context) => {
    cleanupGeneration(generation)
    circuitBreaker.resetTurn()

    const result = loadConfig(context.cwd)
    sessionRuntime = {
      registry: context.modelRegistry,
      sessionManager: context.sessionManager,
    }
    generation = createGeneration(result.config)
    reportIssues(result)
    tryRegister()
  })

  pi.events.on(PERMISSIONS_READY_CHANNEL, () => {
    tryRegister()
  })

  pi.on('turn_start', () => {
    circuitBreaker.resetTurn()
  })

  pi.on('session_shutdown', () => {
    cleanupGeneration(generation)
    generation = undefined
    sessionRuntime = undefined
    circuitBreaker.resetTurn()
  })

  registerAutoReviewCommand(pi, {
    configStore,
    getActiveConfig: () => generation?.config,
    applyConfig,
  })
}

export function createAutoReviewExtension(pi: ExtensionAPI, dependencies: AutoReviewExtensionDependencies = {}): void {
  installAutoReviewExtension(pi, new AutoReviewConfigStore(), dependencies)
}

export function createAutoReviewExtensionWithConfigStore(
  pi: ExtensionAPI,
  configStore: AutoReviewConfigStore,
  dependencies: AutoReviewExtensionDependencies = {},
): void {
  installAutoReviewExtension(pi, configStore, dependencies)
}
