import assert from "node:assert/strict";
import test from "node:test";
import { commentedPath, reviewSidecarPath } from "../src/paths.js";
import { hasOpenOperations, newState, renderCommentedMarkdown, sha256 } from "../src/store.js";

test("derives sidecar and commented paths", () => {
  assert.equal(reviewSidecarPath("/work/draft-v03.md"), "/work/draft-v03.review.json");
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

test("exports a cell-specific marker for cell deletions", () => {
  const source = "| A |\n| - |\n| b |\n";
  const state = newState("draft-v00.md", source);
  state.operations.push({ id: "rvw_001", kind: "delete", status: "open", scope: "cell", quote: "b", range: { start: { offset: 14, line: 3, column: 3 }, end: { offset: 15, line: 3, column: 4 } }, createdAt: "2026-01-01T00:00:00Z" });
  assert.match(renderCommentedMarkdown(source, state), /b <<ASB: \[rvw_001\] Clear this table cell\.>>/);
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
