Type: grilling
Status: resolved
Blocked by: 09, 10, 11, 12, 13, 14

## Question

Based on the round-2 findings (fleet-status interface, native Pi-extension prior art, per-engine harness adapters, authority/wake-queue draining, trace-context correlation & test boundary, stuck/wedge recovery), which recommendations should be incorporated into `spec.md`, and how? In particular: should the IPC protocol grow a task-scoped correlation id (Ticket 13's finding), should the TUI widget adopt the snapshot/view split and bounded "+K more" disclosure plus per-row watch/steer actions (Ticket 09), should the stuck/wedge recovery ladder (peek -> redirect -> interrupt -> capped relaunch, Ticket 14) replace or extend the existing liveness-only failure handling, and how much of the reusable native Pi-extension code (Ticket 10) should be called out as direct implementation guidance versus left as background context?

## Answer

Grilled via a plain-English pros/cons explainer (`.scratch/firstmate-deep-scan/15-decisions-explainer.md`), reviewed by Akhil via `richie`. Five of six sub-decisions settled, matching the recommended option in each case; the sixth was explicitly deferred to a new ticket.

1. **Correlation ID**: Add now. `status.json` grows a `correlation_id` field — an opaque identifier minted once at first spawn, persisted unchanged across every relaunch (including forced relaunches from the Stuck/Wedge Recovery Ladder). Not the full W3C traceparent format Firstmate uses. Folded into `spec.md` item 5.
2. **"Steer" action**: Routes through `inbox.jsonl`, same path as `subagents_send` — not direct pane injection. Folded into `spec.md` new item 12 (Fleet Status Widget & Steer Action), alongside the snapshot/view-split renderer and bounded "+K more" disclosure.
3. **Stuck/wedge recovery ladder**: Adopted in full — peek -> redirect -> interrupt -> forced relaunch (same tab/worktree/branch, carrying a progress note) -> fail after 2 relaunch attempts. Folded into `spec.md` new item 13 (Stuck/Wedge Recovery Ladder), wired to the existing `relaunch` verb (item 9) and the new `correlation_id` (item 5).
4. **Unknown busy-state for `agy`/`codex`**: Accepted as a v1 constraint — both fail closed to `unknown` until a concrete signal is empirically verified; no rendered-text heuristic stopgap. Folded into `spec.md` item 7.
5. **Code-reuse documentation level**: Deferred. Akhil wants further discussion before deciding how explicitly `spec.md` should point at Firstmate's reusable native Pi-extension code. Spun out as Ticket 16 (open, unblocked) rather than resolved here.
6. **Decisions-backlog draining**: Adopted both incremental byte-offset scanning and explicit ack-through draining. Folded into `spec.md` item 11's `/sa-decisions-backlog` bullet.

`spec.md` Testing Decisions also gained two new seams (6, 7) covering correlation-id/wedge-recovery and backlog-draining behavior.
