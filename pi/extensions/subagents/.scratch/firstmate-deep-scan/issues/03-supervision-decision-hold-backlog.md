Type: research
Status: resolved
Blocked by: none

## Question

How does Firstmate implement the decision-hold lifecycle, turnend guards, sessionstart nudges, and authority level classification (`permission` vs `authority`), and how should `pi-subagents` refine `/sa-decisions-backlog` and `pi.on("session_start")`?

## Answer

Firstmate uses a Driver Turn-End Guard (`bin/fm-turnend-guard.sh`) that intercepts driver turn completion if any subagent has an open decision hold (`needs-decision`) or unapproved permission request. It also uses `sessionstart` nudges to inject active fleet state into context.

**Recommendation for `pi-subagents`**:
1. Implement a **Driver Turn-End Guard** in `pi.on("agent_settled")`. If any background subagent is in `blocked_permission` or `blocked_decision`, inject a non-blocking prompt into the driver session before turn completion: *"Subagent <id> is blocked waiting for input: <prompt>. Use `/sa-decisions-backlog` or `subagents_respond`."*
2. Gate `subagents_kill` and worktree teardown against unresolved decision holds to prevent deleting work while decisions remain pending.
