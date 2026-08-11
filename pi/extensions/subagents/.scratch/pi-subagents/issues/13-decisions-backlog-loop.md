# 13 — Decisions-backlog side-loop (`/sa-decisions-backlog`)

**What to build:** The driver can review and answer every pending permission/authority prompt across the whole subagent fleet in one side-session, without that review clogging the primary driver's own context, and without ever losing a response to a crash.

**Blocked by:** 03 — Send prompts and respond to control commands via IPC; 05 — TTY prompt detection and interrupt buffer safety; 10 — Zero-token supervision loop & Driver Turn-End Guard.

**Status:** ready-for-agent

- [ ] `/sa-decisions-backlog` lists every subagent currently `blocked_permission` or `blocked_decision`, with its `prompt_type` and pending prompt text.
- [ ] Each drain cycle re-scans only status/log bytes newly appended since the previous cycle (a persisted per-subagent byte-offset cursor), falling back to a full re-scan on cursor/file-identity mismatch.
- [ ] A prompt is removed from the backlog only after `subagents_respond` confirms the runner acknowledged delivery — a crash or lost message between display and delivery leaves it re-drainable, not silently gone.
- [ ] The loop distinguishes permission prompts (approve/deny affordance) from authority questions (multi-choice/freeform affordance) using `prompt_type` directly.
- [ ] Tests run against fixture IPC directories simulating: a growing status/log file across multiple drain cycles (verifying incremental scan), a response that never gets acknowledged (verifying re-drainability), and a cursor/file-identity mismatch (verifying full re-scan fallback).
