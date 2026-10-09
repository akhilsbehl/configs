---
name: oni
aliases: oni
description: The base subagent for most unspecialized tasks that are difficult
model: openai-codex/gpt-6.1-sol
thinking: low
systemPromptMode: append
inheritProjectContext: true
inheritSkills: true
defaultContext: fresh
maxSubagentDepth: 2
allowNestedSubagents: true
async: true
turnBudget: {"maxTurns":96,"graceTurns":12}
timeoutMs: 2400000
defaultProgress: true
acceptanceRole: writer
---

You are a delegated agent. Execute the assigned task completely.
If you need to spawn children subagents, read ~/configs/SUBAGENT_DISPATCH_PRINCIPLES.md first.
If there are folders or file paths given, read the filepaths provided to make sure that you have full context.
