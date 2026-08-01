# Richie

Richie is a local visual review layer for versioned Markdown. It keeps Markdown canonical, captures browser feedback in temporary JSON, and exports a committed `-commented.md` review copy using `<<ASB: ...>>` markers.

See the [user guide](user-guide.md) for installation, review, and handoff instructions.

The review surface has document navigation on the left, review actions and feedback inventory on the right, inline range highlights, Markdown image review, and document search. The user guide and search controls remain fixed while the outline scrolls. The review actions remain fixed while the feedback inventory scrolls.

Richie renders inline, linked, and reference-style Markdown images. Hover an image to comment on, replace, or delete its complete Markdown syntax. Remote images load directly over HTTPS. Local PNG, JPEG, GIF, WebP, and AVIF files load through the authenticated review session, including absolute and parent-relative paths. SVG and raw HTML media remain disabled.

## Development

```sh
npm install
npm run check
npm test
npm run build
npm start
npm run review -- path/to/draft-v03.md
```

The service binds only to `127.0.0.1:43173`. The CLI asks its Unix control socket to create a review session and opens the resulting tab with `xdg-open`.

## Install as a WSL service

Build first, then install the supplied system unit:

```sh
sudo install -m 644 packaging/richie.service /etc/systemd/system/richie.service
sudo systemctl daemon-reload
sudo systemctl enable --now richie
```

The unit uses the currently installed Node 22 binary under Akhil's NVM installation. It intentionally shares the host `/tmp` namespace so drafts and local media there are reviewable. Update `ExecStart` in `packaging/richie.service` when that Node installation moves.

Check it with `systemctl status richie` and inspect logs with `journalctl -u richie`. Stop it with `sudo systemctl disable --now richie`.

The service keeps WSL running while enabled. Review JSON files are ignored by Git and are deleted only after a successful `Finish review` action. Richie asks for confirmation before finishing, closes the review tab after the response, and does not export a file when there is no open feedback. The agent reviews and commits the resulting `draft-vNN-commented.md` file.
