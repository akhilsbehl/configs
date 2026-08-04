import { describe, expect, it } from 'vitest'
import { buildSystemPrompt } from './policy.js'

describe('personal default review policy', () => {
  it('treats reviewer denials as user confirmation rather than hard denial', () => {
    const prompt = buildSystemPrompt({
      provider: 'openai-codex',
      model: 'codex-auto-review',
      reasoning: 'low',
      timeoutMs: 90_000,
      includeBaselinePolicy: true,
    })

    expect(prompt).toContain('This reviewer never hard-denies an action.')
    expect(prompt).toContain('model deny to the permission-system authorizer verdict')
    expect(prompt).not.toContain('medim')
  })

  it('retains optional additional policy support', () => {
    const prompt = buildSystemPrompt({
      provider: 'openai-codex',
      model: 'codex-auto-review',
      reasoning: 'low',
      timeoutMs: 90_000,
      includeBaselinePolicy: true,
      additionalPolicy: 'Prefer explicit confirmation for this test action.',
    })

    expect(prompt).toContain('Prefer explicit confirmation for this test action.')
  })
})
