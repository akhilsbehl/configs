# Zellij pane switcher

This is a standalone Rust/WebAssembly Zellij plugin.

## Build and test

- Target Zellij 0.44.x and Rust stable.
- Build for `wasm32-wasip1`.
- Keep the checked-in `zellij-pane-switcher.wasm` synchronized with source changes; Zellij loads this artifact from `zellij-conf.kdl`.
- Run model tests with:

  ```bash
  rustc --test src/model.rs -o /tmp/zellij-pane-switcher-model-tests
  /tmp/zellij-pane-switcher-model-tests
  ```

- Use `scripts/zps-test-env.sh` for isolated manual Zellij testing.

## Configuration

The active configuration is the repository root's `zellij-conf.kdl`, symlinked from `~/.config/zellij/config.kdl`. Update that source file rather than editing the symlink target directly.

`vendor` is a machine-local symlink to `/home/akhil/warchives/zellij-pane-switcher/vendor`. On any other machine, remind ASB to remove this symlink and recreate the vendor directory appropriately before building.

## Tips and tricks

- Do not commit the wasm binary until after all testing is completed and ASB asks you to commit it. Remind him to do so before merge back to master.
- To hot reload the plugin, build the WASM, then run the durable commands below from each attached session. The pane ID must be found by scanning all `list-panes` fields because tab names contain spaces. `--skip-plugin-cache` is required to load the latest binary. Zellij 0.44.3 does not persistently launch plugin panes into detached sessions via CLI; attach to each session before running these commands. Do not run a loop that closes panes in detached sessions, because it may be unable to recreate them.

  ```bash
  wasm=/home/akhil/configs/zellij-pane-switcher/zellij-pane-switcher.wasm
  cargo build --release --target wasm32-wasip1
  cp target/wasm32-wasip1/release/zellij-pane-switcher.wasm "$wasm"

  mapfile -t panes < <(
    zellij action list-panes --all --tab --state --command \
      | grep -E 'zellij-pane-switcher\\.wasm' \
      | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^plugin_[0-9]+$/) { print $i; break } }'
  )
  for pane in "${panes[@]}"; do
    zellij action close-pane --pane-id "$pane"
  done
  zellij action launch-plugin --floating --skip-plugin-cache "file:$wasm"
  ```

  Repeat the pane-discovery/reload block after attaching to every session that needs the update. `/tmp/reload-zellij-pane-switcher.sh` is only a convenience copy of this procedure and is not authoritative.
