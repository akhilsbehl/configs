import type { Theme } from "@earendil-works/pi-coding-agent";
import { visibleWidth } from "@earendil-works/pi-tui";
import { ansiStyle } from "./ansi.js";
import {
	LINE_BREAK_SEGMENT_NAME,
	type RenderItem,
	type RenderSegment,
	type SegmentPalette,
	type SeparatorName,
	type StatuslineConfig,
} from "./types.js";

interface BlockColors {
	fg?: string;
	bg?: string;
}

interface PowerlineBlock {
	colors: BlockColors;
	segments: RenderSegment[];
}

const TOKYO_NIGHT_LEAD = "#a3aed2";
const TOKYO_NIGHT_EXTENSION_SEPARATOR = "#394260";

export function renderPowerlineStatusline(
	width: number,
	items: RenderItem[],
	config: Pick<StatuslineConfig, "palette" | "density" | "separator">,
): string {
	if (items.length === 0 || width <= 0) return "";
	return splitLines(items)
		.map((segments) => fitPowerlineSegments(segments, width, config))
		.join("\n");
}

function splitLines(items: RenderItem[]): RenderSegment[][] {
	const lines: RenderSegment[][] = [[]];
	for (const item of items) {
		if (item.name === LINE_BREAK_SEGMENT_NAME) lines.push([]);
		else lines.at(-1)?.push(item);
	}
	return lines;
}

const SEGMENT_RETENTION_PRIORITY: Readonly<Record<RenderSegment["name"], number>> = {
	context: 120,
	model: 110,
	branch: 100,
	tools: 90,
	cwd: 80,
	thinking: 70,
	cost: 60,
	provider: 50,
	cache: 45,
	tokens: 40,
	time: 30,
	turn: 20,
	brand: 10,
};

function fitPowerlineSegments(
	segments: readonly RenderSegment[],
	width: number,
	config: Pick<StatuslineConfig, "palette" | "density" | "separator">,
): string {
	if (segments.length === 0) return "";
	const fitted = [...segments];
	while (fitted.length > 1) {
		const rendered = joinPowerlineSegments(fitted, config);
		if (visibleWidth(rendered) <= width) return rendered;
		let removalIndex = 0;
		for (let index = 1; index < fitted.length; index += 1) {
			const candidate = fitted[index];
			const current = fitted[removalIndex];
			if (
				candidate &&
				current &&
				SEGMENT_RETENTION_PRIORITY[candidate.name] < SEGMENT_RETENTION_PRIORITY[current.name]
			) {
				removalIndex = index;
			}
		}
		fitted.splice(removalIndex, 1);
	}
	const rendered = joinPowerlineSegments(fitted, config);
	return visibleWidth(rendered) <= width ? rendered : "";
}

export function powerlineExtensionSeparator(_theme: Theme): string {
	return ansiStyle(" • ", { fg: TOKYO_NIGHT_EXTENSION_SEPARATOR });
}

function joinPowerlineSegments(
	segments: RenderSegment[],
	config: Pick<StatuslineConfig, "palette" | "density" | "separator">,
): string {
	const blocks = contiguousBlocks(segments, config.palette);
	let line = ansiStyle("░▒▓", { fg: TOKYO_NIGHT_LEAD });

	for (const [index, block] of blocks.entries()) {
		const previous = index === 0 ? undefined : blocks[index - 1]?.colors;
		if (previous) line += ansiStyle("", { fg: previous.bg, bg: block.colors.bg });
		line += ansiStyle(formatBlockText(block, config), block.colors);
	}

	const lastBlock = blocks.at(-1);
	if (lastBlock) line += ansiStyle("", { fg: lastBlock.colors.bg });
	return line;
}

function contiguousBlocks(
	segments: RenderSegment[],
	configuredPalette: SegmentPalette,
): PowerlineBlock[] {
	const blocks: PowerlineBlock[] = [];
	for (const segment of segments) {
		const colors = configuredPalette[segment.name] ?? {};
		const previous = blocks.at(-1);
		if (previous !== undefined && colorsEqual(previous.colors, colors))
			previous.segments.push(segment);
		else blocks.push({ colors, segments: [segment] });
	}
	return blocks;
}

function colorsEqual(left: BlockColors, right: BlockColors): boolean {
	return left.fg === right.fg && left.bg === right.bg;
}

function formatBlockText(
	block: PowerlineBlock,
	config: Pick<StatuslineConfig, "density" | "separator">,
): string {
	const texts = block.segments.map(formatSegmentText);
	const separator = separatorText(config.separator, config.density === "cozy");
	const leading = config.density === "cozy" ? "  " : " ";
	const trailing = config.density === "cozy" ? " " : "";
	return `${leading}${texts.join(separator)}${trailing}`;
}

function formatSegmentText(segment: RenderSegment): string {
	return segment.emphasis ? `\u001b[1m${segment.text}\u001b[22m` : segment.text;
}

function separatorText(separator: SeparatorName, cozy: boolean): string {
	const padding = cozy ? "  " : " ";
	switch (separator) {
		case "dot":
			return `${padding}•${padding}`;
		case "bar":
			return `${padding}│${padding}`;
		case "powerline":
			return `${padding}${padding}`;
		case "round":
			return `${padding}❯${padding}`;
		case "none":
			return padding;
	}
}
