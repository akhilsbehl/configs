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
