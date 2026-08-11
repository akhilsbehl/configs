Type: grilling
Status: resolved
Blocked by: 01, 02, 03, 04, 05, 06, 07

## Question

Based on findings from Tickets 01-07, how should `spec.md` be updated to incorporate all approved architecture, reliability, test, and workflow enhancements?

## Answer

`spec.md` has been fully updated to incorporate all synthesized architectural patterns and workflow steals from `firstmate`:
1. **Transactional Relaunch Verb**: Added control plane `relaunch` verb to update engine/model/effort on active subagents without discarding Zellij tab or worktree state.
2. **Driver Turn-End Guard (`pi.on("agent_settled")`)**: Added turn-end guard that alerts the primary driver before going idle if any subagent is waiting on decision approvals or input.
3. **Primary Delegation PreTool Guard**: Intercepts native harness subagent tools directly, redirecting driver LLM to use `subagents_launch`.
4. **Landed-Work Teardown Safety**: Checks git status/log for uncommitted changes or unmerged commits before destroying worktrees.
5. **Strict `unknown` State Defense & Post-Interrupt Buffer Clearing**: Fails closed on unparseable status files; sends `Ctrl+U` to TTY composer post-interrupt.
6. **`cd-guard` Seatbelt**: Enforces subshell syntax for working directory changes.
7. **Mocked Zellij Test Safety Harness**: Mocked Zellij wrapper for headless integration testing.
