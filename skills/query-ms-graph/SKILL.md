---
name: query-ms-graph
description: Query Microsoft Graph for Fractal employee details or resolve and download M365 sharing links. Not for email or calendar.
---

# Query Microsoft Graph

Execute via CLI:

```bash
query-ms-graph --name "Akhil Behl"
query-ms-graph --link "https://..." --output-dir "$PWD"
query-ms-graph --name "Akhil Behl" --link "https://..."

```

## Usage Guidelines

* **Name Search:** Query by full name when available (exact match). Partial names match `FirstName` fuzzily. Do not query by email.
* **Sharing Links & Paths:** Quote link URLs. `--output-dir` defaults to current working directory; pass Linux paths (auto-converted for Windows PowerShell).

## Auth & Execution Rules

* **Authentication:** Credentials are cached. On auth failure, **do not retry**; notify the user to refresh the auth cache.
* **Errors & Output:** Surface non-zero exit codes as errors. JSON/download results include pre-pended log lines.
* **Debugging:** Use `--debug` only for diagnosing failures. Log outputs to `/tmp/ms-graph-debug-<timestamp>.log`.
