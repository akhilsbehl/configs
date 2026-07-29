import { createServer, request as httpRequest, type IncomingMessage, type ServerResponse } from "node:http";
import { chmod, mkdir, readFile, rm, realpath, unlink, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { assertMarkdownFile, hasOpenOperations, newState, nextCommentedPath, readState, renderCommentedMarkdown, reviewSidecarPath, sha256, writeState } from "./store.js";
import { renderReviewHtml } from "./render.js";
import type { ReviewOperation, ReviewState, Session } from "./types.js";

const port = Number(process.env.RICHIE_HTTP_PORT ?? 43173);
const socket = process.env.RICHIE_CONTROL_SOCKET ?? "/run/richie/control.sock";
const here = dirname(fileURLToPath(import.meta.url));
const publicDirectory = resolve(here, "..", "public");
const style = `
:root{color-scheme:light;--base:#faf4ed;--surface:#fffaf3;--overlay:#f2e9de;--muted:#9893a5;--subtle:#797593;--text:#575279;--pine:#286983;--foam:#56949f;--rose:#d7827e;--love:#b4637a;--gold:#ea9d34;--iris:#907aa9;--border:#dfd6cc}
*{box-sizing:border-box}
body{margin:0;min-height:100vh;background:var(--base);color:var(--text);font:16px/1.6 system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;padding:24px 340px 56px 24px}
#document{max-width:900px;margin:0 auto}
#toolbar{position:sticky;top:12px;display:flex;flex-wrap:wrap;gap:8px;max-width:900px;margin:0 auto 24px;padding:12px;background:var(--surface);border:1px solid var(--border);border-radius:12px;box-shadow:0 8px 24px rgba(87,82,121,.1);z-index:2}
button{padding:7px 11px;border:1px solid var(--border);border-radius:7px;background:var(--overlay);color:var(--text);font:inherit;font-size:.9rem;cursor:pointer;transition:background .15s ease,border-color .15s ease,transform .15s ease}
button:hover{background:#eadfd2;border-color:var(--rose);transform:translateY(-1px)}
button:focus-visible{outline:3px solid rgba(144,122,169,.35);outline-offset:2px}
dialog{width:min(520px,calc(100vw - 32px));padding:0;border:1px solid var(--border);border-radius:12px;background:var(--surface);color:var(--text);box-shadow:0 18px 60px rgba(87,82,121,.28)}
dialog::backdrop{background:rgba(40,34,56,.38)}
dialog form{padding:20px}
dialog h2{margin:0 0 8px;font-size:1.25rem}
dialog p{margin:0 0 16px;white-space:pre-wrap}
dialog label{display:grid;gap:6px;margin:14px 0}
dialog textarea{width:100%;min-height:110px;resize:vertical;padding:9px 11px;border:1px solid var(--border);border-radius:7px;background:#fff;color:var(--text);font:inherit}
dialog menu{display:flex;justify-content:flex-end;gap:8px;margin:18px 0 0;padding:0}
dialog button[value=confirm]{background:var(--pine);border-color:var(--pine);color:#fffaf3}
dialog button.destructive{background:var(--love);border-color:var(--love)}
#toolbar button[data-action=finish]{background:var(--pine);border-color:var(--pine);color:#fffaf3}
#toolbar button[data-action=finish]:hover{background:#20556a}
#toolbar button[data-action=abort]{background:var(--love);border-color:var(--love);color:#fffaf3}
#toolbar button[data-action=abort]:hover{background:#9f5369}
h1,h2,h3{color:var(--text);line-height:1.2;letter-spacing:-.02em}
h1{font-size:2.2rem;margin:1.4em 0 .55em;padding-bottom:.25em;border-bottom:2px solid var(--rose)}
h2{font-size:1.55rem;margin-top:1.8em;color:var(--pine)}
h3{font-size:1.2rem;color:var(--iris)}
a{color:var(--pine);text-decoration-thickness:1.5px;text-underline-offset:3px}
a:hover{color:var(--love)}
blockquote{margin:1.4em 0;padding:12px 18px;background:var(--surface);border-left:4px solid var(--rose);border-radius:0 8px 8px 0;color:var(--subtle)}
hr{border:0;border-top:1px solid var(--border);margin:2.2rem 0}
table{width:100%;border-collapse:separate;border-spacing:0;overflow:hidden;margin:1.4rem 0;background:var(--surface);border:1px solid var(--border);border-radius:10px;box-shadow:0 5px 16px rgba(87,82,121,.06)}
td{padding:10px 13px;border-top:1px solid var(--border);vertical-align:top}
tr:first-child td{background:var(--pine);border-top:0;color:#fffaf3;font-weight:700}
tr:nth-child(odd):not(:first-child) td{background:var(--surface)}
tr:nth-child(even) td{background:var(--overlay)}
tr:hover td{background:#f0d9d2}
pre{overflow:auto;margin:1.2rem 0;padding:16px 18px;background:var(--overlay);border:1px solid var(--border);border-left:4px solid var(--iris);border-radius:9px;color:var(--text);font:14px/1.6 ui-monospace,SFMono-Regular,Menlo,Consolas,"Liberation Mono",monospace;box-shadow:0 4px 14px rgba(87,82,121,.05)}
code{font:0.92em ui-monospace,SFMono-Regular,Menlo,Consolas,"Liberation Mono",monospace}
:not(pre)>code{padding:2px 5px;background:var(--overlay);border-radius:4px;color:var(--love)}
.mermaid{overflow:auto;margin:1.5rem 0 0;padding:18px;background:var(--surface);border:1px solid var(--border);border-radius:10px;box-shadow:0 5px 16px rgba(87,82,121,.06)}
.mermaid svg{display:block;max-width:100%;height:auto;margin:auto}
.mermaid-source{margin:0 0 1.5rem;padding:0;background:var(--surface);border:1px solid var(--border);border-top:0;border-radius:0 0 10px 10px;overflow:hidden}
.mermaid-source summary{padding:9px 14px;background:var(--overlay);color:var(--pine);font-weight:700;cursor:pointer;user-select:none}
.mermaid-source summary:hover{background:#eadfd2}
.mermaid-source pre{margin:0;border:0;border-radius:0;box-shadow:none}
.mermaid-source-line,.code-source-line{display:block;min-height:1.6em}
.mermaid-source-line:hover,.code-source-line:hover{background:rgba(215,130,126,.18)}
#panel{position:fixed;right:20px;top:82px;width:290px;max-height:calc(100vh - 104px);overflow:auto;padding:14px;background:var(--surface);border:1px solid var(--border);border-top:4px solid var(--rose);border-radius:10px;box-shadow:0 10px 30px rgba(87,82,121,.14);color:var(--text)}
#panel strong{color:var(--pine)}
#operations p{margin:10px 0;padding:8px;background:var(--overlay);border-radius:6px;font-size:.86rem;overflow-wrap:anywhere}
.richie-target-menu{display:none;position:fixed;gap:4px;padding:5px;background:var(--surface);border:1px solid var(--border);border-radius:8px;box-shadow:0 8px 22px rgba(87,82,121,.18);white-space:nowrap;z-index:10}
.richie-target-menu .richie-target{margin:0}
li:has(>input[type=checkbox])>p{display:inline}
li>input[type=checkbox]{margin:0 7px 0 0;vertical-align:.05em}
p:hover,h1:hover,h2:hover,h3:hover,td:hover,details:hover{outline:1px dashed var(--rose);outline-offset:3px}
.review-note{color:var(--love);font-size:.9em}
@media(max-width:1000px){body{padding:16px}#panel{position:static;width:auto;max-height:none;margin:0 auto 20px;max-width:900px}#toolbar{top:8px}}
`;

function send(response: ServerResponse, code: number, value: unknown, contentType = "application/json"): void {
  response.writeHead(code, { "content-type": contentType, "cache-control": "no-store" });
  response.end(contentType === "application/json" ? JSON.stringify(value) : String(value));
}
async function body(request: IncomingMessage): Promise<unknown> {
  let output = ""; for await (const chunk of request) output += chunk; return output ? JSON.parse(output) : {};
}
function parseRange(value: unknown): ReviewOperation["range"] | undefined {
  if (!value || typeof value !== "object") return undefined;
  const candidate = value as { start?: { offset?: number; line?: number; column?: number }; end?: { offset?: number; line?: number; column?: number } };
  if (typeof candidate.start?.offset !== "number" || typeof candidate.end?.offset !== "number") return undefined;
  return { start: { offset: candidate.start.offset, line: candidate.start.line ?? 0, column: candidate.start.column ?? 0 }, end: { offset: candidate.end.offset, line: candidate.end.line ?? 0, column: candidate.end.column ?? 0 } };
}

export class RichieService {
  private readonly sessions = new Map<string, Session>();
  private readonly byPath = new Map<string, string>();

  status(): { sessions: number; port: number } { return { sessions: this.sessions.size, port }; }

  async createSession(inputPath: string): Promise<{ id: string; url: string }> {
    const sourcePath = await realpath(inputPath);
    const existing = this.byPath.get(sourcePath);
    if (existing) { const session = this.sessions.get(existing)!; return { id: session.id, url: this.url(session) }; }
    const source = await assertMarkdownFile(sourcePath);
    const sidecarPath = reviewSidecarPath(sourcePath);
    const state = (await readState(sidecarPath)) ?? newState(sourcePath, source);
    if (state.sourceSha256 !== sha256(source)) throw new Error("The existing review sidecar targets a different source version. Finish or remove it before starting a new review.");
    const session: Session = { id: randomUUID(), token: randomUUID(), sourcePath, sidecarPath, state };
    this.sessions.set(session.id, session); this.byPath.set(sourcePath, session.id);
    await writeState(sidecarPath, state);
    return { id: session.id, url: this.url(session) };
  }
  private url(session: Session): string { return `http://127.0.0.1:${port}/s/${session.id}?token=${session.token}`; }
  private session(id: string, token: string | null): Session | undefined { const value = this.sessions.get(id); return value?.token === token ? value : undefined; }
  async handle(request: IncomingMessage, response: ServerResponse): Promise<void> {
    const host = request.headers.host ?? "";
    if (host !== `127.0.0.1:${port}` && host !== `localhost:${port}`) return send(response, 421, { error: "Unexpected host" });
    const url = new URL(request.url ?? "/", `http://${host}`); const match = url.pathname.match(/^\/s\/([^/]+)$/);
    const api = url.pathname.match(/^\/api\/(state|operations|finish|abort)\/([^/]+)$/);
    if (url.pathname.startsWith("/assets/")) {
      const asset = url.pathname.slice("/assets/".length);
      if (!/^[A-Za-z0-9._-]+\.js$/.test(asset)) return send(response, 404, { error: "Asset not found" });
      return send(response, 200, await readFile(join(publicDirectory, asset), "utf8"), "text/javascript");
    }
    if (match && request.method === "GET") {
      const session = this.session(match[1], url.searchParams.get("token")); if (!session) return send(response, 404, { error: "Session not found" });
      const source = await readFile(session.sourcePath, "utf8");
      const page = `<!doctype html><meta charset="utf-8"><title>Richie: ${session.sourcePath}</title><style>${style}</style><div id="toolbar"><button data-action="document-note">Document level note</button><button data-action="abort">Abort review</button><button data-action="finish">Finish review</button></div><aside id="panel"><strong>Open feedback</strong><div id="operations"></div></aside><main id="document">${renderReviewHtml(source)}</main><dialog id="richie-dialog"><form method="dialog"><h2 id="richie-dialog-title"></h2><p id="richie-dialog-message"></p><label id="richie-dialog-field"><span></span><textarea id="richie-dialog-input"></textarea></label><menu><button value="cancel">Cancel</button><button value="confirm">Confirm</button></menu></form></dialog><script>window.__RICHIE__=${JSON.stringify({ id: session.id, token: session.token })}</script><script type="module" src="/assets/client.js"></script>`;
      return send(response, 200, page, "text/html");
    }
    if (!api) return send(response, 404, { error: "Not found" });
    const session = this.session(api[2], url.searchParams.get("token")); if (!session) return send(response, 404, { error: "Session not found" });
    if (api[1] === "state" && request.method === "GET") return send(response, 200, session.state);
    if (api[1] === "operations" && request.method === "POST") {
      const input = await body(request) as Record<string, unknown>; const range = parseRange(input.range);
      const source = await readFile(session.sourcePath, "utf8");
      if (range && (range.start.offset < 0 || range.end.offset > source.length || range.start.offset >= range.end.offset)) return send(response, 400, { error: "Invalid source range" });
      const kind = input.kind; if (kind !== "delete" && kind !== "replace" && kind !== "comment") return send(response, 400, { error: "Invalid operation kind" });
      const scope = typeof input.scope === "string" ? input.scope : "range";
      const operation: ReviewOperation = { id: `rvw_${String(session.state.operations.length + 1).padStart(3, "0")}`, kind, status: "open", scope: scope as ReviewOperation["scope"], range, quote: range ? source.slice(range.start.offset, range.end.offset) : undefined, replacement: typeof input.replacement === "string" ? input.replacement : undefined, comment: typeof input.comment === "string" ? input.comment : undefined, placement: input.placement === "start" || input.placement === "end" ? input.placement : undefined, createdAt: new Date().toISOString() };
      session.state.operations.push(operation); await writeState(session.sidecarPath, session.state); return send(response, 201, operation);
    }
    if (api[1] === "finish" && request.method === "POST") {
      const source = await readFile(session.sourcePath, "utf8"); if (sha256(source) !== session.state.sourceSha256) return send(response, 409, { error: "Source changed during review; feedback was retained." });
      if (!hasOpenOperations(session.state)) {
        await unlink(session.sidecarPath);
        this.sessions.delete(session.id); this.byPath.delete(session.sourcePath);
        return send(response, 200, { exported: false, outputPath: null });
      }
      const outputPath = await nextCommentedPath(session.sourcePath); await writeFile(outputPath, renderCommentedMarkdown(source, session.state), "utf8"); await unlink(session.sidecarPath);
      this.sessions.delete(session.id); this.byPath.delete(session.sourcePath); return send(response, 200, { exported: true, outputPath });
    }
    if (api[1] === "abort" && request.method === "POST") {
      await unlink(session.sidecarPath);
      this.sessions.delete(session.id); this.byPath.delete(session.sourcePath);
      return send(response, 200, { aborted: true });
    }
    return send(response, 405, { error: "Method not allowed" });
  }
}

export async function startService(): Promise<void> {
  await mkdir(dirname(socket), { recursive: true }); await rm(socket, { force: true });
  const service = new RichieService();
  const web = createServer((request, response) => service.handle(request, response).catch((error: Error) => send(response, 500, { error: error.message })));
  const control = createServer((request, response) => {
    if (request.method === "GET" && request.url === "/status") return send(response, 200, service.status());
    if (request.method !== "POST" || request.url !== "/sessions") return send(response, 404, { error: "Not found" });
    body(request).then(async (input) => { const sourcePath = (input as { sourcePath?: unknown }).sourcePath; if (typeof sourcePath !== "string") return send(response, 400, { error: "sourcePath is required" }); return send(response, 201, await service.createSession(sourcePath)); }).catch((error: Error) => send(response, 400, { error: error.message }));
  });
  await new Promise<void>((resolvePromise) => web.listen(port, "127.0.0.1", resolvePromise));
  await new Promise<void>((resolvePromise) => control.listen(socket, resolvePromise)); await chmod(socket, 0o600);
  process.on("SIGTERM", () => { web.close(); control.close(); });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) startService().catch((error: Error) => { console.error(error.message); process.exitCode = 1; });
