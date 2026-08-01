import assert from "node:assert/strict";
import { createServer, request, type IncomingHttpHeaders } from "node:http";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { RichieService, renderReviewPage } from "../src/service.js";

test("renders fixed sidebar controls with independently scrolling content", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" }, "# Draft\n");
  assert.match(html, /body\{[^}]*padding:24px 350px 56px/);
  assert.match(html, /<aside id="panel"><div id="toolbar">/);
  assert.match(html, /#toolbar\{display:grid;/);
  assert.match(html, /#toolbar button\{width:100%;min-height:36px\}/);
  assert.match(html, /#panel,#navigation\{position:fixed;top:20px;display:flex;flex-direction:column;/);
  assert.match(html, /#operations,#outline\{min-height:0;overflow:auto\}/);
  assert.match(html, /#operations\{flex:1;/);
  assert.match(html, /#outline\{flex:1\}/);
  assert.match(html, /#toolbar,#guide-link,#navigation \.search-box,\.panel-heading\{flex:none\}/);
  assert.ok(html.indexOf('id="toolbar"') < html.indexOf("Review feedback"));
});

test("keeps replacement previews and equal search navigation sizing in the page stylesheet", () => {
  const html = renderReviewPage({ id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" }, "# Draft\n");
  assert.match(html, /data-review-replacement/);
  assert.match(html, /\.review-target\[data-review-kind=replace\]\[data-review-replacement\]>\*\{text-decoration:line-through/);
  assert.match(html, /\.review-target\[data-review-kind=replace\]\[data-review-replacement\]::after\{content:"Replacement: "/);
  assert.match(html, /::highlight\(richie-replace\)\{background:rgba\(234,157,52,.28\);text-decoration:line-through/);
  assert.match(html, /\.review-replacement-inline\{/);
  assert.match(html, /\.backlink-active\{/);
  assert.match(html, /\.math-inline\.math-selecting \.math-rendered/);
  assert.match(html, /\.feedback-focus/);
  assert.match(html, /#navigation \.search-box button\{flex:1 1 0;min-width:0;min-height:34px;/);
});

test("renders the stale-source warning only when requested", () => {
  const session = { id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" };
  assert.doesNotMatch(renderReviewPage(session, "# Draft\n"), /id="stale-banner"/);
  assert.match(renderReviewPage(session, "# Draft\n", true), /id="stale-banner"/);
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
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(directory, { recursive: true, force: true });
  }
});
