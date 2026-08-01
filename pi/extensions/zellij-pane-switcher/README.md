# zellij-pane-switcher

A Rust/WebAssembly Zellij plugin for finding and focusing panes across all live Zellij sessions.

## Status

The plugin discovers panes across all live sessions, groups them by session and tab, supports hierarchical local fuzzy search, keyboard navigation, starring, cross-session focusing, and hiding. Resurrectable sessions appear as session-only targets and are restored through Zellij. It also handles the `open` and `focus-starred` plugin messages for external Zellij keybindings.

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

The repository is configured for the WASI plugin target, so run the dependency-free model tests directly:

```bash
rustc --test src/model.rs -o /tmp/zellij-pane-switcher-model-tests
/tmp/zellij-pane-switcher-model-tests
```

## Controls

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

## Session-manager integration

The cross-session view uses `get_session_list()` and `switch_session_with_focus()` from the Zellij plugin API. It is designed to run as a floating `session-manager` alias, with one plugin window per session where practical:

```kdl
plugins {
    session-manager location="file:/absolute/path/to/zellij-pane-switcher.wasm"
}
```

Live session and tab names filter their descendant panes. Only pane rows are selectable for live sessions. A resurrectable session is the sole exception because it has no pane until Zellij restores it.

## Design

See [`pane-switcher-session-design-v02.md`](pane-switcher-session-design-v02.md) for the approved design specification.
