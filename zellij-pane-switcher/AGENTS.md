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
