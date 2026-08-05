import { mkdir } from "node:fs/promises";
import { createHash } from "node:crypto";
import path from "node:path";

export const reviewDirectory = "/tmp/richie-review-jsons";

export async function ensureReviewDirectory(): Promise<void> {
  await mkdir(reviewDirectory, { recursive: true });
}

export function reviewSidecarPath(sourcePath: string, sourceHash: string): string {
  const sourceName = path.basename(sourcePath).replace(/\.md$/i, "");
  const sourceId = createHash("sha256").update(`${sourcePath}\0${sourceHash}`).digest("hex").slice(0, 16);
  return path.join(reviewDirectory, `${sourceName}-${sourceId}.review.json`);
}

export function commentedPath(sourcePath: string, attempt = 1): string {
  const base = sourcePath.replace(/\.md$/i, "-commented");
  return attempt === 1 ? `${base}.md` : `${base}-${attempt}.md`;
}

export function sourceName(sourcePath: string): string {
  return path.basename(sourcePath);
}
