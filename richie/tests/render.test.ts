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
  assert.match(html, /class="md-text"><span class="hljs-keyword">graph<\/span>/);
  assert.match(html, /class="md-text-range" data-md-range=/);
  assert.match(html, /graph TD; A--&gt;B/);
});

test("renders checklist controls beside paragraph text and source-aware code blocks", () => {
  const html = renderReviewHtml("- [ ] Review this\n\n```ts\nconst answer = 42;\n```\n");
  assert.match(html, /<li[^>]*><input type="checkbox" disabled> <p/);
  assert.match(html, /<pre data-md-block="[^"]+"[^>]*data-md-range=/);
  assert.match(html, /<code class="language-ts"><span class="code-source-line" data-md-range="[^"]+"><span class="md-text">.*hljs-keyword.*const.*hljs-number.*42.*<\/span><\/span><\/code>/);
  assert.doesNotMatch(html, /<\/span>\n<span class="code-source-line"/);
});

test("syntax highlights Mermaid source without losing line ranges", () => {
  const html = renderReviewHtml("```mermaid\ngraph TD\nA-->B\n```\n");
  assert.match(html, /class="mermaid-source-line" data-md-range="[^"]+"/);
  assert.match(html, /hljs-keyword/);
  assert.match(html, /hljs-operator/);
  assert.match(html, /<div class="mermaid"[^>]*><pre>graph TD/);
  assert.doesNotMatch(html, /<div class="mermaid"[^>]*>.*class="md-text"/);
  assert.match(html, /<details class="mermaid-source"[^>]*>.*class="md-text"/);
});

test("keeps invalid Mermaid source available for client-side render failures", () => {
  const html = renderReviewHtml("```mermaid\nthis is not valid Mermaid\n```\n");
  assert.match(html, /<div class="mermaid"[^>]*data-mermaid="this is not valid Mermaid"/);
  assert.match(html, /<details class="mermaid-source"[^>]*data-md-mermaid-source>/);
  assert.match(html, /class="mermaid-source-line"[^>]*>.*this is not valid Mermaid/);
});

test("renders unordered and ordered lists as source-aware block targets", () => {
  const html = renderReviewHtml("- Alpha\n- Beta\n\n1. One\n2. Two\n");
  assert.match(html, /<ul data-md-block="[^"]+"[^>]*data-md-range=/);
  assert.match(html, /<ol data-md-block="[^"]+"[^>]*data-md-range=/);
});
