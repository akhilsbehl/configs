import { describe, expect, it } from 'vitest'
import { buildSystemPrompt } from './policy.js'

describe('personal default review policy', () => {
  it('uses concise reviewer semantics without implementation details', () => {
    const prompt = buildSystemPrompt({
      provider: 'openai-codex',
      model: 'codex-auto-review',
      reasoning: 'low',
      timeoutMs: 90_000,
      includeBaselinePolicy: true,
    })

    expect(prompt).toContain('Return deny when the action should not proceed')
    expect(prompt).not.toContain('permission-system authorizer')
    expect(prompt).not.toContain('{"kind":"defer"}')
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
