# Richie user guide

Richie opens a local browser review surface for a Markdown file. Use it to record precise editorial feedback, then hand the generated commented copy to an agent for application to the next Markdown version.

Markdown remains the source of truth. Richie does not edit the source file during review.

## Before you start

The input must be a readable and writable file whose name ends in `.md`. Build Richie before using the CLI:

```sh
npm install
npm run check
npm test
npm run build
```

The automated test command also builds the project. The separate build command is useful when you only need the runnable service.

## Start Richie

For a one-off session, start the service in one terminal:

```sh
npm start
```

Then open a draft from another terminal:

```sh
npm run review -- path/to/draft-vNN.md
```

If the `richie` executable is installed, the equivalent command is:

```sh
richie review path/to/draft-vNN.md
```

The CLI asks the local control socket to create a session and opens the review URL with `xdg-open`. The service listens only on `127.0.0.1:43173`.

Check service status with:

```sh
richie status
```

If the service is unavailable, start it with:

```sh
sudo systemctl start richie
```

The installed system service uses the built output in this repository. Rebuild after source changes, then restart the service.

## Review a draft

1. Open the draft with `richie review path/to/draft-vNN.md`.
2. Read the rendered document for hierarchy, wording, tables, and diagrams.
3. Select text and choose an action from the toolbar:
   - `Delete` marks the selection for deletion.
   - `Replace` records proposed replacement wording.
   - `Comment` records an editorial comment.
4. Use the controls that appear beside a paragraph, heading, list item, table cell, or table row for block-level feedback.
5. Use `Opening note` or `Closing note` for a document-level instruction.
6. Check the feedback list on the right as you work.

Richie saves each operation immediately to a temporary sidecar named like `draft-vNN.review.json`. Each operation retains the selected source quote and source range.

Hover over source-mapped text to open a `Comment`, `Replace`, and `Delete` menu beneath that text range. Use the toolbar for a selection that crosses multiple ranges.

### Tables and Mermaid diagrams

Tables support targeted review controls. Hover over a cell to comment on it, clear its contents, or mark its column for deletion. Hover over a table row to mark the row for deletion. These actions create review operations and do not change the source table during the session.

Mermaid code blocks render as diagrams in the review surface and also expose a `Mermaid source` view beneath the diagram. Expand the source view to select and comment on exact Mermaid lines. The SVG remains visual context; review operations attach to the Mermaid source, not to SVG nodes or edges. Richie does not provide direct source editing or diagram editing. If Mermaid cannot render a diagram, the review surface displays an inline warning and keeps the source view available.

## Finish a review

Click `Finish review` only when the feedback is complete. Richie asks for confirmation, verifies that the Markdown source has not changed, writes the next available commented copy, and removes the temporary review sidecar after a successful export. If there is no open feedback, Richie removes the empty review state without creating a commented file. After the response, the browser attempts to close the review tab.

Click `Abort review` to discard the open feedback without exporting a commented file. Richie asks for confirmation, removes the review sidecar, closes the session, and attempts to close the browser tab.

The output is named like:

```text
draft-vNN-commented.md
```

If that name already exists, Richie adds a numeric suffix. The output contains `<<ASB: ...>>` markers for open review operations. Review and apply those markers to the canonical Markdown source, then create the next versioned draft, for example `draft-v04.md` after reviewing `draft-v03.md`.

Do not edit generated HTML as source. Do not treat the commented copy as the canonical draft.

## Troubleshooting

### “Richie service is unavailable”

Start the service and check its status:

```sh
sudo systemctl start richie
richie status
```

For service logs:

```sh
journalctl -u richie
```

### The review refuses to start

Richie refuses non-Markdown paths, missing files, and files without read/write access. It also refuses to reuse a sidecar whose source hash does not match the current Markdown file. Finish the existing review first, or resolve the stale review state deliberately before starting another session.

### The review refuses to finish

The source changed after the session started. The saved feedback is retained. Reconcile the source change and review feedback before starting a new review session.

## WSL service installation

To keep Richie available as a WSL service, build first and install the supplied unit:

```sh
npm run build
sudo install -m 644 packaging/richie.service /etc/systemd/system/richie.service
sudo systemctl daemon-reload
sudo systemctl enable --now richie
```

Check it with `systemctl status richie`. Stop and disable it with:

```sh
sudo systemctl disable --now richie
```

The unit currently points to the Node 22 binary at `/home/akhil/.nvm/versions/node/v22.22.2/bin/node`. Update `packaging/richie.service` if that installation moves.
