#!/usr/bin/env bash
# Use a request file, not interpolated PowerShell source. No installation or auth UI.
set -euo pipefail
[[ $# == 1 ]] || { echo 'Usage: run.sh /absolute/path/request.json' >&2; exit 2; }
for tool in node powershell.exe wslpath; do
  command -v "$tool" >/dev/null || { echo "Missing $tool; ask the user to install/configure it." >&2; exit 127; }
done
base=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
request=$(realpath -- "$1")
tmp=$(mktemp -d /tmp/fal-ms-365.XXXXXXXX)
chmod 700 "$tmp"
trap 'rm -rf -- "$tmp"' EXIT
node "$base/bridge.cjs" prepare "$request" "$tmp/request.json"
export MS_GRAPH_TENANT_ID="${MS_GRAPH_TENANT_ID:-}" MS_GRAPH_CLIENT_ID="${MS_GRAPH_CLIENT_ID:-}"
for key in MS_GRAPH_TENANT_ID MS_GRAPH_CLIENT_ID; do
  case ":${WSLENV:-}:" in *:"$key":*) ;; *) WSLENV="${WSLENV:+$WSLENV:}$key" ;; esac
done
export WSLENV
# Match the existing Graph wrapper's process-only policy setting; never change machine policy.
set +e
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
  -File "$(wslpath -w "$base/invoke.ps1")" \
  -RequestPath "$(wslpath -w "$tmp/request.json")" > "$tmp/result.json"
status=$?
set -e
if [[ ! -s "$tmp/result.json" ]]; then
  echo "PowerShell returned no structured result (exit $status). Inspect before retrying any write." >&2
  [[ "$status" -ne 0 ]] || status=1
  exit "$status"
fi
node "$base/bridge.cjs" finish "$request" "$tmp/result.json"
exit "$status"
