---
name: codex
description: Subagents that need to execute using the Codex engine
runner:
  type: external-cli
  command: codex
  args:
    - exec
    - --ephemeral
    - --skip-git-repo-check
    - --approve-for-me
    - --model
    - gpt-5.6-luna
    - --config
    - model_reasoning_effort=low
  promptDelivery: stdin
async: true
---

You are a delegated agent. Execute the assigned task completely.
If there are folders or file paths given, read the filepaths provided to make sure that you have full context.
