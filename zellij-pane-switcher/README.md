# zellij-pane-switcher

A Rust/WebAssembly Zellij plugin for finding and focusing panes across all live Zellij sessions.

## Status

The plugin discovers panes across all live sessions, groups them by session and tab, supports hierarchical case-insensitive search, keyboard navigation, cross-session focusing, and hiding. Resurrectable sessions appear as session-only targets and are restored through Zellij. It handles the `open` plugin message for external Zellij keybindings.

## Requirements

- Zellij `0.44.0` or a compatible release
- Rust stable
- Rust target `wasm32-wasip1`

## Build

```bash
cargo fmt --all -- --check
cargo build --release --target wasm32-wasip1
```

The build output will be at:

```text
target/wasm32-wasip1/release/zellij-pane-switcher.wasm
```

The checked-in deployment artifact is kept at:

```text
/home/akhil/configs/zellij-pane-switcher/zellij-pane-switcher.wasm
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
| `Ctrl-s` | Toggle pane switcher / session manager |
| `Tab` / `Shift-Tab` | Move selection |
| `Enter` | Activate the selected pane or session |
| `Esc` | Hide the switcher or cancel a prompt |
| `Backspace` | Delete the last search character |

In session manager mode, `N` creates a named session, `K` kills a live session, and `D` permanently deletes a session. Destructive actions require confirmation. After a remote kill/delete, the plugin returns to pane switcher mode; killing/deleting the current session first switches to the next live session so the plugin remains available. Zellij may not expose a freshly created session as resurrectable until its session serialization has run.

The plugin recognizes this message name for external Zellij bindings:

- `open`: show and focus the switcher pane.

Example `config.kdl` bindings:

```kdl
keybinds {
    shared_except "resize" "scroll" {
        bind "Alt y" {
            MessagePlugin "file:/home/akhil/configs/zellij-pane-switcher/zellij-pane-switcher.wasm" {
                name "open"
                floating true
            }
        }
    }
}
```

Zellij delivers these bindings through the plugin pipe API. The plugin does not modify the user's configuration. Change the plugin URL or keys to override the defaults.

## Session-manager integration

The cross-session view uses Zellij's `SessionUpdate` events for normal refreshes, with `get_session_list()` as the initial snapshot fallback, and `switch_session_with_focus()` for activation. It is designed to run as a floating `session-manager` alias, with one plugin window per session where practical:

```kdl
plugins {
    session-manager location="file:/home/akhil/configs/zellij-pane-switcher/zellij-pane-switcher.wasm"
}
```

Live session and tab names filter their descendant panes. Only pane rows are selectable for live sessions. A resurrectable session is the sole exception because it has no pane until Zellij restores it.
