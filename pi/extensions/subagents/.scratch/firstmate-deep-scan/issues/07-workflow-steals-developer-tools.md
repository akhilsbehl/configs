Type: research
Status: resolved
Blocked by: none

## Question

What developer workflow tools in Firstmate (watch mode, calm mode, session start nudges, brief mode, stow/wake queues, task delivery) are worth stealing for Akhil's daily Pi agentic AI consulting workflow?

## Answer

Firstmate features three outstanding workflow tools:
1. **Primary Subagent PreTool Guard (`bin/fm-subagent-pretool-check.sh`)**: Intercepts primary agent attempts to call native harness delegation tools (e.g. Claude `Agent`/`Task` tool, native subagents) and redirects the model to use the managed fleet dispatch tools (`subagents_launch`).
2. **Persistent Shell `cd-guard` (`bin/fm-cd-pretool-check.sh`)**: PreToolUse hook denying bare top-level `cd <dir>` commands that persistently relocate the primary shell away from the workspace home root.
3. **Stow Memory Decay (`skills/stow/SKILL.md`)**: Sweeps session facts into decaying markdown tiers (`pinned`, `aging` 30d, `perishable` 7d) using HTML timestamp comments.

**Recommendation for `pi-subagents`**:
1. Implement a **Primary Subagent PreTool Guard** in Pi driver (`tool_call` event) to prevent the primary agent from accidentally bypassing `pi-subagents`.
2. Implement a **`cd-guard` Seatbelt** for subagents and primary driver to enforce `(cd <dir> && ...)` or `git -C <dir>` subshell execution instead of mutating persistent working directory.
3. Integrate decaying subagent memory tiers (`stow`) into subagent completion digests.
