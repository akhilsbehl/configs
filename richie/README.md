# Richie

Richie is a local visual review layer for versioned Markdown. It keeps Markdown canonical, captures browser feedback in temporary JSON, and exports a committed `-commented.md` review copy using `<<ASB: ...>>` markers.

See the [user guide](user-guide-v00.md) for installation, review, and handoff instructions.

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

The unit uses the currently installed Node 22 binary under Akhil's NVM installation. Update `ExecStart` in `packaging/richie.service` when that Node installation moves.

Check it with `systemctl status richie` and inspect logs with `journalctl -u richie`. Stop it with `sudo systemctl disable --now richie`.

The service keeps WSL running while enabled. Review JSON files are ignored by Git and are deleted only after a successful `Finish review` export. The agent reviews and commits the resulting `draft-vNN-commented.md` file.
