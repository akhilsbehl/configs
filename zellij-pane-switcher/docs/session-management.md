# Session management specification

## Purpose

Extend the plugin so session lifecycle operations can be performed from the plugin UI, without invoking a shell or leaving the switcher.

The plugin must support:

1. creating a named session and switching to it;
2. killing a live session while retaining its resurrectable state;
3. permanently deleting a session, whether it is live or resurrectable.

After a kill or delete, return to the pane switcher so the user can choose where to jump. The only automatic session switch is the safety switch required when the plugin's current session is being killed or deleted.

## Terminology

- **Live session**: a session returned in `SessionInfo.live_sessions`.
- **Resurrectable session**: a session returned in `resurrectable_sessions`; it has no live panes.
- **Kill**: terminate a live session with `kill_sessions`. Its resurrectable cache is retained when Zellij creates one.
- **Delete**: permanently remove the session's resurrectable cache with `delete_dead_session`. Deleting a live session therefore means kill first, wait for it to disappear from the live list, then delete its cache.
- **Safety destination**: the next available live session used only when the plugin's current session is the affected session. It is selected deterministically by ascending session name, wrapping at the end, and excluding the affected session.

If no other live session exists, the plugin must not kill or delete the current session. Show an error and keep the plugin open.

## UI modes and navigation

The existing pane switcher and the session manager are two modes of the same plugin:

- **Pane switcher mode**: the current behavior; pane and resurrectable-session targets are listed.
- **Session manager mode**: only one row per session is listed. Live sessions and resurrectable sessions are both searchable by session name; panes and tabs are not listed.

`Ctrl-s` toggles back and forth between the modes. When entering session manager mode, carry over the current search query from pane switcher mode. Each mode may then edit its own query; switching modes preserves each mode's latest query.

`Esc` retains the current behavior: it closes the plugin from either mode. In a name prompt or confirmation, `Esc` cancels that prompt without making a host call and remains in the current mode.

In session manager mode:

| Key | Action |
| --- | --- |
| `n` | Prompt for a new session name |
| `k` | Kill the selected live session |
| `d` | Delete the selected live or resurrectable session |
| `Ctrl-s` | Toggle between pane switcher and session manager modes |
| `Esc` | Close the plugin (or cancel the active prompt) |
| `Enter` | Switch to the selected session |

Pane switcher mode retains its current controls. `Ctrl-s` is reserved for mode switching and must not be inserted into either query.

Before `k` or `d`, show a confirmation containing the exact session name and consequence:

- kill: “Session will be terminated but may be resurrected.”
- delete: “Resurrection data will be permanently removed.”

The confirmation must require an explicit `Enter`; `Esc` makes no host call.

## Behavior and invariants

### Create

1. Prompt for a non-empty session name after trimming surrounding whitespace.
2. Reject names containing a newline or exceeding the name length accepted by Zellij; keep the prompt open and show the validation error.
3. Call `switch_session(Some(name))`. Zellij creates the session if it does not exist and focuses it.
4. Clear transient UI state and hide the switcher after issuing the command.
5. Refresh from the next `SessionUpdate`; do not optimistically add a session.
6. If the name already exists, do not silently select a different session. Surface Zellij's failure/status and leave the current session unchanged.

### Kill

1. The target must be live. A resurrectable-only target is invalid for kill.
2. Determine whether the target is the current session from a fresh snapshot.
3. If the target is current, identify the safety destination before issuing any destructive command and switch to it first. This prevents the plugin from being destroyed before it sends the kill command.
4. Call `kill_sessions(&[target_name])` exactly once.
5. If the target is remote, do not automatically switch sessions; the current session remains available and the user chooses the next destination in pane switcher mode.
6. On command failure, report the error and refresh. If the safety switch already happened, do not switch back or retry the kill automatically.
7. On success, return to pane switcher mode and refresh. The killed session may appear as resurrectable and must remain selectable.

### Delete

1. The target may be live or resurrectable.
2. If the target is current, identify a safety destination before issuing any destructive command and switch to it first. If no other live session exists, refuse the operation.
3. For a resurrectable target, call `delete_dead_session(&target_name)` once.
4. For a live target, call `kill_sessions(&[target_name])`, wait for a `SessionUpdate` proving the target is no longer live, then call `delete_dead_session(&target_name)`.
5. If the target is remote, do not automatically switch sessions after deletion; return to pane switcher mode and let the user choose where to jump.
6. Never call `delete_dead_session` while the target is still live.
7. On success, return to pane switcher mode and refresh. The target must disappear from both live and resurrectable entries.
8. If kill or deletion fails, show the exact failure and do not claim completion. Avoid retrying a destructive host call automatically.

## Safety destination selection

Safety destination selection is required only when killing or deleting the current session:

1. take a fresh session snapshot immediately before the operation;
2. order live session names lexicographically using the same ordering as `normalize_sessions`;
3. start immediately after the target and wrap;
4. choose the first other live session;
5. activate it by name before killing the target.

The destination must be captured by name, not vector index, because session updates can reorder entries. Resurrectable-only sessions are not safety destinations: they cannot guarantee that the plugin remains available while the current live session is killed.

## Host API and permissions

Use Zellij tile APIs directly:

- create/switch: `switch_session(Some(name))`;
- kill: `kill_sessions(&[name])`;
- permanent deletion: `delete_dead_session(name)`;
- state: `get_session_list()` and `SessionUpdate`.

The plugin already requests `ReadApplicationState` and `ChangeApplicationState`; no shell command, CLI process, or additional permission is required. All host calls must be centralized behind testable session-operation helpers rather than spread through key handling.

## State model

Add explicit mode and operation state so destructive actions cannot be triggered twice:

```text
Mode: PaneSwitcher(query) | SessionManager(query)

Operation:
  Idle
  CreateName
  ConfirmKill(target)
  ConfirmDelete(target)
  Executing(operation, optional_safety_destination)
  WaitingForDeletion(target)
  Error(message)
```

While `Executing` or `WaitingForDeletion`, ignore lifecycle keys and render progress. Clear the operation only on success or explicit failure. A new `SessionUpdate` must reconcile the snapshot and complete the delete wait only when the target is absent from `live_sessions`.

## Acceptance criteria

- Session manager lists and searches sessions only, with no pane or tab rows.
- Entering session manager carries over the pane switcher's query; switching modes preserves each mode's query.
- `Ctrl-s` toggles between modes without changing either query; `Esc` closes the plugin from either mode and cancels, rather than submits, an active prompt or confirmation.
- Creating `new-name` leaves focus in `new-name` and adds no duplicate UI-only entry.
- Killing a remote live session leaves it absent from live sessions and, if Zellij exposes it, present as resurrectable; the plugin returns to pane switcher without automatically changing the current session.
- Killing the current session switches to the next available live session before sending the kill command, then returns to pane switcher.
- Deleting a resurrectable session removes it permanently and returns to pane switcher.
- Deleting a remote live session performs kill → confirmed absence from live sessions → delete cache, in that order, then returns to pane switcher.
- Deleting the current session performs switch → kill → wait → delete; with no alternative live session it is refused.
- `Esc` during name entry or confirmation produces no lifecycle host call.
- Host failures are visible, destructive calls are not automatically retried, and stale selections are revalidated against a fresh snapshot.

## Test plan

### Model tests

Add dependency-free tests for:

- session-only filtering and query carry-over between modes;
- deterministic safety-destination selection, including wraparound and exclusion of the target;
- refusal when the current session has no alternative live session;
- live versus resurrectable delete plans;
- current-session ordering (switch before kill) versus remote-session ordering (no automatic switch);
- mode toggling and `Esc` behavior;
- operation-state transitions and duplicate-key suppression.

### Integration/manual tests

Using `scripts/zps-test-env.sh`, verify each acceptance criterion with at least:

- two live sessions;
- one live session plus one resurrectable session;
- one current session only;
- a remote live target;
- a current live target;
- failed/invalid names and cancelled confirmations.

The checked-in `zellij-pane-switcher.wasm` must be rebuilt after implementation and tested with the configured Zellij 0.44.x environment.
