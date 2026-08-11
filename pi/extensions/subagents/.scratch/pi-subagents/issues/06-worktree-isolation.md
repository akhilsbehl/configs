# 06 — Disposable git worktree isolation

**What to build:** A code-modifying subagent can run in its own disposable git worktree so its edits never collide with the primary checkout or other concurrent subagents, and that worktree is torn down safely — never discarding uncommitted or unmerged work silently.

**Blocked by:** 01 — Launch a subagent to a Zellij tab and see it run to completion; 04 — Kill a subagent and tear down its Zellij tab.

**Status:** ready-for-agent

- [ ] `subagents_launch` accepts `worktree: true`, creating an isolated worktree and branch for that subagent and spawning it inside that directory.
- [ ] Two subagents launched concurrently with `worktree: true` never collide on git index locks or dirty working-tree state.
- [ ] Before `subagents_kill` removes a worktree, it checks for uncommitted changes and unmerged commits; if either exists, teardown requires an explicit `force: true` or driver confirmation rather than proceeding silently.
- [ ] A worktree with no uncommitted/unmerged work tears down cleanly with no confirmation needed.
- [ ] Tests run against a real (throwaway, test-fixture) git repo — worktree creation/teardown is real git behavior, not something to mock — covering: clean teardown, blocked teardown on dirty state, forced teardown override.
