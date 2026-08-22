# TODO

## Submodule project guidance

- [ ] During the monorepo split, add this rule to the root `AGENTS.md` of every extracted project and preserve it in the submodule repository:

  > This project is checked out as a Git submodule of `configs`. For normal development, switch from the parent's detached pinned commit to a named child branch before editing. Commit and push changes in the child repository, then update the parent repository's submodule pin in a separate commit. Use the detached pinned state only for read-only verification, reproduction, or testing the exact parent integration.

- [ ] Add the same submodule-development rule to any new project created during the migration.

## Monorepo split

- [ ] Stash the current `claude-settings.json` change before migration and restore it after migration completion.
- [ ] Create a safety tag and migration branch before changing the parent repository.
- [ ] Extract `richie` with all history into a public repository. Prepare it for public distribution, add child-local ignore rules, and make systemd checkout and Node paths configurable.
- [ ] Extract `zellij-pane-switcher` with all history into a public repository. Keep the committed WASM, do not publish the vendor repository or absolute symlink, and improve distribution and installation for other users.
- [ ] Extract `pie-zellij-status` into a public repository and document installation/loading.
- [ ] Extract `pie-jina` as a personal-use project loaded through a local symlink.
- [ ] Extract `pie-damare` as a personal-use project loaded through a local symlink.
- [ ] Extract `pie-permission-auto-review-codex` as a personal-use project. Retain MIT attribution and upstream provenance, rename package identities, publish/use the child-owned schema URL, and verify generated `dist/` freshness.
- [ ] Extract `pie-subagents` directly from the `pi-subagents` branch. Keep `.scratch` tracked and prepare the project for public distribution.
- [ ] Add each approved child repository as a submodule at its renamed parent path.
- [ ] Update `pi/settings.json` for renamed local package paths.
- [ ] Recreate machine-local `~/.pi/agent/extensions` symlinks for all renamed extensions.
- [ ] Update schemas, README files, skills, service files, and install references for renamed submodules.
- [ ] Verify clean clone, recursive submodule initialisation, child tests, parent integration, Pi loading, Richie service operation, and Zellij plugin loading.
- [ ] Preserve the pre-split parent history and verify that each child extraction retains all relevant history.
