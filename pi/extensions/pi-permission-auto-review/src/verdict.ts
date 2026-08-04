import { z } from 'zod'

const assessmentPayloadSchema = z.strictObject({
  risk_level: z.enum(['low', 'medium', 'high', 'critical']).optional(),
  user_authorization: z.enum(['unknown', 'low', 'medium', 'high']).optional(),
  outcome: z.enum(['allow', 'deny']),
  rationale: z.string().trim().min(1).max(4_000).optional(),
})

type RiskLevel = 'low' | 'medium' | 'high' | 'critical'
type UserAuthorization = 'unknown' | 'low' | 'medium' | 'high'

export interface ReviewAssessment {
  riskLevel: RiskLevel
  userAuthorization: UserAuthorization
  outcome: 'allow' | 'deny'
  rationale: string
}

function parseJsonObject(text: string): unknown {
  try {
    return JSON.parse(text)
  } catch {
    const start = text.indexOf('{')
    const end = text.lastIndexOf('}')
    if (start < 0 || end <= start) {
      throw new Error('review response was not valid JSON')
    }
    return JSON.parse(text.slice(start, end + 1))
  }
}

export function parseReviewAssessment(text: string): ReviewAssessment {
  const payload = assessmentPayloadSchema.parse(parseJsonObject(text))
  const riskLevel = payload.risk_level ?? (payload.outcome === 'allow' ? 'low' : 'high')
  const rationale =
    payload.rationale ??
    (payload.outcome === 'allow'
      ? 'Automatic review returned a low-risk allow decision.'
      : 'Automatic review returned a deny decision without a rationale.')

  return {
    riskLevel,
    userAuthorization: payload.user_authorization ?? 'unknown',
    outcome: payload.outcome,
    rationale,
  }
}
