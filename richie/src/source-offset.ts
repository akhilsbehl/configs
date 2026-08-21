export type RenderedTextPart = { text: string; isReplacementPreview: boolean };

export function sourceTextLength(parts: readonly RenderedTextPart[]): number {
  return parts.filter((part) => !part.isReplacementPreview).reduce((length, part) => length + part.text.length, 0);
}

export function sourceText(parts: readonly RenderedTextPart[]): string {
  return parts.filter((part) => !part.isReplacementPreview).map((part) => part.text).join("");
}
