import { createServer, request as httpRequest, type IncomingMessage, type ServerResponse } from "node:http";
import { chmod, mkdir, readFile, rm, realpath, unlink, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { assertMarkdownFile, newState, nextCommentedPath, readState, renderCommentedMarkdown, reviewSidecarPath, sha256, writeState } from "./store.js";
import { renderReviewHtml } from "./render.js";
import type { ReviewOperation, ReviewState, Session } from "./types.js";

const port = Number(process.env.RICHIE_HTTP_PORT ?? 43173);
const socket = process.env.RICHIE_CONTROL_SOCKET ?? "/run/richie/control.sock";
const here = dirname(fileURLToPath(import.meta.url));
const publicDirectory = resolve(here, "..", "public");
const style = `body{font:16px/1.55 system-ui,sans-serif;color:#18212b;max-width:1040px;margin:0 auto;padding:24px}main{max-width:780px}#toolbar{position:sticky;top:8px;background:#18212b;color:white;padding:10px;border-radius:7px;display:flex;gap:8px;z-index:2}button{padding:6px 10px;border:0;border-radius:4px;cursor:pointer}#panel{position:fixed;right:18px;top:70px;width:250px;background:#f5f7f9;padding:12px;border-radius:7px}p:hover,h1:hover,h2:hover,h3:hover,td:hover{outline:1px dashed #a8b3be}.richie-target{display:none;margin-left:8px;font-size:.72rem}p:hover>.richie-target,h1:hover>.richie-target,h2:hover>.richie-target,h3:hover>.richie-target,li:hover>.richie-target,td:hover>.richie-target,tr:hover>.richie-target{display:inline}.mermaid{overflow:auto}.review-note{color:#7b341e;font-size:.9em}`;

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
    const api = url.pathname.match(/^\/api\/(state|operations|finish)\/([^/]+)$/);
    if (url.pathname.startsWith("/assets/")) {
      const asset = url.pathname.slice("/assets/".length);
      if (!/^[A-Za-z0-9._-]+\.js$/.test(asset)) return send(response, 404, { error: "Asset not found" });
      return send(response, 200, await readFile(join(publicDirectory, asset), "utf8"), "text/javascript");
    }
    if (match && request.method === "GET") {
      const session = this.session(match[1], url.searchParams.get("token")); if (!session) return send(response, 404, { error: "Session not found" });
      const source = await readFile(session.sourcePath, "utf8");
      const page = `<!doctype html><meta charset="utf-8"><title>Richie: ${session.sourcePath}</title><style>${style}</style><div id="toolbar"><button data-action="delete">Delete</button><button data-action="replace">Replace</button><button data-action="comment">Comment</button><button data-action="opening">Opening note</button><button data-action="closing">Closing note</button><button data-action="finish">Finish review</button></div><aside id="panel"><strong>Open feedback</strong><div id="operations"></div></aside><main id="document">${renderReviewHtml(source)}</main><script>window.__RICHIE__=${JSON.stringify({ id: session.id, token: session.token })}</script><script type="module" src="/assets/client.js"></script>`;
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
      const outputPath = await nextCommentedPath(session.sourcePath); await writeFile(outputPath, renderCommentedMarkdown(source, session.state), "utf8"); await unlink(session.sidecarPath);
      this.sessions.delete(session.id); this.byPath.delete(session.sourcePath); return send(response, 200, { outputPath });
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
