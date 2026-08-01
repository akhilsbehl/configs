#!/usr/bin/env bash
# Manage the isolated Zellij server used by manual-test-plan-v00.md.
# Uses its own socket dir and config, so it can never reach sessions on
# the default socket. Only ever touches sessions named zps-a/b/c/d.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  eval "$(scripts/zps-test-env.sh setup)"
      Creates an isolated test root (temp dir with its own socket, config,
      cache, and data dirs) and prints export statements for ZPS_TEST_ROOT,
      XDG_CONFIG_HOME, XDG_CACHE_HOME, XDG_DATA_HOME, ZELLIJ_SOCKET_DIR,
      ZELLIJ_CONFIG_FILE, and ZPS_ZELLIJ_BIN. eval'ing wires them into your
      current shell.

  scripts/zps-test-env.sh cleanup [ZPS_TEST_ROOT]
      Kills only the zps-a, zps-b, zps-c, zps-d sessions on the isolated
      socket (if running), then deletes the isolated test root. Uses
      $ZPS_TEST_ROOT from the environment if no argument is given.
EOF
}

cmd_setup() {
  local root
  local zellij_bin="${ZPS_ZELLIJ_BIN:-$HOME/.local/bin/zj}"
  if [ ! -x "$zellij_bin" ]; then
    echo "error: Zellij binary is not executable: $zellij_bin" >&2
    exit 1
  fi
  root="$(mktemp -d)"
  mkdir -p "$root/socket" "$root/config-home" "$root/cache" "$root/data-home" "$root/data"
  : > "$root/config.kdl"
  echo "export ZPS_TEST_ROOT=\"$root\""
  echo "export XDG_CONFIG_HOME=\"$root/config-home\""
  echo "export XDG_CACHE_HOME=\"$root/cache\""
  echo "export XDG_DATA_HOME=\"$root/data-home\""
  echo "export ZELLIJ_SOCKET_DIR=\"$root/socket\""
  echo "export ZELLIJ_CONFIG_FILE=\"$root/config.kdl\""
  echo "export ZPS_PLUGIN=\"file:$PWD/target/wasm32-wasip1/debug/zellij-pane-switcher.wasm\""
  echo "export ZPS_ZELLIJ_BIN=\"$zellij_bin\""
}

cmd_cleanup() {
  local root="${1:-${ZPS_TEST_ROOT:-}}"
  if [ -z "$root" ]; then
    echo "error: no test root given and ZPS_TEST_ROOT is not set" >&2
    exit 1
  fi
  if [ ! -d "$root/socket" ]; then
    echo "error: '$root' has no socket dir, refusing to touch it" >&2
    exit 1
  fi
  local zellij_bin="${ZPS_ZELLIJ_BIN:-$HOME/.local/bin/zj}"
  if [ ! -x "$zellij_bin" ]; then
    echo "error: Zellij binary is not executable: $zellij_bin" >&2
    exit 1
  fi
  for name in zps-a zps-b zps-c zps-d; do
    ZELLIJ_SOCKET_DIR="$root/socket" "$zellij_bin" --config "$root/config.kdl" kill-session "$name" \
      >/dev/null 2>&1 || true
  done
  rm -rf "$root"
  echo "cleaned up $root"
}

case "${1:-}" in
  setup) cmd_setup ;;
  cleanup) shift; cmd_cleanup "${1:-}" ;;
  *) usage; exit 1 ;;
esac
