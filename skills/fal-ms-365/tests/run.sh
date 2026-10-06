#!/usr/bin/env bash
set -euo pipefail
base=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for tool in node powershell.exe wslpath; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 127; }; done
bash -n "$base/scripts/run.sh" "$base/tests/run.sh"
node --test "$base/tests/bridge.test.cjs"
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$(wslpath -w "$base/tests/fixtures.ps1")"
