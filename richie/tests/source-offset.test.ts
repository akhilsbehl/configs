import assert from "node:assert/strict";
import test from "node:test";
import { sourceTextLength } from "../src/source-offset.js";

test("excludes prior replacement previews when mapping a later selection on the same line", () => {
  const sourcePrefix = [
    { text: "This executive", isReplacementPreview: false },
    { text: " → foooooooooooooo", isReplacementPreview: true },
    { text: " synthesis is ", isReplacementPreview: false },
  ];

  assert.equal(sourceTextLength(sourcePrefix), "This executive synthesis is ".length);
});
