#!/usr/bin/env bash
# Create a standalone deck that opens directly in a modern browser.
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
exec node "$root/scripts/new-deck.mjs" "$@"
