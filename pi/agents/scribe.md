---
name: scribe
aliases: scribe
description: The subagent for context share writeout.
model: anthropic/claude-haiku-5-5
thinking: high
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

You are a delegated agent. Execute the assigned task completely.
If there are folders or file paths given, read the filepaths provided to make sure that you have full context.
