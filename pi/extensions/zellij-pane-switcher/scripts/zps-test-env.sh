#!/usr/bin/env bash
# Manage an isolated Zellij server used by manual-test-plan-v00.md.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  eval "$(scripts/zps-test-env.sh setup)"

  scripts/zps-test-env.sh cleanup [ZPS_TEST_ROOT]

Environment:
      Create zps-a, zps-b, and zps-c during setup.

Each session receives randomly generated tab and pane names.
EOF
}

pick_name() {
  local -a choices=("$@")
  printf '%s' "${choices[RANDOM % ${#choices[@]}]}"
}

cmd_setup() {
  local root
  local zellij_bin="${ZPS_ZELLIJ_BIN:-$HOME/.local/bin/zellij}"

  if [ ! -x "$zellij_bin" ]; then
    echo "error: Zellij binary is not executable: $zellij_bin" >&2
    exit 1
  fi

  root="$(mktemp -d)"

  mkdir -p \
    "$root/socket" \
    "$root/config-home" \
    "$root/cache" \
    "$root/data-home" \
    "$root/data"

  local -a funny_tabs=(
    "Mission Control"
    "Goblin Workshop"
    "The Backrooms"
    "Caffeinated Operations"
    "Department of Bad Ideas"
    "Keyboard Aquarium"
    "The Panic Room"
    "Ctrl-Alt-Delicatessen"
  )

  local -a funny_panes=(
    "Captain Keyboard"
    "The Log Goblin"
    "Snack Overflow"
    "Compiler Tears"
    "Suspicious Silence"
    "Definitely Production"
    "Mysterious CPU Activity"
    "The Cache Whisperer"
    "One More Terminal"
    "Incidentally Incident Response"
    "PagerDuty's Haunted Cousin"
    "The Button Nobody Presses"
    "Absolutely Not Root"
    "The Process Whisperer"
    "Terminal Velocity"
    "Unscheduled Maintenance"
  )

  # setup is intended to be evaluated by the caller so these exports affect
  # the caller's shell: eval "$(scripts/zps-test-env.sh setup)"
  printf 'export ZPS_TEST_ROOT=%q\n' "$root"
  printf 'export ZELLIJ_SOCKET_DIR=%q\n' "$root/socket"
  printf 'export XDG_CONFIG_HOME=%q\n' "$root/config-home"
  printf 'export XDG_CACHE_HOME=%q\n' "$root/cache"
  printf 'export XDG_DATA_HOME=%q\n' "$root/data-home"
  printf 'export ZPS_ZELLIJ_BIN=%q\n' "$zellij_bin"

  for name in zps-a zps-b zps-c; do
    local layout="$root/$name.kdl"

    cat > "$layout" <<EOF
layout {
  tab name="$(pick_name "${funny_tabs[@]}")" {
    pane split_direction="vertical" {
      pane name="$(pick_name "${funny_panes[@]}")" command="htop"
      pane name="$(pick_name "${funny_panes[@]}")" command="bash" {
        args "-lc" "while true; do date; sleep 5; done"
      }
    }
    pane name="$(pick_name "${funny_panes[@]}")" command="bash"
  }

  tab name="$(pick_name "${funny_tabs[@]}")" {
    pane split_direction="horizontal" {
      pane name="$(pick_name "${funny_panes[@]}")" command="bash"
      pane name="$(pick_name "${funny_panes[@]}")" command="bash"
    }
  }

  tab name="$(pick_name "${funny_tabs[@]}")" {
    pane name="$(pick_name "${funny_panes[@]}")" command="bash"
  }
}
EOF

    ZELLIJ_SOCKET_DIR="$root/socket" \
      XDG_CONFIG_HOME="$root/config-home" \
      XDG_CACHE_HOME="$root/cache" \
      XDG_DATA_HOME="$root/data-home" \
      "$zellij_bin" \
        attach \
        --create-background "$name"

    # In Zellij 0.44.3, --session is a top-level option, before action.
    ZELLIJ_SOCKET_DIR="$root/socket" \
      XDG_CONFIG_HOME="$root/config-home" \
      XDG_CACHE_HOME="$root/cache" \
      XDG_DATA_HOME="$root/data-home" \
      "$zellij_bin" \
        --session "$name" \
        action \
        override-layout "$layout"
  done
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

  local zellij_bin="${ZPS_ZELLIJ_BIN:-$HOME/.local/bin/zellij}"

  if [ ! -x "$zellij_bin" ]; then
    echo "error: Zellij binary is not executable: $zellij_bin" >&2
    exit 1
  fi

  for name in zps-a zps-b zps-c; do
    ZELLIJ_SOCKET_DIR="$root/socket" \
      "$zellij_bin" \
        kill-session "$name" >/dev/null 2>&1 || true
  done

  # Remove the temporary root before emitting commands for the caller.
  rm -rf -- "$root"
  echo "cleaned up $root" >&2

  # cleanup is also intended to be evaluated by the caller:
  # eval "$(scripts/zps-test-env.sh cleanup)"
  printf 'unset ZPS_TEST_ROOT ZELLIJ_SOCKET_DIR XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME ZPS_ZELLIJ_BIN\n'
}

case "${1:-}" in
  setup)
    cmd_setup
    ;;
  cleanup)
    shift
    cmd_cleanup "${1:-}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
