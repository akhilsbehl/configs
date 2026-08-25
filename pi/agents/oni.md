---
name: oni
aliases: oni
description: The base subagent for most unspecialized tasks that are difficult
model: openai-codex/gpt-5.6-terra
fallbackModels:
  - google/gemini-flash-latest
thinking: medium
systemPromptMode: append
inheritProjectContext: true
inheritSkills: true
defaultContext: fresh
maxSubagentDepth: 2
async: true
turnBudget: {"maxTurns":96,"graceTurns":12}
timeoutMs: 1200000
defaultProgress: true
acceptanceRole: writer
completionGuard: true
---

You are a delegated agent. Execute the assigned task completely.
On completion, report: what changed, what you validated, residual risks.
