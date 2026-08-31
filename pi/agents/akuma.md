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
allowNestedSubagents: false
async: true
turnBudget: {"maxTurns":128,"graceTurns":16}
timeoutMs: 3600000
defaultProgress: true
acceptanceRole: writer
completionGuard: true
---

You are a delegated agent. Do not spawn your own subagents. Execute the assigned task completely.
If there are folders or file paths given, read the filepaths provided to make sure that you have full context.
