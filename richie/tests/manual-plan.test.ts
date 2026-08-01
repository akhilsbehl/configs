import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

test("keeps corrected manual deletion and shortcut targets in the standalone fixture", async () => {
  const plan = await readFile(new URL("../../manual-test-plan-v01.md", import.meta.url), "utf8");
  const compact = plan.replace(/\s+/g, " ");
  const requiredTargets = [
    "The second sentence makes block selection visibly different from a sentence selection.",
    "This is block A. It has one sentence and a stable opening phrase.",
    "## Fixture: thematic break and final paragraph",
    "Block D item one has an independent target.",
    "alpha word",
    "beta phrase",
    "gamma sentence",
    "## Fixture: invalid Mermaid diagram",
    "this is not valid Mermaid",
  ];
  requiredTargets.forEach((target) => assert.match(compact, new RegExp(target.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))));
  assert.doesNotMatch(plan, /That distinction matters because a train/);
  assert.doesNotMatch(plan, /The investigation found three contributing factors/);
  assert.doesNotMatch(plan, /Questions for the next timetable/);
  assert.doesNotMatch(plan, /`Closing note`/);
});

test("keeps the Markdown image smoke plan focused and self-contained", async () => {
  const plan = await readFile(new URL("../../manual-media-test-plan-v00.md", import.meta.url), "utf8");
  assert.deepEqual([...plan.matchAll(/^## MI-\d{2}\./gm)].map((match) => match[0]), ["## MI-01.", "## MI-02.", "## MI-03.", "## MI-04."]);
  assert.doesNotMatch(plan, /\.\/figs\//);
  assert.doesNotMatch(plan, /\/home\/akhil\/warchives\/richie\/figs\//);
  assert.match(plan, /!\[W3C remote image\]\(https:\/\/www\.w3\.org\/Icons\/w3c_home\.png\)/);
  assert.match(plan, /!\[Missing reference\]\[definition-does-not-exist\]/);
  assert.match(plan, /Do not rerun the\s+full Richie manual suite/);
});
