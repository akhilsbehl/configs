# Session management implementation tickets

## SM-01 — Add pane/session manager modes

**Status: complete.**

Add explicit mode state and `Ctrl-s` toggling. Session manager mode must render and search one selectable row per live or resurrectable session, while pane switcher behavior remains unchanged. Preserve a separate query per mode and carry the pane query into session mode on first entry. Keep `Esc` as close/cancel in both modes.

**Done when:** model tests cover session-only filtering and mode/query transitions; existing pane-switcher tests still pass.

## SM-02 — Session selection and activation

Make session rows selectable in session manager mode. `Enter` switches to the selected live or resurrectable session. Validate the target against a fresh snapshot before activation and report stale/failed targets without hiding the plugin.

**Depends on:** SM-01.

## SM-03 — Create-session prompt

Add the named-session prompt, validation, `switch_session(Some(name))`, status/error handling, and refresh behavior.

**Depends on:** SM-01, SM-02.

## SM-04 — Kill-session workflow

Add confirmation, current-session safety destination selection, `kill_sessions`, failure handling, and return to pane-switcher mode after success.

**Depends on:** SM-02.

## SM-05 — Delete-session workflow

Add confirmation and permanent deletion for resurrectable sessions, plus live-session kill → `SessionUpdate` absence → `delete_dead_session` sequencing.

**Depends on:** SM-04.

## SM-06 — Manual integration and release artifact

Exercise all acceptance criteria with `scripts/zps-test-env.sh`, then rebuild and verify the checked-in `zellij-pane-switcher.wasm`.

**Depends on:** SM-01 through SM-05.
