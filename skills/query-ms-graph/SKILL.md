---
name: query-ms-graph
description: Use to Query Microsoft Graph when needing a Fractal employee's details or resolve and download a Microsoft 365 sharing link. Don't use for email, calendar, etc.
---

# Query Microsoft Graph

Use `query-ms-graph` which should be in path:

```bash
query-ms-graph --name "Akhil Behl"
query-ms-graph --link "https://..." --output-dir "$PWD"
query-ms-graph --name "Akhil Behl" --link "https://..."
```

Good to know:
* Query by name - not email.
  * Use full name if available
  * Full name if matched will find the exact person (or multiple matches if available)
  * Partial name matches FirstName and returns all names that match (fuzzy).
* `--output-dir` defaults to the caller's current working directory.
  * Pass a Linux path. The wrapper converts it for Windows PowerShell. Sharing links are opaque values. Quote them.

## Authentication

The credentials should be cached but if auth fails, do not reattempt and just inform me to refresh auth cache.

## Output and safety

- Directory results are JSON preceded by log lines.
- Successful downloads print the saved path.
- Surface a non-zero exit as an error. Do not silently retry authentication or Graph requests.
- Use `--debug` only when diagnosing a failure. It writes output to `/tmp/ms-graph-debug-<timestamp>.log` and prints the log path.
