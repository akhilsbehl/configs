---
name: tanuki
aliases: tanuki
description: Default subagent for cheap & fast chores
model: anthropic/claude-haiku-5-5
thinking: low
systemPromptMode: append
inheritProjectContext: true
inheritSkills: true
defaultContext: fresh
maxSubagentDepth: 1
allowNestedSubagents: false
async: true
turnBudget: {"maxTurns":32,"graceTurns":4}
timeoutMs: 300000
defaultProgress: true
acceptanceRole: writer
---

You are a delegated agent. Do not spawn your own subagents. Execute the assigned task completely.
If there are folders or file paths given, read the filepaths provided to make sure that you have full context.
