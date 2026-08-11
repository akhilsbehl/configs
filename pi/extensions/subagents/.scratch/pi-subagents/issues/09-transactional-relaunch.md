# 09 — Transactional relaunch control verb

**What to build:** The driver can change a running subagent's engine, model, or thinking effort without losing its Zellij tab or its worktree — the old process stops, the new one picks up with context about where the last one left off.

**Blocked by:** 03 — Send prompts and respond to control commands via IPC; 06 — Disposable git worktree isolation.

**Status:** ready-for-agent

- [ ] The runner accepts a `{"type": "control", "verb": "relaunch", "engine": "...", "model": "...", "thinking": "..."}` command on `inbox.jsonl`.
- [ ] On relaunch, the current CLI process stops, the Zellij tab and worktree are preserved untouched, and the new CLI spawns with the updated parameters.
- [ ] A progress note is appended to the subagent's instruction context so the replacement process understands what the prior process had done.
- [ ] `correlation_id` and `id` are unchanged across the relaunch — the IPC directory and identity persist.
- [ ] Tests run against a mocked runner process, verifying: old process is stopped before the new one starts (no double-spawn), worktree/tab survive relaunch, progress note is present in the new process's launch context.
