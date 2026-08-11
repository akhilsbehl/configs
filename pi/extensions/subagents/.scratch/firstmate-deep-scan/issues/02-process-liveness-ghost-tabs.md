Type: research
Status: resolved
Blocked by: none

## Question

What multi-surface liveness checks (PID checking, TTY stream activity, status heartbeat, exit code verification) does Firstmate use to detect dead subagents, prevent ghost Zellij tabs, and avoid false-positive zero exit-code cleanups?

## Answer

Firstmate classifies process liveness into `busy`, `idle`, `dead`, or `unknown`. Any corrupted, unreadable, or missing status file evaluates to `unknown` rather than assuming `idle` or `completed`. It monitors process PID, TTY activity, and vendor lifecycle events (`agent_start`, `agent_settled`).

**Recommendation for `pi-subagents`**:
1. Enforce strict `unknown` state classification in `subagents_list` — if a subagent's `status.json` is missing or unparseable while PID is dead, flag as `failed:corrupted_status` rather than marking completed.
2. Verify PID liveness before declaring completion when subagent CLI exits with 0.
3. Clean up ghost Zellij tabs dynamically using `<home_hash>-<id>` tab matchers on `subagents_kill`.
