# Authentication and WSL

Required tools: Windows `powershell.exe`, WSL `wslpath`, Node.js, and existing Windows `MSAL.PS` for Graph. Stop and ask if missing; do not install automatically. Outlook COM additionally requires classic Outlook running in the same Windows user session. New Outlook has no equivalent COM object model.

Graph uses exported `MS_GRAPH_TENANT_ID` and `MS_GRAPH_CLIENT_ID`. The wrapper forwards them via `WSLENV`. Cache location and protection are inherited from `Enable-MsalTokenCacheOnDisk`; no cache reset or replacement app.

Silent acquisition only. On failure, stop and ask the user to refresh authentication. There is no interactive fallback, retry or cache deletion. Adding app scopes requires consent and subsequent acquisition of a token for the newly requested scopes. A granted scope does not override user access, tenant policies or endpoint constraints.

Use JSON files for Unicode text, quotes and body content; never interpolate user text into PowerShell source. The bridge supplies UTF-8 with BOM for request files and the entry point returns UTF-8 JSON. The process-scoped `-ExecutionPolicy Bypass` matches the existing Graph wrapper; it does not alter persistent machine policy. If organisational controls block execution, escalate rather than bypass additional controls.

Nonzero exits are failures even if stdout contains useful partial information. No automatic HTTP retries in the draft. Caller-approved safe read retries may follow `Retry-After`/bounded backoff; writes are never automatically retried. TLS inspection failures must be surfaced; do not disable certificate validation.
