# 03 — Zellij Tab & Disposable Git Worktree Manager

**What to build:** Zellij tab creation, focus preservation, optional disposable git worktree isolation (`worktree: true`), and stale/orphaned worktree detection & cleanup.

**Blocked by:** 02 — `pi-subagent-runner` Process & IPC Protocol Layer

**Status:** ready-for-agent

- [ ] Checks `ZELLIJ_SESSION_NAME` in environment and fails with clear user error if missing
- [ ] Supports optional `worktree?: boolean` parameter: when true, runs `git worktree add .scratch/worktrees/<id> -b subagent/<id>` and sets working directory for subagent
- [ ] Spawns subagent in dedicated Zellij tab with home-scoped title: `zellij action new-tab --name "subagent:<home_hash>-<id> [<engine>]" -- node .../runner.js ...`
- [ ] Preserves active tab focus by calling `zellij action go-to-tab-by-id` immediately after `new-tab` creation
- [ ] Safely removes temporary git worktree (`git worktree remove --force .scratch/worktrees/<id>`) and closes Zellij tab on subagent termination/kill
- [ ] Provides orphan worktree recovery: detects dead subagent PIDs, marks status as `failed`/`stale`, and permits unlanded worktree cleanup without file corruption
