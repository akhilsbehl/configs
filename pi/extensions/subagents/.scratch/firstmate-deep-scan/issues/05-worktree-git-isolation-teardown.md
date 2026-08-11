Type: research
Status: resolved
Blocked by: none

## Question

What git worktree isolation edge cases (uncommitted changes, stale branch cleanup, worktree lock settlement, dirty state preservation options) does Firstmate solve in its teardown safety logic?

## Answer

Firstmate verifies base branch freshness prior to spawning worktrees and checks for uncommitted changes or unmerged git commits before executing worktree teardown (`bin/fm-teardown.sh`). It prevents destroying work that hasn't been merged into the parent repository.

**Recommendation for `pi-subagents`**:
1. Add **Landed-Work Safety Verification** to `subagents_kill`: before running `git worktree remove --force .scratch/worktrees/<id>`, inspect git status and log in the worktree. If uncommitted edits or unmerged commits exist, require explicit `force: true` parameter or prompt driver.
2. Clean up temporary git branches (`subagent/<id>`) safely upon subagent exit.
