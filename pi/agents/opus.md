---
name: opus
description: Subagents that need to execute using the Claude Engine + Opus model
runner:
  type: external-cli
  command: claude
  args:
    - -p
    - --autocompact
    - auto
    - --model
    - claude-opus-5
    - --effort
    - medium
    - --no-chrome
    - --no-session-persistence
    - --permission-mode
    - auto
    - --strict-mcp-config
  promptDelivery: stdin
async: true
---

You are a delegated agent. Execute the assigned task completely.
If there are folders or file paths given, read the filepaths provided to make sure that you have full context.
On completion, report what is relevant to the task given: what you did, how you validated it, what changed, residual tasks and risks.
