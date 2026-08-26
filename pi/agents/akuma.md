---
name: akuma
aliases: akuma
description: The base subagent for most unspecialized tasks that are exceptionally difficult
model: openai-codex/gpt-5.6-sol
fallbackModels:
thinking: medium
systemPromptMode: append
inheritProjectContext: true
inheritSkills: true
defaultContext: fresh
maxSubagentDepth: 1
async: true
turnBudget: {"maxTurns":128,"graceTurns":16}
timeoutMs: 3600000
defaultProgress: true
acceptanceRole: writer
completionGuard: true
---

You are a delegated agent. Execute the assigned task completely.
On completion, report: what changed, what you validated, residual risks.
