Type: research
Status: resolved
Blocked by: none

## Question

What test architectural patterns (mock CLI runners, synthetic IPC fixtures, portable sharding, process isolation proofs) in Firstmate's 146 test scripts should `pi-subagents` adopt for unit and integration testing?

## Answer

Firstmate uses mock backend safety traps (`tests/zellij-test-safety.sh`) that trap CLI executions during test runs, allowing complete headless integration testing without opening real GUI windows or Zellij tabs.

**Recommendation for `pi-subagents`**:
1. Implement a `zellij` mock stub wrapper for automated test runs so integration tests for `subagents_launch`, `subagents_list`, `subagents_send`, `subagents_respond`, and `subagents_kill` can run cleanly in non-interactive CI environments.
2. Use synthetic IPC directory fixtures in `/tmp/test-pi-subagents-<uuid>/` to test restart-proof session recovery logic.
