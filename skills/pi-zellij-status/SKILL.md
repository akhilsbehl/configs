---
name: pi-zellij-status
description: Extend the pi-zellij-status extension when a new Pi package introduces user-blocking interactions. Use this skill to inspect the package source, distinguish agent waiting from user-invoked UI, choose an event/tool/state adapter, and document the integration.
---

# Extending pi-zellij-status

Read `README.md` in the pi-zellij-status project before changing the extension.

## Decision procedure

1. Identify every interaction the package can display.
   Search for:

   ```text
   ctx.ui.select
   ctx.ui.input
   ctx.ui.editor
   ctx.ui.confirm
   ctx.ui.custom
   pi.events.emit
   registerTool
   registerCommand
   ```

2. Classify each interaction:
   - Agent-originated: the model called a tool or the agent workflow reached a decision point. This can set `waiting`.
   - User-originated: the user typed a command such as `/compact` or `/btw`. Do not set `waiting` merely because that command opens a menu.
   - Background work: long-running work without user input. Do not set `waiting`.

3. Prefer signals in this order:
   - A public package event on `pi.events` that brackets the interaction.
   - A specific tool's `tool_execution_start` and `tool_execution_end`, if the tool itself waits for the user.
   - A stable persisted state that proves a decision menu is being presented.

4. Do not mark every tool call as waiting. Most tools run without user attention.

5. Do not infer waiting from question marks in assistant text.

6. Add the smallest adapter to `extensions/pi-zellij-status.ts`.

7. Update `README.md` with:
   - package name and version
   - interaction covered
   - event, tool, or state used
   - cancellation and resolution behavior
   - known limitations

## Existing adapters

- Permission system:
  - `permissions:ui_prompt` starts waiting.
  - `permissions:decision` ends one permission wait.
- Ask-user-question:
  - `rpiv:ask-user:blocked` with `{ active: true }` starts waiting.
  - `{ active: false }` ends it.
- Plan mode:
  - `plan_mode_question` tool execution represents a model-generated question.
  - `plan-mode-state` with `awaitingAction: true` and a `latestPlan` represents the completed-plan decision menu after `agent_settled`.

The extension is intentionally pragmatic. It does not patch Pi core or monkey-patch `ctx.ui`.
