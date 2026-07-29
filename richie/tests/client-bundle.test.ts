import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";
import test from "node:test";

test("bundles the targeted interaction regressions", async () => {
  const directory = new URL("../public/", import.meta.url);
  const files = (await readdir(directory)).filter((name) => name.endsWith(".js"));
  const client = (await Promise.all(files.map((name) => readFile(new URL(name, directory), "utf8")))).join("\n");
  assert.match(client, /Mermaid source \(render failed\)/);
  assert.match(client, /Delete list/);
  assert.match(client, /contextmenu/);
  assert.match(client, /data-review-replacement|reviewReplacement/);
});
