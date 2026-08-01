import { readFile, realpath, stat } from "node:fs/promises";
import { dirname, isAbsolute, resolve } from "node:path";

const maximumImageBytes = 25 * 1024 * 1024;

export class MediaError extends Error {
  constructor(readonly status: 400 | 404 | 413 | 415, message: string) {
    super(message);
  }
}

function rasterContentType(value: Buffer): string | undefined {
  if (value.length >= 8 && value.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return "image/png";
  if (value.length >= 3 && value[0] === 0xff && value[1] === 0xd8 && value[2] === 0xff) return "image/jpeg";
  if (value.length >= 6 && (value.subarray(0, 6).toString("ascii") === "GIF87a" || value.subarray(0, 6).toString("ascii") === "GIF89a")) return "image/gif";
  if (value.length >= 12 && value.subarray(0, 4).toString("ascii") === "RIFF" && value.subarray(8, 12).toString("ascii") === "WEBP") return "image/webp";
  if (value.length >= 16 && value.subarray(4, 8).toString("ascii") === "ftyp" && /avif|avis/.test(value.subarray(8, Math.min(value.length, 40)).toString("ascii"))) return "image/avif";
  return undefined;
}

export async function loadLocalImage(sourcePath: string, requestedPath: string): Promise<{ body: Buffer; contentType: string; resolvedPath: string }> {
  if (!requestedPath || requestedPath.includes("\0")) throw new MediaError(400, "A local image path is required");
  let decodedPath: string;
  try {
    decodedPath = decodeURIComponent(requestedPath);
  } catch {
    throw new MediaError(400, "Local image path is not valid URL encoding");
  }
  const candidate = isAbsolute(decodedPath) ? decodedPath : resolve(dirname(sourcePath), decodedPath);
  let resolvedPath: string;
  try {
    resolvedPath = await realpath(candidate);
  } catch {
    throw new MediaError(404, "Local image not found");
  }
  let metadata;
  try {
    metadata = await stat(resolvedPath);
  } catch {
    throw new MediaError(404, "Local image not found");
  }
  if (!metadata.isFile()) throw new MediaError(415, "Local media path is not a regular file");
  if (metadata.size > maximumImageBytes) throw new MediaError(413, "Local image exceeds the 25 MiB limit");
  let body: Buffer;
  try {
    body = await readFile(resolvedPath);
  } catch {
    throw new MediaError(404, "Local image not found");
  }
  if (body.length > maximumImageBytes) throw new MediaError(413, "Local image exceeds the 25 MiB limit");
  const contentType = rasterContentType(body);
  if (!contentType) throw new MediaError(415, "Only PNG, JPEG, GIF, WebP, and AVIF images are supported");
  return { body, contentType, resolvedPath };
}
