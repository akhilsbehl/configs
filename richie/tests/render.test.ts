import assert from "node:assert/strict";
import test from "node:test";
import { renderReviewHtml } from "../src/render.js";

test("renders inline and display math with source-aware review targets", () => {
  const source = "Inline $a^2+b^2=c^2$\n\n$$\n\\int_0^1 x^2 dx\n$$\n";
  const html = renderReviewHtml(source);
  assert.match(html, /class="math-target math-inline"[^>]*data-md-range=/);
  assert.match(html, /class="math-target math-display"[^>]*data-md-range=/);
  assert.match(html, /katex/);
  assert.match(html, /data-math-source="a\^2\+b\^2=c\^2"/);
  assert.match(html, /class="math-source md-text"[^>]*data-md-range=/);
  assert.match(html, /class="mermaid-source math-source-panel"[^>]*data-md-math-source/);
  assert.match(html, /class="mermaid-source-line math-source-line"[^>]*data-md-range=/);
  assert.match(html, /<math[^>]*>/);
  assert.doesNotMatch(html, /katex-html/);
});

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

test("adds copy controls for fenced code, Mermaid, and display math blocks", () => {
  const html = renderReviewHtml("```python\nprint(\"hello\")\n```\n\n```mermaid\ngraph TD\nA-->B\n```\n\n$$\nx^2\n$$\n");
  assert.match(html, /<pre[^>]*>.*class="copy-block"[^>]*data-copy-source="print\(&quot;hello&quot;\)"[^>]*aria-label="Copy code block"/s);
  assert.match(html, /<div class="mermaid"[^>]*><pre>.*<\/div><details class="mermaid-source"[^>]*>.*class="copy-block"[^>]*data-copy-source="graph TD\nA--&gt;B"[^>]*aria-label="Copy Mermaid source"/s);
  assert.match(html, /class="math-target math-display"[^>]*>.*<\/div><details class="mermaid-source math-source-panel"[^>]*>.*class="copy-block"[^>]*data-copy-source="x\^2"/s);
  assert.match(html, /<svg[^>]*viewBox="0 0 24 24"/);
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

test("renders direct, remote, reference-style, and linked Markdown images as exact media targets", () => {
  const source = [
    "Before ![Local alt](./figs/local.png \"Local title\") after.",
    "",
    "![Remote](https://example.com/remote.png)",
    "",
    "![Reference][hero]",
    "",
    "[![Linked](../linked.webp)](https://example.com/details)",
    "",
    "[hero]: /outside/hero.jpg \"Hero title\"",
    "",
  ].join("\n");
  const html = renderReviewHtml(source, { localImageUrl: (path) => `/media?path=${encodeURIComponent(path)}` });
  assert.match(html, /class="media-target"[^>]*data-md-media-source="!\[Local alt\]\(\.\/figs\/local\.png &quot;Local title&quot;\)"/);
  assert.match(html, /src="\/media\?path=\.%2Ffigs%2Flocal\.png" alt="Local alt" title="Local title"/);
  assert.match(html, /src="https:\/\/example\.com\/remote\.png" alt="Remote"[^>]*referrerpolicy="no-referrer"/);
  assert.match(html, /src="\/media\?path=%2Foutside%2Fhero\.jpg" alt="Reference" title="Hero title"/);
  assert.match(html, /<a class="media-target"[^>]*data-md-media-source="\[!\[Linked\]\(\.\.\/linked\.webp\)\]\(https:\/\/example\.com\/details\)"[^>]*target="_blank"/);
});

test("keeps blocked, unresolved, and raw HTML media source-reviewable without rendering active content", () => {
  const source = "![Blocked](http://example.com/image.png)\n\n![Missing][unknown]\n\n<video controls src=\"movie.mp4\"></video>\n";
  const html = renderReviewHtml(source);
  assert.match(html, /This image source is blocked/);
  assert.match(html, /Image reference is missing its definition/);
  assert.match(html, /<code>!\[Blocked\]\(http:\/\/example\.com\/image\.png\)<\/code>/);
  assert.doesNotMatch(html, /<video/);
});
