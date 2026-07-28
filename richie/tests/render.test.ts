import assert from "node:assert/strict";
import test from "node:test";
import { renderReviewHtml } from "../src/render.js";

test("renders source-aware inline Markdown and GFM tables", () => {
  const source = "# Heading\n\nA **strong** [link](https://example.com).\n\n| A | B |\n| - | - |\n| 1 | 2 |\n\n```mermaid\ngraph TD; A-->B\n```\n";
  const html = renderReviewHtml(source);
  assert.match(html, /data-md-range=/);
  assert.match(html, /<strong/);
  assert.match(html, /<table/);
  assert.match(html, /data-mermaid=/);
  assert.match(html, /class="mermaid-source"/);
  assert.match(html, /class="mermaid-source-line" data-md-range=/);
  assert.match(html, /class="md-text">graph TD/);
  assert.match(html, /class="md-text-range" data-md-range=/);
  assert.match(html, /graph TD; A--&gt;B/);
});
