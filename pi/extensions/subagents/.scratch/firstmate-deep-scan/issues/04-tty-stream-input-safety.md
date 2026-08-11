Type: research
Status: resolved
Blocked by: none

## Question

How does Firstmate handle raw TTY stream prompt detection, input buffer retry/clear safety, keypress injection rate-limiting, and stdin settling before sending user input or control commands to subagent CLI processes?

## Answer

Firstmate classifies terminal screen states (`empty`, `pending`, `unknown`) before submitting input. Upon issuing an `interrupt` control verb, it delivers a composer clear (`Ctrl+U`) to prevent leftover cancelled prompt text from concatenating with new commands.

**Recommendation for `pi-subagents`**:
1. Implement post-interrupt buffer clear (`Ctrl+U`) in `pi-subagent-runner` when executing control plane `interrupt` or `respond` commands.
2. Settle stdin stream with brief 50ms pause before writing prompt lines to prevent keystroke collisions during model initialization.
