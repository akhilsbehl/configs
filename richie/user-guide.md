# Richie user guide

Richie is a local visual review surface for Markdown. Markdown remains canonical. Richie records review operations in a temporary sidecar and exports a commented copy for an agent to apply to the next Markdown version.

## Before you start

The input must be a readable `.md` file. Build Richie before use:

```sh
npm install
npm run check
npm test
npm run build
```

Start the service, then open a draft:

```sh
npm start
npm run review -- path/to/draft-vNN.md
```

If installed, use `richie review path/to/draft-vNN.md`. The service listens only on `127.0.0.1:43173`; `richie status` checks it.

## Review a draft

1. Read the rendered document.
2. Select text and choose `Comment`, `Replace`, or `Delete`, or press `c`, `r`, or `d`.
3. Hover over a heading, paragraph, list item, blockquote, code block, table cell, Mermaid source, or Markdown image for scoped feedback. A list item also offers `Delete list` for the whole containing list.
4. Use `Document level note` for cross-cutting feedback. It appears at the top of the commented copy.
5. Use the left sidebar to navigate headings. The user guide and search controls stay fixed while a long outline scrolls. The right sidebar keeps its 3 review actions fixed while the feedback inventory scrolls.
6. Use the search control at the top of the left sidebar. `Previous match` and `Next match`, or `Shift+Enter` and `Enter`, move between results. `Escape` clears the search.

Richie saves every operation immediately to a hashed `.review.json` sidecar in `/tmp/richie-review-jsons`, keeping review state out of the source project. Each range operation retains the exact source quote and source range. Range highlighting applies only to the selection, not its containing paragraph or line.

Pending replacements show the original content struck through and the proposed replacement inline beside it. With a valid document selection active, Richie suppresses the browser context menu so `c`, `r`, and `d` remain available.

Click visible review markup to reveal its matching feedback card. The first matching card receives focus and overlapping matches flash together with a prominent outline.

### Math

Inline `$...$` expressions render as MathML. Starting a selection on rendered inline math switches it to its source text so TeX can be selected precisely; press `Escape` to restore the rendered form. Full inline-math actions remain available from the hover menu.

Display `$$...$$` blocks render as MathML and expose a collapsed `Math source` disclosure using the same interaction as Mermaid. Select individual source lines for Comment, Replace, or Delete, or use the rendered block for whole-block actions. Multiple aligned equations in one block remain a single Markdown math node.

### Tables, Mermaid, math, and images

Hover over a table cell to comment, replace, clear, delete its row, or delete its column. A column deletion highlights every cell in that column and exports a marker inside each affected table cell, preserving the Markdown table fences.

Mermaid diagrams render as SVG for reading and expose a source view for review. Select Mermaid source lines, not SVG elements. Review highlighting maps only to the source view, so a source selection cannot spread across generated SVG labels. If rendering fails, Richie opens the source automatically so it remains reviewable. Markers for Mermaid and ordinary fenced-code feedback are exported after the closing fence, so the source block continues to render. A code-block-level marker is aligned with that closing fence.

Richie renders direct, linked, and reference-style Markdown images. Hover an image and choose `Comment`, `Replace`, or `Delete`. The operation targets the complete image syntax. For a linked image, it also includes the outer link syntax. Replacement input is stored as Markdown text and is not rendered as active content in the review page.

Remote images load automatically only over HTTPS and use a no-referrer policy. Local images may use relative, parent-relative, or absolute WSL paths. Richie follows symlinks and serves authenticated PNG, JPEG, GIF, WebP, and AVIF files up to 25 MiB. A live session token can request any supported local raster image path. Do not share review URLs or tokens.

Missing, blocked, oversized, unsupported, and failed images show their original Markdown in a visible fallback. Richie does not render local SVG, `http:`, `file:`, `data:`, protocol-relative image URLs, raw HTML video, or raw HTML audio.

## Finish a review

Click `Finish review` when feedback is complete. Richie verifies the source hash, exports the next available `draft-vNN-commented.md`, and removes the temporary sidecar. If there is no open feedback, no commented copy is created.

Exported deletion markers quote the exact selected source text. Cell, row, column, block, and image deletions also identify their operation scope.

Click `Abort review` to discard open feedback without exporting a file.

Do not edit generated HTML as source. Do not treat the commented copy as canonical Markdown.

## Troubleshooting

If the service is unavailable, start it with `sudo systemctl start richie` and inspect `richie status` or `journalctl -u richie`.

If the source changes during a review, Richie blocks new feedback and export while retaining the sidecar. Restore the reviewed source or abort the review.

## WSL service installation

```sh
npm run build
sudo install -m 644 packaging/richie.service /etc/systemd/system/richie.service
sudo systemctl daemon-reload
sudo systemctl enable --now richie
```

The unit points to the current Node 22 path in `packaging/richie.service`. Update it if that installation moves.
