import path from "node:path";

export function reviewSidecarPath(sourcePath: string): string {
  return sourcePath.replace(/\.md$/i, ".review.json");
}

export function commentedPath(sourcePath: string, attempt = 1): string {
  const base = sourcePath.replace(/\.md$/i, "-commented");
  return attempt === 1 ? `${base}.md` : `${base}-${attempt}.md`;
}

export function sourceName(sourcePath: string): string {
  return path.basename(sourcePath);
}
