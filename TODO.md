# TODO

## Submodule project guidance

- [x] During the monorepo split, add this rule to the root `AGENTS.md` of every extracted project and preserve it in the submodule repository:

  > This project is checked out as a Git submodule of `configs`. For normal development, switch from the parent's detached pinned commit to a named child branch before editing. Commit and push changes in the child repository, then update the parent repository's submodule pin in a separate commit. Use the detached pinned state only for read-only verification, reproduction, or testing the exact parent integration.

- [x] Add the same submodule-development rule to any new project created during the migration.

## Monorepo split

- [ ] Stash the current `claude-settings.json` change before migration and restore it after migration completion.
- [x] Create a safety tag and migration branch before changing the parent repository.
- [x] Extract `richie` with all history into a public repository and add child-local ignore rules.
- [ ] Prepare `richie` for public distribution and make systemd checkout and Node paths configurable.
- [x] Extract `zellij-pane-switcher` with all history into a public repository. Keep the committed WASM and do not publish the vendor repository or absolute symlink.
- [ ] Improve `zellij-pane-switcher` distribution and installation for other users.
- [x] Extract `pie-zellij-status` into a public repository.
- [ ] Document `pie-zellij-status` installation/loading.
- [x] Extract `pie-jina` as a personal-use project loaded through a local symlink.
- [x] Extract `pie-damare` as a personal-use project loaded through a local symlink.
- [x] Extract `pie-permission-auto-review-codex` as a personal-use project. Retain MIT attribution and upstream provenance, rename package identities, publish/use the child-owned schema URL, and verify generated `dist/` freshness.
- [x] Extract `pie-subagents` directly from the `pi-subagents` branch and keep `.scratch` tracked.
- [ ] Prepare `pie-subagents` for public distribution.
- [x] Add each approved child repository as a submodule at its renamed parent path.
- [x] Update `pi/settings.json` for renamed local package paths.
- [x] Recreate machine-local `~/.pi/agent/extensions` symlinks for all renamed extensions.
- [ ] Update schemas, README files, skills, service files, and install references for renamed submodules.
- [ ] Verify clean clone, recursive submodule initialisation, child tests, parent integration, Pi loading, Richie service operation, and Zellij plugin loading.
- [x] Preserve the pre-split parent history and verify that each child extraction retains all relevant history.
