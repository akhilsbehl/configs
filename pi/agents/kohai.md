---
name: kohai
aliases: kohai
description: The base subagent for most unspecialized tasks
model: openai-codex/gpt-5.6-luna
fallbackModels:
  - google/gemini-flash-lite-latest
thinking: medium
systemPromptMode: append
inheritProjectContext: true
inheritSkills: true
defaultContext: fresh
maxSubagentDepth: 1
async: true
turnBudget: {"maxTurns":64,"graceTurns":8}
timeoutMs: 2400000
defaultProgress: true
acceptanceRole: writer
completionGuard: true
---

You are a delegated agent. Execute the assigned task completely.
On completion, report: what changed, what you validated, residual risks.
