## Destination

A comprehensive architectural synthesis and feature extraction of `~/warchives/firstmate` against `spec.md`, resulting in prioritized design enhancements, edge-case hardening, test suite additions, and personal workflow tools for `pi-subagents`.

## Notes

- Effort: Custom personal subagent orchestrator (`pi-subagents`) inspired by `firstmate`.
- Scope: High-leverage patterns, zero-token IPC, process liveness, TTY input safety, decision backlog, test suite seams, and custom developer workflows.
- Skills: `/wayfinder`, `/research`, `/grilling`, `/domain-modeling`.

## Decisions so far

- [01-ipc-control-data-plane.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/01-ipc-control-data-plane.md) — Separated Control plane (`interrupt`, `exit`, `relaunch`) from Data plane chat; added transactional `relaunch` control verb.
- [02-process-liveness-ghost-tabs.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/02-process-liveness-ghost-tabs.md) — Enforced strict `unknown` state classification on corrupted IPC status; verified PID liveness & dynamic Zellij tab cleanup.
- [03-supervision-decision-hold-backlog.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/03-supervision-decision-hold-backlog.md) — Implemented Driver Turn-End Guard (`pi.on("agent_settled")`) to alert driver before turn completion if subagents wait for input.
- [04-tty-stream-input-safety.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/04-tty-stream-input-safety.md) — Added post-interrupt `Ctrl+U` composer clear and stdin settling delay.
- [05-worktree-git-isolation-teardown.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/05-worktree-git-isolation-teardown.md) — Added Landed-Work Teardown Safety checking uncommitted/unmerged commits before worktree deletion.
- [06-test-isolation-suite-seams.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/06-test-isolation-suite-seams.md) — Added mocked Zellij runner test harness for headless CI test execution.
- [07-workflow-steals-developer-tools.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/07-workflow-steals-developer-tools.md) — Adopted Primary Delegation PreTool Guard, `cd-guard` seatbelt, and `stow` decaying memory tiers.
- [08-spec-enhancement-synthesis.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/08-spec-enhancement-synthesis.md) — Updated `spec.md` with all synthesized architectural patterns and workflow steals.

## Not yet specified

- Custom shell alias shortcuts and Zellij bindings for quick `pi-subagents` fleet navigation.
- Automatic context pruning / compression adapter for subagent prompt history.

## Out of scope

- Multi-machine / remote secondmate SSH synchronization (`remote-secondmates.md` — out of scope for local WSL2 setup).
- Proprietary enterprise cloud daemon backend integration (Herdr / Orca — Zellij + local IPC is sufficient).
