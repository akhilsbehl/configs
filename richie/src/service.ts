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
body{margin:0;min-height:100vh;background:var(--base);color:var(--text);font:16px/1.6 system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;padding:24px 340px 56px}
#document{max-width:900px;margin:0 auto}
#toolbar{position:sticky;top:12px;display:flex;flex-wrap:wrap;gap:8px;max-width:900px;margin:0 auto 24px;padding:12px;background:var(--surface);border:1px solid var(--border);border-radius:12px;box-shadow:0 8px 24px rgba(87,82,121,.1);z-index:2}
.search-box{display:flex;align-items:center;gap:7px;margin-left:auto;font-size:.82rem;color:var(--subtle)}
.search-box span{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
.search-box input{width:190px;padding:7px 9px;border:1px solid var(--border);border-radius:7px;background:#fffaf3;color:var(--text);font:inherit;font-size:.9rem}
.search-box output{min-width:44px;color:var(--subtle);font-variant-numeric:tabular-nums}
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
dialog menu{display:flex;flex-direction:row-reverse;justify-content:flex-start;gap:8px;margin:18px 0 0;padding:0}
dialog [hidden]{display:none}
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
.hljs-comment,.hljs-quote{color:var(--muted);font-style:italic}
.hljs-keyword,.hljs-selector-tag,.hljs-built_in,.hljs-type{color:var(--love);font-weight:600}
.hljs-string,.hljs-attribute,.hljs-symbol,.hljs-bullet{color:var(--pine)}
.hljs-number,.hljs-literal,.hljs-variable,.hljs-template-variable{color:var(--gold)}
.hljs-title,.hljs-section,.hljs-function .hljs-title{color:var(--iris);font-weight:600}
.hljs-operator,.hljs-punctuation{color:var(--subtle)}
#panel,#navigation{position:fixed;top:82px;width:290px;max-height:calc(100vh - 104px);overflow:auto;padding:14px;background:var(--surface);border:1px solid var(--border);border-top:4px solid var(--rose);border-radius:10px;box-shadow:0 10px 30px rgba(87,82,121,.14);color:var(--text)}
#panel{right:20px}#navigation{left:20px;border-top-color:var(--foam)}
#panel strong{color:var(--pine)}
.panel-heading{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
#feedback-count{color:var(--subtle);font-size:.8rem}
#operations{margin-top:8px}
.operation-card{margin:8px 0;padding:9px;background:var(--overlay);border-radius:7px;font-size:.84rem;overflow-wrap:anywhere;border-left:3px solid var(--foam)}
.operation-card[data-kind=delete]{border-left-color:var(--love)}
.operation-card[data-kind=replace]{border-left-color:var(--gold)}
.operation-meta{display:flex;justify-content:space-between;gap:8px;color:var(--subtle);font-size:.76rem;text-transform:capitalize}
.operation-quote{display:block;margin:5px 0;color:var(--text);font-style:italic}
.operation-detail{margin:0;color:var(--text)}
.operation-actions{display:flex;gap:6px;margin-top:7px}
.operation-actions button{padding:4px 7px;font-size:.78rem}
.operation-actions button[data-action=remove-operation]{color:var(--love)}
#outline-items{margin-top:6px}
.outline-link{display:block;width:100%;padding:4px 6px;border:0;background:transparent;text-align:left;color:var(--subtle);font:inherit;font-size:.82rem;cursor:pointer;border-radius:4px}
.outline-link:hover{background:var(--overlay);color:var(--pine);transform:none}
.outline-link[data-depth="2"]{padding-left:16px}.outline-link[data-depth="3"]{padding-left:28px}
.review-target{outline:2px solid rgba(215,130,126,.55);outline-offset:3px;border-radius:3px}
.review-target[data-review-kind=delete]{background:rgba(180,99,122,.15);text-decoration:line-through;text-decoration-thickness:2px}
.review-target[data-review-kind=replace]{background:rgba(234,157,52,.18)}
.review-target[data-review-kind=comment]{background:rgba(86,148,159,.16)}
.review-column-target{outline:2px solid rgba(215,130,126,.55);outline-offset:-2px}
.review-column-target[data-review-kind=delete]{background:rgba(180,99,122,.15);text-decoration:line-through;text-decoration-thickness:2px}
.review-column-target[data-review-kind=replace]{background:rgba(234,157,52,.18)}
.review-column-target[data-review-kind=comment]{background:rgba(86,148,159,.16)}
.search-match{background:rgba(144,122,169,.28);border-radius:2px}
.search-current{background:rgba(234,157,52,.55)}
::highlight(richie-comment){background:rgba(86,148,159,.24);text-decoration:underline;text-decoration-color:var(--foam);text-decoration-thickness:2px}
::highlight(richie-replace){background:rgba(234,157,52,.28);text-decoration:underline;text-decoration-color:var(--gold);text-decoration-thickness:2px}
::highlight(richie-delete){background:rgba(180,99,122,.22);text-decoration:line-through;text-decoration-color:var(--love);text-decoration-thickness:2px}
::highlight(richie-search){background:rgba(144,122,169,.3)}
.richie-target-menu{display:none;position:fixed;gap:4px;padding:5px;background:var(--surface);border:1px solid var(--border);border-radius:8px;box-shadow:0 8px 22px rgba(87,82,121,.18);white-space:nowrap;z-index:10}
.richie-target-menu .richie-target{margin:0}
li:has(>input[type=checkbox])>p{display:inline}
li>input[type=checkbox]{margin:0 7px 0 0;vertical-align:.05em}
.richie-hover{outline:1px dashed var(--rose);outline-offset:3px;border-radius:3px}
#stale-banner{position:sticky;top:0;z-index:3;max-width:900px;margin:0 auto 16px;padding:10px 14px;background:var(--love);color:#fffaf3;border-radius:8px;font-size:.92rem}
.review-note{color:var(--love);font-size:.9em}
@media(max-width:1300px){body{padding:16px}#panel,#navigation{position:static;width:auto;max-height:none;margin:0 auto 20px;max-width:900px}#toolbar{top:8px}.search-box{margin-left:0}.search-box input{width:min(190px,50vw)}}
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
    const api = url.pathname.match(/^\/api\/(state|operations|finish|abort)\/([^/]+)(?:\/([^/]+))?$/);
    if (url.pathname.startsWith("/assets/")) {
      const asset = url.pathname.slice("/assets/".length);
      if (!/^[A-Za-z0-9._-]+\.js$/.test(asset)) return send(response, 404, { error: "Asset not found" });
      return send(response, 200, await readFile(join(publicDirectory, asset), "utf8"), "text/javascript");
    }
    if (match && request.method === "GET") {
      const session = this.session(match[1], url.searchParams.get("token")); if (!session) return send(response, 404, { error: "Session not found" });
      const source = await readFile(session.sourcePath, "utf8");
      const stale = sha256(source) !== session.state.sourceSha256;
      const banner = stale ? `<div id="stale-banner">The Markdown source changed after this review started. Highlights may be misaligned and new feedback is blocked. Restore the source or abort the review.</div>` : "";
      const page = `<!doctype html><meta charset="utf-8"><title>Richie: ${session.sourcePath}</title><style>${style}</style>${banner}<div id="toolbar"><button data-action="document-note">Document level note</button><button data-action="abort">Abort review</button><label class="search-box"><span>Find in document</span><input id="document-search" type="search" placeholder="Search…" autocomplete="off"><output id="search-count" aria-live="polite"></output></label><button data-action="finish">Finish review</button></div><aside id="navigation"><nav id="outline" aria-label="Document outline"><strong>Document outline</strong><div id="outline-items"></div></nav></aside><aside id="panel"><div class="panel-heading"><strong>Review feedback</strong><span id="feedback-count" aria-live="polite">0 open</span></div><div id="operations"></div></aside><main id="document">${renderReviewHtml(source)}</main><dialog id="richie-dialog"><form method="dialog"><h2 id="richie-dialog-title"></h2><p id="richie-dialog-message"></p><label id="richie-dialog-field"><span></span><textarea id="richie-dialog-input"></textarea></label><menu><button value="confirm">Confirm</button><button value="cancel">Cancel</button></menu></form></dialog><script>window.__RICHIE__=${JSON.stringify({ id: session.id, token: session.token })}</script><script type="module" src="/assets/client.js"></script>`;
      return send(response, 200, page, "text/html");
    }
    if (!api) return send(response, 404, { error: "Not found" });
    const session = this.session(api[2], url.searchParams.get("token")); if (!session) return send(response, 404, { error: "Session not found" });
    if (api[1] === "state" && request.method === "GET") return send(response, 200, session.state);
    if (api[1] === "operations" && request.method === "DELETE" && api[3]) {
      const operation = session.state.operations.find((candidate) => candidate.id === api[3]);
      if (!operation) return send(response, 404, { error: "Review operation not found" });
      if (operation.status !== "open") return send(response, 409, { error: "Only open feedback can be removed" });
      operation.status = "superseded"; operation.updatedAt = new Date().toISOString();
      await writeState(session.sidecarPath, session.state); return send(response, 200, operation);
    }
    if (api[1] === "operations" && request.method === "PATCH" && api[3]) {
      const operation = session.state.operations.find((candidate) => candidate.id === api[3]);
      if (!operation) return send(response, 404, { error: "Review operation not found" });
      if (operation.status !== "open") return send(response, 409, { error: "Only open feedback can be edited" });
      const input = await body(request) as Record<string, unknown>;
      if (operation.kind === "comment" && typeof input.comment === "string" && input.comment.trim()) operation.comment = input.comment;
      else if (operation.kind === "replace" && typeof input.replacement === "string" && input.replacement.trim()) operation.replacement = input.replacement;
      else return send(response, 400, { error: "Nothing to update for this operation" });
      operation.updatedAt = new Date().toISOString();
      await writeState(session.sidecarPath, session.state); return send(response, 200, operation);
    }
    if (api[1] === "operations" && request.method === "POST") {
      const input = await body(request) as Record<string, unknown>; const range = parseRange(input.range);
      const source = await readFile(session.sourcePath, "utf8");
      if (sha256(source) !== session.state.sourceSha256) return send(response, 409, { error: "The Markdown source changed during the review. Restore the source or abort the review." });
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
