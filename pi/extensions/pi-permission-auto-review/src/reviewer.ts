import type { DenialCircuitBreaker } from './circuit-breaker.js'
import type { AutoReviewConfig } from './config.js'
import type { ReviewModelRegistry } from './model.js'
import type { ReviewAssessment } from './verdict.js'
import type { AssistantMessage, Provider, SimpleStreamOptions } from '@earendil-works/pi-ai'
import type { SessionManager } from '@earendil-works/pi-coding-agent'
import type { Authorizer, AuthorizerLog, PromptPermissionDetails } from '@gotgenes/pi-permission-system'
import { resolveReviewModel } from './model.js'
import { buildReviewPrompt } from './prompt.js'
import { renderTranscript } from './transcript.js'
import { parseReviewAssessment } from './verdict.js'

const DEFAULT_MAX_ATTEMPTS = 3
const DEFAULT_RETRY_DELAYS_MS = [250, 1_000]
const MAX_OUTPUT_TOKENS = 1_000
const DECISION_EVENT = 'auto_review.decision'
const FAILURE_EVENT = 'auto_review.failure'
const CIRCUIT_OPEN_EVENT = 'auto_review.circuit_open'

type FailureCategory =
  | 'provider-unresolved'
  | 'model-unresolved'
  | 'auth-unresolved'
  | 'provider-error'
  | 'invalid-response'
  | 'timeout'
  | 'cancelled'
  | 'internal-error'

export interface ReviewerRuntime {
  config: AutoReviewConfig
  registry: ReviewModelRegistry
  sessionManager: Pick<SessionManager, 'buildContextEntries'>
  circuitBreaker: DenialCircuitBreaker
  sessionSignal?: AbortSignal
}

export interface ReviewerDependencies {
  now?: () => number
  sleep?: (milliseconds: number, signal: AbortSignal) => Promise<void>
  maxAttempts?: number
  retryDelaysMs?: number[]
}

interface Failure {
  category: FailureCategory
}

interface ReviewCallResult {
  assessment: ReviewAssessment
}

function abortError(): Error {
  const error = new Error('operation aborted')
  error.name = 'AbortError'
  return error
}

async function defaultSleep(milliseconds: number, signal: AbortSignal): Promise<void> {
  if (milliseconds <= 0) {
    return Promise.resolve()
  }
  return new Promise((resolve, reject) => {
    if (signal.aborted) {
      reject(abortError())
      return
    }
    const timer = setTimeout(resolve, milliseconds)
    signal.addEventListener(
      'abort',
      () => {
        clearTimeout(timer)
        reject(abortError())
      },
      { once: true },
    )
  })
}

async function raceWithSignal<T>(promise: Promise<T>, signal: AbortSignal): Promise<T> {
  if (signal.aborted) {
    return Promise.reject(abortError())
  }
  return new Promise((resolve, reject) => {
    const onAbort = (): void => reject(abortError())
    signal.addEventListener('abort', onAbort, { once: true })
    promise.then(
      value => {
        signal.removeEventListener('abort', onAbort)
        resolve(value)
      },
      (error: unknown) => {
        signal.removeEventListener('abort', onAbort)
        reject(error)
      },
    )
  })
}

function responseText(message: AssistantMessage): string {
  return message.content
    .filter((block): block is Extract<(typeof message.content)[number], { type: 'text' }> => block.type === 'text')
    .map(block => block.text)
    .join('')
    .trim()
}

function buildStreamOptions(
  runtime: ReviewerRuntime,
  signal: AbortSignal,
  timeoutMs: number,
  auth: {
    apiKey?: string
    headers?: Record<string, string>
    env?: Record<string, string>
  },
  reasoning: boolean,
): SimpleStreamOptions {
  const options: SimpleStreamOptions = {
    maxRetries: 0,
    maxTokens: MAX_OUTPUT_TOKENS,
    signal,
    timeoutMs,
  }
  if (auth.apiKey !== undefined) {
    options.apiKey = auth.apiKey
  }
  if (auth.headers !== undefined) {
    options.headers = auth.headers
  }
  if (auth.env !== undefined) {
    options.env = auth.env
  }
  if (reasoning && runtime.config.reasoning !== 'off') {
    options.reasoning = runtime.config.reasoning
  }
  return options
}

async function callProvider(
  provider: Provider,
  model: Parameters<Provider['streamSimple']>[0],
  systemPrompt: string,
  userPrompt: string,
  options: SimpleStreamOptions,
): Promise<AssistantMessage> {
  const stream = provider.streamSimple(
    model,
    {
      systemPrompt,
      messages: [
        {
          role: 'user',
          content: userPrompt,
          timestamp: Date.now(),
        },
      ],
    },
    options,
  )
  return stream.result()
}

function writeFailure(
  log: AuthorizerLog,
  runtime: ReviewerRuntime,
  details: PromptPermissionDetails,
  failure: Failure,
  durationMs: number,
): void {
  const common = {
    requestId: details.requestId,
    provider: runtime.config.provider,
    model: runtime.config.model,
    outcome: 'defer',
    errorCategory: failure.category,
    durationMs,
  }
  log.review(DECISION_EVENT, common)
  log.debug(FAILURE_EVENT, common)
}

function tryWriteFailure(
  log: AuthorizerLog,
  runtime: ReviewerRuntime,
  details: PromptPermissionDetails,
  failure: Failure,
  durationMs: number,
): void {
  try {
    writeFailure(log, runtime, details, failure, durationMs)
  } catch {
    // Permission review failures must not escape into the fail-closed tool boundary.
  }
}

function elapsedMilliseconds(now: () => number, startedAt: number): number {
  try {
    return Math.max(0, now() - startedAt)
  } catch {
    return 0
  }
}

async function runReview(
  runtime: ReviewerRuntime,
  details: PromptPermissionDetails,
  dependencies: Required<Pick<ReviewerDependencies, 'now' | 'sleep' | 'maxAttempts' | 'retryDelaysMs'>>,
): Promise<ReviewCallResult | Failure> {
  const startedAt = dependencies.now()
  const timeoutController = new AbortController()
  const timeout = setTimeout(() => timeoutController.abort(), runtime.config.timeoutMs)
  const signal =
    runtime.sessionSignal === undefined
      ? timeoutController.signal
      : AbortSignal.any([timeoutController.signal, runtime.sessionSignal])

  try {
    const resolved = resolveReviewModel(runtime.registry, runtime.config)
    if (!resolved.ok) {
      return { category: resolved.category }
    }

    let auth
    try {
      auth = await raceWithSignal(runtime.registry.getApiKeyAndHeaders(resolved.value.model), signal)
    } catch {
      if (signal.aborted) {
        return {
          category: timeoutController.signal.aborted ? 'timeout' : 'cancelled',
        }
      }
      return { category: 'auth-unresolved' }
    }
    if (!auth.ok) {
      return { category: 'auth-unresolved' }
    }

    const transcript = renderTranscript(runtime.sessionManager.buildContextEntries())
    const prompt = buildReviewPrompt(runtime.config, transcript, details)

    for (let attempt = 1; attempt <= dependencies.maxAttempts; attempt += 1) {
      try {
        const remainingMs = Math.max(1, runtime.config.timeoutMs - (dependencies.now() - startedAt))
        const message = await raceWithSignal(
          callProvider(
            resolved.value.provider,
            resolved.value.model,
            prompt.systemPrompt,
            prompt.userPrompt,
            buildStreamOptions(runtime, signal, remainingMs, auth, resolved.value.model.reasoning),
          ),
          signal,
        )

        if (message.stopReason === 'error' || message.stopReason === 'aborted') {
          throw new Error(message.errorMessage ?? message.stopReason)
        }

        try {
          return {
            assessment: parseReviewAssessment(responseText(message)),
          }
        } catch {
          return { category: 'invalid-response' }
        }
      } catch {
        if (signal.aborted) {
          return {
            category: timeoutController.signal.aborted ? 'timeout' : 'cancelled',
          }
        }
        if (attempt >= dependencies.maxAttempts) {
          return { category: 'provider-error' }
        }
        const delay = dependencies.retryDelaysMs[attempt - 1] ?? dependencies.retryDelaysMs.at(-1) ?? 0
        try {
          await dependencies.sleep(delay, signal)
        } catch {
          return {
            category: timeoutController.signal.aborted ? 'timeout' : 'cancelled',
          }
        }
      }
    }
    return { category: 'provider-error' }
  } finally {
    clearTimeout(timeout)
  }
}

export function createPermissionReviewer(
  runtime: ReviewerRuntime,
  reviewerDependencies: ReviewerDependencies = {},
): Authorizer['authorize'] {
  const dependencies = {
    now: reviewerDependencies.now ?? Date.now,
    sleep: reviewerDependencies.sleep ?? defaultSleep,
    maxAttempts: reviewerDependencies.maxAttempts ?? DEFAULT_MAX_ATTEMPTS,
    retryDelaysMs: reviewerDependencies.retryDelaysMs ?? DEFAULT_RETRY_DELAYS_MS,
  }

  return async (details, _query, log) => {
    let startedAt = 0
    try {
      startedAt = dependencies.now()
      if (runtime.circuitBreaker.isOpen()) {
        log.review(CIRCUIT_OPEN_EVENT, {
          requestId: details.requestId,
          provider: runtime.config.provider,
          model: runtime.config.model,
          outcome: 'defer',
          durationMs: 0,
          errorCategory: 'circuit-open',
        })
        return { kind: 'defer' }
      }

      const result = await runReview(runtime, details, dependencies)
      const durationMs = elapsedMilliseconds(dependencies.now, startedAt)
      if ('category' in result) {
        runtime.circuitBreaker.recordNonDenial()
        writeFailure(log, runtime, details, result, durationMs)
        return { kind: 'defer' }
      }

      const { assessment } = result
      log.review(DECISION_EVENT, {
        requestId: details.requestId,
        provider: runtime.config.provider,
        model: runtime.config.model,
        riskLevel: assessment.riskLevel,
        userAuthorization: assessment.userAuthorization,
        outcome: assessment.outcome,
        durationMs,
      })

      if (assessment.outcome === 'allow') {
        runtime.circuitBreaker.recordNonDenial()
        return { kind: 'allow' }
      }

      // A negative model assessment is advisory in this personal fork. Defer
      // to the normal permission prompt rather than hard-denying the action.
      runtime.circuitBreaker.recordNonDenial()
      return { kind: 'defer' }
    } catch {
      try {
        runtime.circuitBreaker.recordNonDenial()
      } catch {
        // Returning defer remains the safe fallback even if local state is unavailable.
      }
      tryWriteFailure(
        log,
        runtime,
        details,
        { category: 'internal-error' },
        elapsedMilliseconds(dependencies.now, startedAt),
      )
      return { kind: 'defer' }
    }
  }
}
