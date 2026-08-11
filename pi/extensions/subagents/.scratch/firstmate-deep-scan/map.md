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
- [09-fleet-status-interface.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/09-fleet-status-interface.md) — Adopt snapshot/view split, bounded "+K more" disclosure, per-row watch/steer actions, and a single-line machine-parseable status convention for the TUI widget.
- [10-pi-extension-prior-art.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/10-pi-extension-prior-art.md) — Firstmate already ships working native Pi extensions (`tool_call` veto pattern, `agent_settled` re-entrancy-guarded followUp, visibility-predicate pattern, tool-shell box pattern) directly portable to `pi-subagents`.
- [11-harness-engine-adapters.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/11-harness-engine-adapters.md) — No busy/idle precedent exists for `agy`; adopt Firstmate's tiered source model (hooks > log-fold > rendered-tail) with fail-closed `unknown` until empirically verified, plus graceful effort-flag degradation.
- [12-authority-wake-queue-draining.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/12-authority-wake-queue-draining.md) — Adopt incremental byte-offset decision scanning and explicit ack-through draining; keep `prompt_type` as the structural classifier rather than collapsing it like Firstmate does.
- [13-trace-context-test-boundary.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/13-trace-context-test-boundary.md) — Add a task-scoped correlation id (minted once, reused on relaunch, never inherited) to the IPC protocol; adopt Firstmate's three-tier mock/smoke/live-e2e test boundary and fail-closed session-teardown guard.
- [14-stuck-wedge-recovery.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/14-stuck-wedge-recovery.md) — Adopt a graduated recovery ladder (peek -> redirect -> interrupt -> capped relaunch preserving worktree/branch) and fail-safe lock/worktree staleness proof, beyond PID-only liveness.
- [15-round2-spec-synthesis.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/15-round2-spec-synthesis.md) — Folded correlation ID, steer-via-inbox, stuck/wedge ladder, unknown busy-state acceptance, and backlog draining into `spec.md`; code-reuse doc-level deferred to Ticket 16.
- [16-code-reuse-doc-level.md](file:///home/akhil/warchives/pi-subagents/pi/extensions/subagents/.scratch/firstmate-deep-scan/issues/16-code-reuse-doc-level.md) — Mine Firstmate for backend-agnostic design, port its small MIT-licensed native Pi-extension files verbatim (with attribution), write the Zellij/engine-specific surface fresh; `spec.md` gets one-line pointers per relevant decision, not full patterns.

## Not yet specified

- Custom shell alias shortcuts and Zellij bindings for quick `pi-subagents` fleet navigation.
- Automatic context pruning / compression adapter for subagent prompt history.
- Empirical verification of per-engine busy/idle signal delivery (hooks, log files, rendered-tail tokens) for `agy` and `codex` against `pi-subagents`' actual Zellij-tab launch shape — can't be ticketed precisely until there's a running implementation to verify against.

## Out of scope

- Multi-machine / remote secondmate SSH synchronization (`remote-secondmates.md` — out of scope for local WSL2 setup).
- Proprietary enterprise cloud daemon backend integration (Herdr / Orca — Zellij + local IPC is sufficient).
