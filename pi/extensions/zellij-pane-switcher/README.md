# zellij-pane-switcher

A Rust/WebAssembly Zellij plugin for finding and focusing panes across the current session.

## Status

Initial API-proof slice is implemented. It subscribes to pane, tab, keyboard, and mouse events, requests the required state-change permissions, excludes its own plugin pane, and renders the current pane inventory. The searchable pane model has dependency-free fuzzy matching and passing direct Rust tests.

The interactive actions and persistent floating-pane integration are next.

## Requirements

- Zellij `0.44.0` or a compatible release
- Rust stable
- Rust target `wasm32-wasip1`

## Build

```bash
cargo fmt --all -- --check
cargo build --target wasm32-wasip1
```

The plugin output will be at:

```text
target/wasm32-wasip1/debug/zellij-pane-switcher.wasm
```

## Test

The normal test command is:

```bash
cargo test
```

If dependency downloads are blocked by the network, the dependency-free model tests can be run directly:

```bash
rustc --test src/model.rs -o /tmp/zellij-pane-switcher-model-tests
/tmp/zellij-pane-switcher-model-tests
```

## Planned controls

| Binding | Action |
| --- | --- |
| `Alt-y` | Open or focus the switcher |
| `Alt-g` | Focus the starred pane |
| `Tab` / `Shift-Tab` | Move selection |
| `Enter` | Focus selected pane and hide the switcher |
| `Esc` | Hide the switcher |
| `Space` | Star or unstar the selected pane |
| `Backspace` | Delete the last search character |

The default bindings will be documented with the final Zellij configuration. Users will be able to override them without the plugin overwriting existing configuration.

## Design

See [`pane-switcher-plan.md`](pane-switcher-plan.md) for the current specification and implementation plan.
