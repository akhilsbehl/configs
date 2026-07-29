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
3. Hover over a heading, paragraph, list, blockquote, code block, table cell, or Mermaid source for block-level feedback.
4. Use `Document level note` for cross-cutting feedback. It appears at the top of the commented copy.
5. Use the left sidebar to navigate headings. Use the right sidebar to inspect, edit, jump to, or remove feedback.
6. Use the search control at the top of the left sidebar. `Previous match` and `Next match`, or `Shift+Enter` and `Enter`, move between results. `Escape` clears the search.

Richie saves every operation immediately to `draft-vNN.review.json`. Each range operation retains the exact source quote and source range. Range highlighting applies only to the selection, not its containing paragraph or line.

### Tables and Mermaid

Hover over a table cell to comment, replace, clear, delete its row, or delete its column. A column deletion highlights every cell in that column and exports a marker inside each affected table cell, preserving the Markdown table fences.

Mermaid diagrams render as SVG for reading and expose a source view for review. Select Mermaid source lines, not SVG elements. Markers for Mermaid and ordinary fenced-code feedback are exported after the closing fence, so the source block continues to render. A code-block-level marker is aligned with that closing fence.

## Finish a review

Click `Finish review` when feedback is complete. Richie verifies the source hash, exports the next available `draft-vNN-commented.md`, and removes the temporary sidecar. If there is no open feedback, no commented copy is created.

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
