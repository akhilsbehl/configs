# Permission confirmation / Zellij status integration report

Date: 2026-08-26

## Outcome

The permission extension now exposes an explicit, versioned lifecycle event for the only permission interaction that blocks on the operator. `pie-zellij-status` consumes that event and shows the pane as `◷ Waiting` for the duration of the confirmation.

This avoids guessing from the generic `tool_call` event. Automatic model review, deterministic path allows, redirects, no-UI blocks, and the permission extension's user-invoked configuration menu do not enter `waiting`.

## Event contract

Event name:

```text
pie-permission-auto-review-codex:permission-confirmation:v1
```

Payload:

```ts
{ requestId: string; active: boolean }
```

The permission extension emits `active: true` immediately before `ctx.ui.confirm` and emits `active: false` in `finally`. The request id is the existing permission request id. No command, path, prompt, or other permission data crosses the event boundary. Event observer failures cannot change the permission decision.

The Zellij extension validates the payload, tracks request ids in a `Set`, handles duplicate starts/ends idempotently, and unsubscribes during `session_shutdown`. A pending request takes precedence over `idle`/`running`.

## Changes

### `pie-permission-auto-review-codex`

- Added the exported `PERMISSION_CONFIRMATION_EVENT` constant.
- Added guarded lifecycle emission around the user confirmation.
- Preserved failed-closed permission behaviour and cleanup on rejected/cancelled confirmation.
- Added tests for normal bracketing and rejection cleanup.
- Rebuilt tracked `dist/` output.

Branch/commit: `permission-confirmation-events` / `5e21197`

### `pie-zellij-status`

- Added the matching event subscription and request tracking.
- Removed the obsolete permission channels and dead local waiting-state mutation code.
- Retained child-runtime acknowledgement for `pi-subagents`.
- Updated the README and skill documentation with the integration contract.
- Added the ESM package declaration.

Branch/commit: `permission-confirmation-events` / `a0e5b8c`

## Validation

- Permission package: `npm run typecheck` passed.
- Permission package: `npm test` passed — 6 files, 32 tests.
- Permission package: `npm run build` passed; generated distribution was unchanged after rebuild.
- Cross-package interaction test passed using a shared event bus and mocked Zellij commands. It verified that a pending confirmation produces `◷ Waiting`, and resolution produces `● Running`.
- Zellij package: Node TypeScript syntax check and `git diff --check` passed.
- Child acknowledgement smoke test passed without Zellij environment variables.
- No stale permission-channel references remain in executable code.

The interaction test was deliberately temporary rather than committed as a test in either public package: it imports an absolute sibling checkout path and would not be portable for package consumers. The two package-local test suites remain self-contained.

## Parent monorepo updates

The parent `configs` repository was updated only after each child commit was pushed:

1. `21f9b4c` — updated the permission-extension submodule to `5e21197`.
2. `5d3680f` — updated the Zellij-status submodule to `a0e5b8c`.
3. This report is added in the parent repository in the follow-up commit below.

The parent branch was pushed to `origin/master` at `5d3680f` before this report was added. The report commit follows separately.

## Findings and residual risks

- `pi.events` is process-local. This integration works because both extensions run in the same Pi process; it will not bridge separate child processes.
- The event name is duplicated as a string in the two packages. The `v1` suffix makes future contract changes explicit, but a shared dependency is intentionally avoided to keep the packages independent.
- A child launch policy can disable ambient extensions. The existing child-runtime acknowledgement remains the authoritative evidence for child registration.
- The parent repository had one pre-existing unpushed commit; pushing the requested submodule updates also published that existing parent history.
