import assert from "node:assert/strict";
import { createServer, request, type IncomingHttpHeaders } from "node:http";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { RichieService, renderReviewPage } from "../src/service.js";

test("renders a compact accessible breadcrumb for the reviewed file", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/client notes/draft-v00.md" }, "# Draft\n");
  assert.match(html, /<nav id="file-breadcrumb" aria-label="File path" title="\/work\/client notes\/draft-v00\.md"><ol><li><span>\/<\/span>/);
  assert.match(html, /<li><span>work<\/span><\/li><li><span>client notes<\/span><\/li><li aria-current="page"><span>draft-v00\.md<\/span><\/li>/);
  assert.match(html, /<button class="copy-path" type="button" data-copy-source="\/work\/client notes\/draft-v00\.md" data-copy-label="Copy file path" aria-label="Copy file path" title="Copy file path"><svg/);
  assert.match(html, /#file-breadcrumb\{display:flex;align-items:center;gap:8px;margin:0 0 22px/);
  assert.match(html, /#file-breadcrumb \.copy-path\{flex:none;width:28px;height:28px/);
});

test("escapes reviewed file paths in breadcrumb markup", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/a&b/<draft>.md" }, "# Draft\n");
  assert.match(html, /title="\/work\/a&amp;b\/&lt;draft&gt;\.md"/);
  assert.match(html, /<span>&lt;draft&gt;\.md<\/span>/);
});

test("renders fixed sidebar controls with independently scrolling content", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" }, "# Draft\n");
  assert.match(html, /body\{[^}]*padding:24px 350px 56px/);
  assert.match(html, /<aside id="panel"><div id="toolbar"><button id="navigation-toggle" type="button" aria-controls="navigation" aria-expanded="true">Hide navigation<\/button><button data-action="document-note">/);
  assert.match(html, /body\.navigation-collapsed\{padding-left:48px\}/);
  assert.match(html, /body\.navigation-collapsed #document\{max-width:none\}/);
  assert.match(html, /#navigation\.is-collapsed\{opacity:0;pointer-events:none;transform:translateX\(-calc\(100% \+ 24px\)\)\}/);
  assert.match(html, /#navigation-toggle\{background:var\(--iris\);border-color:var\(--iris\);color:#fffaf3\}/);
  assert.match(html, /#toolbar button\[data-action=document-note\]\{background:var\(--foam\);border-color:var\(--foam\);color:#fffaf3\}/);
  assert.match(html, /#toolbar\{display:grid;/);
  assert.match(html, /#toolbar button\{width:100%;min-height:36px\}/);
  assert.match(html, /#panel,#navigation\{position:fixed;top:20px;display:flex;flex-direction:column;/);
  assert.match(html, /#operations,#outline\{min-height:0;overflow:auto\}/);
  assert.match(html, /\.table-scroll\{max-width:100%;margin:1\.4rem 0;overflow-x:auto;overscroll-behavior-inline:contain\}/);
  assert.match(html, /table\{width:max-content;min-width:100%;border-collapse:separate;/);
  assert.match(html, /#operations\{flex:1;/);
  assert.match(html, /#outline\{flex:1\}/);
  assert.match(html, /#toolbar,#guide-link,#navigation \.search-box,\.panel-heading\{flex:none\}/);
  assert.ok(html.indexOf('id="toolbar"') < html.indexOf("Review feedback"));
});

test("keeps code copy controls overlaid while code scrolls", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" }, "```ts\nconst message = 'hello';\n```\n");
  assert.match(html, /pre>\.copy-block\{position:sticky;top:8px;left:calc\(100% - 38px\);right:auto;float:right;/);
  assert.match(html, /<pre[^>]*><button class="copy-block"[^>]*><svg/s);
  assert.match(html, /<button class="copy-block"[^>]*><svg[\s\S]*<code class="language-ts">/);
});

test("keeps replacement previews and equal search navigation sizing in the page stylesheet", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" }, "# Draft\n");
  assert.match(html, /data-review-replacement/);
  assert.match(html, /\.review-target\[data-review-kind=replace\]\[data-review-replacement\]>\*\{text-decoration:line-through/);
  assert.match(html, /\.review-target\[data-review-kind=replace\]\[data-review-replacement\]::after\{content:"Replacement: "/);
  assert.match(html, /::highlight\(richie-replace\)\{background:rgba\(234,157,52,.28\);text-decoration:line-through/);
  assert.match(html, /\.review-replacement-inline\{/);
  assert.match(html, /\.backlink-active\{/);
  assert.match(html, /\.math-inline\.math-selecting\{display:inline\}/);
  assert.match(html, /\.math-inline\.math-selecting \.math-source\{position:static/);
  assert.match(html, /\.math-display\{display:block;overflow-x:auto;overflow-y:hidden;margin:1\.2rem 0 0/);
  assert.match(html, /\.feedback-focus/);
  assert.match(html, /#navigation \.search-box button\{flex:1 1 0;min-width:0;min-height:34px;/);
});

test("renders the stale-source warning only when requested", () => {
  const session = { id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" };
  assert.doesNotMatch(renderReviewPage(session, "# Draft\n"), /id="stale-banner"/);
  assert.match(renderReviewPage(session, "# Draft\n", true), /id="stale-banner"/);
  assert.match(renderReviewPage(session, "# Draft\n", true), /data-action="reload-source">Reload new draft/);
});

test("renders authenticated local image URLs and media presentation styles", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" }, "![Alt](../outside.png)\n");
  assert.match(html, /<meta name="referrer" content="no-referrer">/);
  assert.match(html, /src="\/api\/media\/session-1\?token=token-1&amp;path=\.\.%2Foutside\.png"/);
  assert.match(html, /data-md-media-source="!\[Alt\]\(\.\.\/outside\.png\)"/);
  assert.match(html, /\.media-target\.review-target\[data-review-kind=delete\]/);
  assert.match(html, /content:"Delete image"/);
  assert.match(html, /Replacement: /);
  assert.match(html, /\.math-target/);
});

test("serves authenticated raster images from absolute paths outside the document directory", async () => {
  const directory = await mkdtemp(join(tmpdir(), "richie-service-media-"));
  const documentDirectory = join(directory, "document");
  const sourcePath = join(documentDirectory, "draft-v00.md");
  const imagePath = join(directory, "outside.png");
  const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  await mkdir(documentDirectory);
  await writeFile(sourcePath, `![Outside](${imagePath})\n`);
  await writeFile(imagePath, png);
  const service = new RichieService();
  const session = await service.createSession(sourcePath);
  const sessionUrl = new URL(session.url);
  const token = sessionUrl.searchParams.get("token")!;
  const server = createServer((incoming, outgoing) => {
    void service.handle(incoming, outgoing).catch((error: Error) => {
      outgoing.statusCode = 500;
      outgoing.end(error.message);
    });
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  assert.ok(address && typeof address === "object");
  const call = (path: string, method = "GET", body?: string) => new Promise<{ status: number; headers: IncomingHttpHeaders; body: Buffer }>((resolve, reject) => {
    const headers: Record<string, string> = { host: "127.0.0.1:43173" };
    if (body !== undefined) headers["content-type"] = "application/json";
    const response = request({ hostname: "127.0.0.1", port: address.port, path, method, headers }, (incoming) => {
      const chunks: Buffer[] = [];
      incoming.on("data", (chunk) => chunks.push(Buffer.from(chunk)));
      incoming.on("end", () => resolve({ status: incoming.statusCode ?? 0, headers: incoming.headers, body: Buffer.concat(chunks) }));
    });
    response.on("error", reject);
    response.end(body);
  });
  try {
    const path = `/api/media/${session.id}?token=${encodeURIComponent(token)}&path=${encodeURIComponent(imagePath)}`;
    const loaded = await call(path);
    assert.equal(loaded.status, 200);
    assert.equal(loaded.headers["content-type"], "image/png");
    assert.equal(loaded.headers["cache-control"], "no-store");
    assert.equal(loaded.headers["x-content-type-options"], "nosniff");
    assert.deepEqual(loaded.body, png);
    assert.equal((await call(`/api/media/${session.id}?token=wrong&path=${encodeURIComponent(imagePath)}`)).status, 404);
    assert.equal((await call(path, "POST")).status, 405);
    const imageSyntax = `![Outside](${imagePath})`;
    const operation = await call(`/api/operations/${session.id}?token=${encodeURIComponent(token)}`, "POST", JSON.stringify({
      kind: "comment",
      scope: "media",
      range: {
        start: { offset: 0, line: 1, column: 1 },
        end: { offset: imageSyntax.length, line: 1, column: imageSyntax.length + 1 },
      },
      comment: "Check this image.",
    }));
    assert.equal(operation.status, 201);
    assert.equal(JSON.parse(operation.body.toString("utf8")).quote, imageSyntax);
    const invalidScope = await call(`/api/operations/${session.id}?token=${encodeURIComponent(token)}`, "POST", JSON.stringify({
      kind: "comment",
      scope: "arbitrary",
      range: {
        start: { offset: 0, line: 1, column: 1 },
        end: { offset: imageSyntax.length, line: 1, column: imageSyntax.length + 1 },
      },
      comment: "Invalid.",
    }));
    assert.equal(invalidScope.status, 400);
    await writeFile(sourcePath, `${imageSyntax}\n\nUpdated draft.\n`);
    const stalePage = await call(`/s/${session.id}?token=${encodeURIComponent(token)}`);
    assert.match(stalePage.body.toString("utf8"), /The Markdown source changed/);
    assert.doesNotMatch(stalePage.body.toString("utf8"), /Updated draft\./);
    const reloaded = await call(`/api/reload/${session.id}?token=${encodeURIComponent(token)}`, "POST", "{}");
    assert.equal(reloaded.status, 200);
    const state = await call(`/api/state/${session.id}?token=${encodeURIComponent(token)}`);
    assert.equal(state.status, 200);
    assert.deepEqual(JSON.parse(state.body.toString("utf8")).operations, []);
    assert.match((await call(`/s/${session.id}?token=${encodeURIComponent(token)}`)).body.toString("utf8"), /Updated draft\./);
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(directory, { recursive: true, force: true });
  }
});
