# 01 — Launch a subagent to a Zellij tab and see it run to completion

**What to build:** `subagents_launch` spawns a subagent CLI process inside a new, home-scoped, dedicated Zellij tab, running under the `pi-subagent-runner` wrapper. The driver's own active tab focus is preserved. The subagent runs to completion and its final state is durably recorded on disk.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `subagents_launch` accepts engine (`pi`/`claude`/`codex`/`agy`, default `pi` for this ticket — other engines land in Ticket 07), model, and thinking/effort parameters.
- [ ] A new Zellij tab is created named `subagent:<home_hash>-<id> [<engine>]`; the driver's previously-active tab regains focus immediately after spawn.
- [ ] `pi-subagent-runner` sanitizes inherited driver environment variables (`PI_CODING_AGENT`, `CLAUDECODE`, etc.) before spawning the target CLI.
- [ ] `/tmp/pi-subagents/<id>/status.json` and `meta.json` are created on spawn with the full IPC schema (`id`, `correlation_id`, `engine`, `state`, `pid`, `created_at`, `updated_at`, `pending_prompt`, `prompt_type`, `error`); `correlation_id` is minted once here.
- [ ] `status.json`'s `state` transitions `starting` → `running` → `completed` as the subagent's CLI process runs and exits cleanly.
- [ ] Attempting to launch without `ZELLIJ_SESSION_NAME` set fails with a clear, actionable error rather than a silent no-op or crash.
- [ ] Tests run headless against a mocked `zellij` binary and mocked IPC directories — no real Zellij display session required.
