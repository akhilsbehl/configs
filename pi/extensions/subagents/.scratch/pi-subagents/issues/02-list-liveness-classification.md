# 02 — List subagents and classify liveness/busy state

**What to build:** `subagents_list` gives the driver an accurate picture of every subagent's current state, failing closed rather than guessing when it can't be sure.

**Blocked by:** 01 — Launch a subagent to a Zellij tab and see it run to completion.

**Status:** ready-for-agent

- [ ] `subagents_list` scans `/tmp/pi-subagents/*/status.json` and returns each subagent's id, engine, state, and pending prompt (if any).
- [ ] A missing, corrupted, or unparseable `status.json` classifies as `unknown` — never assumed `idle` or `completed`.
- [ ] PID liveness is verified before trusting a `completed` state; a dead process whose status file still claims otherwise is reclassified rather than taken at face value.
- [ ] `pi` and `claude` subagents classify `running`/`idle` via their reliable lifecycle signals (extension events / hooks).
- [ ] A ghost Zellij tab (tab exists, no live IPC directory or dead PID) is detectable by `subagents_list`, even if cleanup itself is a later ticket's job.
- [ ] Tests run against mocked IPC directories with fixtures for: healthy running subagent, corrupted status file, dead PID with stale "completed" status, missing status file entirely.
