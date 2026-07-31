import type { ThemeColor } from "@earendil-works/pi-coding-agent";

export const SEGMENT_NAMES = [
	"brand",
	"provider",
	"model",
	"thinking",
	"cwd",
	"branch",
	"tools",
	"context",
	"tokens",
	"cache",
	"cost",
	"time",
	"turn",
] as const;
export type SegmentName = (typeof SEGMENT_NAMES)[number];

export const LINE_BREAK_SEGMENT_NAME = "line_break" as const;
export type ConfigSegmentName = SegmentName | typeof LINE_BREAK_SEGMENT_NAME;

export const DENSITIES = ["compact", "cozy"] as const;
export type Density = (typeof DENSITIES)[number];

export const SEPARATOR_NAMES = ["none", "dot", "bar", "powerline", "round"] as const;
export type SeparatorName = (typeof SEPARATOR_NAMES)[number];

export const TRUNCATION_DIRECTIONS = ["start", "middle", "end"] as const;
export type TruncationDirection = (typeof TRUNCATION_DIRECTIONS)[number];

export type PowerlineBlockName = "header" | "directory" | "git" | "runtime" | "meter";

export interface SegmentTextConfig {
	prefix: string;
	suffix: string;
}

export interface ModelSegmentTextConfig extends SegmentTextConfig {
	truncationLength: number;
	truncationSymbol: string;
	truncationDirection: TruncationDirection;
}

export interface SegmentPaletteColor {
	fg?: string;
	bg?: string;
}

export type SegmentPalette = Partial<Record<SegmentName, SegmentPaletteColor>>;

export interface StatuslineConfig {
	palette: SegmentPalette;
	density: Density;
	separator: SeparatorName;
	segments: ConfigSegmentName[];
	segmentText: Record<SegmentName, SegmentTextConfig> & { model: ModelSegmentTextConfig };
	extensionStatusIcons: Record<string, string>;
	stackExtensionStatuses: boolean;
	maxExtensionStatuses: number;
}

export interface RenderSegment {
	name: SegmentName;
	text: string;
	color: ThemeColor;
	block: PowerlineBlockName;
	emphasis?: boolean;
}

export interface RenderLineBreak {
	name: typeof LINE_BREAK_SEGMENT_NAME;
}

export type RenderItem = RenderSegment | RenderLineBreak;
