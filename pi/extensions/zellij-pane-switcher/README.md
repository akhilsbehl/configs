# zellij-pane-switcher

A Rust/WebAssembly Zellij plugin for finding and focusing panes across the current session.

## Status

The first interactive slice is implemented. It discovers panes across tabs, groups them by tab, supports local fuzzy search, keyboard navigation, starring, focusing, hiding, and mouse selection. It also handles the `open` and `focus-starred` plugin messages for external Zellij keybindings.

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

The plugin recognizes these message names for external Zellij bindings:

- `open`: show and focus the switcher pane;
- `focus-starred`: focus the starred pane, or show `No starred pane`.

Example `config.kdl` bindings:

```kdl
keybinds {
    shared_except "resize" "scroll" {
        bind "Alt y" {
            MessagePlugin "file:/absolute/path/to/zellij-pane-switcher.wasm" {
                name "open"
                floating true
            }
        }
        bind "Alt g" {
            MessagePlugin "file:/absolute/path/to/zellij-pane-switcher.wasm" {
                name "focus-starred"
            }
        }
    }
}
```

Zellij delivers these bindings through the plugin pipe API. The plugin does not modify the user's configuration. Change the plugin URL or keys to override the defaults.

## Design

See [`pane-switcher-plan.md`](pane-switcher-plan.md) for the current specification and implementation plan.
