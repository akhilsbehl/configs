# Jina Extension: Current Design Limitations

## Context

The extension is installed and exposes Jina functionality through Pi commands. The relevant implementation is in `index.ts`.

## Observations

### 1. Jina is exposed as a command, not an agent-callable tool

The extension registers:

- `/jina-read`
- `/jina-search`
- `/jina-deepsearch`

These use `pi.registerCommand(...)`. They are available in the interactive Pi interface, but they do not appear in the model's tool namespace. An agent therefore cannot call them through a normal tool invocation.

### 2. The agent had to bypass the extension

Because the command was not directly callable, the search was run with `curl` against the Jina API using the configured `JINA_API_KEY`. This duplicates logic already present in the extension and means the agent is not actually using the installed command implementation.

### 3. The command result is published as UI-oriented content

Results are sent with `pi.sendMessage(...)` as a custom `jina-result` message and rendered for display. This is suitable for a human-facing TUI, but it is not a strongly structured response for downstream agent reasoning.

### 4. Results are truncated

`MAX_OUTPUT` is set to 50,000 characters. Truncation is sensible for the UI, but the current design does not expose pagination, a saved artifact, or a machine-readable indication that the result is incomplete beyond the appended text marker.

### 5. Search, Reader, and DeepSearch have separate implementations

The extension contains separate functions for the three Jina APIs. This is readable, but shared concerns such as authentication, request handling, error formatting, response limits, and observability are not fully abstracted.

### 6. Search output is not normalized

The command returns Jina's Markdown response directly. The agent receives no stable schema for results, sources, titles, URLs, snippets, citations, or confidence. This makes it harder to combine Jina results with other search providers.

### 7. Interactive and programmatic use cases are coupled

The command handler performs the API operation, publishes a UI message, and sends a notification. There is no clearly separated reusable service layer that can be called by both a Pi command and an agent tool.

## Better design

### Recommended architecture

Separate the extension into three layers:

1. **Jina client layer**
   - Implements Reader, Search, and DeepSearch API calls.
   - Owns authentication, request construction, timeouts, retries, and API error handling.
   - Returns typed data or an explicit typed error.

2. **Agent tool layer**
   - Registers `jina_search`, `jina_read`, and `jina_deepsearch` as model-callable tools using the Pi extension tool API.
   - Returns structured, bounded results suitable for model reasoning.
   - Includes source URLs and an explicit `truncated` field where relevant.

3. **Interactive command layer**
   - Keeps `/jina-search`, `/jina-read`, and `/jina-deepsearch` for human use.
   - Calls the same client layer.
   - Formats the structured response for TUI display.

### Suggested tool response schema

```ts
type JinaSearchResult = {
  query: string;
  answer?: string;
  results: Array<{
    title?: string;
    url: string;
    snippet?: string;
    content?: string;
  }>;
  truncated: boolean;
};
```

Reader and DeepSearch should have equivalent schemas rather than returning arbitrary text only.

### Additional improvements

- Add request timeouts using `AbortController`.
- Centralize API-key validation and HTTP error handling.
- Avoid duplicating the API call through shell commands or `curl`.
- Make output limits configurable per operation.
- Preserve full results in an optional file or artifact when output is truncated.
- Return citations as structured URLs, not only embedded Markdown links.
- Add clear tool descriptions so the model knows when to use Search, Reader, or DeepSearch.
- Keep UI notifications in the command layer, not the client layer.
- Add integration tests against the real Jina API where credentials are available, with a small number of deterministic smoke tests.
- Avoid logging API keys or full sensitive source content.

## Priority order

1. Add model-callable tools backed by the existing API functions.
2. Extract a shared Jina client layer used by both commands and tools.
3. Introduce structured response schemas and explicit truncation metadata.
4. Add timeout, error, and citation handling.
5. Improve testing and optional artifact storage.

## Timeout configuration

The extension uses separate timeout settings for short Jina requests and DeepSearch:

| Setting | Default | Applies to |
|---|---:|---|
| `JINA_REQUEST_TIMEOUT_MS` | `120000` (2 minutes) | Reader and Search |
| `JINA_DEEPSEARCH_TIMEOUT_MS` | `900000` (15 minutes) | DeepSearch total request duration |
| `JINA_DEEPSEARCH_IDLE_TIMEOUT_MS` | `300000` (5 minutes) | DeepSearch time without receiving stream data |

Values must be positive integer milliseconds. Invalid explicitly supplied values fail with a configuration error rather than silently using a default. The caller's Pi cancellation signal remains separate from timeout failures.

DeepSearch keeps `stream: true`, as recommended by Jina for long-running requests. The client now consumes the response body progressively and resets the idle timer whenever a chunk arrives. The total timeout remains the hard upper bound. An upstream HTTP error, such as 504 or 524, is reported separately from a local total or idle timeout. DeepSearch is not retried automatically because retries can duplicate expensive work.

For unusually complex research, an operator can raise `JINA_DEEPSEARCH_TIMEOUT_MS`, but 30 minutes should be treated as a practical maximum rather than a default. The source and installed extension copies must remain synchronized when reinstalling the extension.

## Design principle

Commands are for humans. Tools are for agents. The extension should expose both interfaces over the same underlying Jina client rather than using the command interface as a proxy for agent access.
