# pi-zellij-status

A pragmatic Pi extension that mirrors Pi attention state into the current Zellij session.

## State model

- `idle`: Pi has settled and is ready for a new task. It is cleared by the next chat input.
- `waiting`: Pi is waiting for a user decision in one of the supported current extensions. It remains until the interaction resolves.
- No `running` state is displayed.

The extension is intentionally Zellij-only. It exits without changing anything unless `ZELLIJ_SESSION_NAME` and `ZELLIJ_PANE_ID` are present.

## Current integrations

- `@gotgenes/pi-permission-system`: `permissions:ui_prompt` and `permissions:decision`.
- `@juicesharp/rpiv-ask-user-question`: `rpiv:ask-user:blocked`.
- `@narumitw/pi-plan-mode`: `plan_mode_question` tool lifecycle and the persisted completed-plan state. The completed-plan menu has no public event, so the extension detects its persisted ready state after `agent_settled`.
- User-invoked menus in `pi-btw` and `pi-patty-bg-tasks` are not treated as agent waiting. They are initiated by the user.
- `pi-web-access`, local `jina.ts`, `pi-statusline`, and automatic permission review do not expose a current human blocking interaction used by this extension.

## Naming

Status values are appended to the current pane and tab names. The extension strips only its own trailing status suffix before appending a new one. It does not restore names on shutdown yet because these names are dynamic by design.

Examples:

```text
my-pane [idle]
my-pane [waiting]
my-tab [waiting:2]
```

## Bell

A Zellij visual bell is produced by the Zellij pane when a waiting transition is displayed. Configure Zellij with `visual_bell true`. The extension does not use Windows notifications.

## Future package integration

When installing a package that might ask the user to make a decision:

1. Inspect the package source for `ctx.ui.select`, `input`, `editor`, `confirm`, and `custom`.
2. Determine whether the UI is agent-originated or only a user-invoked command menu.
3. Prefer a package-emitted event on `pi.events` with a start/end or active boolean.
4. If no event exists, identify a stable tool lifecycle or persisted state that proves the agent is waiting.
5. Add the smallest adapter to `extensions/pi-zellij-status.ts`.
6. Update this document with the package version, event/tool/state used, and known limitations.
7. Test both resolution and cancellation. Avoid treating every tool call or every UI primitive as waiting.

This is a deliberate pragmatic adapter pattern. Pi currently has no universal lifecycle hook around UI primitives.
