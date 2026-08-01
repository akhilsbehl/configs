import assert from "node:assert/strict";
import { mkdtemp, mkdir, rm, symlink, truncate, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { loadLocalImage, MediaError } from "../src/media.js";

const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

test("loads relative and absolute raster images by file signature", async () => {
  const directory = await mkdtemp(join(tmpdir(), "richie-media-"));
  try {
    const sourcePath = join(directory, "draft-v00.md");
    const imagePath = join(directory, "image.bin");
    const linkPath = join(directory, "linked-image");
    await writeFile(sourcePath, "# Draft\n");
    await writeFile(imagePath, png);
    await symlink(imagePath, linkPath);
    const relative = await loadLocalImage(sourcePath, "image.bin");
    const encoded = await loadLocalImage(sourcePath, "image%2Ebin");
    const absolute = await loadLocalImage(sourcePath, imagePath);
    const linked = await loadLocalImage(sourcePath, linkPath);
    assert.equal(relative.contentType, "image/png");
    assert.equal(encoded.contentType, "image/png");
    assert.deepEqual(relative.body, png);
    assert.equal(absolute.resolvedPath, imagePath);
    assert.equal(linked.resolvedPath, imagePath);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("recognizes every supported raster signature without trusting extensions", async () => {
  const directory = await mkdtemp(join(tmpdir(), "richie-media-"));
  try {
    const sourcePath = join(directory, "draft-v00.md");
    const imagePath = join(directory, "image.data");
    await writeFile(sourcePath, "# Draft\n");
    const fixtures = [
      ["image/png", png],
      ["image/jpeg", Buffer.from([0xff, 0xd8, 0xff, 0xe0])],
      ["image/gif", Buffer.from("GIF89a", "ascii")],
      ["image/webp", Buffer.from("RIFF0000WEBP", "ascii")],
      ["image/avif", Buffer.from("\0\0\0\u0018ftypavif\0\0\0\0avif", "binary")],
    ] as const;
    for (const [contentType, body] of fixtures) {
      await writeFile(imagePath, body);
      assert.equal((await loadLocalImage(sourcePath, imagePath)).contentType, contentType);
    }
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("rejects missing, non-file, unsupported, and oversized local media", async () => {
  const directory = await mkdtemp(join(tmpdir(), "richie-media-"));
  try {
    const sourcePath = join(directory, "draft-v00.md");
    const textPath = join(directory, "not-image.png");
    const largePath = join(directory, "large.png");
    const folderPath = join(directory, "folder");
    await writeFile(sourcePath, "# Draft\n");
    await writeFile(textPath, "<svg><script>unsafe()</script></svg>");
    await writeFile(largePath, png);
    await truncate(largePath, 25 * 1024 * 1024 + 1);
    await mkdir(folderPath);
    const expected = [
      ["%", 400],
      ["missing.png", 404],
      [folderPath, 415],
      [textPath, 415],
      [largePath, 413],
    ] as const;
    for (const [path, status] of expected) {
      await assert.rejects(loadLocalImage(sourcePath, path), (error: unknown) => error instanceof MediaError && error.status === status);
    }
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
