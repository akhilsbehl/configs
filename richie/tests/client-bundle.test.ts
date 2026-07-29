import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";
import test from "node:test";

test("bundles the targeted interaction regressions", async () => {
  const directory = new URL("../public/", import.meta.url);
  const files = (await readdir(directory)).filter((name) => name.endsWith(".js"));
  const bundles = await Promise.all(files.map((name) => readFile(new URL(name, directory), "utf8")));
  const client = bundles.find((bundle) => bundle.includes("Mermaid source (render failed)"));
  assert.ok(client, "Richie client bundle was not found");
  assert.match(client, /Mermaid source \(render failed\)/);
  assert.match(client, /Delete list/);
  assert.match(client, /contextmenu/);
  assert.match(client, /data-review-replacement|reviewReplacement/);
  assert.match(client, /\.md-text,code\[data-md-range\]/);
  assert.match(client, /scope\s*===\s*"range"/);
});
