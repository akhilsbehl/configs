---
name: sonnet
description: Subagents that need to execute using the Claude engine + Sonnet  model
runner:
  type: external-cli
  command: claude
  args:
    - -p
    - --autocompact
    - auto
    - --model
    - claude-sonnet-5
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
