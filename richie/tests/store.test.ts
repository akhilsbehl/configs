import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import test from "node:test";
import { commentedPath, reviewSidecarPath } from "../src/paths.js";
import { hasOpenOperations, newState, renderCommentedMarkdown, sha256 } from "../src/store.js";

test("derives hashed temporary sidecar and commented paths", () => {
  const sourcePath = "/work/draft-v03.md";
  const sourceHash = "file-content-hash";
  const sidecarId = createHash("sha256").update(`${sourcePath}\0${sourceHash}`).digest("hex").slice(0, 16);
  assert.equal(reviewSidecarPath(sourcePath, sourceHash), `/tmp/richie-review-jsons/draft-v03-${sidecarId}.review.json`);
  assert.notEqual(reviewSidecarPath(sourcePath, sourceHash), reviewSidecarPath(sourcePath, "another-file-content-hash"));
  assert.equal(commentedPath("/work/draft-v03.md"), "/work/draft-v03-commented.md");
  assert.equal(commentedPath("/work/draft-v03.md", 2), "/work/draft-v03-commented-2.md");
});

test("exports range and document annotations without changing source text", () => {
  const source = "# Draft\n\nThe claim is vague.\n";
  const state = newState("draft-v03.md", source);
  state.operations.push({ id: "rvw_001", kind: "replace", status: "open", scope: "range", quote: "vague", replacement: "unsupported", range: { start: { offset: 22, line: 3, column: 14 }, end: { offset: 27, line: 3, column: 19 } }, createdAt: "2026-01-01T00:00:00Z" });
  state.operations.push({ id: "rvw_002", kind: "comment", status: "open", scope: "document", placement: "start", comment: "Lead with the recommendation.", createdAt: "2026-01-01T00:00:00Z" });
  const output = renderCommentedMarkdown(source, state);
  assert.match(output, /^<<ASB: \[rvw_002\] Lead with the recommendation\.>>/);
  assert.match(output, /vague <<ASB: \[rvw_001\] Replace "vague" with "unsupported"\.>>/);
  assert.equal(sha256(source), state.sourceSha256);
});

test("exports the exact selected quote in range annotations", () => {
  const source = "Alpha beta gamma.\n";
  const state = newState("draft-v00.md", source);
  state.operations.push({ id: "rvw_001", kind: "comment", status: "open", scope: "range", quote: "beta", comment: "Check this word.", range: { start: { offset: 6, line: 1, column: 7 }, end: { offset: 10, line: 1, column: 11 } }, createdAt: "2026-01-01T00:00:00Z" });
  assert.equal(renderCommentedMarkdown(source, state), "Alpha beta <<ASB: [rvw_001] Comment on \"beta\": Check this word.>> gamma.\n");
});

test("exports the exact selected quote in deletion annotations", () => {
  const source = "Alpha beta gamma.\n";
  const state = newState("draft-v00.md", source);
  state.operations.push({ id: "rvw_001", kind: "delete", status: "open", scope: "range", quote: "beta", range: { start: { offset: 6, line: 1, column: 7 }, end: { offset: 10, line: 1, column: 11 } }, createdAt: "2026-01-01T00:00:00Z" });
  assert.equal(renderCommentedMarkdown(source, state), "Alpha beta <<ASB: [rvw_001] Delete \"beta\".>> gamma.\n");
});

test("exports a cell-specific marker for cell deletions", () => {
  const source = "| A |\n| - |\n| b |\n";
  const state = newState("draft-v00.md", source);
  state.operations.push({ id: "rvw_001", kind: "delete", status: "open", scope: "cell", quote: "b", range: { start: { offset: 14, line: 3, column: 3 }, end: { offset: 15, line: 3, column: 4 } }, createdAt: "2026-01-01T00:00:00Z" });
  assert.match(renderCommentedMarkdown(source, state), /b <<ASB: \[rvw_001\] Clear the table cell "b"\.>>/);
});

test("exports document notes at the top and keeps code annotations outside fences", () => {
  const source = "```mermaid\ngraph TD; A-->B\n```\n";
  const state = newState("draft-v00.md", source);
  state.operations.push({ id: "rvw_001", kind: "comment", status: "open", scope: "range", quote: "A-->B", comment: "Rename this edge.", range: { start: { offset: 20, line: 2, column: 11 }, end: { offset: 25, line: 2, column: 16 } }, createdAt: "2026-01-01T00:00:00Z" });
  state.operations.push({ id: "rvw_002", kind: "comment", status: "open", scope: "document", placement: "start", comment: "Lead with the recommendation.", createdAt: "2026-01-01T00:00:00Z" });
  assert.equal(renderCommentedMarkdown(source, state), "<<ASB: [rvw_002] Lead with the recommendation.>>\n\n```mermaid\ngraph TD; A-->B\n```\n<<ASB: [rvw_001] Comment on \"A-->B\": Rename this edge.>>\n");
});

test("exports quoted deletion markers after ordinary and Mermaid code fences", () => {
  const source = "```bash\nring_decision_bell()\n```\n\n```mermaid\nclassDef station\n```\n";
  const state = newState("draft-v00.md", source);
  const ordinaryQuote = "ring_decision_bell()";
  const mermaidQuote = "classDef station";
  const ordinaryStart = source.indexOf(ordinaryQuote);
  const mermaidStart = source.indexOf(mermaidQuote);
  state.operations.push({ id: "rvw_001", kind: "delete", status: "open", scope: "range", quote: ordinaryQuote, range: { start: { offset: ordinaryStart, line: 2, column: 1 }, end: { offset: ordinaryStart + ordinaryQuote.length, line: 2, column: ordinaryQuote.length + 1 } }, createdAt: "2026-01-01T00:00:00Z" });
  state.operations.push({ id: "rvw_002", kind: "delete", status: "open", scope: "range", quote: mermaidQuote, range: { start: { offset: mermaidStart, line: 6, column: 1 }, end: { offset: mermaidStart + mermaidQuote.length, line: 6, column: mermaidQuote.length + 1 } }, createdAt: "2026-01-01T00:00:00Z" });
  const output = renderCommentedMarkdown(source, state);
  assert.match(output, /```\n<<ASB: \[rvw_001\] Delete "ring_decision_bell\(\)"\.>>\n\n```mermaid/);
  assert.match(output, /```mermaid\nclassDef station\n```\n<<ASB: \[rvw_002\] Delete "classDef station"\.>>/);
});

test("marks every cell of a deleted table column inside its fences", () => {
  const source = "| A | B |\n| - | - |\n| 1 | 2 |\n";
  const state = newState("draft-v00.md", source);
  state.operations.push({ id: "rvw_001", kind: "delete", status: "open", scope: "column", quote: "B", range: { start: { offset: 6, line: 1, column: 7 }, end: { offset: 7, line: 1, column: 8 } }, createdAt: "2026-01-01T00:00:00Z" });
  const output = renderCommentedMarkdown(source, state);
  assert.match(output, /\| A \| B  <<ASB: \[rvw_001\] Delete the table column selected from "B"\.>>\|/);
  assert.match(output, /\| 1 \| 2  <<ASB: \[rvw_001\] Delete the table column selected from "B"\.>>\|/);
});

test("detects whether a review has open feedback", () => {
  const state = newState("draft-v03.md", "# Draft\n");
  assert.equal(hasOpenOperations(state), false);
  state.operations.push({ id: "rvw_001", kind: "comment", status: "needs-review", scope: "document", comment: "Later", createdAt: "2026-01-01T00:00:00Z" });
  assert.equal(hasOpenOperations(state), false);
  state.operations.push({ id: "rvw_002", kind: "comment", status: "open", scope: "document", comment: "Act on this", createdAt: "2026-01-01T00:00:00Z" });
  assert.equal(hasOpenOperations(state), true);
});

test("does not export feedback removed from the review", () => {
  const source = "Alpha beta.\n";
  const state = newState("draft-v03.md", source);
  state.operations.push({ id: "rvw_001", kind: "comment", status: "superseded", scope: "range", quote: "beta", comment: "Ignore this.", range: { start: { offset: 6, line: 1, column: 7 }, end: { offset: 10, line: 1, column: 11 } }, createdAt: "2026-01-01T00:00:00Z" });
  assert.equal(hasOpenOperations(state), false);
  assert.equal(renderCommentedMarkdown(source, state), source);
});

test("exports media-specific comment, replacement, and deletion markers after complete image syntax", () => {
  const source = "![One](one.png)\n\n[![Two](two.png)](https://example.com)\n\n![Three](three.png)\n";
  const state = newState("draft-v00.md", source);
  const one = "![One](one.png)";
  const two = "[![Two](two.png)](https://example.com)";
  const three = "![Three](three.png)";
  const rangeFor = (quote: string) => {
    const offset = source.indexOf(quote);
    return { start: { offset, line: 1, column: 1 }, end: { offset: offset + quote.length, line: 1, column: quote.length + 1 } };
  };
  state.operations.push({ id: "rvw_001", kind: "comment", status: "open", scope: "media", quote: one, comment: "Check this image.", range: rangeFor(one), createdAt: "2026-01-01T00:00:00Z" });
  state.operations.push({ id: "rvw_002", kind: "replace", status: "open", scope: "media", quote: two, replacement: "![New](new.png)", range: rangeFor(two), createdAt: "2026-01-01T00:00:00Z" });
  state.operations.push({ id: "rvw_003", kind: "delete", status: "open", scope: "media", quote: three, range: rangeFor(three), createdAt: "2026-01-01T00:00:00Z" });
  const output = renderCommentedMarkdown(source, state);
  assert.match(output, /!\[One\]\(one\.png\) <<ASB: \[rvw_001\] Comment on image "!\[One\]\(one\.png\)": Check this image\.>>/);
  assert.match(output, /\[!\[Two\]\(two\.png\)\]\(https:\/\/example\.com\) <<ASB: \[rvw_002\] Replace image "\[!\[Two\]\(two\.png\)\]\(https:\/\/example\.com\)" with "!\[New\]\(new\.png\)"\.>>/);
  assert.match(output, /!\[Three\]\(three\.png\) <<ASB: \[rvw_003\] Delete image "!\[Three\]\(three\.png\)"\.>>/);
});
