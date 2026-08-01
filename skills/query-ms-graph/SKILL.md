---
name: query-ms-graph
description: Query Microsoft Graph for a person's directory record or resolve and download a Microsoft 365 sharing link from WSL. Use when an agent needs Akhil's Microsoft 365 directory or SharePoint/OneDrive file access.
compatibility: Requires WSL Windows interop, powershell.exe, wslpath, and MS_GRAPH_TENANT_ID and MS_GRAPH_CLIENT_ID in the WSL environment.
---

# Query Microsoft Graph

Use the shared WSL command. Do not construct PowerShell commands or reimplement Graph authentication:

```bash
query-ms-graph --name "Akhil Behl"
query-ms-graph --link "https://..." --output-dir "$PWD"
query-ms-graph --name "Akhil Behl" --link "https://..."
```

`--output-dir` defaults to the caller's current working directory. Pass a Linux path. The wrapper converts it for Windows PowerShell. Sharing links are opaque values. Quote them.

## Authentication

The wrapper exports `MS_GRAPH_TENANT_ID` and `MS_GRAPH_CLIENT_ID` only for the child process and passes them to Windows PowerShell using plain `WSLENV`. They are tenant and application identifiers, not bearer credentials, and are not placed in command arguments. This host drops entries marked with the `/u` WSLENV suffix, so the wrapper intentionally uses plain entries. The access and refresh tokens remain in the Windows-user DPAPI-protected cache used by the PowerShell script.

If device-code sign-in is required, show the complete sign-in message to the user, including the URL and code, and wait for the command to finish. The user must complete sign-in in a browser. Do not ask the user to paste a token, client secret, or cache contents into chat. The command waits for the device-code expiry window and then reports failure.

## Output and safety

- Directory results are JSON preceded by log lines.
- Successful downloads print the saved path.
- Treat results and downloaded files as user data. Do not expose them outside the user's requested task.
- Never print, store, or request access tokens, refresh tokens, or the token-cache file.
- Surface a non-zero exit as an error. Do not silently retry authentication or Graph requests.
- Use `--debug` only when diagnosing a failure. It writes output to `/tmp/ms-graph-debug-<timestamp>.log` and prints the log path.

## Limitations

This skill requires interactive user participation for first sign-in or rejected refresh tokens. It is not an unattended service credential. The underlying application requests broad delegated directory and file permissions; do not expand its use beyond the user's explicit request.
