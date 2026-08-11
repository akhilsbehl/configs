Type: research
Status: resolved
Blocked by: none

## Question

How does Firstmate render fleet status to the human (`bin/fm-fleet-view.sh`, `bin/fm-fleet-snapshot.sh`) and what quick-glance/brief interaction commands (`bin/fm-brief.sh`, `bin/fm-peek.sh`) does it expose, and what should `pi-subagents`' TUI status widget and driver-facing commands adopt from these interface patterns?

## Answer

Firstmate separates fleet state from fleet rendering: `fm-fleet-snapshot.sh` is a read-only JSON producer (schema `fm-fleet-snapshot.v1`) that reads `state/*.meta`, `*.status` logs, and `data/backlog.md` and computes per-task `current_state`, `endpoint.exists`/`agent_alive`, `hints.pending_decision`/`blocked_event`, and per-task `actions` (e.g. `watch: bin/fm-peek.sh fm-<id>`, `steer: bin/fm-send.sh fm-<id> '<instruction>'`); `fm-fleet-view.sh` is a pure renderer that shells out to the snapshot and turns it into a human Markdown table (Under Way / Queued / Done / Secondmates), never re-parsing state itself; `fm-bearings-snapshot.sh` is a third, bounded/compact "pick up where I left off" projection (TOON by default) over the same snapshot, capping in-flight/decisions/landed/reports counts and explicitly disclosing what was dropped via an `omitted[]` array. Quick-glance/interaction is handled by tiny dedicated scripts: `fm-peek.sh <target> [lines]` prints a bounded tail of one crewmate's terminal for cheap diagnosis, and (referenced via the snapshot's `actions` field, not read directly) `fm-send.sh` steers/sends into a task's pane. `fm-brief.sh` is a separate, unrelated scaffolding tool that writes the initial task contract (ship/scout/secondmate) a crewmate must follow, including the exact `state: detail` status-line protocol (`working`, `needs-decision`, `blocked`, `paused`, `done`, `failed`) crewmates must self-report through, which is what the snapshot/view/bearings layers all key off of.

**Recommendation for `pi-subagents`**:
1. Mirror the snapshot/view split: keep the Node.js supervision loop's aggregated state as one canonical JSON object (already implied by `status.json` files) and make the TUI widget a pure renderer over it — never have the widget re-derive state from raw files itself, so a second consumer (e.g. a future CLI `pi-subagents status`) gets identical data for free.
2. Give the TUI widget a bounded/compact mode analogous to `fm-bearings-snapshot.sh`: cap the "waiting subagents" list to N rows with an explicit "+K more" disclosure line rather than either truncating silently or growing unbounded — this matters once `/sa-decisions-backlog` can have many pending prompts.
3. Adopt firstmate's per-task `actions` pattern in the widget/backlog: attach a ready-to-run "watch" command (jump to Zellij tab / attach) and a "steer" command (send text into the subagent's pane) directly on each listed row, rather than making the driver hunt for the right tab manually — this is exactly the gap between "TUI shows waiting subagents" and "driver can act on one."
4. Borrow firstmate's status-line discipline for whatever a subagent writes back through: a single-line, machine-parseable `state: detail` convention (firstmate's `working/needs-decision/blocked/paused/done/failed`) keeps both the zero-token scanner and the human-facing renderer trivial to build, versus letting each engine (`pi`/`claude`/`codex`/`agy`) report status in its own shape.
