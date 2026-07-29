import assert from "node:assert/strict";
import test from "node:test";
import { renderReviewPage } from "../src/service.js";

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
  assert.match(html, /#navigation \.search-box button\{flex:1 1 0;min-width:0;min-height:34px;/);
});

test("renders the stale-source warning only when requested", () => {
  const session = { id: "session-1", token: "token-1", sourcePath: "/work/draft-v00.md" };
  assert.doesNotMatch(renderReviewPage(session, "# Draft\n"), /id="stale-banner"/);
  assert.match(renderReviewPage(session, "# Draft\n", true), /id="stale-banner"/);
});
