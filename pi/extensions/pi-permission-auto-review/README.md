# @mzwing/pi-permission-auto-review

[![npm version](https://img.shields.io/npm/v/@mzwing/pi-permission-auto-review?style=flat&logo=npm&logoColor=white)](https://www.npmjs.com/package/@mzwing/pi-permission-auto-review) [![CI](https://img.shields.io/github/actions/workflow/status/mzwing/pi-packages/release.yml?style=flat&logo=github&label=CI)](https://github.com/mzwing/pi-packages/actions/workflows/release.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://opensource.org/licenses/MIT) [![TypeScript](https://img.shields.io/badge/TypeScript-7.x-3178C6?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/) [![Pi Package](https://img.shields.io/badge/Pi-Package-6366F1?style=flat)](https://github.com/earendil-works/pi)

A [Pi](https://github.com/earendil-works/pi) extension that adds Codex-style automatic permission reviews to [`@gotgenes/pi-permission-system`](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system).

## Differences between `@gotgenes/pi-permission-model-judge`

[@gotgenes/pi-permission-model-judge](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-model-judge) is a general-purpose model-based authorizer that can be used to evaluate any permission request.

Ours is mostly specialized for OpenAI's `codex-auto-review` model, which is trained to evaluate permission requests in the context of a coding assistant. Our extension aims at providing Codex-style automatic permission reviews for Pi's coding agent.

## Install

```bash
pi install npm:@gotgenes/pi-permission-system # dependency
pi install npm:@mzwing/pi-permission-auto-review
```

Pi 0.80.10 and Pi 0.81.x are supported. The extension uses `@mzwing/pi-polyfill` transitively for provider lookup on Pi 0.80.10; do not install the polyfill as a separate Pi extension.

## Enable

Add `"auto-review"` to pi-permission-system's config:

```json
{
  "authorizerChain": ["auto-review"]
}
```

The config is normally located at `~/.pi/agent/extensions/pi-permission-system/config.json`.

Extension config can be omitted. The defaults are:

```json
{
  "provider": "openai-codex",
  "model": "codex-auto-review",
  "reasoning": "low",
  "timeoutMs": 90000,
  "includeBaselinePolicy": true
}
```

`codex-auto-review` is an official hidden model. The extension derives it from Pi's `openai-codex` provider and reuses the existing Codex login.

## Configuration

| Scope   | Path                                                           |
| ------- | -------------------------------------------------------------- |
| Global  | `~/.pi/agent/extensions/pi-permission-auto-review/config.json` |
| Project | `<cwd>/.pi/extensions/pi-permission-auto-review/config.json`   |

Project fields override global fields. `PI_CODING_AGENT_DIR` replaces `~/.pi/agent` when set.

| Field                   | Default             | Description                                  |
| ----------------------- | ------------------- | -------------------------------------------- |
| `provider`              | `openai-codex`      | Pi model-registry provider id                |
| `model`                 | `codex-auto-review` | Model id within the selected provider        |
| `reasoning`             | `low`               | Reasoning level for reviewer calls           |
| `timeoutMs`             | `90000`             | Total budget across all retry attempts       |
| `includeBaselinePolicy` | `true`              | Include the built-in Codex-style risk policy |
| `additionalPolicy`      | omitted             | Trusted operator policy appended to it       |

See the [example config](config/config.example.json) and bundled [JSON Schema](schemas/config.schema.json). Unknown or invalid fields disable automatic decisions and fall through to the normal prompt.

Use `/permission-auto-review` in Pi's interactive TUI to edit and apply global or project config without reloading the session. Available subcommands:

```text
/permission-auto-review show
/permission-auto-review path
/permission-auto-review reset [global|project]
/permission-auto-review help
```

Custom providers and models must be defined in Pi's `~/.pi/agent/models.json`, then selected with this extension's `provider` and `model` fields. To replace the built-in risk policy completely, set `includeBaselinePolicy` to `false` and provide a non-empty `additionalPolicy`.

## Behavior and Limits

- Model, authentication, timeout, provider, or response-format failures defer to the normal human prompt.
- Unexpected internal review failures also defer to the human prompt instead of escaping into the permission gate.
- Three consecutive denials, or ten denials in the latest fifty reviews, open a circuit breaker until the next Pi turn.
- pi-permission-system prevents authorizers from auto-approving `path` and `external_directory` requests.

## License

[MIT](LICENSE)
